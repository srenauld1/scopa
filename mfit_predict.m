function [pred, err] = mfit_predict(ft, indv, depv, mdl, supp)

pred = mdl(ft, indv, supp); 
err = mse(depv, pred);
