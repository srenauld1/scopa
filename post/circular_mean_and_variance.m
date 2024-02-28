function [mu, rho, var] = circular_mean_and_variance(ang, wt, omitnan)

%uses atan2 and hypot instead of cart2pol for transparency
%rho computed differently for signed/unsigned weights

if ~exist('omitnan', 'var')
    omitnan = 0;
end
if omitnan && any(isnan(wt(:)))
    disp("WARNING, NAN IN WT IN FUNCTION circular_mean_and_variance")
end

if any(wt(:)<0) && any(wt(:)>0)
    signed_weights = 1;
else
    signed_weights = 0;
end
weightx = wt.*cos(ang)';
weighty = wt.*sin(ang)';
if omitnan
    vecsumx = nansum(weightx);
    vecsumy = nansum(weighty);
else
    vecsumx = sum(weightx);
    vecsumy = sum(weighty);
end
vecsumtheta = atan2(vecsumy,vecsumx);
vecsumrho = hypot(vecsumx,vecsumy); %same as sqrt(abs(vecsumx).^2 + abs(vecsumy).^2), but avoids underflow/overflow
if omitnan
    vecavx = vecsumx ./ nansum( wt );
    vecavy = vecsumy ./ nansum( wt );
else
    vecavx = vecsumx ./ sum( wt );
    vecavy = vecsumy ./ sum( wt );
end
mu = atan2(vecavy,vecavx);
if omitnan
    if signed_weights
        rho = vecsumrho ./ nansum( abs(wt) ); % circular variance. this is OSI (Bonhoeffer et al. 1995 Euro. J. Neurosci.), modified for signed wtonses
    else
        rho = hypot(vecavx,vecavy); %same as sqrt(abs(vecavx).^2 + abs(vecavy).^2), but avoids underflow/overflow
    end
else
    if signed_weights
        rho = vecsumrho ./ sum( abs(wt) ); % circular variance. this is OSI (Bonhoeffer et al. 1995 Euro. J. Neurosci.), modified for signed wtonses
    else
        rho = hypot(vecavx,vecavy); %same as sqrt(abs(vecavx).^2 + abs(vecavy).^2), but avoids underflow/overflow
    end
end
var = 1 - rho;
