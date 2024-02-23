
function [mask_roi_vec, centroids_roi] = ...
    make_morphological_rois_automated(stack, maskmanual, ...
    numroi_morph_auto, do_3d, create_mask_method, subsample_mask_method, ...
    xwid, zwid, stack_hires, map_hires_lores, pth_save_figs_prefix, do_plots)


%this function has several partially overlapping control features,
%organization is meant to make it easy to add new methods (e.g. by
%creating new subsample_mask_method and inserting in switch statement)
%stack must be 4d (xyzt), although 3rd dim (z) can be singleton
%maskmanual must match dimensionality of stack, or be lower dimensional
%stack_hires is optional, must be 3d xyz, and match xyz size of stack


%% preprocess stack, make mean stack


if ~isa(stack, 'single')
    stack = single(stack);
end

if ~exist('maskmanual', 'var') || isempty(maskmanual)
    maskmanual = 1;
end

stackmean = rescale(mean(stack, 4)); %if there's a 4th dim, it's time so collapse it  . . . instead of mean could try zscore, or max, prctile, etc converts to double, also don't change this variable because you need it below
numel_stackmnt = numel(stackmean);

if do_3d==1 && size(stackmean, 3)==1 %if z dim is singleton
    fprintf('WARNING, cannot make requested 3d mask because stack is 2d, making 2d mask instead')
    do_3d = 0; %override if stack is only 2d
end

if do_3d==0 && size(stackmean, 3)>1
    stackmean = rescale(mean(stackmean, 3));
end


%% mask mean stack with any available manual mask (if none was made, maskmanual is all ones, ie has no effect)

maskmanual_allrois = logical(sum(maskmanual, 4)); %if there's a 4th dim, it's rois co collapse it
stackmean_masked = stackmean.*maskmanual_allrois; %don't change this variable because you need it below

%%

if ~(numroi_morph_auto > 1 && do_3d) %if not multiple auto rois, and not 3d, otherwise premask defined below
    premask = stackmean_masked; %define stack used to define mask
end

%% create special premask if numroi_morph_auto > 1 and do_3d

sliceinds_hires = [];
if numroi_morph_auto > 1

    if do_3d

        
        if ~isempty(stack_hires) %if using a hi-z-res stack to help make the 3d mask

            F = griddedInterpolant(single(maskmanual_allrois), 'linear');
            upsampind = linspace(1, size(maskmanual_allrois,3), size(stack_hires, 3) + 1);
            upsampind = upsampind(1:end-1);
            maskmanual_allrois_upsamp = F({ 1:size(maskmanual_allrois,1), 1:size(maskmanual_allrois,2), upsampind }); %upsample the manual mask to apply to hires
            maskmanual_allrois_upsamp = logical(maskmanual_allrois_upsamp);  

            premask = stack_hires.*maskmanual_allrois_upsamp;
            if ~isequal(unique(premask), [0;1]) && ~all(unique(premask)==1)  %in case stack_hires is a binary mask, don't rescale
                idxnz = premask~=0; %find nonzero indices
                premask(idxnz) = rescale(premask(idxnz));
            end
            sliceinds_hires = [0 find(diff(map_hires_lores))] + 1;

        else  %else make a hi-z-res stack from the lo-z-res stack

            upsamp = zwid / xwid; %upsample factor makes cube voxels z pixel width same as xy
            numslices_upsamp = round((size(stackmean_masked,3)) * upsamp);

            F = griddedInterpolant(stackmean_masked, 'linear');
            upsampind = linspace(1, size(stackmean_masked,3), numslices_upsamp + 1);
            upsampind = upsampind(1:end-1);
            premask = F({ 1:size(stackmean_masked,1), 1:size(stackmean_masked,2), upsampind });
            premask = rescale(premask);  %rescale after interpolation

            sliceinds_hires = linspace(1, size(premask,3), size(stack, 3)+1);
            sliceinds_hires = sliceinds_hires(1:end-1);
            sliceinds_hires = round(sliceinds_hires); %this z rounding is one source of imprecision in the mapping

        end
    end
end

%% threshold premask to create mask

mask_allroi_approx = zeros(size(premask));

switch create_mask_method

    case 'edge' %find 3d mask edges, smooth them, apply morphological close       
        
        if do_3d
            do_edge_3d = 1; %2d just seems more sensitive given the same edgethresh
        else
            do_edge_3d = 0; %2d just seems more sensitive given the same edgethresh
        end
        
        edgethresh = [.1 .7]; %two thresholds to detect strong and weak edges; includes weak edges in output only if they are connected to strong edges
        edgesig = [sqrt(2)*2 sqrt(2)*2 sqrt(2)*2 ]; %for 3d (not 2d), can define smoothing filter sigma for each dim, or use one value for all dim
        if do_edge_3d && size(premask, 3)>1
            bookend = zeros(size(premask, 1), size(premask, 2));
            premask = cat(3, bookend, premask, bookend); %bookend with zeros to help 3d edge detection in z
            mask_allroi_approx = edge3(premask, 'approxcanny', edgethresh, edgesig);
            premask = premask(:,:,2:end-1);
            mask_allroi_approx = mask_allroi_approx(:,:,2:end-1);
        else
            for tui = 1:size(premask, 3)
                mask_allroi_approx(:,:,tui) = edge(premask(:,:,tui), 'canny', edgethresh, edgesig(1));
            end
        end
        closing_element_size = 8;
        mask_allroi_approx = imclose(mask_allroi_approx, strel('disk',closing_element_size)); %this appears to work in 2d or 3d basically the same, 2d keeps this section of code shorter


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

if numroi_morph_auto == 1 %for finding a single centroid

    centroids_roi = find_roi_centroids(mask_allroi_approx);

else

    switch subsample_mask_method

        case 'equidistant' % create multiple equal-volume roi along skeleton of mask

            if do_3d
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

                [midx,midy,midz] = graph_sort3(midx,midy,midz); %align the points of the midline starting at the first point and going around in a circle. this requires that the midline be continuous!

                xq = [-min_axis:(length(midx)+min_axis)]; %extend the midline so that it reaches the border of the mask. extrapolate as many points as the minimum axis length

                midx = round(interp1(midx,xq,'linear','extrap'));
                midy = round(interp1(midy,xq,'linear','extrap'));
                midz = round(interp1(midz,xq,'linear','extrap'));

                idxmidkeep = ismember([midx',midy',midz'],[maskx,masky,maskz],'rows'); %keep only the points that exist within the mask
                midx = midx(idxmidkeep);
                midy = midy(idxmidkeep);
                midz = midz(idxmidkeep);

                xq = linspace(1, length(midy), 2*(numroi_morph_auto) + 1)'; %set query points for interpolation (the number of centroids we want). we'll create twice as many points and take every other so that rois on the edges arent clipped
                centmp = [interp1(midy,xq), interp1(midx,xq), interp1(midz,xq)]; %interpolate x and y coordinates, now that they are ordered, into evenly spaced centroids (this allows one to oversample if desired)
                centmp = centmp(2:2:end-1,:); %take every other so that we dont start at the edges, and all are same size

                centroids_roi = cell(1, size(centmp, 1));
                for crmi = 1:size(centmp, 1)
                    centroids_roi{crmi} = centmp(crmi, :); %convert to cell, since centroids_roi is cell elsewhere (to support rois with varying number of discontiguous parts, even though that doesn't occur when using subsample_mask_method 'equidistant')
                end

            else

                error("region is roughly uniform blob, so skeleton approach fails, work in progress finding uniformly distributed centroids within arbitrary 2d or 3d blob")

                mask_allroi_perim = bwperim(mask_allroi_approx);
                centroids_roi = maximin_cx(16, length(size(mask_allroi_approx)),  'mask', ones(size(mask_allroi_approx)));
                
                figure; hold on;
                kbnd = boundary([maskx,masky,maskz]);
                trisurf(kbnd,maskx',masky',maskz','Facecolor','red','FaceAlpha',0.1)
                axis image
                plot3(centroids_roi(:, 1), centroids_roi(:, 2), centroids_roi(:, 3), 'o')
                view(3)



            end

    end

end

%% assign each voxel in the 3d mask to a morphological roi centroid


cenmorphflat = cell2mat(centroids_roi(:));
flatten_key = cell2mat(arrayfun(@(idx) [repmat(idx,size(centroids_roi{idx},1),1), (1:size(centroids_roi{idx},1)).'], (1:numel(centroids_roi)).', 'uniform', 0));
[~, maptmp] = pdist2(cenmorphflat, [masky, maskx, maskz], 'euclidean', 'smallest', 1); %find the index of the centroid that is closest to each voxel in the mask. using euclidean, but maybe chebychev (chessboard)
idx_cenmorph = flatten_key(maptmp, 1); %this records which cell the nearest morph centroid is from


%% find indices for each mophological roi

mask_roi_vec = zeros(numroi_morph_auto, numel_stackmnt, 'logical'); %initialize a logical matrix that is of dimensions centroids x voxels

mask_allroi_approx_plot = mask_allroi_approx;

if isempty(sliceinds_hires) %isempty(stack_hires)

    for i = 1:numroi_morph_auto
        mask_roi_vec(i, sub2ind(size(mask_allroi_approx), masky(idx_cenmorph==i), maskx(idx_cenmorph==i), maskz(idx_cenmorph==i))) = 1; %indices of each roi
    end

else % else downsample the 3 output variables from hires to lores 

    
    %downsample mask_roi_vec
    % map from hi-z-res to lo-z-res (and find multi-roi voxel weighting)
    % for each voxel, after mapping, divide by number of rois contributing to that voxel
    % later the roi signal will be sum across voxels with these weights,
    % this assumes equal contribution from all rois sharing a voxel,
    % which is wrong if there are multiple rois contributing unequally to a voxel
    % but this is better than not accounting for any overlap
    % this approach could be improved further
    % automated rois created with skeleton centroids and pdist2 are not overlapping at first,
    % but they do overlap if the mask is mapped to a smaller mask (hires to lores, eg)
    % later the roi signal will be sum across voxels with these weights,
    maskznew = maskz;
    for ii = 1:length(sliceinds_hires) %for each hires z slice range
        if ii<length(sliceinds_hires)
            zrange = sliceinds_hires(ii):sliceinds_hires(ii+1)-1;
        else
            zrange = sliceinds_hires(ii):size(premask, 3);
        end
        maskznew(ismember(maskznew, zrange)) = ii;
    end


    for i = 1:numroi_morph_auto
        mask_roi_vec(i, sub2ind(size(stackmean_masked), masky(idx_cenmorph==i), maskx(idx_cenmorph==i), maskznew(idx_cenmorph==i))) = 1; %indices of each roi
    end

    mask_roi_vec = single(mask_roi_vec); %in this case only mask_roi_vec is not logical since pixels are weighted, convert before weighting 
    mask_roi_vec = mask_roi_vec ./ sum(mask_roi_vec,1);
    mask_roi_vec(isnan(mask_roi_vec)) = 0;

    %%downsample 3d "allroi" mask for plotting (note this will not quite match union of all roi indices, so it is only used for plotting within this function and is not output)
    F2 = griddedInterpolant(single(mask_allroi_approx), 'linear');
    midpoint_add = median([1 mean(diff(sliceinds_hires))]);  %downsampling using midpoint of hires in z seems better than taking mean
    mask_allroi_approx = F2({ 1:size(mask_allroi_approx,1), 1:size(mask_allroi_approx,2), sliceinds_hires+midpoint_add });
    mask_allroi_approx = logical(mask_allroi_approx);  %rescale after interpolation to be safe


    %%downsample z component of each subroi of each mophological roi centroid
    for rci = 1:length(numroi_morph_auto) %loop over rois
        for rci2 = 1:size(centroids_roi{rci}, 1) %loop over any subrois
            centroids_roi{rci}(rci2,3) = interp1([1, size(premask, 3)], [1, size(stackmean, 3)], centroids_roi{rci}(rci2,3));
        end
    end


end


%% 


if do_plots

    plot_gif(maskmanual, [pth_save_figs_prefix(1:end-4) '_maskmanual_.gif'])
    plot_gif(mask_allroi_approx, [pth_save_figs_prefix(1:end-4) '_mask_.gif'])

    % kbnd = boundary([maskx,masky,maskz]);
    % figure;
    % trisurf(kbnd,maskx',masky',maskz','Facecolor','red','FaceAlpha',0.1)
    % axis image


    if ~isempty(mask_roi_vec)

        overlayarray = rescale(0.2*rescale(mask_allroi_approx_plot) + rescale(premask, 0, 1));

        plot_gif( overlayarray, [pth_save_figs_prefix(1:end-4) '_mask_premask_overlay_.gif'])

        plot_gif(premask, [pth_save_figs_prefix(1:end-4) '_premask_.gif'])

        cmap = distinguishable_colors(size(mask_roi_vec,1));
        double_colormap = 0;
        if double_colormap %like for two halves of PB, EB, etc, made this default 0 since the split is just halfway along mask anyway (not biological)
            num_region_periods = 2; %for example, two halves of pb
        else
            num_region_periods = 1; %for example, two halves of pb
        end
        cmap = repmat(cmap,num_region_periods,1); %if region is periodic with multiple periods

        figure; hold on;
        plot3(maskx, masky, maskz, '.m', 'MarkerSize', 0.1);
        if exist('midx', 'var')
            plot3(midx,midy,midz, '*k', 'MarkerSize', 2.2);
        end
        axis image;
        view(3);

        h = figure; hold on
        %imagesc(mean(mean(stack,3),4)) %plot the image again with max intensity over time to show the whole pb
        for i = 1:numroi_morph_auto %overlay each pixel in its indexed color onto the pb image
            scatter3( maskx(idx_cenmorph == i), masky(idx_cenmorph == i), maskz(idx_cenmorph == i), 'filled', 'MarkerFaceColor', cmap(i,:), 'MarkerFaceAlpha', 0.2 )
        end
        %plot3(midx,midy,midz,'.k', 'MarkerSize',12) %include midline
        %scatter3(centroids_roi(:,2 ), centroids_roi(:,1), centroids_roi(:,3), 80, 'k', 'filled') %show the centroids in each of their colors
        colormap(bone);
        axis image
        axis off
        set(gca,'Visible','off')
        set(gca,'CameraViewAngle',8)
        rotinc = 30;
        views = -180:rotinc:180;
        filenameGIF_cnt = [pth_save_figs_prefix(1:end-4) '_maskfin_.gif'];
        for i = 1:length(views) - 1

            view(views(i)+2, 20)

            frame = getframe(h);
            im = frame2im(frame);
            [imind, cm] = rgb2ind(im,256);

            if i == 1
                imwrite(imind,cm,filenameGIF_cnt, 'DelayTime', 0, 'Loopcount',inf);
            else
                imwrite(imind,cm,filenameGIF_cnt,'DelayTime', 0,'WriteMode','append');
            end
        end


        if strcmp(create_mask_method, 'triangle')

            fuk = sort(tmpup_nz);
            fuk(fuk<thr_tri) = nan;
            figure; subplot(2,1,1);
            plot(sort(tmpup_nz)); hold on; plot(fuk)
            title('triangle threshold (default for threshold method, "triangle"')
            fuk = sort(tmpup_nz);
            fuk(fuk<thr_knee) = nan;
            subplot(2,1,2);
            plot(sort(tmpup_nz)); hold on; plot(fuk)
            title('knee threshold (alternative, not used by default)')

        end

        % % 3d volume plot
        % viewerRegistered = viewer3d(BackgroundColor="black",BackgroundGradient="off");
        % volshow(mask_allroi_approx,Parent=viewerRegistered,RenderingStyle="Isosurface",IsosurfaceValue=0.1, ...
        %     Colormap=[0 1 0],Alphamap=0.1);
        %
        %
        % % test varying clip thresholds for automated PB detection
        % tmptmp = stack.*maskmanual;
        % outz = [];
        % count = 0;
        % clipprct = fliplr([100]);
        % for iiii = clipprct
        %     count = count+1;
        %     tmp3 = mean(tmptmp, 4);
        %     tmp3(tmp3~=0) = rescale(tmp3(tmp3~=0));
        %     %tmp3 = process_stack_for_roi_selection(tmptmp, iiii);
        %     tmpall(:,:,:,count) = tmp3;
        %     idxnz = find(tmp3~=0); %find nonzero indices
        %     idxout = find(isoutlier(tmp3(idxnz))); %find outliers among nonzeros
        %     if isempty(idxout)
        %         break
        %     else
        %         [f1,f2,f3] = ind2sub(size(tmp3), idxnz(idxout));
        %         outz = cat(1, outz, [f1,f2,f3,repmat(count, [length(f1) 1])]);
        %     end
        % end
        % flipdim = 1;
        % plot_gif(tmpall, [filename_im_full(1:end-4) '_fukall_.gif'], flipdim, outz)
        % plot_gif(tmpall, [filename_im_full(1:end-4) '_fukall_.gif'], flipdim)


    end

end


