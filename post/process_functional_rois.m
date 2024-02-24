function [roiinfo, resp] = process_functional_rois(pth_froi, ...
    stack_mnt, roiinfo, regionex, md, opts)


%% params

min_pixels_per_region = opts.min_pixels_per_region;
min_roi_size = opts.min_roi_size;
max_roi_size = opts.max_roi_size;
max_regions_per_roi = opts.max_regions_per_roi;
within_mask_threshold = opts.within_mask_threshold;
numbins = opts.numbins;
sort_roi_method = opts.sort_roi_method; %if morphological rois exist, 'majoraxis' will sort along 3d major axis
foreground_plot_style = opts.foreground_plot_style; %'boundary'; %options to show roi are 'boundary' and 'overlay'
numrois_for_gif = opts.numrois_for_gif;
ncol_each = opts.ncol_each; %number colors in each part of the overlay plot (2 parts are: mean volume/background, and roi/foreground)

do_other_plots = opts.do_other_plots;
saturation_factor_background = opts.saturation_factor_background; %above this fraction of data is sent to max
saturation_factor_rois = opts.saturation_factor_rois; %above this fraction of data is sent to max
normopts = opt.froi.norm;

croptimeinds = md.croptimeinds;
dtmni = md.dtmni;

cnt_mroi = roiinfo.centroids_roi;
mask_mroi_all = roiinfo.mask_allroi;



%% prepare vars

num_mroi = length(cnt_mroi);
cenmorphflat = cell2mat(cnt_mroi(:));
flatten_key = cell2mat(arrayfun(@(idx) [repmat(idx,size(cnt_mroi{idx},1),1), (1:size(cnt_mroi{idx},1)).'], (1:numel(cnt_mroi)).', 'uniform', 0));

stack_mnt_rs = rescale(stack_mnt, 1, ncol_each);

mask_mroi_all_xy = sum(mask_mroi_all, 3);

%% load caiman rois (permute, and crop)

load(pth_froi)

if ~exist('rsnr', 'var')
    rsnr = snr;
    rcor = rval;
    clear snr rval;
end

roimasks = permute(roimasks, [2 1 3 4]);

if ~isempty(regexp(pth_froi, '_2dex_')) %planar/2d extraction

    %convert 2d rois into 3d (by inserting each roi in 3d array in correct slice)
    roimasks_new = zeros(size(roimasks,1), size(roimasks,2), size(roimasks,4), size(roimasks,4), size(roimasks,3), 'single');
    for si = 1:size(roimasks,4)
        for ri = 1:size(roimasks,3)
            if any(vec(roimasks(:,:,ri,si)))
                roimasks_new(:,:,si,si,ri) = roimasks(:,:,ri,si);
            end
        end
    end
    roimasks = reshape(roimasks_new, size(roimasks_new,1), size(roimasks_new,2), size(roimasks_new,3), size(roimasks_new,4)*size(roimasks_new,5));
    clear roimasks_new

    C = reshape(permute(C, [1 3 2]), [], size(C, 2));
    dff = reshape(permute(dff, [1 3 2]), [], size(dff, 2));
    dffr = reshape(permute(dffr, [1 3 2]), [], size(dffr, 2));
    S = reshape(permute(S, [1 3 2]), [], size(S, 2));
    rcor = rcor(:);
    rsnr = rsnr(:);

end

if ~isequal( [size(roimasks, 1), size(roimasks, 2)], [size(stack_mnt_rs, 1), size(stack_mnt_rs, 2)] ) %make sure roimask and stack_mnt sizes match
    error("roimask and stack_mnt sizes do not match")
end
if ndims(roimasks)~=4
    error(sprintf("ERROR, \nTHIS PIPELINE REQUIRES roimasks TO BE 4D (x,y,z,roi), EVEN IF SOME DIM (e.g., 3rd dim z) ARE SINGLETON"))
end

if croptimeinds
    C = C(:,croptimeinds(1)+1:end-croptimeinds(2));
    S = S(:,croptimeinds(1)+1:end-croptimeinds(2));
    dff = dff(:,croptimeinds(1)+1:end-croptimeinds(2));
    dffr = dffr(:,croptimeinds(1)+1:end-croptimeinds(2));
end

numrois = size(roimasks, 4);



%% find roi centroids


centroids_froi = find_roi_centroids(roimasks);

%% loop over rois, applying morphological selection criteria


% tmp = roimasks(roimasks~=0);
% [~, kneeidx] = knee_pt(tmp(:), [], 1, 1);
% thr_global = tmp(kneeidx); %global threshold on spatial correlation


roi_does_not_exist = ones(numrois, 1);
proportion_within_mask = ones(numrois, 1);
centroid_is_outside_mask = ones(numrois, 1);
roi_is_mostly_outside_mask = ones(numrois, 1);
roi_is_outside_size_limits = ones(numrois, 1);
roi_is_discontiguous = ones(numrois, 1);
roi_fails_corr_threshold = ones(numrois, 1);
good_roi_indices = zeros(numrois, 1);
roinumpix = zeros(1, numrois);
roipixvals_binned = cell(numrois, 1);
roipixvals_edges = cell(numrois, 1);
roi_overlay = zeros(size(roimasks), 'single');
pixinds_roi = cell(numrois, 1); %suffix 'pixels' distinguishes this from inds_froi_all and inds_froi_wt_all, which are indices into set of roi timeseries, rather than pixel indices like inds_mroi, but nevertheless are used in extract_volue_responses the same way as inds_mroi, since they are applied to "stack" of roi timeseries rather than movie stack (stack of pixel timeseries)
subroi_primary = ones(numrois, 1);
for ci = 1:numrois

    imtmp = roimasks(:,:,:,ci);
    imtmp_xy = sum(imtmp, 3);


    if any(centroids_froi{ci}(:)) && ~isempty(centroids_froi{ci}) %if roi exists, apply tests (caiman makes empty rois sometimes, not sure why)

        roiprops = regionprops(logical(imtmp), imtmp, 'MaxIntensity'); %in case roi is discontiguous, apply any func2morph map using the subregion with the highest energy pixel (could do meanintensity instead, or several other things ) this is a bit of a hack, but the best solution probably isn't too different, right?
        [~, subroi_primary(ci)] = max([roiprops(:).MaxIntensity]);

        roi_does_not_exist(ci) = 0;

        numpix_within_mask_2d = sum(boolean(imtmp_xy .* mask_mroi_all_xy), "all");
        numpix_outside_mask_2d = sum(boolean(imtmp_xy .* ~mask_mroi_all_xy), "all");
        proportion_within_mask_2d = numpix_within_mask_2d / (numpix_within_mask_2d + numpix_outside_mask_2d);

        numpix_within_mask_3d = sum(boolean(imtmp .* mask_mroi_all), "all");
        numpix_outside_mask_3d = sum(boolean(imtmp .* ~mask_mroi_all), "all");
        proportion_within_mask_3d = numpix_within_mask_3d / (numpix_within_mask_3d + numpix_outside_mask_3d);

        if strcmp(regionex, 'mivesdalis')
            proportion_within_mask(ci) = proportion_within_mask_2d;
            centroid_is_outside_mask(ci) = ~mask_mroi_all_xy( round(centroids_froi{ci}(subroi_primary(ci), 1)), round(centroids_froi{ci}(subroi_primary(ci), 2)));
        else
            proportion_within_mask(ci) = proportion_within_mask_3d;
            centroid_is_outside_mask(ci) = ~mask_mroi_all( round(centroids_froi{ci}(subroi_primary(ci), 1)), round(centroids_froi{ci}(subroi_primary(ci), 2)), round(centroids_froi{ci}(subroi_primary(ci), 3)));
        end

        if proportion_within_mask(ci) >= within_mask_threshold
            roi_is_mostly_outside_mask(ci) = 0;
        end

        imout = bwareaopen( imtmp, min_pixels_per_region ); %get rid of small disconnected components (to not include in the tests below)

        %%filter ROIs based on size
        numpix_roi = sum(imout(:));
        if numpix_roi > min_roi_size || numpix_roi < max_roi_size
            roi_is_outside_size_limits(ci) = 0;
        end


        %%filter ROIs based on number of disconnected components
        tmp = bwconncomp( imout );
        if tmp.NumObjects < max_regions_per_roi
            roi_is_discontiguous(ci) = 0;
        end


        roi_fails_corr_threshold(ci) = 0; %not implemented yet, set to zero

    end


    if ~(roi_does_not_exist(ci) || ...
            centroid_is_outside_mask(ci) || ...
            roi_is_mostly_outside_mask(ci) || ...
            roi_is_outside_size_limits(ci) || ...
            roi_is_discontiguous(ci) || ...
            roi_fails_corr_threshold(ci))

        good_roi_indices(ci) = 1; %pass all morphological tests

    end

    %% create roi image, and save some roi pixel data


    pixinds_roi{ci} = find(imtmp);
    roipixvals = imtmp(pixinds_roi{ci});
    [roipixvals_binned{ci},roipixvals_edges{ci}] = histcounts(roipixvals, numbins);
    roipixvals_edges{ci} = roipixvals_edges{ci}(1:end-1);
    roinumpix(ci) = numel(roipixvals);


    overlay_tmp = rescale(stack_mnt_rs, 1, ncol_each);
    switch foreground_plot_style

        case 'overlay'

            overlay_tmp(pixinds_roi{ci}) = rescale(roipixvals, ncol_each+1, ncol_each*2); %for overlay (filled roi), maintains intensity of original, but with different hue

        case 'boundary'

            bound2d = zeros(size(imtmp), 'logical');
            for ii = 1:size(imtmp, 3)
                bound2d(:,:,ii) = bwperim(imtmp(:,:,ii));
            end

            overlay_tmp(bound2d) = ncol_each*2; %for boundary (hollow roi) with differt hue

    end

    roi_overlay(:,:,:,ci) = overlay_tmp;


end

%% map functional rois to morphological rois (ie map to location)

if length(cnt_mroi)==1

    mapind2ind = ones(1, length(centroids_froi));

else

    mapind2ind = zeros(1, numrois);
    for ci = 1:numrois %find which morph roi is closest to each functional roi's "primary" subroi (by the way most functional rois don't have multiple subrois)
        [~, maptmp] = pdist2(cenmorphflat, centroids_froi{ci}(subroi_primary(ci),:), 'euclidean', 'smallest', 1); % %map roi centroids to to morphological centroids . . . change euclidian to chebychev??
        mapind2ind(ci) = flatten_key(maptmp, 1); %this records which cell the nearest morph centroid is from
    end

end

mask_roi_vec = zeros(num_mroi, length(mapind2ind));
mask_roi_vec(sub2ind(size(mask_roi_vec), mapind2ind, 1:length(mapind2ind))) = 1;

%mask_roi_vec_wt weights by fraction of number of pixels relative to the whole morphological 3d roi (usually includes multiple functional rois)
numpix_roi_per_centroid = mask_roi_vec.*repmat(roinumpix, [num_mroi 1]);
mask_roi_vec_wt = numpix_roi_per_centroid ./ sum(numpix_roi_per_centroid, 2);
mask_roi_vec_wt(isnan(mask_roi_vec_wt)) = 0;


%% sort rois

switch sort_roi_method
    case 'majoraxis'
        [~, roisortinds] = sort(mapind2ind);
    case 'snr'
        [~, roisortinds] = sort(rsnr);
    case 'none'
        roisortinds = 1:numrois;
end

good_roi_indices = good_roi_indices(roisortinds);

mask_roi_vec = mask_roi_vec(:,roisortinds);
mask_roi_vec_wt = mask_roi_vec_wt(:,roisortinds);
centroids_froi = centroids_froi(roisortinds);
roimasks = roimasks(:,:,:,roisortinds);

C = C(roisortinds, :);
dff = dff(roisortinds, :);
try
    dffr = dffr(roisortinds, :);
catch
    disp("nodffr")
    dffr = dff(roisortinds, :);
end
S = S(roisortinds, :);

rcor = rcor(roisortinds);
rsnr = rsnr(roisortinds);
roinumpix = roinumpix(roisortinds);
roipixvals_binned = roipixvals_binned(roisortinds);
roipixvals_edges = roipixvals_edges(roisortinds);
pixinds_roi = pixinds_roi(roisortinds);

roi_overlay = roi_overlay(:,:,:,roisortinds);

%% remove rois that failed morphological criteria above

bad_roi_indices = find(~good_roi_indices);
roi_overlay_bad = roi_overlay(:,:,:,bad_roi_indices); %no need to save bad rois to roiinfo struct

good_roi_indices = find(good_roi_indices);
roi_overlay = roi_overlay(:,:,:,good_roi_indices);


%cmc = single(C(good_roi_indices, :)); %components denoised by caiman (nonnegative . . . that seems bad)
%cmdff = single(dff(good_roi_indices, :)); %dff computed on C
cmdffr = single(dffr(good_roi_indices, :)); %dff computed with residuals (no caiman denoising)
%cms = single(S(good_roi_indices, :)); %deconvolved version of c, not using for now

numroi = length(good_roi_indices);
pixinds_roi = pixinds_roi(good_roi_indices);  %pixel indices of each roi, one roi per cell
mask_roi_vec = mask_roi_vec(:,good_roi_indices); %boolean mask vector of each roi
mask_roi_vec_wt = mask_roi_vec_wt(:,good_roi_indices); %same as mask_roi_vec but weighted pixel indices
centroids_roi = centroids_froi(good_roi_indices);
if any(good_roi_indices) %if there are any rois remaining (don't actually need this except for the logical call below would error)
    mask_allroi = logical(mean(roimasks(:,:,:,good_roi_indices), 4)); %boolean mask of all rois
else
    mask_allroi = mean(roimasks(:,:,:,good_roi_indices), 4); %boolean mask of all rois
end
mapind2ind = mapind2ind(good_roi_indices); %for each pixel in a roi, which roi it belongs to

rcor = rcor(good_roi_indices);
rsnr = rsnr(good_roi_indices);
roinumpix = roinumpix(good_roi_indices);
roipixvals_binned = roipixvals_binned(good_roi_indices);
roipixvals_edges = roipixvals_edges(good_roi_indices);


pixinds_allroi_tmp = unique(vertcat(pixinds_roi{:}));
pixinds_allroi = cell(length(pixinds_allroi_tmp), 1);
for ii = 1:length(pixinds_allroi)
    pixinds_allroi{ii} = pixinds_allroi_tmp(ii); %put each pixel in cell to match what happens with functional rois
end


%% compute functional (caiman) responses averaged by which morphological roi they belong to


resp = extract_roi_responses(resp_froi, mask_roi_vec, pth_froi, normopts, dtmni); %this version not weighted by area by passing mask_roi_vec

% resp = extract_roi_responses(resp_froi, mask_roi_vec_wt, pth_froi, normopts, dtmni, resp);  %this version weighted by area by passing mask_roi_vec_wt, appends output resp to input resp, so the nonweighted version is retained



%% plots


if numrois_for_gif~=0

    %create colormap for roi+mean image overlay (roi is red by default)
    startcol1 = [0 0 0]; %start color for part 1 (mean volume/background)
    endcol1 = [1 1 1]; %end color for part 1 (mean volume/background)
    startcol2 = [0 0 0]; %start color for part 2 (roi/foreground)
    endcol2 = [1 0 0]; %end color for part 2 (roi/foreground)
    cmap_method = '1d'; %colormap interpolation is 1d along arc of colorwheel, or 2d through colorwheel (1d is intuitive i think)

    cmap_im = colormap_custom(cmap_method, ncol_each, ...
        startcol1, endcol1, saturation_factor_background, ...
        startcol2, endcol2, saturation_factor_rois);

    if isempty(numrois_for_gif)
        numrois_for_gif = numroi;
    end


    if numroi>numrois_for_gif
        roi_plot_inds_good = round(linspace(1, numroi, numrois_for_gif));
    else
        roi_plot_inds_good = 1:numroi;
    end

    filename_gif = [pth_froi(1:end-4) 'goodrois_subset_' num2str(numrois_for_gif) 'rois_.gif'];
    plot_gif(roi_overlay(:,:,:, roi_plot_inds_good), filename_gif, cmap_im)

    if length(bad_roi_indices)>numrois_for_gif
        roi_plot_inds_bad = round(linspace(1, length(bad_roi_indices), numrois_for_gif));
    else
        roi_plot_inds_bad = 1:length(bad_roi_indices);
    end

    filename_gif = [pth_froi(1:end-4) 'badrois_subset_' num2str(numrois_for_gif) 'rois_.gif'];
    plot_gif(roi_overlay_bad(:,:,:, roi_plot_inds_bad), filename_gif, cmap_im)

end

%variable 'roimasks' has not been subset by good_roi_indices

if do_other_plots

    tmp = roimasks(:,:,:,good_roi_indices);

    %plot pixel energies (kind of like the strength of each pixel's contribution to the roi signal)
    tmpnz = tmp(tmp~=0);
    figure; subplot(2,1,1); hist(tmpnz);
    subplot(2,1,2); plot(sort(tmpnz));

    [histdt, histx] = hist(tmpnz(:), 1000);
    thrbin_tri = triangle_threshold(histdt, 'R', 1);
    thr_tri = histx(thrbin_tri);

    [~, thrbin_knee] = knee_pt(tmpnz(:), [], 1, 1);
    thr_knee = tmpnz(thrbin_knee);

    furn = sort(tmpnz);
    furn(furn<thr_tri) = nan;
    figure; subplot(2,1,1);
    plot(sort(tmpnz)); hold on; plot(furn)
    title('pixel energy, triangle threshold')
    furn = sort(tmpnz);
    furn(furn<thr_knee) = nan;
    subplot(2,1,2);
    plot(sort(tmpnz)); hold on; plot(furn)
    title('pixel energy knee threshold')


    for ptti = 1:2

        if ptti == 2
            tmp(tmp<thr_knee) = 0;
            titadd = 'thr';
        else
            titadd = '';
        end

        roimasks_all = rescale(mean(tmp, 4));
        roimasks_all_masked = rescale(roimasks_all.*mask_mroi_all);
        roimasks_all_2d = mean(roimasks_all, 3);
        roimasks_all_masked_2d = mean(roimasks_all_masked, 3);


        figure;
        [numimrows, numimcols] = subplot_tiling(size(roimasks_all, 3));
        for tti = 1:size(roimasks_all, 3)
            subplot(numimrows, numimcols, tti)
            imshow(roimasks_all(:,:,tti));
            axis image; axis off
        end
        sgtitle(['roi mean ' titadd])
        saveas( gcf, [pth_froi(1:end-4) 'roisall_' titadd '_.png'])

        figure;
        [numimrows, numimcols] = subplot_tiling(size(roimasks_all_masked, 3));
        for tti = 1:size(roimasks_all_masked, 3)
            subplot(numimrows, numimcols, tti)
            imshow(roimasks_all_masked(:,:,tti));
            axis image; axis off
        end
        sgtitle(['roi mean ' titadd])
        saveas( gcf, [pth_froi(1:end-4) 'roisallmask_' titadd '_.png'])

        figure; imagesc(roimasks_all_2d); title(['roisall2d ' titadd]); axis image
        saveas( gcf, [pth_froi(1:end-4) 'roisall2d_' titadd '_.png'])

        figure; imagesc(roimasks_all_masked_2d); title(['roisall2d ' titadd]); axis image
        saveas( gcf, [pth_froi(1:end-4) 'roisall2dmask_' titadd '_.png'])

    end

    % running = 1;
    % simultaneous = 1;
    % filename_gif = [pth_froi(1:end-4) 'caimanrois_notsimul_bads.gif'];
    % plot_data(resp_froi(bad_roi_indices(roi_plot_inds_bad), :), 'resp_froi', roiindies, filename_gif, [], [], 0, 0)
    % filename_gif = [pth_froi(1:end-4) 'caimanrois_simul_bads.gif'];
    % plot_data(resp_froi(good_roi_indices(roi_plot_inds_good), :), 'resp_froi', roiindies, filename_gif, [], [], running, simultaneous)
    % filename_gif = [pth_froi(1:end-4) 'caimanrois_simul_goods.gif'];
    % plot_data(resp_froi(good_roi_indices(roi_plot_inds_good), :), 'resp_froi', roiindies, filename_gif, [], [], 0, 0)
    % filename_gif = [pth_froi(1:end-4) 'caimanrois_notsimul_goods.gif'];
    % plot_data(resp_froi(good_roi_indices(roi_plot_inds_good), :), 'resp_froi', roiindies, filename_gif, [], [], running, simultaneous)


    % viewerRegistered = viewer3d(BackgroundColor="black",BackgroundGradient="off");
    % volshow(rescale(sum(roimasks, 4)),Parent=viewerRegistered,RenderingStyle="Isosurface",IsosurfaceValue=0.1, ...
    %     Colormap=[0 1 0],Alphamap=0.1);


    % figure;
    % numplots = size(mask_froi_all, 3);
    % npk = 1:numplots;
    % divtmp = npk(rem(numplots,npk)==0);
    % npc = ceil(divtmp(end/2));
    % npr = numplots/npc;
    % for rmi = 1:size(mask_froi_all, 3)
    %     subplot(npr,npc,rmi);
    %     plot(sort(idx_f2m_all{rmi}))
    % end
    % saveas( gcf, [pth_froi_all{1} '_allclusterinds_.png'])


    % restrict_to_max = 0;
    % if restrict_to_max
    %     maxes = max(reshape(roimasks, [], numrois));
    %     for mi = 1:length(maxes)
    %         roimasks_maxes(:,:,:,mi) = roimasks(:,:,:,mi).*(roimasks(:,:,:,mi)==maxes(mi));
    %     end
    %     roimasks = roimasks_maxes;
    % end
    %%


    hfg = figure;
    ncolgif = 128;
    spl1 = subplot(2,1,1);
    spl2 = subplot(2,1,2);
    filenamegif = [pth_froi(1:end-4) '_roimaskkneeeach_.gif'];

    for ci = 1:numrois
        furn = vec(roimasks(:,:,:,ci));
        furn = furn(furn~=0);
        if ~isempty(furn)
            furnsort = sort(furn);
            [~, kneeidx_each] = knee_pt(furnsort,[],1, 1);
            if isnan(kneeidx_each)
                kneeidx_each = 1;
            end
            if ci == 1
                pl11 = plot(spl1, furn);
                hold(spl1, 'on')
                pl12 = yline(spl1, furnsort(kneeidx_each));
                hold(spl1, 'off')
                hold(spl2, 'on')
                pl21 = plot(spl2, furnsort);
                pl22 = scatter(spl2, kneeidx_each, furnsort(kneeidx_each), 'm', 'filled');
                hold(spl2, 'off')
            else
                pl11.YData = furn;
                pl12.Value = furnsort(kneeidx_each);
                pl21.YData = furnsort;
                pl22.XData = kneeidx_each;
                pl22.YData = furnsort(kneeidx_each);
            end

            % knee_all(ci) = furnsort(kneeidx_each);
            sgtitle("spatial correlation (?) for single roi")
        end

        frame = getframe(hfg);
        im = frame2im(frame);
        [imind, cm] = rgb2ind(im, ncolgif);

        if ci==1
            imwrite(imind, cm, filenamegif, 'DelayTime', 0, 'Loopcount', inf);
        else
            imwrite(imind, cm, filenamegif,'DelayTime', 0, 'WriteMode', 'append');
        end

    end
    %%


    furn = vec(roimasks);

    furn = furn(furn~=0);
    furnsort = sort(furn);
    [~, kneeidx] = knee_pt(furnsort,[],1, 1);

    figure;
    subplot(2,1,1);
    plot(furn);
    hold on
    yline(furnsort(kneeidx))
    subplot(2,1,2);
    plot(furnsort);
    hold on
    scatter(kneeidx, furnsort(kneeidx), 'm', 'filled');
    sgtitle("spatial correlation (?) for all rois")
    saveas( gcf, [pth_froi(1:end-4) '_roimaskknee_.png'])




end



%% assign to struct

roiinfo.roi_overlay = roi_overlay;
%resp_froi.cmc = cmc; %components denoised by caiman (nonnegative . . . that seems bad)
%resp_froi.cmdff = cmdff; %dff computed on C
resp_froi.cmdffr = cmdffr; %dff computed with residuals (no caiman denoising)
%resp_froi.cms = cms; %deconvolved version of c, not using for now
roiinfo.numroi = numroi;
roiinfo.pixinds_roi = pixinds_roi;  %pixel indices of each roi, one roi per cell
roiinfo.mask_roi_vec = mask_roi_vec; %boolean mask vector of each roi
roiinfo.mask_roi_vec_wt = mask_roi_vec_wt; %same as mask_roi_vec but weighted pixel indices
roiinfo.centroids_roi = centroids_froi;
roiinfo.mask_allroi = mask_allroi; %boolean mask of all rois
roiinfo.mapind2ind = mapind2ind; %for each pixel in a roi, which roi it belongs to
roiinfo.rcor = rcor;
roiinfo.rsnr = rsnr;
roiinfo.roinumpix = roinumpix;
roiinfo.roipixvals_binned = roipixvals_binned;
roiinfo.roipixvals_edges = roipixvals_edges;
roiinfo.pixinds_allroi = pixinds_allroi;



