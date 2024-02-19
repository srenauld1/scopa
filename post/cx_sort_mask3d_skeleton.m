function centroids_mask3d = cx_sort_mask3d_skeleton(mask3d)

if ndims(mask3d)~=3
    "ADAPT FOR 2D"
    error
end

[masky_seg,maskx_seg,maskz_seg] = ind2sub(size(mask3d),find(mask3d)); %find the cartesian coordinates of points in the mask


min_axis = min([range(maskx_seg),range(masky_seg),range(maskz_seg)]); %find the minimum axis length
mid = bwskel(mask3d,'MinBranchLength',min_axis); %find the midline as the skeleton, shaving out all sub branches that are smaller than the minimum axis length
ep = (convn(double(mid),ones(3,3,3),'same')<3).*mid;
[y0,x0,z0] = ind2sub(size(ep),find(ep,1));

[midy,midx,midz] = ind2sub(size(mid),find(mid));

[midx,midy,midz] = graph_sort3(midx,midy,midz); %align the points of the midline starting at the first point and going around in a circle. this requires that the midline be continuous!

xq = [-min_axis:(length(midx)+min_axis)]; %extend the midline so that it reaches the border of the mask. extrapolate as many points as the minimum axis length

midx = round(interp1(midx,xq,'linear','extrap'));
midy = round(interp1(midy,xq,'linear','extrap'));
midz = round(interp1(midz,xq,'linear','extrap'));

idxmidkeep = ismember([midx',midy',midz'],[maskx_seg,masky_seg,maskz_seg],'rows'); %keep only the points that exist within the mask
midx = midx(idxmidkeep);
midy = midy(idxmidkeep);
midz = midz(idxmidkeep);

xq = linspace(1, length(midy), 2*(numroi_morph) + 1)'; %set query points for interpolation (the number of centroids we want). we'll create twice as many points and take every other so that clusters on the edges arent clipped
centroids_mask3d = [interp1(midy,xq), interp1(midx,xq), interp1(midz,xq)]; %interpolate x and y coordinates, now that they are ordered, into evenly spaced centroids (this allows one to oversample the number of pixels, if desired)
centroids_mask3d = centroids_mask3d(2:2:end-1,:,:); %take every other so that we dont start at the edges, and all are same size
