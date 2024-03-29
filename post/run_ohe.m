function [ft, gof, preddepv] = run_ohe( objfcn, indv, depv)

error("this function is deprecated")

% in setup_model_all, this objfcn was defined: objfcn = @(y,x,z) y'*x / z;

scalefac = size(depv, 1)/10; %don't understand why this needs to be around 1/10th the average to be in the right range for prediction 

ft = objfcn( depv, indv, scalefac);

preddepv = indv*ft.';

gof = mse(depv, preddepv); 
