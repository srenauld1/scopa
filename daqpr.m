function [daqvarout, daqvarout_dv] = daqpr(daqvartype, daqvarname, daqvarin, ...
    newlength, inds, dt, voltmin, voltmax, slopelensec, slopeord, pthfigpre, doplt)

% default resampling uses daq frame timestamps ('inds')
% if they're not on daq, backup uses matlab 'resample', matching goal length ('newlength')
% option to plot multiple zoomed in views of timeseries before and after resampling

% note:
% smoothing daqvarout before differentiation should not be necessary because it's been downsampled so much,
% and tsdv allows variable slope window anyway (increase to reduce output noise)
% but if you still want to smooth first, try passing output of tssm to tsdv, like this:
% tsdv(daqvartype, tssm(daqvartype, daqvarin, smlensec, dt), slopelensec, slopeord, dt);

if isduration(daqvarin)
    daqvarin = seconds(daqvarin); %convert to seconds, whatever the units
end

if strcmp(daqvartype, 'circular')
    daqvarin = daqvarin / (voltmax-voltmin)*2*pi - pi; %put in range -pi to pi, 0 V assigned to -pi
end

if isequal(vec(unique(daqvarin)), [0;1])
    daqvarin = bin2ind(daqvarin);
end

daqvarout = tsrs(daqvartype, daqvarin, inds, newlength); %resample into imaging rate
daqvarout_dv = tsdv(daqvartype, daqvarout, slopelensec, slopeord, dt); %find local slope 


if doplt

    xseg = 20; 

    titlein = [daqvarname '_original_v_resample_' num2str(dt) 'sec_norescale'];
    pth_fig = [pthfigpre titlein '_.gif'];
    tsplt(1:numel(daqvarin), daqvarin, 1:numel(daqvarout), daqvarout, xseg=xseg, titlein=titlein, pthgif=pth_fig)

    titlein = [daqvarname '_original_v_dv_resample_' num2str(dt) 'sec_slopelen_' num2str(slopelensec) 'sec_norescale'];
    pth_fig = [pthfigpre titlein '_.gif'];
    tsplt(daqvarin, y2=daqvarout_dv, xseg=xseg, titlein=titlein, pthgif=pth_fig)

end

