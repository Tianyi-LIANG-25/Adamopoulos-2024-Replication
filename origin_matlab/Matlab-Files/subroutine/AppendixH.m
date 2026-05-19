% This is the code that calculate the results in Appendix H.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024



rng("default");


%% Define the parameter values


case_id     = 1;


% load parameter values

load matfiles/x-baseline.mat
X = parameter;

assignParameterValue

% load parameters that do not depend on the general equilibrium
parameterExo


% Land security experiment

P.mu_varphi    = -999;
P.sigma_varphi = 0.0001;


%% Simulate individuals with different abilities


% Draw quasi random numbers
HA    = haltonset(30,'skip',1e7,'Leap',0);
HA    = HA(1:P.N_sim,:);

dummy_old = HA(:,1:3)<P.old;

% Call subroutine to generate ability distribution and mobility barriers
ability

% Output wedges

ind_tauy_epsilon = exp(norminv(HA(:,(P.N_ind-1)*5+11),-P.sigma_tauy^2/2,P.sigma_tauy));
ind_tauy     = ind_s.^P.zeta_tauy.*ind_tauy_epsilon;
ind_tauy     = ind_tauy./exp(mean(log(ind_tauy)));
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

% load operator variable

load matfiles/exoMigration.mat
hh_migration = exoMigration;

options = optimoptions('lsqnonlin','FunctionTolerance',1e-15,'OptimalityTolerance',1e-10,...
    'StepTolerance',1e-7,'Display','off','MaxFunctionEvaluations',1000);

LB = [0,0,0];
UB = [5,5,5];

x0 = [0.5,0.50,0.30];

[x,fval_price] = lsqnonlin(@(X) ...
    solveEquilibriumVectorExoMigration(X,P,ind_h,ind_xiu,ind_xir,ind_s,...
    ind_s_tilde,ind_s_tilde2,ind_tauy,ind_taul,hh_eta,hh_lambda,...
    hh_varphi,l_bar,hh_migration,case_id),x0,LB,UB,options);
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
            solveEquilibriumVectorExoMigration(X,P,ind_h,ind_xiu,ind_xir,ind_s,...
            ind_s_tilde,ind_s_tilde2,ind_tauy,ind_taul,hh_eta,hh_lambda,...
            hh_varphi,l_bar,hh_migration,case_id),x0,LB,UB,options);

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
occupationalChoiceExoMigration % call the subroutine

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
    corrIncLSPT2 % for 2018 we use a different correlation coefficient
end



%% Report moments for calibration and experiments


medianAbility
withinFamilySelection

load matfiles/baseline-var-baseline.mat


fprintf('-------------------------------------------------- \n');
fprintf('Additional Moments: \n');
fprintf('  Family with Operators:          %+5.3f  \n', PCT_family_operator);
fprintf('  Agr Emp Share (Villagers):      %+5.3f  \n', agr_emp_share_cond);
fprintf('  D. Agr Output:                  %+5.3f  \n', (AD_a+AS_a)/2/baseline_agr_output-1);
fprintf('  D. Agr Labor Productivity:      %+5.3f  \n', (AD_a+AS_a)/2/agr_emp_share_cond/baseline_agr_LP-1);
fprintf('  D. Median Agr Ability:          %+5.3f  \n', median_TFPQ-baseline_median_TFPQ);
fprintf('  D. Nonagr Output:               %+5.3f  \n', (AD_n+AS_n)/2/baseline_nonagr_output-1);
fprintf('  D. Real GDP Per Capita:         %+5.3f  \n', ...
    sqrt(((AD_a+AS_a)/2*baseline_p+(AD_n+AS_n)/2)/baseline_GDP_las*...
    ((AD_a+AS_a)/2*p+(AD_n+AS_n)/2)/(baseline_agr_output*p+baseline_nonagr_output))-1);
fprintf('  PCT Operators Most Productive:  %+5.3f  \n', frac_sorting);
fprintf('  Nominal APG:                    %+5.3f  \n', agr_emp_share/agr_VA_share);
fprintf('-------------------------------------------------- \n');

toc
