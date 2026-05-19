% This subroutine calculates the individual-level correlation between
% income and labor supply for the part-time workers
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024


temp = [];

temp(:,1) = occuSeparate(dummy_pt_r(:)+dummy_pt_u(:),...
    dummy_pt_r(:).*ind_h(:).*(1-P.c_pt_r-ind_pt_ls_r(:))+...
    dummy_pt_u(:).*ind_h(:).*(1-P.c_pt_u-ind_pt_ls_u(:)),1);
temp(:,2) = occuSeparate(dummy_pt_r(:)+dummy_pt_u(:),...
    dummy_pt_r(:).*(1-P.c_pt_r-ind_pt_ls_r(:))./(1-P.c_pt_r)+...
    dummy_pt_u(:).*(1-P.c_pt_u-ind_pt_ls_u(:))./(1-P.c_pt_u),1);
temp(:,3) = occuSeparate(dummy_pt_r(:)+dummy_pt_u(:),...
    dummy_pt_r(:).*(ind_h(:).*(1-P.c_pt_r-ind_pt_ls_r(:))+wa*ind_pt_ls_r(:).^P.nu*P.kappa)+...
    dummy_pt_u(:).*(ind_h(:).*(1-P.c_pt_u-ind_pt_ls_u(:))+wa*ind_pt_ls_u(:).^P.nu*P.kappa),1);

temp1 = occuSeparate((temp(:,2)>=0.65).*(temp(:,2)<=0.80),temp(:,1),1);
temp2 = occuSeparate((temp(:,2)>=0.65).*(temp(:,2)<=0.80),temp(:,2),1);
temp = [temp1,temp2];

if size(temp,1)>1
    corr_inc_ls_pt = corr(temp(:,1),temp(:,2),'type','spearman');
else
    corr_inc_ls_pt = 1;
end
