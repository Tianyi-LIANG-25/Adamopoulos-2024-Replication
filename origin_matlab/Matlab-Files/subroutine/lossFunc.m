% This subroutine defines the loss function for calibration.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

Moment_Model = zeros(21,1);
Moment_Data  = zeros(21,1);

i = 0;

if case_id == 1 % baseline calibration

    load matfiles/datafile-2004-nationwide.mat

    % Part 1: employment share
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_rural+dummy_urban))/P.N_sim/P.N_ind; % rural nonagr
    Moment_Data(i)  = data_rural_nonagr_emp+data_urban_nonagr_emp;
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_pt_r+dummy_pt_u))/P.N_sim/P.N_ind; % agr + rural nonagr
    Moment_Data(i)  = data_parttime_rural_emp+data_parttime_urban_emp;
    i = i+1;
    Moment_Model(i) = ave_hour_pt; % median agr hours among part-time
    Moment_Data(i)  = data_ave_hour_pt;

    % Part 2: Family choices among rural hukou owners
    i = i+1;
    Moment_Model(i) = PCT_family_operator; % family with operator
    Moment_Data(i)  = data_PCT_family_operator;

    % Part 3: Income moments
    i = i+1;
    Moment_Model(i) = std_inc_nonagr; %  nonagr full-time
    Moment_Data(i)  = data_std_inc_nonagr;
    i = i+1;
    Moment_Model(i) = std_inc_nonagr_across; %  nonagr full-time within HH
    Moment_Data(i)  = data_std_inc_nonagr_across;
    i = i+1;
    Moment_Model(i) = inc_diff_uo; % rural nonagr - operator
    Moment_Data(i)  = data_inc_diff_uo;
    i = i+1;
    Moment_Model(i) = corr_pi_nonagr; %farming-nonagr wage rate correlation
    Moment_Data(i)  = data_corr_pi_nonagr;
    i = i+1;
    Moment_Model(i) = corr_inc_ls_pt; %Corr of income vs. labor supply among parttime workers
    Moment_Data(i)  = data_corr_inc_ls_pt;

    % Part 4: Agr production moments
    i = i+1;
    Moment_Model(i) = std_farm_TFPQ;
    Moment_Data(i)  = data_std_farm_TFPQ;
    i = i+1;
    Moment_Model(i) = std_farm_TFPR;
    Moment_Data(i)  = data_std_farm_TFPR;
    i = i+1;
    Moment_Model(i) = corr_farm_TFPQ_TFPR;
    Moment_Data(i)  = data_corr_farm_TFPQ_TFPR;
    i = i+1;
    Moment_Model(i) = inc_diff_nonagr_migration;
    Moment_Data(i)  = data_inc_diff_nonagr_migration;

    % Part 5: National Account
    i = i+1;
    Moment_Model(i) = agr_VA_share/agr_emp_share;
    Moment_Data(i)  = data_GLW_inv;

elseif case_id == 2 % 2018 calibration

    load matfiles/datafile-2018-nationwide.mat

    % Part 1: employment share
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_rural+dummy_urban))/P.N_sim/P.N_ind; % rural nonagr
    Moment_Data(i)  = data_rural_nonagr_emp+data_urban_nonagr_emp;
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_pt_r+dummy_pt_u))/P.N_sim/P.N_ind; % agr + rural nonagr
    Moment_Data(i)  = data_parttime_rural_emp+data_parttime_urban_emp;
    i = i+1;
    Moment_Model(i) = ave_hour_pt; % median agr hours among part-time
    Moment_Data(i)  = data_ave_hour_pt;

    % Part 2: Family choices among rural hukou owners
    i = i+1;
    Moment_Model(i) = PCT_family_operator; % family with operator
    Moment_Data(i)  = data_PCT_family_operator;

    % Part 3: Income moments
    i = i+1;
    Moment_Model(i) = std_inc_nonagr; %  nonagr full-time
    Moment_Data(i)  = data_std_inc_nonagr;
    i = i+1;
    Moment_Model(i) = std_inc_nonagr_across; %  nonagr full-time within HH
    Moment_Data(i)  = data_std_inc_nonagr_across;
    i = i+1;
    Moment_Model(i) = inc_diff_uo; % rural nonagr - operator
    Moment_Data(i)  = data_inc_diff_uo;
    i = i+1;
    Moment_Model(i) = corr_pi_nonagr; %farming-nonagr wage rate correlation
    Moment_Data(i)  = data_corr_pi_nonagr;
    i = i+1;
    Moment_Model(i) = corr_inc_ls_pt; %Corr of income vs. labor supply among parttime workers
    Moment_Data(i)  = data_corr_inc_ls_pt;

    % Part 4: Agr production moments
    i = i+1;
    Moment_Model(i) = std_farm_TFPQ;
    Moment_Data(i)  = data_std_farm_TFPQ;
    i = i+1;
    Moment_Model(i) = std_farm_TFPR;
    Moment_Data(i)  = data_std_farm_TFPR;
    i = i+1;
    Moment_Model(i) = corr_farm_TFPQ_TFPR;
    Moment_Data(i)  = data_corr_farm_TFPQ_TFPR;
    i = i+1;
    Moment_Model(i) = inc_diff_nonagr_migration;
    Moment_Data(i)  = data_inc_diff_nonagr_migration;

    % Part 5: National Account
    i = i+1;
    Moment_Model(i) = agr_VA_share/agr_emp_share;
    Moment_Data(i)  = data_GLW_inv;

elseif case_id == 3 % no eta calibration

    load matfiles/datafile-2004-nationwide.mat

    % Part 1: employment share
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_rural+dummy_urban))/P.N_sim/P.N_ind; % rural nonagr
    Moment_Data(i)  = data_rural_nonagr_emp+data_urban_nonagr_emp;
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_pt_r+dummy_pt_u))/P.N_sim/P.N_ind; % agr + rural nonagr
    Moment_Data(i)  = data_parttime_rural_emp+data_parttime_urban_emp;
    i = i+1;
    Moment_Model(i) = ave_hour_pt; % median agr hours among part-time
    Moment_Data(i)  = data_ave_hour_pt;

    % Part 2: Family choices among rural hukou owners 
    % (NOT APPLICABLE)
    % i = i+1;
    % Moment_Model(i) = PCT_family_operator; % family with operator
    % Moment_Data(i)  = data_PCT_family_operator;

    % Part 3: Income moments
    i = i+1;
    Moment_Model(i) = std_inc_nonagr; %  nonagr full-time
    Moment_Data(i)  = data_std_inc_nonagr;
    i = i+1;
    Moment_Model(i) = std_inc_nonagr_across; %  nonagr full-time within HH
    Moment_Data(i)  = data_std_inc_nonagr_across;
    i = i+1;
    Moment_Model(i) = inc_diff_uo; % rural nonagr - operator
    Moment_Data(i)  = data_inc_diff_uo;
    i = i+1;
    Moment_Model(i) = corr_pi_nonagr; %farming-nonagr wage rate correlation
    Moment_Data(i)  = data_corr_pi_nonagr;
    i = i+1;
    Moment_Model(i) = corr_inc_ls_pt; %Corr of income vs. labor supply among parttime workers
    Moment_Data(i)  = data_corr_inc_ls_pt;

    % Part 4: Agr production moments
    i = i+1;
    Moment_Model(i) = std_farm_TFPQ;
    Moment_Data(i)  = data_std_farm_TFPQ;
    i = i+1;
    Moment_Model(i) = std_farm_TFPR;
    Moment_Data(i)  = data_std_farm_TFPR;
    i = i+1;
    Moment_Model(i) = corr_farm_TFPQ_TFPR;
    Moment_Data(i)  = data_corr_farm_TFPQ_TFPR;
    % (NOT APPLICABLE)
    % i = i+1;
    % Moment_Model(i) = inc_diff_nonagr_migration;
    % Moment_Data(i)  = data_inc_diff_nonagr_migration;

    % Part 5: National Account
    i = i+1;
    Moment_Model(i) = agr_VA_share/agr_emp_share;
    Moment_Data(i)  = data_GLW_inv;

elseif case_id == 4 % 2 nonagr sectors

    load matfiles/datafile-2004-nationwide.mat

    % Part 1: employment share
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_rural))/P.N_sim/P.N_ind; % rural nonagr
    Moment_Data(i)  = data_rural_nonagr_emp;
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_urban))/P.N_sim/P.N_ind; % urban nonagr
    Moment_Data(i)  = data_urban_nonagr_emp;
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_pt_r))/P.N_sim/P.N_ind; % agr + rural nonagr
    Moment_Data(i)  = data_parttime_rural_emp;
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_pt_u))/P.N_sim/P.N_ind; % agr + urban nonagr
    Moment_Data(i)  = data_parttime_urban_emp;
    i = i+1;
    Moment_Model(i) = ave_hour_pt; % median agr hours among part-time
    Moment_Data(i)  = data_ave_hour_pt;

    % Part 2: Family choices among rural hukou owners
    i = i+1;
    Moment_Model(i) = PCT_family_operator; % family with operator
    Moment_Data(i)  = data_PCT_family_operator;

    % Part 3: Income moments
    i = i+1;
    Moment_Model(i) = std_inc_nonagr; %  nonagr full-time
    Moment_Data(i)  = data_std_inc_nonagr;
    i = i+1;
    Moment_Model(i) = std_inc_nonagr_across; %  nonagr full-time within HH
    Moment_Data(i)  = data_std_inc_nonagr_across;
    i = i+1;
    Moment_Model(i) = inc_diff_uo; % rural nonagr - operator
    Moment_Data(i)  = data_inc_diff_uo_2nonagr;
    i = i+1;
    Moment_Model(i) = inc_diff_ur; % urban-rural nonagr wage diff
    Moment_Data(i)  = data_inc_diff_ur_2nonagr;
    i = i+1;
    Moment_Model(i) = corr_pi_nonagr; %farming-nonagr wage rate correlation
    Moment_Data(i)  = data_corr_pi_nonagr;
    i = i+1;
    Moment_Model(i) = corr_inc_ls_pt; %Corr of income vs. labor supply among parttime workers
    Moment_Data(i)  = data_corr_inc_ls_pt;

    % Part 4: Agr production moments
    i = i+1;
    Moment_Model(i) = std_farm_TFPQ;
    Moment_Data(i)  = data_std_farm_TFPQ;
    i = i+1;
    Moment_Model(i) = std_farm_TFPR;
    Moment_Data(i)  = data_std_farm_TFPR;
    i = i+1;
    Moment_Model(i) = corr_farm_TFPQ_TFPR;
    Moment_Data(i)  = data_corr_farm_TFPQ_TFPR;
    i = i+1;
    Moment_Model(i) = inc_diff_nonagr_migration;
    Moment_Data(i)  = data_inc_diff_nonagr_migration;

    % Part 5: National Account
    i = i+1;
    Moment_Model(i) = agr_VA_share/agr_emp_share;
    Moment_Data(i)  = data_GLW_inv;

elseif case_id == 5 % 2 nonagr sectors and age differences

    load matfiles/datafile-2004-nationwide.mat

    % Part 1: employment share
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_rural))/P.N_sim/P.N_ind; % rural nonagr
    Moment_Data(i)  = data_rural_nonagr_emp;
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_urban))/P.N_sim/P.N_ind; % urban nonagr
    Moment_Data(i)  = data_urban_nonagr_emp;
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_pt_r))/P.N_sim/P.N_ind; % agr + rural nonagr
    Moment_Data(i)  = data_parttime_rural_emp;
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_pt_u))/P.N_sim/P.N_ind; % agr + urban nonagr
    Moment_Data(i)  = data_parttime_urban_emp;
    i = i+1;
    Moment_Model(i) = ave_hour_pt; % median agr hours among part-time
    Moment_Data(i)  = data_ave_hour_pt;

    % Part 2: Family choices among rural hukou owners
    i = i+1;
    Moment_Model(i) = PCT_family_operator; % family with operator
    Moment_Data(i)  = data_PCT_family_operator;

    % Part 3: Income moments
    i = i+1;
    Moment_Model(i) = std_inc_nonagr; %  nonagr full-time
    Moment_Data(i)  = data_std_inc_nonagr;
    i = i+1;
    Moment_Model(i) = std_inc_nonagr_across; %  nonagr full-time within HH
    Moment_Data(i)  = data_std_inc_nonagr_across;
    i = i+1;
    Moment_Model(i) = inc_diff_uo; % rural nonagr - operator
    Moment_Data(i)  = data_inc_diff_uo_2nonagr;
    i = i+1;
    Moment_Model(i) = inc_diff_ur; % urban-rural nonagr wage diff
    Moment_Data(i)  = data_inc_diff_ur_2nonagr;
    i = i+1;
    Moment_Model(i) = corr_pi_nonagr; %farming-nonagr wage rate correlation
    Moment_Data(i)  = data_corr_pi_nonagr;
    i = i+1;
    Moment_Model(i) = corr_inc_ls_pt; %Corr of income vs. labor supply among parttime workers
    Moment_Data(i)  = data_corr_inc_ls_pt;

    % Part 4: Agr production moments
    i = i+1;
    Moment_Model(i) = std_farm_TFPQ;
    Moment_Data(i)  = data_std_farm_TFPQ;
    i = i+1;
    Moment_Model(i) = std_farm_TFPR;
    Moment_Data(i)  = data_std_farm_TFPR;
    i = i+1;
    Moment_Model(i) = corr_farm_TFPQ_TFPR;
    Moment_Data(i)  = data_corr_farm_TFPQ_TFPR;
    i = i+1;
    Moment_Model(i) = inc_diff_nonagr_migration;
    Moment_Data(i)  = data_inc_diff_nonagr_migration;

    % Part 5: Age Distribution
    i = i+1;
    Moment_Model(i) = sum(sum((dummy_ope+dummy_agr).*dummy_old))/sum(sum(dummy_ope+dummy_agr));
    Moment_Data(i)  = data_PCT_old_farming;
    i = i+1;
    Moment_Model(i) = sum(sum((dummy_rural+dummy_pt_r).*dummy_old))/sum(sum(dummy_rural+dummy_pt_r));
    Moment_Data(i)  = data_PCT_old_rural;
    i = i+1;
    Moment_Model(i) = inc_diff_yo_ope;
    Moment_Data(i)  = data_inc_diff_yo_ope;
    i = i+1;
    Moment_Model(i) = inc_diff_yo_r;
    Moment_Data(i)  = data_inc_diff_yo_r;

    % Part 6: National Account
    i = i+1;
    Moment_Model(i) = agr_VA_share/agr_emp_share;
    Moment_Data(i)  = data_GLW_inv;

elseif case_id == 6 % remote

    load matfiles/datafile-2004-remote.mat

    % Part 1: employment share
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_rural))/P.N_sim/P.N_ind; % rural nonagr
    Moment_Data(i)  = data_rural_nonagr_emp;
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_urban))/P.N_sim/P.N_ind; % urban nonagr
    Moment_Data(i)  = data_urban_nonagr_emp;
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_pt_r))/P.N_sim/P.N_ind; % agr + rural nonagr
    Moment_Data(i)  = data_parttime_rural_emp;
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_pt_u))/P.N_sim/P.N_ind; % agr + urban nonagr
    Moment_Data(i)  = data_parttime_urban_emp;
    i = i+1;
    Moment_Model(i) = ave_hour_pt; % median agr hours among part-time
    Moment_Data(i)  = data_ave_hour_pt;

    % Part 2: Family choices among rural hukou owners
    i = i+1;
    Moment_Model(i) = PCT_family_operator; % family with operator
    Moment_Data(i)  = data_PCT_family_operator;

    % Part 3: Income moments
    i = i+1;
    Moment_Model(i) = std_inc_nonagr; %  nonagr full-time
    Moment_Data(i)  = data_std_inc_nonagr;
    i = i+1;
    Moment_Model(i) = std_inc_nonagr_across; %  nonagr full-time within HH
    Moment_Data(i)  = data_std_inc_nonagr_across;
    i = i+1;
    Moment_Model(i) = inc_diff_uo; % rural nonagr - operator
    Moment_Data(i)  = data_inc_diff_uo_2nonagr;
    i = i+1;
    Moment_Model(i) = inc_diff_ur; % urban-rural nonagr wage diff
    Moment_Data(i)  = data_inc_diff_ur_2nonagr;
    i = i+1;
    Moment_Model(i) = corr_pi_nonagr; %farming-nonagr wage rate correlation
    Moment_Data(i)  = data_corr_pi_nonagr;
    i = i+1;
    Moment_Model(i) = corr_inc_ls_pt; %Corr of income vs. labor supply among parttime workers
    Moment_Data(i)  = data_corr_inc_ls_pt;

    % Part 4: Agr production moments
    i = i+1;
    Moment_Model(i) = std_farm_TFPQ;
    Moment_Data(i)  = data_std_farm_TFPQ;
    i = i+1;
    Moment_Model(i) = std_farm_TFPR;
    Moment_Data(i)  = data_std_farm_TFPR;
    i = i+1;
    Moment_Model(i) = corr_farm_TFPQ_TFPR;
    Moment_Data(i)  = data_corr_farm_TFPQ_TFPR;
    i = i+1;
    Moment_Model(i) = inc_diff_nonagr_migration;
    Moment_Data(i)  = data_inc_diff_nonagr_migration;

    % Part 5: Age Distribution
    i = i+1;
    Moment_Model(i) = sum(sum((dummy_ope+dummy_agr).*dummy_old))/sum(sum(dummy_ope+dummy_agr));
    Moment_Data(i)  = data_PCT_old_farming;
    i = i+1;
    Moment_Model(i) = sum(sum((dummy_rural+dummy_pt_r).*dummy_old))/sum(sum(dummy_rural+dummy_pt_r));
    Moment_Data(i)  = data_PCT_old_rural;
    i = i+1;
    Moment_Model(i) = inc_diff_yo_ope;
    Moment_Data(i)  = data_inc_diff_yo_ope;
    i = i+1;
    Moment_Model(i) = inc_diff_yo_r;
    Moment_Data(i)  = data_inc_diff_yo_r;

    % Part 6: National Account
    i = i+1;
    Moment_Model(i) = agr_VA_share/agr_emp_share;
    Moment_Data(i)  = data_GLW_inv;

elseif case_id == 7 % peri-urban

    load matfiles/datafile-2004-periurban.mat

    % Part 1: employment share
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_rural))/P.N_sim/P.N_ind; % rural nonagr
    Moment_Data(i)  = data_rural_nonagr_emp;
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_urban))/P.N_sim/P.N_ind; % urban nonagr
    Moment_Data(i)  = data_urban_nonagr_emp;
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_pt_r))/P.N_sim/P.N_ind; % agr + rural nonagr
    Moment_Data(i)  = data_parttime_rural_emp;
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_pt_u))/P.N_sim/P.N_ind; % agr + urban nonagr
    Moment_Data(i)  = data_parttime_urban_emp;
    i = i+1;
    Moment_Model(i) = ave_hour_pt; % median agr hours among part-time
    Moment_Data(i)  = data_ave_hour_pt;

    % Part 2: Family choices among rural hukou owners
    i = i+1;
    Moment_Model(i) = PCT_family_operator; % family with operator
    Moment_Data(i)  = data_PCT_family_operator;

    % Part 3: Income moments
    i = i+1;
    Moment_Model(i) = std_inc_nonagr; %  nonagr full-time
    Moment_Data(i)  = data_std_inc_nonagr;
    i = i+1;
    Moment_Model(i) = std_inc_nonagr_across; %  nonagr full-time within HH
    Moment_Data(i)  = data_std_inc_nonagr_across;
    i = i+1;
    Moment_Model(i) = inc_diff_uo; % rural nonagr - operator
    Moment_Data(i)  = data_inc_diff_uo_2nonagr;
    i = i+1;
    Moment_Model(i) = inc_diff_ur; % urban-rural nonagr wage diff
    Moment_Data(i)  = data_inc_diff_ur_2nonagr;
    i = i+1;
    Moment_Model(i) = corr_pi_nonagr; %farming-nonagr wage rate correlation
    Moment_Data(i)  = data_corr_pi_nonagr;
    i = i+1;
    Moment_Model(i) = corr_inc_ls_pt; %Corr of income vs. labor supply among parttime workers
    Moment_Data(i)  = data_corr_inc_ls_pt;

    % Part 4: Agr production moments
    i = i+1;
    Moment_Model(i) = std_farm_TFPQ;
    Moment_Data(i)  = data_std_farm_TFPQ;
    i = i+1;
    Moment_Model(i) = std_farm_TFPR;
    Moment_Data(i)  = data_std_farm_TFPR;
    i = i+1;
    Moment_Model(i) = corr_farm_TFPQ_TFPR;
    Moment_Data(i)  = data_corr_farm_TFPQ_TFPR;
    i = i+1;
    Moment_Model(i) = inc_diff_nonagr_migration;
    Moment_Data(i)  = data_inc_diff_nonagr_migration;

    % Part 5: Age Distribution
    i = i+1;
    Moment_Model(i) = sum(sum((dummy_ope+dummy_agr).*dummy_old))/sum(sum(dummy_ope+dummy_agr));
    Moment_Data(i)  = data_PCT_old_farming;
    i = i+1;
    Moment_Model(i) = sum(sum((dummy_rural+dummy_pt_r).*dummy_old))/sum(sum(dummy_rural+dummy_pt_r));
    Moment_Data(i)  = data_PCT_old_rural;
    i = i+1;
    Moment_Model(i) = inc_diff_yo_ope;
    Moment_Data(i)  = data_inc_diff_yo_ope;
    i = i+1;
    Moment_Model(i) = inc_diff_yo_r;
    Moment_Data(i)  = data_inc_diff_yo_r;

    % Part 6: National Account
    i = i+1;
    Moment_Model(i) = agr_VA_share/agr_emp_share;
    Moment_Data(i)  = data_GLW_inv;

elseif case_id == 8 % no xi calibration

    load matfiles/datafile-2004-nationwide.mat

    % Part 1: employment share
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_rural+dummy_urban))/P.N_sim/P.N_ind; % rural nonagr
    Moment_Data(i)  = data_rural_nonagr_emp+data_urban_nonagr_emp;
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_pt_r+dummy_pt_u))/P.N_sim/P.N_ind; % agr + rural nonagr
    Moment_Data(i)  = data_parttime_rural_emp+data_parttime_urban_emp;
    i = i+1;
    Moment_Model(i) = ave_hour_pt; % median agr hours among part-time
    Moment_Data(i)  = data_ave_hour_pt;

    % Part 2: Family choices among rural hukou owners
    i = i+1;
    Moment_Model(i) = PCT_family_operator; % family with operator
    Moment_Data(i)  = data_PCT_family_operator;

    % Part 3: Income moments
    i = i+1;
    Moment_Model(i) = std_inc_nonagr; %  nonagr full-time
    Moment_Data(i)  = data_std_inc_nonagr;
    i = i+1;
    Moment_Model(i) = std_inc_nonagr_across; %  nonagr full-time within HH
    Moment_Data(i)  = data_std_inc_nonagr_across;
    i = i+1;
    Moment_Model(i) = corr_pi_nonagr; %farming-nonagr wage rate correlation
    Moment_Data(i)  = data_corr_pi_nonagr;
    % (NOT APPLICABLE)
    % i = i+1;
    % Moment_Model(i) = inc_diff_uo; % rural nonagr - operator
    % Moment_Data(i)  = data_inc_diff_uo;
    % i = i+1;
    % Moment_Model(i) = corr_inc_ls_pt; %Corr of income vs. labor supply among parttime workers
    % Moment_Data(i)  = data_corr_inc_ls_pt;

    % Part 4: Agr production moments
    i = i+1;
    Moment_Model(i) = std_farm_TFPQ;
    Moment_Data(i)  = data_std_farm_TFPQ;
    i = i+1;
    Moment_Model(i) = std_farm_TFPR;
    Moment_Data(i)  = data_std_farm_TFPR;
    i = i+1;
    Moment_Model(i) = corr_farm_TFPQ_TFPR;
    Moment_Data(i)  = data_corr_farm_TFPQ_TFPR;
    i = i+1;
    Moment_Model(i) = inc_diff_nonagr_migration;
    Moment_Data(i)  = data_inc_diff_nonagr_migration;

    % Part 5: National Account
    i = i+1;
    Moment_Model(i) = agr_VA_share/agr_emp_share;
    Moment_Data(i)  = data_GLW_inv;

elseif case_id == 9 % no correlation between abilities

    load matfiles/datafile-2004-nationwide.mat

    % Part 1: employment share
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_rural+dummy_urban))/P.N_sim/P.N_ind; % rural nonagr
    Moment_Data(i)  = data_rural_nonagr_emp+data_urban_nonagr_emp;
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_pt_r+dummy_pt_u))/P.N_sim/P.N_ind; % agr + rural nonagr
    Moment_Data(i)  = data_parttime_rural_emp+data_parttime_urban_emp;
    i = i+1;
    Moment_Model(i) = ave_hour_pt; % median agr hours among part-time
    Moment_Data(i)  = data_ave_hour_pt;

    % Part 2: Family choices among rural hukou owners
    i = i+1;
    Moment_Model(i) = PCT_family_operator; % family with operator
    Moment_Data(i)  = data_PCT_family_operator;

    % Part 3: Income moments
    i = i+1;
    Moment_Model(i) = std_inc_nonagr; %  nonagr full-time
    Moment_Data(i)  = data_std_inc_nonagr;
    i = i+1;
    Moment_Model(i) = std_inc_nonagr_across; %  nonagr full-time within HH
    Moment_Data(i)  = data_std_inc_nonagr_across;
    i = i+1;
    Moment_Model(i) = inc_diff_uo; % rural nonagr - operator
    Moment_Data(i)  = data_inc_diff_uo;
    i = i+1;
    Moment_Model(i) = corr_inc_ls_pt; %Corr of income vs. labor supply among parttime workers
    Moment_Data(i)  = data_corr_inc_ls_pt;

    % Part 4: Agr production moments
    i = i+1;
    Moment_Model(i) = std_farm_TFPQ;
    Moment_Data(i)  = data_std_farm_TFPQ;
    i = i+1;
    Moment_Model(i) = std_farm_TFPR;
    Moment_Data(i)  = data_std_farm_TFPR;
    i = i+1;
    Moment_Model(i) = corr_farm_TFPQ_TFPR;
    Moment_Data(i)  = data_corr_farm_TFPQ_TFPR;
    i = i+1;
    Moment_Model(i) = inc_diff_nonagr_migration;
    Moment_Data(i)  = data_inc_diff_nonagr_migration;

    % Part 5: National Account
    i = i+1;
    Moment_Model(i) = agr_VA_share/agr_emp_share;
    Moment_Data(i)  = data_GLW_inv;

elseif case_id == 10 % high correlation between abilities

    load matfiles/datafile-2004-nationwide.mat

    % Part 1: employment share
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_rural+dummy_urban))/P.N_sim/P.N_ind; % rural nonagr
    Moment_Data(i)  = data_rural_nonagr_emp+data_urban_nonagr_emp;
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_pt_r+dummy_pt_u))/P.N_sim/P.N_ind; % agr + rural nonagr
    Moment_Data(i)  = data_parttime_rural_emp+data_parttime_urban_emp;
    i = i+1;
    Moment_Model(i) = ave_hour_pt; % median agr hours among part-time
    Moment_Data(i)  = data_ave_hour_pt;

    % Part 2: Family choices among rural hukou owners
    i = i+1;
    Moment_Model(i) = PCT_family_operator; % family with operator
    Moment_Data(i)  = data_PCT_family_operator;

    % Part 3: Income moments
    i = i+1;
    Moment_Model(i) = std_inc_nonagr; %  nonagr full-time
    Moment_Data(i)  = data_std_inc_nonagr;
    i = i+1;
    Moment_Model(i) = std_inc_nonagr_across; %  nonagr full-time within HH
    Moment_Data(i)  = data_std_inc_nonagr_across;
    i = i+1;
    Moment_Model(i) = inc_diff_uo; % rural nonagr - operator
    Moment_Data(i)  = data_inc_diff_uo;
    i = i+1;
    Moment_Model(i) = corr(ind_s(:),ind_h(:),'type','spearman'); % higher correlation
    Moment_Data(i)  = 0.5;
    i = i+1;
    Moment_Model(i) = corr_inc_ls_pt; %Corr of income vs. labor supply among parttime workers
    Moment_Data(i)  = data_corr_inc_ls_pt;

    % Part 4: Agr production moments
    i = i+1;
    Moment_Model(i) = std_farm_TFPQ;
    Moment_Data(i)  = data_std_farm_TFPQ;
    i = i+1;
    Moment_Model(i) = std_farm_TFPR;
    Moment_Data(i)  = data_std_farm_TFPR;
    i = i+1;
    Moment_Model(i) = corr_farm_TFPQ_TFPR;
    Moment_Data(i)  = data_corr_farm_TFPQ_TFPR;
    i = i+1;
    Moment_Model(i) = inc_diff_nonagr_migration;
    Moment_Data(i)  = data_inc_diff_nonagr_migration;

    % Part 5: National Account
    i = i+1;
    Moment_Model(i) = agr_VA_share/agr_emp_share;
    Moment_Data(i)  = data_GLW_inv;



elseif case_id == 11 % PIGL calibration

    load matfiles/datafile-2004-nationwide.mat

    % Part 1: employment share
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_rural+dummy_urban))/P.N_sim/P.N_ind; % rural nonagr
    Moment_Data(i)  = data_rural_nonagr_emp+data_urban_nonagr_emp;
    i = i+1;
    Moment_Model(i) = sum(sum(dummy_pt_r+dummy_pt_u))/P.N_sim/P.N_ind; % agr + rural nonagr
    Moment_Data(i)  = data_parttime_rural_emp+data_parttime_urban_emp;
    i = i+1;
    Moment_Model(i) = ave_hour_pt; % median agr hours among part-time
    Moment_Data(i)  = data_ave_hour_pt;

    % Part 2: Family choices among rural hukou owners
    i = i+1;
    Moment_Model(i) = PCT_family_operator; % family with operator
    Moment_Data(i)  = data_PCT_family_operator;

    % Part 3: Income moments
    i = i+1;
    Moment_Model(i) = std_inc_nonagr; %  nonagr full-time
    Moment_Data(i)  = data_std_inc_nonagr;
    i = i+1;
    Moment_Model(i) = std_inc_nonagr_across; %  nonagr full-time within HH
    Moment_Data(i)  = data_std_inc_nonagr_across;
    i = i+1;
    Moment_Model(i) = inc_diff_uo; % rural nonagr - operator
    Moment_Data(i)  = data_inc_diff_uo;
    i = i+1;
    Moment_Model(i) = corr_pi_nonagr; %farming-nonagr wage rate correlation
    Moment_Data(i)  = data_corr_pi_nonagr;
    i = i+1;
    Moment_Model(i) = corr_inc_ls_pt; %Corr of income vs. labor supply among parttime workers
    Moment_Data(i)  = data_corr_inc_ls_pt;

    % Part 4: Agr production moments
    i = i+1;
    Moment_Model(i) = std_farm_TFPQ;
    Moment_Data(i)  = data_std_farm_TFPQ;
    i = i+1;
    Moment_Model(i) = std_farm_TFPR;
    Moment_Data(i)  = data_std_farm_TFPR;
    i = i+1;
    Moment_Model(i) = corr_farm_TFPQ_TFPR;
    Moment_Data(i)  = data_corr_farm_TFPQ_TFPR;
    i = i+1;
    Moment_Model(i) = inc_diff_nonagr_migration;
    Moment_Data(i)  = data_inc_diff_nonagr_migration;

    % Part 5: National Account
    i = i+1;
    Moment_Model(i) = agr_VA_share/agr_emp_share;
    Moment_Data(i)  = data_GLW_inv;

end



Loss = sqrt(sum((Moment_Model - Moment_Data).^2)/i);
