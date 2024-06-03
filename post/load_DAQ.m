function daqdata_resamp = load_DAQ(datenum, flynum, trialnum, numvol, numslice_withflyback, ...
    dtmni, ball_diameter, pth_daq, pth_daq_resamp, slopelen_sec, slopeorder, fast_version, doplots)

arguments
    datenum double
    flynum double
    trialnum double
    numvol double
    numslice_withflyback double
    dtmni double %imaging frame period (1/volrate)
    ball_diameter double
    pth_daq char
    pth_daq_resamp char
    slopelen_sec double
    slopeorder double
    fast_version logical %fast_version takes seconds, but less accurate, slow version takes minutes on first run (subsequent runs takes seconds)
    doplots logical
end

% uses imaging frameClock on DAQ to assign DAQ samples to frames (nearest neighbor interp to find each frame's centroid)
% includes volume and frame flyback samples (reason below)
% then uses mod to convert to sliceinds
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
% also creates a timeseries for the entire volume too, as the final entry (this volume timeseries includes all flyback samples too)
% this function also differentiates all requested daq variables, using movingslope to reduce noise (increase slopelen_sec to reduce noise)
% with movingslope there is no need for smoothing first, since slope window is built in
% for circular variables, derivative operates on x and y components
% for categorical variables, derivative is skipped
% if frameClock is not on daq, uses matlab function 'resample' (again, with adjustments for circular variables)
% default frameClock approach is much slower than using 'resample', so there are checkpoints where variables are saved and loaded on subsequent runs,
% but this appears to be a little more accurate, and handles sharp transitions well
% fast_version will use the resample approach (which takles 5-10 seconds),
% the slow version will take about 10 minutes the first time you run it (but subsequent runs on the same daqdata will just take seconds)



%% set daq variables to read, according to variable type

daqvars.normal = {'Time', 'heat', 'virmenIteration'}; %virmenIteration is averaged by imaging frame, output is converted to frame number in the usual way
daqvars.circular = {'ficTracIntSide', 'ficTracIntForward', 'ficTracYaw', 'g4panels'};
daqvars.categorical = {''};

daqvars_to_scale_by_ball_diameter = {'ficTracIntSide', 'ficTracIntForward'}; %define which of the above need to be rescaled

minvolt = 0; %daq voltage min; need to find this in metadata
maxvolt = 10; %daq voltage max, need to find this in metadata


%% load daqdata

load(pth_daq, 'trialData')

trialData = timetable2table(trialData);

%% define inds for downsampling

if any(strcmp(trialData.Properties.VariableNames, 'frameClock')) && ~fast_version

    try
        load([pth_daq_resamp(1:end-4) 'sliceinds.mat'], 'sliceinds');
    catch
        trialData.frameClock
        if trialData.frameClock(1) == 1
            sprintf("warning, first daq sample is during an imaging frame")
        end
        frameinds = binary2count(trialData.frameClock);
        numvol_from_frames = max(frameinds)/numslice_withflyback;
        if numvol_from_frames~=numvol
            error("number of volumes computed from daq frames does not match number of stack volumes")
        end
        usi = unique(frameinds(frameinds~=0),'stable'); %index of each frame
        sliceinds = nan(size(frameinds));
        for ii = 1:numel(usi) %loop is much faster than using arrayfun
            volume_centroid = mean(trialData.Time(frameinds==usi(ii))); %find time centroid for each volume
            [~, volume_centroid_ind] = min(abs(trialData.Time - volume_centroid)); %find nearest daq sample to volume centroid
            sliceinds(volume_centroid_ind) = frameinds(volume_centroid_ind); %put volume index at nearest daq sample to volume centroid
        end
        sliceinds = fillmissing(sliceinds, 'nearest');
        sliceinds = mod(sliceinds-1, numslice_withflyback)+1; %get one-indexed slice indices
    end

else
    sprintf("frame clock not on daq, downsampling daq data with 'resample' function, rather averaging during frames")
    sliceinds = [];
end


%% make/save resampled daqdata

uniquesliceinds = unique(sliceinds(sliceinds~=0));
num_unique_sliceinds = numel(uniquesliceinds);
num_resamples = num_unique_sliceinds + 1; %resample for each frame, and add one for volume
daqdata_resamp = table();
for si = 1:num_resamples

    newrow = table();
    newrow.datenum = {datenum};
    newrow.flynum = {flynum};
    newrow.trialnum = {trialnum};
    if isempty(sliceinds)
        resample_inds = [];
        newrow.sliceindex = {'volume'};
    else
        if si<num_unique_sliceinds+1
            resample_inds = binary2count(sliceinds==uniquesliceinds(si)); %each slice
            newrow.sliceindex = {uniquesliceinds(si)};
        else
            resample_inds = ceil(binary2count(logical(sliceinds))/num_unique_sliceinds); %all slices (the whole volume)
            newrow.sliceindex = {'volume'};
        end
    end

    fn = fieldnames(daqvars);
    for fni = 1:numel(fn)
        daqvartypes = fn{fni};
        for ii = 1:numel(daqvars.(daqvartypes))
            scale_by_ball_diameter = any(strcmp(daqvars.(daqvartypes){ii}, daqvars_to_scale_by_ball_diameter));
            daqvarname = daqvars.(daqvartypes){ii};
            if ~strcmp(trialData.Properties.VariableNames, daqvarname)
                sprintf("warning, daq does not have variable named '" + daqvarname + "', skipping it")
            else
                [ newrow.(daqvarname), newrow.([daqvarname '_diff']) ] = process_DAQ_signal(daqvartypes, daqvarname, trialData.(daqvarname), numvol, resample_inds, dtmni, maxvolt, slopelen_sec, slopeorder, ball_diameter, scale_by_ball_diameter, pth_daq_resamp, doplots);
            end
        end
    end
    daqdata_resamp = [daqdata_resamp; newrow];
end

save(pth_daq, 'daqdata_resamp');





