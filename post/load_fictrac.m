
function [md, ball, vis] = load_fictrac(ids, md, pth_fictrac, fictracopts)

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


%RIGHT NOW NOW CROPTIMEINDS FOR FICTRAC DATA THE WAY I DID FOR CLANDININ STIM DATA

datenum = ids.datenum;
flynum = ids.flynum;
trialnum = ids.trialnum;

dark_stim_end_duration = fictracopts.dark_stim_end_duration;
num_panel_frames = fictracopts.num_panel_frames;
smoothwindow_sec = fictracopts.smoothwindow_sec;
slopelen = fictracopts.slopelen;
slopeorder = fictracopts.slopeorder;
no_stim_epochs = fictracopts.no_stim_epochs;
doplots = fictracopts.doplots;

try
    load(pth_fictrac)
catch
    [pth_ftfldr, ~, ~] = fileparts(pth_fictrac);
    [ftData_dat] = fittrac_im_pre(pth_ftfldr);
    load(pth_fictrac)
end

if size(ftData_DAQ, 1)>1
    ftData_DAQ = ftData_DAQ(trialnum, :);
end

md.trialtime = ftData_DAQ.trialTime{:};
md.dts_b = [nan; seconds(diff(md.trialtime))];
md.dtmnb = mean(seconds(diff(md.trialtime)));

md.t_ts_b = md.dtmnb * [1:numel(ftData_DAQ.intHD{1})]';
md.total_t = max(md.t_ts_b);
md.t_ts_i = linspace(0, md.total_t, md.numvol_o+1)';
md.t_ts_i = md.t_ts_i(2:end); %2:end rather than 1:end-1 since each timestamp marks the end of the sample
md.dtmni = mean(diff(md.t_ts_i)); %close to 1/md.volrate;

if datenum<20231119
    dark_epoch_time_start = max(md.trialtime(:))-seconds(dark_stim_end_duration);
else
    dark_epoch_time_start = 1e9;
    dark_stim_end_duration = 0;
end

smoothwindow_b = smoothwindow_sec/md.dtmnb;
smoothwindow_i = smoothwindow_sec/md.dtmni;

naninds_i = md.t_ts_i>seconds(dark_epoch_time_start); %dark gets nans
naninds_b = md.t_ts_b>seconds(dark_epoch_time_start); %dark gets nas

ball.velf = ftData_DAQ.velFor{:}; 
ball.spdf = abs(ball.velf);
ball.velr = ftData_DAQ.velYaw{:};
ball.spdr = abs(ball.velr);
ball.angint = ftData_DAQ.intHD{:};
ball.ang = wrapToPi(ball.angint);

if smoothwindow_b
    ball.velfs = smoothdata(ball.velf, 'gaussian', smoothwindow_b, 'omitnan');
    ball.angs = smooth_circular_variable(ball.ang, smoothwindow_b);
    ball.velrs = differentiate_circular_variable(ball.angs, md.dtmnb, slopelen, slopeorder);
end

vis.raw = ftData_DAQ.cuePos{:}'; %cuePos is index into G4 frames (usually 192, but i've added one more for a dark frame)

vis.ang = vis.raw;
vis.ang(vis.ang == 193) = 192; %don't just replace all 193s with nan bc sometimes intended 192 is 193
vis.ang = vis.ang  / num_panel_frames * 2*pi - pi; %put in range -pi to pi, G4 frame 0 assigned to -pi

vis.ang_fictrac = ftData_DAQ.cueAngle{:}'; %saving fictrac's angle as convenience to make sure my vis.ang matches it 

vis.velr = differentiate_circular_variable(vis.ang, md.dtmnb, slopelen, slopeorder);

if smoothwindow_b
    vis.angs = smooth_circular_variable(vis.ang, smoothwindow_b);
    vis.velrs = differentiate_circular_variable(vis.angs, md.dtmnb, slopelen, slopeorder);
end

iscircular = 1;
vis.angsd = downsample_variable(md, vis.angs, iscircular); %downsample into imaging rate
ball.angsd = downsample_variable(md, ball.angs, iscircular); %downsample into imaging rate
iscircular = 0;
vis.velrsd = downsample_variable(md, vis.velrs, iscircular); %downsample into imaging rate
ball.velrsd = downsample_variable(md, ball.velrs, iscircular); %downsample into imaging rate
ball.velfsd = downsample_variable(md, ball.velfs, iscircular); %downsample into imaging rate

vis.angs(naninds_b) = nan; %put nans where the cue doesn't exist (dark epoch)
vis.velrs(naninds_b) = nan; %put nans where the cue doesn't exist (dark epoch)
vis.angsd(naninds_i) = nan; %put nans where the cue doesn't exist (dark epoch)
vis.velrsd(naninds_i) = nan; %put nans where the cue doesn't exist (dark epoch)

if no_stim_epochs
    epochinds_ts_i = ones(length(md.t_ts_i), 1);
    epochinds_ts_b = ones(length(md.t_ts_b), 1);
else
    
    if datenum<20231119
        define_stim_epoch_indices %%%%%% DEFINE STIM EPOCH INDS IN THIS SCRIPT, WILL BE DEPRECATED WHEN SOCKET CODE SAVES EPOCH INDICES DURING EXPERIMENT   %%%%%%%%%
    else
    %% 
    
        ft_misoffset = 2.26;
        define_stim_epoch_indices_2 %%%%%% DEFINE STIM EPOCH INDS IN THIS SCRIPT, WILL BE DEPRECATED WHEN SOCKET CODE SAVES EPOCH INDICES DURING EXPERIMENT   %%%%%%%%%  %%%%%%%%%
        fu = vis.ang(epochinds_ts_b==5);
        figure; plot(fu)
        title(numel(find(fu~=fu(1))))
    %% 
    
    end

end
md.epochinds_ts_i = epochinds_ts_i;
md.epochinds_ts_b = epochinds_ts_b;

%organize_epochs(md, vis, 'imaging', [0 35]) %unfinished


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