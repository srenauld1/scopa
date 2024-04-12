function [ft, gof1, depvp] = run_svd(fitin)

mdlfcn = fitin.opop.optimp.objective;
pvar = fitin.pvar;
indv = fitin.indv;
depv = fitin.depv;

ft = mdlfcn( indv, depv, pvar);

run_toy = 0;
if run_toy
    mdl_toy
end

depvp = indv*ft;

gof1 = mse(depv, depvp);
