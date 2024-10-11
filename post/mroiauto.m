
function [roiwt, roicen, numroifinal] = ...
    mroiauto(stackmnt, roimaskman, ...
    numroiinit, xwid, ywid, zwid, stack_hires, ...
    map_hires_lores, pth_mroi_prefix, ...
    regionex, imhsv, doplt, opts)

%this function has several partially overlapping control features,
%organization is meant to make it easy to add new methods (e.g. by
%creating new maskseg and inserting in switch statement)
%stackmnt must be 3d (xyz), although 3rd dim (z) can be singleton
%roimaskman must match dimensionality of stackmnt, or be lower dimensional
%stack_hires is optional, must be 3d xyz, and match xy size of stackmnt

maskmake = opts.maskmake;
maskseg = opts.maskseg;
edgethr = opts.edgethr;
edgesig = opts.edgesig;
celsz = opts.celsz;
do3d = opts.do3d;


%% preprocess stackmnt, make mean stackmnt

if ~isa(stackmnt, 'single')
    stackmnt = single(stackmnt);
end

if ~exist('roimaskman', 'var') || isempty(roimaskman)
    roimaskman = 1;
end

stackmnt = rescale(stackmnt); %if there's a 4th dim, it's time so collapse it  . . . instead of mean could try zscore, or max, prctile, etc converts to double, also don't change this variable because you need it below
numel_stackmnt = numel(stackmnt);

if do3d==1 && size(stackmnt, 3)==1 %if z dim is singleton
    fprintf('WARNING, cannot make requested 3d mask because stackmnt is 2d, making 2d mask instead')
    pause(2)
    do3d = 0; %override if stackmnt is only 2d
end

% if do3d==0 && size(stackmnt, 3)>1
%     stackmnt = rescale(mean(stackmnt, 3));
% end


%% mask mean stackmnt with any available manual mask (if none was made, roimaskman is all ones, ie has no effect)

roimaskman_allrois = logical(sum(roimaskman, 4)); %if there's a 4th dim, it's rois co collapse it
stackmean_masked = stackmnt.*roimaskman_allrois; %don't change this variable because you need it below



%% create hi-z-res premask if numroiinit > 1 and do3d

sliceinds_hires = [];
if numroiinit > 1 && do3d

    if ~isempty(stack_hires) %if using a hi-z-res stackmnt to help make the 3d mask

        F = griddedInterpolant(single(roimaskman_allrois), 'linear');
        upsampind = linspace(1, size(roimaskman_allrois,3), size(stack_hires, 3) + 1);
        upsampind = upsampind(1:end-1);
        roimaskman_allrois_upsamp = F({ 1:size(roimaskman_allrois,1), 1:size(roimaskman_allrois,2), upsampind }); %upsample the manual mask to apply to hires
        roimaskman_allrois_upsamp = logical(roimaskman_allrois_upsamp);

        premask = stack_hires.*roimaskman_allrois_upsamp;
        if ~isequal(unique(premask), [0;1]) && ~all(unique(premask)==1)  %in case stack_hires is a binary mask, don't rescale
            idxnz = premask~=0; %find nonzero indices
            premask(idxnz) = rescale(premask(idxnz));
        end
        sliceinds_hires = [0 find(diff(map_hires_lores))] + 1; %map_hires_lores may not be uniform hi-z-res sampling of lo-z-res, causing some imprecision (design acquisition zfov and zwid to avoid this)

    else  %else make a hi-z-res stackmnt from the lo-z-res stackmnt

        if round(zwid/xwid)==1 %if it's not already "hires"
            premask = stackmean_masked; %define stackmnt used to define mask
        else

            if xwid-ywid>1e-6
                error("this is currently only written for square pixels")
            end

            upsamp = zwid / xwid; %upsamp factor makes cube voxels

            numslices_upsamp = round((size(stackmean_masked,3)) * upsamp);

            F = griddedInterpolant(stackmean_masked, 'linear');
            upsampind = linspace(1, size(stackmean_masked,3), numslices_upsamp + 1);
            upsampind = upsampind(1:end-1);
            premask = F({ 1:size(stackmean_masked,1), 1:size(stackmean_masked,2), upsampind });
            premask = rescale(premask);  %rescale after interpolation

            sliceinds_hires = linspace(1, size(premask,3), size(stackmnt, 3)+1);
            sliceinds_hires = sliceinds_hires(1:end-1);
            sliceinds_hires = round(sliceinds_hires); %this z rounding is one source of imprecision in the mapping
        end

    end

else

    premask = stackmean_masked; %define stackmnt used to define mask

end

%% threshold premask to create mask

mask_allroi_approx = zeros(size(premask));

switch maskmake

    case 'edge' %find 3d mask edges, smooth them, apply morphological close

        if do3d
            do_edge_3d = 1;
        else
            do_edge_3d = 0; %2d edge detection just seems more sensitive given the same edgethr
        end

        if do_edge_3d && size(premask, 3)>1
            bookend = zeros(size(premask, 1), size(premask, 2));
            premask = cat(3, bookend, premask, bookend); %bookend with zeros to help 3d edge detection in z
            mask_allroi_approx = edge3(premask, 'approxcanny', edgethr, edgesig);
            premask = premask(:,:,2:end-1);
            mask_allroi_approx = mask_allroi_approx(:,:,2:end-1);
        else
            for tui = 1:size(premask, 3)
                mask_allroi_approx(:,:,tui) = edge(premask(:,:,tui), 'canny', edgethr, edgesig(1));
            end
        end
        mask_allroi_approx = imclose(mask_allroi_approx, strel('disk',celsz)); %this is a 2d closing element so works in 2d or 3d basically the same, 2d keeps this section of code shorter,

    case 'outlier' %mask is outlier

        idxnz = find(premask~=0); %find nonzero indices (use find because you index into this below, so you don't want a logical array)
        premask(idxnz) = rescale(premask(idxnz));
        mask_allroi_approx(idxnz(isoutlier(premask(idxnz)))) = 1;

    case 'triangle' %triangle threshold (and similar alternative in knee_pt)

        premask_nz = premask(premask~=0);

        [histdt, histx] = hist( premask_nz, 1000);
        thrbin_tri = triangle_threshold(histdt, 'R', 0); %last arg 1 to plot
        thr_tri = histx(thrbin_tri);

        [~, thrbin_knee] = knee_pt(premask_nz, [], 1, 1);
        thr_knee = premask_nz(thrbin_knee);

        mask_allroi_approx(premask<thr_tri) = 1;

    case 'nonzero' %all nonzero elements

        mask_allroi_approx = logical(premask);

end

mask_allroi_approx = logical(mask_allroi_approx);

[masky,maskx,maskz] = ind2sub(size(mask_allroi_approx),find(mask_allroi_approx)); %find the cartesian coordinates of points in the mask


%% find 3d mask centroids

numroifinal = numroiinit; %as of 240605 these will match for all cases except 'uniform' or 'uniformp' where do3d~=0

if numroiinit == 1 %for finding a single centroid

    roicen = find_roi_centroids(mask_allroi_approx);

else

    switch maskseg

        case 'skeleton' % create multiple roughly equal-volume roi along skeleton of mask

            if do3d
                min_axis = min([range(maskx),range(masky),range(maskz)]);
                max_axis = max([range(maskx),range(masky),range(maskz)]);
            else
                min_axis = min([range(maskx),range(masky)]);
                max_axis = max([range(maskx),range(masky)]);
            end
            mid = bwskel(mask_allroi_approx,'MinBranchLength',min_axis); %find the midline as the skeleton, shaving out all sub branches that are smaller than the minimum axis length
            ep = (convn(double(mid),ones(3,3,3),'same')<3).*mid;
            [y0,x0,z0] = ind2sub(size(ep),find(ep,1)); %the "starting point" endpoint

            [midy,midx,midz] = ind2sub(size(mid),find(mid));

            if length(midy)>1

                midz_check = midz;
                [midx,midy,midz] = graph_sort3(midx,midy,midz); %here set up to work for 2d and 3d align the points of the midline starting at the first point and going around in a circle. this requires that the midline be continuous!
                if numel(midz)~=numel(midz_check)
                    error("you are attempting to use maskseg skeleton for 2d extraction from a 3d stack with a manual mask that is discontiguous in z; maskseg skeleton cannot yet accommodate that, but uniform and uniformp can; or your skeleton is just discontiguous in 3d")
                end
                xq = [-min_axis:(length(midx)+min_axis)]; %extend the midline so that it reaches the border of the mask. extrapolate as many points as the minimum axis length

                midx = round(interp1(midx,xq,'linear','extrap'));
                midy = round(interp1(midy,xq,'linear','extrap'));
                midz = round(interp1(midz,xq,'linear','extrap'));

                idxmidkeep = ismember([midx',midy',midz'],[maskx,masky,maskz],'rows'); %keep only the points that exist within the mask
                midx = midx(idxmidkeep);
                midy = midy(idxmidkeep);
                midz = midz(idxmidkeep);

                xq = linspace(1, length(midy), 2*(numroiinit) + 1)'; %set query points for interpolation (the number of centroids we want). we'll create twice as many points and take every other so that rois on the edges arent clipped
                centmp = [interp1(midy,xq), interp1(midx,xq), interp1(midz,xq)]; %interpolate x and y coordinates, now that they are ordered, into evenly spaced centroids (this allows one to oversample if desired)
                centmp = centmp(2:2:end-1,:); %take every other so that we dont start at the edges, and all are same size

            else

                error(sprintf("region '" + regionex + "' is roughly uniform blob, so maskseg 'skeleton' fails; try maskseg 'uniform' for roughly equal-volume ROIs within 2d or 3d regionex"))

            end

        case {'uniform', 'uniformp'} % create multiple roughly equal-volume roi by partitioning regionex into numroiinit groups

            if do3d

                [tmp, centmp, bin_prctiles] = probability_bin([masky, maskx, maskz], numroiinit, 1, 0); %iteratively median split along dimension of greatest variance, ties are randomly assigned, so as of 240509, results are not reproducible, although differences are typically not major; so for reproducibility, pipeline loads saves/loads previous results

            else %else split into roughly equal area rois on each slice in mask, rounding number rois for each slice to nearest power of 2 proportional to number of voxels relative to total (typically lots of inaccuracy there)

                uz = unique(maskz);
                for uzi = 1:numel(uz)
                    zinds_each{uzi} = find(maskz==uz(uzi));
                    num_vox_each_slice(uzi) = numel(zinds_each{uzi});
                    frac_vox_each_slice(uzi) = num_vox_each_slice(uzi) / numel(maskz);
                    ideal_mroi_auto_each_slice(uzi) = frac_vox_each_slice(uzi) * numroiinit;
                end
                rnds = pow2(round(log2(ideal_mroi_auto_each_slice))); %rnds = round(frac_mroi_auto_each_slice);

                numroifinal = sum(rnds);
                if numroiinit~=numroifinal
                    sprintf("warning, changing numroiinit is " + num2str(numroiinit) + " while numroifinal is " + num2str(numroifinal))
                    pause(2)
                end

                tmp = zeros([numel(masky) 2], 'uint16');
                centmp = [];
                bin_prctiles = [];
                rndsprev = 0;
                for uzi = 1:numel(rnds)
                    [tmp_xy, centmp_xy, bin_prctiles_xy] = probability_bin([masky(zinds_each{uzi}), maskx(zinds_each{uzi})], rnds(uzi), 1, 0); %iteratively median split along dimension of greatest variance, ties are randomly assigned, so as of 240509, results are not reproducible, although differences are typically not major; so for reproducibility, pipeline loads saves/loads previous results
                    kpinds = ~isnan(sum(centmp_xy));
                    centmp_xy = centmp_xy(:,kpinds);
                    bin_prctiles_xy = bin_prctiles_xy(kpinds);
                    currslice = uz(uzi);
                    tmp(zinds_each{uzi},:) = tmp_xy+rndsprev;
                    rndsprev = max(vec(tmp));
                    centmp_xyz = [centmp_xy; ones(1, size(centmp_xy, 2))*currslice];
                    centmp = [centmp centmp_xyz];
                    bin_prctiles = [bin_prctiles; bin_prctiles_xy];
                end
            end
            if size(unique(tmp.', 'rows'), 1)~=1
                error("each row must have constant value")
            end
            idx_vox2roi = tmp(:,1);
            centmp = centmp.';



    end

    roicen = cell(1, size(centmp, 1));
    for crmi = 1:size(centmp, 1)
        roicen{crmi} = centmp(crmi, :); %convert to cell, since roicen is cell elsewhere (to support rois with varying number of discontiguous parts, even though that doesn't occur when using maskseg 'equidistant')
    end

end

%% assign each voxel in the 3d mask to a morphological roi centroid

if ~strcmp(maskseg, 'uniform') %method 'uniform' has already computed idx_vox2roi (with different algorithm), 'uniformp' recomputes it using pdist2 and its output centroids
    cenmorphflat = cell2mat(roicen(:));
    flatten_key = cell2mat(arrayfun(@(idx) [repmat(idx,size(roicen{idx},1),1), (1:size(roicen{idx},1)).'], (1:numel(roicen)).', 'uniform', 0));
    [~, maptmp] = pdist2(cenmorphflat, [masky, maskx, maskz], 'euclidean', 'smallest', 1); %find the index of the centroid that is closest to each voxel in the mask. using euclidean, but maybe chebychev (chessboard)
    idx_vox2roi = uint16(flatten_key(maptmp, 1)); %this records which cell the nearest morph centroid is from
end

%% find indices for each mophological roi

roiwt = zeros(numroifinal, numel_stackmnt, 'single'); %size [rois, voxels], describes how each voxel contirbutes to roi response, since roi can occupy less than entire voxel (in z dimension especially)

if isempty(sliceinds_hires) %isempty(stack_hires)

    for i = 1:numroifinal
        roiwt(i, sub2ind(size(mask_allroi_approx), masky(idx_vox2roi==i), maskx(idx_vox2roi==i), maskz(idx_vox2roi==i))) = 1; %indices of each roi
    end

else % else downsample the 3 output variables from hires to lores

    % map from hi-z-res to lo-z-res,
    % find voxel weighting that describes how hi-z-res rois occupy lo-z-res voxels
    % roiwt encodes how each voxel contributes to a roi response
    % each voxel's signal is weighted by the proportion of its hires voxels occupied by the roi
    % later the roi signal will be summed across voxels with these weights,
    % also, automated morphological rois created above are not overlapping at first,
    % but some do partially overlap when mapped to lower/imaging res
    % also, equal-volume rois created above will no longer have same number of voxels when mapped down to lores, as a sampling artifact
    % but response extraction (because it is weighted) does represent equal volume roi responses (a linearly interpolated estimate of them, at least)

    mask_allroi_approx_upsamp = mask_allroi_approx; %rename to distinguish for plotting below

    maskznew = maskz;
    for ii = 1:length(sliceinds_hires) %for each hires z slice range
        if ii<length(sliceinds_hires)
            zrange{ii} = sliceinds_hires(ii):sliceinds_hires(ii+1)-1;
        else
            zrange{ii} = sliceinds_hires(ii):size(premask, 3);
        end
        maskznew(ismember_each_element(maskznew, zrange{ii})) = ii; %map to lores z
    end

    for i = 1:numroifinal
        coords_this_roi = [masky(idx_vox2roi==i), maskx(idx_vox2roi==i), maskznew(idx_vox2roi==i)];
        [~, ~, voxinds_lores_this_roi] = unique(coords_this_roi, 'rows', 'stable');
        for voxind = 1:numel(voxinds_lores_this_roi)
            inds_this_vox = voxinds_lores_this_roi==voxinds_lores_this_roi(voxind);
            zind_lores_this_vox = unique(coords_this_roi(inds_this_vox,3));
            if numel(zind_lores_this_vox)>1
                error("zind_lores_this_vox should be scalar")
            end
            num_interp_vox_in_this_vox_this_roi = numel(find(inds_this_vox));
            num_interp_vox_in_this_vox_total = numel(zrange{zind_lores_this_vox});
            roiwt(i, sub2ind(size(stackmean_masked), coords_this_roi(voxind,1), coords_this_roi(voxind,2), coords_this_roi(voxind,3))) = num_interp_vox_in_this_vox_this_roi / num_interp_vox_in_this_vox_total;
        end
    end

    if any(sum(roiwt)>1)
        totals_with_rounding_error = sum(roiwt);
        totals_with_rounding_error = totals_with_rounding_error(totals_with_rounding_error>1);
        nearly_equal_tol = 1e-6;
        for trei = 1:numel(totals_with_rounding_error)
            is_equal_to_one = isequaltol(double(totals_with_rounding_error(trei)), 1, nearly_equal_tol);
            if ~is_equal_to_one
                error("sum of each voxel's contribution to all rois within should be range 0-1; first check that totals_with_rounding_error are not nearly equal to 1, if so maybe just adjust nearly_equal_tol")
            end
        end
    end
    if any(isnan(roiwt(:)))
        error("roiwt should not have any nans") %roiwt(isnan(roiwt)) = 0;
    end

    %%downsample 3d "allroi" mask for plotting (note this will not quite match union of all roi indices, so it is only used for plotting within this function and is not output)
    F2 = griddedInterpolant(single(mask_allroi_approx), 'linear');
    midpoint_add = median([1 mean(diff(sliceinds_hires))]);  %downsampling using midpoint of hires in z seems better than taking mean
    mask_allroi_approx = F2({ 1:size(mask_allroi_approx,1), 1:size(mask_allroi_approx,2), sliceinds_hires+midpoint_add });
    mask_allroi_approx = logical(mask_allroi_approx);  %rescale after interpolation to be safe

    %%downsample z component of each subroi of each mophological roi centroid
    for rci = 1:numroifinal %loop over rois
        for rci2 = 1:size(roicen{rci}, 1) %loop over any subrois (discontiguous subregions of single roi)
            roicen{rci}(rci2,3) = interp1([1, size(premask, 3)], [1, size(stackmnt, 3)], roicen{rci}(rci2,3));
        end
    end


end

%%


if doplt

    if ~isempty(sliceinds_hires) %if interp to hi z res to help segmentation, plot those hi z res versions here, imaging sampling version of these (which are the used variables) are plotted in mroimake

        %mask overlay
        overlayarray = rescale(0.2*rescale(mask_allroi_approx_upsamp) + rescale(premask, 0, 1));
        stackplt( overlayarray, pthgif=[pth_mroi_prefix 'maskallroi_overlay_upsamp.gif'])


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
        for i = 1:numroifinal %overlay each pixel in its indexed color onto the pb image
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
        pthgif = [pth_mroi_prefix 'huerois_3dspin_upsamp.gif'];
        for framecount = 1:length(views) - 1
            view(views(framecount)+2, 20)
            fig2gif(hfg, framecount, pthgif)
        end


        %data for upsamp overlay and hsv
        roiwt_upsamp = zeros(numroifinal, numel(mask_allroi_approx_upsamp), 'single');
        for i = 1:numroifinal
            roiwt_upsamp(i, sub2ind(size(mask_allroi_approx_upsamp), masky(idx_vox2roi==i), maskx(idx_vox2roi==i), maskz(idx_vox2roi==i))) = 1; %indices of each roi
        end
        roipixind_upsamp = cell(numroifinal, 1);
        for ii = 1:numel(roipixind_upsamp)
            roipixind_upsamp{ii} = find(vec(roiwt_upsamp(ii,:)));
        end

        %roi overlay in upsampled res
        filename_olay = [pth_mroi_prefix 'roiolmake_upsamp_.gif'];
        gifvis = 'on';
        stackplt(premask, pthgif=filename_olay, gifvis=gifvis, roipx=roipixind_upsamp) %include roipx as argument to plot roi overlay


        %hsv gif, each slice, each roi a different hue
        imhsv = plots_setup_hsv(imhsv);
        hue_feature = [1:numroifinal]';
        hsvmap = hsvcmp(imhsv, hue_feature);
        filename_hsv = [pth_mroi_prefix 'hsvfov_upsamp_.gif'];
        hsvimg_upsamp = hsvplt(imhsv, premask, hsvmap, roipixind_upsamp, roiwt_upsamp, filename_hsv);


        %3d scatter plot
        figure; hold on;
        plot3(maskx, masky, maskz, '.m', 'MarkerSize', 0.1);
        if exist('midx', 'var')
            plot3(midx,midy,midz, '*k', 'MarkerSize', 2.2);
        end
        axis image;
        view(3);
        title('3d mask (interpolated to hires if do3d is true)')
        saveas( gcf, [pth_mroi_prefix 'maskallroi_scatter_upsamp_.png'])


        % %3d surface plot
        % kbnd = boundary([maskx,masky,maskz]);
        % figure;
        % trisurf(kbnd,maskx',masky',maskz','Facecolor','red','FaceAlpha',0.1)
        % axis image
        % saveas( gcf, [pth_mroi_prefix 'maskallroi_surface_upsamp_.png'])

        % 3d volume plot
        % viewerRegistered = viewer3d(BackgroundColor="black",BackgroundGradient="off");
        % volshow(mask_allroi_approx,Parent=viewerRegistered,RenderingStyle="Isosurface",IsosurfaceValue=0.1, ...
        %     Colormap=[0 1 0],Alphamap=0.1);


    end

    stackplt(premask, pthgif=[pth_mroi_prefix 'autopremask_.gif'])

    if strcmp(maskmake, 'triangle')
        duk = sort(tmpup_nz);
        duk(duk<thr_tri) = nan;
        figure; subplot(2,1,1);
        plot(sort(tmpup_nz)); hold on; plot(duk)
        title('triangle threshold (default for threshold method, "triangle"')
        duk = sort(tmpup_nz);
        duk(duk<thr_knee) = nan;
        subplot(2,1,2);
        plot(sort(tmpup_nz)); hold on; plot(duk)
        title('knee threshold (alternative, not used by default)')
        saveas( gcf, [pth_mroi_prefix 'trianglethresh_.png'])
    end

end



