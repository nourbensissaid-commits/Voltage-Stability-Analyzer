% =========================
% Data_1.m (NORMALIZED)
% =========================

nbus = 3;
npq  = 1;      % bus 3
npv  = 1;      % bus 2
ns   = 1;      % bus 1
nbr  = 2;
Sbase = 100;   % MVA base

maxiterations = 100;
tolerance = 1e-3;

% -------------------------------------------------
% BusData columns:
% [Bus i i Type Vm delta Pd Qd Pg Qg basekv Vref Qmax Qmin QshG QshB remote]
% -------------------------------------------------

BusData = [
    1  1  1  1  1.0     0.0   0.0   0.0   0.0   0.0   0.0  1.0   0.0   0.0   0.0  0.0  0;
    2  1  1  2  1.0007  0.0   0.9   0.0   0.0   0.0   0.0  1.0007  0.0   0.0   0.0  0.0  0;
    3  1  1  0  1.0     0.0   0.5   0.3   0.0   0.0   0.0  1.0   0.0   0.0   0.0  0.0  0
];

% -------------------------------------------------
% BranchData (already in per-unit)
% -------------------------------------------------

BranchData = [
    1  2  1  1  1  0  0.012  0.3  0.066  0  0  0  0  0  1.0  0  0  0  0  0  0;
    1  3  1  1  1  0  0.012  0.3  0.066  0  0  0  0  0  1.0  0  0  0  0  0  0
];

% =========================
% NORMALIZATION (same as Data_2)
% =========================

% Degrees → radians
BusData(:,6) = (BusData(:,6) / 360) * (2*pi);

% MW / MVAR → per-unit
BusData(:,7:10) = BusData(:,7:10) / Sbase;

% Qmax / Qmin → per-unit
BusData(:,13:14) = BusData(:,13:14) / Sbase;
