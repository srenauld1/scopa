function [mu, rho] = stim_response_tuning(stim, resp, is_circular)

if is_circular

    weightx = resp.*cos(stim )';
    weighty = resp.*sin(stim )';
    vecsumx = nansum(weightx);
    vecsumy = nansum(weighty);
    [vecsumtheta, vecsumrho] = cart2pol( vecsumx, vecsumy );
    vecavx = vecsumx ./ nansum( resp );
    vecavy = vecsumy ./ nansum( resp );
    [mu, rho2] = cart2pol( vecavx, vecavy );
    rho = vecsumrho ./ nansum( abs(resp) ); % circular variance. this is OSI (Bonhoeffer et al. 1995 Euro. J. Neurosci.), modified for signed responses

else

end