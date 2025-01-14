function roimask = roimauto(stackmnt, roimask, widyxz, regionex, opt)

arguments
    stackmnt
    roimask
    widyxz
    regionex
    opt
end

chan = opt.chan;
numroi_init = opt.numroi;
maskmake = opt.maskmake;
maskseg = opt.maskseg;
edgethr = opt.edgethr;
edgesig = opt.edgesig;
celsz = opt.celsz;
do3d = opt.do3d;

numchan = size(stackmnt,5);
for c = 1:numchan
    if ismember(c,chan)
        if ~isequal(numroi_init, 0)
            roimask{c} = roimauto_onechan(stackmnt(:,:,:,:,c), roimask{c}, numroi_init, widyxz, regionex, maskmake, maskseg, edgethr, edgesig, celsz, do3d);
        end
    end
end

end

function roimaskout = roimauto_onechan(stackmnt, roimaskin, numroi_init, widyxz, regionex, maskmake, maskseg, edgethr, edgesig, celsz, do3d)

%this function has several partially overlapping control features,
%organization is meant to make it easy to add new methods (e.g. by
%creating new maskseg and inserting in switch statement)
%stackmnt must be 3d (xyz), although 3rd dim (z) can be singleton
%roimaskin must match dimensionality of stackmnt, or be lower dimensional

%% preprocess stackmnt, make mean stackmnt


stackmnt = rescale(stackmnt);
numel_stackmnt = numel(stackmnt);

if isempty(roimaskin)
    roimaskin = 1;
end

num_roim_manual = size(roimaskin, 4);

if num_roim_manual>1
    error(sprintf("num_roim_manual is greater than one AND numroiauto is greater than zero" + newline + ...
        "DELETE OR RENAME pth_roimaskman AND DRAW MANUAL MORPHOLOGICAL ROIS AGAIN" + newline + ...
        "OR KEEP MANUAL MORPHOLOGICAL ROIS AND REQUEST 0-1 AUTOMATED MORPHOLOGICAL ROIS" + newline))
end


if do3d==1 && size(stackmnt, 3)==1 %if z dim is singleton
    fprintf('WARNING, cannot make requested 3d mask because stackmnt is 2d, making 2d mask instead')
    do3d = 0; %override if stackmnt is only 2d
end

% if do3d==0 && size(stackmnt, 3)>1
%     stackmnt = rescale(mean(stackmnt, 3));
% end


%% mask mean stackmnt with any available manual mask (if none was made, roimaskin is all ones, ie has no effect)

roimaskman_allrois = logical(sum(roimaskin, 4)); %if there's a 4th dim, it's rois co collapse it
premask = stackmnt.*roimaskman_allrois; %don't change this variable because you need it below


%% threshold premask to create mask

mask_allroi_approx = zeros(size(premask));

switch maskmake

    case 'edge' %find 3d mask edges, smooth them, apply morphological close

        if do3d && size(premask, 3)>1
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

[masky,maskx,maskz] = ind2sub(size(mask_allroi_approx), find(mask_allroi_approx)); %find the cartesian coordinates of points in the mask


%% find 3d mask centroids

numroi_final = numroi_init; %as of 240605 these will match for all cases except 'uniform' or 'uniformp' where do3d~=0

if numroi_init == 1 %for finding a single centroid

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

                xq = linspace(1, length(midy), 2*(numroi_init) + 1)'; %set query points for interpolation (the number of centroids we want). we'll create twice as many points and take every other so that rois on the edges arent clipped
                centmp = [interp1(midy,xq), interp1(midx,xq), interp1(midz,xq)]; %interpolate x and y coordinates, now that they are ordered, into evenly spaced centroids (this allows one to oversample if desired)
                centmp = centmp(2:2:end-1,:); %take every other so that we dont start at the edges, and all are same size

            else

                error(sprintf("region '" + regionex + "' is roughly uniform blob, so maskseg 'skeleton' fails; try maskseg 'uniform' for roughly equal-volume ROIs within 2d or 3d regionex"))

            end

        case {'uniform'} % create multiple roughly equal-volume roi by partitioning regionex into numroi_init groups

            if isempty(widyxz)
                error("you did not pass argument widyxz, or you passed empty widyxz, but you also requested maskseg 'uniform', which requires nonempty argument widyxz")
            end
            ywid = widyxz(1);
            xwid = widyxz(2);
            zwid = widyxz(3);


            if do3d

                [tmp, centmp, bin_prctiles] = probability_bin([masky, maskx, maskz], numroi_init, 1, 0); %iteratively median split along dimension of greatest variance, ties are randomly assigned, so as of 240509, results are not reproducible, although differences are typically not major; so for reproducibility, pipeline loads saves/loads previous results

            else %else split into roughly equal area rois on each slice in mask, rounding number rois for each slice to nearest power of 2 proportional to number of voxels relative to total (typically lots of inaccuracy there)

                uz = unique(maskz);
                for uzi = 1:numel(uz)
                    zinds_each{uzi} = find(maskz==uz(uzi));
                    num_vox_each_slice(uzi) = numel(zinds_each{uzi});
                    frac_vox_each_slice(uzi) = num_vox_each_slice(uzi) / numel(maskz);
                    ideal_roim_auto_each_slice(uzi) = frac_vox_each_slice(uzi) * numroi_init;
                end
                rnds = pow2(round(log2(ideal_roim_auto_each_slice))); %rnds = round(frac_roim_auto_each_slice);

                numroi_final = sum(rnds);
                if numroi_init~=numroi_final
                    sprintf("warning, changing numroi_init is " + num2str(numroi_init) + " while numroi_final is " + num2str(numroi_final))
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
            % idx_vox2roi = tmp(:,1); %previously this was an alternative to deriving idx_vox2roi below; it is very similar
            centmp = centmp.';

    end

    roicen = cell(1, size(centmp, 1));
    for crmi = 1:size(centmp, 1)
        roicen{crmi} = centmp(crmi, :); %convert to cell, since roicen is cell elsewhere (to support rois with varying number of discontiguous parts, even though that doesn't occur when using maskseg 'equidistant')
    end

end

%% assign each voxel in the 3d mask to a morphological roi centroid

cenmorphflat = cell2mat(roicen(:));
flatten_key = cell2mat(arrayfun(@(idx) [repmat(idx,size(roicen{idx},1),1), (1:size(roicen{idx},1)).'], (1:numel(roicen)).', 'uniform', 0));
[~, maptmp] = pdist2(cenmorphflat, [masky, maskx, maskz], 'euclidean', 'smallest', 1); %find the index of the centroid that is closest to each voxel in the mask. using euclidean, but maybe chebychev (chessboard)
idx_vox2roi = uint16(flatten_key(maptmp, 1)); %this records which cell the nearest morph centroid is from

%% find indices for each mophological roi

roiwt = zeros(numroi_final, numel_stackmnt, 'single'); %size [rois, voxels], describes how each voxel contirbutes to roi response, since roi can occupy less than entire voxel (in z dimension especially)
for i = 1:numroi_final
    roiwt(i, sub2ind(size(mask_allroi_approx), masky(idx_vox2roi==i), maskx(idx_vox2roi==i), maskz(idx_vox2roi==i))) = 1; %indices of each roi
end

if ndims(stackmnt)==2
    roimaskout = reshape(roiwt, [size(stackmnt), 1, numroi_final] );
elseif ndims(stackmnt)==3
    roimaskout = reshape(roiwt, [size(stackmnt), numroi_final] );
end




end

