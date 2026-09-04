function CPF(BusData,BranchData,nbus,nbr,ns,Sbase,tolerance,maxiterations,bus_to_plot, pf)

 V_mag_final=BusData(:,5);
 V_ang_final=BusData(:,6); 
 P_load=BusData(:,7);
 Q_load=BusData(:,8); 
 P_gen=BusData(:,9);
 Q_gen=BusData(:,10);
 Qmax = BusData(:,13);
 Qmin = BusData(:,14);   

 %% type of buses
 slack=find(BusData(:,4)==1|BusData(:,4)==3);
 PQ=find(BusData(:,4)==0);
 PV=find(BusData(:,4)==2); 
 nslack=length(slack);
 nPQ=length(PQ);
 nPV=length(PV);

 %% optional constant power factor for loads (affects Q_load)
 if nargin >= 10 && ~isempty(pf)
     pf_val = pf;
     if ~isscalar(pf_val) || ~isfinite(pf_val) || pf_val <= 0 || pf_val > 1
         error('CPF: pf must be a finite scalar in the range (0,1].');
     end
     % Use load_angle approach like PVcurve: tan(acos(pf)) gives Q/P ratio
     load_angle = acos(pf_val);
     Q_load(PQ) = P_load(PQ) * tan(load_angle);
 end
 %% form Y_matrix
 [Ybus,Theta,Y_mag,B,G] = compute_YBUS(BusData,BranchData);

 %% Find buses connected to bus_to_plot
from = BranchData(:,1);
to   = BranchData(:,2);

idx_conn = (from == bus_to_plot) | (to == bus_to_plot);
connected_branches = BranchData(idx_conn,:);

connected_buses = unique([ ...
    connected_branches(:,1); ...
    connected_branches(:,2)]);
connected_buses(connected_buses == bus_to_plot) = [];
X_ij = connected_branches(:,8);  
bus_j = connected_buses(:);


%% initialize parameters
P_sch=P_gen-P_load; 
Q_sch=Q_gen-Q_load;
V_mag = V_mag_final;  
V_Delta = V_ang_final;   
Lambda=0;
CPF_prediction=[V_Delta(2:end);V_mag(PQ); Lambda];
CPF_correction=[V_Delta(2:end);V_mag(PQ); Lambda]; 
nSteps = size(CPF_correction,2);
nConn  = length(bus_j);

Pij_hist = zeros(nConn, nSteps);
Vi_hist  = zeros(1, nSteps);


%% phase 1 upper part of PV curve
%predictor
while 1
    sigma=0.01;
    K=[P_sch(2:end);Q_sch(PQ)];
    [P_cal,Q_cal]=cal_PQ(V_mag,Y_mag,Theta,V_Delta,nbus);    
    [J]=Jacobian_matrix(V_mag,P_cal,Q_cal,Y_mag,Theta, V_Delta,nbus,PQ,nPQ,B,G); 
    nVar = (nbus-1) + nPQ;
    ek=zeros(1,nVar+1);
    ek(end)=1; 
    J_extended=[J, -K; ek];
    predict_vector=[V_Delta(2:end);V_mag(PQ); Lambda] + sigma*(J_extended\ek');  
 
    ang_end = nbus-1;
    V_Delta(2:end) = predict_vector(1:ang_end);
    V_mag(PQ) = predict_vector(ang_end+1 : ang_end + nPQ);
   Lambda=predict_vector(end);
   CPF_prediction=[CPF_prediction predict_vector];  

 %corrector

 tol_max=0.001;
 iter=0; 
 tol=1; 
  P_sch=(1+Lambda)*(P_gen-P_load);
  Q_sch=(1+Lambda)*(Q_gen-Q_load);
 while (tol>tol_max && iter<100)    
    [P_cal,Q_cal]=cal_PQ(V_mag,Y_mag,Theta,V_Delta,nbus);      
    [dif_PQ]=difference_PQ(P_sch,Q_sch,P_cal,Q_cal,PQ,nPQ); 
    [J]=Jacobian_matrix(V_mag,P_cal,Q_cal,Y_mag,Theta, V_Delta,nbus,PQ,nPQ,B,G);

    dif_Voltage = J\dif_PQ; 
    dif_D = dif_Voltage(1:nbus-1); 
    dif_V = dif_Voltage(nbus:nbus+nPQ-1);

    V_Delta(2:end)=V_Delta(2:end)+dif_D; 
    V_mag(PQ)=V_mag(PQ)+dif_V;
    tol=max(abs(dif_PQ));
    iter=iter+1;
 end
correct_vector=[V_Delta(2:end);V_mag(PQ); Lambda];
CPF_correction =[CPF_correction correct_vector];
 if iter>=10
       CPF_correction(:,end)=[]; 
       CPF_prediction(:,end)=[]; 
       break;
 end 
 end
CPF_correction(:,end)=[]; 
CPF_prediction(:,end)=[];
V_Delta(2:end)=CPF_correction(1:nbus-1,end);
V_mag(PQ)=CPF_correction(nbus:nbus+nPQ-1,end);
Lambda=CPF_correction(end,end);
P_sch = (1+Lambda)*(P_gen-P_load);  
Q_sch = (1+Lambda)*(Q_gen-Q_load);  


%% phase 2  near the tip of the nose curve--switch from changing lamda to V
 counter=0;
while 1
    sigma=0.005;
    K=[P_sch(2:end);Q_sch(PQ)];    
    [P_cal,Q_cal]=cal_PQ(V_mag,Y_mag,Theta,V_Delta,nbus);   
    [J]=Jacobian_matrix(V_mag,P_cal,Q_cal,Y_mag,Theta, V_Delta,nbus,PQ,nPQ,B,G);
   nVar = (nbus-1) + nPQ;
   
   ek = zeros(1, nVar+1);
   
   posPQ = find(PQ==bus_to_plot,1);
   
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
           V_mag(PQ) = predict_vector(ang_end+1 : ang_end + nPQ);
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
    V_mag(PQ) = predict_vector(ang_end+1 : ang_end + nPQ);
   Lambda=predict_vector(end);
   CPF_prediction=[CPF_prediction predict_vector];  

%% corrector--solve power flow equations by NR method
tol_max=0.01; 
 iter=0; 
 tol=1;

 while (tol>tol_max && iter<100)
     P_sch=(1+Lambda)*(P_gen-P_load);
     Q_sch=(1+Lambda)*(Q_gen-Q_load);
    [P_cal,Q_cal]=cal_PQ(V_mag,Y_mag,Theta,V_Delta,nbus); 
    [dif_PQ]=difference_PQ(P_sch,Q_sch,P_cal,Q_cal,PQ,nPQ);
    [J]=Jacobian_matrix(V_mag,P_cal,Q_cal,Y_mag,Theta, V_Delta,nbus,PQ,nPQ,B,G);


    JPh2 = [J, -Lambda*K; ek];
    RHS = [dif_PQ; 0];
    X = JPh2\RHS;

    dif_D = X(1:nbus-1);
    dif_V = X(nbus:nbus+nPQ-1);

    V_Delta(2:end) = V_Delta(2:end) + dif_D;
    V_mag(PQ) = V_mag(PQ) + dif_V;
    Lambda = Lambda + X(end);

    tol=max(abs(dif_PQ));
    iter=iter+1;
 end
correct_vector=[V_Delta(2:end);V_mag(PQ); Lambda];
CPF_correction =[CPF_correction correct_vector];

 if iter>=100
       CPF_correction(:,end)=[]; 
       CPF_prediction(:,end)=[]; 
       break;
 end 

 if CPF_correction(end,end)<CPF_correction(end,end-1)
    counter=counter+1;
 end
    if counter ==100
        break;
    end
end

%% Lower PV Curve (Part 3) - Follow the descending side of the curve
while 1
    sigma = 0.001;  
    K=[P_sch(2:end);Q_sch(PQ)];    
    [P_cal,Q_cal]=cal_PQ(V_mag,Y_mag,Theta,V_Delta,nbus);    
    [J]=Jacobian_matrix(V_mag,P_cal,Q_cal,Y_mag,Theta, V_Delta,nbus,PQ,nPQ,B,G);
    nVar = (nbus-1) + nPQ;
    ek = zeros(1, nVar+1);
    ek(end) = 1;
    ekv = zeros(1, nVar+1);
   
    ekv(nbus-1 + posPQ) = 1;
    J_extended = [J, -K; ekv]; 

    predict_vector = [V_Delta(2:end); V_mag(PQ); Lambda] + sigma*(J_extended\ek');  
    ang_end = nbus-1;
    V_Delta(2:end) = predict_vector(1:ang_end);
    V_mag(PQ) = predict_vector(ang_end+1 : ang_end + nPQ);
   Lambda=predict_vector(end);
   CPF_prediction=[CPF_prediction predict_vector];  

%% corrector--solve power flow equations by NR method
tol_max=0.00001;
 iter=0;
 tol=1;

 while (tol>tol_max && iter<100)
     P_sch=(1+Lambda)*(P_gen-P_load); 
     Q_sch=(1+Lambda)*(Q_gen-Q_load);
    [P_cal,Q_cal]=cal_PQ(V_mag,Y_mag,Theta,V_Delta,nbus);   
    [dif_PQ]=difference_PQ(P_sch,Q_sch,P_cal,Q_cal,PQ,nPQ);
    [J]=Jacobian(V_mag,P_cal,Q_cal,Y_mag,Theta, V_Delta,nbus,PQ,nPQ,B,G);

    JExt = [J, -Lambda*K; ekv];
    RHS = [dif_PQ; 0];
    X = JExt\RHS;

    dif_D = X(1:nbus-1);
    dif_V = X(nbus:nbus+nPQ-1);

    V_Delta(2:end) = V_Delta(2:end) + dif_D;
    V_mag(PQ) = V_mag(PQ) + dif_V;
    Lambda = Lambda + X(end);

    tol=max(abs(dif_PQ));
    iter=iter+1;
 end
correct_vector=[V_Delta(2:end);V_mag(PQ); Lambda];
CPF_correction =[CPF_correction correct_vector];

 if iter>=100
       CPF_correction(:,end)=[]; 
       CPF_prediction(:,end)=[]; 
       break;
 end 


end

%% Plot PV Curve

if nPQ > 0
    posPQ = find(PQ==bus_to_plot,1);
    if ~isempty(posPQ)
        rowIdx = (nbus-1) + posPQ;
        figure;
        plot(CPF_correction(end,:), CPF_correction(rowIdx,:), '.-');
        xlabel('Lambda');
        ylabel(sprintf('Voltage magnitude of bus %d (pu)', bus_to_plot));
        title(sprintf('Complete PV Curve for Bus %d', bus_to_plot));
        grid on;
    else
        % Bus is PV or slack - plot first PQ bus voltage
        figure;
        plot(CPF_correction(end,:), CPF_correction(nbus,:), '.-');
        xlabel('Lambda');
        ylabel(sprintf('Voltage magnitude of first PQ bus (pu)'));
        title(sprintf('CPF Curve', bus_to_plot));
        grid on;
    end
else
    figure;
    plot(CPF_correction(end,:), CPF_correction(1,:), '.-');
    xlabel('Lambda');
    ylabel('Voltage magnitude (pu)');
    title('Complete PV Curve (no PQ buses available)');
    grid on;
end

end
