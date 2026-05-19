% This subroutine calculates the percentage of agr families whose operators
% turn out to be the individual with highest agr ability.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

hh_s_max = max(ind_s,[],2);
frac_sorting = sum(occuSeparate(hh_migration,hh_s_max,0)==occuSeparate(hh_migration,farm_s,0))/ ...
    sum(occuSeparate(hh_migration,ones(P.N_sim,1),0));

