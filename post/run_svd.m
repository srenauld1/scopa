function [ft, gof, preddepv, hdata, sdata, vdata, indvpref] = ...
    run_svd( objfcn, indv, depv, pvar, gethue, getsat, getval)

ft = objfcn( indv, depv, pvar);

preddepv = indv*ft;

mserr = mse(depv, preddepv); 

gof = mserr; 

hdata = gethue(ft, indv, preddepv);
sdata = getsat(gof);
vdata = getval(depv);

indvpref = indv(find(max(preddepv)==preddepv,1));