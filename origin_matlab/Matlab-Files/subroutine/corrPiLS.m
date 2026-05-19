% This subroutine calculates the family-level correlation between profit
% and non-agricultural labor supply.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024


temp = [];
temp(:,1) = farm_pi;
temp(:,2) = sum(dummy_rural + dummy_urban + dummy_pt_r.*(1-P.c_pt_r-ind_pt_ls_r) ...
    + dummy_pt_u.*(1-P.c_pt_u-ind_pt_ls_u),2);
if size(temp,1)>1
    corr_pi_ls = corr(temp(:,1),temp(:,2),'type','spearman');
else
    corr_pi_ls = 1;
end
