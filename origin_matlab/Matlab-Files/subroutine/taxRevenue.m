% This subroutine calculates tax revenues arising from wedges and 
% distortions.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

% Tax revenue

TR_xir = 0;
for i = 1:P.N_ind
    TR_xir = TR_xir + sum(dummy_rural(:,i).*ind_h(:,i).*wr.*ind_xir(:,i)) + ...
        sum(dummy_pt_r(:,i).*ind_h(:,i).*(1-P.c_pt_r-ind_pt_ls_r(:,i)).*wr.*ind_xir(:,i));
end
TR_xir = TR_xir/P.N_sim;

TR_xiu = 0;
for i = 1:P.N_ind
    TR_xiu = TR_xiu + sum(dummy_urban(:,i).*ind_h(:,i).*wu.*ind_xiu(:,i)) + ...
        sum(dummy_pt_u(:,i).*ind_h(:,i).*(1-P.c_pt_u-ind_pt_ls_u(:,i)).*wu.*ind_xiu(:,i));
end
TR_xiu = TR_xiu/P.N_sim;

TR_tauy = sum(farm_y.*p.*(1-farm_tauy) + farm_l.*q.*(1-farm_taul))/P.N_sim;

TR_pt = 0;
for i = 1:P.N_ind
    TR_pt = TR_pt + sum(dummy_pt_r(:,i)+dummy_pt_u(:,i))/P.N_sim*P.c_pt_2;
end

TR_expropriation = sum(hh_eta.*hh_varphi.*farm_rentout.*(1-hh_migration) ...
    + hh_migration.*l_bar.*hh_lambda.*hh_varphi)/P.N_sim;


TR      = TR_xir + TR_xiu + TR_tauy + TR_pt + TR_expropriation;
