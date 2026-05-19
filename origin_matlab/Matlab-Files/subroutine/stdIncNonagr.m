% This subroutine calculates dispersion and within family correlation for 
% the non-agricultural income.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024


wn_Mat = wr*(dummy_rural + dummy_pt_r) + wu*(dummy_urban + dummy_pt_u);

temp = occuSeparate(dummy_rural(:)+dummy_pt_r(:)+dummy_urban(:)+dummy_pt_u(:),...
    ind_h(:).*wn_Mat(:),1);
if size(temp,1) > 1
    std_inc_nonagr = std(log(temp));
else
    std_inc_nonagr = 0;
end


temp1 = [];
for i = 1:P.N_sim
    if sum(dummy_rural(i,:)+dummy_pt_r(i,:)+dummy_urban(i,:)+dummy_pt_u(i,:))==2
        if dummy_rural(i,1)+dummy_urban(i,1)+dummy_pt_r(i,1)+dummy_pt_u(i,1) == 0
            temp1 = [temp1;log(ind_h(i,2).*wn_Mat(i,2)),log(ind_h(i,3).*wn_Mat(i,3))];
        elseif dummy_rural(i,2)+dummy_urban(i,2)+dummy_pt_r(i,2)+dummy_pt_u(i,2) == 0
            temp1 = [temp1;log(ind_h(i,1).*wn_Mat(i,1)),log(ind_h(i,3).*wn_Mat(i,3))];
        else
            temp1 = [temp1;log(ind_h(i,1).*wn_Mat(i,1)),log(ind_h(i,2).*wn_Mat(i,2))];
        end
    end
end
if size(temp1,1) > 1
    std_inc_nonagr_across = corr(temp1(:,1),temp1(:,2),'type','spearman');
else
    std_inc_nonagr_across = 0;
end


temp = [];
for i = 1:P.N_sim
    if sum(dummy_rural(i,:)+dummy_pt_r(i,:)+dummy_urban(i,:)+dummy_pt_u(i,:))==1 && hh_migration(i) == 0
        temp = [temp; sum(...
            log(ind_h(i,:)).*wn_Mat(i,:)...
            .*(dummy_rural(i,:)+dummy_pt_r(i,:)+dummy_urban(i,:)+dummy_pt_u(i,:))),...
            log(farm_pi(i))];
    end
end
if size(temp,1) > 1 && isreal(temp)
    corr_pi_nonagr = corr(temp(:,1),temp(:,2),'type','spearman');
else
    corr_pi_nonagr = 1;
end