function [pred, resid, err] = mdl_predict(ft, indv, depv, mdl, supp)

if startsWith(supp.mdlname, 'svd')
    pred = indv*ft;
else
    pred = mdl(ft, indv, supp);
end

resid = depv - pred;
err = mean((resid).^2); %mse, same as 2*mse(depv, pred) since mse uses half mse 

