% This subroutine calculates the family-level correlation between rural and
% urban wage rates.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

temp = [];
for i = 1:P.N_sim
    if sum(dummy_rural(i,:)+dummy_pt_r(i,:))==1 && sum(dummy_urban(i,:)+dummy_pt_u(i,:))==1 
        temp = [temp; sum(log(ind_h(i,:))*wr.*(dummy_rural(i,:)+dummy_pt_r(i,:))), ...
            sum(log(ind_h(i,:))*wu.*(dummy_urban(i,:)+dummy_pt_u(i,:)))];
    end
end
if size(temp,1) > 1
    corr_rural_urban = corr(temp(:,1),temp(:,2),'type','spearman');
else
    corr_rural_urban = 1;
end