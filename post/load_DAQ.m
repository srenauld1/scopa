function [md, ball, vis] = load_DAQ(ids, md, pth_daq, pth_fldr, opts)

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

ball = [];
vis = [];

maxvolt = 10; %need to find this in metadata
minvolt = 0; %need to find this in metadata
padlensec = 5; %arbitrary
smoothwindow_i = opts.smoothwindow_sec*md.volrate;

if opts.use_carls_epochs
    if ids.datenum<20231119
        testepochind_all = [2 3];
    elseif ids.datenum>=20231119 && ids.datenum<20231231
        testepochind_all = [2 3 5];
    end
end

try

    fool=moo
    load(pth_daq, 'daqdata_resamp', 'epochinds_ts_i', 'epochinds')

catch


    %% load flyg_metadata and daqdata

    % md = load_flyg_metadata(ids, pth_fldr, md);

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

    md.ball_diameter = 9;
    uniquesliceinds = unique(sliceinds(sliceinds~=0));
    num_unique_sliceinds = numel(uniquesliceinds);
    daqdata_resamp = table();
    for si = 1:num_unique_sliceinds+1
        
        newrow = table();
        newrow.expID = {ids.datefly_hyphen};
        newrow.trialNum = ids.trialnum;
        if isempty(sliceinds)
            resample_inds = [];
        else
            if si<num_unique_sliceinds+1
                resample_inds = binary2count(sliceinds==uniquesliceinds(si)); %each slice
                newrow.sliceindex = uniquesliceinds(si);
            else
                resample_inds = ceil(binary2count(logical(sliceinds))/num_unique_sliceinds); %all slices (the whole volume)
                newrow.sliceindex = 'volume';
            end
        end

        ftvars = trialData.Properties.VariableNames;
        for ii = 1:numel(ftvars)
            fnnew = erase(ftvars{ii}, 'ficTrac');
            if ~contains(ftvars{ii}, 'Clock')
                [ newrow.(fnnew), newrow.([fnnew '_diff']) ] = process_DAQ_signal(ftvars{ii}, trialData.(ftvars{ii}), md.numvol_o, resample_inds, md.dtmni, maxvolt, opts.slopelen, opts.slopeorder, md.ball_diameter, padlensec);
            end
        end
        daqdata_resamp = [daqdata_resamp; newrow];
    end

    %% epochinds


    [epochinds_ts_i, epochinds] = process_epochinds(opts.no_stim_epochs, trialtime, pth_fldr, ids, daqdata_resamp, testepochind_all);


    %% save and plot

    save(pth_daq, 'daqdata_resamp', 'epochinds_ts_i', 'epochinds');

end

figframes = 0;
hfg = figure;
hax = axes('Parent', hfg);
for tei = 1:numel(testepochind_all)
    figframes = figframes+1;
    plot(hax, daqdata_resamp.g4panels{1}(epochinds_ts_i==testepochind_all(tei)))
    title(['final offset'])
    fig2gif(hfg, figframes, [pth_fldr 'misoffset_final.gif'])
end

md.epochinds_ts_i = epochinds_ts_i;
if isfield(epochinds, 'dark') || isfield(epochinds, 'closedfinaldark')
    naninds_i = epochinds_ts_i==epochinds.dark | epochinds_ts_i==epochinds.closedfinaldark; %dark gets nans
else
    naninds_i = [];
end

ball.yaw = daqdata_resamp.Yaw{1};
ball.yawvel = daqdata_resamp.Yaw_diff{1};
ball.intfor = daqdata_resamp.IntForward{1};
ball.forvel = daqdata_resamp.IntForward_diff{1};
ball.intside = daqdata_resamp.IntSide{1};
ball.sidevel = daqdata_resamp.IntSide_diff{1};

vis.ang = daqdata_resamp.g4panels{1};
vis.angvel = daqdata_resamp.g4panels_diff{1};
vis.ang(naninds_i) = nan; %put nans where the cue doesn't exist (dark epoch)
vis.angvel(naninds_i) = nan; %put nans where the cue doesn't exist (dark epoch)

md.t_ts_i = daqdata_resamp.Time{:};
md.total_t = max(md.t_ts_i);
sprintf("dti and volrate, respectively (should be the same or nearly the same): " + num2str(mean(diff(md.t_ts_i))) + ", " + num2str(1/md.volrate))

