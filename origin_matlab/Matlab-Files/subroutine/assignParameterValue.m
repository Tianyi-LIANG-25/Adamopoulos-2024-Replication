% This subroutine assigns values to parameters.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

if case_id == 1 || case_id == 2 || case_id == 10 
    % baseline or 2018 calibration or high correlation

    P.sigma_omega = 0.0001;
    P.omega       = X(1);
    P.sigma_sH    = X(2);
    P.sigma_sI    = X(2)*X(4);
    P.sigma_hH    = X(3);
    P.sigma_hI    = X(3)*X(4);
    P.mu_sI_y     = 0.0001;
    P.mu_hI_y     = 0.0001;
    P.sigma_tauy  = X(5);
    P.zeta_tauy   = X(6);
    P.sigma_xir   = X(7);
    P.sigma_xiu   = P.sigma_xir;
    P.mu_xiu_y    = X(8);
    P.mu_xiu_o    = P.mu_xiu_y+0;
    P.zeta_xiu    = 0.0001;
    P.zeta_xir    = 0.0001;

    P.sigma_varphi= X(9);
    P.mu_varphi   = X(10);

    P.c_pt_u      = X(11);
    P.c_pt_2      = 0.00;
    P.kappa       = X(12);
    P.cbar        = X(13);
    P.B           = X(14);

    P.sigma_eta   = 0.0001;

elseif case_id == 3 % No eta calibration

    P.sigma_omega = 0.0001;
    P.omega       = X(1);
    P.sigma_sH    = X(2);
    P.sigma_sI    = X(2)*X(4);
    P.sigma_hH    = X(3);
    P.sigma_hI    = X(3)*X(4);
    P.mu_sI_y     = 0.0001;
    P.mu_hI_y     = 0.0001;
    P.sigma_tauy  = X(5);
    P.zeta_tauy   = X(6);
    P.sigma_xir   = X(7);
    P.sigma_xiu   = P.sigma_xir;
    P.mu_xiu_y    = X(8);
    P.mu_xiu_o    = P.mu_xiu_y+0;
    P.zeta_xiu    = 0.0001;
    P.zeta_xir    = 0.0001;


    P.c_pt_u      = X(9);
    P.c_pt_2      = 0.00;
    P.kappa       = X(10);
    P.cbar        = X(11);
    P.B           = X(12);

    P.mu_varphi   = 0.5;
    P.sigma_varphi= 0.0001;

    P.sigma_eta   = 0.0001;

elseif case_id == 4 % 2 non-agr sectors

    P.sigma_omega = 0.0001;
    P.omega       = X(1);
    P.sigma_sH    = X(2);
    P.sigma_sI    = X(2)*X(4);
    P.sigma_hH    = X(3);
    P.sigma_hI    = X(3)*X(4);
    P.mu_sI_y     = 0.0001;
    P.mu_hI_y     = 0.0001;
    P.sigma_tauy  = X(5);
    P.zeta_tauy   = X(6);
    P.sigma_xir   = X(7);
    P.sigma_xiu   = P.sigma_xir;
    P.mu_xiu_y    = X(8);
    P.mu_xir_y    = X(9);
    P.mu_xiu_o    = P.mu_xiu_y+0;
    P.mu_xir_o    = P.mu_xir_y+0;
    P.zeta_xiu    = 0.0001;
    P.zeta_xir    = 0.0001;

    P.sigma_varphi= X(10);
    P.mu_varphi   = X(11);

    P.c_pt_r      = X(12);
    P.c_pt_u      = X(13);
    P.c_pt_2      = 0.00;
    P.kappa       = X(14);
    % P.nu_PIGL     = 0.6080;
    P.cbar        = X(15);
    P.Au          = X(16);
    P.B           = X(17);



    P.sigma_eta   = 0.0001;


elseif case_id == 5 || case_id == 6 || case_id == 7
    % 2 non-agr sectors and age differences, OR
    % remote calibration
    % suburban calibration

    P.sigma_omega = 0.0001;
    P.omega       = X(1);
    P.sigma_sH    = X(2);
    P.sigma_sI    = X(2)*X(4);
    P.sigma_hH    = X(3);
    P.sigma_hI    = X(3)*X(4);
    P.mu_sI_y     = X(5);
    P.mu_hI_y     = X(6);
    P.sigma_tauy  = X(7);
    P.zeta_tauy   = X(8);
    P.sigma_xir   = X(9);
    P.sigma_xiu   = P.sigma_xir;
    P.mu_xiu_y    = X(10);
    P.mu_xir_y    = X(11);
    P.mu_xiu_o    = P.mu_xiu_y+X(12);
    P.mu_xir_o    = P.mu_xir_y+X(13);
    P.zeta_xiu    = 0.0001;
    P.zeta_xir    = 0.0001;

    P.sigma_varphi= X(14);
    P.mu_varphi   = X(15);
    

    P.c_pt_r      = X(16);
    P.c_pt_u      = X(17);
    P.c_pt_2      = 0.00;
    P.kappa       = X(18);
    % P.nu_PIGL     = 0.6080;
    P.cbar        = X(19);
    P.Au          = X(20);
    P.B           = X(21);

    

    P.sigma_eta   = 0.0001;

elseif case_id == 8 % No xi calibration

    P.sigma_omega = 0.0001;
    P.omega       = X(1);
    P.sigma_sH    = X(2);
    P.sigma_sI    = X(2)*X(4);
    P.sigma_hH    = X(3);
    P.sigma_hI    = X(3)*X(4);
    P.mu_sI_y     = 0.0001;
    P.mu_hI_y     = 0.0001;
    P.sigma_tauy  = X(5);
    P.zeta_tauy   = X(6);
    P.sigma_xir   = 0.0001;
    P.sigma_xiu   = P.sigma_xir;
    P.mu_xiu_y    = -999;
    P.mu_xiu_o    = P.mu_xiu_y+0;
    P.zeta_xiu    = 0.0001;
    P.zeta_xir    = 0.0001;

    P.sigma_varphi= X(7);
    P.mu_varphi   = X(8);

    P.c_pt_u      = X(9);
    P.c_pt_2      = 0.00;
    P.kappa       = X(10);
    P.cbar        = X(11);
    P.B           = X(12);

    P.sigma_eta   = 0.0001;

elseif case_id == 9 % no correlation between abilities

    P.sigma_omega = 0.0001;
    P.omega       = 0.0001;
    P.sigma_sH    = X(1);
    P.sigma_sI    = X(1)*X(3);
    P.sigma_hH    = X(2);
    P.sigma_hI    = X(2)*X(3);
    P.mu_sI_y     = 0.0001;
    P.mu_hI_y     = 0.0001;
    P.sigma_tauy  = X(4);
    P.zeta_tauy   = X(5);
    P.sigma_xir   = X(6);
    P.sigma_xiu   = P.sigma_xir;
    P.mu_xiu_y    = X(7);
    % P.mu_xir_y    = X(11);
    P.mu_xiu_o    = P.mu_xiu_y+0;
    % P.mu_xir_o    = P.mu_xir_y+X(13);
    P.zeta_xiu    = 0.0001;
    P.zeta_xir    = 0.0001;

    P.sigma_varphi= X(8);
    P.mu_varphi   = X(9);


    % P.c_pt_r      = X(16);
    P.c_pt_u      = X(10);
    P.c_pt_2      = 0.00;
    P.kappa       = X(11);
    % P.nu_PIGL     = 0.6080;
    P.cbar        = X(12);
    % P.Au          = X(20);
    P.B           = X(13);

    P.sigma_eta   = 0.0001;


elseif case_id == 11
    % PIGL

    P.sigma_omega = 0.0001;
    P.omega       = X(1);
    P.sigma_sH    = X(2);
    P.sigma_sI    = X(2)*X(4);
    P.sigma_hH    = X(3);
    P.sigma_hI    = X(3)*X(4);
    P.mu_sI_y     = 0.0001;
    P.mu_hI_y     = 0.0001;
    P.sigma_tauy  = X(5);
    P.zeta_tauy   = X(6);
    P.sigma_xir   = X(7);
    P.sigma_xiu   = P.sigma_xir;
    P.mu_xiu_y    = X(8);
    % P.mu_xir_y    = X(11);
    P.mu_xiu_o    = P.mu_xiu_y+0;
    % P.mu_xir_o    = P.mu_xir_y+X(13);
    P.zeta_xiu    = 0.0001;
    P.zeta_xir    = 0.0001;

    P.sigma_varphi= X(9);
    P.mu_varphi   = X(10);


    % P.c_pt_r      = X(16);
    P.c_pt_u      = X(11);
    P.c_pt_2      = 0.00;
    P.kappa       = X(12);
    P.nu_PIGL     = X(13);
    P.cbar        = 0.00001;
    % P.Au          = X(20);
    P.B           = X(14);

    P.sigma_eta   = 0.0001;


end


