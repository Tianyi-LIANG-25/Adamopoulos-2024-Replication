% This subroutine solves the non-agricultural problem and national account.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024


% Non-agricultural problem


exp_n = (1-P.phi)*DI;

Hr = 0;
for i = 1:P.N_ind
    Hr = Hr + sum((dummy_rural(:,i) + dummy_pt_r(:,i).*(1-P.c_pt_r-ind_pt_ls_r(:,i))).*ind_h(:,i));
end
Hr = Hr/P.N_sim;
Hr = Hr + P.B*P.Nn_r*mean(mean(ind_h));

Hu = 0;
for i = 1:P.N_ind
    Hu = Hu + sum((dummy_urban(:,i) + dummy_pt_u(:,i).*(1-P.c_pt_u-ind_pt_ls_u(:,i))).*ind_h(:,i));
end
Hu = Hu/P.N_sim;
Hu = Hu + P.B*P.Nn_u*mean(mean(ind_h));



AD_n = exp_n;
AS_n = Hr*P.Ar+Hu*P.Au;


% National Account

GDPo = AS_a*p + AS_n;
GDPe = AD_a*p + AD_n;
GDPi = sum(hh_inc_total)/P.N_sim+TR+LI+...
    P.B*(P.Nn_u*mean(mean(ind_h))*wu+P.Nn_r*mean(mean(ind_h))*wr);
