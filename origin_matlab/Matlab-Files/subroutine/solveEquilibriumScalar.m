function [f] = solveEquilibriumScalar(X,P,ind_h,ind_xiu,ind_xir,ind_s,...
    ind_s_tilde,ind_s_tilde2,ind_tauy,ind_taul,hh_eta,hh_lambda,hh_varphi,l_bar,case_id)

% This function calculates the equilibrium prices.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024
p     = X(1);
q     = X(2);
wa    = X(3);

pr   = 1;
pu   = 1;

wu   = P.Au*pu;
wr   = P.Ar*pr;



% Solve for occupational choices for individuals and families
occupationalChoice % call the subroutine

% Markets Clearing
landLaborMarket % call the subroutine

% Revenue from wedges and distortions
taxRevenue % call the subroutine

% Agricultural goods market
agrMarket


f = sum([distance_Na,distance_ADA,distance_L].^2);
end

