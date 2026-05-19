% This subroutine calculates dispersion and within family correlation for
% rural or urban non-agricultural sector.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024


temp = occuSeparate(dummy_rural(:)+dummy_pt_r(:),ind_h(:),1);
if size(temp,1) > 1
    std_inc_rural = std(log(temp));
else
    std_inc_rural = 0;
end


temp = [];
temp1 = [];
for i = 1:P.N_sim
    if sum(dummy_rural(i,:)+dummy_pt_r(i,:))==2
        if dummy_rural(i,1)+dummy_pt_r(i,1) == 0
            temp1 = [temp1;log(ind_h(i,2)),log(ind_h(i,3))];
        elseif dummy_rural(i,2)+dummy_pt_r(i,2) == 0
            temp1 = [temp1;log(ind_h(i,1)),log(ind_h(i,3))];
        else
            temp1 = [temp1;log(ind_h(i,1)),log(ind_h(i,2))];
        end
    end
end
if size(temp,1) > 1 && size(temp1,1) > 1
    std_inc_rural_across = corr(temp1(:,1),temp1(:,2),'type','spearman');
else
    std_inc_rural_across = 0;
end


temp = [];
temp1 = [];
for i = 1:P.N_sim
    if sum(dummy_urban(i,:)+dummy_pt_u(i,:))==2
        if dummy_urban(i,1)+dummy_pt_u(i,1) == 0
            temp1 = [temp1;log(ind_h(i,2)),log(ind_h(i,3))];
        elseif dummy_urban(i,2)+dummy_pt_u(i,2) == 0
            temp1 = [temp1;log(ind_h(i,1)),log(ind_h(i,3))];
        else
            temp1 = [temp1;log(ind_h(i,1)),log(ind_h(i,2))];
        end
    end
end
if size(temp,1) > 1 && size(temp1,1) > 1
    std_inc_urban_across = corr(temp1(:,1),temp1(:,2),'type','spearman');
else
    std_inc_urban_across = 0;
end