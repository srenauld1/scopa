function [roiinfo, resp] = make_morphological_rois(stack, stack_mnt, opts_mroi, ...
    ti, imper, xwid, ywid, zwid, pth_mroi, pth_tmpfiles, stack_hires, map_hires_lores, ...
    regionex, parstr_mroi, maskmanual2)


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
% manually create 2d mask (maskmanual)
% that 2d mask is projected into a 3d mask (mask_mroi_all_simple)
% that is refined using chosen method (edge detection, global threshold, etc)
% if creating multiple morphological rois, the 3d mask is refined using
% a high-z-res version of the data, and the mask is mapped back to original resolution
% find the morphological roi centroids (centroids_roi) of the final 3d mask,
% and all voxels that are nearest each centroid (mask_roi_vec)
% if you draw multiple rois in maskmanual, a different mask_mroi_all_simple will be
% made for each, but the 3d refining code cannot accommodate
% multiple drawn rois currently, so do not do this;
% if you want multiple rois within the fov passed to this function,
% call this function (make_morphological_rois)
% again with the same inputs, but draw a different single 2d roi,
% and assign the outputs of this function a different name (outside this function)

%mask_roi_vec can be single when it's weighted, boolean otherwise

%% params

if exist('maskmanual2', 'var') %if passing in a morph roi mask (interactive mode)
    maskmanual2 = {maskmanual2};
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
chanproject = opts_mroi.chanproject;
channorm = opts_mroi.channorm;
autoopts = opts_mroi.auto;

pth_mroi_prefix = pth_mroi(1:end-4);
numchan = size(stack,5);

%% draw rois (polygons/polyhedra)

if ~maskinput

    if use_drawn_rois
        for c = 1:numchan

            if ismember(c,chandraw)

                pth_mroi_manual_prefix = erase(pth_mroi_prefix, ['_' parstr_mroi]); %different prefix since the parstr_mroi are irrelevant for manually drawn rois, allowing manually drawn to be used for different parstr_mroi
                pth_mroi_manual_prefix = erase(pth_mroi_manual_prefix, ['_morph']); %string 'morph' is redundant here, since this has suffix manual
                pth_maskmanual = [pth_mroi_manual_prefix 'chn' num2str(c) '_maskmanual_.mat'];
                try
                    load(pth_maskmanual, 'maskmanual');
                    if all(maskmanual(:)==1)
                        disp(["WARNING, MASK MANUAL IS ALL ONES FOR REGION: " regionex])
                    end
                catch
                    flag_limit_one_manual_roi = 0;
                    if num_mroi_auto>1
                        flag_limit_one_manual_roi = 1;
                    end
                    maskmanual = drawrois(stack(:,:,:,:,c), regionex, pth_maskmanual, pth_tmpfiles, flag_limit_one_manual_roi);
                end

            else
                maskmanual = ones(size(stack,1), size(stack,2), size(stack,3), 'logical'); %otherwise just ones
            end

            maskmanual2{c} = maskmanual;

        end
    else
        maskmanual2 = repmat({ones(size(stack,1), size(stack,2), size(stack,3), 'logical')}, [1 1 1 numchan]);
    end
end

%% make mask_3d (from manual mask plus automated mask, or just manual mask, or just automated mask)


for c = 1:numchan

    if ismember(c,autoopts.chan)

        maskmanual = maskmanual2{c};
        stack_mnt_tmp = stack_mnt(:,:,:,c);
        num_mroi_manual = size(maskmanual, 4);
        pth_morphroidata = [pth_mroi_prefix 'chn' num2str(c) '_morphroidata_.mat'];

        try

            load(pth_morphroidata, 'mask_roi_vec', 'centroids_roi', 'num_mroi');

        catch

            if num_mroi_manual>1 || num_mroi_auto==0

                num_mroi = num_mroi_manual;

                if num_mroi_auto>0
                    error(sprintf(['ERROR \n' ...
                        'num_mroi_manual is greater than one AND num_mroi_auto is greater than zero \n' ...
                        'DELETE OR RENAME pth_maskmanual AND DRAW MANUAL MORPHOLOGICAL ROIS AGAIN, \n' ...
                        'OR KEEP MANUAL MORPHOLOGICAL ROIS AND REQUEST 0-1 AUTOMATED MORPHOLOGICAL ROIS']))
                end

                mask_roi_vec = zeros(num_mroi, numel(sum(maskmanual, 4)), 'logical');  %initialize a logical matrix that is size (centroids, voxels)
                for mi = 1:num_mroi
                    tmp = maskmanual(:,:,:,mi);
                    [maskytmp, maskxtmp, maskztmp] = ind2sub(size(tmp), find(tmp));
                    mask_roi_vec(mi, sub2ind(size(tmp), maskytmp, maskxtmp, maskztmp)) = true; %indices of each roi
                end

                centroids_roi = find_roi_centroids(maskmanual);

                sprintf("WARNING,\n" + ...
                    "if sort_roi_method is 'morph_long_axis', rois will be sorted by drawn roi index, not morph long axis, \n" + ...
                    "since determining the long axis of extraction currently requires automated morph roi extraction")

            else

                [mask_roi_vec, centroids_roi, num_mroi] = ...
                    make_morphological_rois_automated(stack_mnt_tmp, maskmanual, num_mroi_auto, ...
                    xwid, ywid, zwid, stack_hires, map_hires_lores, pth_mroi_prefix, ...
                    regionex, hsvopt, do_other_plots, autoopts);

            end

            if ~maskinput
                save(pth_morphroidata, 'mask_roi_vec', 'centroids_roi', 'num_mroi', '-mat', '-v7.3');
            end

        end

    end
end

%% compute some morphological roi data

mask_allroi = zeros(size(stack, 1), size(stack, 2), size(stack, 3), 'logical');

roipixinds = cell(num_mroi, 1);
pixinds_bnd_roi = cell(num_mroi, 1);
bnd2d = zeros(size(mask_allroi), 'logical');
for ii = 1:length(roipixinds)
    roipixinds{ii} = find(vec(mask_roi_vec(ii,:))); %pixel indices of each roi
    mask_allroi(roipixinds{ii}) = 1;
    bnd2d(:) = 0;
    for jj = 1:size(mask_allroi, 3)
        bnd2d(:,:,jj) = bwperim(mask_allroi(:,:,jj));
    end
    pixinds_bnd_roi{ii} = find(vec(bnd2d)); %pixel indices of each roi boundary
    mask_allroi(:) = 0;
end

pixinds_allroi_tmp = unique(vertcat(roipixinds{:})); %this is not always the same as find(mask_allroi) inside morph auto function above, since rois can be overlapping, and also sometimes derived from interpolated z

mask_allroi(pixinds_allroi_tmp) = 1;

[masky,maskx,maskz] = ind2sub(size(mask_allroi),find(mask_allroi)); %find the cartesian coordinates of points in the mask

centroids_roi_flat = cell2mat(centroids_roi(:));
flatten_key = cell2mat(arrayfun(@(idx) [repmat(idx,size(centroids_roi{idx},1),1), (1:size(centroids_roi{idx},1)).'], (1:numel(centroids_roi)).', 'uniform', 0));

pixinds_allroi = cell(length(pixinds_allroi_tmp), 1);
idx_vox2roi = zeros(length(pixinds_allroi_tmp), 1, 'uint16');
for ii = 1:numel(pixinds_allroi) %one pixel at a time
    [tmpy, tmpx, tmpz] = ind2sub(size(mask_allroi), pixinds_allroi_tmp(ii));

    [~, maptmp] = pdist2(centroids_roi_flat, [tmpy, tmpx, tmpz], 'euclidean', 'smallest', 1); %map roi centroids to to morphological centroids . . . change euclidian to chebychev??
    idx_vox2roi(ii) = flatten_key(maptmp, 1); %this records which cell the nearest morph centroid is from

    pixinds_allroi{ii} = pixinds_allroi_tmp(ii); %put in cell array to match what happens with functional rois
end



%% compute morphological roi responses

pth_morphroiresp = [pth_mroi_prefix 'resp_.mat'];
try
    fload(pth_morphroiresp, 'resp')
catch
    resp = extract_roi_responses(stack, mask_roi_vec, pth_mroi_prefix, normopts, imper);
    do_wavelet_denoise = 1;
    if do_wavelet_denoise
        % resp.in_rawf_pc_f_cl_rsc000100_w_no_chn1 = wavelet_denoise(resp.in_rawf_pc_f_cl_rsc000100_w_no_chn1, t=ti, it=1:numel(ti), pthgifpre=''); %pth_mroi_prefix
        resp.in_rawf_pc_f_cl_f_w_no_chn1 = wavelet_denoise(resp.in_rawf_pc_f_cl_f_w_no_chn1, t=ti, it=1:numel(ti), pthgifpre=''); %pth_mroi_prefix
    end
    if ~maskinput && c==numchan
        save(pth_morphroiresp, 'resp', '-v7.3', '-mat')
    end
end

if channorm
    norm_cross_chan(resp.in_rawf_pc_f_cl_rsc000100_w_no_chn1, resp.in_rawf_pc_f_cl_rsc000100_w_no_chn2, t=ti, roiind=1, it=1:numel(ti), pthgifpre=pth_mroi_prefix, mincoh=0.3);
end


%% put in struct 'roiinfo'
"NEED TO PUT THIS IN ASSEMBLE ROI INFO FUNCTION WITH Compute some morphological roi data SECTION ABOVE, ONE FOR EACH REQUESTED CHANNEL, OR PROJECT"
roiinfo.numroi = num_mroi;
roiinfo.roipixinds = roipixinds;  %pixel indices of each roi, one roi per cell
roiinfo.mask_roi_vec = mask_roi_vec; %boolean mask vector of each roi
roiinfo.centroids_roi = centroids_roi;
roiinfo.mask_allroi = mask_allroi; %boolean mask of all rois
roiinfo.idx_vox2roi = idx_vox2roi; %for each pixel in a roi, which roi it belongs to
roiinfo.cmrval = [];
roiinfo.cmsnr = [];
roiinfo.roinumpix = [];
roiinfo.roipixvals_binned = [];
roiinfo.roipixvals_edges = [];
roiinfo.pixinds_allroi = pixinds_allroi; %all pixels in all rois, one pixel for each cell (treating each pixel as a roi to match structure of roipixinds)

if chanproject
    roiinfo(2) = roiinfo;
    if chanproject==2
        roiinfo = flip(roiinfo);
    end
end

%% plots


if hsvopt.do %roi hsv map
    hsvopt = plots_setup_hsv(hsvopt);
    hue_feature = [1:num_mroi]';
    hsvmap = plots_compute_hsv(hsvopt, hueft=hue_feature);
    hsv_filename = [pth_mroi_prefix 'hsvfov_.gif'];
    hsvimg_as_rgb = plots_hsvfov(hsvopt, stack_mnt, hsvmap, roipixinds, mask_roi_vec, hsv_filename);
end

if olayopt.do %roi overlay
    filename_olay = [pth_mroi_prefix 'roioverlay_.gif'];
    gif_visibility = 'on';
    stack2fig(stack_mnt, pthgif=filename_olay, gif_visibility=gif_visibility, roipixinds=roipixinds, roi_colors=olayopt.roi_color, roialpha=olayopt.roialpha) %include roipixinds as argument to plot roi overlay
end


if do_other_plots %all these are at imaging resolution

    %colormap for each roi
    cmap = distinguishable_colors(size(mask_roi_vec,1));
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
    %scatter3(centroids_roi(:,2 ), centroids_roi(:,1), centroids_roi(:,3), 80, 'k', 'filled') %show the centroids in each of their colors
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
    stack2fig(maskmanual, pthgif=[pth_mroi_prefix 'maskmanual_.gif'])

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
