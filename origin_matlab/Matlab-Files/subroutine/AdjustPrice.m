%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Untitled Land, Occupational Choice, and Agricultural Productivity
% American Economic Journal: Macroeconomics
% By Chaoran Chen
% This code is used to adjust prices in computing the general equilibrium:
% if the aggregate demand is greater than the aggregate supply, then we
% adjust the price level upwards; otherwise adjust it downwards.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



function [ p,ph,pl ] = Adjust_Price( distance,p,ph,pl,tol )

if abs(distance)>tol
    if distance>0
        pl=p;
        p=0.5*p+0.5*ph;
    else
        ph=p;
        p=0.5*p+0.5*pl;
    end
end

end

