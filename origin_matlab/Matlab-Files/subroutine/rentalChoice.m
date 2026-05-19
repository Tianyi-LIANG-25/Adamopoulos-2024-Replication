% This subroutine calculates the farmer's land rental choices.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

%% Rent in



ind_l_in  = ind_s_tilde.*(P.gamma*p*P.A).^(1/(1-P.gamma))...
    .*(P.theta./(ind_taul.*q)).^((1-(1-P.theta)*P.gamma)/(1-P.gamma))...
    .*((1-P.theta)/wa)^((1-P.theta)*P.gamma/(1-P.gamma));
ind_n_in  = ind_l_in.*(ind_taul.*q./P.theta).*((1-P.theta)./wa);

ind_pi_in = (1-P.gamma)*(P.gamma*p*P.A)^(P.gamma/(1-P.gamma)).*p*P.A.*ind_s_tilde.*...
    (P.theta./(ind_taul.*q)).^((P.theta*P.gamma)/(1-P.gamma))*...
    ((1-P.theta)/wa)^((1-P.theta)*P.gamma/(1-P.gamma))+P.ope_ls*wa+ind_taul.*q.*l_bar;


% Expected profit

ind_pi_in = -999.*(ind_l_in<=l_bar) + ind_pi_in.*(ind_l_in>l_bar);



%% Rent out

l_omega = ind_taul.*q - hh_eta.*hh_varphi*ones(1,P.N_ind);
l_omega = (l_omega>0.0001).*l_omega + (l_omega<=0.0001).*0.0001;

ind_l_out  = ind_s_tilde.*(P.gamma*p*P.A).^(1/(1-P.gamma))...
    .*(P.theta./l_omega).^((1-(1-P.theta)*P.gamma)/(1-P.gamma))...
    .*((1-P.theta)/wa)^((1-P.theta)*P.gamma/(1-P.gamma));
ind_n_out  = ind_l_out.*(l_omega./P.theta).*((1-P.theta)./wa);


ind_pi_out = (1-P.gamma)*(P.gamma*p*P.A)^(P.gamma/(1-P.gamma)).*p*P.A.*ind_s_tilde.*...
    (P.theta./l_omega).^((P.theta*P.gamma)/(1-P.gamma))*...
    ((1-P.theta)/wa)^((1-P.theta)*P.gamma/(1-P.gamma))...
    + P.ope_ls*wa + l_omega.*l_bar;


ind_pi_out = (ind_l_out>=l_bar).*(-999) + (ind_l_out<l_bar).*ind_pi_out;





%% No rentals

% No expropriation

ind_l_no  = l_bar;
ind_n_no  = ind_s_tilde2.*(p*P.A)^(1/(1-P.gamma*(1-P.theta)))...
    .*(P.gamma*(1-P.theta)/wa)^(1/(1-P.gamma*(1-P.theta)))...
    .*ind_l_no.^(P.theta*P.gamma/(1-P.gamma*(1-P.theta)));

ind_pi_no = (1-P.gamma*(1-P.theta))*...
    ind_s_tilde2.*(p*P.A)^(1/(1-P.gamma*(1-P.theta)))...
    .*(P.gamma*(1-P.theta)/wa)^((1-P.theta)*P.gamma/(1-P.gamma*(1-P.theta)))...
    .*ind_l_no.^(P.theta*P.gamma/(1-P.gamma*(1-P.theta))) + P.ope_ls*wa;


%% Make the rental choices

dummy_ind_rentin  = (ind_pi_in > ind_pi_out).*(ind_pi_in > ind_pi_no );
dummy_ind_rentout = (ind_pi_out>=ind_pi_in ).*(ind_pi_out> ind_pi_no );
dummy_ind_rentno  = (ind_pi_no >=ind_pi_in ).*(ind_pi_no >=ind_pi_out);

ind_pi = dummy_ind_rentin.*ind_pi_in ...
    + dummy_ind_rentout.*ind_pi_out ...
    + dummy_ind_rentno.*ind_pi_no;

ind_n  = dummy_ind_rentin.*ind_n_in ...
    + dummy_ind_rentout.*ind_n_out ...
    + dummy_ind_rentno.*ind_n_no;

ind_l  = dummy_ind_rentin.*ind_l_in ...
    + dummy_ind_rentout.*ind_l_out ...
    + dummy_ind_rentno.*ind_l_no;




ind_l_rentin  = (ind_l_in >l_bar).*(ind_l_in-l_bar ).*dummy_ind_rentin;
ind_l_rentout = (ind_l_out<l_bar).*(l_bar-ind_l_out).*dummy_ind_rentout;

