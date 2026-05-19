fprintf('-------------------------------------------------- \n');
fprintf('Additional Moments: \n');
fprintf('  Family with Operators:          %+5.3f  \n', PCT_family_operator);
fprintf('  Agr Emp Share (Villagers):      %+5.3f  \n', agr_emp_share_cond);
fprintf('  D. Agr Output:                  %+5.3f  \n', (AD_a+AS_a)/2/baseline_agr_output-1);
fprintf('  D. Agr Labor Productivity:      %+5.3f  \n', (AD_a+AS_a)/2/agr_emp_share_cond/baseline_agr_LP-1);
fprintf('  D. Median Agr Ability:          %+5.3f  \n', median_TFPQ-baseline_median_TFPQ);
fprintf('  D. Nonagr Output:               %+5.3f  \n', (AD_n+AS_n)/2/baseline_nonagr_output-1);
fprintf('  D. Real GDP Per Capita:         %+5.3f  \n', ...
    sqrt(((AD_a+AS_a)/2*baseline_p+(AD_n+AS_n)/2)/baseline_GDP_las*...
    ((AD_a+AS_a)/2*p+(AD_n+AS_n)/2)/(baseline_agr_output*p+baseline_nonagr_output))-1);
fprintf('  PCT Operators Most Productive:  %+5.3f  \n', frac_sorting);
fprintf('  Nominal APG:                    %+5.3f  \n', agr_emp_share/agr_VA_share);
fprintf('-------------------------------------------------- \n');