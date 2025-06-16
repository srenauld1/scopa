function roiwt = roiwtmake(roimask)

arguments
    roimask
end

if ndims(roimask)~=4
    error("roimask input to roiwtmake cannot have more than 4 dimensions (yxzr)")
end

dmroi = ndims(roimask);
numroi = size(roimask, dmroi);

roiwt = logical(reshape(permute(roimask, [4 1 2 3]), numroi, [])); %logical matrix size (roi,voxels)


end