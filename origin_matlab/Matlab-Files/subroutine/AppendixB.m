% This is the code that calculate the matrix of sensitivity analysis in
% Appendix B.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024




rng("default");




%% Calculate moments for baseline calibration 

jacobianBaseline



%% Calculate moments for the sensitivity economy

% Change one parameter by 5 percent (instead of 1 percent to reduce
% numerical erros. We will adjust for this amount when we calculate the
% elasticity. 

adj_factor = 0.05;

X = parameter;
assignParameterValue
P.mu_varphi = log(exp(P.mu_varphi)*(1+adj_factor));

fprintf('-------------------------------------------------- \n');
fprintf('Changed parameter: mu_phi: \n');

jacobianAlt


X = parameter;
assignParameterValue
P.mu_xiu_y = log(exp(P.mu_xiu_y)*(1+adj_factor));
P.mu_xir_y = log(exp(P.mu_xir_y)*(1+adj_factor));

P.mu_xiu_o = log(exp(P.mu_xiu_o)*(1+adj_factor));
P.mu_xir_o = log(exp(P.mu_xir_o)*(1+adj_factor));

fprintf('-------------------------------------------------- \n');
fprintf('Changed parameter: mu_xi: \n');

jacobianAlt


X = parameter;
assignParameterValue
P.sigma_varphi = P.sigma_varphi * (1+adj_factor);

fprintf('-------------------------------------------------- \n');
fprintf('Changed parameter: sigma_phi: \n');

jacobianAlt


X = parameter;
assignParameterValue
P.sigma_xir = P.sigma_xir * (1+adj_factor); P.sigma_xiu = P.sigma_xir;

fprintf('-------------------------------------------------- \n');
fprintf('Changed parameter: sigma_xi: \n');

jacobianAlt



X = parameter;
assignParameterValue
P.cbar = P.cbar * (1+adj_factor);

fprintf('-------------------------------------------------- \n');
fprintf('Changed parameter: abar: \n');

jacobianAlt



X = parameter;
assignParameterValue
P.c_pt_r = P.c_pt_r * (1+adj_factor); P.c_pt_u = P.c_pt_u * (1+adj_factor);

fprintf('-------------------------------------------------- \n');
fprintf('Changed parameter: c: \n');

jacobianAlt


adj_factor = 0.01; % Sensitive to the value of kappa.
X = parameter;
assignParameterValue
P.kappa = P.kappa * (1+adj_factor);

fprintf('-------------------------------------------------- \n');
fprintf('Changed parameter: kappa: \n');

jacobianAlt


adj_factor = 0.05;
X = parameter;
assignParameterValue
P.sigma_tauy = P.sigma_tauy * (1+adj_factor);

fprintf('-------------------------------------------------- \n');
fprintf('Changed parameter: sigma_tauy: \n');

jacobianAlt


X = parameter;
assignParameterValue
P.zeta_tauy = P.zeta_tauy * (1+adj_factor);

fprintf('-------------------------------------------------- \n');
fprintf('Changed parameter: zeta_tauy: \n');

jacobianAlt


X = parameter;
assignParameterValue
P.omega = P.omega * (1+adj_factor);

fprintf('-------------------------------------------------- \n');
fprintf('Changed parameter: lambda (omega): \n');

jacobianAlt



X = parameter;
assignParameterValue
P.sigma_sH = P.sigma_sH * (1+adj_factor);

fprintf('-------------------------------------------------- \n');
fprintf('Changed parameter: sigma_sH: \n');

jacobianAlt



X = parameter;
assignParameterValue
P.sigma_sI = P.sigma_sI * (1+adj_factor);

fprintf('-------------------------------------------------- \n');
fprintf('Changed parameter: sigma_sI: \n');

jacobianAlt



X = parameter;
X(4) = X(4) * (1+adj_factor);
assignParameterValue

fprintf('-------------------------------------------------- \n');
fprintf('Changed parameter: IH ratio: \n');

jacobianAlt



X = parameter;
assignParameterValue
P.B = P.B * (1+adj_factor);

fprintf('-------------------------------------------------- \n');
fprintf('Changed parameter: hbar: \n');

jacobianAlt


