% This subroutine calculates the median ability of individuals after
% selection into certain occupation groups.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

median_TFPQ    = sort(log(occuSeparate(hh_migration,TFPQ,0)));
median_TFPQ    = median_TFPQ(round(size(median_TFPQ,1)*0.5));

temp = sort(log(occuSeparate(dummy_rural(:)+dummy_pt_r(:),ind_h(:),1)));
median_r       = temp(round(size(temp,1)*0.5));
temp = sort(log(occuSeparate(dummy_urban(:)+dummy_pt_u(:),ind_h(:),1)));
median_u       = temp(round(size(temp,1)*0.5));