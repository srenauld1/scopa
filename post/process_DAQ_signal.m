function [daqvarout, daqvarout_diff] = process_DAQ_signal(daqvartype, daqvarname, daqvarin, ...
    newlength, inds, dt, maxvolt, slopelen_sec, slopeorder, ...
    pth_daq_resamp, doplots)

% default resampling uses daq frame timestamps ('inds')
% if they're not on daq, backup uses matlab 'resample', matching goal length ('newlength')
% option to plot multiple zoomed in views of timeseries before and after resampling

% note:
% smoothing daqvarout before differentiation should not be necessary because it's been downsampled so much,
% and differentiate_timeseries allows variable slope window anyway (increase to reduce output noise)
% but if you still want to smooth first, try passing output of smooth_timeseries to differentiate_timeseries, like this:
% differentiate_timeseries(daqvartype, smooth_timeseries(daqvartype, daqvarin, smoothwindow_sec, dt), slopelen_sec, slopeorder, dt);

if isduration(daqvarin)
    daqvarin = seconds(daqvarin); %convert to seconds, whatever the units
end

if strcmp(daqvartype, 'circular')
    daqvarin = daqvarin / maxvolt*2*pi - pi; %put in range -pi to pi,  0 V assigned to -pi
end


daqvarout = resample_timeseries(daqvartype, daqvarin, inds, newlength); %downsample into imaging rate
daqvarout_diff = differentiate_timeseries(daqvartype, daqvarout, slopelen_sec, slopeorder, dt);


if doplots

    numframes = 20; 

    titlein = [daqvarname '_hires_v_lores_' num2str(dt) 'sec_norescale'];
    pth_fig = [pth_daq_resamp(1:end-4) titlein '_.gif'];
    plot_multi_timeseries(daqvarin, daqvarout{1} / rescalefac, pth_fig, numframes, titlein)

    titlein = [daqvarname '_hires_v_difflores_' num2str(dt) 'sec_slopelen_' num2str(slopelen_sec) 'sec_norescale'];
    pth_fig = [pth_daq_resamp(1:end-4) titlein '_.gif'];
    plot_multi_timeseries(daqvarin, daqvarout_diff{1} / rescalefac, pth_fig, numframes, titlein)

end

