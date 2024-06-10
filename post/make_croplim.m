
function [croplim, croplimstr] = make_croplim(stack, sz_t, pth_fldr, pth_tmpfiles, recid, regionex, regionex_nounderscore)


clip_prctile = [0 100]; %[0 100] does not change contrast
scalefac = 1;
ignore_zeros = 1; %don't include zeros in percentile for contrast adjustment
numdim_out = 3; %number of dimensions of output image
filename_gif = []; %filename to save image, empty to skip

stack_mnt = process_stack_for_roi_selection(stack, numdim_out, clip_prctile, scalefac, ignore_zeros, filename_gif);

%% first define z limits

prompt = ['you requested region "' regionex '", but there is no croplim file "' regionex_nounderscore '"; do you want to define a subset of z slices to be used for region "' regionex '" and all regions prefixed with "' regionex_nounderscore '"? type 1 for yes, type 0 to use all z slices: '];

commandwindow();
define_z_lim = input(sprintf(prompt));

if define_z_lim
    [zinds, stack_mnt] = croplim_z(stack_mnt, pth_tmpfiles, regionex_nounderscore);
else
    zinds = 1:size(stack_mnt, 3);
end

stack_mntz = mean(stack_mnt, 3);

%% then xy limits

prompt = ['do you want to define a subset of xy pixels for region "' regionex '" and all regions prefixed with "' regionex_nounderscore '"? type 1 for yes, type 0 to use all xy pixels within selected z: '];

commandwindow();
define_xy_lim = input(sprintf(prompt));

if define_xy_lim

    %then define polygon in mean image across chosen z indices (xy limits is bounding box of polygon)
    title_prefix = ['THIS IS THE MEAN OF SELECTED Z SLICES . . . NOW DRAW A SINGLE POLYGON AND ITS BOUNDING BOX WILL BE THE XY LIMITS FOR REGIONS PREFIXED WITH "' regionex_nounderscore '"'];

    flag_croplim = 1;
    flag_one_image = 1;
    flag_limit_one_manual_roi = 1;
    roi_cropxy = drawrois_oneimage(stack_mntz, pth_tmpfiles, regionex_nounderscore, title_prefix, flag_one_image, flag_limit_one_manual_roi, flag_croplim);
    if ~any(roi_cropxy(:))
        roi_cropxy = ones(size(roi_cropxy));
    end
    [yinds, xinds] = ind2sub(size(roi_cropxy), find(roi_cropxy));
    yinds = min(yinds):max(yinds);
    xinds = min(xinds):max(xinds);

else

    yinds = 1:size(stack, 1);
    xinds = 1:size(stack, 2);

end

%% save

tinds = 1:sz_t;
croplim = [yinds(1), yinds(end), xinds(1), xinds(end), zinds(1), zinds(end), tinds(1), tinds(end)];
croplimstr = [num2str(croplim(7)) '_' num2str(croplim(8)) '_' num2str(croplim(3)) '_' num2str(croplim(4)) '_' num2str(croplim(1)) '_' num2str(croplim(2)) '_' num2str(croplim(5)) '_' num2str(croplim(6))];
pth_croplim = [pth_fldr recid '_' regionex_nounderscore '_' croplimstr '_croplim_.mat'];
save(pth_croplim, 'yinds', 'xinds', 'zinds', 'tinds', '-v7.3', '-mat')



