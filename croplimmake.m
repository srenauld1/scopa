
function [croplim, croplimstr] = croplimmake(stack, sz_t, dirstack, recid, regionex, regionex_nounderscore, numchan)

if numchan==2
    fprintf("averaging both channels to create the images for defining croplim" + newline)
end

stackmnt = single(mean(stack, [4 5])); %native is slow and not necessary for mean t

%% first define z limits

prompt = ['you requested region "' regionex '", but there is no croplim file "' regionex_nounderscore '"\nDo you want to define a subset of z slices to be used for region "' regionex '" and all regions prefixed with "' regionex_nounderscore '"? type 1 for yes, type 0 to use all z slices: '];

commandwindow();
define_z_lim = input(sprintf(prompt));

if define_z_lim
    [zinds, stackmnt] = cropz(stackmnt, regionex_nounderscore);
else
    zinds = 1:size(stackmnt, 3);
end

stackmntz = mean(stackmnt, 3);

%% then xy limits

prompt = ['do you want to define a subset of xy pixels for region "' regionex '" and all regions prefixed with "' regionex_nounderscore '"? type 1 for yes, type 0 to use all xy pixels within selected z: '];

commandwindow();
define_xy_lim = input(sprintf(prompt));

if define_xy_lim

    %then define polygon in mean image across chosen z indices (xy limits is bounding box of polygon)
    title_prefix = ['THIS IS THE MEAN OF SELECTED Z SLICES . . . NOW DRAW A SINGLE POLYGON AND ITS BOUNDING BOX WILL BE THE XY LIMITS FOR REGIONS PREFIXED WITH "' regionex_nounderscore '"'];

    flag_croplim = 1;
    flag_oneim = 1;
    flag_oneroi = 1;
    flag_allz = 0;
    draw_on_meanzt = 1;
    roi_cropxy = roidraw_onefig(stackmntz, flag_oneim, flag_oneroi, flag_allz, flag_croplim, draw_on_meanzt, title_prefix=title_prefix);
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
cinds = 1:size(stack,5);
croplim = [yinds(1), yinds(end), xinds(1), xinds(end), zinds(1), zinds(end), tinds(1), tinds(end), cinds(1), cinds(end)]; 
croplimstr = [num2str(croplim(7)) '_' num2str(croplim(8)) '_' num2str(croplim(3)) '_' num2str(croplim(4)) '_' num2str(croplim(1)) '_' num2str(croplim(2)) '_' num2str(croplim(5)) '_' num2str(croplim(6)) '_' num2str(croplim(9)) '_' num2str(croplim(10))]; %txyz
pth_croplim = [dirstack recid '_' regionex_nounderscore '_' croplimstr '_croplim_.mat'];
save(pth_croplim, 'yinds', 'xinds', 'zinds', 'tinds', 'cinds', '-v7.3', '-mat')



