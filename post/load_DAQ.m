function [md, ball, vis] = load_DAQ(ids, md, pth_daq, pth_fldr, fictracopts)

%note extracting velocity for what should be constant velocity cue can have
%spikes because of noise in the acquisition/display, zoom in and you will see it
% so there's a balance between large slope filters, which lose information
% but fix noise, and short filters which do oppoisite

% notes about cue artifacts
% frame 193 (when there is one) darkness, just replace with 192 for now as dummy (to not affect unwrapping), then fix later
% (do not replace with nan because sometimes intended 192 is assigned 193 presumably because of instrument noise, ie 193 doesn't just occur during the dark period at the end, even though it's supposed to)

% beware occasional circular artifact during transitions from max to min (eg 192 to 0), or vice versa,
% sometimes these transitions take more than 2 samples
% probably a
% the intermediate value can be unsystematically on either side of 0,
% which causes spikes in the unwrapped timeseries when the intermediate value is less than pi radians away from the previous value
% so smooth those out with tiny window in the unwrapped stim, otherwise there are spikes

%Elena: all Berg4 trials prior to 05/25/22 have the channels for IntSide & IntFor switched

%RIGHT NOW NOW CROPTIMEINDS FOR FICTRAC DATA THE WAY I DID FOR CLANDININ STIM DATA

datenum = ids.datenum;
flynum = ids.flynum;
trialnum = ids.trialnum;

dark_stim_end_duration = fictracopts.dark_stim_end_duration;
smoothwindow_sec = fictracopts.smoothwindow_sec;
slopelen = fictracopts.slopelen;
slopeorder = fictracopts.slopeorder;
no_stim_epochs = fictracopts.no_stim_epochs;
doplots = fictracopts.doplots;

maxvolt = 10; %need to find this in metadata
minvolt = 0; %need to find this in metadata
padlensec = 5; %arbitrary
rateim = md.volrate;
numsamp_im = md.numvol_o;
smoothwindow_i = smoothwindow_sec*rateim;

try
    
    load(pth_daq, 'daqdata')

catch


    [expMetadata,trialMetadata, patternMetadata, fictracMetadata] = load_flyg_metadata(ids, pth_fldr);

    if ~trialMetadata.usingPanels
        error("no panels info")
    end

    if isfield(patternMetadata,'arenaExtent')
        arenaExtent = patternMetadata.arenaExtent;
    else
        arenaExtent = 360;
        warning('experiment.arenaExtent missing in experiment CSV, using arenaExtent: 360 degrees')
    end

    if isfield(patternMetadata,'initialAngle')
        initialAngle = patternMetadata.initialAngle;
    else
        initialAngle = -9.375;
        warning('experiment.initialAngle missing in experiment CSV, using initialAngle: 90 degrees')
    end

    if isfield(patternMetadata,'ball')
        ball = patternMetadata.ball;
    else
        ball = 9;
        warning('fictrac.ball.diameter missing in experiment CSV, using ball diameter: 9 mm')
    end

    if isfield(patternMetadata,'patternLuminance')
        luminance = patternMetadata.patternLuminance;
    else
        luminance = 1;
        warning('experiment.patternLuminance missing in experiment CSV, using G3 pattern luminance: 1')
    end

    if isfield(patternMetadata,'yDimxDimRelationship')
        yDimxDim = patternMetadata.yDimxDimRelationship;
    else
        yDimxDim = 1;
        warning('experiment.yDimxDimRelationship missing in experiment CSV, using G3 yDimxDimRelationship: 1')
    end

    if isfield(patternMetadata,'cuePosAngleRelationship')
        cuePosAngleRel = patternMetadata.cuePosAngleRelationship;
    else
        cuePosAngleRel = 1;
        warning('experiment.cuePosAngleRel missing in experiment CSV, using G3 cuePosAngleRel: 1')
    end


    %%


    fndaq = dir(fullfile(pth_fldr,['*',ids.datefly_hyphen,'_daqData_*_trial_'  sprintf( '%03d', ids.trialnum ) '.mat']));

    load(fullfile(pth_fldr,fndaq.name), 'trialData')

    ratefictrac = fictracMetadata.fictracRate;
    try
        ratedaq = trialMetadata.daqSampRate;
    catch
        ratedaq = expMetadata.daqSampRate;
    end

    % Copy important variables, converting units as needed
    trialData = timetable2table(trialData);

    %% make daqdata table

    daqdata = table();
    daqdata.expID = {ids.datefly_hyphen};
    daqdata.trialNum = ids.trialnum;

    if any(strcmp(trialData.Properties.VariableNames, 'VolumeClock'))
        method_resample = 'timestamps';
        inds = trialData.VolumeClock;
    else
        method_resample = 'resample';
        inds = [];
    end

    ftvars = trialData.Properties.VariableNames;
    for ii = 1:numel(ftvars)
        fnnew = erase(ftvars{ii}, 'ficTrac');
        [ daqdata.(fnnew), daqdata.([fnnew '_diff']) ] = process_DAQ(ftvars{ii}, trialData.(ftvars{ii}), method_resample, numsamp_im, inds, rateim, maxvolt, slopelen, slopeorder, ball, padlensec);
    end


     save(pth_daq, 'daqdata', '-v7.3', '-mat')

end

