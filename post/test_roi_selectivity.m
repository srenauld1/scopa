function [roi_is_not_selective, tuning] = ...
    test_roi_selectivity(resp, cue, ball, md, ...
    region_extraction, filename_save, doplots)


tuning.preferred_velocity_cue = nan;
tuning.gof_velocity_cue = nan;
tuning.preferred_velocity_ball = nan;
tuning.gof_velocity_ball = nan;
tuning.preferred_hd_cue = nan;
tuning.gof_hd_cue = nan;

if strcmp(region_extraction, 'nol') | strcmp(region_extraction, 'nor') %we want to separate left and right so don't make it too low

    epochinds_lfit = [1 2 3 4]; %restrict stimulus epochs for linear fit
    epochinds_lfit = [1 4]; %restrict stimulus epochs for linear fit
    stim_norm_method = 'none';
    resp_norm_method = 'rescale'; %how to normalize each response prior to fitting
    linfit_method = 'svd';
    fitlen = 0.5; %seconds
    pvar = 0.9; %dimensionality reduction in svd if linfit_method=svd (how much variance to keep)
    stim_is_circular = 0;

    vel_rescale_mag = 1;
    cuevel = cue.vel_r_sm_rsmp;
    cuevel_rscl = cuevel; %copy so 0 gets rescaled for each direction
    cuevel_rscl(cuevel<=0) = rescale(cuevel_rscl(cuevel<=0), -vel_rescale_mag, 0); %rescale velocity independently for each direction
    cuevel_rscl(cuevel>=0) = rescale(cuevel_rscl(cuevel>=0), 0, vel_rescale_mag); %rescale velocity independently for each direction

    [lfit_cue, ~] = linfit_scopa(md, cuevel_rscl, resp, fitlen, pvar, ...
        stim_norm_method, resp_norm_method, epochinds_lfit, linfit_method, ...
        stim_is_circular, filename_save, doplots);

    tuning.preferred_velocity_cue = mean(lfit_cue(:));
    tuning.gof_velocity_cue = norm(vec(lfit_cue), 1);

    ballvel = ball.vel_r_sm_rsmp;
    ballvel_rscl = ballvel; %copy so 0 gets rescaled for each direction
    ballvel_rscl(ballvel<=0) = rescale(ballvel_rscl(ballvel<=0), -vel_rescale_mag, 0); %rescale velocity independently for each direction
    ballvel_rscl(ballvel>=0) = rescale(ballvel_rscl(ballvel>=0), 0, vel_rescale_mag); %rescale velocity independently for each direction

    [lfit_ball, ~] = linfit_scopa(md, ballvel_rscl, resp, fitlen, pvar, ...
        stim_norm_method, resp_norm_method, epochinds_lfit, linfit_method, ...
        stim_is_circular, filename_save, doplots);

    tuning.preferred_velocity_ball = mean(lfit_ball(:));
    tuning.gof_velocity_ball = norm(vec(lfit_ball), 1);

    %nor prefers positive vel, nol prefers negative
    %0.1 might work for tuning strength thresh
    if strcmp(region_extraction, 'nol') & (tuning.preferred_velocity_ball<0 | tuning.gof_velocity_ball>0.1)
        roi_is_not_selective = 0;
    elseif strcmp(region_extraction, 'nor') & (tuning.preferred_velocity_ball>0 | tuning.gof_velocity_ball>0.1)
        roi_is_not_selective = 0;
    end


elseif strcmp(region_extraction, 'gal') | strcmp(region_extraction, 'gar') | strcmp(region_extraction, 'pb') %auto mask tends to not capture deepest z (??) and nothing else is near (??) so make it low

    %% 

%     epochinds_lfit = [1]; %restrict stimulus epochs for linear fit
%     stim_norm_method = 'none';
%     resp_norm_method = 'rescale'; %how to normalize each response prior to fitting
%     linfit_method = 'lm'; %'poly11';
%     fitlen = 2; %seconds
%     pvar = 0.9; %dimensionality reduction in svd if linfit_method=svd (how much variance to keep)
%     stim_is_circular = 1;
% 
%     cueang = cue.ang_sm_rsmp;
% 
%     stim = [cos(cueang(:)) sin(cueang(:))]';
% 
%     doplots = 0;
%      [lfit_cue, gof_mse, gof_ar] = linfit_scopa(md, stim, resp, fitlen, pvar, ...
%         stim_norm_method, resp_norm_method, epochinds_lfit, linfit_method, ...
%         stim_is_circular, filename_save, doplots);
% 
% %% 
% 
%     tuning.preferred_hd_cue = mean(atan2(lfit_cue(:,2,:), lfit_cue(:,1,:)), 3); %cart2pol(x,y) same as atan2(y,x)
%     tuning.gof_hd_cue_mse = gof_mse;
%     tuning.gof_hd_cue_ar = gof_ar;

    roi_is_not_selective = 0;
    % if (tuning.preferred_hd_cue<0 | tuning.gof_hd_cue>0.1)
    %     roi_is_not_selective = 0;
    % end

else

    roi_is_not_selective = 0;



end



