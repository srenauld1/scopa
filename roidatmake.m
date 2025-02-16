function roidat = roidatmake(stackmnt, roimask, regionex, maskname, pthstack)

arguments
    stackmnt
    roimask
    regionex = []
    maskname = []
    pthstack = []
end

numchan = size(stackmnt,5);
roidat = cell(numchan, 1);
for c = 1:numchan
    if ~isempty(roimask{c})
        roidat{c} = roidatmake_onechan(stackmnt(:,:,:,:,c), roimask{c}, c, regionex, maskname, pthstack); 
    end
end


end



function roidat = roidatmake_onechan(stackmnt_onechan, roimask_onechan, chan, regionex, maskname, pthstack)

roiwt = roiwtmake(stackmnt_onechan, roimask_onechan);
numroi = size(roiwt,1);
roicen = find_roi_centroids(roimask_onechan);

mask_allroi = zeros(size(stackmnt_onechan, 1), size(stackmnt_onechan, 2), size(stackmnt_onechan, 3), 'logical');

roipx = cell(numroi, 1);
pixinds_bnd_roi = cell(numroi, 1);
bnd2d = zeros(size(mask_allroi), 'logical');
for ii = 1:length(roipx)
    roipx{ii} = find(vec(roiwt(ii,:))); %pixel indices of each roi
    mask_allroi(roipx{ii}) = 1;
    bnd2d(:) = 0;
    for jj = 1:size(mask_allroi, 3)
        bnd2d(:,:,jj) = bwperim(mask_allroi(:,:,jj));
    end
    pixinds_bnd_roi{ii} = find(vec(bnd2d)); %pixel indices of each roi boundary
    mask_allroi(:) = 0;
end

pixinds_allroi_tmp = unique(vertcat(roipx{:})); %this is not always the same as find(mask_allroi) inside morph auto function above, since rois can be overlapping, and also sometimes derived from interpolated z

mask_allroi(pixinds_allroi_tmp) = 1;

[masky,maskx,maskz] = ind2sub(size(mask_allroi),find(mask_allroi)); %find the cartesian coordinates of points in the mask

roicen_flat = cell2mat(roicen(:));
flatten_key = cell2mat(arrayfun(@(idx) [repmat(idx,size(roicen{idx},1),1), (1:size(roicen{idx},1)).'], (1:numel(roicen)).', 'uniform', 0));

pixinds_allroi = cell(length(pixinds_allroi_tmp), 1);
idx_vox2roi = zeros(length(pixinds_allroi_tmp), 1, 'uint16');
for ii = 1:numel(pixinds_allroi) %one pixel at a time
    [tmpy, tmpx, tmpz] = ind2sub(size(mask_allroi), pixinds_allroi_tmp(ii));

    [~, maptmp] = pdist2(roicen_flat, [tmpy, tmpx, tmpz], 'euclidean', 'smallest', 1); %map roi centroids to to morphological centroids . . . change euclidian to chebychev??
    idx_vox2roi(ii) = flatten_key(maptmp, 1); %this records which cell the nearest morph centroid is from

    pixinds_allroi{ii} = pixinds_allroi_tmp(ii); %put in cell array to match what happens with functional rois
end


roidat.regionex = regionex;
roidat.maskname = maskname;
roidat.pthstack = pthstack;
roidat.chan = chan;
roidat.numroi = numroi;
roidat.roipx = roipx;  %pixel indices of each roi, one roi per cell
roidat.roiwt = roiwt; %boolean mask vector of each roi
roidat.roicen = roicen;
roidat.mask_allroi = mask_allroi; %boolean mask of all rois
roidat.idx_vox2roi = idx_vox2roi; %for each pixel in a roi, which roi it belongs to
roidat.cmrval = [];
roidat.cmsnr = [];
roidat.roinumpix = [];
roidat.roipixvals_binned = [];
roidat.roipixvals_edges = [];
roidat.pixinds_allroi = pixinds_allroi; %all pixels in all rois, one pixel for each cell (treating each pixel as a roi to match structure of roipx)
roidat.stackmnt = stackmnt_onechan; %index after taking mean (if glb('stackmnt') isn't set, to save ram; %roi timeseries are single precision, so this can be too, it won't be very big

roidat = orderfields(roidat);

end