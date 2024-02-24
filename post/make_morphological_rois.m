function [roiinfo, resp]  = make_morphological_rois(stack, opts_mroi, ...
    md, pth, stack_hires, map_hires_lores, regionex)


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

%% params

use_drawn_rois = opts_mroi.use_drawn_rois.(regionex);
num_mroi_auto = opts_mroi.num_mroi_auto.(regionex);
doplots = opts_mroi.doplots;
normopts = opts_mroi.norm;

pth_stack = pth.stack_analysis;
pth_mroi = pthmroi.(regionex);

xwid = md.xwid;
zwid = md.zwid; 

%% draw rois (polygons/polyhedra)


if use_drawn_rois

    pth_maskmanual = [pth_stack(1:end-4) regionex '_maskmanual_.mat'];

    try
        maskmanual = struct2cell(load(pth_maskmanual));
        maskmanual = maskmanual{1};
        if all(maskmanual(:)==1)
            disp(["WARNING, MASK MANUAL IS ALL ONES FOR REGION: " regionex])
        end
    catch
        flag_limit_one_manual_roi = 0;
        if num_mroi_auto>1
            flag_limit_one_manual_roi = 1;
        end
        maskmanual = drawrois(stack, regionex, pth_maskmanual, flag_limit_one_manual_roi);
    end
else
    maskmanual = ones(size(stack,1), size(stack,2), size(stack,3), 'logical'); %otherwise just ones
end

num_mroi_manual_manual = size(maskmanual, 4);

%% make mask_3d (from manual mask plus automated mask, or just manual mask, or just automated mask)

if num_mroi_manual_manual>1 || num_mroi_auto==0

    num_mroi = num_mroi_manual_manual;

    if num_mroi_auto>0
        error(sprintf(['ERROR \n' ...
            'num_mroi_manual_manual is greater than one AND num_mroi_auto is greater than zero \n' ...
            'DELETE OR RENAME pth_maskmanual AND DRAW MANUAL MORPHOLOGICAL ROIS AGAIN, \n' ...
            'OR KEEP MANUAL MORPHOLOGICAL ROIS AND REQUEST 0-1 AUTOMATED MORPHOLOGICAL ROIS']))
    end

    mask_roi_vec = zeros(num_mroi, numel(sum(maskmanual, 4)), 'logical');  %initialize a logical matrix that is of dimensions Centroids  x AllPixels
    for mi = 1:num_mroi
        tmp = maskmanual(:,:,:,mi);
        [masky, maskx, maskz] = ind2sub(size(tmp), find(tmp));
        mask_roi_vec(mi, sub2ind(size(tmp), masky, maskx, maskz)) = true; %indices of each roi
    end

    centroids_roi = find_roi_centroids(maskmanual);

    fprintf("WARNING, if sort_roi_method is 'morph_long_axis', rois will be sorted by drawn roi index, not morph long axis, since long axis extraction requires automated morph roi extraction")

else

    num_mroi = num_mroi_auto;
    do_3d = 1; %1 makes 3d mask unless stack is 2d, 0 makes 2d mask for 2d, 3d, or 4d stack input
    create_mask_method = 'edge'; %method for defining edges of mask from input premask
    subsample_mask_method = 'equidistant'; %method for subsampling mask into rois
    pth_save_figs_prefix = [pth_stack(1:end-4) '_' regionex];
    [mask_roi_vec, centroids_roi] = ...
        make_morphological_rois_automated(stack, maskmanual, ...
        num_mroi_auto, do_3d, create_mask_method, subsample_mask_method, ...
        xwid, zwid, stack_hires, map_hires_lores, pth_save_figs_prefix, doplots);

end

pixinds_roi = cell(num_mroi, 1);
for ii = 1:length(pixinds_roi)
    pixinds_roi{ii} = find(vec(mask_roi_vec(ii,:)));
end
pixinds_allroi_tmp = unique(vertcat(pixinds_roi{:})); %this is not always the same as find(mask_allroi) inside morph auto function above, since rois can be overlapping, and also sometimes derived from interpolated z

mask_allroi = zeros(size(stack, 1), size(stack, 2), size(stack, 3), 'logical');
mask_allroi(pixinds_allroi_tmp) = 1;

centroids_roi_flat = cell2mat(centroids_roi(:));
flatten_key = cell2mat(arrayfun(@(idx) [repmat(idx,size(centroids_roi{idx},1),1), (1:size(centroids_roi{idx},1)).'], (1:numel(centroids_roi)).', 'uniform', 0));

pixinds_allroi = cell(length(pixinds_allroi_tmp), 1);
mapind2ind = zeros(length(pixinds_allroi_tmp), 1, 'uint16');
for ii = 1:length(pixinds_allroi) %one pixel at a time
    [tmpy, tmpx, tmpz] = ind2sub(size(mask_allroi), pixinds_allroi_tmp(ii));
    [~, maptmp] = pdist2(centroids_roi_flat, [tmpy, tmpx, tmpz], 'euclidean', 'smallest', 1); %map roi centroids to to morphological centroids . . . change euclidian to chebychev??
    mapind2ind(ii) = flatten_key(maptmp, 1); %this records which cell the nearest morph centroid is from

    pixinds_allroi{ii} = pixinds_allroi_tmp(ii); %put in cell array to match what happens with functional rois

end



%% compute morphological roi responses


resp = extract_roi_responses(stackcrop, mask_roi_vec, pth_mroi, normopts, dtmni);


%% put in struct 'roiinfo'

roiinfo.numroi = num_mroi;
roiinfo.pixinds_roi = pixinds_roi;  %pixel indices of each roi, one roi per cell
roiinfo.mask_roi_vec = mask_roi_vec; %boolean mask vector of each roi
roiinfo.centroids_roi = centroids_roi;
roiinfo.mask_allroi = mask_allroi; %boolean mask of all rois
roiinfo.mapind2ind = mapind2ind; %for each pixel in a roi, which roi it belongs to
roiinfo.roi_overlay = [];
roiinfo.rcor = [];
roiinfo.rsnr = [];
roiinfo.roinumpix = [];
roiinfo.roipixvals_binned = [];
roiinfo.roipixvals_edges = [];
roiinfo.pixinds_allroi = pixinds_allroi; %all pixels in all rois, one pixel for each cell (treating each pixel as a roi to match structure of pixinds_roi)



%% plots

if doplots

    [masky,maskx,maskz] = ind2sub(size(mask_allroi),find(mask_allroi)); %find the cartesian coordinates of points in the mask
    kbnd = boundary([maskx,masky,maskz]);
    figure;
    trisurf(kbnd,maskx',masky',maskz','Facecolor','red','FaceAlpha',0.1)
    axis image

    overlayarray = rescale(0.2*rescale(mask_allroi) + rescale(mean(stack, 4), 0, 1));
    plot_gif( overlayarray, [pth_stack(1:end-4) '3d_mask_manual_' regionex '_.gif'])


    plot_gif(maskmanual, [pth_stack(1:end-4) '3d_mask_manual_' regionex '_.gif'])
    plot_gif(mask_allroi, [pth_stack(1:end-4) '3d_mask_simple_' regionex '_.gif'])

end

end
