function [imrgb, imalpha] = roiolmake(opt)

%{

make roi overlay image(s) using input 'roimask' (or 'roipx') and background image 'imgray' (or 'imrgb')
creates overlay for each roi in input 'roimask' (or 'roipx')
overlapping rois are averaged in color and alpha/transparency
rgb average is additive, not subtractive (ie average of green and red is yellow, not brown)
roi r is assigned color r, even if roi is empty
imalpha is a grayscale image matching size of imrgb in spatial dimensions, with value representing alpha/transparency; 
    imalpha is output, and is also an optional input (imalpha input and output can be different if roi alphas get averaged)
this function uses all name-value arguments, even for background image, to make clear distinction between grayscale and rgb inputs, since number of dimensions will not always distinguish them, likewise for roimask and roipx

%}

arguments
    opt.imgray = [] %background image, grayscale, size yxz, can pass in this or imrgb, or neither, but not both; if neither, must pass in roimask (not roipx) to determine image dimensions
    opt.imrgb = [] %background image, rgb, size yx3 or yxz3, must pass in this or imgray, or neither, but not both; if neither, must pass in roimask (not roipx) to determine image dimensions
    opt.imalpha = [] %optional; background image alpha (transparency), size yxa or yxza; only need this if rois have different alpha and you want their alpha averaged
    opt.roimask = [] % mask for roi(s) (size yxzr), matching imgray yxz or imrgb yxz dimensions (z may be singleton), must pass in this or roipx, but not both
    opt.roipx = [] %length-r cell array of roi's linear indices, or vector of linear indices if one roi, must pass in this or roimask, but not both
    opt.rgb = [1,0,0] %color for each roi in output overlay rgb image; size (r,3), where r is number rois, matching roimask final dimension r
    opt.a = 0.3 %alpha (transparency) for output overlay rgb image
    opt.combine = 'occlude' %'add' or 'occlude'; how overlapping rois are combined; 'add' is additive average; 'occlude' puts later rois on top of earlier rois
    opt.dmroi (1,1) {mustBeMember(opt.dmroi,[3,4])} = [] %roi dimension in roimask; can only be 3 or 4 (or empty); only allowed to be set nonempty if background image input is empty (imgray, imrgb, imalpha) and foreground image input is roimask (not roipx), and roimask is 3d; in this case, dmroi determines whether 3rd dim is z or r 
end
imgray = opt.imgray;
imrgb = opt.imrgb;
imalpha = opt.imalpha;
roipx = opt.roipx;
roimask = opt.roimask;
rgb = opt.rgb;
a = opt.a;
combine = opt.combine;
dmroi = opt.dmroi;


%%%% PREP BACKGROUND IMAGE %%%%

singleton_z = 0;
dmroi_must_be_empty = 1;

if isempty(imrgb)
    if isempty(imgray)
        if isempty(imalpha) && isempty(roimask)
            error("if imrgb and imgray are empty, must pass in imalpha or roimask (not roipx) to determine image dimensions")
        else
            if ~isempty(imalpha)
                [ny,nx,nz] = size(imalpha);
            elseif ~isempty(roimask)
                if ndims(roimask)==3
                    dmroi_must_be_empty = 0;
                    if isempty(dmroi)
                        error("if user did not set any background image input (imgray, imrgb, or imalpha), and roimask is 3d, name-value argument rdim must be nonempty to determine whether roimask 3rd dimension is z or r")
                    else
                        if isequal(dmroi, 3)
                            roimask = reshape(roimask, size(roimask,1), size(roimask,2), 1, size(roimask,3));
                            singleton_z = 1;
                        end
                    end
                end
                [ny,nx,nz,nr] = size(roimask);
            end
            imrgb = zeros( ny, nx, nz, 3, 'single');
        end
    else
        imgray = single(rescale(imgray));
        imrgb = cat(ndims(imgray)+1,imgray,imgray,imgray);
    end
else
    if ~isempty(imgray)
        error("cannot pass in both imrgb and imgray")
    end
    if size(imrgb,ndims(imrgb))~=3
        error("last dimension of imrgb must be size 3 (rgb)")
    end
end

if dmroi_must_be_empty && ~isempty(dmroi)
    error("dmroi can only be nonempty if background image input is empty (imgray, imrgb, imalpha) and foreground image input is roimask (not roipx), and roimask is 3d; in this case, dmroi determines whether 3rd dim is z or r")
end

if ndims(imrgb)==3
    singleton_z = 1;
    imrgb = reshape(imrgb, size(imrgb,1), size(imrgb,2), 1, size(imrgb,3));
end

numimdim = ndims(imrgb); %should always be 4
if ~isequal(numimdim,4)
    error("numimdim should alwayds be 4")
end

imrgb_mask = logical(sum(imrgb, numimdim));
if isempty(imalpha)
    imalpha = imrgb_mask.*a(1);
end

if ndims(imrgb)~=4 || ndims(imalpha)<2 || ndims(imalpha)>3
    error("imrgb and must be 4d at this point and imalpha must be 2d or 3d")
end


%%%% PREP ROI MASK %%%%

if isempty(roimask)
    if isempty(roipx)
        error("must pass in either roimask or roipx")
    end
    if isvector(roipx)
        roipx = {roipx};
    else
        error("roimask must be cell, or vector of linear indices, or roi mask")
    end
    roimask = zeros([size(imrgb, [1,2,3]), numel(roipx)], 'logical');
    for k = 1:numel(roipx)
        if ~isempty(roipx{k})
            [i1,i2,i3] = ind2sub(size(imrgb), roipx{k});
            roimask(i1,i2,i3,k) = 1;
        end
    end
else
    if ~isempty(roipx)
        error("cannot pass in both roimask and roipx")
    end
end

if ndims(roimask)<2 || ndims(roimask)>4
    error("at this point, roimask must be 2d, 3d, or 4d")
end
if singleton_z
    if ndims(roimask)==4
        if size(roimask,3)>1
            error("if image has singleton z, so must roimask")
        end
    else
        roimask = reshape(roimask, size(roimask,1), size(roimask,2), 1, size(roimask,3));
    end
end
if ~isequal(size(imrgb, [1,2,3]), size(imalpha, [1,2,3]), size(roimask, [1,2,3]))
    error("roimask must match imrgb in first 3 dimensions")
end
if ~islogical(roimask)
    roimask = logical(roimask);
end

numroi = size(roimask,4);


%%%% PREP OTHER OPTIONAL ARGUMENTS %%%%

if isscalar(a)
    a = repelem(a, numroi);
end
a = single(a);
if isvector(rgb)
    if numel(rgb)~=3
        error("rgb must be (n,3)")
    end
    rgb = rgb(:)'; %make it a row vector
end
if size(rgb,1)==1
    rgb = repmat(rgb, [numroi 1]);
end
rgb = reshape(rgb, [numroi,1,1,3]);
rgb = single(rgb);

if ~isequal(numroi, size(rgb,1), numel(a))
    error("numroi, size(rgb,1), numel(a) must all be equal")
end


%%%% MAKE OVERLAY %%%%

overlaps_sum_plusone = ones(size(imrgb_mask), 'single');
idxne = find(any(roimask, [1,2,3])); %nonnempty roi indices
overlaps = imrgb_mask; %initialize with input image rgb "mask" (anywhere there's a color)
for k = 1:size(roimask,4)

    if ismember(k, idxne) %skip empty rois to save time

        roialpha = roimask(:,:,:,k).*a(k);
        roirgb = roimask(:,:,:,k).*rgb(k,:,:,:); %include 4 colons in rgb to multiply roimask (which is 3d after k indexing) into 4th (rgb) dim

        if strcmp(combine, 'occlude')
            imalpha = imalpha.*~roimask(:,:,:,k);
            imrgb = imrgb.*~roimask(:,:,:,k);
        else
            overlaps = overlaps & sum(roirgb, numimdim); %sum final dim (rgb dim) to mark overlap in any rgb channel, then find overlaps with logical "and" (overlaps is logical array)
            overlaps_sum_plusone = overlaps_sum_plusone + overlaps; %sum overlaps, plus one, to divide to get mean at end of roi loop
        end
        imalpha = imalpha + roialpha;
        imrgb = imrgb + roirgb;

    end

    if k==size(roimask,4) && ~strcmp(combine, 'occlude')   %on final roi, divide by each voxel's number of overlapping (nonempty) rois
        imalpha = imalpha ./ overlaps_sum_plusone; %average where rois overlap
        imrgb = imrgb ./ overlaps_sum_plusone; %average where rois overlap
    end

end

if ndims(imrgb)==3
    imrgb = reshape(imrgb, size(imrgb, 1), size(imrgb, 2), 1, size(imrgb, 3)); %include singleton z
end

% imrgba = cat(4, imrgb, imalpha);

end

