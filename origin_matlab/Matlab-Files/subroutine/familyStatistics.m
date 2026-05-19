% This subroutine calculates statistics at the family level
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

PCT_family_operator    = sum((sum(dummy_ope,2)>0))/P.N_sim;