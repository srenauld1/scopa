function [mu, rho, var] = circmnvar(ang, wt, omitnan)

%{
circular mean and variance for signed responses 
circmnvar is modified to combine circ_mean and circ_var, 
and deal with signed responses (weights magnitude, not just order), 
also can ignore nans 
so if responses includes negatives and positives, circmnvar will not give the same output as circ_mean and circ_var
uses atan2 and hypot instead of cart2pol for transparency

compare with:             
    mu = circ_mean(repmat(domain', [1 size(resptmp, 2)]), resptmp);
    [rho, ~, sel] = circ_var(repmat(domain', [1 size(resptmp, 2)]), resptmp);

can also compare with alternative FEX functions below . . . I'm not sure if these  
    for rti = 1:size(resptmp, 2)
        mu_true(:, rti) = deg2rad(weighted_circular_mean(rad2deg(domain), resptmp(:,rti))); % "true circular mean", so far results are not very different
        rho_true(:, rti) = weighted_circular_std(rad2deg(domain), resptmp(:,rti)); % std based on "true circular mean",
    end

%}

if ~exist('omitnan', 'var')
    omitnan = 0;
end
if omitnan && any(isnan(wt(:)))
    disp("WARNING, NAN IN WT IN FUNCTION circmnvar")
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
