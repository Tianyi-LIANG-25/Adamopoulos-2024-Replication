% This subroutine writes data moments.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

clc

%% 2004 nationwide moments

clear

% Part 1: employment share

data_farm_ope_emp       = 0.2755;
data_agr_emp            = 0.2152;
data_rural_nonagr_emp   = 0.1479;
data_urban_nonagr_emp   = 0.1545;
data_parttime_rural_emp = 0.1590;
data_parttime_urban_emp = 0.0480;
data_ave_hour_pt        = 0.2857;
data_corr_inc_ls_pt     = 0.3978;

% Part 2: Family choices among rural hukou owners

data_PCT_family_operator = 0.7371;

% Part 3: Income moments

data_std_inc_nonagr        = 0.6097;
data_std_inc_nonagr_across = 0.5581;
data_inc_diff_uo           = 0.3677-log(365/274);
data_inc_diff_uo_2nonagr   = 0.3067-log(365/274); % adjust for the number of workdays
data_inc_diff_ur_2nonagr   = -0.1545;
data_corr_pi_nonagr        = 0.0796;

% Part 4: Agr production moments

data_std_farm_TFPQ             = 0.6573;
data_std_farm_TFPR             = 0.6329;
data_corr_farm_TFPQ_TFPR       = 0.9678;
data_inc_diff_nonagr_migration = -0.2806;

% Part 5: National Account

data_GLW_inv = 0.1517/0.3907;

% Part 6: Age Distribution

data_PCT_old_farming = 0.5513;
data_PCT_old_rural   = 0.3687;
data_inc_diff_yo_ope = 0.0719;
data_inc_diff_yo_r   = -0.0709;

save matfiles/datafile-2004-nationwide.mat


%% 2018 nationwide moments

clear

% Part 1: employment share

data_farm_ope_emp       = 0.1672;
data_agr_emp            = 0.1547;
data_rural_nonagr_emp   = 0.2959;
data_urban_nonagr_emp   = 0.2621;
data_parttime_rural_emp = 0.0904;
data_parttime_urban_emp = 0.0296;
data_ave_hour_pt        = 0.1579;
data_corr_inc_ls_pt     = 0.4694;

% Part 2: Family choices among rural hukou owners

data_PCT_family_operator = 0.4239;

% Part 3: Income moments

data_std_inc_nonagr        = 0.5417;
data_std_inc_nonagr_across = 0.4445;
data_inc_diff_uo           = 1.2341-log(365/271); % adjust for the number of workdays
data_corr_pi_nonagr        = 0.0761;

% Part 4: Agr production moments

data_std_farm_TFPQ             = 0.8111;
data_std_farm_TFPR             = 0.7720;
data_corr_farm_TFPQ_TFPR       = 0.9563;
data_inc_diff_nonagr_migration = -0.0583;

% Part 5: National Account

data_GLW_inv = 0.0719/0.1372;

save matfiles/datafile-2018-nationwide.mat


%% 2004 remote moments

clear

% Part 1: employment share

data_farm_ope_emp       = 0.2889;
data_agr_emp            = 0.2249;
data_rural_nonagr_emp   = 0.1104;
data_urban_nonagr_emp   = 0.1665;
data_parttime_rural_emp = 0.1577;
data_parttime_urban_emp = 0.0515;
data_ave_hour_pt        = 0.3010;
data_corr_inc_ls_pt     = 0.3764;

% Part 2: Family choices among rural hukou owners

data_PCT_family_operator = 0.7811;

% Part 3: Income moments

data_std_inc_nonagr        = 0.5919;
data_std_inc_nonagr_across = 0.5625;
data_inc_diff_uo_2nonagr   = 0.3010-log(365/272); % adjust for the number of workdays
data_inc_diff_ur_2nonagr   = -0.0966;
data_corr_pi_nonagr        = 0.0817;

% Part 4: Agr production moments

data_std_farm_TFPQ             = 0.6612;
data_std_farm_TFPR             = 0.6379;
data_corr_farm_TFPQ_TFPR       = 0.9689;
data_inc_diff_nonagr_migration = -0.2042;

% Part 5: National Account

data_GLW_inv = 0.1517/0.3907;

% Part 6: Age Distribution

data_PCT_old_farming = 0.5480;
data_PCT_old_rural   = 0.3674;
data_inc_diff_yo_ope = 0.0677;
data_inc_diff_yo_r   = -0.0878;

save matfiles/datafile-2004-remote.mat


%% 2004 peri-urban moments

clear

% Part 1: employment share

data_farm_ope_emp       = 0.2264;
data_agr_emp            = 0.1778;
data_rural_nonagr_emp   = 0.2876;
data_urban_nonagr_emp   = 0.1096;
data_parttime_rural_emp = 0.1634;
data_parttime_urban_emp = 0.0353;
data_ave_hour_pt        = 0.2244;
data_corr_inc_ls_pt     = 0.4597;

% Part 2: Family choices among rural hukou owners

data_PCT_family_operator = 0.5816;

% Part 3: Income moments

data_std_inc_nonagr        = 0.6777;
data_std_inc_nonagr_across = 0.5232;
data_inc_diff_uo_2nonagr   = 0.4275-log(365/275); % adjust for the number of workdays
data_inc_diff_ur_2nonagr   = -0.1362;
data_corr_pi_nonagr        = 0.0368;

% Part 4: Agr production moments

data_std_farm_TFPQ             = 0.5975;
data_std_farm_TFPR             = 0.5664;
data_corr_farm_TFPQ_TFPR       = 0.9591;
data_inc_diff_nonagr_migration = -0.3461;

% Part 5: National Account

data_GLW_inv = 0.1517/0.3907;

% Part 6: Age Distribution

data_PCT_old_farming = 0.5463;
data_PCT_old_rural   = 0.3730;
data_inc_diff_yo_ope = 0.0743;
data_inc_diff_yo_r   = -0.0327;

save matfiles/datafile-2004-periurban.mat
