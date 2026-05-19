% This subroutine calculates the family-level correlation between farming
% profit and rural non-agricultural sector wage rate.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

temp = [];
for i = 1:P.N_sim
    if sum(dummy_rural(i,:)+dummy_pt_r(i,:))==1 && hh_migration(i) == 0
        temp = [temp; sum(...
            log(ind_h(i,:))*wr.*(dummy_rural(i,:)+dummy_pt_r(i,:))),...
            log(farm_pi(i))];
    end
end
if size(temp,1) > 1
    corr_pi_rural = corr(temp(:,1),temp(:,2),'type','spearman');
else
    corr_pi_rural = 1;
end