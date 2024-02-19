
function [resp, alpha] = cx_map_rois_to_head_direction_deprecated(resp, visang, visvel, md, lnth, pvar, halfcent, fn_prefix)


%% cx_nonlinearly_transform_response before linear fit


%resp = cx_nonlinearly_transform_response(resp)


%% find functional alpha (preferred stim features) with stim/response linear fit


epochinds_lfit = [4]; %restrict stimulus epochs for linear fit
stim_norm_method = 'none';
resp_norm_method = 'rescale'; %how to normalize each response prior to fitting
fit_method = 'svd'; %'svd';
fitlen_sec = 0.4; %seconds
doplots_linfit = 1;
stim_is_circular = 1;

rescale_vel = 'none'; %'sphere', 'one', 'none';  'sphere' considers position and velocity to be part of same structure(?), so far i've not seen this change qualitative results (except for extremely weak correlations might change a little)
switch rescale_vel
    case 'sphere'
        vel_rescale_mag = pi/2;
        cuevel_rscl = visvel;
        cuevel_rscl(visvel<=0) = rescale(cuevel_rscl(visvel<=0), -vel_rescale_mag, 0); %rescale velocity independently for each direction
        cuevel_rscl(visvel>=0) = rescale(cuevel_rscl(visvel>=0), 0, vel_rescale_mag); %rescale velocity independently for each direction
    case 'one'
        vel_rescale_mag = 1;
        cuevel_rscl = visvel;
        cuevel_rscl(visvel<=0) = rescale(cuevel_rscl(visvel<=0), -vel_rescale_mag, 0); %rescale velocity independently for each direction
        cuevel_rscl(visvel>=0) = rescale(cuevel_rscl(visvel>=0), 0, vel_rescale_mag); %rescale velocity independently for each direction
    case 'none'
        cuevel_rscl = visvel;
end

stim = [cos(visang) sin(visang) cuevel_rscl]';


[lfittmp, ~] = cx_linfit(md, stim, resp, fitlen_sec, pvar, ...
    stim_norm_method, resp_norm_method, epochinds_lfit, fit_method, ...
    stim_is_circular, fn_prefix, doplots_linfit);

clear lfit 
for ri = 1:size(lfittmp, 1)
    if size(lfittmp, 2)==2
        lfit(ri,1,:) = atan2(lfittmp(ri,2,:), lfittmp(ri,1,:)); %cart2pol(x,y) same as atan2(y,x)
    elseif size(lfittmp, 2)==3
        if strcmp(rescale_vel, 'sphere')
            [lfit(ri,1,:), lfit(ri,2,:)] = cart2sph(lfittmp(ri,1,:), lfittmp(ri,2,:), lfittmp(ri,3,:));
        else
            lfit(ri,1,:) = atan2(lfittmp(ri,2,:), lfittmp(ri,1,:));
            lfit(ri,2,:) = lfittmp(ri,3,:);
        end
    end
end

%% 

if doplots_linfit

    figure; subplot(2,1,1); imagesc(squeeze(lfit(:,1,:)))
    subplot(2,1,2); imagesc(squeeze(lfit(:,2,:)))
    saveas( gcf, [fn_prefix '_linmodspacetime_.png'])

    lfitplotrois_numrois = 20;
    lfitplotrois_inds = round(linspace(1, size(lfit, 1), lfitplotrois_numrois));
    lfitrois = squeeze(lfit(lfitplotrois_inds, 1,:));
    filenameGIF_resp = [fn_prefix '_1drfs_' num2str(epochinds_lfit) '_.gif'];
    hfg = figure;
    for lfri = 1:size(lfitrois, 1)
        %pl1 = plot(unwrap(lfitrois(lfri,:) - lfitrois(lfri,1)));
        %pl1 = plot(unwrap(lfitrois(lfri,:)));
        pl1 = plot(lfitrois(lfri,:));
        %pl1 = plot(squeeze(lfitroisall(lfri,:,:)));
        %ylim([-2*pi 2*pi])
        ylim([-pi pi])
        %pause(0.5)

        [imind, cm] = rgb2ind(frame2im(getframe(hfg)),128);
        if lfri == 1
            imwrite(imind,cm,filenameGIF_resp, 'DelayTime', 0, 'Loopcount',inf);
        else
            imwrite(imind,cm,filenameGIF_resp,'DelayTime', 0,'WriteMode','append');
        end
        %delete(pl1);

    end


end
%% 

lfit = mean(lfit, 3);
lfit = lfit';
preferred_head_position = lfit(1,:);
preferred_velocity = lfit(2,:);

if doplots_linfit

    figure; plot(preferred_head_position)
    saveas( gcf, [fn_prefix '_linmodhdmeantime_.png'])

    figure; scatter(preferred_head_position, preferred_velocity)
    saveas( gcf, [fn_prefix '_linmodmeantime_.png'])
end


%% resample functional alpha

["resampling original numrois " num2str(size(resp, 1))]

resample_smoothfac = 1;
doplots2 = 0;

% if size(resp,1)<numroi_func*2
%     "TOO FEW ROIS FOR RESAMPLING COMPASS"
%     error
% end

rois_left = find(preferred_velocity<0);
rois_right = find(preferred_velocity>0);

[dfc_left, alpha_left] = cx_resample_compass(resp(rois_left,:), preferred_head_position(rois_left), halfcent, resample_smoothfac, doplots2);
[dfc_right, alpha_right] = cx_resample_compass(resp(rois_right,:), preferred_head_position(rois_right), halfcent, resample_smoothfac, doplots2);

resp = cat(1, dfc_left, dfc_right);
alpha = [alpha_left alpha_right];


close all

