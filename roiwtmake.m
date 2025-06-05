function roiwt = roiwtmake(stackmnt, roimask)

arguments
    stackmnt
    roimask
end

if ndims(stackmnt)>3
    error("stackmnt input to roiwtmake must be single channel, cannot have more than 3 dimensions")
end
if ndims(roimask)==ndims(stackmnt) || ndims(roimask)==ndims(stackmnt)+1
    dmroi = ndims(stackmnt)+1;
elseif size(stackmnt,3)==1 && ndims(roimask)==ndims(stackmnt)+2
    dmroi = ndims(stackmnt)+2;
else
    error("if one roi and non-singleton z, ndims(roimask) must equal ndims(stackmnt); if multiple rois and non-singleton z, ndims(roimask) must equal ndims(stackmnt)+1; if multiple rois and singleton z, ndims(roimask) must equal ndims(stackmnt)+2")
end

numroi = size(roimask, dmroi);
roiwt = zeros(numroi, numel(sum(roimask, dmroi)), 'logical');  %initialize a logical matrix that is size (centroids, voxels)
for mi = 1:numroi
    if dmroi==3
        tmp = roimask(:,:,mi);
    elseif dmroi==4
        tmp = roimask(:,:,:,mi);
    else
        error("dmroi must be 2 or 3")
    end
    roiwt(mi, logical(tmp)) = true; %indices of each roi
end

end