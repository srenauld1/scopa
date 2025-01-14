function roiwt = roiwtmake(stackmnt, roimask)

arguments
    stackmnt
    roimask
end

if ndims(stackmnt)>3
    error("stackmnt input to roiwtmake must be single channel, cannot have more than 3 dimensions")
end
if ndims(roimask)~=ndims(stackmnt) && ndims(roimask)~=ndims(stackmnt)+1
    error("ndims(roimask) must equal ndims(stackmnt)+1")
end

dmroi = ndims(stackmnt)+1;
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
    [maskytmp, maskxtmp, maskztmp] = ind2sub(size(tmp), find(tmp));
    roiwt(mi, sub2ind(size(tmp), maskytmp, maskxtmp, maskztmp)) = true; %indices of each roi
end

end