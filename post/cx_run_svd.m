function [ft, gof, predresp, hdata, sdata, vdata, pstim] = ...
    cx_run_svd( objfcn, stim, resp, pvar, gethue, getsat, getval)

ft = objfcn( stim, resp, pvar);

predresp = stim*ft;

mserr = mse(resp, predresp); 

gof = mserr; 

hdata = gethue(ft, stim, predresp);
sdata = getsat(gof);
vdata = getval(resp);

pstim = stim(find(max(predresp)==predresp,1));