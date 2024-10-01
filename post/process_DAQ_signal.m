function [daqvarout, daqvarout_diff] = process_DAQ_signal(daqvartype, daqvarname, daqvarin, ...
    newlength, inds, dt, voltmin, voltmax, slopelensec, slopeord, pthfigpre, doplots)

% default resampling uses daq frame timestamps ('inds')
% if they're not on daq, backup uses matlab 'resample', matching goal length ('newlength')
% option to plot multiple zoomed in views of timeseries before and after resampling

% note:
% smoothing daqvarout before differentiation should not be necessary because it's been downsampled so much,
% and differentiate_timeseries allows variable slope window anyway (increase to reduce output noise)
% but if you still want to smooth first, try passing output of smooth_timeseries to differentiate_timeseries, like this:
% differentiate_timeseries(daqvartype, smooth_timeseries(daqvartype, daqvarin, smoothwindow_sec, dt), slopelensec, slopeord, dt);

if isduration(daqvarin)
    daqvarin = seconds(daqvarin); %convert to seconds, whatever the units
end

if strcmp(daqvartype, 'circular')
    daqvarin = daqvarin / (voltmax-voltmin)*2*pi - pi; %put in range -pi to pi,  0 V assigned to -pi
end

if isequal(vec(unique(daqvarin)), [0;1])
    daqvarin = bin2ind(daqvarin);
end

daqvarout = resample_timeseries(daqvartype, daqvarin, inds, newlength); %downsample into imaging rate
daqvarout_diff = differentiate_timeseries(daqvartype, daqvarout, slopelensec, slopeord, dt);


if doplots

    numframes = 20; 

    titlein = [daqvarname '_original_v_resample_' num2str(dt) 'sec_norescale'];
    pth_fig = [pthfigpre titlein '_.gif'];
    pltmultits(daqvarin, daqvarout, pth_fig, numframes, titlein)

    titlein = [daqvarname '_original_v_diff_resample_' num2str(dt) 'sec_slopelen_' num2str(slopelensec) 'sec_norescale'];
    pth_fig = [pthfigpre titlein '_.gif'];
    pltmultits(daqvarin, daqvarout_diff, pth_fig, numframes, titlein)

end

