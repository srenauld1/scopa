function roiwt = roiwtmake(roimask)

arguments
    roimask
end

if ndims(roimask)>4
    error("roimask input to roiwtmake cannot have more than 4 dimensions (yxzr)")
end
if ndims(roimask)==3 && ~isempty(roimask)
    fprintf("need to disambiguate singleton z with multiple rois, vs non-singleton z with one roi, ideally without requiring another input (should just make roi first dimension of roimask, rather than last, but that will require changing several functions")
end

dmroi = 4;%ndims(roimask);
numroi = size(roimask, dmroi);

roiwt = logical(reshape(permute(roimask, [4 1 2 3]), numroi, [])); %logical matrix size (roi,voxels); this works for singleton z and singleton roi, but will cause problem with ambiguous 3d (see error above to prevent this)


end