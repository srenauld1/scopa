function [roi_is_outside_size_limits, roi_is_discontiguous] = ...
    cx_filter_rois_by_morphology(imin, min_pixels_per_region, min_roi_size, ...
    max_roi_size, max_regions_per_roi)


imout = bwareaopen( imin, min_pixels_per_region ); %get rid of small disconnected components (to not include in the tests below)


%% filter ROIs based on size

numpix = sum(imout(:));
if numpix > min_roi_size || numpix < max_roi_size
    roi_is_outside_size_limits = 0;
end


%% filter ROIs based on number of disconnected components

tmp = bwconncomp( imout );
if tmp.NumObjects < max_regions_per_roi
    roi_is_discontiguous = 0;
end



