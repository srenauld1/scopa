function [imroi, imalpha] = roiolmake(imbg, roipx, opt)

% make overlay for roi set defined by roipx, background is imbg;
% roipx is cell array of roi pixel linear indices into imbg
% imbg is the grayscale image stack, used as background
% imroi is rgb stack matching size of imgb, but with color representing rois 
% overlapping rois are averaged in color and transparency/alpha
% imalpha is a grayscale stack matching size of imgb, with value representing transparency 
% uses persistent variables because typically called in plotting loop

arguments
    imbg
    roipx
    opt.col = [1 0 0] 
    opt.alp = 0.3
end
col = opt.col;
alp = opt.alp;

persistent imalpha_oneroi
persistent imroi_oneroi

if isempty(imalpha_oneroi) && isempty(imroi_oneroi)
    imalpha_oneroi = zeros(size(imbg,1), size(imbg,2), size(imbg,3), size(imbg,4), size(imbg,5), 'single');
    imroi_oneroi = repmat(imalpha_oneroi, [ones(1, numel(size(imalpha_oneroi))) 3]);
end

if ~iscell(roipx)
    if isvector(roipx)
        roipx = {roipx};
    else
        error("roipx must be cell, or vector")
    end
end
numroi = numel(roipx); %do after possible conversion to cell 
if size(col, 1)==1
    col = repmat(col, [numroi 1]);
end
if numel(alp)==1
    alp = repelem(alp, numroi);
end

assert(isequal(numroi,size(col,1),numel(alp)))


rcnt = 0;
for ri = 1:numel(roipx)
    if ~isempty(roipx{ri})
        rcnt = rcnt+1;
        [imroi_oneroi, imalpha_oneroi] = roiolmake_each(roipx{ri}, imroi_oneroi, imalpha_oneroi, col(ri,:), alp(ri)); %make an overlay for one roi
        if rcnt==1
            imroi = imroi_oneroi;
            imalpha = imalpha_oneroi;
        else
            overlaps = sum(imroi, numel(size(imroi))) & sum(imroi_oneroi, numel(size(imroi_oneroi))); %sum final dim for overlap in any rgb channel
            overlaps_rgb = repmat(overlaps, [ones(1, numel(size(overlaps))) 3]);
            imroi(overlaps_rgb) = (imroi(overlaps_rgb)+imroi_oneroi(overlaps_rgb))/2;
            imroi(~overlaps_rgb) = imroi(~overlaps_rgb)+imroi_oneroi(~overlaps_rgb);
            overlaps = imalpha & imalpha_oneroi;
            imalpha(overlaps) = (imalpha(overlaps)+imalpha_oneroi(overlaps))/2;
            imalpha(~overlaps) = imalpha(~overlaps)+imalpha_oneroi(~overlaps);
        end
    end
end

if ndims(imroi)==3
    imroi = reshape(imroi, size(imroi, 1), size(imroi, 2), 1, size(imroi, 3)); %include singleton z
end

end


function [imroi, imalpha] = roiolmake_each(pixind_oneroi, imroi, imalpha, col, alp)

if numel(pixind_oneroi(:))>numel(imroi)
    error("number roi pixels exceeds number image pixels")
end
imroi(:) = 0;
imalpha(:) = 0;
pixind_oneroi_rgb = pixind_oneroi(:)+numel(imalpha)*([1:3]-1);
imroi(pixind_oneroi_rgb(:,1)) = col(1);
imroi(pixind_oneroi_rgb(:,2)) = col(2);
imroi(pixind_oneroi_rgb(:,3)) = col(3);
imalpha(pixind_oneroi) = alp;

end