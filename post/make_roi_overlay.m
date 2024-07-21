function [imroi, imalpha] = make_roi_overlay(pixind_oneroi, roi_color, imroi, imalpha, roialpha)

imroi(:) = 0;
imalpha(:) = 0;
pixind_oneroi_rgb = pixind_oneroi+numel(imalpha)*([1:3]-1);
imroi(pixind_oneroi_rgb(:,1)) = roi_color(1);
imroi(pixind_oneroi_rgb(:,2)) = roi_color(2);
imroi(pixind_oneroi_rgb(:,3)) = roi_color(3);
imalpha(pixind_oneroi) = roialpha;
imroi = reshape(imroi, [size(imalpha), 3]);

end