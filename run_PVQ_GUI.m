function run_PVQ_GUI()

%% Theme
bg      = [0.94 0.95 1.00];
panelBg = [0.88 0.90 0.96];
btnBlue = [0.20 0.55 0.90];
txtCol  = [0.12 0.16 0.22];

%% Main Figure (RESIZABLE)
hFig = figure('Name','PV / QV / CPF Curve Visualizer','NumberTitle','off', ...
    'MenuBar','none','ToolBar','none','Color',bg, ...
    'Resize','on', ...
    'Position',[150 140 800 500]);

%% Controls Panel
hPanel = uipanel('Parent',hFig,'Title',' Controls ','FontWeight','bold', ...
    'FontSize',12,'BackgroundColor',panelBg,'ForegroundColor',txtCol, ...
    'Units','normalized','Position',[0.01 0.02 0.28 0.96]);

% Data
uicontrol('Style','text','Parent',hPanel,'Units','normalized', ...
    'Position',[0.05 0.92 0.40 0.05],'String','Data Set:', ...
    'ForegroundColor',txtCol,'BackgroundColor',panelBg, ...
    'FontSize',11,'HorizontalAlignment','left','FontWeight','bold');

hData = uicontrol('Style','popupmenu','Parent',hPanel,'Units','normalized', ...
    'Position',[0.47 0.92 0.48 0.06],'String',{'Data_1','Data_2'}, ...
    'FontSize',11,'BackgroundColor','white');

% Method (added 'CPF')
uicontrol('Style','text','Parent',hPanel,'Units','normalized', ...
    'Position',[0.05 0.85 0.40 0.05],'String','Method:', ...
    'ForegroundColor',txtCol,'BackgroundColor',panelBg, ...
    'FontSize',11,'HorizontalAlignment','left','FontWeight','bold');

hMethod = uicontrol('Style','popupmenu','Parent',hPanel,'Units','normalized', ...
    'Position',[0.47 0.85 0.48 0.06],'String',{'PVcurve','QVcurve','CPF'}, ...
    'FontSize',11,'BackgroundColor','white','Callback',@onMethodChange);

% Node list
uicontrol('Style','text','Parent',hPanel,'Units','normalized', ...
    'Position',[0.05 0.74 0.90 0.06],'String','Select Node(s):', ...
    'ForegroundColor',txtCol,'BackgroundColor',panelBg, ...
    'FontSize',11,'HorizontalAlignment','left','FontWeight','bold');

initialNodes = arrayfun(@(x) sprintf('Node %d',x),1:14,'UniformOutput',false);

hNodeList = uicontrol('Style','listbox','Parent',hPanel,'Units','normalized', ...
    'Position',[0.05 0.50 0.90 0.24],'String',initialNodes,'Max',14,'Min',1, ...
    'FontSize',11,'BackgroundColor','white');

% attach node id mapping to listbox (initially 1..14)
set(hNodeList,'UserData',1:14);

% Checkboxes
hAllCB = uicontrol('Style','checkbox','Parent',hPanel,'Units','normalized', ...
    'Position',[0.05 0.44 0.90 0.05],'String','Plot ALL Nodes', ...
    'BackgroundColor',panelBg,'FontSize',10);

hLegendCB = uicontrol('Style','checkbox','Parent',hPanel,'Units','normalized', ...
    'Position',[0.05 0.39 0.90 0.05],'String','Show Legend', ...
    'BackgroundColor',panelBg,'FontSize',10,'Value',1);

% Power Factor selection (for PVcurve)
uicontrol('Style','text','Parent',hPanel,'Units','normalized', ...
    'Position',[0.05 0.14 0.90 0.04],'String','Power Factors:', ...
    'ForegroundColor',txtCol,'BackgroundColor',panelBg, ...
    'FontSize',10,'HorizontalAlignment','left','FontWeight','bold');

pfOptions = {'0.70','0.75','0.80','0.85','0.90','0.95'};
hPFList = uicontrol('Style','listbox','Parent',hPanel,'Units','normalized', ...
    'Position',[0.05 0.02 0.90 0.12],'String',pfOptions,'Max',6,'Min',1, ...
    'FontSize',10,'BackgroundColor','white','Value',5);

% Run Button
uicontrol('Style','pushbutton','Parent',hPanel,'Units','normalized', ...
    'Position',[0.10 0.26 0.80 0.10],'String','RUN', ...
    'FontSize',12,'FontWeight','bold','ForegroundColor','white', ...
    'BackgroundColor',btnBlue,'Callback',@onRun);

% Status
hStatus = uicontrol('Style','text','Parent',hPanel,'Units','normalized', ...
    'Position',[0.05 0.18 0.90 0.06],'String','Ready', ...
    'ForegroundColor',txtCol,'BackgroundColor',panelBg, ...
    'FontSize',10,'HorizontalAlignment','left');

%% Axes
hAx = axes('Parent',hFig,'Units','normalized', ...
    'Position',[0.37 0.1 0.6 0.78], ...
    'Box','on','FontSize',12,'Color',[0.985 0.99 1]);
grid(hAx,'on');

%% RUN CALLBACK
    function onRun(~,~)
        set(hStatus,'String','Running...'); drawnow;
        dataChoices = get(hData,'String'); methodChoices = get(hMethod,'String');
        dataChoice = dataChoices{get(hData,'Value')};
        method = methodChoices{get(hMethod,'Value')};
        plotAll = logical(get(hAllCB,'Value'));
        showLegend = logical(get(hLegendCB,'Value'));

        % Load dataset into base workspace
        try
            evalin('base',[dataChoice ';']);
        catch ME
            errordlg(['Error loading data: ' ME.message],'Data Error');
            set(hStatus,'String','Error loading data'); return;
        end

        % update node list length (default full list) if possible
        try
            nbus = evalin('base','nbus');
            nodeLabels = arrayfun(@(x) sprintf('Node %d',x),1:nbus,'UniformOutput',false);
            set(hNodeList,'String',nodeLabels,'UserData',1:nbus);
        end

        if plotAll
            nodes = 1:evalin('base','nbus');
        else
            sel = get(hNodeList,'Value');
            if isempty(sel)
                errordlg('Please select at least one node.','Node Error');
                set(hStatus,'String','Select a node'); return;
            end
            nodeIDs = get(hNodeList,'UserData');
            if isempty(nodeIDs)
                nodeIDs = 1:evalin('base','nbus');
            end
            nodes = nodeIDs(sel(:)');
        end

        try
            % Handle CPF separately (plots all selected buses at once)
            if strcmpi(method,'CPF')
                % Call CPF function for the selected node(s)
                BusData = evalin('base','BusData');
                BranchData = evalin('base','BranchData');

                % Read parameters from base workspace or use defaults
                try nbus = evalin('base','nbus'); catch, nbus = size(BusData,1); end
                try nbr  = evalin('base','nbr');  catch, nbr  = size(BranchData,1); end
                try ns   = evalin('base','ns');   catch, ns   = 1; end
                try Sbase= evalin('base','Sbase');catch, Sbase=100; end
                try tolerance = evalin('base','accuracy');     catch, tolerance = 1e-6; end
                try maxiterations = evalin('base','maxiter');  catch, maxiterations = 100; end

                % Read selected PF values (apply to loads during CPF)
                pfSelIdx = get(hPFList,'Value');
                pfOptions_val = str2double(get(hPFList,'String'));
                pfSelected = pfOptions_val(pfSelIdx);
                if isempty(pfSelected)
                    pfSelected = 0.9;
                end

                % Clear axes and plot CPF for each selected node and pf
                cla(hAx); hold(hAx,'on');
                colors = lines(max(6,length(nodes)*numel(pfSelected)));
                legendEntries = {};
                
                for ii = 1:length(nodes)
                    bus_to_plot = nodes(ii);
                    
                    % For each selected PF, adjust Q_load at PQ buses and run CPF
                    for pf_idx = 1:numel(pfSelected)
                        pf = pfSelected(pf_idx);
                        c = colors(mod((ii-1)*numel(pfSelected) + (pf_idx-1), size(colors,1)) + 1, :);

                        % Embedded CPF calculation and plot
                        try
                        %% Extract bus data
                        V_mag_final = BusData(:,5);
                        V_ang_final = BusData(:,6);
                        P_load = BusData(:,7);
                        Q_load = BusData(:,8);
                        P_gen = BusData(:,9);
                        Q_gen = BusData(:,10);
                        
                        % Apply PF scaling to PQ bus loads (use load_angle approach)
                        slack = find(BusData(:,4)==1 | BusData(:,4)==3);
                        PQ = find(BusData(:,4)==0);
                        PV = find(BusData(:,4)==2);
                        nslack = length(slack);
                        nPQ = length(PQ);
                        nPV = length(PV);
                        if isfinite(pf) && pf > 0 && pf <= 1
                            load_angle = acos(pf);
                            Q_load(PQ) = P_load(PQ) * tan(load_angle);
                        end
                        
                        %% Classify buses
                        % (already computed above)
                        
                        %% Compute Y-bus matrix
                        [Ybus, Theta, Y_mag, B, G] = compute_YBUS(BusData, BranchData);
                        
                        %% Find connected buses
                        from = BranchData(:,1);
                        to = BranchData(:,2);
                        idx_conn = (from == bus_to_plot) | (to == bus_to_plot);
                        connected_branches = BranchData(idx_conn,:);
                        connected_buses = unique([connected_branches(:,1); connected_branches(:,2)]);
                        connected_buses(connected_buses == bus_to_plot) = [];
                        
                        %% Initialize CPF
                        P_sch = P_gen - P_load;
                        Q_sch = Q_gen - Q_load;
                        V_mag = V_mag_final;
                        V_Delta = V_ang_final;
                        Lambda = 0;
                        CPF_prediction = [V_Delta(2:end); V_mag(PQ); Lambda];
                        CPF_correction = [V_Delta(2:end); V_mag(PQ); Lambda];
                        nVar = (nbus-1) + nPQ;
                        
                        %% Phase 1: Upper PV curve
                        while 1
                            sigma = 0.01;
                            K = [P_sch(2:end); Q_sch(PQ)];
                            [P_cal, Q_cal] = cal_PQ(V_mag, Y_mag, Theta, V_Delta, nbus);
                            [J] = Jacobian_matrix(V_mag, P_cal, Q_cal, Y_mag, Theta, V_Delta, nbus, PQ, nPQ, B, G);
                            
                            ek = zeros(1, nVar+1);
                            ek(end) = 1;
                            J_extended = [J, -K; ek];
                            predict_vector = [V_Delta(2:end); V_mag(PQ); Lambda] + sigma*(J_extended\ek');
                            
                            ang_end = nbus-1;
                            V_Delta(2:end) = predict_vector(1:ang_end);
                            V_mag(PQ) = predict_vector(ang_end+1:ang_end+nPQ);
                            Lambda = predict_vector(end);
                            CPF_prediction = [CPF_prediction predict_vector];
                            
                            %% Corrector
                            tol_max = 0.001;
                            iter = 0;
                            tol = 1;
                            P_sch = (1+Lambda)*(P_gen-P_load);
                            Q_sch = (1+Lambda)*(Q_gen-Q_load);
                            
                            while tol > tol_max && iter < 100
                                [P_cal, Q_cal] = cal_PQ(V_mag, Y_mag, Theta, V_Delta, nbus);
                                [dif_PQ] = difference_PQ(P_sch, Q_sch, P_cal, Q_cal, PQ, nPQ);
                                [J] = Jacobian_matrix(V_mag, P_cal, Q_cal, Y_mag, Theta, V_Delta, nbus, PQ, nPQ, B, G);
                                
                                dif_Voltage = J\dif_PQ;
                                dif_D = dif_Voltage(1:nbus-1);
                                dif_V = dif_Voltage(nbus:nbus+nPQ-1);
                                
                                V_Delta(2:end) = V_Delta(2:end) + dif_D;
                                V_mag(PQ) = V_mag(PQ) + dif_V;
                                tol = max(abs(dif_PQ));
                                iter = iter + 1;
                            end
                            
                            correct_vector = [V_Delta(2:end); V_mag(PQ); Lambda];
                            CPF_correction = [CPF_correction correct_vector];
                            
                            if iter >= 10
                                CPF_correction(:,end) = [];
                                CPF_prediction(:,end) = [];
                                break;
                            end
                        end
                        
                        CPF_correction(:,end) = [];
                        CPF_prediction(:,end) = [];
                        V_Delta(2:end) = CPF_correction(1:nbus-1,end);
                        V_mag(PQ) = CPF_correction(nbus:nbus+nPQ-1,end);
                        Lambda = CPF_correction(end,end);
                        P_sch = (1+Lambda)*(P_gen-P_load);
                        Q_sch = (1+Lambda)*(Q_gen-Q_load);
                        
                        %% Phase 2: Near the nose of the curve
                        counter = 0;
                        while 1
                            sigma = 0.005;
                            K = [P_sch(2:end); Q_sch(PQ)];
                            [P_cal, Q_cal] = cal_PQ(V_mag, Y_mag, Theta, V_Delta, nbus);
                            [J] = Jacobian_matrix(V_mag, P_cal, Q_cal, Y_mag, Theta, V_Delta, nbus, PQ, nPQ, B, G);
                            
                            ek = zeros(1, nVar+1);
                            posPQ = find(PQ==bus_to_plot, 1);
                            
                            if isempty(posPQ)
                                if nPQ > 0
                                    posPQ = 1;
                                else
                                    ek(end) = 1;
                                    J_extended = [J, -K; ek];
                                    ZerosOne = [zeros(nVar,1); 1];
                                    predict_vector = [V_Delta(2:end); V_mag(PQ); Lambda] + sigma*(J_extended\ZerosOne);
                                    ang_end = nbus-1;
                                    V_Delta(2:end) = predict_vector(1:ang_end);
                                    V_mag(PQ) = predict_vector(ang_end+1:ang_end+nPQ);
                                    Lambda = predict_vector(end);
                                    CPF_prediction = [CPF_prediction predict_vector];
                                    continue;
                                end
                            end
                            
                            ek(nbus-1 + posPQ) = -1;
                            J_extended = [J, -K; ek];
                            ZerosOne = [zeros(nVar,1); 1];
                            predict_vector = [V_Delta(2:end); V_mag(PQ); Lambda] + sigma*(J_extended\ZerosOne);
                            
                            ang_end = nbus-1;
                            V_Delta(2:end) = predict_vector(1:ang_end);
                            V_mag(PQ) = predict_vector(ang_end+1:ang_end+nPQ);
                            Lambda = predict_vector(end);
                            CPF_prediction = [CPF_prediction predict_vector];
                            
                            %% Corrector Phase 2
                            tol_max = 0.01;
                            iter = 0;
                            tol = 1;
                            
                            while tol > tol_max && iter < 100
                                P_sch = (1+Lambda)*(P_gen-P_load);
                                Q_sch = (1+Lambda)*(Q_gen-Q_load);
                                [P_cal, Q_cal] = cal_PQ(V_mag, Y_mag, Theta, V_Delta, nbus);
                                [dif_PQ] = difference_PQ(P_sch, Q_sch, P_cal, Q_cal, PQ, nPQ);
                                [J] = Jacobian_matrix(V_mag, P_cal, Q_cal, Y_mag, Theta, V_Delta, nbus, PQ, nPQ, B, G);
                                
                                JPh2 = [J, -Lambda*K; ek];
                                RHS = [dif_PQ; 0];
                                X = JPh2\RHS;
                                
                                dif_D = X(1:nbus-1);
                                dif_V = X(nbus:nbus+nPQ-1);
                                
                                V_Delta(2:end) = V_Delta(2:end) + dif_D;
                                V_mag(PQ) = V_mag(PQ) + dif_V;
                                Lambda = Lambda + X(end);
                                
                                tol = max(abs(dif_PQ));
                                iter = iter + 1;
                            end
                            
                            correct_vector = [V_Delta(2:end); V_mag(PQ); Lambda];
                            CPF_correction = [CPF_correction correct_vector];
                            
                            if iter >= 100
                                CPF_correction(:,end) = [];
                                CPF_prediction(:,end) = [];
                                break;
                            end
                            
                            if CPF_correction(end,end) < CPF_correction(end,end-1)
                                counter = counter + 1;
                            end
                            if counter == 105
                                break;
                            end
                        end
                        
                        %% Phase 3: Lower PV curve
                        while 1
                            sigma = 0.001;
                            K = [P_sch(2:end); Q_sch(PQ)];
                            [P_cal, Q_cal] = cal_PQ(V_mag, Y_mag, Theta, V_Delta, nbus);
                            [J] = Jacobian_matrix(V_mag, P_cal, Q_cal, Y_mag, Theta, V_Delta, nbus, PQ, nPQ, B, G);
                            
                            ek = zeros(1, nVar+1);
                            ek(end) = 1;
                            ekv = zeros(1, nVar+1);
                            ekv(nbus-1 + posPQ) = 1;
                            J_extended = [J, -K; ekv];
                            
                            predict_vector = [V_Delta(2:end); V_mag(PQ); Lambda] + sigma*(J_extended\ek');
                            ang_end = nbus-1;
                            V_Delta(2:end) = predict_vector(1:ang_end);
                            V_mag(PQ) = predict_vector(ang_end+1:ang_end+nPQ);
                            Lambda = predict_vector(end);
                            CPF_prediction = [CPF_prediction predict_vector];
                            
                            %% Corrector Phase 3
                            tol_max = 0.00001;
                            iter = 0;
                            tol = 1;
                            
                            while tol > tol_max && iter < 100
                                P_sch = (1+Lambda)*(P_gen-P_load);
                                Q_sch = (1+Lambda)*(Q_gen-Q_load);
                                [P_cal, Q_cal] = cal_PQ(V_mag, Y_mag, Theta, V_Delta, nbus);
                                [dif_PQ] = difference_PQ(P_sch, Q_sch, P_cal, Q_cal, PQ, nPQ);
                                [J] = Jacobian_matrix(V_mag, P_cal, Q_cal, Y_mag, Theta, V_Delta, nbus, PQ, nPQ, B, G);
                                
                                JExt = [J, -Lambda*K; ekv];
                                RHS = [dif_PQ; 0];
                                X = JExt\RHS;
                                
                                dif_D = X(1:nbus-1);
                                dif_V = X(nbus:nbus+nPQ-1);
                                
                                V_Delta(2:end) = V_Delta(2:end) + dif_D;
                                V_mag(PQ) = V_mag(PQ) + dif_V;
                                Lambda = Lambda + X(end);
                                
                                tol = max(abs(dif_PQ));
                                iter = iter + 1;
                            end
                            
                            correct_vector = [V_Delta(2:end); V_mag(PQ); Lambda];
                            CPF_correction = [CPF_correction correct_vector];
                            
                            if iter >= 100
                                CPF_correction(:,end) = [];
                                CPF_prediction(:,end) = [];
                                break;
                            end
                        end
                        
                        %% Plot to GUI axes
                        posPQ = find(PQ==bus_to_plot, 1);
                        if ~isempty(posPQ)
                            rowIdx = (nbus-1) + posPQ;
                            plot(hAx, CPF_correction(end,:)/1.8, CPF_correction(rowIdx,:), '.-', 'LineWidth', 1.8, 'Color', c);
                        else
                            if nPQ > 0
                                plot(hAx, CPF_correction(end,:)/1.8, CPF_correction(nbus,:), '.-', 'LineWidth', 1.8, 'Color', c);
                            else
                                plot(hAx, CPF_correction(end,:)/1.8, CPF_correction(1,:), '.-', 'LineWidth', 1.8, 'Color', c);
                            end
                        end
                        
                        if showLegend
                            legendEntries{end+1} = sprintf('Bus %d (PF=%.2f)', bus_to_plot, pf);
                        end
                        
                    catch ME
                        errordlg(['CPF Error for Bus ' num2str(bus_to_plot) ' (PF=' num2str(pf) '): ' ME.message],'CPF Error');
                        set(hStatus,'String','CPF error');
                        return;
                    end
                    end % pf loop
                end
                
                xlabel(hAx,'Load Parameter Lambda'); 
                ylabel(hAx,'Voltage Magnitude (pu)');
                title(hAx,sprintf('CPF Curves (Data: %s)',dataChoice));
                
                if showLegend && ~isempty(legendEntries)
                    legend(hAx,legendEntries,'Location','bestoutside');
                end
                
                grid(hAx,'on'); 
                hold(hAx,'off');
                set(hStatus,'String','CPF executed (plotted in app)');
                
            else
                % PVcurve and QVcurve - plot in loop
                cla(hAx); hold(hAx,'on');
                colors = lines(max(6,length(nodes)));
                legendEntries = {};
                
            for ii = 1:length(nodes)
                Bto = nodes(ii);
                c = colors(mod(ii-1,size(colors,1))+1,:);
                if strcmpi(method,'PVcurve') 
                    [Ppv,V21,V22,connected_buses] = PVcurve(Bto,false);
                    for k = 1:size(V21,2)
                            % Get selected power factors
                            pfSelIdx = get(hPFList,'Value');
                            pfOptions_val = str2double(get(hPFList,'String'));
                            pfSelected = pfOptions_val(pfSelIdx);
                        
                            if isscalar(pfSelected)
                                pfSelected = pfSelected;
                            end

                            % For each selected power factor, plot a PV curve
                            if isempty(pfSelected)
                                pfSelected = 0.9;
                            end
                            for pf_idx = 1:length(pfSelected)
                                pf = pfSelected(pf_idx);
                                [Ppv_pf,V21_pf,V22_pf,~] = PVcurve(Bto, [], false, pf);
                                % PF scaling applied inside PVcurve; plot directly
                                plot(hAx,Ppv_pf,V21_pf(:,k),'LineWidth',1.8,'Color',c);
                                plot(hAx,Ppv_pf,V22_pf(:,k),'--','LineWidth',1.2,'Color',c);
                                if showLegend
                                    if isempty(pf) || abs(pf - 0.9) < 1e-9
                                        legendEntries{end+1} = sprintf('N%d - %d High',Bto,connected_buses(k));
                                        legendEntries{end+1} = sprintf('N%d - %d Low' ,Bto,connected_buses(k));
                                    else
                                        legendEntries{end+1} = sprintf('N%d - %d (PF=%.2f) High',Bto,connected_buses(k),pf);
                                        legendEntries{end+1} = sprintf('N%d - %d (PF=%.2f) Low' ,Bto,connected_buses(k),pf);
                                    end
                                end
                        end
                    end
                    xlabel(hAx,'Active Power P (pu)'); ylabel(hAx,'Voltage V (pu)');
                    title(hAx,sprintf('PV Curves (Data: %s)',dataChoice));

                elseif strcmpi(method,'QVcurve')
                    % Plot only net Q(V) for selected PF values using BusData
                    pfSelIdx = get(hPFList,'Value');
                    pfOptions_val = str2double(get(hPFList,'String'));
                    pfSelected = pfOptions_val(pfSelIdx);
                    if isempty(pfSelected)
                        pfSelected = 0.9;
                    end
                    pfColors = lines(max(1,numel(pfSelected)));
                    for pf_idx = 1:numel(pfSelected)
                        pf = pfSelected(pf_idx);
                        [Vrange_pf,~,~,~,Qtotal] = QVcurve(Bto,evalin('base','BusData'),false,pf);
                        if ~isempty(Qtotal)
                            colPF = pfColors(mod(pf_idx-1,size(pfColors,1))+1,:);
                            plot(hAx,Vrange_pf,Qtotal,'--','LineWidth',2.2,'Color',colPF);
                            if showLegend
                                legendEntries{end+1} = sprintf('N%d Net (PF=%.2f)',Bto,pf);
                            end
                        end
                    end
                    xlabel(hAx,'Voltage V (pu)'); ylabel(hAx,'Reactive Power Q (pu)');
                    title(hAx,sprintf('QV Curves (Data: %s)',dataChoice));

                end
            end

            if showLegend && ~isempty(legendEntries)
                legend(hAx,legendEntries,'Location','bestoutside');
            end

            grid(hAx,'on'); hold(hAx,'off');
            end  % end of else block for PVcurve/QVcurve
            
            set(hStatus,'String','Done');

        catch ME
            errordlg(['Execution Error: ' ME.message],'Error');
            set(hStatus,'String','Error during run');
        end
    end

    function onMethodChange(~,~)
        % Optional: add any method-specific GUI adjustments here
    end
    
end