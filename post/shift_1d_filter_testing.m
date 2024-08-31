
%i'm using fmincon to fit a model
%part of the model is a parametric, 1d linear filter (shape is fast increase, then exponential decay)
%fmincon is optimizing two scalar parameters of this linear filter: the time constant ('tau_sec' below) and the time shift ('shift_sec' below, which is constrained to be positive, ie a delay)
%the time shift (delay), 'shift_sec',  is the tricky parameter
%currently, i'm using spline interpolation to shift the filter by optimized 'shift_sec'
%since the function model_output = f(shift_sec) must be differentiable (for the fmincon algorithm i'm using), linear interp is not an option
%the spline interpolation works for some input parameters (relatively long filters, relatively small shifts)
%but fails for some input parameters (relatively short filters, relatively long shifts)
%this causes problems during optimization,  
%below you can see two arbitrary examples of each situation by toggling 'use_good_inputs'
%the plot shows the original, and shifted filter
% some time-domain functions could easily be shifted by making t=t-shift, and not using interpolation at all,
% this is my preferred approach, since it would avoid interpolation failures (and cost during optimization)
% but that doesn't work in this case, for this specific function 
%see what i mean by setting use_preferred_approach=1
%to use interpolation, which sometimes looks good, set use_preferred_approach=0
% DO YOU KNOW HOW TO MAKE use_preferred_approach WORK FOR THE PARAMETRIC FILTER BELOW, OR SOMETHING ANALOGOUS, SO I CAN AVOID THE INTERPOLATION?
% or is this really the best way to shift this kind of parametric filter?
% thanks!

clear all
close all
clc

use_preferred_approach = 0; %1 uses t-shift to (try but fail to) shift, rather than interp, 0 uses interp (which only sometimes looks good)
use_good_inputs = 1; %only relevant if use_preferred_approach==0, set to 1 to use inputs in which interp looks good, 0 to use inputs in which interp looks bad

if use_good_inputs
    filt_len_sec = 10; %length of filter in seconds
    dt = 0.2; %filter sampling period in seconds
    tau_sec = 0.2; %filter time constant in seconds
    shift_sec = 2; %positive shift in seconds (delay)
    padlen_sec = 4; %padding length in seconds
else
    filt_len_sec = 1; %length of filter in seconds
    dt = 0.2; %filter sampling period in seconds
    tau_sec = 0.1; %filter time constant in seconds
    shift_sec = 0.3; %positive shift in seconds (delay)
    padlen_sec = 4; %padding length in seconds
end

%% make a 1d linear filter

t = 0:dt:filt_len_sec; %zero-indexed time domain for filter

filt = t./tau_sec^2.*exp(-t./tau_sec); %filter function, cannot implement shift by making t=t-shift
filt = filt / norm(filt(:),1); %normalize to make L1 norm==1

if use_preferred_approach
    
    tshift = t-shift_sec;
    filt_shift = tshift./tau_sec^2.*exp(-tshift./tau_sec); %filter function, cannot implement shift by making t=t-shift
    filt_shift = filt_shift / norm(filt_shift(:),1); %normalize to make L1 norm==1


else %%pad filter, then shift with spline, then remove padding

    padlen = round(padlen_sec/dt); %number samples for padding
    tmppad = zeros(1, length(t)+padlen*2); %initialize padded filter with zeros
    tnew = 0:length(tmppad)-1; %time domain for padded filter
    tmppad(padlen+1:end-padlen) = filt; %insert filter into padding
    tmppad = spline(tnew+shift_sec/dt,tmppad,tnew); %shift the padded filter with spline (transform shift_sec into samples by dividing by dt)
    filt_shift = tmppad(padlen+1:end-padlen); %remove padding
    filt_shift = filt_shift / norm(filt_shift(:),1); %normalize to make L1 norm==1

end
%% plot filter and shifted filter


figure; plot(t, filt); hold on; plot(t, filt_shift)
