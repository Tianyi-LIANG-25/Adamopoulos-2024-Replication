% This function calculates the share of young and old individuals for each
% occupation.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

agr_emp_share_old    = sum(sum((dummy_ope+dummy_agr ).*dummy_old))/sum(sum(dummy_old));
ope_share_old        = sum(sum((dummy_ope           ).*dummy_old))/sum(sum(dummy_old));
agr_worker_share_old = sum(sum((dummy_agr           ).*dummy_old))/sum(sum(dummy_old));

agr_emp_share_young    = sum(sum((dummy_ope+dummy_agr ).*(1-dummy_old)))/sum(sum((1-dummy_old)));
ope_share_young        = sum(sum((dummy_ope           ).*(1-dummy_old)))/sum(sum((1-dummy_old)));
agr_worker_share_young = sum(sum((dummy_agr           ).*(1-dummy_old)))/sum(sum((1-dummy_old)));

fprintf('-------------------------------------------------- \n');
fprintf('Employment Share Among Old: \n');
fprintf('  Agr:                          %5.3f  \n', agr_emp_share_old);
fprintf('    Operator:                   %5.3f  \n', ope_share_old);
fprintf('    Agr Worker:                 %5.3f  \n', agr_worker_share_old);
fprintf('Employment Share Among Young: \n');
fprintf('  Agr:                          %5.3f  \n', agr_emp_share_young);
fprintf('  Rural Non-Agr:                %5.3f  \n', ope_share_young);
fprintf('  Urban Non-Agr:                %5.3f  \n', agr_worker_share_young);
fprintf('Young-Old Gap: \n');
fprintf('                                %5.3f  \n', agr_emp_share_old-agr_emp_share_young);
fprintf('-------------------------------------------------- \n');