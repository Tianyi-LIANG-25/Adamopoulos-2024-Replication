% This is the main code that reads subroutines to solve for the equilibrium
% and report model moments.
%
% Used in the paper "Land Insecurity and Mobility Frictions," by Tasso
% Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, and Xiaoyun
% Wei, prepared for publication at the Quarterly Journal of Economics.
%
% Last modified: March 3, 2024

clear
clc
tic

addpath('subroutine');
addpath('matfiles');




calibration = 0;  
% 1---Use the particle swarm algorithm to search for parameter values.
% Takes a very long time to finish. 
% 0---Load parameter values from stored results of the particle swarm
% search. We can compare the model and data moments by choosing
% counterfactual = 0.

case_id     = 1;
%  1---baseline calibration
%  2---2018 calibration
%  3---no eta calibration
%  4---2 non-agr sectors
%  5---2 non-agr sectors and age differences
%  6---remote
%  7---peri-urban
%  8---no xi calibration
%  9---no correlation between abilities
% 10---high correlation calibration between abilities
% 11---PIGL preferences

counterfactual = 0;
% 0---Illustrate the baseline calibrated economy, including the parameter
% values and model-data comparison on targeted moments. It also writes a
% few m-files for the counterfactual analysis.
% 1---Land security counterfactual
% 2---No labor mobility friction counterfactual
% 3---No static misallocation
% 4---Land security + no static misallocation
% 5---2018 land security
% 6---2018 labor mobility barriers
% 7---Land security + no labor mobility barriers

% Read the subroutine to compute model moments
computeModelMoments



fprintf('================================================== \n');
fprintf('SECTION V: CALIBRATION \n');
fprintf('================================================== \n');
fprintf('  \n');
fprintf('Table IV (Calibration Moments) \n');
calibrationMoments
fprintf('  \n');
fprintf('Appendix Table B.5 (Model Parameter Values) \n');
displayParameterValue
fprintf('  \n');
fprintf('Statistics on Rentals \n');
rentalMoments
fprintf('  \n');
fprintf('Baseline Vs. No Eta Economy \n');
fprintf('    Baseline Labor Mob Barrier: %+5.3f  \n', mean(mean(ind_xiu)));
fprintf('    Baseline Family with Ope:   %+5.3f  \n', PCT_family_operator);
case_id = 3; 
computeModelMoments
fprintf('    No ETA   Labor Mob Barrier: %+5.3f  \n', mean(mean(ind_xiu)));
fprintf('    No ETA   Family with Ope:   %+5.3f  \n', PCT_family_operator);
fprintf('  \n');
fprintf('  \n');

fprintf('================================================== \n');
fprintf('SECTION VI: QUANTITATIVE ANALYSIS \n');
fprintf('================================================== \n');
fprintf('  \n');
fprintf('================================================== \n');
fprintf('SECTION VI.A \n');
fprintf('  \n');
fprintf('Table V (Col I) Table VI (Col I) Table VII (Col I) \n');
case_id = 1; counterfactual = 0;
computeModelMoments
expTable
fprintf('Table V (Col II) & Table VII (Col II) \n');
case_id = 1; counterfactual = 1;
computeModelMoments
expTable
fprintf('Table V (Column III) \n');
case_id = 1; counterfactual = 2;
computeModelMoments
expTable
fprintf('  \n');
fprintf('  \n');
fprintf('================================================== \n');
fprintf('SECTION VI.B \n');
fprintf('  \n');
fprintf('Calibration Moments for 2018 \n');
case_id = 2; counterfactual = 0;
computeModelMoments
calibrationMoments
fprintf('  \n');
fprintf('Appendix Table C.7 (Parameter Values for 2018) \n');
displayParameterValue
fprintf('  \n');
fprintf('Ave Inc Loss from Land  \n');
fprintf('  2018:         %+5.3f  \n', exp(mean(log(hh_b./hh_inc_total))));
case_id = 1; counterfactual = 0;
computeModelMoments
fprintf('  2004:         %+5.3f  \n', exp(mean(log(hh_b./hh_inc_total))));
case_id = 1; counterfactual = 5;
computeModelMoments
fprintf('  Exp VI.2:     %+5.3f  \n', exp(mean(log(hh_b./hh_inc_total))));
fprintf('  \n');
fprintf('Table VI (Column II) \n');
expTable
fprintf('Table VI (Column III) \n');
case_id = 1; counterfactual = 6;
computeModelMoments
expTable
fprintf('  \n');
fprintf('  \n');
fprintf('================================================== \n');
fprintf('SECTION VI.C \n');
fprintf('  \n');
fprintf('Table VII (Column III) \n');
case_id = 1; counterfactual = 3;
computeModelMoments
expTable
fprintf('  \n');
fprintf('Table VII (Column IV) \n');
case_id = 1; counterfactual = 4;
computeModelMoments
expTable
fprintf('  \n');
fprintf('  \n');

fprintf('================================================== \n');
fprintf('SECTION VII: EXTENSIONS \n');
fprintf('================================================== \n');
fprintf('  \n');
fprintf('================================================== \n');
fprintf('SECTION VII.A \n');
fprintf('  \n');
fprintf('Calibration Moments for 2-Nonagr Extension \n');
case_id = 4; counterfactual = 0;
computeModelMoments
calibrationMoments
fprintf('  \n');
fprintf('Appendix Table C.8 Column 1 (Parameter Values) \n');
displayParameterValue
fprintf('  \n');
fprintf('Table IX.A Column 1 \n');
expTable
fprintf('  \n');
fprintf('Table IX.A Column 2 \n');
case_id = 4; counterfactual = 1;
computeModelMoments
expTable
fprintf('  \n');
fprintf('Table IX.A Column 3 \n');
case_id = 4; counterfactual = 2;
computeModelMoments
expTable
fprintf('  \n');
fprintf('  \n');
fprintf('================================================== \n');
fprintf('SECTION VII.B \n');
fprintf('  \n');
fprintf('Calibration Moments for 2-Nonagr + Age Extension \n');
case_id = 5; counterfactual = 0;
computeModelMoments
calibrationMoments
fprintf('  \n');
fprintf('Appendix Table C.8 Column 2 (Parameter Values) \n');
displayParameterValue
fprintf('  \n');
fprintf('Table IX.B Column I \n');
expTable
fprintf('  \n');
fprintf('Table X Column I \n');
youngOldShare
fprintf('  \n');
fprintf('Table IX.B Column II \n');
case_id = 5; counterfactual = 1;
computeModelMoments
expTable
fprintf('  \n');
fprintf('Table X Column II \n');
youngOldShare
fprintf('  \n');
fprintf('Table IX.B Column III \n');
case_id = 5; counterfactual = 2;
computeModelMoments
expTable
fprintf('  \n');
fprintf('Table X Column III \n');
youngOldShare
fprintf('  \n');
fprintf('Table X Column IV \n');
case_id = 5; counterfactual = 7;
computeModelMoments
youngOldShare
fprintf('  \n');
fprintf('  \n');
fprintf('================================================== \n');
fprintf('SECTION VII.C \n');
fprintf('  \n');
fprintf('Calibration Moments for Peri-Urban \n');
case_id = 7; counterfactual = 0;
computeModelMoments
calibrationMoments
fprintf('  \n');
fprintf('Appendix Table C.8 Column 3 (Parameter Values) \n');
displayParameterValue
fprintf('  \n');
fprintf('Table XI.A Column 1 \n');
expTable
fprintf('  \n');
fprintf('Table XI.A Column 2 \n');
case_id = 7; counterfactual = 1;
computeModelMoments
expTable
fprintf('  \n');
fprintf('Table XI.A Column 3 \n');
case_id = 7; counterfactual = 2;
computeModelMoments
expTable
fprintf('  \n');
fprintf('Calibration Moments for Remote \n');
case_id = 6; counterfactual = 0;
computeModelMoments
calibrationMoments
fprintf('  \n');
fprintf('Appendix Table C.8 Column 4 (Parameter Values) \n');
displayParameterValue
fprintf('  \n');
fprintf('Table XI.B Column 1 \n');
expTable
fprintf('  \n');
fprintf('Table XI.B Column 2 \n');
case_id = 6; counterfactual = 1;
computeModelMoments
expTable
fprintf('  \n');
fprintf('Table XI.B Column 3 \n');
case_id = 6; counterfactual = 2;
computeModelMoments
expTable
fprintf('  \n');
fprintf('  \n');

fprintf('================================================== \n');
fprintf('APPENDIX B: SENSITIVITY B.6 \n');
fprintf('================================================== \n');
fprintf('  \n');

AppendixB

fprintf('  \n');
fprintf('  \n');
fprintf('================================================== \n');
fprintf('APPENDIX D: WITHIN FAMILY SELECTION \n');
fprintf('================================================== \n');
fprintf('  \n');

AppendixD


fprintf('  \n');
fprintf('  \n');
fprintf('================================================== \n');
fprintf('APPENDIX F: SECTORAL CORRELATION OF ABILITIES \n');
fprintf('================================================== \n');
fprintf('  \n');
fprintf('================================================== \n');
fprintf('No correlation \n');
case_id = 9; counterfactual = 0;
computeModelMoments
calibrationMoments
fprintf('  \n');
fprintf('Parameter Values \n');
displayParameterValue
fprintf('  \n');
fprintf('Table F.9 Row 4 \n');
expTable
fprintf('  \n');
fprintf('Table F.9 Row 5 \n');
case_id = 9; counterfactual = 1;
computeModelMoments
expTable
fprintf('  \n');
fprintf('Table F.9 Row 6 \n');
case_id = 9; counterfactual = 2;
computeModelMoments
expTable
fprintf('  \n');
fprintf('================================================== \n');
fprintf('High correlation \n');
case_id = 10; counterfactual = 0;
computeModelMoments
calibrationMoments
fprintf('  \n');
fprintf('Parameter Values \n');
displayParameterValue
fprintf('  \n');
fprintf('Table F.9 Row 7 \n');
expTable
fprintf('  \n');
fprintf('Table F.9 Row 8 \n');
case_id = 10; counterfactual = 1;
computeModelMoments
expTable
fprintf('  \n');
fprintf('Table F.9 Row 9 \n');
case_id = 10; counterfactual = 2;
computeModelMoments
expTable

fprintf('  \n');
fprintf('  \n');

fprintf('================================================== \n');
fprintf('APPENDIX G: PIGL PREFERENCES \n');
fprintf('================================================== \n');
fprintf('  \n');

case_id = 11; counterfactual = 0;
computeModelMoments
calibrationMoments
fprintf('  \n');
fprintf('Parameter Values \n');
displayParameterValue
fprintf('  \n');
fprintf('Table G.10 Column 1 \n');
expTable
fprintf('  \n');
fprintf('Table G.10 Column 2 \n');
case_id = 11; counterfactual = 1;
computeModelMoments
expTable
fprintf('  \n');
fprintf('Table G.10 Column 3 \n');
case_id = 11; counterfactual = 2;
computeModelMoments
expTable


fprintf('  \n');
fprintf('  \n');

fprintf('================================================== \n');
fprintf('APPENDIX H: INTENSIVE VS EXTENSIVE MARGIN \n');
fprintf('================================================== \n');
fprintf('  \n');

case_id = 11; counterfactual = 0;
AppendixH



fprintf('  \n');
fprintf('  \n');

fprintf('================================================== \n');
fprintf('DONE. \n');
fprintf('THANK YOU FOR READING OUR WORK. \n');
fprintf('  \n');
fprintf('"LAND SECURITY AND MOBILITY FRICTIONS,"  \n');
fprintf('PREPARED FOR THE QUARTERLY JOURNAL OF ECONOMICS, \n');
fprintf('    TASSO ADAMOPOULOS,  \n');
fprintf('    LOREN BRANDT,  \n');
fprintf('    CHAORAN CHEN,  \n');
fprintf('    DIEGO RESTUCCIA,  \n');
fprintf('    XIAOYUN WEI.  \n');
fprintf('      \n');
fprintf('MARCH 3RD, 2024  \n');
fprintf('================================================== \n');
toc

