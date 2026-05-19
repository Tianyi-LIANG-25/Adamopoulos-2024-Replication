% This subroutine calculates the wage differences for families with and
% without farm operators.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

temp = [];
for i = 1:P.N_sim
    if sum(dummy_rural(i,:)+dummy_pt_r(i,:)+dummy_urban(i,:)+dummy_pt_u(i,:))>0
        temp = [temp; sum(...
            log(ind_h(i,:)*wr).*(dummy_rural(i,:)+dummy_pt_r(i,:))+...
            log(ind_h(i,:)*wu).*(dummy_urban(i,:)+dummy_pt_u(i,:)))/...
            sum(dummy_rural(i,:)+dummy_pt_r(i,:)+dummy_urban(i,:)+dummy_pt_u(i,:)),...
            1-hh_migration(i)];
    end
end

if size(temp,1) > 1
    inc_diff_nonagr_migration = mean(occuSeparate(temp(:,2),temp(:,1),1)) - ...
        mean(occuSeparate(temp(:,2),temp(:,1),0));
else
    inc_diff_nonagr_migration = 0;
end