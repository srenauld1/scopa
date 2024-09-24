function [depvp, err] = fitmdl_predict(ft, indv, depv, mdl, supp)

depvp = mdl(ft, indv, supp); 
err = mse(depv, depvp);
