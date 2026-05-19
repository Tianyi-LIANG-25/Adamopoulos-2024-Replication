% This subroutine clears the agricultural good market
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

% Agr Goods Market

LI   = 0;

DI   = sum(hh_inc_total)/P.N_sim+TR+LI-(P.N_ind+P.Nn_r+P.Nn_u)*P.cbar*p+...
    P.B*(P.Nn_u*mean(mean(ind_h))*wu+P.Nn_r*mean(mean(ind_h))*wr);

if case_id == 11 % PIGL case
    eta_a = P.nu_PIGL * p^P.gamma_PIGL / DI^P.epsilon_PIGL;
    AD_a = eta_a*DI/p + (P.N_ind + P.Nn_u + P.Nn_r)*P.cbar;
else
    AD_a = P.phi*DI/p + (P.N_ind + P.Nn_u + P.Nn_r)*P.cbar;
end
AS_a = sum(farm_y.*(1-hh_migration))/P.N_sim;
distance_ADA = (AD_a-AS_a)/(0.5*AD_a+0.5*AS_a+0.001);