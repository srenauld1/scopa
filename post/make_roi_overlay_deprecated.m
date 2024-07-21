function roi_overlay = make_roi_overlay_deprecated(stack, pixinds_roi, ncol_each, ...
    foreground_plot_style, saturation_factor_background, ...
    saturation_factor_rois, filename_gif, doplot)

% makes roi overlay truecolor image that is x-y-z-channel-roi
% this function works but is now deprecated because it creates a potentially large variable (the roi overlay),
% and the colormapping method here is a little complex because it is fairly low level
% newer approach plots overlay within stack2fig by including the roi pixel indices as an argument 
% newer approach handles colormapping and transparency with higher level matlab functions

arguments
    stack
    pixinds_roi
    ncol_each = 128
    foreground_plot_style char = 'overlay'
    saturation_factor_background = 1
    saturation_factor_rois = 1
    filename_gif char = 'roioverlay.gif'
    doplot = 0
end

if ~iscell(pixinds_roi)
    if isvector(pixinds_roi)
        pixinds_roi = {pixinds_roi};
    else
        error("pixinds_roi must be cell, or vector")
    end
end


numrois = numel(pixinds_roi);

stack_rs = rescale(stack, 1, ncol_each);

img = zeros([size(stack_rs, 1), size(stack_rs, 2), size(stack_rs, 3), numrois], 'single');

for ri = 1:numrois

    roipixvals = stack(pixinds_roi{ri});

    overlay_tmp = rescale(stack_rs, 1, ncol_each); %redefine for each roi

    switch foreground_plot_style

        case 'overlay'

            overlay_tmp(pixinds_roi{ri}) = rescale(roipixvals, ncol_each+1, ncol_each*2); %for overlay (filled roi), maintains intensity of original, but with different hue

        case 'boundary'

            bound2d = zeros(size(imtmp), 'logical');
            for ii = 1:size(imtmp, 3)
                bound2d(:,:,ii) = bwperim(imtmp(:,:,ii));
            end
            overlay_tmp(bound2d) = ncol_each*2; %for boundary (hollow roi) with different hue

    end

    img(:,:,:,ri) = overlay_tmp;

end

%create colormap for roi+mean image overlay (roi is red by default)
startcol1 = [0 0 0]; %start color for part 1 (mean volume/background)
endcol1 = [1 1 1]; %end color for part 1 (mean volume/background)
startcol2 = [0 0 0]; %start color for part 2 (roi/foreground)
endcol2 = [1 0 0]; %end color for part 2 (roi/foreground)
cmap_method = '1d'; %colormap interpolation is 1d along arc of colorwheel, or 2d through colorwheel (1d is intuitive i think)

cmap = colormap_custom(cmap_method, ncol_each, ...
    startcol1, endcol1, saturation_factor_background, ...
    startcol2, endcol2, saturation_factor_rois);

roi_overlay = zeros(size(img, 1), size(img, 2), size(img, 3), 3, size(img, 4),  'single');
for ri = 1:size(img, 4)
    for zi = 1:size(img, 3)
        roi_overlay(:,:,zi,:,ri) = ind2rgb(round(img(:,:,zi,ri)), cmap);
    end
end

if doplot
    gif_visibility = 'on';
    stack2fig(img, filename_gif, gif_visibility) 
end
