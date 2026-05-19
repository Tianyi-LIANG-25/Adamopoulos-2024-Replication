% This is the main code that reads subroutines to compute model moments.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024



rng("default");


%% Define the parameter values


if calibration == 1
    % Search for the parameter values (calibration)
    particleSwarmOpt
else
    % If we want to use existing parameter values:
    if case_id == 1
        load matfiles/x-baseline.mat
    elseif case_id == 2
        load matfiles/x-2018.mat
    elseif case_id == 3
        load matfiles/x-noeta.mat
    elseif case_id == 4
        load matfiles/x-2nonagr.mat
    elseif case_id == 5
        load matfiles/x-2nonagr-cohort.mat
    elseif case_id == 6
        load matfiles/x-remote.mat
    elseif case_id == 7
        load matfiles/x-periurban.mat
    elseif case_id == 8
        load matfiles/x-noxi.mat
    elseif case_id == 9
        load matfiles/x-nocorr.mat
    elseif case_id == 10
        load matfiles/x-highcorr.mat
    elseif case_id == 11
        load matfiles/x-PIGL.mat
    end
    X = parameter;
end

assignParameterValue



% load parameters that do not depend on the general equilibrium
parameterExo

if counterfactual == 1 || counterfactual == 4 || counterfactual == 7 % Land security
    P.mu_varphi    = -999;
    P.sigma_varphi = 0.0001;
elseif counterfactual == 5 % 2018 land security
    P.mu_eta       = 0.007875;
    P.mu_varphi    = 2.6346;
elseif counterfactual == 6 % 2018 labor mobility barriers
    P.mu_xiu_y     = 1.2642;
    P.sigma_xir    = 0.2000;
    P.sigma_xiu    = 0.2000;
end


%% Simulate individuals with different abilities


% Draw quasi random numbers
HA    = haltonset(30,'skip',1e7,'Leap',0);
HA    = HA(1:P.N_sim,:);

dummy_old = HA(:,1:3)<P.old;

% Call subroutine to generate ability distribution and mobility barriers
ability

if counterfactual == 2 || counterfactual == 7 % No labor mobility barriers
    ind_xir = zeros(P.N_sim,P.N_ind)+rand(P.N_sim,P.N_ind)*0.001;
    ind_xiu = zeros(P.N_sim,P.N_ind)+rand(P.N_sim,P.N_ind)*0.001;
end

% Output wedges

ind_tauy_epsilon = exp(norminv(HA(:,(P.N_ind-1)*5+11),-P.sigma_tauy^2/2,P.sigma_tauy));
ind_tauy     = ind_s.^P.zeta_tauy.*ind_tauy_epsilon;
ind_tauy     = ind_tauy./exp(mean(log(ind_tauy)));
if counterfactual == 3 || counterfactual == 4 % No static misallocation
    ind_tauy     = ones(P.N_sim,P.N_ind);
end
ind_s_tilde  = (ind_s.*ind_tauy).^(1/(1-P.gamma));
ind_s_tilde2 = (ind_s.*ind_tauy).^(1/(1-P.gamma*(1-P.theta)));

ind_taul     = ones(P.N_sim,P.N_ind);

% Land frictions

hh_eta       = ones(P.N_sim,1)*P.mu_eta;
dummy_expropriation = (HA(:,(P.N_ind-1)*5+13)<hh_eta);

% Currently we set lambda = eta (residual parameter in the code)

hh_lambda    = hh_eta;
dummy_expropriation_2 = (HA(:,(P.N_ind-1)*5+14)<hh_lambda);

hh_varphi    = exp(norminv(HA(:,(P.N_ind-1)*5+15),P.mu_varphi-P.sigma_varphi^2/2,...
    P.sigma_varphi));

% Land endowments
l_bar        = ones(P.N_sim,1)*P.LS;


%% Solve the equilibrium

options = optimoptions('lsqnonlin','FunctionTolerance',1e-15,'OptimalityTolerance',1e-10,...
    'StepTolerance',1e-7,'Display','off','MaxFunctionEvaluations',1000);

LB = [0,0,0];
UB = [5,5,5];

if counterfactual == 7
    x0 = [2,1,1]; % Need a different starting point for the algorithm to converge
else
    x0 = [0.5,0.50,0.30];
end

[x,fval_price] = lsqnonlin(@(X) ...
    solveEquilibriumVector(X,P,ind_h,ind_xiu,ind_xir,ind_s,...
    ind_s_tilde,ind_s_tilde2,ind_tauy,ind_taul,hh_eta,hh_lambda,...
    hh_varphi,l_bar,case_id),x0,LB,UB,options);
X=x;

fval_eq = fval_price;

if fval_price > 0.001

    error_price = 1;
    ite_price   = 0;
    fval_bench  = fval_price;

    while error_price == 1 && ite_price <= 1

        ite_price = ite_price + 1;

        x0 = LB + rand(1,3).*(UB-LB);


        [x2,fval_price2] = lsqnonlin(@(X) ...
            solveEquilibriumVector(X,P,ind_h,ind_xiu,ind_xir,ind_s,...
            ind_s_tilde,ind_s_tilde2,ind_tauy,ind_taul,hh_eta,hh_lambda,...
            hh_varphi,l_bar,case_id),x0,LB,UB,options);

        if fval_price2 < 0.001
            error_price = 0;
        end

        if fval_price2 < fval_bench
            X = x2;
            fval_bench = fval_price2;
        end
    end
end



p     = X(1);
q     = X(2);
wa    = X(3);

pr   = 1;
pu   = 1;

wu   = P.Au*pu;
wr   = P.Ar*pr;



% Solve for occupational choices for individuals and families
occupationalChoice % call the subroutine

% Markets Clearing
landLaborMarket % call the subroutine

% Revenue from wedges and distortions
taxRevenue % call the subroutine

% Agricultural goods market
agrMarket

% Non-agricultural problem and national account
nonAgrProblem


%% Calculate moments for calibration

sectoralShare

familyStatistics

stdIncRural
stdIncNonagr

corrPiLS
corrPiRural
corrRuralUrban

incDiffNonagrMigration
incDiffSectorYO
incDiffSector
incDiffYO
aveHourPT
agrProductionMoment

if case_id ~= 2
    corrIncLSPT1
elseif case_id == 2
    corrIncLSPT2 % for 2018 we calculate correlation coefficient for a different group
end



%% Report moments for calibration and experiments


medianAbility


if counterfactual == 0
    baseline_agr_LP        = (AD_a+AS_a)/2/agr_emp_share_cond;
    baseline_agr_output    = (AD_a+AS_a)/2;
    baseline_nonagr_output = (AD_n+AS_n)/2;
    baseline_p             = p;
    baseline_GDP_las       = ((AD_a+AS_a)/2*baseline_p+(AD_n+AS_n)/2);
    baseline_median_TFPQ   = median_TFPQ;
    baseline_median_u      = median_u;
    baseline_welfare       = P.phi*log(baseline_agr_output/(P.N_ind+P.Nn_r+P.Nn_u)-P.cbar) ...
        + (1-P.phi)*log(baseline_nonagr_output/(P.N_ind+P.Nn_r+P.Nn_u));

    if case_id == 1
        save matfiles/baseline-var-baseline.mat baseline_agr_LP baseline_agr_output ...
            baseline_nonagr_output baseline_p baseline_GDP_las baseline_median_TFPQ ...
            baseline_median_u baseline_welfare
    elseif case_id == 2
        save matfiles/baseline-var-2018.mat baseline_agr_LP baseline_agr_output ...
            baseline_nonagr_output baseline_p baseline_GDP_las baseline_median_TFPQ ...
            baseline_median_u baseline_welfare
    elseif case_id == 3
        save matfiles/baseline-var-noeta.mat baseline_agr_LP baseline_agr_output ...
            baseline_nonagr_output baseline_p baseline_GDP_las baseline_median_TFPQ ...
            baseline_median_u baseline_welfare
    elseif case_id == 4
        save matfiles/baseline-var-2nonagr.mat baseline_agr_LP baseline_agr_output ...
            baseline_nonagr_output baseline_p baseline_GDP_las baseline_median_TFPQ ...
            baseline_median_u baseline_welfare
    elseif case_id == 5
        save matfiles/baseline-var-2nonagrcohort.mat baseline_agr_LP baseline_agr_output ...
            baseline_nonagr_output baseline_p baseline_GDP_las baseline_median_TFPQ ...
            baseline_median_u baseline_welfare
    elseif case_id == 6
        save matfiles/baseline-var-remote.mat baseline_agr_LP baseline_agr_output ...
            baseline_nonagr_output baseline_p baseline_GDP_las baseline_median_TFPQ ...
            baseline_median_u baseline_welfare
    elseif case_id == 7
        save matfiles/baseline-var-periurban.mat baseline_agr_LP baseline_agr_output ...
            baseline_nonagr_output baseline_p baseline_GDP_las baseline_median_TFPQ ...
            baseline_median_u baseline_welfare
    elseif case_id == 8
        save matfiles/baseline-var-noxi.mat baseline_agr_LP baseline_agr_output ...
            baseline_nonagr_output baseline_p baseline_GDP_las baseline_median_TFPQ ...
            baseline_median_u baseline_welfare
    elseif case_id == 9
        save matfiles/baseline-var-nocorr.mat baseline_agr_LP baseline_agr_output ...
            baseline_nonagr_output baseline_p baseline_GDP_las baseline_median_TFPQ ...
            baseline_median_u baseline_welfare
    elseif case_id == 10
        save matfiles/baseline-var-highcorr.mat baseline_agr_LP baseline_agr_output ...
            baseline_nonagr_output baseline_p baseline_GDP_las baseline_median_TFPQ ...
            baseline_median_u baseline_welfare
    elseif case_id == 11
        save matfiles/baseline-var-PIGL.mat baseline_agr_LP baseline_agr_output ...
            baseline_nonagr_output baseline_p baseline_GDP_las baseline_median_TFPQ ...
            baseline_median_u baseline_welfare
    end

else
    if case_id == 1
        load matfiles/baseline-var-baseline.mat
    elseif case_id == 2
        load matfiles/baseline-var-2018.mat
    elseif case_id == 3
        load matfiles/baseline-var-noeta.mat
    elseif case_id == 4
        load matfiles/baseline-var-2nonagr.mat
    elseif case_id == 5
        load matfiles/baseline-var-2nonagrcohort.mat
    elseif case_id == 6
        load matfiles/baseline-var-remote.mat
    elseif case_id == 7
        load matfiles/baseline-var-periurban.mat
    elseif case_id == 8
        load matfiles/baseline-var-noxi.mat
    elseif case_id == 9
        load matfiles/baseline-nocorr.mat
    elseif case_id == 10
        load matfiles/baseline-highcorr.mat
    elseif case_id == 11
        load matfiles/baseline-PIGL.mat
    end

end

% save files for operator choice and migration decision for future usage
if case_id == 1 && counterfactual == 0
    exoOperator  = operator;
    exoMigration = hh_migration;
    save matfiles/exoOperator.mat  exoOperator
    save matfiles/exoMigration.mat exoMigration
end

withinFamilySelection





