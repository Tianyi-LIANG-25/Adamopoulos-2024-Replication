% This subroutine assigns value to parameters that do not depend on general
% equilibrium.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

P.N_sim       = 30000; % Number of simulated individuals


if case_id == 1 % baseline calibration


    P.ope_ls      = 0.0;

    P.gamma       = 0.75;
    P.theta       = 0.533;
    P.A           = 1;
    P.Ar          = 0.00001;
    P.nu          = 0.6;

    P.phi         = 0.02;
    P.LS          = 1;

    P.N_ind       = 3;

    P.old         = 0.4053;

    P.Nn_u        = 1.3385;
    P.Nn_r        = 0;

    P.Au          = 1;
    P.mu_xir_y    = 100;
    P.mu_xir_o    = 100;
    P.c_pt_r      = 0.99999;

    P.epsilon_PIGL = 0.7;
    P.gamma_PIGL   = 0.3;

    P.lambda      = 1;

    P.mu_eta      = 0.05108;

elseif case_id == 2 % 2018 calibration

    P.ope_ls      = 0.0;


    P.gamma       = 0.75;
    P.theta       = 0.533;
    P.A           = 1;
    P.Ar          = 0.00001;
    P.nu          = 0.6;

    P.phi         = 0.02;
    P.LS          = 1;

    P.N_ind       = 3;
    P.Nn_r        = 0;
    P.Nn_u        = 4.6693;

    P.old         = 0.5217;

    P.Au          = 1;
    P.mu_xir_y    = 100;
    P.mu_xir_o    = 100;
    P.c_pt_r      = 0.99999;

    P.epsilon_PIGL = 0.7;
    P.gamma_PIGL   = 0.3;

    P.lambda      = 1;

    P.mu_eta      = 0.007875;

elseif case_id == 3 % no eta calibration

    P.ope_ls      = 0.0;

    P.gamma       = 0.75;
    P.theta       = 0.533;
    P.A           = 1;
    P.Ar          = 0.00001;
    P.nu          = 0.6;

    P.phi         = 0.02;
    P.LS          = 1;

    P.N_ind       = 3;

    P.old         = 0.4053;

    P.Nn_u        = 1.3385;
    P.Nn_r        = 0;

    P.Au          = 1;
    P.mu_xir_y    = 100;
    P.mu_xir_o    = 100;
    P.c_pt_r      = 0.99999;

    P.epsilon_PIGL = 0.7;
    P.gamma_PIGL   = 0.3;

    P.lambda      = 1;

    P.mu_eta      = 0.0001;

elseif case_id == 4 % 2 nonagr sectors

    P.ope_ls      = 0.0;

    P.gamma       = 0.75;
    P.theta       = 0.533;
    P.A           = 1;
    P.Ar          = 1;
    P.nu          = 0.6;

    P.phi         = 0.02;
    P.LS          = 1;

    P.N_ind       = 3;
    P.Nn_r        = 0.3136;
    P.Nn_u        = 1.0249;

    P.old         = 0.4053;

    P.epsilon_PIGL = 0.7;
    P.gamma_PIGL   = 0.3;

    P.lambda      = 1;

    P.mu_eta      = 0.05108;

elseif case_id == 5 % 2 nonagr sectors and cohort differences

    P.ope_ls      = 0.0;

    P.gamma       = 0.75;
    P.theta       = 0.533;
    P.A           = 1;
    P.Ar          = 1;
    P.nu          = 0.6;

    P.phi         = 0.02;
    P.LS          = 1;

    P.N_ind       = 3;
    P.Nn_r        = 0.3136;
    P.Nn_u        = 1.0249;

    P.old         = 0.4053;

    P.epsilon_PIGL = 0.7;
    P.gamma_PIGL   = 0.3;

    P.lambda      = 1;

    P.mu_eta      = 0.05108;


elseif case_id == 6 % remote


    P.ope_ls      = 0.0;

    P.gamma       = 0.75;
    P.theta       = 0.533;
    P.A           = 1;
    P.Ar          = 1;
    P.nu          = 0.6;

    P.phi         = 0.02;
    P.LS          = 1;

    P.N_ind       = 3;
    P.Nn_r        = 0.3136;
    P.Nn_u        = 1.0249;

    P.old         = 0.4024;

    P.epsilon_PIGL = 0.7;
    P.gamma_PIGL   = 0.3;

    P.lambda      = 1;

    P.mu_eta      = 0.05242;

elseif case_id == 7 % 2 peri-urban

    P.ope_ls      = 0.0;

    P.gamma       = 0.75;
    P.theta       = 0.533;
    P.A           = 1;
    P.Ar          = 1;
    P.nu          = 0.6;

    P.phi         = 0.02;
    P.LS          = 1;

    P.N_ind       = 3;
    P.Nn_r        = 0.3136;
    P.Nn_u        = 1.0249;

    P.old         = 0.4175;

    P.epsilon_PIGL = 0.7;
    P.gamma_PIGL   = 0.3;

    P.lambda      = 1;

    P.mu_eta      = 0.04608;


elseif case_id == 8 % no xi calibration


    P.ope_ls      = 0.0;

    P.gamma       = 0.75;
    P.theta       = 0.533;
    P.A           = 1;
    P.Ar          = 0.00001;
    P.nu          = 0.6;

    P.phi         = 0.02;
    P.LS          = 1;

    P.N_ind       = 3;

    P.old         = 0.4053;

    P.Nn_u        = 1.3385;
    P.Nn_r        = 0;

    P.Au          = 1;
    P.mu_xir_y    = 100;
    P.mu_xir_o    = 100;
    P.c_pt_r      = 0.99999;

    P.epsilon_PIGL = 0.7;
    P.gamma_PIGL   = 0.3;

    P.lambda      = 1;

    P.mu_eta      = 0.05108;

elseif case_id == 9 % no correlation between abilities


    P.ope_ls      = 0.0;

    P.gamma       = 0.75;
    P.theta       = 0.533;
    P.A           = 1;
    P.Ar          = 0.00001;
    P.nu          = 0.6;

    P.phi         = 0.02;
    P.LS          = 1;

    P.N_ind       = 3;

    P.old         = 0.4053;

    P.Nn_u        = 1.3385;
    P.Nn_r        = 0;

    P.Au          = 1;
    P.mu_xir_y    = 100;
    P.mu_xir_o    = 100;
    P.c_pt_r      = 0.99999;

    P.epsilon_PIGL = 0.7;
    P.gamma_PIGL   = 0.3;

    P.lambda      = 1;

    P.mu_eta      = 0.05108;

elseif case_id == 10 % higher correlation between abilities


    P.ope_ls      = 0.0;

    P.gamma       = 0.75;
    P.theta       = 0.533;
    P.A           = 1;
    P.Ar          = 0.00001;
    P.nu          = 0.6;

    P.phi         = 0.02;
    P.LS          = 1;

    P.N_ind       = 3;

    P.old         = 0.4053;

    P.Nn_u        = 1.3385;
    P.Nn_r        = 0;

    P.Au          = 1;
    P.mu_xir_y    = 100;
    P.mu_xir_o    = 100;
    P.c_pt_r      = 0.99999;

    P.epsilon_PIGL = 0.7;
    P.gamma_PIGL   = 0.3;

    P.lambda      = 1;

    P.mu_eta      = 0.05108;


elseif case_id == 11 % PIGL preferences

    P.ope_ls      = 0.0;

    P.gamma       = 0.75;
    P.theta       = 0.533;
    P.A           = 1;
    P.Ar          = 0.00001;
    P.nu          = 0.6;

    P.phi         = 0.00001;
    P.LS          = 1;

    P.N_ind       = 3;

    P.old         = 0.4053;

    P.Nn_u        = 1.3385;
    P.Nn_r        = 0;

    P.Au          = 1;
    P.mu_xir_y    = 100;
    P.mu_xir_o    = 100;
    P.c_pt_r      = 0.99999;

    P.epsilon_PIGL = 0.7;
    P.gamma_PIGL   = 0.3;

    P.lambda      = 1;

    P.mu_eta      = 0.05108;


end
