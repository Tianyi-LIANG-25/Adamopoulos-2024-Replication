% This subroutine calculates the equilibrium moments for the Jacobian
% matrix analysis.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

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

x0 = [0.5,0.50,0.30];

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
% incDiffFP
incDiffYO
aveHourPT
agrProductionMoment

corrIncLSPT1