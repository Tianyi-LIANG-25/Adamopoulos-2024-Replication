"""
main.py — Entry point for Adamopoulos et al. (2024) Initial Equilibrium.

Translated from origin_matlab/Matlab-Files/main.m + computeModelMoments.m
Original authors: Adamopoulos, Brandt, Chen, Restuccia, Wei (QJE 2024)

This script:
  1. Sets up the baseline model configuration (case_id=1)
  2. Runs the calibration via particle swarm (outer loop) with equilibrium
     solving (inner loop) — the calibration IS the initial equilibrium.
  3. Displays calibrated parameters, endogenous prices, and model vs data moments.

Two modes:
  - QUICK_MODE = True  → use hardcoded pre-calibrated parameters (fast verification)
  - QUICK_MODE = False → run full particle swarm calibration (slow but authentic)

Usage:
  python main.py
"""

import numpy as np
import time
from module import (
    get_data_moments,
    set_exogenous_params,
    assign_parameter_value,
    prepare_individual_blocks,
    solve_equilibrium,
    compute_all_moments,
    calibration_objective,
)

# ===========================================================================
# Configuration
# ===========================================================================

CASE_ID = 1
QUICK_MODE = True  # True: use hardcoded params; False: run full calibration

# Pre-calibrated baseline parameters (from x-baseline.mat)
# X = [omega, sigma_sH, sigma_hH, IH_ratio, sigma_tauy, zeta_tauy,
#      sigma_xir, mu_xiu_y, sigma_varphi, mu_varphi, c_pt_u, kappa, cbar, B]
BASELINE_X = np.array([
    0.31941415,    # X[0]  — omega
    0.57652178,    # X[1]  — sigma_sH
    0.73307642,    # X[2]  — sigma_hH
    0.52309257,    # X[3]  — IH_ratio
    0.26115522,    # X[4]  — sigma_tauy
    -0.85956705,   # X[5]  — zeta_tauy
    0.62736484,    # X[6]  — sigma_xir
    0.37401741,    # X[7]  — mu_xiu_y
    0.40738062,    # X[8]  — sigma_varphi
    2.30400203,    # X[9]  — mu_varphi
    0.08025734,    # X[10] — c_pt_u
    1.03970152,    # X[11] — kappa
    0.21871107,    # X[12] — cbar
    3.66974553,    # X[13] — B
])


# ===========================================================================
# Particle Swarm Optimization (Simple Implementation)
# ===========================================================================

def particle_swarm_opt(objective_func, nvars, LB, UB, swarm_size=140,
                       max_iter=30, tol=1e-6, verbose=True):
    """
    Simple Particle Swarm Optimization.
    Equivalent to MATLAB's particleswarm().

    Parameters
    ----------
    objective_func : callable
        Function to minimize: f(X) → float.
    nvars : int
        Number of variables.
    LB, UB : np.ndarray
        Lower and upper bounds.
    swarm_size : int
        Number of particles.
    max_iter : int
        Maximum iterations.
    tol : float
        Convergence tolerance on function value.
    verbose : bool
        Print iteration info.

    Returns
    -------
    X_best : np.ndarray
        Best parameters found.
    fval_best : float
        Best function value.
    """
    LB = np.asarray(LB)
    UB = np.asarray(UB)

    # PSO hyperparameters
    w = 0.5       # Inertia weight
    c1 = 1.49     # Cognitive (personal best) coefficient
    c2 = 1.49     # Social (global best) coefficient

    # Initialize swarm
    positions = LB + np.random.rand(swarm_size, nvars) * (UB - LB)
    velocities = np.zeros((swarm_size, nvars))

    # Evaluate initial positions
    fitness = np.full(swarm_size, np.inf)
    for i in range(swarm_size):
        fitness[i] = objective_func(positions[i])

    personal_best_pos = positions.copy()
    personal_best_val = fitness.copy()

    global_best_idx = np.argmin(fitness)
    global_best_pos = positions[global_best_idx].copy()
    global_best_val = fitness[global_best_idx]

    if verbose:
        print(f'  PSO iter 0: best fval = {global_best_val:.6f}')

    for iteration in range(1, max_iter + 1):
        # Update velocity and position
        r1 = np.random.rand(swarm_size, nvars)
        r2 = np.random.rand(swarm_size, nvars)

        velocities = (w * velocities +
                      c1 * r1 * (personal_best_pos - positions) +
                      c2 * r2 * (global_best_pos - positions))

        positions = positions + velocities

        # Enforce bounds
        positions = np.clip(positions, LB, UB)

        # Evaluate
        for i in range(swarm_size):
            fitness[i] = objective_func(positions[i])

        # Update personal bests
        improved = fitness < personal_best_val
        personal_best_pos[improved] = positions[improved]
        personal_best_val[improved] = fitness[improved]

        # Update global best
        new_global_idx = np.argmin(personal_best_val)
        if personal_best_val[new_global_idx] < global_best_val:
            global_best_pos = personal_best_pos[new_global_idx].copy()
            global_best_val = personal_best_val[new_global_idx]

        if verbose and iteration % 5 == 0:
            print(f'  PSO iter {iteration}: best fval = {global_best_val:.6f}')

        # Check convergence
        if global_best_val < tol:
            if verbose:
                print(f'  PSO converged (fval < {tol}) at iteration {iteration}')
            break

    return global_best_pos, global_best_val


# ===========================================================================
# Display Functions
# ===========================================================================

def display_parameter_values(P):
    """Print parameter values table (equivalent to displayParameterValue.m)."""
    print('-' * 50)
    print('Display parameter values:')
    print(f'  A               {P.get("A", 0):+5.3f}')
    print(f'  A_r             {P.get("Ar", 0):+5.3f}')
    print(f'  A_u             {P.get("Au", 0):+5.3f}')
    print(f'  B (h_bar)       {P.get("B", 0):+5.3f}')
    print(f'  gamma           {P.get("gamma", 0):+5.3f}')
    print(f'  theta           {P.get("theta", 0):+5.3f}')
    print(f'  nu              {P.get("nu", 0):+5.3f}')
    print(f'  kappa           {P.get("kappa", 0):+5.3f}')
    print(f'  c^r             {P.get("c_pt_r", 0):+5.3f}')
    print(f'  c^u             {P.get("c_pt_u", 0):+5.3f}')
    print(f'  cbar (a_bar)    {P.get("cbar", 0):+5.3f}')
    print(f'  phi             {P.get("phi", 0):+5.3f}')
    print(f'  J               {P.get("N_ind", 0):+5.3f}')
    print(f'  N_r             {P.get("Nn_r", 0):+5.3f}')
    print(f'  N_u             {P.get("Nn_u", 0):+5.3f}')
    print(f'  p_o             {P.get("old", 0):+5.3f}')
    print(f'  omega (lambda)  {P.get("omega", 0):+5.3f}')
    print(f'  sigma_s^H       {P.get("sigma_sH", 0):+5.3f}')
    print(f'  sigma_h^H       {P.get("sigma_hH", 0):+5.3f}')
    print(f'  IH_ratio        {P.get("sigma_hI", 0) / P.get("sigma_hH", 1):+5.3f}')
    print(f'  mu_s^y          {P.get("mu_sI_y", 0):+5.3f}')
    print(f'  mu_h^y          {P.get("mu_hI_y", 0):+5.3f}')
    print(f'  zeta            {P.get("zeta_tauy", 0):+5.3f}')
    print(f'  sigma_tau       {P.get("sigma_tauy", 0):+5.3f}')
    print(f'  mu_r            {P.get("mu_xir_y", 0):+5.3f}')
    print(f'  mu_u            {P.get("mu_xiu_y", 0):+5.3f}')
    print(f'  mu_r^o          {P.get("mu_xir_o", 0) - P.get("mu_xir_y", 0):+5.3f}')
    print(f'  mu_u^o          {P.get("mu_xiu_o", 0) - P.get("mu_xiu_y", 0):+5.3f}')
    print(f'  sigma_xi        {P.get("sigma_xir", 0):+5.3f}')
    print(f'  eta             {P.get("mu_eta", 0):+5.3f}')
    print(f'  mu_varphi       {P.get("mu_varphi", 0):+5.3f}')
    print(f'  sigma_varphi    {P.get("sigma_varphi", 0):+5.3f}')
    print('-' * 50)


def display_calibration_moments(moments, occ, data_moments, P):
    """
    Print model vs data moments table.
    Equivalent to calibrationMoments.m (case_id==1 branch).
    """
    N_sim = P['N_sim']
    N_ind = P['N_ind']

    # Model moments that need occ-level access
    rural_nonagr_emp_model = np.sum(occ['dummy_rural'] + occ['dummy_urban']) / N_sim / N_ind
    pt_emp_model = np.sum(occ['dummy_pt_r'] + occ['dummy_pt_u']) / N_sim / N_ind
    GLW_model = moments['agr_VA_share'] / moments['agr_emp_share']

    rural_nonagr_emp_data = (data_moments['data_rural_nonagr_emp'] +
                             data_moments['data_urban_nonagr_emp'])
    pt_emp_data = (data_moments['data_parttime_rural_emp'] +
                   data_moments['data_parttime_urban_emp'])

    print('-' * 50)
    print(f'{"":40s} {"Data":>8s} {"Model":>8s}')
    print('Occupational Choice of Rural Individuals:')
    print(f'  Full-time  Nonagr Worker:     {rural_nonagr_emp_data:+8.4f}  {rural_nonagr_emp_model:+8.4f}')
    print('  Part-time Worker:')
    print(f'    PT Worker:                  {pt_emp_data:+8.4f}  {pt_emp_model:+8.4f}')
    print(f'    Median Hours Agr Among PT:  {data_moments["data_ave_hour_pt"]:+8.4f}  '
          f'{moments.get("ave_hour_pt", 0):+8.4f}')
    print(f'    Corr Hour Inc Among PT:     {data_moments["data_corr_inc_ls_pt"]:+8.4f}  '
          f'{moments.get("corr_inc_ls_pt", 0):+8.4f}')
    print(f'Family with Operators:          {data_moments["data_PCT_family_operator"]:+8.4f}  '
          f'{moments.get("PCT_family_operator", 0):+8.4f}')
    print('Income Moments:')
    print(f'  Dispersion:')
    print(f'    FT Nonagr:                  {data_moments["data_std_inc_nonagr"]:+8.4f}  '
          f'{moments.get("std_inc_nonagr", 0):+8.4f}')
    print(f'      Within HH Corr:           {data_moments["data_std_inc_nonagr_across"]:+8.4f}  '
          f'{moments.get("std_inc_nonagr_across", 0):+8.4f}')
    print(f'  Corr farming nonagr:          {data_moments["data_corr_pi_nonagr"]:+8.4f}  '
          f'{moments.get("corr_pi_nonagr", 0):+8.4f}')
    print('Sectoral Wage Differentials:')
    print(f'    Nonagr - Operator:          {data_moments["data_inc_diff_uo"]:+8.4f}  '
          f'{moments.get("inc_diff_uo", 0):+8.4f}')
    print('Family Wage Differentials:')
    print(f'    With/Without Operator:      {data_moments["data_inc_diff_nonagr_migration"]:+8.4f}  '
          f'{moments.get("inc_diff_nonagr_migration", 0):+8.4f}')
    print('Agr Production Moments:')
    print(f'  Dispersion:')
    print(f'    Farm TFP:                   {data_moments["data_std_farm_TFPQ"]:+8.4f}  '
          f'{moments.get("std_farm_TFPQ", 0):+8.4f}')
    print(f'    Farm TFPR:                  {data_moments["data_std_farm_TFPR"]:+8.4f}  '
          f'{moments.get("std_farm_TFPR", 0):+8.4f}')
    print(f'  Correlation:')
    print(f'    TFP VS TFPR:                {data_moments["data_corr_farm_TFPQ_TFPR"]:+8.4f}  '
          f'{moments.get("corr_farm_TFPQ_TFPR", 0):+8.4f}')
    print(f'GLW Gap:                        {data_moments["data_GLW_inv"]:+8.4f}  '
          f'{GLW_model:+8.4f}')
    print('-' * 50)


# ===========================================================================
# Main Flow
# ===========================================================================

def run_initial_equilibrium():
    """
    Run the full initial equilibrium: calibration (outer loop) +
    equilibrium solving (inner loop).
    """
    print('=' * 50)
    print('SECTION V: CALIBRATION')
    print('=' * 50)
    print()
    print('Land Security and Mobility Frictions')
    print('Adamopoulos, Brandt, Chen, Restuccia, Wei (QJE 2024)')
    print('Python Replication — Initial Equilibrium (case_id=1)')
    print()

    t_start = time.time()

    # --- Get data moments ---
    data_moments = get_data_moments(CASE_ID)

    # --- Get exogenous parameters ---
    P_exog = set_exogenous_params(CASE_ID)

    if QUICK_MODE:
        # ---------------------------------------------------------------
        # QUICK MODE: Use pre-calibrated parameters
        # ---------------------------------------------------------------
        print('Mode: QUICK (using pre-calibrated parameters)')
        print()

        X_opt = BASELINE_X.copy()
        P_calib = assign_parameter_value(X_opt, CASE_ID)
        P = {**P_exog, **P_calib}

        # Generate Halton, prepare individuals, solve equilibrium
        from scipy.stats.qmc import Halton
        halton_sampler = Halton(d=30, scramble=False)
        for _ in range(100):
            halton_sampler.random(100000)
        halton_seq = halton_sampler.random(P['N_sim'])

        ind_blocks = prepare_individual_blocks(P, halton_seq)
        eq_results = solve_equilibrium(P, ind_blocks, retry=True)

        loss = None

    else:
        # ---------------------------------------------------------------
        # FULL CALIBRATION: Particle Swarm Optimization
        # ---------------------------------------------------------------
        print('Mode: FULL CALIBRATION (particle swarm)')
        print('This may take a long time...')
        print()

        # Parameter bounds (14 parameters for baseline)
        # Same as particleSwarmOpt.m case_id=1
        LB = np.array([
            0.27,   # 1  omega
            0.53,   # 2  sigma_sH
            0.69,   # 3  sigma_hH
            0.48,   # 4  IH_ratio
            0.23,   # 5  sigma_tauy
            -0.90,  # 6  zeta_tauy
            0.57,   # 7  sigma_xir
            0.36,   # 8  mu_xiu_y
            0.35,   # 9  sigma_varphi
            2.20,   # 10 mu_varphi
            0.065,  # 11 c_pt_u
            1.032,  # 12 kappa
            0.17,   # 13 cbar
            3.50,   # 14 B
        ])
        UB = np.array([
            0.35,   # 1  omega
            0.61,   # 2  sigma_sH
            0.77,   # 3  sigma_hH
            0.56,   # 4  IH_ratio
            0.30,   # 5  sigma_tauy
            -0.82,  # 6  zeta_tauy
            0.65,   # 7  sigma_xir
            0.43,   # 8  mu_xiu_y
            0.44,   # 9  sigma_varphi
            2.36,   # 10 mu_varphi
            0.10,   # 11 c_pt_u
            1.044,  # 12 kappa
            0.23,   # 13 cbar
            3.80,   # 14 B
        ])

        nvars = len(LB)

        print('Running Particle Swarm Optimization...')
        print(f'  Swarm size: {min(140, 30)} (reduced for speed; MATLAB uses 140)')
        print(f'  Max iterations: 30')
        print(f'  Parameters: {nvars}')
        print()

        # Use a smaller swarm for practical runtime; MATLAB uses 140
        X_opt, fval_opt = particle_swarm_opt(
            lambda x: calibration_objective(x, CASE_ID),
            nvars, LB, UB,
            swarm_size=min(140, 30),
            max_iter=30,
            tol=1e-6,
            verbose=True
        )

        print()
        print(f'Calibration complete. Final loss = {fval_opt:.6f}')

        # Final evaluation at optimum to get full results
        P_calib = assign_parameter_value(X_opt, CASE_ID)
        P = {**P_exog, **P_calib}

        from scipy.stats.qmc import Halton
        halton_sampler = Halton(d=30, scramble=False)
        for _ in range(100):
            halton_sampler.random(100000)
        halton_seq = halton_sampler.random(P['N_sim'])

        ind_blocks = prepare_individual_blocks(P, halton_seq)
        eq_results = solve_equilibrium(P, ind_blocks, retry=True)

        # Compute loss for display
        from module import _compute_loss_raw
        moments_full = compute_all_moments(
            P, eq_results['occ'], eq_results['nonagr'],
            eq_results['AD_a'], eq_results['AS_a'],
            {'p': eq_results['p'], 'q': eq_results['q'], 'wa': eq_results['wa']},
            CASE_ID
        )
        loss = _compute_loss_raw(moments_full, eq_results['occ'], data_moments, P)
        print(f'Final RMSE Loss = {loss:.6f}')

    # --- Post-calibration: compute moments and display ---
    P_calib_final = assign_parameter_value(X_opt, CASE_ID)
    P = {**P_exog, **P_calib_final}

    occ = eq_results['occ']
    nonagr = eq_results['nonagr']
    p, q, wa = eq_results['p'], eq_results['q'], eq_results['wa']

    moments = compute_all_moments(
        P, occ, nonagr, eq_results['AD_a'], eq_results['AS_a'],
        {'p': p, 'q': q, 'wa': wa}, CASE_ID
    )

    # Compute loss if in quick mode
    if loss is None:
        from module import _compute_loss_raw
        loss = _compute_loss_raw(moments, occ, data_moments, P)

    # --- Display ---
    print()
    print('=' * 50)
    print('RESULTS')
    print('=' * 50)
    print()

    # Equilibrium prices
    print(f'Endogenous Prices:')
    print(f'  p  (agricultural price)     = {p:.6f}')
    print(f'  q  (land rental rate)       = {q:.6f}')
    print(f'  wa (agricultural wage)      = {wa:.6f}')
    print(f'  wu (urban nonagr wage)      = {P["Au"]:.4f}  (numeraire)')
    print(f'  wr (rural nonagr wage)      = {P["Ar"]:.6f}  (numeraire)')
    print(f'  Equilibrium residual (max)  = {eq_results["fval"]:.8f}')
    print()

    # Parameter values (Table B.5)
    display_parameter_values(P)

    print()

    # Calibration moments (Table IV)
    print('Table IV (Calibration Moments)')
    display_calibration_moments(moments, occ, data_moments, P)

    print()
    print(f'RMSE Loss (Model vs Data): {loss:.6f}')
    print()

    # Additional statistics
    print('Statistics on Rentals:')
    print(f'  Rent-in  farmers:  {np.sum(occ["dummy_farm_rentin"]) / P["N_sim"]:.4f}')
    print(f'  Rent-out farmers:  {np.sum(occ["dummy_farm_rentout"]) / P["N_sim"]:.4f}')
    print(f'  No-rental farmers: {np.sum(occ["dummy_farm_rentno"]) / P["N_sim"]:.4f}')
    print(f'  Migrating families:{np.sum(occ["hh_migration"]) / P["N_sim"]:.4f}')
    print()

    # Median abilities
    print('Median Abilities:')
    print(f'  Median TFPQ (operator): {moments.get("median_TFPQ", 0):.4f}')
    print(f'  Median u (urban):       {moments.get("median_u", 0):.4f}')
    print()

    # Within-family selection
    print(f'Fraction correct sorting: {moments.get("frac_sorting", 0):.4f}')
    print()

    t_elapsed = time.time() - t_start
    print('=' * 50)
    print(f'DONE. Elapsed time: {t_elapsed:.1f} seconds.')
    print('=' * 50)


if __name__ == '__main__':
    run_initial_equilibrium()
