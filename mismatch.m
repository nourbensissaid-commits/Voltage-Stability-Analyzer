function [Pcalc,Qcalc,dP,dQ,dPred,dQred,dPdQred]=mismatch(V,d,Ybus,Psch,Qsch,posSL,posPV)
Scalc=conj( V.*exp(1i*d)).*(Ybus*(V.*exp(1i*d)));
Pcalc=real(Scalc);
Qcalc=-imag(Scalc);
dP=Psch-Pcalc;
dQ=Qsch-Qcalc;
dPred=dP(posSL==0);
dQred=dQ(posSL+posPV==0);
dPdQred=[dPred;dQred];
