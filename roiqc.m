function roiqc(roimask, opt, opt2)

arguments
    roimask
    opt.minpixperreg = 3 % min pix in each distongiguous region, roi selection criterion
    opt.minroisz = 5 % pixels, roi selection criterion
    opt.maxroisz = 300 % pixels
    opt.maxregperroi = 4 % for discontiguous rois
    opt.inmaskthr = 0.5 % discard roi if more than inmaskthr is outside morphological mask (morph mask is all ones if you don't make one)
    opt2.numbins = 20 % num hist bins for rval and snr caiman output
    opt2.roisrt = 'majoraxis' % 'snr' sorts by caiman output cmsnr, 'none' doens't sort, 'majoraxis' if morphological rois exist, 'majoraxis' will sort along 3d major axis
    opt2.ir = []
    opt2.trm = [0,0]
    opt2.roicen = []
    opt2.mask_allroi = []
    opt2.doplt = 0
end
minpixperreg = opt.minpixperreg;
minroisz = opt.minroisz;
maxroisz = opt.maxroisz;
maxregperroi = opt.maxregperroi;
inmaskthr = opt.inmaskthr;

numbins = opt2.numbins;
roisrt = opt2.roisrt; %if morphological rois exist, 'majoraxis' will sort along 3d major axis
numroiplt = opt2.ir;
trm = opt2.trm;
cnt_roim = opt2.roicen;
mask_roim_all = opt2.mask_allroi;
doplt = opt2.doplt;

error("roiqc function is not finished")

if size(stack,4)>1
    stackmnt = mean(stack,4);
else
    stackmnt = stack;
end


%% prepare vars

num_roim = length(cnt_roim);
cenmorphflat = cell2mat(cnt_roim(:));
flatten_key = cell2mat(arrayfun(@(idx) [repmat(idx,size(cnt_roim{idx},1),1), (1:size(cnt_roim{idx},1)).'], (1:numel(cnt_roim)).', 'uniform', 0));

mask_roim_all_xy = sum(mask_roim_all, 3);

%% load caiman rois (permute, and crop)

load(pth_roif)

if exist('rcor', 'var')%rename vars in old files
    cmsnr = rsnr;
    cmrval = rcor;
    clear rsnr rcor;
end
if exist('rval', 'var')%rename vars in old files
    cmsnr = snr;
    cmrval = rval;
    clear snr rval;
end
if exist('roimasks', 'var') %rename vars in old files
    cma = roimasks;
    cmc = C;
    cms = S;
    cmdff = dff;
    cmdffr = dffr;
    clear roimasks C S dff dffr;
end

cma = permute(cma, [2 1 3 4]);

if ~isempty(regexp(pth_roif, '_2dex_')) %planar/2d extraction

    %convert 2d rois into 3d (by inserting each roi in 3d array in correct slice)
    roimasks_new = zeros(size(cma,1), size(cma,2), size(cma,4), size(cma,4), size(cma,3), 'single');
    for si = 1:size(cma,4)
        for ri = 1:size(cma,3)
            if any(vec(cma(:,:,ri,si)))
                roimasks_new(:,:,si,si,ri) = cma(:,:,ri,si);
            end
        end
    end
    cma = reshape(roimasks_new, size(roimasks_new,1), size(roimasks_new,2), size(roimasks_new,3), size(roimasks_new,4)*size(roimasks_new,5));
    clear roimasks_new

    cmc = reshape(permute(cmc, [1 3 2]), [], size(cmc, 2));
    cmdff = reshape(permute(cmdff, [1 3 2]), [], size(cmdff, 2));
    cmdffr = reshape(permute(cmdffr, [1 3 2]), [], size(cmdffr, 2));
    cms = reshape(permute(cms, [1 3 2]), [], size(cms, 2));
    cmrval = cmrval(:);
    cmsnr = cmsnr(:);


    %cmc = cmdffr;

end

if ~isequal( [size(cma, 1), size(cma, 2)], [size(stackmnt, 1), size(stackmnt, 2)] ) %make sure roimask and stackmnt sizes match
    error("roimask and stackmnt sizes do not match")
end
if ndims(cma)~=4
    error("THIS PIPELINE REQUIRES cma TO BE 4D (x,y,z,roi), EVEN IF SOME DIM (e.g., 3rd dim z) ARE SINGLETON")
end

if any(trm)
    cmc = cmc(:,trm(1)+1:end-trm(2));
    cms = cms(:,trm(1)+1:end-trm(2));
end

numrois = size(cma, 4);


%% find roi centroids


centroids_roif = find_roi_centroids(cma);

%% loop over rois, applying morphological selection criteria


% tmp = cma(cma~=0);
% [~, kneeidx] = knee_pt(tmp(:), [], 1, 1);
% thr_global = tmp(kneeidx); %global threshold on spatial correlation


roi_does_not_exist = ones(numrois, 1);
roi_has_no_response = ones(numrois, 1);
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
roipx = cell(numrois, 1); %suffix 'pixels' distinguishes this from inds_roif_all and inds_roif_wt_all, which are indices into set of roi timeseries, rather than pixel indices like inds_roim, but nevertheless are used in extract_volue_responses the same way as inds_roim, since they are applied to "stack" of roi timeseries rather than movie stack (stack of pixel timeseries)
subroi_primary = ones(numrois, 1);

for ci = 1:numrois

    imtmp = cma(:,:,:,ci);
    imtmp_xy = sum(imtmp, 3);

    noresponseflag = 1;

    if any(centroids_roif{ci}(:)) && ~isempty(centroids_roif{ci}) %if roi exists, apply tests (caiman makes empty rois sometimes, not sure why)

        roiprops = regionprops(logical(imtmp), imtmp, 'MaxIntensity'); %in case roi is discontiguous, apply any func2morph map using the subregion with the highest energy pixel (could do meanintensity instead, or several other things ) this is a bit of a hack, but the best solution probably isn't too different, right?
        [~, subroi_primary(ci)] = max([roiprops(:).MaxIntensity]);

        roi_does_not_exist(ci) = 0;

        if any(cmc(ci,:))
            roi_has_no_response(ci) = 0;
        end

        numpix_within_mask_2d = sum(boolean(imtmp_xy .* mask_roim_all_xy), "all");
        numpix_outside_mask_2d = sum(boolean(imtmp_xy .* ~mask_roim_all_xy), "all");
        proportion_within_mask_2d = numpix_within_mask_2d / (numpix_within_mask_2d + numpix_outside_mask_2d);

        numpix_within_mask_3d = sum(boolean(imtmp .* mask_roim_all), "all");
        numpix_outside_mask_3d = sum(boolean(imtmp .* ~mask_roim_all), "all");
        proportion_within_mask_3d = numpix_within_mask_3d / (numpix_within_mask_3d + numpix_outside_mask_3d);

        proportion_within_mask(ci) = proportion_within_mask_3d;
        centroid_is_outside_mask(ci) = ~mask_roim_all( round(centroids_roif{ci}(subroi_primary(ci), 1)), round(centroids_roif{ci}(subroi_primary(ci), 2)), round(centroids_roif{ci}(subroi_primary(ci), 3)));

        % if strcmp(rgname, 'mivesdalis')
        %     proportion_within_mask(ci) = proportion_within_mask_2d;
        %     centroid_is_outside_mask(ci) = ~mask_roim_all_xy( round(centroids_roif{ci}(subroi_primary(ci), 1)), round(centroids_roif{ci}(subroi_primary(ci), 2)));
        % else
        %     proportion_within_mask(ci) = proportion_within_mask_3d;
        %     centroid_is_outside_mask(ci) = ~mask_roim_all( round(centroids_roif{ci}(subroi_primary(ci), 1)), round(centroids_roif{ci}(subroi_primary(ci), 2)), round(centroids_roif{ci}(subroi_primary(ci), 3)));
        % end

        if proportion_within_mask(ci) >= inmaskthr
            roi_is_mostly_outside_mask(ci) = 0;
        end

        imout = bwareaopen( imtmp, minpixperreg ); %get rid of small disconnected components (to not include in the tests below)

        %%filter ROIs based on size
        numpix_roi = sum(imout(:));
        if numpix_roi > minroisz || numpix_roi < maxroisz
            roi_is_outside_size_limits(ci) = 0;
        end


        %%filter ROIs based on number of disconnected components
        tmp = bwconncomp( imout );
        if tmp.NumObjects < maxregperroi
            roi_is_discontiguous(ci) = 0;
        end


        roi_fails_corr_threshold(ci) = 0; %not implemented yet, set to zero

    end


    if ~(roi_does_not_exist(ci) || ...
            roi_has_no_response(ci) || ...
            centroid_is_outside_mask(ci) || ...
            roi_is_mostly_outside_mask(ci) || ...
            roi_is_outside_size_limits(ci) || ...
            roi_is_discontiguous(ci) || ...
            roi_fails_corr_threshold(ci))

        good_roi_indices(ci) = 1; %pass in all morphological tests

    end

    %% create roi image, and save some roi pixel data


    roipx{ci} = find(imtmp);
    roipixvals = imtmp(roipx{ci});
    [roipixvals_binned{ci},roipixvals_edges{ci}] = histcounts(roipixvals, numbins);
    roipixvals_edges{ci} = roipixvals_edges{ci}(1:end-1);
    roinumpix(ci) = numel(roipixvals);


end

%% map functional rois to morphological rois (ie map to location)

if length(cnt_roim)==1

    idx_vox2roi = ones(length(centroids_roif), 1, 'uint16');

else

    idx_vox2roi = zeros(numrois, 1, 'uint16');
    for ci = 1:numrois %find which morph roi is closest to each functional roi's "primary" subroi (by the way most functional rois don't have multiple subrois)
        [~, maptmp] = pdist2(cenmorphflat, centroids_roif{ci}(subroi_primary(ci),:), 'euclidean', 'smallest', 1); % %map roi centroids to to morphological centroids . . . change euclidian to chebychev??
        idx_vox2roi(ci) = flatten_key(maptmp, 1); %this records which cell the nearest morph centroid is from
    end

end

roiwt = zeros(num_roim, length(idx_vox2roi));
roiwt(sub2ind(size(roiwt), idx_vox2roi, vec(1:numel(idx_vox2roi)))) = 1;

%roiwt_wt weights by fraction of number of pixels relative to the whole morphological 3d roi (usually includes multiple functional rois)
numpix_roi_per_centroid = roiwt.*repmat(roinumpix, [num_roim 1]);
roiwt_wt = numpix_roi_per_centroid ./ sum(numpix_roi_per_centroid, 2);
roiwt_wt(isnan(roiwt_wt)) = 0;


%% sort rois

switch roisrt
    case 'majoraxis'
        [~, roisortinds] = sort(idx_vox2roi);
    case 'snr'
        [~, roisortinds] = sort(cmsnr);
    case 'none'
        roisortinds = 1:numrois;
end

good_roi_indices = good_roi_indices(roisortinds);

roiwt = roiwt(:,roisortinds);
roiwt_wt = roiwt_wt(:,roisortinds);
centroids_roif = centroids_roif(roisortinds);
cma = cma(:,:,:,roisortinds);

cmc = cmc(roisortinds, :);
cmdff = cmdff(roisortinds, :);
try
    cmdffr = cmdffr(roisortinds, :);
catch
    disp("nodffr")
    cmdffr = cmdff(roisortinds, :);
end
cms = cms(roisortinds, :);

cmrval = cmrval(roisortinds);
cmsnr = cmsnr(roisortinds);
roinumpix = roinumpix(roisortinds);
roipixvals_binned = roipixvals_binned(roisortinds);
roipixvals_edges = roipixvals_edges(roisortinds);
roipx = roipx(roisortinds);


%% remove rois that failed morphological criteria above

bad_roi_indices = find(~good_roi_indices);

good_roi_indices = find(good_roi_indices);

cmc = single(cmc(good_roi_indices, :)); %components denoised by caiman (nonnegative . . . that seems bad)
%cmdff = single(cmdff(good_roi_indices, :)); %cmdff computed on cmc
%cmdffr = single(cmdffr(good_roi_indices, :)); %cmdff computed with residuals (no caiman denoising)
%cms = single(cms(good_roi_indices, :)); %deconvolved version of c, not using for now

numroi = length(good_roi_indices);
roipixind_bad = roipx(bad_roi_indices);  %pixel indices of each roi, one roi per cell
roipx = roipx(good_roi_indices);  %pixel indices of each roi, one roi per cell
roiwt = roiwt(:,good_roi_indices); %boolean mask vector of each roi
roiwt_wt = roiwt_wt(:,good_roi_indices); %same as roiwt but weighted pixel indices
roicen = centroids_roif(good_roi_indices);
if any(good_roi_indices) %if there are any rois remaining (don't actually need this except for the logical call below would error)
    mask_allroi = logical(mean(cma(:,:,:,good_roi_indices), 4)); %boolean mask of all rois
else
    mask_allroi = mean(cma(:,:,:,good_roi_indices), 4); %boolean mask of all rois
end
idx_vox2roi = idx_vox2roi(good_roi_indices); %for each pixel in a roi, which roi it belongs to

cmrval = cmrval(good_roi_indices);
cmsnr = cmsnr(good_roi_indices);
roinumpix = roinumpix(good_roi_indices);
roipixvals_binned = roipixvals_binned(good_roi_indices);
roipixvals_edges = roipixvals_edges(good_roi_indices);


pixinds_allroi_tmp = unique(vertcat(roipx{:}));
pixinds_allroi = cell(length(pixinds_allroi_tmp), 1);
for ii = 1:length(pixinds_allroi)
    pixinds_allroi{ii} = pixinds_allroi_tmp(ii); %put each pixel in cell to match what happens with functional rois
end

%% plots

if doplt

    if numroi>numroiplt
        roi_plot_inds_good = round(linspace(1, numroi, numroiplt));
    else
        roi_plot_inds_good = 1:numroi;
    end

    filename_gif = [pth_roif(1:end-4) 'goodrois_subset_' num2str(numroiplt) 'rois_.gif'];
    gifvis = 'on';
    plotchannel = 1;
    stackplt(stackmnt(:,:,:,:,plotchannel), pthgif=filename_gif, gifvis=gifvis, roipx=roipx, ir=roi_plot_inds_good) %include roipx as argument to plot roi overlay

    if length(bad_roi_indices)>numroiplt
        roi_plot_inds_bad = round(linspace(1, length(bad_roi_indices), numroiplt));
    else
        roi_plot_inds_bad = 1:length(bad_roi_indices);
    end

    filename_gif = [pth_roif(1:end-4) 'badrois_subset_' num2str(numroiplt) 'rois_.gif'];
    stackplt(stackmnt(:,:,:,:,plotchannel), pthgif=filename_gif, gifvis=gifvis, roipx=roipixind_bad, ir=roi_plot_inds_bad) %include roipx as argument to plot roi overlay

    figure; imagesc(roiwt); title("which caiman rois are closest to which morph roi")

    %variable 'cma' has not been subset by good_roi_indices
    tmp = cma(:,:,:,good_roi_indices);

    %plot pixel energies (similar to strength of each pixel's contribution to the roi signal)
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
        roimasks_all_masked = rescale(roimasks_all.*mask_roim_all);
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
        saveas( gcf, [pth_roif(1:end-4) 'roisall_' titadd '_.png'])

        figure;
        [numimrows, numimcols] = subplot_tiling(size(roimasks_all_masked, 3));
        for tti = 1:size(roimasks_all_masked, 3)
            subplot(numimrows, numimcols, tti)
            imshow(roimasks_all_masked(:,:,tti));
            axis image; axis off
        end
        sgtitle(['roi mean ' titadd])
        saveas( gcf, [pth_roif(1:end-4) 'roisallmask_' titadd '_.png'])

        figure; imagesc(roimasks_all_2d); title(['roisall2d ' titadd]); axis image
        saveas( gcf, [pth_roif(1:end-4) 'roisall2d_' titadd '_.png'])

        figure; imagesc(roimasks_all_masked_2d); title(['roisall2d ' titadd]); axis image
        saveas( gcf, [pth_roif(1:end-4) 'roisall2dmask_' titadd '_.png'])

    end

    % running = 1;
    % simultaneous = 1;
    % filename_gif = [pth_roif(1:end-4) 'caimanrois_notsimul_bads.gif'];
    % plot_data(resp_roif(bad_roi_indices(roi_plot_inds_bad), :), 'resp_roif', roiindies, filename_gif, [], [], 0, 0)
    % filename_gif = [pth_roif(1:end-4) 'caimanrois_simul_bads.gif'];
    % plot_data(resp_roif(good_roi_indices(roi_plot_inds_good), :), 'resp_roif', roiindies, filename_gif, [], [], running, simultaneous)
    % filename_gif = [pth_roif(1:end-4) 'caimanrois_simul_goods.gif'];
    % plot_data(resp_roif(good_roi_indices(roi_plot_inds_good), :), 'resp_roif', roiindies, filename_gif, [], [], 0, 0)
    % filename_gif = [pth_roif(1:end-4) 'caimanrois_notsimul_goods.gif'];
    % plot_data(resp_roif(good_roi_indices(roi_plot_inds_good), :), 'resp_roif', roiindies, filename_gif, [], [], running, simultaneous)


    % viewerRegistered = viewer3d(BackgroundColor="black",BackgroundGradient="off");
    % volshow(rescale(sum(cma, 4)),Parent=viewerRegistered,RenderingStyle="Isosurface",IsosurfaceValue=0.1, ...
    %     Colormap=[0 1 0],Alphamap=0.1);


    % figure;
    % numplots = size(mask_roif_all, 3);
    % npk = 1:numplots;
    % divtmp = npk(rem(numplots,npk)==0);
    % npc = ceil(divtmp(end/2));
    % npr = numplots/npc;
    % for rmi = 1:size(mask_roif_all, 3)
    %     subplot(npr,npc,rmi);
    %     plot(sort(idx_f2m_all{rmi}))
    % end
    % saveas( gcf, [pth_roif_all{1} '_allclusterinds_.png'])


    % restrict_to_max = 0;
    % if restrict_to_max
    %     maxes = max(reshape(cma, [], numrois));
    %     for mi = 1:length(maxes)
    %         roimasks_maxes(:,:,:,mi) = cma(:,:,:,mi).*(cma(:,:,:,mi)==maxes(mi));
    %     end
    %     cma = roimasks_maxes;
    % end

    %%


    hfg = figure;
    spl1 = subplot(2,1,1);
    spl2 = subplot(2,1,2);
    filename_gif = [pth_roif(1:end-4) '_roimaskkneeeach_.gif'];

    for ci = 1:numrois
        furn = vec(cma(:,:,:,ci));
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

        fig2gif(hfg, ci, filename_gif)

    end
    %%


    furn = vec(cma);

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
    saveas( gcf, [pth_roif(1:end-4) '_roimaskknee_.png'])




end







