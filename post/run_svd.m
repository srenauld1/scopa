function [ft, gof, preddepv] = run_svd( objfcn, indv, depv, pvar)

ft = objfcn( indv, depv, pvar);

preddepv = indv*ft;

gof = mse(depv, preddepv); 
