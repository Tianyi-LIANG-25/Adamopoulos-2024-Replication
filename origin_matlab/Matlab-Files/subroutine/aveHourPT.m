% This subroutine calculates average hours among part-time workers.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

temp = occuSeparate(dummy_pt_r(:)+dummy_pt_u(:),...
    (ind_pt_ls_r(:)/(1-P.c_pt_r).*dummy_pt_r(:))+(ind_pt_ls_u(:)/(1-P.c_pt_u).*dummy_pt_u(:)),1);
temp = sort(temp);
ave_hour_pt = temp(round(0.5*size(temp,1)));

