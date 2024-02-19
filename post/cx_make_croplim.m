
function [stack, cropdims] = cx_make_croplim(stack, sz_t, pth_fldr, recid, region_extraction)


clip_prctile = [0 100]; %[0 100] does not change contrast
scalefac = 1;
ignore_zeros = 1; %don't include zeros in percentile for contrast adjustment
numdim_out = 3; %number of dimensions of output image
filename_gif = []; %filename to save image, empty to skip

stack_mnt = cx_process_stack_for_roi_selection(stack, numdim_out, clip_prctile, scalefac, ignore_zeros, filename_gif);

%first define z limits 
[zinds, stack_mnt] = cx_croplim_z(stack_mnt, region_extraction);

stack_mntz = mean(stack_mnt, 3);

%then define polygon in mean image across chosen z indices (xy limits is bounding box of polygon)
title_draw_xy = ['DEFINE xy LIMITS FOR REGION "' region_extraction '", XY LIMITS WILL BE BOUNDING BOX OF THE DRAWN ROI'];
flag_xy_discontiguous = 0;
flag_single_roi_per_figure = 1;
roi_cropxy = cx_drawrois_oneimage(stack_mntz, title_draw_xy, flag_xy_discontiguous, flag_single_roi_per_figure);
[yinds, xinds] = ind2sub(size(roi_cropxy), find(roi_cropxy));
yinds = min(yinds):max(yinds);
xinds = min(xinds):max(xinds);
tinds = 1:sz_t;
stack = stack(yinds, xinds, zinds, tinds); %need to create this and make single for draw_morphological_rois function
cropdims = [yinds(1), yinds(end), xinds(1), xinds(end), zinds(1), zinds(end), tinds(1), tinds(end)];

pth_croplim = [pth_fldr recid '_' region_extraction '_' num2str(min(tinds)) '_' num2str(max(tinds)) '_' num2str(min(xinds)) '_' num2str(max(xinds)) '_' num2str(min(yinds)) '_' num2str(max(yinds)) '_' num2str(min(zinds)) '_' num2str(max(zinds)) '_croplim_.mat'];
save(pth_croplim, 'yinds', 'xinds', 'zinds', 'tinds', '-v7.3', '-mat')


