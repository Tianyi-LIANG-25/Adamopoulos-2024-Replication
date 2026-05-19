% This code calculates the model moments when one parameter is changed by
% one percent.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024


%% Calculate the equilibrium

jacobianEquilibrium


%% Report the moments

agrFamilyShare_Alt    = PCT_family_operator;
UOWageDiff_Alt        = inc_diff_uo;
incDiffMigrate_Alt    = inc_diff_nonagr_migration;
corrIncLSPT_Alt       = corr_inc_ls_pt;
urbanFTShare_Alt      = sum(sum(dummy_urban))/P.N_sim/P.N_ind;
PTShare_Alt           = sum(sum(dummy_pt_r+dummy_pt_u))/P.N_sim/P.N_ind;
aveHourPT_Alt         = ave_hour_pt;
stdFarmTFPR_Alt       = std_farm_TFPR;
corrQR_Alt            = corr_farm_TFPQ_TFPR;
corrPiNonagr_Alt      = corr_pi_nonagr;
stdFarmTFPQ_Alt       = std_farm_TFPQ;
stdNonagr_Alt         = std_inc_nonagr;
stdNonagrWithin_Alt   = std_inc_nonagr_across;
APG_Alt               = agr_VA_share/agr_emp_share;




fprintf('  Family Operating Farms:       %+5.2f  \n', ...
    (agrFamilyShare_Alt  - agrFamilyShare_Base )*100/(adj_factor/0.01));
fprintf('  Urban-Farming Wage Diffs:     %+5.2f  \n', ...
    (UOWageDiff_Alt      - UOWageDiff_Base     )*100/(adj_factor/0.01));
fprintf('  Nonagr Wage Diffs Migration:  %+5.2f  \n', ...
    (-incDiffMigrate_Alt + incDiffMigrate_Base )*100/(adj_factor/0.01));
fprintf('  Corr: LS VS Wage (PT):        %+5.2f  \n', ...
    (corrIncLSPT_Alt     - corrIncLSPT_Base    )*100/(adj_factor/0.01));
fprintf('  Full-time Nonagr Share:       %+5.2f  \n', ...
    (urbanFTShare_Alt    - urbanFTShare_Base   )*100/(adj_factor/0.01));
fprintf('  Part-time Nonagr Share:       %+5.2f  \n', ...
    (PTShare_Alt         - PTShare_Base        )*100/(adj_factor/0.01));
fprintf('  Ave Agr Hour (PT):            %+5.2f  \n', ...
    (aveHourPT_Alt       - aveHourPT_Base      )/aveHourPT_Base*100/(adj_factor/0.01));
fprintf('  Std Farm TFPR:                %+5.2f  \n', ...
    (stdFarmTFPR_Alt     - stdFarmTFPR_Base    )/stdFarmTFPR_Base*100/(adj_factor/0.01));
fprintf('  Corr: TFPQ VS TFPR:           %+5.2f  \n', ...
    (corrQR_Alt          - corrQR_Base         )*100/(adj_factor/0.01));
fprintf('  Corr: Pi VS Nonagr Wage:      %+5.2f  \n', ...
    (corrPiNonagr_Alt    - corrPiNonagr_Base   )*100/(adj_factor/0.01));
fprintf('  Std Farm TFPQ:                %+5.2f  \n', ...
    (stdFarmTFPQ_Alt     - stdFarmTFPQ_Base    )/stdFarmTFPQ_Base*100/(adj_factor/0.01));
fprintf('  Std Nonagr Wage:              %+5.2f  \n', ...
    (stdNonagr_Alt       - stdNonagr_Base      )/stdNonagr_Base*100/(adj_factor/0.01));
fprintf('  Within-Family Nonagr Wage:    %+5.2f  \n', ...
    (stdNonagrWithin_Alt - stdNonagrWithin_Base)/stdNonagrWithin_Base*100/(adj_factor/0.01));
fprintf('  APG:                          %+5.2f  \n', ...
    (APG_Alt             - APG_Base            )/APG_Base*100/(adj_factor/0.01));
fprintf('-------------------------------------------------- \n');
fprintf(' \n');
