function [CI,p] = polyparci(PolyPrms,PolyS,varargin)
% POLYPARCI takes PolyPrms, the 1xN vector of parameter estimates from polyfit,
%   PolyS, the structure returned by polyfit, and alpha, and returns the
%   �alpha� confidence intervals for the parameters in CI.  The default
%   for alpha is 0.95.  
% 
%   RETURNS: CI (2xN matrix of confidence intervals whose columns match the 
%               1xN vector of coefficients returned by polyfit)
%            p  (1xN vector of probabilities that the corresponding 
%               parameter is different from zero)
% 
% CALLING POLYPARCI: 
% [p,S,mu] = polyfit(x,y,n);                % Fit the data (POLYPARCI does 
%                                             not use 'mu')
% [ci,p] = polyparci(p,S,alpha,tails);      % NOTE: specifying a value for 
%                                             alpha is optional, enter []
%                                             in the third postion to use
%                                             the default value if also
%                                             specifying a value for 'tails'
% 
% Star Strider � 2012 07 05;    
% Update         2014 02 10 (Compatible with 2013b changes. Corrected typo. 
%                   Inverted �CI� matrix to 2xN be compatible with 1xN row 
%                       vector of coefficients �polyfit� produces.)
% Update         2023 12 31 (Major Upgrade)
%                   Additional (integer) argument 'tails' (default 2) 
%                       selects 1 or 2-tailed t-test, must be either '1' 
%                       or '2'
%                   Allows for default argument option with [] for 'alpha',
%                       'tails', or both, first two arguments are required,
%                       the rest are optional and can be omitted
%                   Second output is the probability that a given parameter
%                       is different from zero (respects the 'tails'
%                       argument, so is 2-tailed if 'tails' is 2)
% 
% % % % % T-DISTRIBUTIONS � 
% Variables: 
% t: t-Statistic
% v: Degrees Of Freedom
tdist2T = @(t,v) 1-0.5*betainc(v./(v+t.^2),v/2,0.5);                                    % 2-Tailed t-Distribution (CDF)
tdist1T = @(t,v) 1-(1-tdist2T(t,v))/2;                                                  % 1-Tailed t-Distribution (CDF)
optargs = cell(1,2);
optargs(1:numel(varargin)) = varargin;
% Check for a specified value of alpha: 
if isempty(optargs{1})
    alpha = 0.95;
else
    alpha = optargs{1};
end
if isempty(optargs{2})
    tails = 2;
else
    tails = optargs{2};
end
if ~any(ismember([1 2],tails))
    error(sprintf('tails = %.0f, must be either 1 or 2',tails))
end
% Check for out-of-range values for alpha and substitute if necessary: 
if alpha < 1.0E-010
    alpha = 1.0E-010;
elseif alpha > (1 - 1.0E-010)
    alpha = 1 - 1.0E-010;
end
% Check = [alpha; tails]
% Calculate the covariance matrix of the parameters (COVB) and the standard
%   errors (SE) from the �S� structure.  (See the �polyfit� documentation.)   
COVB = (PolyS.R'*PolyS.R)\eye(size(PolyS.R)) * PolyS.normr^2/PolyS.df;
SE = sqrt(diag(COVB));                                                                  % Standard Errors
[PrmSizR,PrmSizC] = size(PolyPrms);                                                     % Convert Parameter Vector To Column If Necessary
if PrmSizR < PrmSizC
    PolyPrms = PolyPrms';
end
T1 = @(alpha,v) fzero(@(tval) (min(alpha,(1-alpha)) - (1 - tdist1T(tval,v))*2), 1);     % t-Statistic Given Probability 1alpha  & Degrees-Of-Freedom [v,
T2 = @(alpha,v) fzero(@(tval) (min(alpha,(1-alpha)) - (1 - tdist2T(tval,v))*2), 1);     % t-Statistic Given Probability 1alpha  & Degrees-Of-Freedom 2v2
pT = PolyPrms ./ SE;                                                                    % Parameter t-Statistic For Probability Calculations
if tails == 1
    [T,fv] = T1(alpha,PolyS.df);                                                        % Calculate One-Tailed t-Values
    p = (1 - tdist1T(abs(pT),PolyS.df)).'*2;                                            % Calculate One-Tailed Probabilities
elseif tails == 2
    [T,fv] = T2(alpha,PolyS.df);                                                        % Calculate Two-Tailed t-Values
    p = (1 - tdist2T(abs(pT),PolyS.df)).'*2;                                            % Calculate Two-Tailed Probabilities
else
    T = NaN;
    fv = NaN;
end
T = abs(T);                                                                             % Critical +ve Value From T-Distribution
ts = T * [-1  1];                                                                       % Create Vector Of � t-Statistic Values
CI  = bsxfun(@plus,bsxfun(@times,SE,ts),PolyPrms)';                                     % Confidence Intervals Matrix (2xN)
end
% =========================  END: polyparci.m  =========================