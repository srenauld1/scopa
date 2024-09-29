function [depvp, err] = mfit_predict(ft, indv, depv, mdl, supp)

depvp = mdl(ft, indv, supp); 
err = mse(depv, depvp);
