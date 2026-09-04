function [Vrange, Qvals, neighbor_bus, idx_branches, Qtotal] = QVcurve(Bto, data_2, plotFlag, pf)

if nargin < 3
    plotFlag = true;
end
if nargin == 2 && (islogical(data_2) || (isnumeric(data_2) && isscalar(data_2)))
    plotFlag = logical(data_2);
    data_2 = [];
end
if nargin < 4
    pf = [];
end

V_all = [];
theta_all = [];
BranchData = [];
nbus = [];
BusData_local = [];
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
            if size(D,2) >= 8
                BusData_local = D;
            end
        elseif size(D,2) >= 2
            BranchData = D;
        end
    elseif isstruct(D)
        s = D;
        if isfield(s,'BusData')
            BD = s.BusData;
            if size(BD,2) >= 5
                V_all = BD(:,5);
            end
            if size(BD,2) >= 6
                thcol = BD(:,6);
                if max(abs(thcol)) > 2*pi
                    theta_all = thcol * pi/180;
                else
                    theta_all = thcol;
                end
            end
            BusData_local = s.BusData;
        end
        if isfield(s,'V_all')
            V_all = s.V_all;
        end
        if isfield(s,'theta_all')
            theta_all = s.theta_all;
        end
        if isfield(s,'BranchData')
            BranchData = s.BranchData;
        end
        if isfield(s,'nbus')
            nbus = s.nbus;
        end
    end
end

% Fall back to base workspace
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
if isempty(BusData_local) && evalin('base','exist(''BusData'',''var'')')
    BusData_local = evalin('base','BusData');
end

if isempty(V_all) || isempty(theta_all)
    error('QVcurve: Could not find voltage magnitudes or angles. Provide `data_2` (BusData) or define `V_all`/`theta_all` in base workspace.');
end
if isempty(BranchData) || isempty(nbus)
    error('QVcurve: Could not find `BranchData` or `nbus` in provided data or base workspace.');
end

if nargin < 1 || isempty(Bto)
    error('QVcurve: Bto must be provided by caller.');
end
if ~ismember(Bto, 1:nbus)
    error('QVcurve: Bus number must be between 1 and %d', nbus);
end

% Find connected branches
idx_to   = find(BranchData(:,2) == Bto);
idx_from = find(BranchData(:,1) == Bto);
idx_branches = unique([idx_to; idx_from]);
if isempty(idx_branches)
    error('QVcurve: Selected bus %d has no connected branches.', Bto);
end

nBranches = numel(idx_branches);
neighbor_bus = zeros(nBranches,1);
X_branch = zeros(nBranches,1);
Vf_init = zeros(nBranches,1);
th_f = zeros(nBranches,1);

for k = 1:nBranches
    idx = idx_branches(k);
    b_from = BranchData(idx,1);
    b_to   = BranchData(idx,2);
    if b_from == Bto
        neighbor = b_to;
    else
        neighbor = b_from;
    end
    neighbor_bus(k) = neighbor;
    X_branch(k) = BranchData(idx,8);
    Vf_init(k) = V_all(neighbor);
    th_f(k) = theta_all(neighbor);
end

th_r = theta_all(Bto);
delta = th_r - th_f;

Vrange = linspace(0.6, 1.6, 300);
nV = numel(Vrange);
Qvals = nan(nV, nBranches);
Qtotal = [];

% Always compute branch network Q(V) (independent of PF)
for k = 1:nBranches
    Vf = Vf_init(k);
    X  = X_branch(k); if X == 0, X = eps; end
    if isempty(pf) || abs(pf - 0.9) < 1e-9
        % Standard: use network angle only
        theta = delta(k);
    else
        % Apply PF: shift angle by load_angle = acos(pf)
        load_angle = acos(pf);
        theta = delta(k) - load_angle;
    end
    for i = 1:nV
        V = Vrange(i);
        Qvals(i,k) = (V^2)/X - (Vf * V / X) * cos(theta);
    end
end

% Compute net Q(V) if PF provided (subtract load reactive power)
if ~isempty(pf) && ~(abs(pf - 0.9) < 1e-9)
    if isempty(BusData_local) || size(BusData_local,2) < 8
        error('QVcurve: BusData required to compute PF-based Q(V). Provide BusData via data_2 or base workspace.');
    end
    P_load_bus = BusData_local(Bto,7);
    if ~isfinite(pf) || pf <= 0 || pf > 1
        error('QVcurve: pf must be a scalar in (0,1].');
    end
    % Q_load affected by tan(acos(pf)) same as in CPF
    Qload_pf = P_load_bus * tan(acos(pf));
    Qnetwork_total = sum(Qvals, 2);
    Qtotal = Qnetwork_total - Qload_pf;
end

% Optional plotting
if plotFlag
    figure; hold on;
    legend_text_Q = {};
    if isempty(pf)
        % Show branch curves when no PF provided
        for k = 1:nBranches
            plot(Vrange, Qvals(:,k), 'LineWidth', 1.4);
            legend_text_Q{end+1} = sprintf('Bus %d', neighbor_bus(k));
        end
    end
    % If PF was provided, plot only the net Q(V)
    if ~isempty(Qtotal)
        plot(Vrange, Qtotal, 'k--', 'LineWidth', 2.0);
        legend_text_Q{end+1} = sprintf('Net (pf=%.3g)', pf);
    end
    xlabel('Voltage V (pu)');
    ylabel('Reactive Power Q (pu)');
    title(sprintf('QV Curves for Bus %d', Bto));
    legend(legend_text_Q, 'Location','best');
    grid on; hold off;
end
end