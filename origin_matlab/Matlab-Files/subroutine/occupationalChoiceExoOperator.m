% This subroutine solves for the occupational and family choices holding
% the within-family selection constant.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

% Income from full-time occupations
ind_inc_u = ind_h.*(1-ind_xiu)*wu;      % full-time urban non-agriculture
ind_inc_r = ind_h.*(1-ind_xir)*wr;      % full-time rural non-agriculture
ind_inc_a = ones(P.N_sim,P.N_ind).*wa;  % full-time agricultural worker

dummy_urban = (ind_inc_u>ind_inc_r);
ind_inc_nonagr = dummy_urban.*ind_inc_u + (1-dummy_urban).*ind_inc_r;


% Income from part-time occupations
ind_pt_ls     = (P.kappa*P.nu*wa./ind_inc_nonagr).^(1/(1-P.nu));
ind_pt_ls     = (ind_pt_ls>=0).*ind_pt_ls;

ind_pt_ls_r   = (ind_pt_ls<=1-P.c_pt_r).*ind_pt_ls + (1-P.c_pt_r).*(ind_pt_ls>1-P.c_pt_r);
ind_pt_ls_u   = (ind_pt_ls<=1-P.c_pt_u).*ind_pt_ls + (1-P.c_pt_u).*(ind_pt_ls>1-P.c_pt_u);

ind_inc_pt_r  = ind_pt_ls_r.^P.nu*wa*P.kappa+ind_inc_r.*(1-P.c_pt_r-ind_pt_ls_r)-P.c_pt_2;
ind_inc_pt_u  = ind_pt_ls_u.^P.nu*wa*P.kappa+ind_inc_u.*(1-P.c_pt_u-ind_pt_ls_u)-P.c_pt_2;

% Occupational Choice
dummy_urban  = (ind_inc_u>ind_inc_r) & (ind_inc_u>ind_inc_a) & ...
    (ind_inc_u>ind_inc_pt_r) & (ind_inc_u>ind_inc_pt_u);
dummy_rural  = (ind_inc_r>ind_inc_u) & (ind_inc_r>ind_inc_a) & ...
    (ind_inc_r>ind_inc_pt_r) & (ind_inc_r>ind_inc_pt_u);
dummy_agr    = (ind_inc_a>ind_inc_u) & (ind_inc_a>ind_inc_r) & ...
    (ind_inc_a>ind_inc_pt_r) & (ind_inc_a>ind_inc_pt_u);
dummy_pt_u   = (ind_inc_pt_u>ind_inc_u) & (ind_inc_pt_u>ind_inc_r) & ...
    (ind_inc_pt_u>ind_inc_a) & (ind_inc_pt_u>ind_inc_pt_r);
dummy_pt_r   = (ind_inc_pt_r>ind_inc_u) & (ind_inc_pt_r>ind_inc_r) & ...
    (ind_inc_pt_r>ind_inc_a) & (ind_inc_pt_r>ind_inc_pt_u);

% Income from non-farm-operator sources
ind_inc_nonop = dummy_urban.*ind_inc_u + dummy_rural.*ind_inc_r ...
    + dummy_agr.*ind_inc_a + dummy_pt_u.*ind_inc_pt_u + dummy_pt_r.*ind_inc_pt_r;


% Choose the farm operator


rentalChoice


% We hold the operator as exogenous
temp = sum(ind_inc_nonop,2);
hh_inc_total = zeros(P.N_sim,1);
for i = 1:P.N_sim
    hh_inc_total(i) = temp(i) - ind_inc_nonop(i,operator(i)) + ind_pi(i,operator(i));
end



% We allow no one is the operator (whole family migrated)
hh_b = hh_lambda.*l_bar.*hh_varphi;
hh_migration = (temp-hh_b+l_bar.*q)>hh_inc_total;
hh_inc_total = hh_inc_total.*(1-hh_migration)+(temp+l_bar.*q-hh_b).*hh_migration;


% Adjust for the operator dummies
dummy_ope = zeros(P.N_sim,P.N_ind);
for i=1:P.N_ind
    dummy_ope(:,i) = (operator==i).*(1-hh_migration);
end

dummy_urban  = dummy_urban.*(1-dummy_ope);
dummy_rural  = dummy_rural.*(1-dummy_ope);
dummy_agr    = dummy_agr  .*(1-dummy_ope);
dummy_pt_u   = dummy_pt_u .*(1-dummy_ope);
dummy_pt_r   = dummy_pt_r .*(1-dummy_ope);

% Farm-level problem
farm_s    = sum(ind_s.*dummy_ope,2);
farm_tauy = sum(ind_tauy.*dummy_ope,2);
farm_taul = sum(ind_taul.*dummy_ope,2);

farm_rentin  = sum(ind_l_rentin .*dummy_ope,2);
farm_rentout = sum(ind_l_rentout.*dummy_ope,2);

dummy_farm_rentin  = sum(dummy_ind_rentin .*dummy_ope,2);
dummy_farm_rentout = sum(dummy_ind_rentout.*dummy_ope,2);
dummy_farm_rentno  = sum(dummy_ind_rentno .*dummy_ope,2);



farm_n    = sum(ind_n.*dummy_ope,2);
farm_l    = sum(ind_l.*dummy_ope,2);
farm_pi   = sum(ind_pi.*dummy_ope,2);
farm_y    = P.A*farm_s.*farm_l.^(P.theta*P.gamma).*farm_n.^((1-P.theta)*P.gamma);



