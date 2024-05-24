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

maxvolt = 10; %need to find this in metadata
minvolt = 0; %need to find this in metadata
padlensec = 5; %arbitrary
rateim = md.volrate;
numsamp_im = md.numvol_o;
smoothwindow_i = smoothwindow_sec*rateim;
method_resample = opts.method_resample;

try

    fool = mool
    load(pth_daq, 'daqdata_resamp')

catch


    %% load flyg_metadata and daqdata

    [expMetadata,trialMetadata, patternMetadata, fictracMetadata] = load_flyg_metadata(ids, pth_fldr);

    fndaq = dir(fullfile(pth_fldr,['*', ids.datefly_hyphen,'_daqData_*_trial_' sprintf( '%03d', ids.trialnum ) '.mat']));
    load(fullfile(pth_fldr,fndaq.name), 'trialData')

    md.dtmnb = fictracMetadata.fictracRate;
    try
        md.ratedaq = trialMetadata.daqSampRate;
    catch
        md.ratedaq = expMetadata.daqSampRate;
    end

    trialData = timetable2table(trialData);   % Copy important variables, converting units as needed


    %% check variables / set defaults

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
            [ daqdata_resamp.(fnnew), daqdata_resamp.([fnnew '_diff']) ] = process_DAQ(ftvars{ii}, trialData.(ftvars{ii}), method_resample, numsamp_im, inds, rateim, maxvolt, slopelen, slopeorder, ball, padlensec);
        end
    end

    % save(pth_daq, 'daqdata_resamp', '-v7.3', '-mat')


    %% epochinds

    md.t_ts_i = daqdata_resamp.Time{:}; %linspace(0, md.total_t, md.numvol_o+1)';md.t_ts_i(2:end);
    md.total_t = max(md.t_ts_i);
    sprintf("dti and volrate, respectively (should be the same or nearly the same): " + num2str(mean(diff(md.t_ts_i))) + ", " + num2str(1/md.volrate))

    if no_stim_epochs
        epochinds_ts_i = ones(numel(md.t_ts_i), 1);
        epochinds_ts_b = ones(numel(md.t_ts_b), 1);
    else
        if ~any(strcmp(daqdata_resamp.Properties.VariableNames, 'epochinds'))

            sprintf("warning, epochinds not saved to daq, using hard coded epochinds aligned by minimizing error")
            maxshiftsec = 5;
            maxshiftframes = maxshiftsec/md.dtmni;
            inc = 0.45;
            ft_misoffset_frames_all = -maxshiftframes:inc:maxshiftframes;
            hfg = figure;
            hax = axes('Parent', hfg);
            if datenum<20231119
                testepochind_all = [2 3];
            else
                testepochind_all = [2 3 5];
            end
            bestshiftind_allepochs = [];
            figframes = 0;
            for tei = 1:numel(testepochind_all)
                testepochind = testepochind_all(tei);
                criter = nan(numel(ft_misoffset_frames_all), 1);
                for fmsai = 1:numel(ft_misoffset_frames_all)
                    figframes = figframes+1;
                    
                    ft_misoffset_frames = ft_misoffset_frames_all(fmsai);
                    ft_misoffset_sec = md.dtmni*ft_misoffset_frames;
                    epochinds_ts_i = define_stim_epoch_indices(ft_misoffset_frames, md, datenum); %%%%%% DEFINE STIM EPOCH INDS IN THIS SCRIPT, WILL BE DEPRECATED WHEN SOCKET CODE SAVES EPOCH INDICES DURING EXPERIMENT   %%%%%%%%%  %%%%%%%%%

                    fu = daqdata_resamp.g4panels{1}(epochinds_ts_i==testepochind);
                    if testepochind==2 || testepochind==3
                        % fu = unwrap(fu); %makes it easier to see
                    end
                    % fu = cos(fu);
                    %fu = diff(diff(fu));
                    plot(hax,fu)
                    ylim(hax, [min(daqdata_resamp.g4panels{1}(:)) - abs(min(daqdata_resamp.g4panels{1}(:)))*0.3, max(daqdata_resamp.g4panels{1}(:)) + abs(max(daqdata_resamp.g4panels{1}(:)))*0.3])
                    if testepochind==2 || testepochind==3
                        fud2 = diff(diff(fu));
                        criter(fmsai) = numel(find(isoutlier(fud2))); %minimize num unique variables in diff, since open look should have only a couple (constant vel)
                    elseif testepochind==5
                        criter(fmsai) = var(cos(fu)); %minimize variance of x (or y) component of circular variable, this is offset with least error
                    end
                    title([criter(fmsai) ft_misoffset_frames ft_misoffset_sec])
                    fig2gif(hfg, figframes, [pth_fldr 'misoffset_.gif'])
                    
                    if fmsai==numel(ft_misoffset_frames_all)
                        if ~(min(diff(criter))<0 && max(diff(criter))>0)
                            error("error is monotonic, expand search range")
                        end
                        [~, bestshiftind_oneepoch] = min(criter);
                        bestshiftind_allepochs = [bestshiftind_allepochs bestshiftind_oneepoch];
                    end
                end
            end

            ft_misoffset_frames = mean(ft_misoffset_frames_all(bestshiftind_allepochs));
            [epochinds_ts_i, epochinds] = define_stim_epoch_indices(ft_misoffset_frames, md, datenum); %%%%%% DEFINE STIM EPOCH INDS IN THIS SCRIPT, WILL BE DEPRECATED WHEN SOCKET CODE SAVES EPOCH INDICES DURING EXPERIMENT   %%%%%%%%%  %%%%%%%%%

            for tei = 1:numel(testepochind_all)
                figframes = figframes+1;
                plot(hax, daqdata_resamp.g4panels{1}(epochinds_ts_i==testepochind_all(tei)))
                title([ft_misoffset_frames ft_misoffset_sec])
                fig2gif(hfg, figframes, [pth_fldr 'misoffset_.gif'])
            end

        end
    end

    md.epochinds_ts_i = epochinds_ts_i;

    naninds_i = epochinds_ts_i==epochinds.dark | epochinds_ts_i==epochinds.closedfinaldark; %dark gets nans

    % vis.raw = daqdata_resamp.cuePos{:}'; %cuePos is index into G4 frames (usually 192, but i've added one more for a dark frame)
    % vis.ang = vis.raw;
    % vis.ang(vis.ang == 193) = 192; %don't just replace all 193s with nan bc sometimes intended 192 is 193
    % vis.ang = vis.ang  / num_panel_frames * 2*pi - pi; %put in range -pi to pi, G4 frame 0 assigned to -pi
    % vis.ang_fictrac = daqdata_resamp.cueAngle{:}'; %saving fictrac's angle as convenience to make sure my vis.ang matches it
    % vis.angsd(naninds_i) = nan; %put nans where the cue doesn't exist (dark epoch)
    % vis.velrsd(naninds_i) = nan; %put nans where the cue doesn't exist (dark epoch)

    %% save and plot

    save(pth_daq, 'daqdata_resamp');


    if doplots

        numsamp_i_subset = 500;
        numsec_subset = numsamp_i_subset*md.dtmni;
        startsec_i_subset = round(md.t_ts_i(end) / 2); %arbitrarily in the middle
        plot_t_inds_sec = startsec_i_subset:startsec_i_subset+numsec_subset;

        t_ind_b = md.t_ts_b>plot_t_inds_sec(1) & md.t_ts_b<plot_t_inds_sec(end);
        t_ind_i = md.t_ts_i>plot_t_inds_sec(1) & md.t_ts_i<plot_t_inds_sec(end);

        ballang_unwrap = unwrap(ball.ang);
        ballang_unwrap = ballang_unwrap - ballang_unwrap(1);  %zero for plotting bc unwrapping can shift very similar values by 2pi
        ballangsu = unwrap(ball.angs);
        ballangsu = ballangsu - ballangsu(1); %zero for plotting bc unwrapping can shift very similar values by 2pi

        titopt = 'raw vs smoothed ball angle';
        figure; plot(ball.ang(t_ind_b)); hold on; plot(ball.angs(t_ind_b)); title(titopt)
        figure; plot(ballang_unwrap(t_ind_b)); hold on; plot(ballangsu(t_ind_b)); title(titopt)
        figure; plot(ballang_unwrap); hold on; plot(ballangsu); title(titopt)
        titopt = 'smoothed ball angle vs smoothed ball rot vel';
        figure; plot(ballangsu(t_ind_b)); yyaxis right; plot(ball.velrs(t_ind_b)); yline(0); title(titopt)
        figure; plot(ballangsu); yyaxis right; plot(ball.velrs); yline(0); title(titopt)
        titopt = 'smoothed ball angle vs smoothed ball rot vel';
        figure; plot(ballangsu(t_ind_b)); yyaxis right; plot(ball.velrs(t_ind_b)); yline(0); title(titopt)
        figure; plot(ballangsu); yyaxis right; plot(ball.velrs); yline(0); title(titopt)
        titopt = 'ball rot vel vs smoothed ball rot vel';
        figure; plot(ball.velr(t_ind_b)); hold on; plot(ball.velrs(t_ind_b)); yline(0); title(titopt)
        figure; plot(ball.velr); hold on; plot(ball.velrs); yline(0); title(titopt)


        cueang_unwrap = unwrap(vis.ang);
        cueang_unwrap = cueang_unwrap - cueang_unwrap(1);  %zero for plotting bc unwrapping can shift very similar values by 2pi
        cueangsu = unwrap(vis.angs);
        cueangsu = cueangsu - cueangsu(1); %zero for plotting bc unwrapping can shift very similar values by 2pi

        titopt = 'raw vs smoothed cue rot vel, behavior sampling';
        figure; plot(md.t_ts_b(t_ind_b), vis.velr(t_ind_b)); hold on; plot(md.t_ts_b(t_ind_b), vis.velrs(t_ind_b)); title(titopt)

        titopt = 'raw vs smoothed cue angle';
        figure; plot(vis.ang(t_ind_b)); hold on; plot(vis.angs(t_ind_b)); title(titopt)
        figure; plot(cueang_unwrap(t_ind_b)); hold on; plot(cueangsu(t_ind_b)); title(titopt)
        figure; plot(cueang_unwrap); hold on; plot(cueangsu); title(titopt)
        titopt = 'smoothed cue angle vs smoothed cue rot vel';
        figure; plot(cueangsu(t_ind_b)); yyaxis right; plot(vis.velrs(t_ind_b)); yline(0); title(titopt)
        figure; plot(cueangsu); yyaxis right; plot(vis.velrs); yline(0); title(titopt)
        % titopt = 'smoothed cue angle vs smoothed cue rot vel med filtered';
        % visvelrs_med = movmedian(vis.velrs, [8 8], 'omitnan');
        % figure; plot(cueangsu(t_ind_b)); yyaxis right; plot(visvelrs_med(t_ind_b)); yline(0); title(titopt)
        % figure; plot(cueangsu); yyaxis right; plot(visvelrs_med); yline(0); title(titopt)

        titopt = 'behavior vs imaging sampling of ball angle';
        figure; plot(md.t_ts_b(t_ind_b), ball.angs(t_ind_b)); hold on; plot(md.t_ts_i(t_ind_i), ball.angsd(t_ind_i)); title(titopt)
        figure; plot(md.t_ts_b, ball.angs); hold on; plot(md.t_ts_i, ball.angsd); title(titopt)
        titopt = 'behavior vs imaging sampling of cue angle';
        figure; plot(md.t_ts_b(t_ind_b), vis.angs(t_ind_b)); hold on; plot(md.t_ts_i(t_ind_i), vis.angsd(t_ind_i)); title(titopt)
        figure; plot(md.t_ts_b, vis.angs); hold on; plot(md.t_ts_i, vis.angsd); title(titopt)
        titopt = 'behavior vs imaging sampling of ball velocity';
        figure; plot(md.t_ts_b(t_ind_b), ball.velrs(t_ind_b)); hold on; plot(md.t_ts_i(t_ind_i), ball.velrsd(t_ind_i)); title(titopt)
        figure; plot(md.t_ts_b, ball.velrs); hold on; plot(md.t_ts_i, ball.velrsd); title(titopt)
        titopt = 'behavior vs imaging sampling of cue velocity';
        figure; plot(md.t_ts_b(t_ind_b), vis.velrs(t_ind_b)); hold on; plot(md.t_ts_i(t_ind_i), vis.velrsd(t_ind_i)); title(titopt)
        figure; plot(md.t_ts_b, vis.velrs); hold on; plot(md.t_ts_i, vis.velrsd); title(titopt)

        figure; plot(md.t_ts_i, epochinds_ts_i); ylim([0 max(epochinds_ts_i)+1]); xlim([0 floor(md.total_t)]); title('stim epochs')
        hold on; plot(md.t_ts_b, epochinds_ts_b); ylim([0 max(epochinds_ts_b)+1]); xlim([0 floor(md.total_t)]); title('stim epochs (b)')


    end

end

