% This is the code that reads subroutines to calibrate various setups of
% the model by minimizing a loss function defined as the distance between
% model moments and data moments. It stores results in mat files. 
%
% NOTE: THE MAT FILES ARE ALREADY PROVIDED AND YOU DO NOT NEED TO RUN THIS
% CODE WHICH TAKES A VERY LONG TIME (DAYS) TO FINISH ON A PC.
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



calibration = 1;  
% 1---Use the particle swarm algorithm to search for parameter values.
% Takes a very long time to finish. 
% 0---Load parameter values from stored results of the particle swarm
% search. We can compare the model and data moments by choosing
% counterfactual = 0.

counterfactual = 0;
% 0---Illustrate the baseline calibrated economy, including the parameter
% values and model-data comparison on targeted moments. It also writes a
% few m-files for the counterfactual analysis.

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

fprintf('This is the code that calibrates various setups of the model. \n');
fprintf(' \n');
fprintf('NOTE: THE MAT FILES STORING PARAMETER VALUES ARE ALREADY PROVIDED. \n');
fprintf('YOU DO NOT NEED TO RUN THIS CODE. IT TAKES A LONG TIME (DAYS) ON A PC. \n');
fprintf(' \n');
fprintf('================================================== \n');
fprintf('1. BASELINE CALIBRATION \n');
fprintf('================================================== \n');

computeModelMoments
calibrationMoments
displayParameterValue


fprintf(' \n');
fprintf(' \n');
fprintf('================================================== \n');
fprintf('2. 2018 CALIBRATION \n');
fprintf('================================================== \n');

case_id     = 2;
computeModelMoments
calibrationMoments
displayParameterValue


fprintf(' \n');
fprintf(' \n');
fprintf('================================================== \n');
fprintf('3. NO ETA CALIBRATION \n');
fprintf('================================================== \n');

case_id     = 3;
computeModelMoments
calibrationMoments
displayParameterValue

fprintf(' \n');
fprintf(' \n');
fprintf('================================================== \n');
fprintf('4. 2-NONAGR SECTOR CALIBRATION \n');
fprintf('================================================== \n');

case_id     = 4;
computeModelMoments
calibrationMoments
displayParameterValue

fprintf(' \n');
fprintf(' \n');
fprintf('================================================== \n');
fprintf('5. 2-NONAGR + AGE CALIBRATION \n');
fprintf('================================================== \n');

case_id     = 5;
computeModelMoments
calibrationMoments
displayParameterValue


fprintf(' \n');
fprintf(' \n');
fprintf('================================================== \n');
fprintf('6. REMOTE CALIBRATION \n');
fprintf('================================================== \n');

case_id     = 6;
computeModelMoments
calibrationMoments
displayParameterValue


fprintf(' \n');
fprintf(' \n');
fprintf('================================================== \n');
fprintf('7. PERI-URBAN CALIBRATION \n');
fprintf('================================================== \n');

case_id     = 7;
computeModelMoments
calibrationMoments
displayParameterValue


fprintf(' \n');
fprintf(' \n');
fprintf('================================================== \n');
fprintf('8. NO XI CALIBRATION \n');
fprintf('================================================== \n');

case_id     = 8;
computeModelMoments
calibrationMoments
displayParameterValue


fprintf(' \n');
fprintf(' \n');
fprintf('================================================== \n');
fprintf('9. NO CORRELATION CALIBRATION \n');
fprintf('================================================== \n');

case_id     = 9;
computeModelMoments
calibrationMoments
displayParameterValue


fprintf(' \n');
fprintf(' \n');
fprintf('================================================== \n');
fprintf('10. HIGH CORRELATION CALIBRATION \n');
fprintf('================================================== \n');

case_id     = 10;
computeModelMoments
calibrationMoments
displayParameterValue


fprintf(' \n');
fprintf(' \n');
fprintf('================================================== \n');
fprintf('11. PIGL CALIBRATION \n');
fprintf('================================================== \n');

case_id     = 11;
computeModelMoments
calibrationMoments
displayParameterValue



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



