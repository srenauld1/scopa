
function [md, stim] = load_fictrac(datenum, flynum, trialnum, md, pth_fictrac, fictracopts)


%note extracting velocity for what should be constant velocity cue can have
%spikes because of noise in the acquisition/display, zoom in and you will see it
% so there's a balance between large slope filters, which lose information
% but fix noise, and short filters which do oppoisite 

%notes about cue artifacts
% frame 193 (when there is one) is darkness at end of trial, just replace with 192 for now as dummy (to not affect unwrapping), then fix later
% (do not replace with nan because sometimes intended 192 is assigned 193 presumably because of electrical noise, ie 193 doesn't just occur during the dark period at the end, even though it's supposed to)

%in transitioning from max to min (eg 192 to 0), or vice versa, there is sometimes an intermediate value,
% presumably a sample taken as the voltage makes the large transition,
% so smooth those out with tiny window in the unwrapped stim, otherwise there are spikes


%RIGHT NOW NOW CROPTIMEINDS FOR FICTRAC DATA THE WAY I DID FOR CLANDININ STIM DATA

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
    [ftData_dat] = imaging_fictrac_pipeline(pth_ftfldr, 0, 0, 0);
    load(pth_fictrac)
end

if size(ftData_DAQ, 1)>1
    ftData_DAQ = ftData_DAQ(trialnum, :);
end

md.trialtime = ftData_DAQ.trialTime{:};
md.dts_b = [nan; seconds(diff(md.trialtime))];
md.dtmnb = mean(seconds(diff(md.trialtime)));

md.tb = md.dtmnb * [1:length(ftData_DAQ.intHD{1})];
md.total_t = max(md.tb);
md.ti = linspace(0, md.total_t, md.numvol_o+1)';
md.ti = md.ti(2:end);
md.dtmni = mean(diff(md.tb)); %close to 1/md.volrate;

if datenum<20231119
    dark_epoch_time_start = max(md.trialtime(:))-seconds(dark_stim_end_duration);
else
    dark_epoch_time_start = 1e9;
    dark_stim_end_duration = 0;
end

smoothwindow_b = smoothwindow_sec/md.dtmnb;
smoothwindow_i = smoothwindow_sec/md.dtmni;

naninds_i = md.ti>seconds(dark_epoch_time_start); %dark gets nans
naninds_b = md.tb>seconds(dark_epoch_time_start); %dark gets nas

ball.vel_f = ftData_DAQ.velFor{:}; 
ball.spd_f = abs(ball.vel_f);
ball.vel_r = ftData_DAQ.velYaw{:};
ball.spd_r = abs(ball.vel_r);
ball.inthd = ftData_DAQ.intHD{:};
ball.ang = wrapToPi(ball.inthd);

if smoothwindow_b
    ball.vel_f_sm = smoothdata(ball.vel_f, 'gaussian', smoothwindow_b, 'omitnan');
    ball.ang_sm = smooth_circular_variable(ball.ang, smoothwindow_b);
    ball.vel_r_sm = differentiate_circular_variable(ball.ang_sm, md.dtmnb, slopelen, slopeorder);
end

vis.raw = ftData_DAQ.cuePos{:}'; %cuePos is index into G4 frames (usually 192, but i've added one more for a dark frame)

vis.ang = vis.raw;
vis.ang(vis.ang == 193) = 192; %don't just replace all 193s with nan bc sometimes intended 192 is 193
vis.ang = vis.ang  / (num_panel_frames + 1) * 2*pi - pi; %put in range -pi to pi, frame 0 assigned to -pi

vis.ang_fictrac = ftData_DAQ.cueAngle{:}'; %saving fictrac's angle as convenience to make sure my vis.ang matches it 

vis.vel_r = differentiate_circular_variable(vis.ang, md.dtmnb, slopelen, slopeorder);

if smoothwindow_b
    vis.ang_sm = smooth_circular_variable(vis.ang, smoothwindow_b);
    vis.vel_r_sm = differentiate_circular_variable(vis.ang_sm, md.dtmnb, slopelen, slopeorder);
end

iscircular = 1;
vis.ang_sm_rsmp =downsample_variable(md, vis.ang_sm, iscircular); %downsample into imaging rate
ball.ang_sm_rsmp =downsample_variable(md, ball.ang_sm, iscircular); %downsample into imaging rate
iscircular = 0;
vis.vel_r_sm_rsmp =downsample_variable(md, vis.vel_r_sm, iscircular); %downsample into imaging rate
ball.vel_r_sm_rsmp =downsample_variable(md, ball.vel_r_sm, iscircular); %downsample into imaging rate
ball.vel_f_sm_rsmp =downsample_variable(md, ball.vel_f_sm, iscircular); %downsample into imaging rate

vis.ang_sm(naninds_b) = nan; %put nans where the cue doesn't exist (dark epoch)
vis.vel_r_sm(naninds_b) = nan; %put nans where the cue doesn't exist (dark epoch)
vis.ang_sm_rsmp(naninds_i) = nan; %put nans where the cue doesn't exist (dark epoch)
vis.vel_r_sm_rsmp(naninds_i) = nan; %put nans where the cue doesn't exist (dark epoch)

if no_stim_epochs
    trialepochinds_i = ones(length(md.ti), 1);
    trialepochinds_b = ones(length(md.tb), 1);
else
    
    if datenum<20231119
        define_stim_epoch_indices %%%%%% DEFINE STIM EPOCH INDS IN THIS SCRIPT, WILL BE DEPRECATED WHEN SOCKET CODE SAVES EPOCH INDICES DURING EXPERIMENT   %%%%%%%%%
    else
        define_stim_epoch_indices_2 %%%%%% DEFINE STIM EPOCH INDS IN THIS SCRIPT, WILL BE DEPRECATED WHEN SOCKET CODE SAVES EPOCH INDICES DURING EXPERIMENT   %%%%%%%%%  %%%%%%%%%
    end

end
md.trialepochinds_i = trialepochinds_i;
md.trialepochinds_b = trialepochinds_b;

%organize_epochs(md, vis, 'imaging', [0 35]) %unfinished

stim.vis = vis;
stim.ball = ball;

if doplots

    numsamp_i_subset = 500;
    numsec_subset = numsamp_i_subset*md.dtmni;
    startsec_i_subset = round(md.ti(end) / 2); %arbitrarily in the middle
    plot_t_inds_sec = startsec_i_subset:startsec_i_subset+numsec_subset;

    t_ind_b = md.tb>plot_t_inds_sec(1) & md.tb<plot_t_inds_sec(end);
    t_ind_i = md.ti>plot_t_inds_sec(1) & md.ti<plot_t_inds_sec(end);

    ballang_unwrap = unwrap(ball.ang);
    ballang_unwrap = ballang_unwrap - ballang_unwrap(1);  %zero for plotting bc unwrapping can shift very similar values by 2pi
    ballangsm_unwrap = unwrap(ball.ang_sm);
    ballangsm_unwrap = ballangsm_unwrap - ballangsm_unwrap(1); %zero for plotting bc unwrapping can shift very similar values by 2pi

    titopt = 'raw vs smoothed ball angle';
    figure; plot(ball.ang(t_ind_b)); hold on; plot(ball.ang_sm(t_ind_b)); title(titopt)
    figure; plot(ballang_unwrap(t_ind_b)); hold on; plot(ballangsm_unwrap(t_ind_b)); title(titopt)
    figure; plot(ballang_unwrap); hold on; plot(ballangsm_unwrap); title(titopt)
    titopt = 'smoothed ball angle vs smoothed ball rot vel';
    figure; plot(ballangsm_unwrap(t_ind_b)); yyaxis right; plot(ball.vel_r_sm(t_ind_b)); yline(0); title(titopt)
    figure; plot(ballangsm_unwrap); yyaxis right; plot(ball.vel_r_sm); yline(0); title(titopt)
    titopt = 'smoothed ball angle vs smoothed ball rot vel';
    figure; plot(ballangsm_unwrap(t_ind_b)); yyaxis right; plot(ball.vel_r_sm(t_ind_b)); yline(0); title(titopt)
    figure; plot(ballangsm_unwrap); yyaxis right; plot(ball.vel_r_sm); yline(0); title(titopt)
    titopt = 'ball rot vel vs smoothed ball rot vel';
    figure; plot(ball.vel_r(t_ind_b)); hold on; plot(ball.vel_r_sm(t_ind_b)); yline(0); title(titopt)
    figure; plot(ball.vel_r); hold on; plot(ball.vel_r_sm); yline(0); title(titopt)


    cueang_unwrap = unwrap(vis.ang);
    cueang_unwrap = cueang_unwrap - cueang_unwrap(1);  %zero for plotting bc unwrapping can shift very similar values by 2pi
    cueangsm_unwrap = unwrap(vis.ang_sm);
    cueangsm_unwrap = cueangsm_unwrap - cueangsm_unwrap(1); %zero for plotting bc unwrapping can shift very similar values by 2pi

    titopt = 'raw vs smoothed cue rot vel, behavior sampling';
    figure; plot(md.tb(t_ind_b), vis.vel_r(t_ind_b)); hold on; plot(md.tb(t_ind_b), vis.vel_r_sm(t_ind_b)); title(titopt)

    titopt = 'raw vs smoothed cue angle';
    figure; plot(vis.ang(t_ind_b)); hold on; plot(vis.ang_sm(t_ind_b)); title(titopt)
    figure; plot(cueang_unwrap(t_ind_b)); hold on; plot(cueangsm_unwrap(t_ind_b)); title(titopt)
    figure; plot(cueang_unwrap); hold on; plot(cueangsm_unwrap); title(titopt)
    titopt = 'smoothed cue angle vs smoothed cue rot vel';
    figure; plot(cueangsm_unwrap(t_ind_b)); yyaxis right; plot(vis.vel_r_sm(t_ind_b)); yline(0); title(titopt)
    figure; plot(cueangsm_unwrap); yyaxis right; plot(vis.vel_r_sm); yline(0); title(titopt)
    % titopt = 'smoothed cue angle vs smoothed cue rot vel med filtered';
    % visvelrsm_med = movmedian(vis.vel_r_sm, [8 8], 'omitnan');
    % figure; plot(cueangsm_unwrap(t_ind_b)); yyaxis right; plot(visvelrsm_med(t_ind_b)); yline(0); title(titopt)
    % figure; plot(cueangsm_unwrap); yyaxis right; plot(visvelrsm_med); yline(0); title(titopt)

    titopt = 'behavior vs imaging sampling of ball angle';
    figure; plot(md.tb(t_ind_b), ball.ang_sm(t_ind_b)); hold on; plot(md.ti(t_ind_i), ball.ang_sm_rsmp(t_ind_i)); title(titopt)
    figure; plot(md.tb, ball.ang_sm); hold on; plot(md.ti, ball.ang_sm_rsmp); title(titopt)
    titopt = 'behavior vs imaging sampling of cue angle';
    figure; plot(md.tb(t_ind_b), vis.ang_sm(t_ind_b)); hold on; plot(md.ti(t_ind_i), vis.ang_sm_rsmp(t_ind_i)); title(titopt)
    figure; plot(md.tb, vis.ang_sm); hold on; plot(md.ti, vis.ang_sm_rsmp); title(titopt)
    titopt = 'behavior vs imaging sampling of ball velocity';
    figure; plot(md.tb(t_ind_b), ball.vel_r_sm(t_ind_b)); hold on; plot(md.ti(t_ind_i), ball.vel_r_sm_rsmp(t_ind_i)); title(titopt)
    figure; plot(md.tb, ball.vel_r_sm); hold on; plot(md.ti, ball.vel_r_sm_rsmp); title(titopt)
    titopt = 'behavior vs imaging sampling of cue velocity';
    figure; plot(md.tb(t_ind_b), vis.vel_r_sm(t_ind_b)); hold on; plot(md.ti(t_ind_i), vis.vel_r_sm_rsmp(t_ind_i)); title(titopt)
    figure; plot(md.tb, vis.vel_r_sm); hold on; plot(md.ti, vis.vel_r_sm_rsmp); title(titopt)


    figure; plot(md.ti, trialepochinds_i); ylim([0 max(trialepochinds_i)+1]); xlim([0 floor(md.total_t)]); title('stim epochs')
    hold on; plot(md.tb, trialepochinds_b); ylim([0 max(trialepochinds_b)+1]); xlim([0 floor(md.total_t)]); title('stim epochs (b)')


end