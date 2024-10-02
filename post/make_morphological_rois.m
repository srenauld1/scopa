function [roidat, resp] = make_morphological_rois(stack, opts_mroi, ...
    ti, imper, xwid, ywid, zwid, pth_mroi, pth_tmpfiles, stack_hires, map_hires_lores, ...
    regionex, parstr_mroi, roimaskman_allchan)


%if you want to automate rois from multiple drawn regions, use different
%regionex (they can be analzed together after extracting voluem
%responses), or choose to draw discontiguous roi and that one can get
%passed to make_morphological_rois_automated


% for num_mroi argument
% if number is passed, method is automated
% you can have zero morph rois, which means any functional rois will not get morph selection
% you can have one morph roi, which will use edge detection to refine and functional rois will get that selection
% you can have more than 1 morph roi, which will create automated rois (either with or without hires stack), and those are bad for functional roi selection
% if more than zero automated morph rois, option to use manually drawn roi
% to help automation (loops over each drawn roi)
% if string 'manual' is passed
% rois are drawn, either on the mean image (what is drawn is projected through z), or on each z slice

%regardless, 3d centroids of each morph roi are found (if zero, then whole fov centroid)


% create morphological rois
% using the mean-time and mean-z projection of the data,
% manually create 2d mask (roimaskman)
% that 2d mask is projected into a 3d mask (mask_mroi_all_simple)
% that is refined using chosen method (edge detection, global threshold, etc)
% if creating multiple morphological rois, the 3d mask is refined using
% a high-z-res version of the data, and the mask is mapped back to original resolution
% find the morphological roi centroids (roicen) of the final 3d mask,
% and all voxels that are nearest each centroid (roiwt)
% if you draw multiple rois in roimaskman, a different mask_mroi_all_simple will be
% made for each, but the 3d refining code cannot accommodate
% multiple drawn rois currently, so do not do this;
% if you want multiple rois within the fov passed to this function,
% call this function (make_morphological_rois)
% again with the same inputs, but draw a different single 2d roi,
% and assign the outputs of this function a different name (outside this function)

%roiwt can be single when it's weighted, boolean otherwise

%% params

if exist('roimaskman_allchan', 'var') %if passing in a morph roi mask (interactive mode)
    roimaskman_allchan = {roimaskman_allchan};
    maskinput = 1;
    use_drawn_rois = 0;
    num_mroi_auto = 0;
    normopts = opts_mroi.norm;
    hsvopt.do = 0;
    olayopt.do = 0;
    do_other_plots = 0;
else
    maskinput = 0;
    use_drawn_rois = opts_mroi.use_drawn_rois.(regionex);
    num_mroi_auto = opts_mroi.auto.num_mroi_auto.(regionex);
    normopts = opts_mroi.norm;
    hsvopt = opts_mroi.hsvopt;
    olayopt = opts_mroi.olayopt;
    do_other_plots = opts_mroi.do_other_plots;
end

chandraw = opts_mroi.chandraw;
chancopy = opts_mroi.chancopy;
channorm = opts_mroi.channorm;
dowav = opts_mroi.dowav;
autoopts = opts_mroi.auto;


pth_mroi_prefix = pth_mroi(1:end-4);
numchan = size(stack,5);

stackmnt = mean(stack, 4, 'native');

%% draw rois (polygons/polyhedra)

if ~maskinput
    roimaskman_allchan = repmat({ones(size(stack,1), size(stack,2), size(stack,3), 'logical')}, [numchan, 1]);
    if use_drawn_rois
        for c = 1:numchan
            if ismember(c,chandraw)
                pth_mroi_manual_prefix = erase(pth_mroi_prefix, ['_' parstr_mroi]); %different prefix since the parstr_mroi are irrelevant for manually drawn rois, allowing manually drawn to be used for different parstr_mroi
                pth_mroi_manual_prefix = erase(pth_mroi_manual_prefix, ['_morph']); %string 'morph' is redundant here, since this has suffix manual
                pth_roimaskman = [pth_mroi_manual_prefix 'chn' num2str(c) '_roimaskman_.mat'];
                try
                    roimaskman = struct2cell(load(pth_roimaskman));
                    roimaskman = roimaskman{1};
                    if all(roimaskman(:)==1)
                        sprintf(['WARNING, MASK MANUAL CHANNEL' num2str(c) ' IS ALL ONES FOR REGION: ' regionex])
                    end
                catch
                    flag_limit_one_manual_roi = 0;
                    if num_mroi_auto>1
                        flag_limit_one_manual_roi = 1;
                    end
                    roimaskman = drawrois(stack(:,:,:,:,c), regionex, pth_tmpfiles, flag_limit_one_manual_roi);
                    save(pth_roimaskman, 'roimaskman', '-v7.3', '-mat')
                end
                roimaskman_allchan{c} = roimaskman;
            end
        end
        if ~isempty(chancopy) && numchan==2
            chanreceive = setxor(chancopy, [1,2]);
            sprintf("chancopy is " + num2str(chancopy) + "; \nCOPYING ANY DRAWN ROIS FROM CHANNEL " + num2str(chancopy) + " ONTO CHANNEL " + num2str(chanreceive));
            if all(roimaskman_allchan{chancopy}==1, 'all') && ~all(roimaskman_allchan{chanreceive}==1, 'all')
                sprintf("warning projecting a manual mask of all ones onto a manual mask that is not all ones; you may not intend this");
            end
            roimaskman_allchan(chanreceive) = roimaskman_allchan(chancopy);
        end
    end
end



%% make morphological roi mask (from manual mask plus automated mask, or just manual mask, or just automated mask), and compute some roi info and save in struct roidat


for c = 1:numchan
    if ismember(c,autoopts.chan)
        roimaskman = roimaskman_allchan{c};
        stackmnt_tmp = stackmnt(:,:,:,:,c);
        num_mroi_manual = size(roimaskman, 4);
        pth_mroidat = [pth_mroi_prefix 'chn' num2str(c) '_mroidat_.mat'];
        try
            mo=mo
            load(pth_mroidat, 'roidat');
        catch
            if num_mroi_manual>1 || num_mroi_auto==0
                num_mroi = num_mroi_manual;
                if num_mroi_auto>0
                    error(sprintf(['ERROR \n' ...
                        'num_mroi_manual is greater than one AND num_mroi_auto is greater than zero \n' ...
                        'DELETE OR RENAME pth_roimaskman AND DRAW MANUAL MORPHOLOGICAL ROIS AGAIN, \n' ...
                        'OR KEEP MANUAL MORPHOLOGICAL ROIS AND REQUEST 0-1 AUTOMATED MORPHOLOGICAL ROIS']))
                end
                roiwt = zeros(num_mroi, numel(sum(roimaskman, 4)), 'logical');  %initialize a logical matrix that is size (centroids, voxels)
                for mi = 1:num_mroi
                    tmp = roimaskman(:,:,:,mi);
                    [maskytmp, maskxtmp, maskztmp] = ind2sub(size(tmp), find(tmp));
                    roiwt(mi, sub2ind(size(tmp), maskytmp, maskxtmp, maskztmp)) = true; %indices of each roi
                end
                roicen = find_roi_centroids(roimaskman);
                sprintf("WARNING,\n" + ...
                    "if sort_roi_method is 'morph_long_axis', rois will be sorted by drawn roi index, not morph long axis, \n" + ...
                    "since determining the long axis of extraction currently requires automated morph roi extraction")
            else
                [roiwt, roicen, num_mroi] = ...
                    make_morphological_rois_automated(stackmnt_tmp, roimaskman, num_mroi_auto, ...
                    xwid, ywid, zwid, stack_hires, map_hires_lores, pth_mroi_prefix, ...
                    regionex, hsvopt, do_other_plots, autoopts);
            end
            roidat = makeroidat(stack, roiwt, roicen, num_mroi);
            if ~maskinput
                save(pth_mroidat, 'roidat', '-mat', '-v7.3');
            end
        end
    end
end
if ~isempty(chancopy) && numchan==2
    chanreceive = setxor(chancopy, [1,2]);
    sprintf("chancopy is " + num2str(chancopy) + "; \nCOPYING ROI INFO FROM CHANNEL " + num2str(chancopy) + " ONTO CHANNEL " + num2str(chanreceive));
    roidat(chanreceive) = roidat(chancopy);
end


%% compute morphological roi responses

pth_morphroiresp = [pth_mroi_prefix '_resp_.mat']; %don't need channel infix here
try
    load(pth_morphroiresp, 'resp')
catch
    resp = [];
    for c = 1:numchan
        resp = extract_roi_responses(stack, roiwt, pth_mroi_prefix, normopts, imper, resp=resp, dowav=dowav, ti=ti); %if two channel, input resp for 2nd channel gets appended to resp that was output for first channel, with fieldnames identifying channel
        if ~maskinput && c==numchan
            save(pth_morphroiresp, 'resp', '-v7.3', '-mat')
        end
    end
end

% if channorm %2 channel normalization based on wavelet coherence, not fully tested
%     norm_cross_chan(resp.in_rawf_pc_f_cl_rsc000100_w_no_chn1, resp.in_rawf_pc_f_cl_rsc000100_w_no_chn2, t=ti, roiind=1, it=1:numel(ti), pthgifpre=pth_mroi_prefix, mincoh=0.3);
% end


%% plots


if hsvopt.do %roi hsv map
    hsvopt = plots_setup_hsv(hsvopt);
    hue_feature = [1:num_mroi]';
    hsvmap = plots_compute_hsv(hsvopt, hueft=hue_feature);
    hsv_filename = [pth_mroi_prefix 'hsvfov_.gif'];
    plotchannel = 1;
    hsvimg_as_rgb = hsvplt(hsvopt, stackmnt(:,:,:,:,plotchannel), hsvmap, roipx, roiwt, hsv_filename);
end

if olayopt.do %roi overlay
    filename_olay = [pth_mroi_prefix 'roioverlay_.gif'];
    gif_visibility = 'on';
    plotchannel = 1;
    stack2fig(stackmnt(:,:,:,:,plotchannel), pthgif=filename_olay, gif_visibility=gif_visibility, roipx=roipx, roi_colors=olayopt.roi_color, roialpha=olayopt.roialpha) %include roipx as argument to plot roi overlay
end


if do_other_plots %all these are at imaging resolution

    %colormap for each roi
    cmap = distinguishable_colors(size(roiwt,1));
    double_colormap = 0;
    if double_colormap %like for two halves of PB, etc, made this default 0 since the split is just halfway along mask (not functional)
        num_region_periods = 2; %for example, two halves of pb
    else
        num_region_periods = 1;
    end
    cmap = repmat(cmap,num_region_periods,1); %if region is periodic with multiple periods


    %3d scatter, each roi a different hue
    hfg = figure; hold on
    for i = 1:num_mroi %overlay each pixel in its indexed color onto the pb image
        scatter3( maskx(idx_vox2roi == i), masky(idx_vox2roi == i), maskz(idx_vox2roi == i), 'filled', 'MarkerFaceColor', cmap(i,:), 'MarkerFaceAlpha', 0.2 )
    end
    %plot3(midx,midy,midz,'.k', 'MarkerSize',12) %include midline if using 'skeleton'
    %scatter3(roicen(:,2 ), roicen(:,1), roicen(:,3), 80, 'k', 'filled') %show the centroids in each of their colors
    colormap(bone);
    axis image; axis off
    set(gca,'Visible','off')
    set(gca,'CameraViewAngle',8)
    rotinc = 30;
    views = -180:rotinc:180;
    pthgif = [pth_mroi_prefix 'huerois_3dspin_.gif'];
    for framecount = 1:length(views) - 1
        view(views(framecount)+2, 20)
        fig2gif(hfg, framecount, pthgif)
    end



    %mask overlay
    overlayarray = rescale(0.2*rescale(mask_allroi) + rescale(mean(stack, 4), 0, 1));
    stack2fig( overlayarray, pthgif=[pth_mroi_prefix 'maskallroi_overlay_.gif'])

    %manual roi mask
    stack2fig(roimaskman, pthgif=[pth_mroi_prefix 'roimaskman_.gif'])

    %mask all rois (without stack background)
    stack2fig(mask_allroi, pthgif=[pth_mroi_prefix 'maskallroi_.gif'])

    % %3d surface plot
    % kbnd = boundary([maskx,masky,maskz]);
    % figure;
    % trisurf(kbnd,maskx',masky',maskz','Facecolor','red','FaceAlpha',0.1)
    % axis image
    % saveas( gcf, [pth_mroi_prefix 'maskallroi_surface_.png'])


end

end



