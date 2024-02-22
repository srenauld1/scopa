function [mu, rho] = circular_mean_var(stim, resp)

%uses atan2 and hypot instead of cart2pol for transparency
weightx = resp.*cos(stim )';
weighty = resp.*sin(stim )';
vecsumx = nansum(weightx);
vecsumy = nansum(weighty);
vecsumtheta = atan2(vecsumy,vecsumx);
vecsumrho = hypot(vecsumx,vecsumy); %same as sqrt(abs(vecsumx).^2 + abs(vecsumy).^2), but avoids underflow/overflow
vecavx = vecsumx ./ nansum( resp );
vecavy = vecsumy ./ nansum( resp );
mu = atan2(vecavy,vecavx);
rho = hypot(vecavx,vecavy); %same as sqrt(abs(vecavx).^2 + abs(vecavy).^2), but avoids underflow/overflow
rho = vecsumrho ./ nansum( abs(resp) ); % circular variance. this is OSI (Bonhoeffer et al. 1995 Euro. J. Neurosci.), modified for signed responses

