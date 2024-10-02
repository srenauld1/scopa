function daqrs = daqld(recdatenum, flynum, trialnum, numvol, numslice, numslice_withflyback, imper, balldia, voltmin, voltmax, opt)


% uses imaging frameClock on DAQ to assign DAQ samples to frames (nearest neighbor interp to find each frame's centroid)
% includes volume and frame flyback samples (reason below)
% then uses mod to convert to daqinds.slice
% then, operates on daq variables according to coincident slice index, creating a different timeseries for each slice index
% this occurs differently according to daq variable type (see default 'daqvars' struct below)
% for 'normal' daq variables, averages daq variables during each frame,
% for 'circular' daq variables, does the same but operates on x and y components
% for 'categorical' daq variables, finds same but mode instead of mean
% only variables listed in daqvars will be processed, anything listed in daqvars but not found on daq is skipped
% averaging by frame allows comparisons between imaging and behavior to have greater resolution in lag
% volume and frame flyback samples are included for two reasons:
%    1 - we don't know the optimal lag,
%    2 - our imaging rates and indicators are pretty slow
% this function downsamples daq variables to match imaging, rather than upsampling imaging to match daq variables
% imaging rates and indicators are already smoothing neural activity, and visual system at least has very little power at 60 hz anyway (although not sure about other input modalities to our neurons)
% downsampling behavior regularizes subsequent model fitting (and also speeds computation)
% but this function does retain all available lag information by averaging during each slice index
% also creates a timeseries for the entire volume too, as the final entry of the resampled matrix, for each daqvariable, (this volume timeseries includes all flyback samples too)
% this function also differentiates all requested daq variables, using movingslope to reduce noise (increase slopelensec to reduce noise)
% with movingslope there is no need for smoothing first, since slope window is built in
% for circular variables, derivative operates on x and y components
% for categorical variables, derivative is skipped
% if frameClock is not on daq, uses matlab function 'resample' (again, with adjustments for circular variables)
% default frameClock approach is much slower than using 'resample', so there are checkpoints where variables are saved and loaded on subsequent runs,
% but this appears to be a little more accurate, and handles sharp transitions well
% useinds 'none' will use the resample approach (which takles 5-10 seconds),
% the slow version will take about 10 minutes the first time you run it (but subsequent runs on the same daqdata will just take seconds)


arguments
    recdatenum {mustBeNumeric}
    flynum {mustBeNumeric}
    trialnum {mustBeNumeric}
    numvol {mustBeNumeric}
    numslice {mustBeNumeric}
    numslice_withflyback {mustBeNumeric}
    imper {mustBeNumeric} %imaging frame period (1/volrate)
    balldia {mustBeNumeric}
    voltmin {mustBeNumeric}
    voltmax {mustBeNumeric}
    opt.vnormal = {'Time', 'heat', 'virmenIteration'}; %list normal (not circular, not categorical) daq variables you want to process; virmenIteration is averaged by imaging frame, output is converted to frame number in the usual way
    opt.vcircular = {'ficTracIntSide', 'ficTracIntForward', 'ficTracYaw', 'g4panels'}; %list circular daq variables you want to process
    opt.vcategorical = {'ftcam'}; %list categorical daq variables you want to process
    opt.toballscale = {'ficTracIntSide', 'ficTracIntForward'}; %define which vars to rescale from radians to mm
    opt.tounwrap = {'ficTracIntSide', 'ficTracIntForward'}; %define which vars to unwrap
    opt.tozero = {'ficTracIntSide', 'ficTracIntForward'}; %%define which vars to zero (force to start at 0)
    opt.pth_fldr = '' %can pass pth_fldr instead of pth_daq and/or pth_daqrs
    opt.pth_daq char = '' %path to daq data from experiment; can pass pth_fldr instead of pth_daq and/or pth_daqrs
    opt.pth_daqrs char = '' %save path for resampled daq data; can pass pth_fldr instead of pth_daq and/or pth_daqrs
    opt.slopelensec {mustBeNumeric} = 0.2 %slope length (seconds) for computing derivative of each daq variable
    opt.slopeord {mustBeNumeric} = 2 %slope order for computing derivative of each daq variable (should just stay 2)
    opt.useinds = 'none' %'none', 'slice', 'vol', 'all', or numeric vector of slice indices, with optional 0 to mean volume indices; 'none' (resample using 'resample' function with padding to avoid start/end transients), 'slice' (resample using all slice indices), 'vol' (resample using volume indices), 'all' (resample using all slice indices and volume indices), numeric vector defines which slice indices (one indexed) to use with 0 denoting volume index resampling (eg [0 4] will resample with volume and slice 4); 'none' is fastest but has a little more aliasing, which is probably rarely a problem; slice resampling is included especially for slow imaging rate, or large flyback; the more resampling registers are used, the slower this function on first run (output is saved/loaded for subsequent runs)
    opt.use_flyback_lines logical = 1 %use flyback lines when defining resampling inds if useinds is not none; flyback lines are probably always too fast to ever make this parameter matter
    opt.use_flyback_frames logical = 1%use flyback frames when defining resampling inds if useinds is not none; this param could be relevant for slow volume rates, or flyback that is slow, relative to non-flyback
    opt.doplots logical = 0
    opt.idxreg char = 'start' %work-in-progress, currently has no effect; 'start', 'end', 'center'; index represents the start, end, center of bin
end

vnormal = opt.vnormal;
vcircular = opt.vcircular;
vcategorical = opt.vcategorical;
toballscale = opt.toballscale;
tounwrap = opt.tounwrap;
tozero = opt.tozero;
pth_fldr = opt.pth_fldr;
pth_daq = opt.pth_daq;
pth_daqrs = opt.pth_daqrs;
slopelensec = opt.slopelensec;
slopeord = opt.slopeord;
useinds = opt.useinds;
use_flyback_lines = opt.use_flyback_lines;
use_flyback_frames = opt.use_flyback_frames;
doplots = opt.doplots;
idxreg = opt.idxreg;


sprintf("FOR NORMAL AND CIRCULAR VARIABLES, CONSIDER A SWITCH FROM MEAN TO INTERP NEAREST WHEN THERE ARE MANY FLYBACK FRAMES, OR WHEN VOLRTE IS LOW, SINCE INCLUDING THOSE IS IN MEAN IS MISLEADING (IF THEY ARE INCLUDED WITH use_flyback_frames=1)")


if isempty(pth_daq)
    if isempty(pth_fldr)
        error(sprintf("pth_fldr cannot be empty if pth_daq is empty"))
    end
    pth_daq_pat = [pth_fldr num2str(recdatenum) '-' num2str(flynum) '_daqData_*_trial_' sprintf( '%03d', trialnum ) '.mat'];
    pth_daq = rdir(pth_daq_pat);
    pth_daq = pth_daq.name;
end

if isempty(pth_daqrs)
    if isempty(pth_fldr)
        error(sprintf("pth_fldr cannot be empty if pth_daqrs is empty"))
    end
    pth_daqrs = [pth_fldr num2str(recdatenum) '_' num2str(flynum) '_' num2str(trialnum) '_daqrs_.mat'];
end

pthfigpre = pth_daqrs(1:end-4);

if doplots
    maxtplot = 2; %first maxtplot seconds to plot daqinds in daqindsmake
else
    maxtplot = 0; %first maxtplot seconds to plot daqinds in daqindsmake
end

daqvars_bytype.normal = vnormal;
daqvars_bytype.circular = vcircular;
daqvars_bytype.categorical = vcategorical;

%% load daqdata

load(pth_daq, 'trialData', 'outputData')
trialData = timetable2table(trialData);

if exist('outputData', 'var') && outputData(2)==0 && outputData(end-1)==0 %output data is less accurate than frameClock, since volume (or frame?) seems to complete after outputData ends, but i think frameClock is missing any final flyback frames
    "TEMPORARY HACK FOR CROPPING NEW RUNBG DAQ (WHEN DAQ RUNS IN BACKGROUND, TO CAPTURE START AND END OF EVERYTHING)"
    firstsamp = find(trialData.frameClock, 1, 'first');
    lastsamp = find(trialData.frameClock, 1, 'last');
    if strcmp(idxreg, 'start')
        starttime = trialData.Time(firstsamp);
    elseif strcmp(idxreg, 'end')
        starttime = trialData.Time(firstsamp-1);
    elseif strcmp(idxreg, 'center')
        starttime = (trialData.Time(firstsamp) - trialData.Time(firstsamp-1) ) / 2;
    end
    trialData = trialData(firstsamp:lastsamp, :);
else
    starttime = trialData.Time(1);
end

%% define inds for downsampling

%%%%%%%%% extract slice and volume indices from scanimage clocks %%%%%%%%% 

daqinds.frame = []; %frame inds are not used outside function daqindsmake, although could be in the same way as slice or volume indices 
daqinds.slice = [];
daqinds.vol = [];
if any(strcmp(trialData.Properties.VariableNames, 'frameClock')) %cannot run daqindsmake without frameClock
    daqinds = daqindsmake(trialData.frameClock, trialData.Time, use_flyback_lines, use_flyback_frames, numvol, numslice, numslice_withflyback, maxtplot, pthfigpre);
else
    sprintf("frame clock not on daq, or user requested useinds 'none'; downsampling daq data with 'resample' function, rather than resampling with frame and/or volume indices")
end

%%%%%%%%% filter slice inds and volume inds according to useinds %%%%%%%%% 

if strcmp(useinds, 'slice') || strcmp(useinds, 'none')
    daqinds.vol = [];
end
if strcmp(useinds, 'vol') || strcmp(useinds, 'none')
    daqinds.slice = [];
end
if isnumeric(useinds)
    if any(~ismember(useinds(useinds~=0), daqinds.slice))
        error("you requested a useinds that does not exist in sliceinds; it may exceed numslice_withflyback, or it may have been eliminated from sliceinds given your setting for use_flyback_frames")
    end
    if all(useinds==0) %useinds=0 is same as useinds='vol'
        daqinds.slice = [];
    else
        daqinds.slice(~ismember(daqinds.slice, useinds)) = 0;
    end
    if ~ismember(0, useinds)
        daqinds.vol = [];
    end
end
if isempty(daqinds.vol)
    include_volume_resample = 0;
else
    include_volume_resample = 1;
end
if strcmp(useinds, 'none')
    include_volume_approx_resample = 1;
else
    include_volume_approx_resample = 0;
end


%% make/save resampled daqdata


sliceinds_unique = unique(daqinds.slice(daqinds.slice~=0));
num_unique_sliceinds = numel(sliceinds_unique);
num_resamples = num_unique_sliceinds + include_volume_resample + include_volume_approx_resample; %resample for each slice remaining in sliceinds, and and another for volume (if it volinds remains)
daqrs = table();
for si = 1:num_resamples

    newrow = table();
    newrow.recdatenum = {recdatenum};
    newrow.flynum = {flynum};
    newrow.trialnum = {trialnum};
    if strcmp(useinds, 'none')
        resample_inds = [];
        newrow.methodrs = {'volume_approx'};
    else
        if si<num_unique_sliceinds+1
            resample_inds = bin2ind(daqinds.slice==sliceinds_unique(si)); %each slice
            newrow.methodrs = {['slice' num2str(sliceinds_unique(si))]};
        else
            resample_inds = daqinds.vol;
            newrow.methodrs = {'volume'};
        end
    end

    fn = fieldnames(daqvars_bytype);
    for fni = 1:numel(fn)
        daqvartype = fn{fni};
        for ii = 1:numel(daqvars_bytype.(daqvartype))
            daqvarname = daqvars_bytype.(daqvartype){ii};
            if strcmp(daqvarname, 'Time')
                trialData.(daqvarname) = trialData.(daqvarname)-starttime; %zero imaging starttime in case daq ran in the background
            end
            if ~strcmp(trialData.Properties.VariableNames, daqvarname)
                sprintf("warning, daq does not have variable named '" + daqvarname + "', skipping it")
            else

                [ tmp, tmp_diff ] = daqproc(daqvartype, daqvarname, trialData.(daqvarname), numvol, resample_inds, imper, voltmin, voltmax, slopelensec, slopeord, pthfigpre, doplots);

                if any(strcmp(daqvars_bytype.(daqvartype){ii}, tounwrap))
                    tmp = unwrap(tmp); %convert to mm (not for tmp_diff)
                end
                if any(strcmp(daqvars_bytype.(daqvartype){ii}, tozero))
                    tmp = tmp - tmp(1); %convert to mm (not for tmp_diff)
                end
                if any(strcmp(daqvars_bytype.(daqvartype){ii}, toballscale))
                    tmp = tmp*balldia/2; %convert to mm
                    tmp_diff = tmp_diff*balldia/2; %convert to mm
                end
                if ~strcmp(daqvarname, 'Time') %we don't care to create 'Time_diff'
                    tmp_diff = tmp_diff / imper; %convert to per second using mean sample period (could scale by each Time_diff, but this is more stable against dropped samples)
                end
                if strcmp(daqvarname, 'Time') && strcmp(idxreg, 'start') %if idxreg is 'start', make sure time starts at zero, for useinds 'none', it is artifactually slightly above zero
                    tmp(1) = 0;
                    tmp_diff(1) = tmp(2) - tmp(1); %also update first diff, not that it matters
                end
                if isrow(tmp) %each daq var must be column; will be column for useinds 'none', will be row for useinds 'all' and 'vol'
                    tmp = tmp';
                end
                newrow.(daqvarname) = {tmp}; %put in cell, then table, for variable sizes
                newrow.([daqvarname '_dv']) = {tmp_diff}; %put in cell, then table, for variable sizes
            end
        end
    end
    daqrs = [daqrs; newrow];
end

save(pth_daqrs, 'daqrs', '-v7.3', '-mat');








