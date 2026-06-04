"""
module.py — Functions for the Adamopoulos et al. (2024) replication.

Translated from origin_matlab/Matlab-Files/subroutine/*.m
Original authors: Adamopoulos, Brandt, Chen, Restuccia, Wei (QJE 2024)

This module contains all functions needed to solve the initial equilibrium
(calibration + endogenous price determination) of the baseline model (case_id=1).

Architecture (bottom-up):
  Layer 0: Helper functions
  Layer 1: Data moments and parameter setup
  Layer 2: Individual heterogeneity (ability generation)
  Layer 3: Individual decisions given prices (rental choice, occupational choice)
  Layer 4: Market clearing (land, labor, agricultural goods, non-agricultural)
  Layer 5: Equilibrium solver (inner loop)
  Layer 6: Model moments
  Layer 7: Calibration objective (outer loop evaluation)

All state is passed explicitly via dictionaries — no global variables.
"""

import numpy as np
from scipy.stats import norm as scipy_norm
from scipy.stats import spearmanr
from scipy.stats.qmc import Halton
from scipy.optimize import least_squares

# ===========================================================================
# Layer 0: Helper Functions
# ===========================================================================

def occu_separate(occupation, X, dummy):
    """
    Filter elements of X where occupation == dummy.
    Equivalent to MATLAB occuSeparate.m

    Parameters
    ----------
    occupation : np.ndarray (N,) or (N,1)
        Binary or integer indicator array.
    X : np.ndarray (N,) or (N,1)
        Values to filter.
    dummy : scalar
        The value to match in occupation.

    Returns
    -------
    CC : np.ndarray (K,)
        X[occupation == dummy], flattened. Returns empty array if no matches.
    """
    occupation = np.asarray(occupation).flatten()
    X = np.asarray(X).flatten()
    mask = occupation == dummy
    return X[mask]


# ===========================================================================
# Layer 1: Data Moments and Parameter Setup
# ===========================================================================

def get_data_moments(case_id=1):
    """
    Return hardcoded data moments for 2004 nationwide.
    Equivalent to dataMoments.m (datafile-2004-nationwide.mat section).

    Parameters
    ----------
    case_id : int
        Only case_id=1 (baseline) is implemented.

    Returns
    -------
    moments : dict
        Data moments keyed by name.
    """
    if case_id != 1:
        raise ValueError(f"Only case_id=1 is implemented, got {case_id}")

    moments = {
        # Part 1: Employment shares
        'data_farm_ope_emp':       0.2755,
        'data_agr_emp':            0.2152,
        'data_rural_nonagr_emp':   0.1479,
        'data_urban_nonagr_emp':   0.1545,
        'data_parttime_rural_emp': 0.1590,
        'data_parttime_urban_emp': 0.0480,
        'data_ave_hour_pt':        0.2857,
        'data_corr_inc_ls_pt':     0.3978,

        # Part 2: Family choices
        'data_PCT_family_operator': 0.7371,

        # Part 3: Income moments
        'data_std_inc_nonagr':        0.6097,
        'data_std_inc_nonagr_across': 0.5581,
        'data_inc_diff_uo':           0.3677 - np.log(365/274),
        'data_inc_diff_uo_2nonagr':   0.3067 - np.log(365/274),
        'data_inc_diff_ur_2nonagr':  -0.1545,
        'data_corr_pi_nonagr':        0.0796,

        # Part 4: Agr production moments
        'data_std_farm_TFPQ':             0.6573,
        'data_std_farm_TFPR':             0.6329,
        'data_corr_farm_TFPQ_TFPR':       0.9678,
        'data_inc_diff_nonagr_migration': -0.2806,

        # Part 5: National Account
        'data_GLW_inv': 0.1517 / 0.3907,
    }
    return moments


def set_exogenous_params(case_id=1):
    """
    Set exogenous parameters that do not depend on general equilibrium.
    Equivalent to parameterExo.m (case_id==1 branch).

    Parameters
    ----------
    case_id : int
        Only case_id=1 (baseline) is implemented.

    Returns
    -------
    P : dict
        Exogenous parameter dictionary.
    """
    if case_id != 1:
        raise ValueError(f"Only case_id=1 is implemented, got {case_id}")

    P = {}

    # Number of simulated individuals and family members
    P['N_sim'] = 30000
    P['N_ind'] = 3

    # Operator labour supply
    P['ope_ls'] = 0.0

    # Production function parameters
    P['gamma'] = 0.75       # span-of-control / returns to scale
    P['theta'] = 0.533      # land share in agriculture
    P['A']     = 1.0        # agricultural TFP
    P['Ar']    = 0.00001    # rural non-agricultural TFP (effectively zero in 1-nonagr model)

    # Preferences
    P['nu']  = 0.6          # curvature on agricultural labour disutility
    P['phi'] = 0.02         # agricultural expenditure share (Stone-Geary)
    P['LS']  = 1.0          # per-capita land endowment

    # Demographics
    P['old']  = 0.4053      # fraction old
    P['Nn_u'] = 1.3385      # urban non-agricultural population (relative to rural hukou)
    P['Nn_r'] = 0.0         # rural non-agricultural population (zero in 1-nonagr model)

    # Urban TFP and rural-wedge (effectively turn off rural non-agr in baseline)
    P['Au']       = 1.0
    P['mu_xir_y'] = 100.0       # effectively infinite rural mobility barrier (young)
    P['mu_xir_o'] = 100.0       # effectively infinite rural mobility barrier (old)
    P['c_pt_r']   = 0.99999     # effectively disable rural part-time

    # PIGL preference parameters (not used in baseline, but set for completeness)
    P['epsilon_PIGL'] = 0.7
    P['gamma_PIGL']   = 0.3

    # Land expropriation
    P['lambda'] = 1.0
    P['mu_eta'] = 0.05108      # expropriation probability

    return P


def assign_parameter_value(X, case_id=1):
    """
    Map calibration vector X to parameter dictionary P.
    Equivalent to assignParameterValue.m (case_id==1 branch).

    For baseline (case_id=1), X is a 14-element vector:
      X[0]  → P.omega       (ability correlation)
      X[1]  → P.sigma_sH    (household-level agricultural ability dispersion)
      X[2]  → P.sigma_hH    (household-level non-agr ability dispersion)
      X[3]  → ratio H/I     (individual/household dispersion ratio)
      X[4]  → P.sigma_tauy  (output wedge dispersion)
      X[5]  → P.zeta_tauy   (output wedge scale elasticity)
      X[6]  → P.sigma_xir   (mobility barrier dispersion)
      X[7]  → P.mu_xiu_y    (urban mobility barrier level, young)
      X[8]  → P.sigma_varphi (land compensation dispersion)
      X[9]  → P.mu_varphi   (land compensation mean)
      X[10] → P.c_pt_u      (urban part-time fixed cost)
      X[11] → P.kappa       (part-time productivity)
      X[12] → P.cbar        (subsistence consumption)
      X[13] → P.B           (non-agr population ability scaling)

    Parameters
    ----------
    X : np.ndarray (14,)
        Calibration parameter vector.
    case_id : int
        Only case_id=1 (baseline) is implemented.

    Returns
    -------
    P : dict
        Parameter dictionary (merged with exogenous params).
    """
    if case_id not in (1, 2, 10):
        # For case_id=1,2,10 the mapping is identical
        raise ValueError(f"Only case_id=1 is implemented, got {case_id}")

    P = {}

    P['sigma_omega'] = 0.0001

    P['omega']       = X[0]
    P['sigma_sH']    = X[1]
    P['sigma_sI']    = X[1] * X[3]
    P['sigma_hH']    = X[2]
    P['sigma_hI']    = X[2] * X[3]
    P['mu_sI_y']     = 0.0001
    P['mu_hI_y']     = 0.0001

    P['sigma_tauy']  = X[4]
    P['zeta_tauy']   = X[5]

    P['sigma_xir']   = X[6]
    P['sigma_xiu']   = P['sigma_xir']
    P['mu_xiu_y']    = X[7]
    P['mu_xiu_o']    = P['mu_xiu_y'] + 0.0
    P['zeta_xiu']    = 0.0001
    P['zeta_xir']    = 0.0001

    P['sigma_varphi'] = X[8]
    P['mu_varphi']    = X[9]

    P['c_pt_u']  = X[10]
    P['c_pt_2']  = 0.00
    P['kappa']   = X[11]
    P['cbar']    = X[12]
    P['B']       = X[13]

    P['sigma_eta'] = 0.0001

    return P


# ===========================================================================
# Layer 2: Individual Heterogeneity
# ===========================================================================

def generate_abilities(P, halton_seq):
    """
    Generate ability distributions and labour mobility barriers.
    Equivalent to ability.m

    Uses a Halton quasi-random sequence for reproducibility.

    Parameters
    ----------
    P : dict
        Parameter dictionary (must contain N_sim, N_ind, sigma_sH, sigma_hH,
        sigma_sI, sigma_hI, sigma_omega, sigma_xir, sigma_xiu, mu_xir_y,
        mu_xir_o, mu_xiu_y, mu_xiu_o, zeta_xir, zeta_xiu, mu_sI_y, mu_hI_y,
        omega, old).
    halton_seq : np.ndarray (N_sim, 30)
        Halton sequence draws.

    Returns
    -------
    results : dict
        Contains ind_s, ind_h, ind_xir, ind_xiu, dummy_old arrays.
    """
    N_sim = P['N_sim']
    N_ind = P['N_ind']

    # Determine old/young status from first 3 Halton dimensions
    dummy_old = halton_seq[:, :3] < P['old']  # (N_sim, 3)

    # Household-level abilities (common across family members)
    # HA(:,4) → column 3; HA(:,5) → column 4
    sH = np.exp(scipy_norm.ppf(halton_seq[:, 3],
                                loc=-P['sigma_sH']**2 / 2,
                                scale=P['sigma_sH']))
    hH = np.exp(scipy_norm.ppf(halton_seq[:, 4],
                                loc=-P['sigma_hH']**2 / 2,
                                scale=P['sigma_hH']))

    # Individual-level arrays
    ind_s   = np.ones((N_sim, N_ind))
    ind_h   = np.ones((N_sim, N_ind))
    ind_xir = np.zeros((N_sim, N_ind))
    ind_xiu = np.zeros((N_sim, N_ind))

    for i in range(N_ind):
        # Halton column indices (MATLAB: 6+(i-1)*5, 7+(i-1)*5, 8+(i-1)*5, ...)
        col_base = 5 + i * 5  # 0-indexed: 5, 10, 15 for i=0,1,2

        # omega: HA(:,8+(i-1)*5) → column 7, 12, 17
        omega = np.exp(scipy_norm.ppf(halton_seq[:, col_base + 2],
                                       loc=-P['sigma_omega']**2 / 2,
                                       scale=P['sigma_omega']))

        # sI: HA(:,6+(i-1)*5) → column 5, 10, 15
        sI = np.exp(scipy_norm.ppf(halton_seq[:, col_base],
                                    loc=-P['sigma_sI']**2 / 2,
                                    scale=P['sigma_sI']))
        # hI: HA(:,7+(i-1)*5) → column 6, 11, 16
        hI = np.exp(scipy_norm.ppf(halton_seq[:, col_base + 1],
                                    loc=-P['sigma_hI']**2 / 2,
                                    scale=P['sigma_hI']))

        # Individual ability
        h = omega * hH * hI
        s = omega * sH * sI * h ** P['omega']

        # Age effects on ability (young get premium if mu_*_y > 0)
        s = s * np.exp(P['mu_sI_y'] * (1 - dummy_old[:, i]))
        h = h * np.exp(P['mu_hI_y'] * (1 - dummy_old[:, i]))

        ind_s[:, i] = s
        ind_h[:, i] = h

        # Rural mobility barrier (logistic function)
        # HA(:,9+(i-1)*5) → column 8, 13, 18
        log_h = np.log(ind_h[:, i])
        xir_raw_old = (P['zeta_xir'] * log_h +
                       scipy_norm.ppf(halton_seq[:, col_base + 3],
                                      loc=P['mu_xir_o'] - P['sigma_xir']**2 / 2,
                                      scale=P['sigma_xir']))
        xir_raw_young = (P['zeta_xir'] * log_h +
                         scipy_norm.ppf(halton_seq[:, col_base + 3],
                                        loc=P['mu_xir_y'] - P['sigma_xir']**2 / 2,
                                        scale=P['sigma_xir']))
        ind_xir[:, i] = (np.exp(xir_raw_old) / (1 + np.exp(xir_raw_old)) * dummy_old[:, i] +
                         np.exp(xir_raw_young) / (1 + np.exp(xir_raw_young)) * (1 - dummy_old[:, i]))

        # Urban mobility barrier (logistic function)
        # HA(:,10+(i-1)*5) → column 9, 14, 19
        xiu_raw_old = (P['zeta_xiu'] * log_h +
                       scipy_norm.ppf(halton_seq[:, col_base + 4],
                                      loc=P['mu_xiu_o'] - P['sigma_xiu']**2 / 2,
                                      scale=P['sigma_xiu']))
        xiu_raw_young = (P['zeta_xiu'] * log_h +
                         scipy_norm.ppf(halton_seq[:, col_base + 4],
                                        loc=P['mu_xiu_y'] - P['sigma_xiu']**2 / 2,
                                        scale=P['sigma_xiu']))
        ind_xiu[:, i] = (np.exp(xiu_raw_old) / (1 + np.exp(xiu_raw_old)) * dummy_old[:, i] +
                         np.exp(xiu_raw_young) / (1 + np.exp(xiu_raw_young)) * (1 - dummy_old[:, i]))

    return {
        'ind_s': ind_s,
        'ind_h': ind_h,
        'ind_xir': ind_xir,
        'ind_xiu': ind_xiu,
        'dummy_old': dummy_old,
    }


# ===========================================================================
# Layer 3: Individual Decisions (given prices)
# ===========================================================================

def rental_choice(p, q, wa, P, ind_s_tilde, ind_s_tilde2, ind_tauy, ind_taul,
                  hh_eta, hh_lambda, hh_varphi, l_bar):
    """
    Farmer's land rental decision: rent-in, rent-out, or no rental.
    Equivalent to rentalChoice.m

    For each individual, computes profit under three regimes and selects the
    profit-maximizing one.

    Parameters
    ----------
    p, q, wa : float
        Agricultural price, land rental rate, agricultural wage.
    P : dict
        Parameter dictionary.
    ind_s_tilde, ind_s_tilde2 : np.ndarray (N_sim, N_ind)
        Ability indices (adjusted for output wedges).
    ind_tauy, ind_taul : np.ndarray (N_sim, N_ind)
        Output and land wedges.
    hh_eta, hh_lambda : np.ndarray (N_sim,)
        Expropriation probability.
    hh_varphi : np.ndarray (N_sim,)
        Land compensation factor.
    l_bar : np.ndarray (N_sim, 1)
        Per-capita land endowment (= P.LS).

    Returns
    -------
    results : dict
        ind_pi, ind_n, ind_l, ind_l_rentin, ind_l_rentout,
        dummy_ind_rentin, dummy_ind_rentout, dummy_ind_rentno.
    """
    N_sim = P['N_sim']
    N_ind = P['N_ind']
    gamma = P['gamma']
    theta = P['theta']
    A = P['A']
    ope_ls = P['ope_ls']

    # Common factor for optimal land/labour demand
    # ind_l = ind_s_tilde * (gamma * p * A)^{1/(1-gamma)} * ...
    common_factor = (gamma * p * A) ** (1.0 / (1.0 - gamma))

    # ---- Rent-in ----
    # Effective land price for rent-in: ind_taul * q
    eff_q_in = ind_taul * q  # (N_sim, N_ind)

    ind_l_in = (ind_s_tilde * common_factor *
                (theta / eff_q_in) ** ((1.0 - (1.0 - theta) * gamma) / (1.0 - gamma)) *
                ((1.0 - theta) / wa) ** ((1.0 - theta) * gamma / (1.0 - gamma)))

    ind_n_in = ind_l_in * (eff_q_in / theta) * ((1.0 - theta) / wa)

    ind_pi_in = ((1.0 - gamma) * (gamma * p * A) ** (gamma / (1.0 - gamma)) *
                 p * A * ind_s_tilde *
                 (theta / eff_q_in) ** ((theta * gamma) / (1.0 - gamma)) *
                 ((1.0 - theta) / wa) ** ((1.0 - theta) * gamma / (1.0 - gamma)) +
                 ope_ls * wa + ind_taul * q * l_bar)

    # Rent-in only valid if optimal land > endowment
    ind_pi_in = np.where(ind_l_in > l_bar, ind_pi_in, -999.0)

    # ---- Rent-out ----
    # Effective land price for rent-out: reduced by expropriation risk
    l_omega = ind_taul * q - hh_eta[:, np.newaxis] * hh_varphi[:, np.newaxis] * np.ones((1, N_ind))
    l_omega = np.maximum(l_omega, 0.0001)  # floor at small positive value

    ind_l_out = (ind_s_tilde * common_factor *
                 (theta / l_omega) ** ((1.0 - (1.0 - theta) * gamma) / (1.0 - gamma)) *
                 ((1.0 - theta) / wa) ** ((1.0 - theta) * gamma / (1.0 - gamma)))

    ind_n_out = ind_l_out * (l_omega / theta) * ((1.0 - theta) / wa)

    ind_pi_out = ((1.0 - gamma) * (gamma * p * A) ** (gamma / (1.0 - gamma)) *
                  p * A * ind_s_tilde *
                  (theta / l_omega) ** ((theta * gamma) / (1.0 - gamma)) *
                  ((1.0 - theta) / wa) ** ((1.0 - theta) * gamma / (1.0 - gamma)) +
                  ope_ls * wa + l_omega * l_bar)

    # Rent-out only valid if optimal land < endowment
    ind_pi_out = np.where(ind_l_out < l_bar, ind_pi_out, -999.0)

    # ---- No rental (self-cultivate endowment) ----
    ind_l_no = l_bar  # use exactly the endowment

    ind_n_no = (ind_s_tilde2 * (p * A) ** (1.0 / (1.0 - gamma * (1.0 - theta))) *
                (gamma * (1.0 - theta) / wa) ** (1.0 / (1.0 - gamma * (1.0 - theta))) *
                ind_l_no ** (theta * gamma / (1.0 - gamma * (1.0 - theta))))

    ind_pi_no = ((1.0 - gamma * (1.0 - theta)) *
                 ind_s_tilde2 *
                 (p * A) ** (1.0 / (1.0 - gamma * (1.0 - theta))) *
                 (gamma * (1.0 - theta) / wa) ** ((1.0 - theta) * gamma / (1.0 - gamma * (1.0 - theta))) *
                 ind_l_no ** (theta * gamma / (1.0 - gamma * (1.0 - theta))) +
                 ope_ls * wa)

    # ---- Make the rental choice ----
    dummy_ind_rentin  = (ind_pi_in > ind_pi_out) & (ind_pi_in > ind_pi_no)
    dummy_ind_rentout = (ind_pi_out >= ind_pi_in) & (ind_pi_out > ind_pi_no)
    dummy_ind_rentno  = (ind_pi_no >= ind_pi_in) & (ind_pi_no >= ind_pi_out)

    ind_pi = (dummy_ind_rentin * ind_pi_in +
              dummy_ind_rentout * ind_pi_out +
              dummy_ind_rentno * ind_pi_no)

    ind_n = (dummy_ind_rentin * ind_n_in +
             dummy_ind_rentout * ind_n_out +
             dummy_ind_rentno * ind_n_no)

    ind_l = (dummy_ind_rentin * ind_l_in +
             dummy_ind_rentout * ind_l_out +
             dummy_ind_rentno * ind_l_no)

    # Land rented in/out (positive quantities)
    ind_l_rentin  = np.where(ind_l_in > l_bar, ind_l_in - l_bar, 0.0) * dummy_ind_rentin
    ind_l_rentout = np.where(ind_l_out < l_bar, l_bar - ind_l_out, 0.0) * dummy_ind_rentout

    return {
        'ind_pi': ind_pi,
        'ind_n': ind_n,
        'ind_l': ind_l,
        'ind_l_rentin': ind_l_rentin,
        'ind_l_rentout': ind_l_rentout,
        'dummy_ind_rentin': dummy_ind_rentin,
        'dummy_ind_rentout': dummy_ind_rentout,
        'dummy_ind_rentno': dummy_ind_rentno,
    }


def occupational_choice(p, q, wa, P, ind_s, ind_h, ind_xiu, ind_xir,
                        ind_s_tilde, ind_s_tilde2, ind_tauy, ind_taul,
                        hh_eta, hh_lambda, hh_varphi, l_bar,
                        dummy_old=None):
    """
    Full occupational choice: 5 options per individual, then family operator selection.
    Equivalent to occupationalChoice.m

    Five occupational states:
      1. Full-time urban non-agriculture (dummy_urban)
      2. Full-time rural non-agriculture  (dummy_rural)
      3. Full-time agricultural worker    (dummy_agr)
      4. Part-time urban                  (dummy_pt_u)
      5. Part-time rural                  (dummy_pt_r)

    Then selects one family member as farm operator (or whole-family migration).

    Parameters
    ----------
    p, q, wa : float
        Prices.
    P : dict
        Parameters.
    ind_s, ind_h, ind_xiu, ind_xir : np.ndarray (N_sim, N_ind)
        Individual abilities and mobility barriers.
    ind_s_tilde, ind_s_tilde2, ind_tauy, ind_taul : np.ndarray (N_sim, N_ind)
        Adjusted abilities and wedges.
    hh_eta, hh_lambda, hh_varphi : np.ndarray (N_sim,)
        Land frictions.
    l_bar : np.ndarray (N_sim, 1)
        Land endowment.

    Returns
    -------
    results : dict
        All occupational dummies, incomes, farm-level variables.
    """
    N_sim = P['N_sim']
    N_ind = P['N_ind']
    wu = P['Au'] * 1.0  # numeraire: pr = pu = 1
    wr = P['Ar'] * 1.0

    # ---- Incomes from full-time occupations ----
    ind_inc_u = ind_h * (1.0 - ind_xiu) * wu   # urban non-agr
    ind_inc_r = ind_h * (1.0 - ind_xir) * wr   # rural non-agr
    ind_inc_a = np.ones((N_sim, N_ind)) * wa   # agricultural worker

    # Choose between urban and rural for the "best" non-agr option initially
    dummy_urban_init = ind_inc_u > ind_inc_r
    ind_inc_nonagr = dummy_urban_init * ind_inc_u + (1 - dummy_urban_init) * ind_inc_r

    # ---- Part-time labour supply and income ----
    # Optimal agricultural labour supply for part-time workers
    # ind_pt_ls = (kappa * nu * wa / ind_inc_nonagr)^{1/(1-nu)}
    ratio = P['kappa'] * P['nu'] * wa / (ind_inc_nonagr + 1e-16)
    ind_pt_ls = ratio ** (1.0 / (1.0 - P['nu']))
    ind_pt_ls = np.maximum(ind_pt_ls, 0.0)

    # Truncate at the part-time upper bound
    ind_pt_ls_r = np.minimum(ind_pt_ls, 1.0 - P['c_pt_r'])
    ind_pt_ls_u = np.minimum(ind_pt_ls, 1.0 - P['c_pt_u'])

    # Part-time income
    ind_inc_pt_r = (ind_pt_ls_r ** P['nu'] * wa * P['kappa'] +
                    ind_inc_r * (1.0 - P['c_pt_r'] - ind_pt_ls_r) - P['c_pt_2'])
    ind_inc_pt_u = (ind_pt_ls_u ** P['nu'] * wa * P['kappa'] +
                    ind_inc_u * (1.0 - P['c_pt_u'] - ind_pt_ls_u) - P['c_pt_2'])

    # ---- Occupational Choice (5-way comparison) ----
    dummy_urban = ((ind_inc_u > ind_inc_r) & (ind_inc_u > ind_inc_a) &
                   (ind_inc_u > ind_inc_pt_r) & (ind_inc_u > ind_inc_pt_u))
    dummy_rural = ((ind_inc_r > ind_inc_u) & (ind_inc_r > ind_inc_a) &
                   (ind_inc_r > ind_inc_pt_r) & (ind_inc_r > ind_inc_pt_u))
    dummy_agr   = ((ind_inc_a > ind_inc_u) & (ind_inc_a > ind_inc_r) &
                   (ind_inc_a > ind_inc_pt_r) & (ind_inc_a > ind_inc_pt_u))
    dummy_pt_u  = ((ind_inc_pt_u > ind_inc_u) & (ind_inc_pt_u > ind_inc_r) &
                   (ind_inc_pt_u > ind_inc_a) & (ind_inc_pt_u > ind_inc_pt_r))
    dummy_pt_r  = ((ind_inc_pt_r > ind_inc_u) & (ind_inc_pt_r > ind_inc_r) &
                   (ind_inc_pt_r > ind_inc_a) & (ind_inc_pt_r > ind_inc_pt_u))

    # Income from non-operator sources (best of 5 for each individual)
    ind_inc_nonop = (dummy_urban * ind_inc_u + dummy_rural * ind_inc_r +
                     dummy_agr * ind_inc_a + dummy_pt_u * ind_inc_pt_u +
                     dummy_pt_r * ind_inc_pt_r)

    # ---- Rental choice for each individual (as potential operator) ----
    rental = rental_choice(p, q, wa, P, ind_s_tilde, ind_s_tilde2,
                           ind_tauy, ind_taul, hh_eta, hh_lambda,
                           hh_varphi, l_bar)
    ind_pi = rental['ind_pi']

    # ---- Family operator selection ----
    # The operator is the family member who generates the highest total HH income
    # when they farm and everyone else takes non-operator occupation.
    temp = np.sum(ind_inc_nonop, axis=1, keepdims=True)  # (N_sim, 1)
    hh_inc_with_operator = temp - ind_inc_nonop + ind_pi   # (N_sim, N_ind)

    # operator: index (0-based) of max income family member
    hh_inc_total = np.max(hh_inc_with_operator, axis=1)    # (N_sim,)
    operator = np.argmax(hh_inc_with_operator, axis=1)     # (N_sim,)

    # ---- Whole-family migration decision ----
    # Family migrates if total income from migration > income with operator
    hh_b = hh_lambda * l_bar.flatten() * hh_varphi
    hh_migration = (temp.flatten() - hh_b + l_bar.flatten() * q) > hh_inc_total
    hh_migration = hh_migration.astype(float)

    hh_inc_total = (hh_inc_total * (1 - hh_migration) +
                    (temp.flatten() + l_bar.flatten() * q - hh_b) * hh_migration)

    # ---- Operator dummies ----
    dummy_ope = np.zeros((N_sim, N_ind))
    for i in range(N_ind):
        dummy_ope[:, i] = (operator == i) * (1 - hh_migration)

    # Non-operator individuals cannot be operators
    dummy_urban = dummy_urban * (1 - dummy_ope)
    dummy_rural = dummy_rural * (1 - dummy_ope)
    dummy_agr   = dummy_agr   * (1 - dummy_ope)
    dummy_pt_u  = dummy_pt_u  * (1 - dummy_ope)
    dummy_pt_r  = dummy_pt_r  * (1 - dummy_ope)

    # ---- Farm-level variables (operator only) ----
    farm_s    = np.sum(ind_s * dummy_ope, axis=1)        # (N_sim,)
    farm_tauy = np.sum(ind_tauy * dummy_ope, axis=1)
    farm_taul = np.sum(ind_taul * dummy_ope, axis=1)
    farm_rentin  = np.sum(rental['ind_l_rentin'] * dummy_ope, axis=1)
    farm_rentout = np.sum(rental['ind_l_rentout'] * dummy_ope, axis=1)
    dummy_farm_rentin  = np.sum(rental['dummy_ind_rentin'] * dummy_ope, axis=1)
    dummy_farm_rentout = np.sum(rental['dummy_ind_rentout'] * dummy_ope, axis=1)
    dummy_farm_rentno  = np.sum(rental['dummy_ind_rentno'] * dummy_ope, axis=1)

    farm_n  = np.sum(rental['ind_n'] * dummy_ope, axis=1)
    farm_l  = np.sum(rental['ind_l'] * dummy_ope, axis=1)
    farm_pi = np.sum(ind_pi * dummy_ope, axis=1)

    # Agricultural output
    farm_y = (P['A'] * farm_s * farm_l ** (P['theta'] * P['gamma']) *
              farm_n ** ((1.0 - P['theta']) * P['gamma']))

    return {
        # Occupational dummies
        'dummy_urban': dummy_urban,
        'dummy_rural': dummy_rural,
        'dummy_agr': dummy_agr,
        'dummy_pt_u': dummy_pt_u,
        'dummy_pt_r': dummy_pt_r,
        'dummy_ope': dummy_ope,
        # Part-time labour supply
        'ind_pt_ls_r': ind_pt_ls_r,
        'ind_pt_ls_u': ind_pt_ls_u,
        # Incomes
        'ind_inc_u': ind_inc_u,
        'ind_inc_r': ind_inc_r,
        'ind_inc_a': ind_inc_a,
        'ind_inc_nonop': ind_inc_nonop,
        'hh_inc_total': hh_inc_total,
        # Individual abilities and frictions (needed by downstream functions)
        'ind_s': ind_s,
        'ind_h': ind_h,
        'ind_xiu': ind_xiu,
        'ind_xir': ind_xir,
        'dummy_old': dummy_old if dummy_old is not None else np.zeros((N_sim, N_ind)),
        # Land frictions (carried through from ind_blocks)
        'hh_eta': hh_eta,
        'hh_lambda': hh_lambda,
        'hh_varphi': hh_varphi,
        'l_bar': l_bar,
        # Farm-level
        'farm_s': farm_s,
        'farm_tauy': farm_tauy,
        'farm_taul': farm_taul,
        'farm_rentin': farm_rentin,
        'farm_rentout': farm_rentout,
        'dummy_farm_rentin': dummy_farm_rentin,
        'dummy_farm_rentout': dummy_farm_rentout,
        'dummy_farm_rentno': dummy_farm_rentno,
        'farm_n': farm_n,
        'farm_l': farm_l,
        'farm_pi': farm_pi,
        'farm_y': farm_y,
        # Family decisions
        'operator': operator,
        'hh_migration': hh_migration,
        'hh_b': hh_b,
        'hh_inc_total': hh_inc_total,
        # Rental outcomes
        'ind_pi': ind_pi,
    }


# ===========================================================================
# Layer 4: Market Clearing
# ===========================================================================

def compute_tax_revenue(P, occ):
    """
    Compute tax revenues from wedges and distortions.
    Equivalent to taxRevenue.m

    Five sources: rural mobility barrier (xir), urban mobility barrier (xiu),
    output wedge (tauy), part-time cost, and expropriation.

    Parameters
    ----------
    P : dict
        Parameters.
    occ : dict
        Occupational choice results.

    Returns
    -------
    TR : float
        Total tax revenue per capita.
    """
    N_sim = P['N_sim']
    N_ind = P['N_ind']
    wu = P['Au'] * 1.0
    wr = P['Ar'] * 1.0

    # Rural mobility barrier revenue
    TR_xir = 0.0
    for i in range(N_ind):
        TR_xir += (np.sum(occ['dummy_rural'][:, i] * occ['ind_h'][:, i] * wr *
                          occ['ind_xir'][:, i]) +
                   np.sum(occ['dummy_pt_r'][:, i] * occ['ind_h'][:, i] *
                          (1.0 - P['c_pt_r'] - occ['ind_pt_ls_r'][:, i]) * wr *
                          occ['ind_xir'][:, i]))
    TR_xir /= N_sim

    # Urban mobility barrier revenue
    TR_xiu = 0.0
    for i in range(N_ind):
        TR_xiu += (np.sum(occ['dummy_urban'][:, i] * occ['ind_h'][:, i] * wu *
                          occ['ind_xiu'][:, i]) +
                   np.sum(occ['dummy_pt_u'][:, i] * occ['ind_h'][:, i] *
                          (1.0 - P['c_pt_u'] - occ['ind_pt_ls_u'][:, i]) * wu *
                          occ['ind_xiu'][:, i]))
    TR_xiu /= N_sim

    # Output wedge revenue
    TR_tauy = np.sum(occ['farm_y'] * 1.0 * (1.0 - occ['farm_tauy']) +
                     occ['farm_l'] * 1.0 * (1.0 - occ['farm_taul'])) / N_sim
    # Note: in MATLAB, farm_y is multiplied by p, farm_l by q (both = 1 at this point)

    # Part-time cost revenue
    TR_pt = 0.0
    for i in range(N_ind):
        TR_pt += np.sum(occ['dummy_pt_r'][:, i] + occ['dummy_pt_u'][:, i]) / N_sim * P['c_pt_2']

    # Expropriation revenue
    TR_expropriation = np.sum(
        occ['hh_eta'] * occ['hh_varphi'] * occ['farm_rentout'] * (1.0 - occ['hh_migration']) +
        occ['hh_migration'] * occ['l_bar'].flatten() * occ['hh_lambda'] * occ['hh_varphi']
    ) / N_sim

    TR = TR_xir + TR_xiu + TR_tauy + TR_pt + TR_expropriation
    return TR


def land_labor_market(P, occ):
    """
    Compute land and agricultural labour market clearing residuals.
    Equivalent to landLaborMarket.m

    Returns (distance_L, distance_Na) — normalized excess demand.
    """
    N_sim = P['N_sim']
    N_ind = P['N_ind']

    # Land market
    AD_L = np.sum(occ['farm_rentin']) / N_sim
    AS_L = (np.sum(occ['farm_rentout']) +
            np.sum(occ['hh_migration'] * occ['l_bar'].flatten())) / N_sim
    distance_L = (AD_L - AS_L) / (0.5 * AD_L + 0.5 * AS_L + 0.001)

    # Agricultural labour market
    AD_Na = np.sum(occ['farm_n']) / N_sim

    AS_Na = 0.0
    for i in range(N_ind):
        AS_Na += (np.sum(occ['dummy_agr'][:, i]) +
                  np.sum(occ['dummy_pt_r'][:, i] *
                         occ['ind_pt_ls_r'][:, i] ** P['nu'] * P['kappa']) +
                  np.sum(occ['dummy_pt_u'][:, i] *
                         occ['ind_pt_ls_u'][:, i] ** P['nu'] * P['kappa']) +
                  P['ope_ls'] * np.sum(occ['dummy_ope'][:, i]))
    AS_Na /= N_sim
    distance_Na = (AD_Na - AS_Na) / (0.5 * AD_Na + 0.5 * AS_Na + 0.001)

    return distance_Na, distance_L


def nonagr_problem(P, occ, TR):
    """
    Compute non-agricultural sector aggregates and national accounts.
    Equivalent to nonAgrProblem.m

    Parameters
    ----------
    P : dict
    occ : dict
    TR : float
        Tax revenue.

    Returns
    -------
    results : dict
        Contains DI, Hr, Hu, AD_n, AS_n, GDPo, GDPe, GDPi.
    """
    N_sim = P['N_sim']
    N_ind = P['N_ind']
    wu = P['Au'] * 1.0
    wr = P['Ar'] * 1.0

    # Total income
    DI = (np.sum(occ['hh_inc_total']) / N_sim + TR + 0.0 -
          (N_ind + P['Nn_r'] + P['Nn_u']) * P['cbar'] * 1.0 +
          P['B'] * (P['Nn_u'] * np.mean(occ['ind_h']) * wu +
                    P['Nn_r'] * np.mean(occ['ind_h']) * wr))

    # Non-agricultural labour supply (rural and urban)
    Hr = 0.0
    for i in range(N_ind):
        Hr += np.sum((occ['dummy_rural'][:, i] +
                      occ['dummy_pt_r'][:, i] *
                      (1.0 - P['c_pt_r'] - occ['ind_pt_ls_r'][:, i])) *
                     occ['ind_h'][:, i])
    Hr = Hr / N_sim + P['B'] * P['Nn_r'] * np.mean(occ['ind_h'])

    Hu = 0.0
    for i in range(N_ind):
        Hu += np.sum((occ['dummy_urban'][:, i] +
                      occ['dummy_pt_u'][:, i] *
                      (1.0 - P['c_pt_u'] - occ['ind_pt_ls_u'][:, i])) *
                     occ['ind_h'][:, i])
    Hu = Hu / N_sim + P['B'] * P['Nn_u'] * np.mean(occ['ind_h'])

    # Non-agricultural output
    exp_n = (1.0 - P['phi']) * DI
    AD_n = exp_n
    AS_n = Hr * P['Ar'] + Hu * P['Au']

    # National account
    GDPo = -999.0  # placeholder, will be set after agr market
    GDPe = -999.0
    GDPi = (np.sum(occ['hh_inc_total']) / N_sim + TR + 0.0 +
            P['B'] * (P['Nn_u'] * np.mean(occ['ind_h']) * wu +
                      P['Nn_r'] * np.mean(occ['ind_h']) * wr))

    return {
        'DI': DI,
        'Hr': Hr,
        'Hu': Hu,
        'AD_n': AD_n,
        'AS_n': AS_n,
        'GDPi': GDPi,
    }


def agr_market(p, P, occ, nonagr):
    """
    Compute agricultural goods market clearing residual.
    Equivalent to agrMarket.m

    Returns distance_ADA — normalized excess demand for agricultural goods.
    """
    N_sim = P['N_sim']
    N_ind = P['N_ind']
    wu = P['Au'] * 1.0
    wr = P['Ar'] * 1.0
    DI = nonagr['DI']

    # Agricultural demand
    AD_a = (P['phi'] * DI / p +
            (N_ind + P['Nn_u'] + P['Nn_r']) * P['cbar'])

    # Agricultural supply
    AS_a = np.sum(occ['farm_y'] * (1.0 - occ['hh_migration'])) / N_sim

    distance_ADA = (AD_a - AS_a) / (0.5 * AD_a + 0.5 * AS_a + 0.001)

    return distance_ADA, AD_a, AS_a


# ===========================================================================
# Layer 5: Equilibrium Solver (Inner Loop)
# ===========================================================================

def equilibrium_residuals(X_price, P, ind_blocks):
    """
    Target function for least_squares: compute market-clearing residuals
    given candidate prices X_price = [p, q, wa].

    Equivalent to solveEquilibriumVector.m

    Internally calls occupational_choice → rental_choice, then computes
    land/labour/agricultural market residuals.

    Parameters
    ----------
    X_price : np.ndarray (3,)
        Candidate prices [p, q, wa].
    P : dict
        Parameters.
    ind_blocks : dict
        Pre-computed individual heterogeneity blocks:
        ind_s, ind_h, ind_xiu, ind_xir, ind_s_tilde, ind_s_tilde2,
        ind_tauy, ind_taul, hh_eta, hh_lambda, hh_varphi, l_bar.

    Returns
    -------
    f : np.ndarray (3,)
        [distance_Na, distance_ADA, distance_L]
    """
    p, q, wa = X_price

    # Occupational choice with current prices
    occ = occupational_choice(
        p, q, wa, P,
        ind_blocks['ind_s'], ind_blocks['ind_h'],
        ind_blocks['ind_xiu'], ind_blocks['ind_xir'],
        ind_blocks['ind_s_tilde'], ind_blocks['ind_s_tilde2'],
        ind_blocks['ind_tauy'], ind_blocks['ind_taul'],
        ind_blocks['hh_eta'], ind_blocks['hh_lambda'],
        ind_blocks['hh_varphi'], ind_blocks['l_bar'],
        ind_blocks.get('dummy_old', None)
    )

    # Market clearing
    TR = compute_tax_revenue(P, occ)
    distance_Na, distance_L = land_labor_market(P, occ)
    nonagr = nonagr_problem(P, occ, TR)
    distance_ADA, _, _ = agr_market(p, P, occ, nonagr)

    return np.array([distance_Na, distance_ADA, distance_L])


def solve_equilibrium(P, ind_blocks, x0=None, retry=True):
    """
    Solve for equilibrium prices (p, q, wa) using least_squares.
    Equivalent to the lsqnonlin block in computeModelMoments.m

    Parameters
    ----------
    P : dict
        Parameters.
    ind_blocks : dict
        Individual heterogeneity blocks.
    x0 : np.ndarray or None
        Initial guess [p, q, wa]. Default: [0.5, 0.5, 0.3].
    retry : bool
        If True and fval > 0.001, retry with random starting point (up to 1 retry).

    Returns
    -------
    results : dict
        Contains p, q, wa, fval, success, and the full occupational choice results.
    """
    if x0 is None:
        x0 = np.array([0.5, 0.5, 0.3])

    LB = np.array([0.0, 0.0, 0.0])
    UB = np.array([5.0, 5.0, 5.0])

    res = least_squares(
        equilibrium_residuals,
        x0,
        bounds=(LB, UB),
        method='trf',
        ftol=1e-15,
        gtol=1e-10,
        xtol=1e-7,
        max_nfev=1000,
        args=(P, ind_blocks)
    )

    X_best = res.x
    fval_best = np.max(np.abs(res.fun)) if len(res.fun) > 0 else 999.0

    # Retry with random starting point if needed
    if retry and fval_best > 0.001:
        error_price = True
        ite_price = 0

        while error_price and ite_price <= 1:
            ite_price += 1
            x0_rand = LB + np.random.rand(3) * (UB - LB)

            res2 = least_squares(
                equilibrium_residuals,
                x0_rand,
                bounds=(LB, UB),
                method='trf',
                ftol=1e-15,
                gtol=1e-10,
                xtol=1e-7,
                max_nfev=1000,
                args=(P, ind_blocks)
            )

            fval2 = np.max(np.abs(res2.fun)) if len(res2.fun) > 0 else 999.0

            if fval2 < 0.001:
                error_price = False

            if fval2 < fval_best:
                X_best = res2.x
                fval_best = fval2

    p, q, wa = X_best

    # Final occupational choice at converged prices
    occ = occupational_choice(
        p, q, wa, P,
        ind_blocks['ind_s'], ind_blocks['ind_h'],
        ind_blocks['ind_xiu'], ind_blocks['ind_xir'],
        ind_blocks['ind_s_tilde'], ind_blocks['ind_s_tilde2'],
        ind_blocks['ind_tauy'], ind_blocks['ind_taul'],
        ind_blocks['hh_eta'], ind_blocks['hh_lambda'],
        ind_blocks['hh_varphi'], ind_blocks['l_bar'],
        ind_blocks.get('dummy_old', None)
    )

    TR = compute_tax_revenue(P, occ)
    _, _ = land_labor_market(P, occ)
    nonagr = nonagr_problem(P, occ, TR)
    _, AD_a, AS_a = agr_market(p, P, occ, nonagr)

    return {
        'p': p,
        'q': q,
        'wa': wa,
        'fval': fval_best,
        'success': fval_best <= 0.001,
        'occ': occ,
        'TR': TR,
        'nonagr': nonagr,
        'AD_a': AD_a,
        'AS_a': AS_a,
    }


# ===========================================================================
# Layer 6: Model Moments
# ===========================================================================

def compute_all_moments(P, occ, nonagr, AD_a, AS_a, eq_prices, case_id=1):
    """
    Compute all model moments for comparison with data.
    Equivalent to the individual moment subroutines called in
    computeModelMoments.m / CalibrationComputeMoments.m

    Parameters
    ----------
    P : dict
    occ : dict
    nonagr : dict
    AD_a, AS_a : float
    eq_prices : dict with p, q, wa
    case_id : int

    Returns
    -------
    moments : dict
        Model moments keyed by name.
    """
    N_sim = P['N_sim']
    N_ind = P['N_ind']
    wu = P['Au'] * 1.0
    wr = P['Ar'] * 1.0

    # --- Sectoral shares (sectoralShare.m) ---
    GDPe = AD_a * eq_prices['p'] + nonagr['AS_n']

    agr_emp_share = np.sum(
        occ['dummy_ope'] + occ['dummy_agr'] +
        occ['dummy_pt_r'] * occ['ind_pt_ls_r'] / (1.0 - P['c_pt_r']) +
        occ['dummy_pt_u'] * occ['ind_pt_ls_u'] / (1.0 - P['c_pt_u'])
    ) / N_sim / (N_ind + P['Nn_r'] + P['Nn_u'])

    agr_VA_share = AD_a * eq_prices['p'] / GDPe

    # --- Family statistics (familyStatistics.m) ---
    PCT_family_operator = np.sum(np.sum(occ['dummy_ope'], axis=1) > 0) / N_sim

    # --- Non-agricultural income dispersion (stdIncNonagr.m) ---
    wn_Mat = (wr * (occ['dummy_rural'] + occ['dummy_pt_r']) +
              wu * (occ['dummy_urban'] + occ['dummy_pt_u']))

    # Flatten for full-time nonagr workers
    mask_ft = (occ['dummy_rural'].flatten() + occ['dummy_pt_r'].flatten() +
               occ['dummy_urban'].flatten() + occ['dummy_pt_u'].flatten()) > 0
    ft_income = occu_separate(
        (occ['dummy_rural'].flatten() + occ['dummy_pt_r'].flatten() +
         occ['dummy_urban'].flatten() + occ['dummy_pt_u'].flatten()),
        occ['ind_h'].flatten() * wn_Mat.flatten(), 1)

    if len(ft_income) > 1:
        std_inc_nonagr = np.std(np.log(ft_income))
    else:
        std_inc_nonagr = 0.0

    # Within-household correlation (households with exactly 2 nonagr workers)
    temp1_pairs = []
    for i in range(N_sim):
        if np.sum(occ['dummy_rural'][i, :] + occ['dummy_pt_r'][i, :] +
                  occ['dummy_urban'][i, :] + occ['dummy_pt_u'][i, :]) == 2:
            idx = np.where(occ['dummy_rural'][i, :] + occ['dummy_pt_r'][i, :] +
                           occ['dummy_urban'][i, :] + occ['dummy_pt_u'][i, :])[0]
            if len(idx) == 2:
                temp1_pairs.append([
                    np.log(occ['ind_h'][i, idx[0]] * wn_Mat[i, idx[0]]),
                    np.log(occ['ind_h'][i, idx[1]] * wn_Mat[i, idx[1]])
                ])

    if len(temp1_pairs) > 1:
        temp1_arr = np.array(temp1_pairs)
        std_inc_nonagr_across = spearmanr(temp1_arr[:, 0], temp1_arr[:, 1])[0]
    else:
        std_inc_nonagr_across = 0.0

    # Correlation: farming profit vs nonagr wage (households with 1 nonagr + 1 operator)
    temp_pi_nonagr = []
    for i in range(N_sim):
        n_nonagr = np.sum(occ['dummy_rural'][i, :] + occ['dummy_pt_r'][i, :] +
                          occ['dummy_urban'][i, :] + occ['dummy_pt_u'][i, :])
        if n_nonagr == 1 and occ['hh_migration'][i] == 0:
            idx = np.where(occ['dummy_rural'][i, :] + occ['dummy_pt_r'][i, :] +
                           occ['dummy_urban'][i, :] + occ['dummy_pt_u'][i, :])[0]
            if len(idx) == 1:
                temp_pi_nonagr.append([
                    np.log(occ['ind_h'][i, idx[0]]) * wn_Mat[i, idx[0]],
                    np.log(occ['farm_pi'][i])
                ])
    if len(temp_pi_nonagr) > 1 and np.all(np.isfinite(np.array(temp_pi_nonagr))):
        temp_arr = np.array(temp_pi_nonagr)
        corr_pi_nonagr = spearmanr(temp_arr[:, 0], temp_arr[:, 1])[0]
    else:
        corr_pi_nonagr = 1.0

    # --- Income differences (incDiffSector.m) ---
    eps = np.finfo(float).eps
    inc_diff_uo = (np.sum(np.log(occ['ind_h'] * wu + eps) *
                          (occ['dummy_urban'] + occ['dummy_pt_u'])) /
                   (np.sum(occ['dummy_urban'] + occ['dummy_pt_u']) + eps) -
                   np.sum(np.log(occ['farm_y'] * eq_prices['p'] + eps) *
                          (1.0 - occ['hh_migration'])) /
                   (np.sum(1.0 - occ['hh_migration']) + eps))

    # --- Income difference: migration vs non-migration (incDiffNonagrMigration.m) ---
    temp_mig = []
    for i in range(N_sim):
        n_nonagr_i = np.sum(occ['dummy_rural'][i, :] + occ['dummy_pt_r'][i, :] +
                            occ['dummy_urban'][i, :] + occ['dummy_pt_u'][i, :])
        if n_nonagr_i > 0:
            avg_nonagr_inc = (np.sum(np.log(occ['ind_h'][i, :] * wr) *
                                     (occ['dummy_rural'][i, :] + occ['dummy_pt_r'][i, :])) +
                              np.sum(np.log(occ['ind_h'][i, :] * wu) *
                                     (occ['dummy_urban'][i, :] + occ['dummy_pt_u'][i, :]))) / n_nonagr_i
            temp_mig.append([avg_nonagr_inc, 1.0 - occ['hh_migration'][i]])

    if len(temp_mig) > 1:
        temp_mig_arr = np.array(temp_mig)
        with_op = occu_separate(temp_mig_arr[:, 1], temp_mig_arr[:, 0], 1)
        without_op = occu_separate(temp_mig_arr[:, 1], temp_mig_arr[:, 0], 0)
        if len(with_op) > 0 and len(without_op) > 0:
            inc_diff_nonagr_migration = np.mean(with_op) - np.mean(without_op)
        else:
            inc_diff_nonagr_migration = 0.0
    else:
        inc_diff_nonagr_migration = 0.0

    # --- Part-time hours (aveHourPT.m) ---
    pt_hours = occu_separate(
        occ['dummy_pt_r'].flatten() + occ['dummy_pt_u'].flatten(),
        (occ['ind_pt_ls_r'].flatten() / (1.0 - P['c_pt_r']) * occ['dummy_pt_r'].flatten() +
         occ['ind_pt_ls_u'].flatten() / (1.0 - P['c_pt_u']) * occ['dummy_pt_u'].flatten()),
        1)
    if len(pt_hours) > 0:
        pt_hours_sorted = np.sort(pt_hours)
        ave_hour_pt = pt_hours_sorted[int(0.5 * len(pt_hours_sorted))]
    else:
        ave_hour_pt = 0.0

    # --- Agricultural production moments (agrProductionMoment.m) ---
    # TFPR = farm_y / (farm_l^theta * farm_n^(1-theta))
    # Add small epsilon to avoid division by zero for non-farming households
    denom = (np.maximum(occ['farm_l'], 1e-10) ** P['theta'] *
             np.maximum(occ['farm_n'], 1e-10) ** (1.0 - P['theta']))
    TFPR = occ['farm_y'] / np.maximum(denom, 1e-10)
    TFPR_operating = occu_separate(1.0 - occ['hh_migration'], TFPR, 1)
    TFPQ_operating = occu_separate(1.0 - occ['hh_migration'], occ['farm_s'], 1)

    if len(TFPR_operating) > 1:
        std_farm_TFPR = np.std(np.log(TFPR_operating))
    else:
        std_farm_TFPR = 0.0

    if len(TFPQ_operating) > 1:
        std_farm_TFPQ = np.std(np.log(TFPQ_operating))
    else:
        std_farm_TFPQ = 0.0

    # Correlation TFPQ vs TFPR (among rent-in farmers)
    mask_rentin = (1.0 - occ['hh_migration']) * occ['dummy_farm_rentin']
    TFPQ_rentin = occu_separate(mask_rentin, occ['farm_s'], 1)
    TFPR_rentin = occu_separate(mask_rentin, TFPR, 1)

    if len(TFPQ_rentin) > 1 and len(TFPR_rentin) > 1:
        corr_farm_TFPQ_TFPR = spearmanr(
            np.log(TFPQ_rentin), np.log(TFPR_rentin))[0]
    else:
        corr_farm_TFPQ_TFPR = 1.0

    # --- Correlation: income vs labour supply for part-time (corrIncLSPT1.m) ---
    pt_mask = occ['dummy_pt_r'].flatten() + occ['dummy_pt_u'].flatten()
    inc_pt = occu_separate(pt_mask,
        occ['dummy_pt_r'].flatten() * occ['ind_h'].flatten() * (1.0 - P['c_pt_r'] - occ['ind_pt_ls_r'].flatten()) +
        occ['dummy_pt_u'].flatten() * occ['ind_h'].flatten() * (1.0 - P['c_pt_u'] - occ['ind_pt_ls_u'].flatten()),
        1)
    ls_pt = occu_separate(pt_mask,
        occ['dummy_pt_r'].flatten() * (1.0 - P['c_pt_r'] - occ['ind_pt_ls_r'].flatten()) / (1.0 - P['c_pt_r']) +
        occ['dummy_pt_u'].flatten() * (1.0 - P['c_pt_u'] - occ['ind_pt_ls_u'].flatten()) / (1.0 - P['c_pt_u']),
        1)

    # Filter to labour supply between 0.65 and 0.80
    mask_mid = (ls_pt >= 0.65) & (ls_pt <= 0.80)
    if np.sum(mask_mid) > 1:
        inc_filt = inc_pt[mask_mid]
        ls_filt = ls_pt[mask_mid]
        corr_inc_ls_pt = spearmanr(inc_filt, ls_filt)[0]
    else:
        corr_inc_ls_pt = 1.0

    # --- Young-old income differences (incDiffYO.m) ---
    # (For baseline, these are computed but not used as calibration targets)
    dummy_ope_y = (1.0 - occ['dummy_old']) * occ['dummy_ope']
    dummy_ope_o = occ['dummy_old'] * occ['dummy_ope']

    inc_diff_yo_r = (np.sum(np.log(occ['ind_h'] + eps) * (occ['dummy_rural'] + occ['dummy_pt_r']) *
                            (1.0 - occ['dummy_old'])) /
                     (np.sum((occ['dummy_rural'] + occ['dummy_pt_r']) * (1.0 - occ['dummy_old'])) + eps) -
                     np.sum(np.log(occ['ind_h'] + eps) * (occ['dummy_rural'] + occ['dummy_pt_r']) *
                            occ['dummy_old']) /
                     (np.sum((occ['dummy_rural'] + occ['dummy_pt_r']) * occ['dummy_old']) + eps))

    inc_diff_yo_ope = (np.sum(np.log(occ['farm_y'][:, np.newaxis] * eq_prices['p'] + eps) * dummy_ope_y) /
                       (np.sum(dummy_ope_y) + eps) -
                       np.sum(np.log(occ['farm_y'][:, np.newaxis] * eq_prices['p'] + eps) * dummy_ope_o) /
                       (np.sum(dummy_ope_o) + eps))

    # --- Median ability (medianAbility.m) ---
    tfpq_all = occu_separate(occ['hh_migration'], occ['farm_s'], 0)
    if len(tfpq_all) > 0:
        tfpq_sorted = np.sort(np.log(tfpq_all))
        median_TFPQ = tfpq_sorted[int(len(tfpq_sorted) * 0.5)]
    else:
        median_TFPQ = 0.0

    rural_h = occu_separate(
        occ['dummy_rural'].flatten() + occ['dummy_pt_r'].flatten(),
        occ['ind_h'].flatten(), 1)
    if len(rural_h) > 0:
        median_r = np.sort(np.log(rural_h))[int(len(rural_h) * 0.5)]
    else:
        median_r = 0.0

    urban_h = occu_separate(
        occ['dummy_urban'].flatten() + occ['dummy_pt_u'].flatten(),
        occ['ind_h'].flatten(), 1)
    if len(urban_h) > 0:
        median_u = np.sort(np.log(urban_h))[int(len(urban_h) * 0.5)]
    else:
        median_u = 0.0

    # --- Within-family selection (withinFamilySelection.m) ---
    hh_s_max = np.max(occ['ind_s'], axis=1)
    migrant_mask = occ['hh_migration']
    if np.sum(occu_separate(migrant_mask, np.ones(N_sim), 0)) > 0:
        frac_sorting = (np.sum(occu_separate(migrant_mask, hh_s_max, 0) ==
                               occu_separate(migrant_mask, occ['farm_s'], 0)) /
                        np.sum(occu_separate(migrant_mask, np.ones(N_sim), 0)))
    else:
        frac_sorting = 0.0

    # --- Profit-labour supply correlation (corrPiLS.m) ---
    temp_pi_ls = np.column_stack([
        occ['farm_pi'],
        np.sum(occ['dummy_rural'] + occ['dummy_urban'] +
               occ['dummy_pt_r'] * (1.0 - P['c_pt_r'] - occ['ind_pt_ls_r']) +
               occ['dummy_pt_u'] * (1.0 - P['c_pt_u'] - occ['ind_pt_ls_u']), axis=1)
    ])
    if temp_pi_ls.shape[0] > 1:
        corr_pi_ls = spearmanr(temp_pi_ls[:, 0], temp_pi_ls[:, 1])[0]
    else:
        corr_pi_ls = 1.0

    # --- Profit-rural correlation (corrPiRural.m) ---
    temp_pi_rural = []
    for i in range(N_sim):
        if (np.sum(occ['dummy_rural'][i, :] + occ['dummy_pt_r'][i, :]) == 1 and
                occ['hh_migration'][i] == 0):
            temp_pi_rural.append([
                np.sum(np.log(occ['ind_h'][i, :]) * wr *
                       (occ['dummy_rural'][i, :] + occ['dummy_pt_r'][i, :])),
                np.log(occ['farm_pi'][i])
            ])
    if len(temp_pi_rural) > 1:
        temp_arr = np.array(temp_pi_rural)
        corr_pi_rural = spearmanr(temp_arr[:, 0], temp_arr[:, 1])[0]
    else:
        corr_pi_rural = 1.0

    # --- Rural-urban correlation (corrRuralUrban.m) ---
    temp_ru = []
    for i in range(N_sim):
        if (np.sum(occ['dummy_rural'][i, :] + occ['dummy_pt_r'][i, :]) == 1 and
                np.sum(occ['dummy_urban'][i, :] + occ['dummy_pt_u'][i, :]) == 1):
            temp_ru.append([
                np.sum(np.log(occ['ind_h'][i, :]) * wr *
                       (occ['dummy_rural'][i, :] + occ['dummy_pt_r'][i, :])),
                np.sum(np.log(occ['ind_h'][i, :]) * wu *
                       (occ['dummy_urban'][i, :] + occ['dummy_pt_u'][i, :]))
            ])
    if len(temp_ru) > 1:
        temp_arr = np.array(temp_ru)
        corr_rural_urban = spearmanr(temp_arr[:, 0], temp_arr[:, 1])[0]
    else:
        corr_rural_urban = 1.0

    # --- Assemble all moments ---
    moments = {
        # Employment shares
        'agr_emp_share': agr_emp_share,
        'agr_VA_share': agr_VA_share,
        # Family
        'PCT_family_operator': PCT_family_operator,
        # Income dispersion
        'std_inc_nonagr': std_inc_nonagr,
        'std_inc_nonagr_across': std_inc_nonagr_across,
        'corr_pi_nonagr': corr_pi_nonagr,
        # Wage differentials
        'inc_diff_uo': inc_diff_uo,
        'inc_diff_nonagr_migration': inc_diff_nonagr_migration,
        # Part-time
        'ave_hour_pt': ave_hour_pt,
        'corr_inc_ls_pt': corr_inc_ls_pt,
        # Agricultural production
        'std_farm_TFPQ': std_farm_TFPQ,
        'std_farm_TFPR': std_farm_TFPR,
        'corr_farm_TFPQ_TFPR': corr_farm_TFPQ_TFPR,
        # GLW gap
        'agr_VA_share': agr_VA_share,
        'agr_emp_share': agr_emp_share,
        # Medians
        'median_TFPQ': median_TFPQ,
        'median_u': median_u,
        # Within-family selection
        'frac_sorting': frac_sorting,
        # Correlations (not calibration targets)
        'corr_pi_ls': corr_pi_ls,
        'corr_pi_rural': corr_pi_rural,
        'corr_rural_urban': corr_rural_urban,
        'inc_diff_yo_r': inc_diff_yo_r,
        'inc_diff_yo_ope': inc_diff_yo_ope,
    }

    return moments


def compute_loss(model_moments, data_moments, case_id=1):
    """
    Compute RMSE loss between model and data moments.
    Equivalent to lossFunc.m (case_id==1 branch).

    Uses 14 targeted moments for baseline calibration.

    Parameters
    ----------
    model_moments : dict
    data_moments : dict
    case_id : int

    Returns
    -------
    loss : float
        RMSE.
    moments_list : list of (name, model_val, data_val) tuples
        For display.
    """
    # Moment definitions for case_id=1 (same order as lossFunc.m)
    moment_specs = [
        # (model_key, data_key, description)
        # Part 1: Employment shares
        ('rural_nonagr_emp', 'data_rural_nonagr_emp', 'FT Nonagr Worker'),
        ('parttime_emp', 'data_parttime_rural_emp', 'PT Worker'),
        ('ave_hour_pt', 'data_ave_hour_pt', 'Median Hours Agr Among PT'),
        # Part 2: Family choices
        ('PCT_family_operator', 'data_PCT_family_operator', 'Family with Operators'),
        # Part 3: Income moments
        ('std_inc_nonagr', 'data_std_inc_nonagr', 'Disp FT Nonagr'),
        ('std_inc_nonagr_across', 'data_std_inc_nonagr_across', 'Within HH Corr'),
        ('inc_diff_uo', 'data_inc_diff_uo', 'Nonagr - Operator'),
        ('corr_pi_nonagr', 'data_corr_pi_nonagr', 'Corr farming nonagr'),
        ('corr_inc_ls_pt', 'data_corr_inc_ls_pt', 'Corr Hour Inc Among PT'),
        # Part 4: Agr production moments
        ('std_farm_TFPQ', 'data_std_farm_TFPQ', 'Farm TFP'),
        ('std_farm_TFPR', 'data_std_farm_TFPR', 'Farm TFPR'),
        ('corr_farm_TFPQ_TFPR', 'data_corr_farm_TFPQ_TFPR', 'TFP VS TFPR'),
        ('inc_diff_nonagr_migration', 'data_inc_diff_nonagr_migration',
         'With/Without Operator'),
        # Part 5: National Account
        ('GLW_inv', 'data_GLW_inv', 'GLW Gap'),
    ]

    Moment_Model = []
    Moment_Data = []
    moment_list = []

    for model_key, data_key, desc in moment_specs:
        if model_key == 'rural_nonagr_emp':
            model_val = (np.sum(occ['dummy_rural'] + occ['dummy_urban']) /
                         model_moments['_N_sim'] / model_moments['_N_ind'])
        elif model_key == 'parttime_emp':
            model_val = (np.sum(occ['dummy_pt_r'] + occ['dummy_pt_u']) /
                         model_moments['_N_sim'] / model_moments['_N_ind'])
        elif model_key == 'GLW_inv':
            model_val = model_moments['agr_VA_share'] / model_moments['agr_emp_share']
        else:
            model_val = model_moments.get(model_key, 0.0)

        data_val = data_moments[data_key]

        Moment_Model.append(model_val)
        Moment_Data.append(data_val)
        moment_list.append((desc, model_val, data_val))

    Moment_Model = np.array(Moment_Model)
    Moment_Data = np.array(Moment_Data)

    loss = np.sqrt(np.sum((Moment_Model - Moment_Data) ** 2) / len(Moment_Model))

    return loss, moment_list


# ===========================================================================
# Layer 7: Calibration Objective (Outer Loop Evaluation)
# ===========================================================================

def prepare_individual_blocks(P, halton_seq):
    """
    Prepare all individual heterogeneity blocks from Halton draws.
    This is called once per calibration objective evaluation.

    Equivalent to the middle section of CalibrationComputeMoments.m
    (ability generation → wedge computation → land frictions).

    Parameters
    ----------
    P : dict
        Combined parameters (calibrated + exogenous).
    halton_seq : np.ndarray (N_sim, 30)
        Halton sequence.

    Returns
    -------
    ind_blocks : dict
        All individual-level arrays needed by equilibrium_residuals.
    """
    N_sim = P['N_sim']
    N_ind = P['N_ind']

    # Dummy old
    dummy_old = halton_seq[:, :3] < P['old']

    # Generate abilities
    ability_results = generate_abilities(P, halton_seq)
    ind_s   = ability_results['ind_s']
    ind_h   = ability_results['ind_h']
    ind_xir = ability_results['ind_xir']
    ind_xiu = ability_results['ind_xiu']
    dummy_old = ability_results['dummy_old']

    # Output wedges
    # ind_tauy_epsilon: HA(:,(N_ind-1)*5+11) → column 2*5+11=21
    col_tauy_eps = (N_ind - 1) * 5 + 11  # = 21 for N_ind=3
    ind_tauy_epsilon = np.exp(scipy_norm.ppf(
        halton_seq[:, col_tauy_eps],
        loc=-P['sigma_tauy']**2 / 2,
        scale=P['sigma_tauy']))

    ind_tauy = ind_s ** P['zeta_tauy'] * ind_tauy_epsilon[:, np.newaxis]
    ind_tauy = ind_tauy / np.exp(np.mean(np.log(ind_tauy)))

    ind_s_tilde  = (ind_s * ind_tauy) ** (1.0 / (1.0 - P['gamma']))
    ind_s_tilde2 = (ind_s * ind_tauy) ** (1.0 / (1.0 - P['gamma'] * (1.0 - P['theta'])))

    ind_taul = np.ones((N_sim, N_ind))

    # Land frictions
    hh_eta = np.ones(N_sim) * P['mu_eta']

    # Expropriation: HA(:, (N_ind-1)*5+13) → column 23
    col_exprop = (N_ind - 1) * 5 + 13
    dummy_expropriation = halton_seq[:, col_exprop] < hh_eta

    hh_lambda = hh_eta.copy()

    # varphi: HA(:, (N_ind-1)*5+15) → column 25
    col_varphi = (N_ind - 1) * 5 + 15
    hh_varphi = np.exp(scipy_norm.ppf(
        halton_seq[:, col_varphi],
        loc=P['mu_varphi'] - P['sigma_varphi']**2 / 2,
        scale=P['sigma_varphi']))

    # Land endowments
    l_bar = np.ones((N_sim, 1)) * P['LS']

    return {
        'ind_s': ind_s,
        'ind_h': ind_h,
        'ind_xiu': ind_xiu,
        'ind_xir': ind_xir,
        'ind_s_tilde': ind_s_tilde,
        'ind_s_tilde2': ind_s_tilde2,
        'ind_tauy': ind_tauy,
        'ind_taul': ind_taul,
        'hh_eta': hh_eta,
        'hh_lambda': hh_lambda,
        'hh_varphi': hh_varphi,
        'l_bar': l_bar,
        'dummy_old': dummy_old,
    }


def calibration_objective(X, case_id=1):
    """
    Full calibration objective: given parameter vector X, solve equilibrium
    and return RMSE loss vs data moments.

    Equivalent to CalibrationComputeMoments.m

    This is the function called by the outer-loop optimizer (particle swarm).

    Parameters
    ----------
    X : np.ndarray (14,)
        Calibration parameter vector.
    case_id : int

    Returns
    -------
    loss : float
        RMSE between model and data moments.
    """
    # Check parameter bounds for kappa
    P_calib = assign_parameter_value(X, case_id)
    P_exog = set_exogenous_params(case_id)
    P = {**P_exog, **P_calib}  # merge

    if P['kappa'] >= 1.0 / (1.0 - P['c_pt_r']) ** P['nu'] or \
       P['kappa'] >= 1.0 / (1.0 - P['c_pt_u']) ** P['nu']:
        return 3.0

    # Generate Halton sequence
    halton_sampler = Halton(d=30, scramble=False)
    # Skip 1e7 draws to match MATLAB
    batch_size = 100000
    for _ in range(100):  # 100 * 100000 = 10M
        halton_sampler.random(batch_size)
    halton_seq = halton_sampler.random(P['N_sim'])

    # Prepare individual blocks
    ind_blocks = prepare_individual_blocks(P, halton_seq)

    # Solve equilibrium (inner loop)
    eq_results = solve_equilibrium(P, ind_blocks, retry=True)

    occ = eq_results['occ']
    nonagr = eq_results['nonagr']
    AD_a = eq_results['AD_a']
    AS_a = eq_results['AS_a']

    # Check validity
    if not np.isreal(eq_results['p']) or not np.isreal(occ['farm_y']).all():
        return 10.0

    # Compute moments and loss
    moments = compute_all_moments(P, occ, nonagr, AD_a, AS_a,
                                  {'p': eq_results['p'], 'q': eq_results['q'],
                                   'wa': eq_results['wa']}, case_id)

    data_moments = get_data_moments(case_id)

    # Build moment arrays for loss computation
    loss = _compute_loss_raw(moments, occ, data_moments, P)

    # Penalty for poor equilibrium convergence
    if eq_results['fval'] > 0.001:
        loss += 2.0

    return loss


def _compute_loss_raw(moments, occ, data_moments, P):
    """
    Compute RMSE loss from moments dict (matching lossFunc.m order for case_id=1).
    Internal helper.
    """
    N_sim = P['N_sim']
    N_ind = P['N_ind']

    Moment_Model = np.zeros(14)
    Moment_Data = np.zeros(14)
    i = -1

    # 1: rural + urban nonagr employment share
    i += 1
    Moment_Model[i] = np.sum(occ['dummy_rural'] + occ['dummy_urban']) / N_sim / N_ind
    Moment_Data[i] = data_moments['data_rural_nonagr_emp'] + data_moments['data_urban_nonagr_emp']

    # 2: part-time employment share
    i += 1
    Moment_Model[i] = np.sum(occ['dummy_pt_r'] + occ['dummy_pt_u']) / N_sim / N_ind
    Moment_Data[i] = data_moments['data_parttime_rural_emp'] + data_moments['data_parttime_urban_emp']

    # 3: median agricultural hours among part-time
    i += 1
    Moment_Model[i] = moments.get('ave_hour_pt', 0.0)
    Moment_Data[i] = data_moments['data_ave_hour_pt']

    # 4: family with operator
    i += 1
    Moment_Model[i] = moments.get('PCT_family_operator', 0.0)
    Moment_Data[i] = data_moments['data_PCT_family_operator']

    # 5: std nonagr income
    i += 1
    Moment_Model[i] = moments.get('std_inc_nonagr', 0.0)
    Moment_Data[i] = data_moments['data_std_inc_nonagr']

    # 6: within-HH correlation nonagr
    i += 1
    Moment_Model[i] = moments.get('std_inc_nonagr_across', 0.0)
    Moment_Data[i] = data_moments['data_std_inc_nonagr_across']

    # 7: nonagr - operator income diff
    i += 1
    Moment_Model[i] = moments.get('inc_diff_uo', 0.0)
    Moment_Data[i] = data_moments['data_inc_diff_uo']

    # 8: corr farming-nonagr
    i += 1
    Moment_Model[i] = moments.get('corr_pi_nonagr', 0.0)
    Moment_Data[i] = data_moments['data_corr_pi_nonagr']

    # 9: corr income vs labour supply among PT
    i += 1
    Moment_Model[i] = moments.get('corr_inc_ls_pt', 0.0)
    Moment_Data[i] = data_moments['data_corr_inc_ls_pt']

    # 10: std farm TFPQ
    i += 1
    Moment_Model[i] = moments.get('std_farm_TFPQ', 0.0)
    Moment_Data[i] = data_moments['data_std_farm_TFPQ']

    # 11: std farm TFPR
    i += 1
    Moment_Model[i] = moments.get('std_farm_TFPR', 0.0)
    Moment_Data[i] = data_moments['data_std_farm_TFPR']

    # 12: corr TFPQ vs TFPR
    i += 1
    Moment_Model[i] = moments.get('corr_farm_TFPQ_TFPR', 0.0)
    Moment_Data[i] = data_moments['data_corr_farm_TFPQ_TFPR']

    # 13: migration income diff
    i += 1
    Moment_Model[i] = moments.get('inc_diff_nonagr_migration', 0.0)
    Moment_Data[i] = data_moments['data_inc_diff_nonagr_migration']

    # 14: GLW inverse gap
    i += 1
    Moment_Model[i] = moments.get('agr_VA_share', 0.0) / (moments.get('agr_emp_share', 0.01) + 1e-10)
    Moment_Data[i] = data_moments['data_GLW_inv']

    loss = np.sqrt(np.sum((Moment_Model - Moment_Data) ** 2) / (i + 1))
    return loss
