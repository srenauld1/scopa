function roi_cen = find_roi_centroids(roimasks)

numrois = size(roimasks, 4);

roi_cen = cell(numrois, 1);
for mi = 1:numrois

    roi_cen{mi} = zeros(1, 3); %preallocate zeros in case there are empty rois, also force to be 3d

    tmp = roimasks(:,:,:,mi);
    roiprops = regionprops(logical(tmp), tmp, 'WeightedCentroid'); %pass logical(tmp) as first arg, and tmp as second, if you pass first arg as double(x) or even double(logical(x)) it's a labeled image rather than logical, which will treat any discontiguous regions as a same region (which we don't want), weighted centroid is fine for binary mask and not binary mask
    if any(tmp(:)) %if not any, centroid is nans, but we want zeros, so that's why preallocate roi_cen as zeros and skip here
        for rpi = 1:length(roiprops)
            centmp = roiprops(rpi).WeightedCentroid;
            if length(roiprops(rpi).WeightedCentroid)==3
                roi_cen{mi}(rpi,:) = [centmp(2), centmp(1), centmp(3)]; %switch order for yxz
            else
                roi_cen{mi}(rpi,:) = [centmp(2), centmp(1), 1]; %%switch order for yxz, and this z==1 is fine it will only occur if stack z dim is singleton since roimaskman xyz matches stack xyz size, so later when centroid is used 1 will map to 1
            end
        end
    end

end

end