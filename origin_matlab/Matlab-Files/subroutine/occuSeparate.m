%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Untitled Land, Occupational Choice, and Agricultural Productivity
% American Economic Journal: Macroeconomics
% By Chaoran Chen
% This code is used to generate a vector of simulations that includes 
% farmers or workers only.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [ CC ] = occuSeparate( occupation,X,dummy )
CC=0;
N=length(occupation);
N=N(1);
j=0;
for i=1:N 
    if occupation(i)==dummy
        j=j+1;
        CC(j)=X(i);
    end
end
CC=CC';

end

