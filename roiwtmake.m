function roiwt = roiwtmake(roimask)

arguments
    roimask
end

dmroi = 4;%forcing 4th dim as roi dim

if ndims(roimask)>4
    error("roimask input to roiwtmake cannot have more than 4 dimensions (yxzr)")
end

numroi = size(roimask, dmroi);

roiwt = logical(reshape(permute(roimask, [4 1 2 3]), numroi, [])); %logical matrix size (roi,voxels); this works for singleton z and singleton roi, but will cause problem with ambiguous 3d (see error above to prevent this)


end