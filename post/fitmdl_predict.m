function [depvp, gof] = fitmdl_predict(ft, indv, depv, mdl, supp)


depvp = mdl(ft, indv, supp); 
gof = mse(depv, depvp);
