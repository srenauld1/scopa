notes on optimization


%%

% svd for linear model (subtract centroid, then add it back)
% 
% f for linear model, amp and bias 
% s /d for int / diff , positive, fixed amp 1
% 
% e / i for sigmoid, fixed amp
% 
% s e f integrate, nonlinearity, amplitude/bias (normalize input data first)
%   normalize input
%   s/d: positive integrator/differentiator; maintains input scale and polarity (2 param)
%   e/i/l: nonlinearity; gives polarity; maintains input scale (3 param)
%   f: amp and bias, no L1 constraint (2 param)
 


%% 

https://www.mathworks.com/help/gads/improving-optimization-by-choosing-another-solver.html

ga and surrogateopt are the only Global Optimization Toolbox solvers that accept integer constraints.
Try surrogateopt for problems that have time-consuming objective functions. 
surrogateopt searches for a global solution. surrogateopt requires finite bounds, and accepts integer constraints, linear constraints, and nonlinear inequality constraints.
ga has little supporting theory and is often less efficient than patternsearch or particleswarm. 
ga handles all types of constraints. 
ga and surrogateopt are the only Global Optimization Toolbox solvers that accept integer constraints.


%% 

https://www.mathworks.com/discovery/integer-programming.html#:~:text=Integer%20constraints%20restrict%20some%20or,yes%2Dor%2Dno%20decisions.


%% 

https://www.mathworks.com/matlabcentral/answers/127754-misunderstanding-about-the-number-of-trial-points-in-globalsearch

 It sounds to me as if your objective function is time-consuming to evaluate. 
 If so, then you can probably get better control over the amount of time the 
 solver takes by using MultiStart. You see, GlobalSearch evalueates the objective 
function quite a large number of times without calling fmincon. In contrast, 
MultiStart calls fmincon repeatedly. So perhaps, in your case, you would get a good 
solution in less time, and in a more controlled amount of time, by using MultiStart, 
and having all computations be directed at finding a minimum, rather than at determining 
whether or not it is worthwhile to run fmincon.

