function [md, ball, vis] = load_DAQ(ids, md, pth_daq, pth_fldr, opts)

% using movingslope to extract velocity (can increase slopelen_sec to reduce noise)
% with this there is no need for smoothing first 
% for circular variables, operating on x and y components

%croptimeinds is just here for symmetry with loading carl's clandinin lab data in another function

ball = [];
vis = [];
epochinds = [];

maxvolt = 10; %need to find this in metadata
minvolt = 0; %need to find this in metadata
padlensec = 5; %arbitrary
smoothwindow_i = opts.smoothwindow_sec*md.volrate;

try

    fool=dd
    load(pth_daq, 'daqdata_resamp', 'epochinds')

catch


    %% load daqdata

    fndaq = dir(fullfile(pth_fldr,['*', ids.datefly_hyphen,'_daqData_*_trial_' sprintf( '%03d', ids.trialnum ) '.mat']));
    load(fullfile(pth_fldr,fndaq.name), 'trialData')

    trialData = timetable2table(trialData); % Copy important variables, converting units as needed

    if any(strcmp(trialData.Properties.VariableNames, 'frameClock'))
        sliceinds = binary2count(trialData.frameClock);
        if opts.discard_flyback_frames
            flyback_frames = md.numslice+1:md.numslice_withflyback;
            numvol_from_frames = max(sliceinds)/md.numslice_withflyback;
            if numvol_from_frames~=md.numvol_o
                error("number of volumes computed from daq frames does not match number of stack volumes")
            end
            sliceinds(sliceinds==0) = nan; %make zeros nan before mod
            sliceinds = mod(sliceinds-1, md.numslice_withflyback)+1; %get one-indexed slice indices
            sliceinds(ismember_each_element(sliceinds, flyback_frames)) = 0; %make flyback frames zero
            sliceinds(isnan(sliceinds)) = 0; %return nan to zero
        end
    else
        sprintf("frame clock not on daq, downsampling daq data with 'resample' function, rather averaging during frames")
        sliceinds = [];
    end


    %% make/save daqdata_resamp table

    uniquesliceinds = unique(sliceinds(sliceinds~=0));
    num_unique_sliceinds = numel(uniquesliceinds);
    daqdata_resamp = table();
    for si = 1:num_unique_sliceinds+1
        
        newrow = table();
        newrow.datenum = {ids.datenum};
        newrow.flynum = {ids.flynum};
        newrow.trialnum = {ids.trialnum};
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

        ftvars = trialData.Properties.VariableNames;
        for ii = 1:numel(ftvars)
            if ~contains(ftvars{ii}, 'Clock')
                [ newrow.(ftvars{ii}), newrow.([ftvars{ii} '_diff']) ] = process_DAQ_signal(ftvars{ii}, trialData.(ftvars{ii}), md.numvol_o, resample_inds, md.dtmni, maxvolt, opts.slopelen_sec, opts.slopeorder, md.ball_diameter, padlensec);
            end
        end
        daqdata_resamp = [daqdata_resamp; newrow];
    end

    %% epochinds


    epochinds = process_epochs(daqdata_resamp.Time{strcmp(daqdata_resamp.sliceindex, 'volume')}, pth_fldr, ids, md.dtmni, daqdata_resamp, opts.use_carls_epochs);



    %% save and plot

    save(pth_daq, 'daqdata_resamp', 'epochinds');

end


ball.yaw = daqdata_resamp.ficTracYaw{1};
ball.yawvel = daqdata_resamp.ficTracYaw_diff{1};
ball.intfor = daqdata_resamp.ficTracIntForward{1};
ball.forvel = daqdata_resamp.ficTracIntForward_diff{1};
ball.intside = daqdata_resamp.ficTracIntSide{1};
ball.sidevel = daqdata_resamp.ficTracIntSide_diff{1};

vis.ang = daqdata_resamp.g4panels{1};
vis.angvel = daqdata_resamp.g4panels_diff{1};
vis.ang(epochinds.naninds_i) = nan; %put nans where the cue doesn't exist (dark epoch)
vis.angvel(epochinds.naninds_i) = nan; %put nans where the cue doesn't exist (dark epoch)

md.t_ts_i = daqdata_resamp.Time{:};
md.total_t = max(md.t_ts_i);
md.epochinds_ts_i = epochinds.epochinds_ts_i;
md.naninds_i = epochinds.naninds_i;

