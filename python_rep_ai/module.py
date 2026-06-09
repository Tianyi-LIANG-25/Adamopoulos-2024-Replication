"""
module.py — Core functions for Adamopoulos et al. (2024) baseline replication.

Translated from origin_matlab/Matlab-Files/subroutine/*.m
Original authors: Adamopoulos, Brandt, Chen, Restuccia, Wei (QJE 2024)

Paper: "Land Insecurity and Mobility Frictions"
       Quarterly Journal of Economics, 2024

This module solves the baseline initial equilibrium (case_id=1, counterfactual=0).
All extension-only features are stripped: no rural non-agricultural sector,
no cohort differences, no ability-barrier correlation.

Architecture (bottom-up, matching MATLAB subroutine/ structure):
  Layer 0: Helper functions
  Layer 1: Data moments and parameter setup
  Layer 2: Individual heterogeneity (ability generation, Halton draws)
  Layer 3: Individual decisions (rental choice → occupational choice)
  Layer 4: Market clearing (land, labour, agricultural goods, non-agr)
  Layer 5: Equilibrium solver (inner loop: lsqnonlin → least_squares)
  Layer 6: Model moments (14 calibration-targeted moments)
  Layer 7: Calibration objective (outer loop: SMM loss evaluation)

Nested fixed-point structure (Paper Section V, Appendix B):
  Outer loop: Particle Swarm Optimization calibrates 14 parameters X
    by minimizing RMSE between 14 model moments and 14 data moments (SMM).
  Inner loop: For each candidate X, solve for equilibrium prices (p, q, wa)
    that clear 3 markets: agricultural labour, agricultural goods, land.

All state is passed explicitly via dictionaries (vs MATLAB global struct P).
"""

import numpy as np
from scipy.stats import norm as scipy_norm
from scipy.stats import spearmanr
from scipy.stats.qmc import Halton
from scipy.optimize import least_squares


# ======================================================================
# Layer 0: Helper Functions
# ======================================================================

def occu_separate(occupation, X, dummy):
    """
    Filter array X to elements where occupation == dummy.

    MATLAB: origin_matlab/Matlab-Files/subroutine/occuSeparate.m
    """
    occupation = np.asarray(occupation).flatten()
    X = np.asarray(X).flatten()
    return X[occupation == dummy]


# ======================================================================
# Layer 1: Data Moments and Parameter Setup
# ======================================================================

def get_data_moments():
    """
    14 calibration-targeted data moments for 2004 nationwide baseline.

    Paper: Table IV (Calibration Moments), Data column.
    MATLAB: origin_matlab/Matlab-Files/subroutine/lossFunc.m (case_id==1)
    """
    return {
        'data_ft_nonagr_share':      0.3024,
        'data_pt_share':             0.2070,
        'data_ave_hour_pt':          0.2857,
        'data_corr_inc_ls_pt':       0.3978,
        'data_PCT_family_operator':  0.7371,
        'data_std_inc_nonagr':       0.6097,
        'data_std_inc_nonagr_across':0.5581,
        'data_inc_diff_uo':          0.080931,
        'data_corr_pi_nonagr':       0.0796,
        'data_std_farm_TFPQ':        0.6573,
        'data_std_farm_TFPR':        0.6329,
        'data_corr_farm_TFPQ_TFPR':  0.9678,
        'data_inc_diff_migration':  -0.2806,
        'data_GLW_inv':              0.3883,
    }


def set_exogenous_params():
    """
    Exogenous (non-calibrated) parameters for baseline.

    Paper: Appendix Table B.1
    MATLAB: origin_matlab/Matlab-Files/subroutine/parameterExo.m (case_id==1)

    Baseline model has only urban non-agriculture. No rural nonagr sector.
    """
    return {
        'N_sim': 30000,        # Number of simulated households
        'N_ind': 3,            # Family size (J=3 working-age members)

        # Production technology (Paper eq. 1)
        'gamma': 0.75,         # Span-of-control returns to scale
        'theta': 0.533,        # Land share in agricultural production
        'A': 1.0,              # Agricultural TFP (normalization)

        # Non-agricultural sector (urban only in baseline)
        'Au': 1.0,             # Urban nonagr TFP = numeraire wage
        'Nn_u': 1.3385,        # Urban non-farm population (from census)

        # Preferences
        'nu': 0.6,             # Part-time disutility curvature
        'phi': 0.02,           # Agricultural expenditure share (Stone-Geary)

        # Land and operator
        'LS': 1.0,             # Per-household land endowment (normalized)
        'ope_ls': 0.0,         # Operator labour supply (= 0 in baseline)

        # Land insecurity (Paper Section V)
        'mu_eta': 0.05108,     # Expropriation probability (~5.1%)
    }


def assign_parameter_value(X):
    """
    Map 14-element calibration vector X → calibrated parameter dict.

    Paper: Appendix Table B.5 (Baseline column)
    MATLAB: origin_matlab/Matlab-Files/subroutine/assignParameterValue.m (case_id==1)

    Index  Parameter       Description
    ---------------------------------------------------------------------------
    X[0]   omega           Ability correlation (λ in paper)
    X[1]   sigma_sH        HH-level agricultural ability dispersion
    X[2]   sigma_hH        HH-level non-agricultural ability dispersion
    X[3]   IH_ratio        σ_sI/σ_sH = σ_hI/σ_hH (within-HH ability dispersion)
    X[4]   sigma_tauy      Output wedge dispersion
    X[5]   zeta_tauy       Output wedge elasticity w.r.t. ability
    X[6]   sigma_xiu       Urban mobility barrier dispersion
    X[7]   mu_xiu           Urban mobility barrier mean
    X[8]   sigma_varphi    Land compensation dispersion
    X[9]   mu_varphi       Land compensation mean
    X[10]  c_pt_u          Urban PT fixed cost
    X[11]  kappa           PT productivity shifter
    X[12]  cbar            Subsistence consumption level
    X[13]  B               Non-agricultural scale parameter
    """
    return {
        # Ability distribution (Paper Appendix B.2)
        'omega':       X[0],            # Mean ability correlation
        'sigma_sH':    X[1],            # HH-level agricultural ability dispersion
        'sigma_sI':    X[1] * X[3],     # Individual-level agr ability dispersion
        'sigma_hH':    X[2],            # HH-level non-agricultural ability dispersion
        'sigma_hI':    X[2] * X[3],     # Individual-level nonagr ability dispersion

        # Output wedges (Paper Appendix B.3)
        'sigma_tauy':  X[4],            # Dispersion of output wedge τ_y
        'zeta_tauy':   X[5],            # Elasticity of τ_y w.r.t. ability s

        # Urban mobility barrier (Paper Appendix B.4)
        # ξ = logistic(ε_ξ), ε_ξ ~ N(μ_ξ - σ²/2, σ)
        'sigma_xiu':   X[6],            # Dispersion of urban mobility barrier
        'mu_xiu':      X[7],            # Urban mobility barrier mean

        # Land insecurity (Paper Appendix B.5)
        'sigma_varphi': X[8],           # Dispersion of land compensation φ
        'mu_varphi':    X[9],           # Mean land compensation

        # Part-time and preferences
        'c_pt_u':       X[10],          # Urban PT fixed cost (fraction of time)
        'kappa':        X[11],          # PT productivity shifter
        'cbar':         X[12],          # Subsistence consumption level
        'B':            X[13],          # Non-agricultural scale parameter
    }


# ======================================================================
# Layer 2: Individual Heterogeneity
# ======================================================================

def generate_abilities(P, halton_seq):
    """
    Generate ability distributions and urban mobility barriers.

    Paper: Appendix B.2
           s_{ih} = s_Hh · s_Ii · h_{ih}^ω   (agricultural ability)
           h_{ih} = h_Hh · h_Ii               (non-agricultural ability)

           Urban mobility barrier (logistic):
           ξ_{ih} = exp(ε_ξ) / (1 + exp(ε_ξ))
           ε_ξ ~ N(μ_ξ - σ_ξ²/2, σ_ξ)

    MATLAB: origin_matlab/Matlab-Files/subroutine/ability.m

    Halton column layout (30 columns, 0-indexed):
      Col 3: sH — household-level agricultural ability
      Col 4: hH — household-level non-agricultural ability
      For individual i ∈ {0, 1, 2}:
        base = 5 + i*5
        Col base+0: sI  — individual agr ability
        Col base+1: hI  — individual nonagr ability
        Col base+4: ε_ξ for urban barrier
    """
    N_sim = P['N_sim']
    N_ind = P['N_ind']

    # Household-level abilities (Lognormal, mean 1)
    sH = np.exp(scipy_norm.ppf(halton_seq[:, 3],
                                loc=-P['sigma_sH']**2/2, scale=P['sigma_sH']))
    hH = np.exp(scipy_norm.ppf(halton_seq[:, 4],
                                loc=-P['sigma_hH']**2/2, scale=P['sigma_hH']))

    ind_s   = np.ones((N_sim, N_ind))
    ind_h   = np.ones((N_sim, N_ind))
    ind_xiu = np.zeros((N_sim, N_ind))

    for i in range(N_ind):
        base = 5 + i*5

        sI = np.exp(scipy_norm.ppf(halton_seq[:, base],
                                    loc=-P['sigma_sI']**2/2,
                                    scale=P['sigma_sI']))
        hI = np.exp(scipy_norm.ppf(halton_seq[:, base+1],
                                    loc=-P['sigma_hI']**2/2,
                                    scale=P['sigma_hI']))

        h = hH * hI
        s = sH * sI * h**P['omega']
        ind_s[:, i] = s
        ind_h[:, i] = h

        # Urban mobility barrier ξ^u
        raw_xiu = scipy_norm.ppf(halton_seq[:, base+4],
                                  loc=P['mu_xiu']-P['sigma_xiu']**2/2,
                                  scale=P['sigma_xiu'])
        ind_xiu[:, i] = np.exp(raw_xiu)/(1+np.exp(raw_xiu))

    return {'ind_s': ind_s, 'ind_h': ind_h, 'ind_xiu': ind_xiu}


# ======================================================================
# Layer 3: Individual Decisions
# ======================================================================

def rental_choice(p, q, wa, P, ind_s_tilde, ind_s_tilde2,
                  ind_tauy, ind_taul, hh_eta, hh_lambda, hh_varphi, l_bar):
    """
    Farmer's land rental decision: rent-in, rent-out, or no-rental.

    Paper: Section IV.B, Appendix equations (1)-(3)
           Production function (Paper eq. 1): y = A · s · l^{θγ} · n^{(1-θ)γ}

    MATLAB: origin_matlab/Matlab-Files/subroutine/rentalChoice.m
    """
    g, th = P['gamma'], P['theta']
    A = P['A']
    cf = (g*p*A)**(1/(1-g))

    # ---- Rent-in ----
    eff_q = ind_taul*q
    l_in = (ind_s_tilde*cf *
            (th/eff_q)**((1-(1-th)*g)/(1-g)) *
            ((1-th)/wa)**((1-th)*g/(1-g)))
    n_in = l_in*(eff_q/th)*((1-th)/wa)
    pi_in = ((1-g)*(g*p*A)**(g/(1-g))*p*A*ind_s_tilde*
             (th/eff_q)**((th*g)/(1-g)) *
             ((1-th)/wa)**((1-th)*g/(1-g)) +
             P['ope_ls']*wa + ind_taul*q*l_bar)
    pi_in = np.where(l_in > l_bar, pi_in, -999.)

    # ---- Rent-out (land insecurity: effective rate = q - η·φ) ----
    l_omega = ind_taul*q - hh_eta[:, None]*hh_varphi[:, None]
    l_omega = np.maximum(l_omega, 0.0001)
    l_out = (ind_s_tilde*cf *
             (th/l_omega)**((1-(1-th)*g)/(1-g)) *
             ((1-th)/wa)**((1-th)*g/(1-g)))
    n_out = l_out*(l_omega/th)*((1-th)/wa)
    pi_out = ((1-g)*(g*p*A)**(g/(1-g))*p*A*ind_s_tilde*
              (th/l_omega)**((th*g)/(1-g)) *
              ((1-th)/wa)**((1-th)*g/(1-g)) +
              P['ope_ls']*wa + l_omega*l_bar)
    pi_out = np.where(l_out < l_bar, pi_out, -999.)

    # ---- No-rental ----
    l_no = l_bar
    n_no = (ind_s_tilde2*(p*A)**(1/(1-g*(1-th)))*
            (g*(1-th)/wa)**(1/(1-g*(1-th)))*
            l_no**(th*g/(1-g*(1-th))))
    pi_no = ((1-g*(1-th))*ind_s_tilde2*
             (p*A)**(1/(1-g*(1-th)))*
             (g*(1-th)/wa)**((1-th)*g/(1-g*(1-th)))*
             l_no**(th*g/(1-g*(1-th))) + P['ope_ls']*wa)

    # ---- Regime selection ----
    rin  = (pi_in > pi_out) & (pi_in > pi_no)
    rout = (pi_out >= pi_in) & (pi_out > pi_no)
    rno  = (pi_no >= pi_in) & (pi_no >= pi_out)

    pi = rin*pi_in + rout*pi_out + rno*pi_no
    n_ = rin*n_in + rout*n_out + rno*n_no
    l_ = rin*l_in + rout*l_out + rno*l_no

    l_rentin  = np.where(l_in > l_bar, l_in-l_bar, 0.)*rin
    l_rentout = np.where(l_out < l_bar, l_bar-l_out, 0.)*rout

    return {'ind_pi': pi, 'ind_n': n_, 'ind_l': l_,
            'ind_l_rentin': l_rentin, 'ind_l_rentout': l_rentout,
            'dummy_ind_rentin': rin, 'dummy_ind_rentout': rout,
            'dummy_ind_rentno': rno}


def occupational_choice(p, q, wa, P, ind_s, ind_h, ind_xiu,
                        ind_s_tilde, ind_s_tilde2, ind_tauy, ind_taul,
                        hh_eta, hh_lambda, hh_varphi, l_bar):
    """
    Full occupational choice: 3 individual options → family operator.

    Paper: Section IV (Occupational Choice and Migration)
           Each individual chooses among:
             1. Full-time urban non-agriculture
             2. Full-time agricultural worker
             3. Part-time urban (nonagr + some farming)

           Family operator: argmax of total household income.
           Whole-family migration: if selling land beats staying.

    MATLAB: origin_matlab/Matlab-Files/subroutine/occupationalChoice.m
    """
    N_sim, N_ind = P['N_sim'], P['N_ind']
    wu = P['Au']

    # ---- Full-time incomes ----
    inc_u = ind_h*(1-ind_xiu)*wu  # Urban FT
    inc_a = np.ones((N_sim, N_ind))*wa  # Agricultural worker

    # Best nonagr option (only urban in baseline)
    inc_nonagr = inc_u

    # ---- Part-time labour supply ----
    # FOC: ls* = (κ·ν·wa / w_nonagr)^{1/(1-ν)}
    ratio = P['kappa']*P['nu']*wa/(inc_nonagr + 1e-16)
    pt_ls = ratio**(1/(1-P['nu']))
    pt_ls = np.maximum(pt_ls, 0.)
    pt_ls_u = np.minimum(pt_ls, 1-P['c_pt_u'])  # Truncate at time endowment

    # ---- Part-time income ----
    inc_pt_u = (pt_ls_u**P['nu']*wa*P['kappa'] +
                inc_u*(1-P['c_pt_u']-pt_ls_u))

    # ---- 3-way occupational comparison ----
    d_u = (inc_u > inc_a) & (inc_u > inc_pt_u)
    d_a = (inc_a > inc_u) & (inc_a > inc_pt_u)
    d_ptu = (inc_pt_u > inc_u) & (inc_pt_u > inc_a)

    inc_nonop = d_u*inc_u + d_a*inc_a + d_ptu*inc_pt_u

    # ---- Rental choice for each individual as potential operator ----
    r = rental_choice(p, q, wa, P, ind_s_tilde, ind_s_tilde2,
                      ind_tauy, ind_taul, hh_eta, hh_lambda,
                      hh_varphi, l_bar)
    ind_pi = r['ind_pi']

    # ---- Family operator: argmax of total household income ----
    temp_sum = np.sum(inc_nonop, axis=1, keepdims=True)
    hh_with_op = temp_sum - inc_nonop + ind_pi
    hh_inc_total = np.max(hh_with_op, axis=1)
    operator = np.argmax(hh_with_op, axis=1)

    # ---- Whole-family migration ----
    hh_b = hh_lambda*l_bar.flatten()*hh_varphi
    hh_mig = (temp_sum.flatten() - hh_b + l_bar.flatten()*q) > hh_inc_total
    hh_mig = hh_mig.astype(float)
    hh_inc_total = (hh_inc_total*(1-hh_mig) +
                    (temp_sum.flatten()+l_bar.flatten()*q-hh_b)*hh_mig)

    # ---- Operator dummies ----
    d_ope = np.zeros((N_sim, N_ind))
    for i in range(N_ind):
        d_ope[:, i] = (operator == i)*(1-hh_mig)

    # ---- Non-operator adjustments ----
    d_u, d_a = d_u*(1-d_ope), d_a*(1-d_ope)
    d_ptu = d_ptu*(1-d_ope)

    # ---- Farm-level aggregates ----
    farm_s = np.sum(ind_s*d_ope, axis=1)
    farm_tauy = np.sum(ind_tauy*d_ope, axis=1)
    farm_taul = np.sum(ind_taul*d_ope, axis=1)
    farm_rentin = np.sum(r['ind_l_rentin']*d_ope, axis=1)
    farm_rentout = np.sum(r['ind_l_rentout']*d_ope, axis=1)
    farm_rin = np.sum(r['dummy_ind_rentin']*d_ope, axis=1)
    farm_rout = np.sum(r['dummy_ind_rentout']*d_ope, axis=1)
    farm_rno = np.sum(r['dummy_ind_rentno']*d_ope, axis=1)
    farm_n = np.sum(r['ind_n']*d_ope, axis=1)
    farm_l = np.sum(r['ind_l']*d_ope, axis=1)
    farm_pi = np.sum(ind_pi*d_ope, axis=1)

    # Farm output: y = A · s · l^{θγ} · n^{(1-θ)γ}
    farm_y = (P['A']*farm_s *
              farm_l**(P['theta']*P['gamma']) *
              farm_n**((1-P['theta'])*P['gamma']))

    return {
        'dummy_urban': d_u, 'dummy_agr': d_a,
        'dummy_pt_u': d_ptu, 'dummy_ope': d_ope,
        'ind_pt_ls_u': pt_ls_u,
        'ind_inc_u': inc_u,
        'ind_s': ind_s, 'ind_h': ind_h,
        'ind_xiu': ind_xiu,
        'hh_eta': hh_eta, 'hh_lambda': hh_lambda,
        'hh_varphi': hh_varphi, 'l_bar': l_bar,
        'farm_s': farm_s, 'farm_tauy': farm_tauy, 'farm_taul': farm_taul,
        'farm_rentin': farm_rentin, 'farm_rentout': farm_rentout,
        'dummy_farm_rentin': farm_rin, 'dummy_farm_rentout': farm_rout,
        'dummy_farm_rentno': farm_rno,
        'farm_n': farm_n, 'farm_l': farm_l,
        'farm_pi': farm_pi, 'farm_y': farm_y,
        'operator': operator, 'hh_migration': hh_mig,
        'hh_inc_total': hh_inc_total,
    }


# ======================================================================
# Layer 4: Market Clearing
# ======================================================================

def compute_tax_revenue(P, occ):
    """
    Compute total tax revenue from wedges and distortions.

    Paper: Appendix B.6
           Three sources in baseline:
             TR_xiu  : urban mobility barrier wedge
             TR_tauy : output wedge
             TR_exp  : expropriation losses

    MATLAB: origin_matlab/Matlab-Files/subroutine/taxRevenue.m
    """
    N_sim, N_ind = P['N_sim'], P['N_ind']
    wu = P['Au']

    # Urban mobility barrier revenue
    TR_xiu = 0.
    for i in range(N_ind):
        TR_xiu += (np.sum(occ['dummy_urban'][:,i]*occ['ind_h'][:,i]*wu*
                          occ['ind_xiu'][:,i]) +
                   np.sum(occ['dummy_pt_u'][:,i]*occ['ind_h'][:,i]*
                          (1-P['c_pt_u']-occ['ind_pt_ls_u'][:,i])*wu*
                          occ['ind_xiu'][:,i]))
    TR_xiu /= N_sim

    # Output wedge revenue
    TR_tauy = np.sum(occ['farm_y']*(1-occ['farm_tauy']) +
                     occ['farm_l']*(1-occ['farm_taul']))/N_sim

    # Expropriation losses
    TR_exp = np.sum(occ['hh_eta']*occ['hh_varphi']*occ['farm_rentout']*(1-occ['hh_migration']) +
                    occ['hh_migration']*occ['l_bar'].flatten()*occ['hh_lambda']*occ['hh_varphi']
                    )/N_sim

    return TR_xiu + TR_tauy + TR_exp


def land_labor_market(P, occ):
    """
    Land and agricultural labour market clearing.

    Paper: Section IV.D (Equilibrium)
    MATLAB: origin_matlab/Matlab-Files/subroutine/landLaborMarket.m
    """
    N_sim, N_ind = P['N_sim'], P['N_ind']

    # Land market
    AD_L = np.sum(occ['farm_rentin'])/N_sim
    AS_L = (np.sum(occ['farm_rentout']) +
            np.sum(occ['hh_migration']*occ['l_bar'].flatten()))/N_sim
    dist_L = (AD_L-AS_L)/(0.5*AD_L+0.5*AS_L+0.001)

    # Agricultural labour market
    AD_Na = np.sum(occ['farm_n'])/N_sim
    AS_Na = 0.
    for i in range(N_ind):
        AS_Na += (np.sum(occ['dummy_agr'][:,i]) +
                  np.sum(occ['dummy_pt_u'][:,i]*
                         occ['ind_pt_ls_u'][:,i]**P['nu']*P['kappa']) +
                  P['ope_ls']*np.sum(occ['dummy_ope'][:,i]))
    AS_Na /= N_sim
    dist_Na = (AD_Na-AS_Na)/(0.5*AD_Na+0.5*AS_Na+0.001)

    return dist_Na, dist_L


def nonagr_problem(P, occ, TR):
    """
    Non-agricultural sector and national accounts (urban only).

    Paper: Section IV.D (Equilibrium)
    MATLAB: origin_matlab/Matlab-Files/subroutine/nonAgrProblem.m
    """
    N_sim, N_ind = P['N_sim'], P['N_ind']
    wu = P['Au']

    DI = (np.sum(occ['hh_inc_total'])/N_sim + TR -
          (N_ind+P['Nn_u'])*P['cbar'] +
          P['B']*P['Nn_u']*np.mean(occ['ind_h'])*wu)

    # Urban nonagr effective labour supply
    Hu = 0.
    for i in range(N_ind):
        Hu += np.sum((occ['dummy_urban'][:,i] +
                      occ['dummy_pt_u'][:,i]*
                      (1-P['c_pt_u']-occ['ind_pt_ls_u'][:,i]))*occ['ind_h'][:,i])
    Hu = Hu/N_sim + P['B']*P['Nn_u']*np.mean(occ['ind_h'])

    exp_n = (1-P['phi'])*DI
    AD_n = exp_n
    AS_n = Hu*P['Au']

    GDPi = (np.sum(occ['hh_inc_total'])/N_sim + TR +
            P['B']*P['Nn_u']*np.mean(occ['ind_h'])*wu)

    return {'DI': DI, 'Hu': Hu, 'AD_n': AD_n, 'AS_n': AS_n, 'GDPi': GDPi}


def agr_market(p, P, occ, nonagr):
    """
    Agricultural goods market clearing.

    Paper: Section IV.D (Equilibrium)
    MATLAB: origin_matlab/Matlab-Files/subroutine/agrMarket.m
    """
    N_ind = P['N_ind']
    DI = nonagr['DI']
    total_pop = N_ind + P['Nn_u']

    AD_a = P['phi']*DI/p + total_pop*P['cbar']
    AS_a = np.sum(occ['farm_y']*(1-occ['hh_migration']))/P['N_sim']
    dist_ADA = (AD_a-AS_a)/(0.5*AD_a+0.5*AS_a+0.001)

    return dist_ADA, AD_a, AS_a


# ======================================================================
# Layer 5: Equilibrium Solver (Inner Loop)
# ======================================================================

def equilibrium_residuals(X_price, P, ind_blocks):
    """
    Market-clearing residuals for candidate prices [p, q, wa].

    Paper: Section IV.D — 3 equations, 3 unknowns.
    MATLAB: origin_matlab/Matlab-Files/subroutine/solveEquilibriumVector.m
    """
    p, q, wa = X_price

    occ = occupational_choice(
        p, q, wa, P,
        ind_blocks['ind_s'], ind_blocks['ind_h'],
        ind_blocks['ind_xiu'],
        ind_blocks['ind_s_tilde'], ind_blocks['ind_s_tilde2'],
        ind_blocks['ind_tauy'], ind_blocks['ind_taul'],
        ind_blocks['hh_eta'], ind_blocks['hh_lambda'],
        ind_blocks['hh_varphi'], ind_blocks['l_bar'])

    TR = compute_tax_revenue(P, occ)
    d_Na, d_L = land_labor_market(P, occ)
    nonagr = nonagr_problem(P, occ, TR)
    d_ADA, _, _ = agr_market(p, P, occ, nonagr)

    return np.array([d_Na, d_ADA, d_L])


def solve_equilibrium(P, ind_blocks, x0=None, retry=True):
    """
    Solve for equilibrium prices (p, q, wa) using least_squares.

    MATLAB: lsqnonlin, ftol=1e-15, gtol=1e-10, xtol=1e-7, maxfev=1000.
            Retries once with random x0 if fval > 0.001.
    """
    if x0 is None:
        x0 = np.array([0.5, 0.5, 0.3])
    LB = np.array([0., 0., 0.])
    UB = np.array([5., 5., 5.])

    res = least_squares(equilibrium_residuals, x0, bounds=(LB, UB),
                        method='trf', ftol=1e-15, gtol=1e-10, xtol=1e-7,
                        max_nfev=1000, args=(P, ind_blocks))
    X_best = res.x
    fval_best = np.max(np.abs(res.fun)) if len(res.fun) > 0 else 999.

    if retry and fval_best > 0.001:
        for _ in range(1):
            x0_rand = LB + np.random.rand(3)*(UB-LB)
            res2 = least_squares(equilibrium_residuals, x0_rand,
                                 bounds=(LB, UB), method='trf',
                                 ftol=1e-15, gtol=1e-10, xtol=1e-7,
                                 max_nfev=1000, args=(P, ind_blocks))
            f2 = np.max(np.abs(res2.fun)) if len(res2.fun) > 0 else 999.
            if f2 < fval_best:
                X_best, fval_best = res2.x, f2
            if f2 < 0.001:
                break

    p, q, wa = X_best

    occ = occupational_choice(
        p, q, wa, P,
        ind_blocks['ind_s'], ind_blocks['ind_h'],
        ind_blocks['ind_xiu'],
        ind_blocks['ind_s_tilde'], ind_blocks['ind_s_tilde2'],
        ind_blocks['ind_tauy'], ind_blocks['ind_taul'],
        ind_blocks['hh_eta'], ind_blocks['hh_lambda'],
        ind_blocks['hh_varphi'], ind_blocks['l_bar'])

    TR = compute_tax_revenue(P, occ)
    _, _ = land_labor_market(P, occ)
    nonagr = nonagr_problem(P, occ, TR)
    _, AD_a, AS_a = agr_market(p, P, occ, nonagr)

    return {'p': p, 'q': q, 'wa': wa, 'fval': fval_best,
            'success': fval_best <= 0.001,
            'occ': occ, 'TR': TR, 'nonagr': nonagr,
            'AD_a': AD_a, 'AS_a': AS_a}


# ======================================================================
# Layer 6: Model Moments
# ======================================================================

def compute_all_moments(P, occ, nonagr, AD_a, AS_a, p):
    """
    Compute all 14 model moments (Table IV).

    MATLAB subroutines (in order):
      sectoralShare, familyStatistics, stdIncNonagr,
      incDiffSector, incDiffNonagrMigration, aveHourPT,
      corrIncLSPT1, agrProductionMoment, medianAbility,
      withinFamilySelection
    """
    N_sim, N_ind = P['N_sim'], P['N_ind']
    wu = P['Au']
    total_pop = N_ind + P['Nn_u']

    # ---- sectoralShare.m ----
    GDPe = AD_a*p + nonagr['AS_n']
    agr_emp_share = np.sum(
        occ['dummy_ope'] + occ['dummy_agr'] +
        occ['dummy_pt_u']*occ['ind_pt_ls_u']/(1-P['c_pt_u'])
    )/N_sim/total_pop
    agr_VA_share = AD_a*p/GDPe

    # ---- familyStatistics.m ----
    PCT_family_operator = np.sum(np.sum(occ['dummy_ope'], axis=1) > 0)/N_sim

    # ---- stdIncNonagr.m ----
    wn_Mat = wu*(occ['dummy_urban']+occ['dummy_pt_u'])
    d_ft = occ['dummy_urban']+occ['dummy_pt_u']

    ft_income = occu_separate(d_ft.flatten(), occ['ind_h'].flatten()*wn_Mat.flatten(), 1)
    std_inc_nonagr = np.std(np.log(ft_income)) if len(ft_income) > 1 else 0.

    # Within-HH correlation (exactly 2 nonagr workers)
    pairs = []
    for i in range(N_sim):
        if np.sum(d_ft[i,:]) == 2:
            idx = np.where(d_ft[i,:])[0]
            if len(idx) == 2:
                pairs.append([np.log(occ['ind_h'][i,idx[0]]*wn_Mat[i,idx[0]]),
                              np.log(occ['ind_h'][i,idx[1]]*wn_Mat[i,idx[1]])])
    if len(pairs) > 1:
        a = np.array(pairs)
        std_inc_nonagr_across = spearmanr(a[:,0], a[:,1])[0]
    else:
        std_inc_nonagr_across = 0.

    # Corr(farming profit, nonagr wage) — exactly 1 nonagr worker, no migration
    pi_nagr = []
    for i in range(N_sim):
        if np.sum(d_ft[i,:]) == 1 and occ['hh_migration'][i] == 0:
            idx = np.where(d_ft[i,:])[0][0]
            pi_nagr.append([np.log(occ['ind_h'][i,idx]*wn_Mat[i,idx]),
                            np.log(occ['farm_pi'][i])])
    if len(pi_nagr) > 1 and np.all(np.isfinite(np.array(pi_nagr))):
        a = np.array(pi_nagr)
        corr_pi_nonagr = spearmanr(a[:,0], a[:,1])[0]
    else:
        corr_pi_nonagr = 1.

    # ---- incDiffSector.m ----
    eps = 1e-16
    inc_diff_uo = (np.sum(np.log(occ['ind_h']*wu+eps)*
                          (occ['dummy_urban']+occ['dummy_pt_u']))/
                   (np.sum(occ['dummy_urban']+occ['dummy_pt_u'])+eps) -
                   np.sum(np.log(occ['farm_y']*p+eps)*(1-occ['hh_migration']))/
                   (np.sum(1-occ['hh_migration'])+eps))

    # ---- incDiffNonagrMigration.m ----
    mig_data = []
    for i in range(N_sim):
        n_i = np.sum(d_ft[i,:])
        if n_i > 0:
            avg_w = (np.sum(np.log(occ['ind_h'][i,:]*wu+eps)*
                           (occ['dummy_urban'][i,:]+occ['dummy_pt_u'][i,:])))/n_i
            mig_data.append([avg_w, 1-occ['hh_migration'][i]])
    if len(mig_data) > 1:
        a = np.array(mig_data)
        w_op = occu_separate(a[:,1], a[:,0], 1)
        w_no = occu_separate(a[:,1], a[:,0], 0)
        inc_diff_nonagr_migration = (np.mean(w_op)-np.mean(w_no)
                                     if len(w_op) and len(w_no) else 0.)
    else:
        inc_diff_nonagr_migration = 0.

    # ---- aveHourPT.m ----
    pts = occu_separate(
        occ['dummy_pt_u'].flatten(),
        occ['ind_pt_ls_u'].flatten()/(1-P['c_pt_u'])*occ['dummy_pt_u'].flatten(), 1)
    ave_hour_pt = np.median(pts) if len(pts) > 0 else 0.

    # ---- corrIncLSPT1.m ----
    pt_mask = occ['dummy_pt_u'].flatten()
    inc_pt = occu_separate(pt_mask,
        occ['dummy_pt_u'].flatten()*occ['ind_h'].flatten()*(1-P['c_pt_u']-occ['ind_pt_ls_u'].flatten()), 1)
    ls_pt = occu_separate(pt_mask,
        occ['dummy_pt_u'].flatten()*(1-P['c_pt_u']-occ['ind_pt_ls_u'].flatten())/(1-P['c_pt_u']), 1)
    mask_mid = (ls_pt >= 0.65) & (ls_pt <= 0.80)
    corr_inc_ls_pt = (spearmanr(inc_pt[mask_mid], ls_pt[mask_mid])[0]
                      if np.sum(mask_mid) > 1 else 1.)

    # ---- agrProductionMoment.m ----
    denom = (np.maximum(occ['farm_l'], 1e-10)**P['theta'] *
             np.maximum(occ['farm_n'], 1e-10)**(1-P['theta']))
    TFPR = occ['farm_y']/np.maximum(denom, 1e-10)

    tfpr_op = occu_separate(1-occ['hh_migration'], TFPR, 1)
    tfpq_op = occu_separate(1-occ['hh_migration'], occ['farm_s'], 1)
    std_farm_TFPR = np.std(np.log(tfpr_op)) if len(tfpr_op) > 1 else 0.
    std_farm_TFPQ = np.std(np.log(tfpq_op)) if len(tfpq_op) > 1 else 0.

    mask_rin = (1-occ['hh_migration'])*occ['dummy_farm_rentin']
    t_rin = occu_separate(mask_rin, occ['farm_s'], 1)
    f_rin = occu_separate(mask_rin, TFPR, 1)
    corr_farm_TFPQ_TFPR = (spearmanr(np.log(t_rin), np.log(f_rin))[0]
                           if len(t_rin) > 1 and len(f_rin) > 1 else 1.)

    # ---- medianAbility.m ----
    tfpq_all = occu_separate(occ['hh_migration'], occ['farm_s'], 0)
    median_TFPQ = np.median(np.log(tfpq_all)) if len(tfpq_all) > 0 else 0.
    urb_h = occu_separate(occ['dummy_urban'].flatten()+occ['dummy_pt_u'].flatten(),
                          occ['ind_h'].flatten(), 1)
    median_u = np.median(np.log(urb_h)) if len(urb_h) > 0 else 0.

    # ---- withinFamilySelection.m ----
    hh_s_max = np.max(occ['ind_s'], axis=1)
    no_mig = 1-occ['hh_migration']
    sel = occu_separate(no_mig, hh_s_max, 1) == occu_separate(no_mig, occ['farm_s'], 1)
    frac_sorting = np.sum(sel)/np.sum(occu_separate(no_mig, np.ones(N_sim), 1)) \
                   if np.sum(no_mig == 1) > 0 else 0.

    return {
        'agr_emp_share': agr_emp_share,
        'agr_VA_share': agr_VA_share,
        'PCT_family_operator': PCT_family_operator,
        'std_inc_nonagr': std_inc_nonagr,
        'std_inc_nonagr_across': std_inc_nonagr_across,
        'corr_pi_nonagr': corr_pi_nonagr,
        'inc_diff_uo': inc_diff_uo,
        'inc_diff_nonagr_migration': inc_diff_nonagr_migration,
        'ave_hour_pt': ave_hour_pt,
        'corr_inc_ls_pt': corr_inc_ls_pt,
        'std_farm_TFPQ': std_farm_TFPQ,
        'std_farm_TFPR': std_farm_TFPR,
        'corr_farm_TFPQ_TFPR': corr_farm_TFPQ_TFPR,
        'median_TFPQ': median_TFPQ,
        'median_u': median_u,
        'frac_sorting': frac_sorting,
    }


def compute_loss(moments, occ, P):
    """
    Compute RMSE loss for 14 calibration-targeted moments.

    Paper: Section V (Calibration) — Method of Simulated Moments
    MATLAB: origin_matlab/Matlab-Files/subroutine/lossFunc.m (case_id==1)
    """
    data = get_data_moments()
    N_sim, N_ind = P['N_sim'], P['N_ind']

    m = np.zeros(14)
    d = np.zeros(14)
    i = -1

    # 1: FT nonagr employment share
    i += 1; m[i] = np.sum(occ['dummy_urban'])/N_sim/N_ind
    d[i] = data['data_ft_nonagr_share']

    # 2: PT employment share
    i += 1; m[i] = np.sum(occ['dummy_pt_u'])/N_sim/N_ind
    d[i] = data['data_pt_share']

    # 3: Median agricultural hours among PT
    i += 1; m[i] = moments['ave_hour_pt']
    d[i] = data['data_ave_hour_pt']

    # 4: Family with operator share
    i += 1; m[i] = moments['PCT_family_operator']
    d[i] = data['data_PCT_family_operator']

    # 5: Std dev of log FT nonagr income
    i += 1; m[i] = moments['std_inc_nonagr']
    d[i] = data['data_std_inc_nonagr']

    # 6: Within-HH Spearman corr of log nonagr income
    i += 1; m[i] = moments['std_inc_nonagr_across']
    d[i] = data['data_std_inc_nonagr_across']

    # 7: Nonagr - Operator wage gap
    i += 1; m[i] = moments['inc_diff_uo']
    d[i] = data['data_inc_diff_uo']

    # 8: Corr(farming profit, nonagr wage)
    i += 1; m[i] = moments['corr_pi_nonagr']
    d[i] = data['data_corr_pi_nonagr']

    # 9: Corr(income, labour supply) among PT
    i += 1; m[i] = moments['corr_inc_ls_pt']
    d[i] = data['data_corr_inc_ls_pt']

    # 10: Std dev of log farm TFPQ
    i += 1; m[i] = moments['std_farm_TFPQ']
    d[i] = data['data_std_farm_TFPQ']

    # 11: Std dev of log farm TFPR
    i += 1; m[i] = moments['std_farm_TFPR']
    d[i] = data['data_std_farm_TFPR']

    # 12: Corr(TFPQ, TFPR) among rent-in farmers
    i += 1; m[i] = moments['corr_farm_TFPQ_TFPR']
    d[i] = data['data_corr_farm_TFPQ_TFPR']

    # 13: Migration income difference
    i += 1; m[i] = moments['inc_diff_nonagr_migration']
    d[i] = data['data_inc_diff_migration']

    # 14: GLW gap = Agr VA share / Agr Emp share
    i += 1; m[i] = moments['agr_VA_share']/(moments['agr_emp_share']+1e-16)
    d[i] = data['data_GLW_inv']

    return np.sqrt(np.sum((m-d)**2)/14)


# ======================================================================
# Layer 7: Calibration Objective (Outer Loop)
# ======================================================================

def prepare_individual_blocks(P, halton_seq):
    """
    Prepare individual heterogeneity blocks from Halton draws.

    Halton columns used:
      Col (N_ind-1)*5+11 = 21: output wedge ε_τ
      Col (N_ind-1)*5+15 = 25: land compensation φ

    MATLAB: origin_matlab/Matlab-Files/subroutine/computeModelMoments.m
    """
    N_sim, N_ind = P['N_sim'], P['N_ind']

    ab = generate_abilities(P, halton_seq)

    # ---- Output wedges τ_y ----
    col_te = (N_ind-1)*5+11
    ind_tauy_epsilon = np.exp(scipy_norm.ppf(
        halton_seq[:, col_te],
        loc=-P['sigma_tauy']**2/2, scale=P['sigma_tauy']))
    ind_tauy = ab['ind_s']**P['zeta_tauy']*ind_tauy_epsilon[:, None]
    ind_tauy /= np.exp(np.mean(np.log(ind_tauy)))

    ind_s_tilde  = (ab['ind_s']*ind_tauy)**(1/(1-P['gamma']))
    ind_s_tilde2 = (ab['ind_s']*ind_tauy)**(1/(1-P['gamma']*(1-P['theta'])))

    ind_taul = np.ones((N_sim, N_ind))

    # ---- Land insecurity ----
    hh_eta = np.ones(N_sim)*P['mu_eta']
    hh_lambda = hh_eta.copy()

    col_ph = (N_ind-1)*5+15
    hh_varphi = np.exp(scipy_norm.ppf(
        halton_seq[:, col_ph],
        loc=P['mu_varphi']-P['sigma_varphi']**2/2,
        scale=P['sigma_varphi']))

    l_bar = np.ones((N_sim, 1))*P['LS']

    return {
        'ind_s': ab['ind_s'], 'ind_h': ab['ind_h'],
        'ind_xiu': ab['ind_xiu'],
        'ind_s_tilde': ind_s_tilde, 'ind_s_tilde2': ind_s_tilde2,
        'ind_tauy': ind_tauy, 'ind_taul': ind_taul,
        'hh_eta': hh_eta, 'hh_lambda': hh_lambda,
        'hh_varphi': hh_varphi, 'l_bar': l_bar,
    }


def calibration_objective(X):
    """
    Full calibration objective: X → equilibrium → RMSE loss.

    Paper: Section V — Method of Simulated Moments (SMM)
    MATLAB: origin_matlab/Matlab-Files/subroutine/CalibrationComputeMoments.m
    """
    P_calib = assign_parameter_value(X)
    P_exog = set_exogenous_params()
    P = {**P_exog, **P_calib}

    # κ validity check: PT labour supply must not exceed time endowment
    if P['kappa'] >= 1/(1-P['c_pt_u'])**P['nu']:
        return 3.

    halton = Halton(d=30, scramble=False)
    for _ in range(100):
        halton.random(100000)
    hseq = halton.random(P['N_sim'])

    ind_blocks = prepare_individual_blocks(P, hseq)
    eq = solve_equilibrium(P, ind_blocks, retry=True)
    occ = eq['occ']

    if not np.isreal(eq['p']) or not np.isreal(occ['farm_y']).all():
        return 10.

    moments = compute_all_moments(P, occ, eq['nonagr'],
                                  eq['AD_a'], eq['AS_a'], eq['p'])
    loss = compute_loss(moments, occ, P)
    if eq['fval'] > 0.001:
        loss += 2.
    return loss
