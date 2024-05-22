function [posint_out, vel] = ...
    process_DAQ(ftvar, posint_in, method_resample, ...
    rslen, inds, rateim, ratedaq, ratefictrac, maxvolt, smoothwindow, ...
    slopelen, slopeorder, ball, padlensec)

% method_resample 'timestamps' should be most accurate
% method_resample 'resample' will have some onset offset transient artifacts, but minor
% note:
% smoothing posint_out before differentiation should not be necessary since it has been downsampled so much,
% and differentiate_timeseries allows variable slope window anyway
% but if you still wanted to smooth first, try passing output of smooth_timeseries to differentiate_timeseries, like this
% vel = differentiate_timeseries(iscircular, smooth_timeseries(iscircular, posint_out, smoothwindow), rateim, slopelen, slopeorder);
% noteL: after accounting for ball, y stretching will occur in plot for side and for, not yaw

doplots = 0;
xlim_prct = [0.48 0.52];

if any(strcmp(ftvar, {'ficTracIntSide', 'ficTracIntForward', 'ficTracYaw', 'g4panels'}))
    iscircular = 1;
else
    iscircular = 0;
end

if isduration(posint_in)
    posint_in = seconds(posint_in); %convert to seconds, whatever the units
end

if iscircular
    posint_in = posint_in / maxvolt*2*pi - pi; %put in range -pi to pi,  0 V assigned to -pi
end

posint_out = resample_timeseries(iscircular, posint_in, rslen, method_resample, inds, padlensec); %downsample into imaging rate
vel = differentiate_timeseries(iscircular, posint_out, rateim, slopelen, slopeorder);

if doplots %here, before scaling by ball, y values should "match"
    plot_multi_timeseries(posint_in, posint_out, xlim_prct)
    plot_multi_timeseries(posint_in, vel, xlim_prct)
end

if strcmp(ftvar, 'ficTracIntSide') || strcmp(ftvar, 'ficTracIntForward') 
    posint_out = {(posint_out * ball/2)};
    vel = {(vel * ball/2)};
else %else ignore ball, units are rad and rad/sec, otherwise they are mm and mm/sec
    posint_out = {posint_out};
    vel = {vel};
end

if doplots %here they will be stretching for side and for
    plot_multi_timeseries(posint_in, posint_out{1}, xlim_prct)
    plot_multi_timeseries(posint_in, vel{1}, xlim_prct)
end


