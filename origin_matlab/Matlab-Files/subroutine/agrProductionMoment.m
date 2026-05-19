% This subroutine calculates agr production moments.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

TFPR  = farm_y./(farm_l.^P.theta.*farm_n.^(1-P.theta));
std_farm_TFPR  = std(log(occuSeparate((1-hh_migration),TFPR,1)));

TFPQ  = farm_s;
std_farm_TFPQ  = std(log(occuSeparate((1-hh_migration),TFPQ,1)));



corr_farm_TFPQ_TFPR  = corr(log(occuSeparate((1-hh_migration).*dummy_farm_rentin,TFPQ,1)),...
    log(occuSeparate((1-hh_migration).*dummy_farm_rentin,TFPR,1)),'type','spearman');



