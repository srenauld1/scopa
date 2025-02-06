
% default is to use globalsearch with solver fmincon
% multistart and globalsearch are from global optim toolbox
% multistart can run parallel, can accept user input start points, and will test all start points, and can use different solvers, globalsearch cannot run parallel and will skip "bad" startpoints and can only use fmincon
% fmincon and lsqcurvefit are from optimization toolbox
% lsqcurvefit uses the same algorithm as lsqnonlin (also in optimization toolbox) - lsqcurvefit simply provides a convenient interface for data-fitting problems
% for lsqcurvefit, custom function should return fun(x,xdata), and not the sum-of-squares sum((fun(x,xdata)-ydata).^2). lsqcurvefit implicitly computes the sum of squares of the components of fun(x,xdata)-ydata.
% fmincon could be used instead of lsqcurvefit, but i haven't found a reason to prefer it yet (perhaps if we aren't doing regression),
% if using fmincon for least squares regression, custom function should explicitly return the sum-of-squares sum((fun(x,xdata)-ydata).^2)
% for choosing lsqcurvefit algorithm, docs say
% --For problems with bound constraints only, try 'trust-region-reflective' or 'levenberg-marquardt' first.
% --If your bound-constrained problem is underdetermined (fewer equations than dimensions), try 'levenberg-marquardt' first.
% --If your problem has linear or nonlinear constraints, use 'interior-point'.
% fmincon and lsqcurvefit will both use interior-point algorithm if using constraints
% some online resources say fmincon take constraints and lsqcurvefit doesn't, but that is not true (perhaps it used to be)

% fitnlm and nlfit are from SML toolbox, have lots of useful options and outputs
% fitnlm is shell around and nlinfit, but neither can take constraints
% so fitnlm may be useful as alternative approach when there are no constraints
% fitnlm finds least squares, and can use the same objective function as lsqcurvefit, just cannot take constraints or bounds as arguments
% for nlinfit and fitnlm:
% --nlinfit treats NaN values in Y or modelfun(beta0,X) as missing data, and ignores the corresponding observations,
% --For nonrobust estimation, nlinfit uses the Levenberg-Marquardt nonlinear least squares algorithm
% --For robust estimation, nlinfit uses the algorithm of Iteratively Reweighted Least Squares. At each iteration, the robust weights are recalculated based on each observation-s residual from the previous iteration. These weights downweight outliers, so that their influence on the fit is decreased. Iterations continue until the weights converge.
% --When you specify a function handle for observation weights, the weights depend on the fitted model. In this case, nlinfit uses an iterative generalized least squares algorithm to fit the nonlinear regression model.

% fit is from curve fitting toolbox, is very general, has useful output stats, but can only take 2d independent variables, and cannot take constraints

% using above to fit linear models can be very inefficient, but should still find the best solution
% For reduced computation time on high-dimensional data sets, fit a linear regression model using the fitrlinear function.
% for linear regression, can use fitlm
% alternatives to fitlm include
% --To regularize a regression, use fitrlinear, lasso, ridge, or plsregress.
% --fitrlinear regularizes a regression for high-dimensional data sets using lasso or ridge regression.
% --lasso removes redundant predictors in linear regression using lasso or elastic net.
% --ridge regularizes a regression with correlated terms using ridge regression.
% --plsregress regularizes a regression with correlated terms using partial least squares.

%it's not clear to me yet how to include categorical predictors, which i do have need for

% slmengine is a completely different approach from file exchange, not appropriate for large scale automated fitting, but useful for single-case exploration

% there are other options still, but above seems to me to be the most general, small set of functions for our purposes
