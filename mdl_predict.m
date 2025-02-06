function [pred, err] = mdl_predict(ft, indv, depv, mdl, supp)

pred = mdl(ft, indv, supp); 
err = mse(depv, pred);
