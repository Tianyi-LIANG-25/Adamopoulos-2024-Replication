% This subroutine calculates model moments used as the baseline for
% sensitivity analysis.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

%% Define the parameter values


case_id     = 1;


load matfiles/x-baseline.mat

X = parameter;


assignParameterValue



% load parameters that do not depend on the general equilibrium
parameterExo

%% Calculate the equilibrium

jacobianEquilibrium


%% Report the moments

agrFamilyShare_Base    = PCT_family_operator;
UOWageDiff_Base        = inc_diff_uo;
incDiffMigrate_Base    = inc_diff_nonagr_migration;
corrIncLSPT_Base       = corr_inc_ls_pt;
urbanFTShare_Base      = sum(sum(dummy_urban))/P.N_sim/P.N_ind;
PTShare_Base           = sum(sum(dummy_pt_r+dummy_pt_u))/P.N_sim/P.N_ind;
aveHourPT_Base         = ave_hour_pt;
stdFarmTFPR_Base       = std_farm_TFPR;
corrQR_Base            = corr_farm_TFPQ_TFPR;
corrPiNonagr_Base      = corr_pi_nonagr;
stdFarmTFPQ_Base       = std_farm_TFPQ;
stdNonagr_Base         = std_inc_nonagr;
stdNonagrWithin_Base   = std_inc_nonagr_across;
APG_Base               = agr_VA_share/agr_emp_share;

