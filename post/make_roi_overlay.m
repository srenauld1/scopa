function [imroi, imalpha] = make_roi_overlay(imbg, roipixinds, roi_color, roialpha)

% make overlay for roi set defined by roipixinds, background is imbg;
% overlapping rois are averaged in color and transparency/alpha
% uses persistent variables because typically called in plotting loop

arguments
    imbg
    roipixinds
    roi_color = [1 0 0]
    roialpha = 0.3
end
persistent imalpha_oneroi
persistent imroi_oneroi

if isempty(imalpha_oneroi) && isempty(imroi_oneroi)
    imalpha_oneroi = zeros(size(imbg,1), size(imbg,2), size(imbg,3), size(imbg,4), size(imbg,5), 'single');
    imroi_oneroi = repmat(imalpha_oneroi, [ones(1, numel(size(imalpha_oneroi))) 3]);
end

if ~iscell(roipixinds)
    if isvector(roipixinds)
        roipixinds = {roipixinds};
    else
        error("roipixinds must be cell, or vector")
    end
end
if size(roi_color, 1)==1
    roi_color = repmat(roi_color, [numel(roipixinds) 1]);
end


rcnt = 0;
for ri = 1:numel(roipixinds)
    if ~isempty(roipixinds{ri})
        rcnt = rcnt+1;
        [imroi_oneroi, imalpha_oneroi] = make_roi_overlay_oneroi(roipixinds{ri}, imroi_oneroi, imalpha_oneroi, roi_color(ri,:), roialpha); %make an overlay for one roi
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


function [imroi, imalpha] = make_roi_overlay_oneroi(pixind_oneroi, imroi, imalpha, roi_color, roialpha)

imroi(:) = 0;
imalpha(:) = 0;
pixind_oneroi_rgb = pixind_oneroi(:)+numel(imalpha)*([1:3]-1);
imroi(pixind_oneroi_rgb(:,1)) = roi_color(1);
imroi(pixind_oneroi_rgb(:,2)) = roi_color(2);
imroi(pixind_oneroi_rgb(:,3)) = roi_color(3);
imalpha(pixind_oneroi) = roialpha;

end