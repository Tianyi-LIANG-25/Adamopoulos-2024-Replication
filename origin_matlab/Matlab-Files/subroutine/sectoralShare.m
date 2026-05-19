% This subroutine calculates sectoral employment/valueadded shares.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

Urban_GDP_Share = (P.B*(P.Nn_u*mean(mean(ind_h))*wu+P.Nn_r*mean(mean(ind_h))*wr))/GDPi;


agr_emp_share = sum(sum(dummy_ope+dummy_agr+dummy_pt_r.*ind_pt_ls_r./(1-P.c_pt_r)+...
    dummy_pt_u.*ind_pt_ls_u./(1-P.c_pt_u)))/P.N_sim/(P.N_ind+P.Nn_r+P.Nn_u);

agr_emp_share_cond = sum(sum(dummy_ope+dummy_agr+dummy_pt_r.*ind_pt_ls_r./(1-P.c_pt_r)+...
    dummy_pt_u.*ind_pt_ls_u./(1-P.c_pt_u)))/P.N_sim/(P.N_ind);



rural_nonagr_emp_share = (sum(sum(dummy_rural+dummy_pt_r.*(1-P.c_pt_r-ind_pt_ls_r)./(1-P.c_pt_r)))...
    /P.N_sim+P.Nn_r)/(P.N_ind+P.Nn_r+P.Nn_u);

rural_nonagr_emp_share_cond = (sum(sum(dummy_rural+dummy_pt_r.*(1-P.c_pt_r-ind_pt_ls_r)./(1-P.c_pt_r)))...
    /P.N_sim)/(P.N_ind);

urban_nonagr_emp_share = (sum(sum(dummy_urban+dummy_pt_u.*(1-P.c_pt_u-ind_pt_ls_u)./(1-P.c_pt_u)))...
    /P.N_sim+P.Nn_u)/(P.N_ind+P.Nn_r+P.Nn_u);

urban_nonagr_emp_share_cond = (sum(sum(dummy_urban+dummy_pt_u.*(1-P.c_pt_u-ind_pt_ls_u)./(1-P.c_pt_u)))...
    /P.N_sim)/(P.N_ind);

agr_VA_share  = AD_a*p/GDPe;