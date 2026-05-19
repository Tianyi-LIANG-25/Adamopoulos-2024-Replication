% This subroutine search for parameter values by using the particle swarm
% algorithm.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

if case_id == 1 % baseline calibration


    i = 0;

    % 1 P.omega
    i = i+1;
    LB(i) = 0.27;
    UB(i) = 0.35;

    % 2 P.sigma_sH
    i = i+1;
    LB(i) = 0.53;
    UB(i) = 0.61;

    % 3 P.sigma_hH
    i = i+1;
    LB(i) = 0.69;
    UB(i) = 0.77;

    % 4 ratio: H to I
    i = i+1;
    LB(i) = 0.48;
    UB(i) = 0.56;

    % 5 P.sigma_tauy
    i = i+1;
    LB(i) = 0.23;
    UB(i) = 0.30;

    % 6 P.zeta_tauy
    i = i+1;
    LB(i) = -0.90;
    UB(i) = -0.82;

    % 7 P.sigma_xi
    i = i+1;
    LB(i) = 0.57;
    UB(i) = 0.65;

    % 8 P.mu_xiu_y
    i = i+1;
    LB(i) = 0.36;
    UB(i) = 0.43;

    % 9 P.sigma_varphi
    i = i+1;
    LB(i) = 0.35;
    UB(i) = 0.44;

    % 10 P.mu_varphi
    i = i+1;
    LB(i) = 2.20;
    UB(i) = 2.36;

    % 11 P.c_pt_u
    i = i+1;
    LB(i) = 0.065;
    UB(i) = 0.10;

    % 12 P.kappa
    i = i+1;
    LB(i) = 1.032;
    UB(i) = 1.044;

    % 13 P.cbar
    i = i+1;
    LB(i) = 0.17;
    UB(i) = 0.23;

    % 14 P.B
    i = i+1;
    LB(i) = 3.5;
    UB(i) = 3.8;


    nvars = i;

    options = optimoptions('particleswarm','SwarmSize',140,'ObjectiveLimit',1e-6,'FunctionTolerance',1e-6,...
        'MaxIterations',30,'Display','iter','UseParallel',true);

    randx0 = LB + rand(1,nvars).*(UB-LB);
    load matfiles/x-baseline.mat;
    x0 = parameter;


    options.InitialSwarmMatrix = x0;

    [X,fval] = particleswarm(@(X) CalibrationComputeMoments(X,case_id),nvars,LB,UB,options);

    parameter = X;
    save matfiles/x-baseline.mat parameter fval


elseif case_id == 2 % 2018 calibration

    i = 0;

    % 1 P.omega
    i = i+1;
    LB(i) = 0.50;
    UB(i) = 0.60;

    % 2 P.sigma_sH
    i = i+1;
    LB(i) = 0.58;
    UB(i) = 0.68;

    % 3 P.sigma_hH
    i = i+1;
    LB(i) = 0.53;
    UB(i) = 0.63;

    % 4 ratio: H to I
    i = i+1;
    LB(i) = 0.69;
    UB(i) = 0.79;

    % 5 P.sigma_tauy
    i = i+1;
    LB(i) = 0.16;
    UB(i) = 0.26;

    % 6 P.zeta_tauy
    i = i+1;
    LB(i) = -0.96;
    UB(i) = -0.85;

    % 7 P.sigma_xi
    i = i+1;
    LB(i) = 0.16;
    UB(i) = 0.27;

    % 8 P.mu_xiu_y
    i = i+1;
    LB(i) = 1.10;
    UB(i) = 1.40;

    % 9 P.sigma_varphi
    i = i+1;
    LB(i) = 1.50;
    UB(i) = 1.65;

    % 10 P.mu_varphi
    i = i+1;
    LB(i) = 2.80;
    UB(i) = 3.10;

    % 11 P.c_pt_u
    i = i+1;
    LB(i) = 0.04;
    UB(i) = 0.09;

    % 12 P.kappa
    i = i+1;
    LB(i) = 0.835;
    UB(i) = 0.875;

    % 13 P.cbar
    i = i+1;
    LB(i) = 0.04;
    UB(i) = 0.12;

    % 14 P.B
    i = i+1;
    LB(i) = 0.35;
    UB(i) = 0.45;

    nvars = i;

    options = optimoptions('particleswarm','SwarmSize',140,'ObjectiveLimit',1e-6,'FunctionTolerance',1e-6,...
        'MaxIterations',100,'Display','iter','UseParallel',true);

    x0 = LB + rand(1,nvars).*(UB-LB);
    load matfiles/x-2018.mat;
    x0 = parameter;
    


    options.InitialSwarmMatrix = x0;

    [X,fval] = particleswarm(@(X) CalibrationComputeMoments(X,case_id),nvars,LB,UB,options);

    parameter = X;
    save matfiles/x-2018.mat parameter fval

elseif case_id == 3 % no eta calibration

    i = 0;

    % 1 P.omega
    i = i+1;
    LB(i) = 0.55;
    UB(i) = 0.65;

    % 2 P.sigma_sI
    i = i+1;
    LB(i) = 0.47;
    UB(i) = 0.57;

    % 3 P.sigma_hH
    i = i+1;
    LB(i) = 0.75;
    UB(i) = 0.90;

    % 4 ratio: H to I
    i = i+1;
    LB(i) = 0.36;
    UB(i) = 0.46;

    % 5 P.sigma_tauy
    i = i+1;
    LB(i) = 0.12;
    UB(i) = 0.28;

    % 6 P.zeta_tauy
    i = i+1;
    LB(i) = -0.97;
    UB(i) = -0.81;

    % 7 P.sigma_xi
    i = i+1;
    LB(i) = 0.15;
    UB(i) = 0.55;

    % 8 P.mu_xiu_y
    i = i+1;
    LB(i) = 1.20;
    UB(i) = 1.55;

    % % 9 P.sigma_varphi
    % i = i+1;
    % LB(i) = 0.35;
    % UB(i) = 0.45;

    % % 10 P.mu_varphi
    % i = i+1;
    % LB(i) = 2.10;
    % UB(i) = 2.35;

    % 11 P.c_pt_u
    i = i+1;
    LB(i) = 0.065;
    UB(i) = 0.10;

    % 12 P.kappa
    i = i+1;
    LB(i) = 1.015;
    UB(i) = 1.035;

    % 13 P.cbar
    i = i+1;
    LB(i) = 0.12;
    UB(i) = 0.22;

    % 14 P.B
    i = i+1;
    LB(i) = 1.25;
    UB(i) = 1.55;


    nvars = i;


    options = optimoptions('particleswarm','SwarmSize',120,'ObjectiveLimit',1e-6,'FunctionTolerance',1e-6,...
        'MaxIterations',30,'Display','iter','UseParallel',true);

    randx0 = LB + rand(1,nvars).*(UB-LB);
    load matfiles/x-noeta.mat;
    x0 = parameter;

    options.InitialSwarmMatrix = x0;


    [X,fval] = particleswarm(@(X) CalibrationComputeMoments(X,case_id),nvars,LB,UB,options);

    parameter = X;
    save matfiles/x-noeta.mat parameter fval

elseif case_id == 4 % 2 nonagr sectors

    i = 0;

    % 1 P.omega
    i = i+1;
    LB(i) = 0.41;
    UB(i) = 0.51;

    % 2 P.sigma_sH
    i = i+1;
    LB(i) = 0.50;
    UB(i) = 0.60;

    % 3 P.sigma_hH
    i = i+1;
    LB(i) = 0.68;
    UB(i) = 0.78;

    % 4 ratio: H to I
    i = i+1;
    LB(i) = 0.41;
    UB(i) = 0.51;

    % 5 P.sigma_tauy
    i = i+1;
    LB(i) = 0.23;
    UB(i) = 0.33;

    % 6 P.zeta_tauy
    i = i+1;
    LB(i) = -0.96;
    UB(i) = -0.84;

    % 7 P.sigma_xi
    i = i+1;
    LB(i) = 0.68;
    UB(i) = 0.90;

    % 8 P.mu_xiu_y
    i = i+1;
    LB(i) = 0.32;
    UB(i) = 0.42;

    % 9 P.mu_xir_y
    i = i+1;
    LB(i) = 0.88;
    UB(i) = 1.02;

    % 10 P.sigma_varphi
    i = i+1;
    LB(i) = 0.38;
    UB(i) = 0.55;

    % 11 P.mu_varphi
    i = i+1;
    LB(i) = 2.10;
    UB(i) = 2.45;

    % 12 P.c_pt_r
    i = i+1;
    LB(i) = 0.04;
    UB(i) = 0.09;

    % 13 P.c_pt_u
    i = i+1;
    LB(i) = 0.070;
    UB(i) = 0.120;

    % 14 P.kappa
    i = i+1;
    LB(i) = 1.028;
    UB(i) = 1.042;

    % 15 P.cbar
    i = i+1;
    LB(i) = 0.12;
    UB(i) = 0.23;

    % 16 P.Au
    i = i+1;
    LB(i) = 0.64;
    UB(i) = 0.77;

    % 17 P.B
    i = i+1;
    LB(i) = 3.50;
    UB(i) = 3.90;

    nvars = i;

    options = optimoptions('particleswarm','SwarmSize',170,'ObjectiveLimit',1e-6,'FunctionTolerance',1e-6,...
        'MaxIterations',30,'Display','iter','UseParallel',true);

    randx0 = LB + rand(1,nvars).*(UB-LB);
    load matfiles/x-2nonagr.mat;
    x0 = parameter;

    options.InitialSwarmMatrix = x0;

    [X,fval] = particleswarm(@(X) CalibrationComputeMoments(X,case_id),nvars,LB,UB,options);

    parameter = X;
    save matfiles/x-2nonagr.mat parameter fval

elseif case_id == 5 % 2 nonagr sectors and age differences

    i = 0;

    % 1 P.omega
    i = i+1;
    LB(i) = 0.32;
    UB(i) = 0.42;

    % 2 P.sigma_sH
    i = i+1;
    LB(i) = 0.54;
    UB(i) = 0.64;

    % 3 P.sigma_hH
    i = i+1;
    LB(i) = 0.70;
    UB(i) = 0.80;

    % 4 ratio: H to I
    i = i+1;
    LB(i) = 0.42;
    UB(i) = 0.52;

    % 5 P.mu_sI_y
    i = i+1;
    LB(i) = 0.09;
    UB(i) = 0.19;

    % 6 P.mu_hI_y
    i = i+1;
    LB(i) = 0.14;
    UB(i) = 0.25;

    % 7 P.sigma_tauy
    i = i+1;
    LB(i) = 0.18;
    UB(i) = 0.28;

    % 8 P.zeta_tauy
    i = i+1;
    LB(i) = -0.94;
    UB(i) = -0.83;

    % 9 P.sigma_xi
    i = i+1;
    LB(i) = 0.55;
    UB(i) = 0.65;

    % 10 P.mu_xiu_y
    i = i+1;
    LB(i) = 0.20;
    UB(i) = 0.30;

    % 11 P.mu_xir_y
    i = i+1;
    LB(i) = 0.78;
    UB(i) = 0.88;

    % 12 P.mu_xiu_o_delta
    i = i+1;
    LB(i) = 0.90;
    UB(i) = 1.30;

    % 13 P.mu_xir_o_delta
    i = i+1;
    LB(i) = 0.35;
    UB(i) = 0.46;

    % 14 P.sigma_varphi
    i = i+1;
    LB(i) = 0.33;
    UB(i) = 0.43;

    % 15 P.mu_varphi
    i = i+1;
    LB(i) = 1.90;
    UB(i) = 2.10;

    % 16 P.c_pt_r
    i = i+1;
    LB(i) = 0.04;
    UB(i) = 0.09;

    % 17 P.c_pt_u
    i = i+1;
    LB(i) = 0.080;
    UB(i) = 0.130;

    % 18 P.kappa
    i = i+1;
    LB(i) = 1.028;
    UB(i) = 1.042;

    % 19 P.cbar
    i = i+1;
    LB(i) = 0.14;
    UB(i) = 0.26;

    % 20 P.Au
    i = i+1;
    LB(i) = 0.69;
    UB(i) = 0.79;

    % 21 P.B
    i = i+1;
    LB(i) = 3.20;
    UB(i) = 4.00;


    nvars = i;

    options = optimoptions('particleswarm','SwarmSize',210,'ObjectiveLimit',1e-6,'FunctionTolerance',1e-6,...
        'MaxIterations',30,'Display','iter','UseParallel',true);

    randx0 = LB + rand(1,nvars).*(UB-LB);
    load matfiles/x-2nonagr-cohort.mat;
    x0 = parameter;

    options.InitialSwarmMatrix = x0;

    [X,fval] = particleswarm(@(X) CalibrationComputeMoments(X,case_id),nvars,LB,UB,options);

    parameter = X;
    save matfiles/x-2nonagr-cohort.mat parameter fval

elseif case_id == 6 % remote

    i = 0;

    % 1 P.omega
    i = i+1;
    LB(i) = 0.34;
    UB(i) = 0.44;

    % 2 P.sigma_sH
    i = i+1;
    LB(i) = 0.52;
    UB(i) = 0.62;

    % 3 P.sigma_hH
    i = i+1;
    LB(i) = 0.66;
    UB(i) = 0.76;

    % 4 ratio: H to I
    i = i+1;
    LB(i) = 0.47;
    UB(i) = 0.57;

    % 5 P.mu_sI_y
    i = i+1;
    LB(i) = 0.11;
    UB(i) = 0.21;

    % 6 P.mu_hI_y
    i = i+1;
    LB(i) = 0.17;
    UB(i) = 0.27;

    % 7 P.sigma_tauy
    i = i+1;
    LB(i) = 0.18;
    UB(i) = 0.28;

    % 8 P.zeta_tauy
    i = i+1;
    LB(i) = -0.94;
    UB(i) = -0.83;

    % 9 P.sigma_xi
    i = i+1;
    LB(i) = 0.53;
    UB(i) = 0.63;

    % 10 P.mu_xiu_y
    i = i+1;
    LB(i) = 0.24;
    UB(i) = 0.34;

    % 11 P.mu_xir_y
    i = i+1;
    LB(i) = 0.85;
    UB(i) = 0.95;

    % 12 P.mu_xiu_o_delta
    i = i+1;
    LB(i) = 1.20;
    UB(i) = 1.40;

    % 13 P.mu_xir_o_delta
    i = i+1;
    LB(i) = 0.38;
    UB(i) = 0.48;

    % 14 P.sigma_varphi
    i = i+1;
    LB(i) = 0.42;
    UB(i) = 0.54;

    % 15 P.mu_varphi
    i = i+1;
    LB(i) = 2.15;
    UB(i) = 2.35;

    % 16 P.c_pt_r
    i = i+1;
    LB(i) = 0.04;
    UB(i) = 0.09;

    % 17 P.c_pt_u
    i = i+1;
    LB(i) = 0.080;
    UB(i) = 0.130;

    % 18 P.kappa
    i = i+1;
    LB(i) = 1.028;
    UB(i) = 1.040;

    % 19 P.cbar
    i = i+1;
    LB(i) = 0.16;
    UB(i) = 0.27;

    % 20 P.Au
    i = i+1;
    LB(i) = 0.74;
    UB(i) = 0.86;

    % 21 P.B
    i = i+1;
    LB(i) = 3.55;
    UB(i) = 3.95;

    nvars = i;

    options = optimoptions('particleswarm','SwarmSize',210,'ObjectiveLimit',1e-6,'FunctionTolerance',1e-6,...
        'MaxIterations',30,'Display','iter','UseParallel',true);

    randx0 = LB + rand(1,nvars).*(UB-LB);
    load matfiles/x-remote.mat;
    x0 = parameter;

    options.InitialSwarmMatrix = x0;

    [X,fval] = particleswarm(@(X) CalibrationComputeMoments(X,case_id),nvars,LB,UB,options);

    parameter = X;
    save matfiles/x-remote.mat parameter fval

elseif case_id == 7 % peri-urban

    i = 0;

    % 1 P.omega
    i = i+1;
    LB(i) = 0.31;
    UB(i) = 0.41;

    % 2 P.sigma_sH
    i = i+1;
    LB(i) = 0.47;
    UB(i) = 0.57;

    % 3 P.sigma_hH
    i = i+1;
    LB(i) = 0.76;
    UB(i) = 0.86;

    % 4 ratio: H to I
    i = i+1;
    LB(i) = 0.43;
    UB(i) = 0.53;

    % 5 P.mu_sI_y
    i = i+1;
    LB(i) = 0.08;
    UB(i) = 0.18;

    % 6 P.mu_hI_y
    i = i+1;
    LB(i) = 0.20;
    UB(i) = 0.30;

    % 7 P.sigma_tauy
    i = i+1;
    LB(i) = 0.16;
    UB(i) = 0.26;

    % 8 P.zeta_tauy
    i = i+1;
    LB(i) = -0.85;
    UB(i) = -0.75;

    % 9 P.sigma_xi
    i = i+1;
    LB(i) = 0.37;
    UB(i) = 0.47;

    % 10 P.mu_xiu_y
    i = i+1;
    LB(i) = 0.29;
    UB(i) = 0.39;

    % 11 P.mu_xir_y
    i = i+1;
    LB(i) = 0.45;
    UB(i) = 0.60;

    % 12 P.mu_xiu_o_delta
    i = i+1;
    LB(i) = 0.78;
    UB(i) = 0.88;

    % 13 P.mu_xir_o_delta
    i = i+1;
    LB(i) = 0.32;
    UB(i) = 0.42;

    % 14 P.sigma_varphi
    i = i+1;
    LB(i) = 0.19;
    UB(i) = 0.31;

    % 15 P.mu_varphi
    i = i+1;
    LB(i) = 1.42;
    UB(i) = 1.58;

    % 16 P.c_pt_r
    i = i+1;
    LB(i) = 0.04;
    UB(i) = 0.10;

    % 17 P.c_pt_u
    i = i+1;
    LB(i) = 0.065;
    UB(i) = 0.120;

    % 18 P.kappa
    i = i+1;
    LB(i) = 1.001;
    UB(i) = 1.025;

    % 19 P.cbar
    i = i+1;
    LB(i) = 0.14;
    UB(i) = 0.26;

    % 20 P.Au
    i = i+1;
    LB(i) = 0.72;
    UB(i) = 0.82;

    % 21 P.B
    i = i+1;
    LB(i) = 2.50;
    UB(i) = 2.70;

    nvars = i;

    options = optimoptions('particleswarm','SwarmSize',210,'ObjectiveLimit',1e-6,'FunctionTolerance',1e-6,...
        'MaxIterations',30,'Display','iter','UseParallel',true);

    randx0 = LB + rand(1,nvars).*(UB-LB);
    load matfiles/x-periurban.mat;
    x0 = parameter;

    options.InitialSwarmMatrix = x0;

    [X,fval] = particleswarm(@(X) CalibrationComputeMoments(X,case_id),nvars,LB,UB,options);

    parameter = X;
    save matfiles/x-periurban.mat parameter fval


elseif case_id == 8 % no xi calibration

    i = 0;

    % 1 P.omega
    i = i+1;
    LB(i) = 0.37;
    UB(i) = 0.47;

    % 2 P.sigma_sH
    i = i+1;
    LB(i) = 0.48;
    UB(i) = 0.58;

    % 3 P.sigma_hH
    i = i+1;
    LB(i) = 0.72;
    UB(i) = 0.82;

    % 4 ratio: H to I
    i = i+1;
    LB(i) = 0.54;
    UB(i) = 0.64;

    % 5 P.sigma_tauy
    i = i+1;
    LB(i) = 0.36;
    UB(i) = 0.46;

    % 6 P.zeta_tauy
    i = i+1;
    LB(i) = -0.985;
    UB(i) = -0.88;

    % % 7 P.sigma_xi
    % i = i+1;
    % LB(i) = 0.51;
    % UB(i) = 0.65;
    %
    % % 8 P.mu_xiu_y
    % i = i+1;
    % LB(i) = 0.38;
    % UB(i) = 0.48;

    % 9 P.sigma_varphi
    i = i+1;
    LB(i) = 0.37;
    UB(i) = 0.45;

    % 10 P.mu_varphi
    i = i+1;
    LB(i) = 3.35;
    UB(i) = 3.55;

    % 11 P.c_pt_u
    i = i+1;
    LB(i) = 0.065;
    UB(i) = 0.10;

    % 12 P.kappa
    i = i+1;
    LB(i) = 1.022;
    UB(i) = 1.040;

    % 13 P.cbar
    i = i+1;
    LB(i) = 0.10;
    UB(i) = 0.20;

    % 14 P.B
    i = i+1;
    LB(i) = 4.5;
    UB(i) = 5.3;

    nvars = i;

    options = optimoptions('particleswarm','SwarmSize',120,'ObjectiveLimit',1e-6,'FunctionTolerance',1e-6,...
        'MaxIterations',30,'Display','iter','UseParallel',true);

    randx0 = LB + rand(1,nvars).*(UB-LB);
    load matfiles/x-noxi.mat;
    x0 = parameter;

    options.InitialSwarmMatrix = x0;

    [X,fval] = particleswarm(@(X) CalibrationComputeMoments(X,case_id),nvars,LB,UB,options);

    parameter = X;
    save matfiles/x-noxi.mat parameter fval

elseif case_id == 9 % no correlation between abilities

    i = 0;

    % % 1 P.omega
    % i = i+1;
    % LB(i) = 0.29;
    % UB(i) = 0.39;

    % 2 P.sigma_sH
    i = i+1;
    LB(i) = 0.54;
    UB(i) = 0.64;

    % 3 P.sigma_hH
    i = i+1;
    LB(i) = 0.68;
    UB(i) = 0.78;

    % 4 ratio: H to I
    i = i+1;
    LB(i) = 0.46;
    UB(i) = 0.56;

    % 5 P.sigma_tauy
    i = i+1;
    LB(i) = 0.22;
    UB(i) = 0.34;

    % 6 P.zeta_tauy
    i = i+1;
    LB(i) = -0.91;
    UB(i) = -0.81;

    % 7 P.sigma_xi
    i = i+1;
    LB(i) = 0.53;
    UB(i) = 0.65;

    % 8 P.mu_xiu_y
    i = i+1;
    LB(i) = 0.38;
    UB(i) = 0.48;

    % 9 P.sigma_varphi
    i = i+1;
    LB(i) = 0.35;
    UB(i) = 0.45;

    % 10 P.mu_varphi
    i = i+1;
    LB(i) = 2.20;
    UB(i) = 2.40;

    % 11 P.c_pt_u
    i = i+1;
    LB(i) = 0.065;
    UB(i) = 0.10;

    % 12 P.kappa
    i = i+1;
    LB(i) = 1.029;
    UB(i) = 1.042;

    % 13 P.cbar
    i = i+1;
    LB(i) = 0.15;
    UB(i) = 0.28;

    % 14 P.B
    i = i+1;
    LB(i) = 3.2;
    UB(i) = 3.8;

    nvars = i;

    options = optimoptions('particleswarm','SwarmSize',130,'ObjectiveLimit',1e-6,'FunctionTolerance',1e-6,...
        'MaxIterations',30,'Display','iter','UseParallel',true);

    randx0 = LB + rand(1,nvars).*(UB-LB);
    load matfiles/x-nocorr.mat;
    x0 = parameter;

    options.InitialSwarmMatrix = x0;


    [X,fval] = particleswarm(@(X) CalibrationComputeMoments(X,case_id),nvars,LB,UB,options);

    parameter = X;
    save matfiles/x-nocorr.mat parameter fval


elseif case_id == 10 % high correlation between abilities

    i = 0;

    % 1 P.omega
    i = i+1;
    LB(i) = 0.35;
    UB(i) = 0.55;

    % 2 P.sigma_sH
    i = i+1;
    LB(i) = 0.50;
    UB(i) = 0.60;

    % 3 P.sigma_hH
    i = i+1;
    LB(i) = 0.70;
    UB(i) = 0.80;

    % 4 ratio: H to I
    i = i+1;
    LB(i) = 0.46;
    UB(i) = 0.56;

    % 5 P.sigma_tauy
    i = i+1;
    LB(i) = 0.21;
    UB(i) = 0.31;

    % 6 P.zeta_tauy
    i = i+1;
    LB(i) = -0.91;
    UB(i) = -0.81;

    % 7 P.sigma_xi
    i = i+1;
    LB(i) = 0.49;
    UB(i) = 0.65;

    % 8 P.mu_xiu_y
    i = i+1;
    LB(i) = 0.32;
    UB(i) = 0.46;

    % 9 P.sigma_varphi
    i = i+1;
    LB(i) = 0.35;
    UB(i) = 0.49;

    % 10 P.mu_varphi
    i = i+1;
    LB(i) = 2.15;
    UB(i) = 2.35;

    % 11 P.c_pt_u
    i = i+1;
    LB(i) = 0.065;
    UB(i) = 0.10;

    % 12 P.kappa
    i = i+1;
    LB(i) = 1.029;
    UB(i) = 1.042;

    % 13 P.cbar
    i = i+1;
    LB(i) = 0.15;
    UB(i) = 0.28;

    % 14 P.B
    i = i+1;
    LB(i) = 3.5;
    UB(i) = 3.9;

    nvars = i;

    options = optimoptions('particleswarm','SwarmSize',140,'ObjectiveLimit',1e-6,'FunctionTolerance',1e-6,...
        'MaxIterations',30,'Display','iter','UseParallel',true);

    randx0 = LB + rand(1,nvars).*(UB-LB);
    load matfiles/x-highcorr.mat;
    x0 = parameter;

    options.InitialSwarmMatrix = x0;

    [X,fval] = particleswarm(@(X) CalibrationComputeMoments(X,case_id),nvars,LB,UB,options);

    parameter = X;
    save matfiles/x-highcorr.mat parameter fval


elseif case_id == 11 % PIGL calibration


    i = 0;

    % 1 P.omega
    i = i+1;
    LB(i) = 0.29;
    UB(i) = 0.39;

    % 2 P.sigma_sH
    i = i+1;
    LB(i) = 0.53;
    UB(i) = 0.61;

    % 3 P.sigma_hH
    i = i+1;
    LB(i) = 0.68;
    UB(i) = 0.76;

    % 4 ratio: H to I
    i = i+1;
    LB(i) = 0.48;
    UB(i) = 0.57;

    % 5 P.sigma_tauy
    i = i+1;
    LB(i) = 0.21;
    UB(i) = 0.30;

    % 6 P.zeta_tauy
    i = i+1;
    LB(i) = -0.90;
    UB(i) = -0.80;

    % 7 P.sigma_xi
    i = i+1;
    LB(i) = 0.57;
    UB(i) = 0.66;

    % 8 P.mu_xiu_y
    i = i+1;
    LB(i) = 0.29;
    UB(i) = 0.39;

    % 9 P.sigma_varphi
    i = i+1;
    LB(i) = 0.36;
    UB(i) = 0.46;

    % 10 P.mu_varphi
    i = i+1;
    LB(i) = 2.24;
    UB(i) = 2.36;

    % 11 P.c_pt_u
    i = i+1;
    LB(i) = 0.065;
    UB(i) = 0.10;

    % 12 P.kappa
    i = i+1;
    LB(i) = 1.033;
    UB(i) = 1.045;

    % 13 P.nu_PIGL
    i = i+1;
    LB(i) = 0.62;
    UB(i) = 0.72;

    % 14 P.B
    i = i+1;
    LB(i) = 2.8;
    UB(i) = 3.1;


    nvars = i;

    options = optimoptions('particleswarm','SwarmSize',140,'ObjectiveLimit',1e-6,'FunctionTolerance',1e-6,...
        'MaxIterations',30,'Display','iter','UseParallel',true);

    randx0 = LB + rand(1,nvars).*(UB-LB);
    load matfiles/x-PIGL.mat;
    x0 = parameter;


    options.InitialSwarmMatrix = x0;

    [X,fval] = particleswarm(@(X) CalibrationComputeMoments(X,case_id),nvars,LB,UB,options);

    parameter = X;
    save matfiles/x-PIGL.mat parameter fval


end



