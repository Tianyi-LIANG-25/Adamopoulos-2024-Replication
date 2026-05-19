% This subroutine clears land and labor market.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

% Land market

AD_L = sum(farm_rentin )/P.N_sim;
AS_L = sum(farm_rentout)/P.N_sim + sum(hh_migration.*l_bar)/P.N_sim;
distance_L = (AD_L-AS_L)/(0.5*AD_L+0.5*AS_L+0.001);


% Agr Labor Market
AD_Na = sum(farm_n)/P.N_sim;
AS_Na = 0;
for i = 1:P.N_ind
    AS_Na = AS_Na + sum(dummy_agr(:,i))+...
        sum(dummy_pt_r(:,i).*ind_pt_ls_r(:,i).^P.nu*P.kappa)+...
        sum(dummy_pt_u(:,i).*ind_pt_ls_u(:,i).^P.nu*P.kappa)+...
        P.ope_ls*sum(dummy_ope(:,i));
end
AS_Na = AS_Na / P.N_sim;
distance_Na = (AD_Na-AS_Na)/(0.5*AD_Na+0.5*AS_Na+0.001);




