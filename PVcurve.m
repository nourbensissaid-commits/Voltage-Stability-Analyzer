function [P, V21, V22, connected_buses] = PVcurve(Bto, data_2, plotFlag, powerFactor)

if nargin < 4 || isempty(powerFactor)
    powerFactor = 0.9;
end
if nargin < 3
    plotFlag = true;
end

if nargin == 2 && (islogical(data_2) || (isnumeric(data_2) && isscalar(data_2)))
    plotFlag = logical(data_2);
    data_2 = [];
end

V_all = [];
theta_all = [];
BranchData = [];
nbus = [];
if exist('data_2','var') && ~isempty(data_2)
    D = data_2;
    if ischar(D) || isstring(D)
        try
            D = evalin('base', D);
        catch
            D = [];
        end
    end
    if isnumeric(D)
        if size(D,2) >= 6
            BD = D;
            V_all = BD(:,5);
            thcol = BD(:,6);
            if max(abs(thcol)) > 2*pi
                theta_all = thcol * pi/180;
            else
                theta_all = thcol;
            end
        else
            % Could be BranchData; try to detect 2+ columns
            if size(D,2) >= 2
                BranchData = D;
            end
        end
    elseif isstruct(D)
        s = D;
        if isfield(s,'BusData')
            BD = s.BusData;
            V_all = BD(:,5);
            thcol = BD(:,6);
            if max(abs(thcol)) > 2*pi
                theta_all = thcol * pi/180;
            else
                theta_all = thcol;
            end
        end
        if isfield(s,'BranchData')
            BranchData = s.BranchData;
        end
        if isfield(s,'V_all')
            V_all = s.V_all;
        end
        if isfield(s,'theta_all')
            theta_all = s.theta_all;
        end
        if isfield(s,'nbus')
            nbus = s.nbus;
        end
    end
end

if isempty(V_all)
    if evalin('base','exist(''V_all'',''var'')')
        V_all = evalin('base','V_all');
    elseif evalin('base','exist(''Vm'',''var'')')
        V_all = evalin('base','Vm');
    elseif evalin('base','exist(''V'',''var'')')
        Vtmp = evalin('base','V');
        V_all = abs(Vtmp);
    elseif evalin('base','exist(''busdata'',''var'')')
        bd = evalin('base','busdata');
        V_all = bd(:,3);
    elseif evalin('base','exist(''BusData'',''var'')')
        BD = evalin('base','BusData');
        if size(BD,2) >= 5
            V_all = BD(:,5);
        end
    end
end

if isempty(theta_all)
    if evalin('base','exist(''theta_all'',''var'')')
        theta_all = evalin('base','theta_all');
    elseif evalin('base','exist(''delta'',''var'')')
        theta_all = evalin('base','delta');
    elseif evalin('base','exist(''deltad'',''var'')')
        theta_all = evalin('base','deltad') * pi/180;
    elseif evalin('base','exist(''busdata'',''var'')')
        bd = evalin('base','busdata');
        if size(bd,2) >= 4
            theta_all = bd(:,4) * pi/180;
        end
    elseif exist('BD','var') && size(BD,2) >= 6
        thcol = BD(:,6);
        if max(abs(thcol)) > 2*pi
            theta_all = thcol * pi/180;
        else
            theta_all = thcol;
        end
    end
end

if isempty(BranchData) && evalin('base','exist(''BranchData'',''var'')')
    BranchData = evalin('base','BranchData');
end
if isempty(nbus) && evalin('base','exist(''nbus'',''var'')')
    nbus = evalin('base','nbus');
end

% Validate we've got what we need
if isempty(V_all) || isempty(theta_all)
    error('PVcurve: Could not find voltage magnitudes or angles. Provide `data_2` (BusData) or define `V_all`/`theta_all` in base workspace.');
end
if isempty(BranchData) || isempty(nbus)
    error('PVcurve: Could not find `BranchData` or `nbus` in provided data or base workspace.');
end

if nargin < 1 || isempty(Bto)
    error('PVcurve: Bto must be provided by caller.');
end
if ~ismember(Bto, 1:nbus)
    error('PVcurve: Bus number must be between 1 and %d', nbus);
end

% Find branches connected to Bto
idx_to   = find(BranchData(:,2) == Bto);
idx_from = find(BranchData(:,1) == Bto);
idx_branches = unique([idx_to; idx_from]);
if isempty(idx_branches)
    error('PVcurve: Selected bus %d has no connected branches.', Bto);
end

nBranches = numel(idx_branches);
connected_buses = zeros(nBranches,1);
X_branch = zeros(nBranches,1);
Vf_init = zeros(nBranches,1);
th_f = zeros(nBranches,1);

Vr_init = V_all(Bto);
theta_r = theta_all(Bto);

for k = 1:nBranches
    idx = idx_branches(k);
    b_from = BranchData(idx,1);
    b_to   = BranchData(idx,2);
    if b_from == Bto
        neighbor = b_to;
    else
        neighbor = b_from;
    end
    connected_buses(k) = neighbor;
    X_branch(k) = BranchData(idx,8);
    Vf_init(k) = V_all(neighbor);
    th_f(k) = theta_all(neighbor);
end

delta = theta_r - th_f;
if isempty(powerFactor) || abs(powerFactor - 0.9) < 1e-9
    Bvec = tan(delta);
else
    load_angle = acos(powerFactor);
    Bvec = tan(delta - load_angle);
end

% Prepare P sweep
X_safe = X_branch;
zeroX = (X_safe == 0);
if any(zeroX)
    X_safe(zeroX) = eps;
end
Pmax_branch = abs((Vf_init .* Vr_init) ./ X_safe);
Pmax = max(Pmax_branch);
if Pmax == 0
    Pmax = 1.0;
end
P = linspace(0, 0.9 * Pmax, 200);
nP = numel(P);

V21 = nan(nP, nBranches);
V22 = nan(nP, nBranches);

for k = 1:nBranches
    Vf = Vf_init(k);
    X = X_branch(k);
    if X == 0
        X = eps;
    end
    B = Bvec(k);
    for i = 1:nP
        Pi = P(i);
        term1 = (Vf^2)/2;
        disc = (Vf^4)/4 - Pi*X * (Pi*X + B*(Vf^2));
        if disc < 0
            V21(i,k) = NaN;
            V22(i,k) = NaN;
        else
            term3 = sqrt(disc);
            val1 = term1 - B*Pi*X + term3;
            val2 = term1 - B*Pi*X - term3;
            if val1 >= 0
                V21(i,k) = sqrt(val1);
            else
                V21(i,k) = NaN;
            end
            if val2 >= 0
                V22(i,k) = sqrt(val2);
            else
                V22(i,k) = NaN;
            end
        end
    end
end

% Optional plotting (plots in current axes)
if plotFlag
    figure; hold on;
    legend_text = {};
    for k = 1:nBranches
        bus_k = connected_buses(k);
        plot(P, V21(:,k), 'LineWidth', 1.4);
        plot(P, V22(:,k), '--', 'LineWidth', 1.4);
        legend_text{end+1} = sprintf('Bus %d - high', bus_k);
        legend_text{end+1} = sprintf('Bus %d - low',  bus_k);
    end
    xlabel('Active Power P (pu)');
    ylabel('Voltage V (pu)');
    title(sprintf('PV Curves for Bus %d', Bto));
        if isempty(powerFactor) || abs(powerFactor - 0.9) < 1e-9
            legend(legend_text, 'Location','best');
        else
            for pf_display = 1:numel(legend_text)
                legend_text{pf_display} = [legend_text{pf_display} ' (PF=' num2str(powerFactor,3) ')'];
            end
            legend(legend_text, 'Location','best');
        end
    grid on; hold off;
    grid on; hold off;
end
end