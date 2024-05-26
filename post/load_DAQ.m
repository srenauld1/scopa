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

datenum = ids.datenum;
flynum = ids.flynum;
trialnum = ids.trialnum;

smoothwindow_sec = opts.smoothwindow_sec;
slopelen = opts.slopelen;
slopeorder = opts.slopeorder;
no_stim_epochs = opts.no_stim_epochs;
doplots = opts.doplots;
method_resample = opts.method_resample;

maxvolt = 10; %need to find this in metadata
minvolt = 0; %need to find this in metadata
padlensec = 5; %arbitrary
rateim = md.volrate;
numsamp_im = md.numvol_o;
smoothwindow_i = smoothwindow_sec*rateim;

if datenum<20231119
    testepochind_all = [2 3];
elseif datenum>=20231119 && datenum<20231231
    testepochind_all = [2 3 5];
end

try

    load(pth_daq, 'daqdata_resamp', 'epochinds_ts_i', 'epochinds')

catch


    %% load flyg_metadata and daqdata

    md = load_flyg_metadata(ids, pth_fldr, md);

    fndaq = dir(fullfile(pth_fldr,['*', ids.datefly_hyphen,'_daqData_*_trial_' sprintf( '%03d', ids.trialnum ) '.mat']));
    load(fullfile(pth_fldr,fndaq.name), 'trialData')

    trialData = timetable2table(trialData);   % Copy important variables, converting units as needed

    if strcmp(method_resample, 'frames')
        if any(strcmp(trialData.Properties.VariableNames, 'frameClock'))
            inds = cumsum(trialData.FrameClock); %this assumes there is always at least one zero between frames (flyback)
        else
            method_resample = 'volumes';
            sprintf("frame clock not on daq, trying method_resample 'volumes'")
        end
    end
    if strcmp(method_resample, 'volumes')
        if any(strcmp(trialData.Properties.VariableNames, 'volumeClock'))
            inds = cumsum(trialData.VolumeClock); %this assumes there is always at least one zero between frames (flyback)
        else
            method_resample = 'uniform';
            sprintf("volume clock not on daq, trying method_resample 'uniform'")
        end
    end
    if strcmp(method_resample, 'uniform')
        method_resample = 'uniform';
        inds = [];
    end

    %% make/save daqdata_resamp table

    daqdata_resamp = table();
    daqdata_resamp.expID = {ids.datefly_hyphen};
    daqdata_resamp.trialNum = ids.trialnum;

    ftvars = trialData.Properties.VariableNames;
    for ii = 1:numel(ftvars)
        fnnew = erase(ftvars{ii}, 'ficTrac');
        if ~contains(ftvars{ii}, 'Clock')
            [ daqdata_resamp.(fnnew), daqdata_resamp.([fnnew '_diff']) ] = process_DAQ_signal(ftvars{ii}, trialData.(ftvars{ii}), method_resample, numsamp_im, inds, rateim, maxvolt, slopelen, slopeorder, md.ball_diameter, padlensec);
        end
    end


    %% epochinds


    if no_stim_epochs
        epochinds_ts_i = ones(numel(daqdata_resamp.Time{:}), 1);
    else
        if ~any(strcmp(daqdata_resamp.Properties.VariableNames, 'epochinds'))

            sprintf("warning, epochinds not saved to daq, using hard coded epochinds aligned by minimizing error")
            minshiftsec = 0;
            maxshiftsec = 8;
            ft_misoffset_sec_all = 0 : md.dtmni*0.45 : 7;
            hfg = figure;
            hax = axes('Parent', hfg);
            bestshiftind_allepochs = [];
            figframes = 0;
            for tei = 1:numel(testepochind_all)
                testepochind = testepochind_all(tei);
                criter = nan(numel(ft_misoffset_sec_all), 1);
                for fmsai = 1:numel(ft_misoffset_sec_all)
                    figframes = figframes+1;

                    ft_misoffset_sec = ft_misoffset_sec_all(fmsai);
                    epochinds_ts_i = define_stim_epoch_indices(ft_misoffset_sec, daqdata_resamp.Time{:}, datenum); %%%%%% DEFINE STIM EPOCH INDS IN THIS SCRIPT, WILL BE DEPRECATED WHEN SOCKET CODE SAVES EPOCH INDICES DURING EXPERIMENT   %%%%%%%%%  %%%%%%%%%

                    fu = daqdata_resamp.g4panels{1}(epochinds_ts_i==testepochind);
                    if testepochind==2 || testepochind==3
                        fu = unwrap(fu); %makes it easier to see
                    end
                    % fu = cos(fu);
                    %fu = diff(diff(fu));
                    plot(hax,fu)
                    %ylim(hax, [min(daqdata_resamp.g4panels{1}(:)) - abs(min(daqdata_resamp.g4panels{1}(:)))*0.3, max(daqdata_resamp.g4panels{1}(:)) + abs(max(daqdata_resamp.g4panels{1}(:)))*0.3])
                    % ylim([-20 20])
                    if testepochind==2 || testepochind==3
                        fud2 = diff(diff(fu));
                        criter(fmsai) = numel(find(isoutlier(fud2))); %minimize num unique variables in diff, since open look should have only a couple (constant vel)
                    elseif testepochind==5
                        criter(fmsai) = var(cos(fu)); %minimize variance of x (or y) component of circular variable, this is offset with least error
                    end
                    title([criter(fmsai) ft_misoffset_sec ft_misoffset_sec])
                    fig2gif(hfg, figframes, [pth_fldr 'misoffset_.gif'])

                    if fmsai==numel(ft_misoffset_sec_all)
                        critd = movingslope(criter, 20, 2, md.dtmni);
                        if ~(min(critd)<0 && max(critd)>0)
                            sptinf("error is monotonic, expand search range")
                        end
                        [~, bestshiftind_oneepoch] = min(criter);
                        bestshiftind_allepochs = [bestshiftind_allepochs bestshiftind_oneepoch];
                    end
                end
            end

            ft_misoffset_sec = mean(ft_misoffset_sec_all(bestshiftind_allepochs));
            [epochinds_ts_i, epochinds] = define_stim_epoch_indices(ft_misoffset_sec, daqdata_resamp.Time{:}, datenum); %%%%%% DEFINE STIM EPOCH INDS IN THIS SCRIPT, WILL BE DEPRECATED WHEN SOCKET CODE SAVES EPOCH INDICES DURING EXPERIMENT   %%%%%%%%%  %%%%%%%%%

        end
    end


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
naninds_i = epochinds_ts_i==epochinds.dark | epochinds_ts_i==epochinds.closedfinaldark; %dark gets nans

ball.ang = daqdata_resamp.Yaw{1};
ball.angvel = daqdata_resamp.Yaw_diff{1};
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

