% This subroutine calculates moments on land rentals.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

rentin_hh_frac  = sum(dummy_farm_rentin .*(1-hh_migration))/sum(1-hh_migration);

rentout_hh_frac = sum(dummy_farm_rentout.*(1-hh_migration))/sum(1-hh_migration);

rentno_hh_frac  = sum(dummy_farm_rentno .*(1-hh_migration))/sum(1-hh_migration);

corr_TFPQ_rental_int_1 = corr(occuSeparate((1-hh_migration).*dummy_farm_rentin,log(farm_s),1),...
    occuSeparate((1-hh_migration).*dummy_farm_rentin,log(farm_rentin),1));

corr_TFPQ_rental_int_2 = corr(occuSeparate((1-hh_migration).*dummy_farm_rentin,farm_s,1),...
    occuSeparate((1-hh_migration).*dummy_farm_rentin,farm_rentin,1),'type','spearman');


corr_TFPQ_rental_ext   = corr(occuSeparate((1-hh_migration),farm_s,1),...
    occuSeparate((1-hh_migration),dummy_farm_rentin,1),'type','spearman');

corr_TFPQ_rental_both  = corr(occuSeparate((1-hh_migration),farm_s,1),...
    occuSeparate((1-hh_migration),farm_rentin,1),'type','spearman');

rentin_size_rel        = mean(occuSeparate((1-hh_migration).*dummy_farm_rentin,farm_rentin,1))/...
    mean(occuSeparate(1-hh_migration,farm_l,1));


fprintf('-------------------------------------------------- \n');
fprintf('                                Data   Model \n');
fprintf('Rental Moments: \n');
fprintf('  Inactive farms:              %+5.3f  %+5.3f  \n', 0.7847, rentno_hh_frac);
fprintf('  Rank corr TFPQ VS Rent In:   %+5.3f  %+5.3f  \n', 0.0616, corr_TFPQ_rental_ext);
fprintf('  Ave Rent In Size (as AFS):   %+5.3f  %+5.3f  \n', 0.8904, rentin_size_rel);
fprintf('-------------------------------------------------- \n');
