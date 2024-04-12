function [ft, gof, depvp] = run_ohe( mdl, indv, depv)

error("this function is deprecated")

% in setup_model, this mdl was defined: mdl = @(y,x,z) y'*x / z;

scalefac = size(depv, 1)/10; %don't understand why this needs to be around 1/10th the average to be in the right range for prediction 

ft = mdl( depv, indv, scalefac);

depvp = indv*ft.';

gof = mse(depv, depvp); 
