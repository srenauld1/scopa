function [ft, gof, depvp] = run_ohe( mdlfcn, indv, depv)

error("this function is deprecated")

% in setup_model, this mdlfcn was defined: mdlfcn = @(y,x,z) y'*x / z;

scalefac = size(depv, 1)/10; %don't understand why this needs to be around 1/10th the average to be in the right range for prediction 

ft = mdlfcn( depv, indv, scalefac);

depvp = indv*ft.';

gof = mse(depv, depvp); 
