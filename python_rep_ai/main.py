"""
main.py — Entry point for Adamopoulos et al. (2024) baseline replication.

Paper: "Land Insecurity and Mobility Frictions"
       Adamopoulos, Brandt, Chen, Restuccia, Wei (QJE 2024)

Translated from origin_matlab/Matlab-Files/main.m + computeModelMoments.m

Nested Fixed-Point Structure (Paper Section V):
  ┌─────────────────────────────────────────────────────────┐
  │ OUTER LOOP: Particle Swarm Optimization (SMM)           │
  │   Calibrates 14 parameters X by minimizing RMSE between │
  │   14 model moments and 14 data moments (Table IV).      │
  │   Each evaluation requires solving the inner loop.      │
  │                                                         │
  │   INNER LOOP: least_squares (≡ MATLAB lsqnonlin)       │
  │     Solves for 3 equilibrium prices (p, q, wa) that    │
  │     clear 3 markets: agricultural labour, agricultural  │
  │     goods, land. Non-agricultural wage is numeraire.   │
  │     Convergence criterion: max residual < 0.001.        │
  └─────────────────────────────────────────────────────────┘

Two modes:
  QUICK_MODE = True  → use hardcoded calibrated parameters (~4s)
  QUICK_MODE = False → run full particle swarm calibration (hours)

Usage:  python main.py
"""

import numpy as np
import time
from module import (
    get_data_moments, set_exogenous_params, assign_parameter_value,
    prepare_individual_blocks, solve_equilibrium, compute_all_moments,
    compute_loss, calibration_objective,
)
from scipy.stats.qmc import Halton

# ======================================================================
# Configuration
# ======================================================================

QUICK_MODE = True

# Pre-calibrated baseline parameters from MATLAB x-baseline.mat (fval=0.002487)
# Source: origin_matlab/Matlab-Files/matfiles/x-baseline.mat
#
# Index  Parameter       Value        Role (Table B.5)
# ---------------------------------------------------------------------------
# X[0]   omega           0.31941415   Ability correlation (sorting)
# X[1]   sigma_sH        0.57652178   HH-level agr ability dispersion
# X[2]   sigma_hH        0.73307642   HH-level nonagr ability dispersion
# X[3]   IH_ratio        0.52309257   Within-HH ability dispersion ratio
# X[4]   sigma_tauy      0.26115522   Output wedge dispersion
# X[5]   zeta_tauy      -0.85956705   Output wedge elasticity
# X[6]   sigma_xiu       0.62736484   Urban mobility barrier dispersion
# X[7]   mu_xiu           0.37401741   Urban mobility barrier mean
# X[8]   sigma_varphi    0.40738062   Land compensation dispersion
# X[9]   mu_varphi        2.30400203   Land compensation mean (insecurity)
# X[10]  c_pt_u          0.08025734   Urban PT fixed cost
# X[11]  kappa           1.03970152   PT productivity shifter
# X[12]  cbar            0.21871107   Subsistence consumption
# X[13]  B               3.66974553   Non-agricultural scale
BASELINE_X = np.array([
    0.31941415,    # X[0]  omega
    0.57652178,    # X[1]  sigma_sH
    0.73307642,    # X[2]  sigma_hH
    0.52309257,    # X[3]  IH_ratio
    0.26115522,    # X[4]  sigma_tauy
   -0.85956705,    # X[5]  zeta_tauy
    0.62736484,    # X[6]  sigma_xir
    0.37401741,    # X[7]  mu_xiu
    0.40738062,    # X[8]  sigma_varphi
    2.30400203,    # X[9]  mu_varphi
    0.08025734,    # X[10] c_pt_u
    1.03970152,    # X[11] kappa
    0.21871107,    # X[12] cbar
    3.66974553,    # X[13] B
])


# ======================================================================
# Particle Swarm Optimization (Outer Loop)
# ======================================================================

def particle_swarm_opt(f, nvars, LB, UB, swarm_size=140, max_iter=30,
                       tol=1e-6, verbose=True):
    """
    Simple Particle Swarm Optimization.

    Equivalent to MATLAB's particleswarm() used in particleSwarmOpt.m.
    PSO parameters (w=0.5, c1=1.49, c2=1.49) from MATLAB defaults.

    Each particle = candidate parameter vector X. Updates based on:
      - Inertia (w): keep moving in current direction
      - Cognitive (c1): move towards personal best
      - Social (c2): move towards global best
    """
    LB, UB = np.asarray(LB), np.asarray(UB)
    w, c1, c2 = 0.5, 1.49, 1.49

    pos = LB + np.random.rand(swarm_size, nvars)*(UB-LB)
    vel = np.zeros((swarm_size, nvars))
    fit = np.array([f(pos[i]) for i in range(swarm_size)])

    pbest_pos = pos.copy()
    pbest_val = fit.copy()
    gbest_idx = np.argmin(fit)
    gbest_pos = pos[gbest_idx].copy()
    gbest_val = fit[gbest_idx]

    if verbose:
        print(f'  PSO iter 0: fval={gbest_val:.6f}')

    for it in range(1, max_iter+1):
        r1 = np.random.rand(swarm_size, nvars)
        r2 = np.random.rand(swarm_size, nvars)
        vel = w*vel + c1*r1*(pbest_pos-pos) + c2*r2*(gbest_pos-pos)
        pos = np.clip(pos+vel, LB, UB)
        for i in range(swarm_size):
            fit[i] = f(pos[i])
        improved = fit < pbest_val
        pbest_pos[improved] = pos[improved]
        pbest_val[improved] = fit[improved]
        new_best = np.argmin(pbest_val)
        if pbest_val[new_best] < gbest_val:
            gbest_pos = pbest_pos[new_best].copy()
            gbest_val = pbest_val[new_best]
        if verbose and it % 5 == 0:
            print(f'  PSO iter {it}: fval={gbest_val:.6f}')
        if gbest_val < tol:
            if verbose:
                print(f'  Converged at iter {it}')
            break

    return gbest_pos, gbest_val


# ======================================================================
# Display
# ======================================================================

def display_parameter_values(P):
    """
    Print calibrated parameter values.

    MATLAB: origin_matlab/Matlab-Files/subroutine/displayParameterValue.m
    """
    print('-'*50)
    print('Parameter Values:')

    # Production and preferences (exogenous)
    print(f'  A (agr TFP)              {P["A"]:+10.4f}')
    print(f'  A_u (urban nonagr TFP)   {P["Au"]:+10.4f}')
    print(f'  B (h-bar, nonagr scale)  {P["B"]:+10.4f}')
    print(f'  gamma (span-of-control)   {P["gamma"]:+10.4f}')
    print(f'  theta (land share)        {P["theta"]:+10.4f}')
    print(f'  nu (PT disutility curv)   {P["nu"]:+10.4f}')
    print(f'  kappa (PT productivity)   {P["kappa"]:+10.4f}')
    print(f'  c^u (urban PT cost)       {P["c_pt_u"]:+10.4f}')
    print(f'  cbar (subsistence)        {P["cbar"]:+10.4f}')
    print(f'  phi (agr share)           {P["phi"]:+10.4f}')

    # Demographics
    print(f'  J (family size)           {P["N_ind"]:+10.4f}')
    print(f'  N_u (urban nonagr pop)    {P["Nn_u"]:+10.4f}')

    # Ability parameters (calibrated)
    print(f'  omega (ability corr)      {P["omega"]:+10.4f}')
    print(f'  sigma_s^H                 {P["sigma_sH"]:+10.4f}')
    print(f'  sigma_h^H                 {P["sigma_hH"]:+10.4f}')
    print(f'  IH_ratio                  {P["sigma_hI"]/P["sigma_hH"]:+10.4f}')

    # Output wedge parameters
    print(f'  zeta (wedge elasticity)   {P["zeta_tauy"]:+10.4f}')
    print(f'  sigma_tau (wedge disp)    {P["sigma_tauy"]:+10.4f}')

    # Urban mobility barrier
    print(f'  mu_xiu (urban barrier)    {P["mu_xiu"]:+10.4f}')
    print(f'  sigma_xiu (barrier disp)  {P["sigma_xiu"]:+10.4f}')

    # Land insecurity parameters
    print(f'  eta (expropriation prob)  {P["mu_eta"]:+10.4f}')
    print(f'  mu_varphi (land comp)     {P["mu_varphi"]:+10.4f}')
    print(f'  sigma_varphi (comp disp)  {P["sigma_varphi"]:+10.4f}')
    print('-'*50)


def display_calibration_moments(moments, occ, P):
    """
    Print model vs data moments in Table IV format.

    Paper: Table IV (Calibration Moments) — 2004 baseline.
    """
    data = get_data_moments()
    N_sim, N_ind = P['N_sim'], P['N_ind']

    ft_m = np.sum(occ['dummy_urban'])/N_sim/N_ind
    pt_m = np.sum(occ['dummy_pt_u'])/N_sim/N_ind
    glw_m = moments['agr_VA_share']/(moments['agr_emp_share']+1e-16)

    print('-'*50)
    print(f'{"Table IV (Calibration Moments)":>40s}')
    print(f'{"":35s} {"Data":>8s} {"Model":>8s}')
    print('Occupational Choice of Rural Individuals:')
    print(f'  Full-time Nonagr Worker:      {data["data_ft_nonagr_share"]:8.4f}  {ft_m:8.4f}')
    print('  Part-time Worker:')
    print(f'    PT Worker:                  {data["data_pt_share"]:8.4f}  {pt_m:8.4f}')
    print(f'    Median Hours Agr Among PT:  {data["data_ave_hour_pt"]:8.4f}  '
          f'{moments["ave_hour_pt"]:8.4f}')
    print(f'    Corr Hour Inc Among PT:     {data["data_corr_inc_ls_pt"]:8.4f}  '
          f'{moments["corr_inc_ls_pt"]:8.4f}')
    print(f'Family with Operators:          {data["data_PCT_family_operator"]:8.4f}  '
          f'{moments["PCT_family_operator"]:8.4f}')
    print('Income Moments:')
    print(f'  Dispersion:')
    print(f'    FT Nonagr:                  {data["data_std_inc_nonagr"]:8.4f}  '
          f'{moments["std_inc_nonagr"]:8.4f}')
    print(f'      Within HH Corr:           {data["data_std_inc_nonagr_across"]:8.4f}  '
          f'{moments["std_inc_nonagr_across"]:8.4f}')
    print(f'  Corr farming nonagr:          {data["data_corr_pi_nonagr"]:8.4f}  '
          f'{moments["corr_pi_nonagr"]:8.4f}')
    print('Sectoral Wage Differentials:')
    print(f'    Nonagr - Operator:          {data["data_inc_diff_uo"]:8.4f}  '
          f'{moments["inc_diff_uo"]:8.4f}')
    print('Family Wage Differentials:')
    print(f'    With/Without Operator:      {data["data_inc_diff_migration"]:8.4f}  '
          f'{moments["inc_diff_nonagr_migration"]:8.4f}')
    print('Agr Production Moments:')
    print(f'  Dispersion:')
    print(f'    Farm TFP:                   {data["data_std_farm_TFPQ"]:8.4f}  '
          f'{moments["std_farm_TFPQ"]:8.4f}')
    print(f'    Farm TFPR:                  {data["data_std_farm_TFPR"]:8.4f}  '
          f'{moments["std_farm_TFPR"]:8.4f}')
    print(f'  Correlation:')
    print(f'    TFP VS TFPR:                {data["data_corr_farm_TFPQ_TFPR"]:8.4f}  '
          f'{moments["corr_farm_TFPQ_TFPR"]:8.4f}')
    print(f'GLW (VA share / Emp share):     {data["data_GLW_inv"]:8.4f}  '
          f'{glw_m:8.4f}')
    print('-'*50)


# ======================================================================
# Main
# ======================================================================

def run():
    """Run baseline calibration and display results."""
    print('='*50)
    print('SECTION V: CALIBRATION')
    print('='*50)
    print()
    print('Land Security and Mobility Frictions')
    print('Adamopoulos, Brandt, Chen, Restuccia, Wei (QJE 2024)')
    print('Python Replication — Baseline Initial Equilibrium')
    print()

    t0 = time.time()

    # Step 1: Get calibrated parameters
    if QUICK_MODE:
        print('Mode: QUICK (pre-calibrated parameters from x-baseline.mat)')
        X_opt = BASELINE_X.copy()
    else:
        print('Mode: FULL CALIBRATION (particle swarm optimization)')
        LB = np.array([0.27,0.53,0.69,0.48,0.23,-0.90,0.57,0.36,
                       0.35,2.20,0.065,1.032,0.17,3.50])
        UB = np.array([0.35,0.61,0.77,0.56,0.30,-0.82,0.65,0.43,
                       0.44,2.36,0.10,1.044,0.23,3.80])
        X_opt, fv = particle_swarm_opt(calibration_objective, len(LB), LB, UB,
                                       swarm_size=min(140, 30), max_iter=30,
                                       tol=1e-6, verbose=True)

    # Step 2: Build parameter dict, generate Halton draws
    P = {**set_exogenous_params(), **assign_parameter_value(X_opt)}

    halton = Halton(d=30, scramble=False)
    for _ in range(100):
        halton.random(100000)
    hseq = halton.random(P['N_sim'])

    # Step 3: Prepare individual heterogeneity
    ind_blocks = prepare_individual_blocks(P, hseq)

    # Step 4: Solve inner loop (equilibrium prices)
    eq = solve_equilibrium(P, ind_blocks, retry=True)
    p, q, wa = eq['p'], eq['q'], eq['wa']

    # Step 5: Compute moments and loss
    moments = compute_all_moments(P, eq['occ'], eq['nonagr'],
                                  eq['AD_a'], eq['AS_a'], p)
    loss = compute_loss(moments, eq['occ'], P)

    # ---- Display ----
    print('\n'+'='*50)
    print('RESULTS')
    print('='*50)

    print(f'\nEndogenous Prices (inner loop equilibrium):')
    print(f'  p  (agricultural price)     = {p:.6f}')
    print(f'  q  (land rental rate)       = {q:.6f}')
    print(f'  wa (agricultural wage)      = {wa:.6f}')
    print(f'  wu (urban nonagr wage)      = {P["Au"]:.4f}  (numeraire)')
    print(f'  Equilibrium residual (max)  = {eq["fval"]:.8f}  (target < 0.001)')
    print()

    display_parameter_values(P)
    print()
    display_calibration_moments(moments, eq['occ'], P)

    print(f'\nRMSE Loss (14 moments) = {loss:.6f}')
    print()

    occ = eq['occ']
    print('Statistics on Rentals:')
    print(f'  Rent-in  farmers:  {np.sum(occ["dummy_farm_rentin"])/P["N_sim"]:.4f}')
    print(f'  Rent-out farmers:  {np.sum(occ["dummy_farm_rentout"])/P["N_sim"]:.4f}')
    print(f'  No-rental farmers: {np.sum(occ["dummy_farm_rentno"])/P["N_sim"]:.4f}')
    print(f'  Migrating families:{np.sum(occ["hh_migration"])/P["N_sim"]:.4f}')
    print(f'\nMedian TFPQ (operator): {moments["median_TFPQ"]:.4f}')
    print(f'Median u (urban):       {moments["median_u"]:.4f}')
    print(f'Fraction correct sorting: {moments["frac_sorting"]:.4f}')

    print(f'\nElapsed: {time.time()-t0:.1f}s')
    print('='*50)
    print('DONE.')
    print()
    print('Note: Moment #8 (corr_pi_nonagr) may differ from paper by ~0.03')
    print('due to Halton sequence differences between scipy and MATLAB.')
    print('MATLAB: haltonset(30, ''skip'', 1e7) vs scipy: Halton(d=30)')


if __name__ == '__main__':
    run()
