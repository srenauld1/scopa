function [posint_out, vel] = process_DAQ_signal(ftvar, posint_in, ...
    rslen, inds, dt, maxvolt, slopelen_sec, slopeorder, ball_diameter, padlensec)

% default resampling with daq frame timestamps, which accounts for flyback, and slice time offsets
% if these are not on daq, backup uses matlab 'resample', which will have some onset offset transient artifacts, but minor, and will not account for flyback

% note:
% smoothing posint_out before differentiation should not be necessary since it has been downsampled so much,
% and differentiate_timeseries allows variable slope window anyway
% but if you still wanted to smooth first, try passing output of smooth_timeseries to differentiate_timeseries, like this
% vel = differentiate_timeseries(datatype, smooth_timeseries(datatype, posint_out, smoothwindow), slopelen_sec, slopeorder, dt);
% noteL: after accounting for ball, y stretching will occur in plot for side and for, not yaw

doplots = 0;
xlim_prct = [0.48 0.52];

if any(strcmp(ftvar, {'ficTracIntSide', 'ficTracIntForward', 'ficTracYaw', 'g4panels'}))
    datatype = 'circular';
else
    if all(mod(posint_in, 1)==0) % needs to change since integer variables might not always be intended categorical
        error("need better categorical datatype criterion")
        datatype = 'categorical';
    else
        datatype = 'standard';
    end
end

if isduration(posint_in)
    posint_in = seconds(posint_in); %convert to seconds, whatever the units
end

if strcmp(datatype, 'circular')
    posint_in = posint_in / maxvolt*2*pi - pi; %put in range -pi to pi,  0 V assigned to -pi
end

posint_out = resample_timeseries(datatype, posint_in, inds, rslen, padlensec); %downsample into imaging rate
vel = differentiate_timeseries(datatype, posint_out, slopelen_sec, slopeorder, dt);

if strcmp(ftvar, 'ficTracIntSide') || strcmp(ftvar, 'ficTracIntForward')
    posint_out = {(posint_out * ball_diameter/2)};
    vel = {(vel * ball_diameter/2)};
else %else ignore ball, units are rad and rad/sec, otherwise they are mm and mm/sec
    posint_out = {posint_out};
    vel = {vel};
end

if doplots %here they will be stretching for side and for
    plot_multi_timeseries(posint_in, posint_out{1} / ball_diameter/2, xlim_prct)
    plot_multi_timeseries(posint_in, vel{1} / ball_diameter/2, xlim_prct)
    plot_multi_timeseries(posint_in, posint_out{1}, xlim_prct)
    plot_multi_timeseries(posint_in, vel{1}, xlim_prct)
end


