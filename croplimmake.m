
function croplim = croplimmake(stack, pthcroplim, nmcroplim, regionex)

arguments
    stack
    pthcroplim
    nmcroplim
    regionex
end

numchan = size(stack,5);

if numchan==2
    fprintf("averaging both channels to create the images for defining croplim" + newline)
end

stackmnt = single(mean(stack, [4 5])); %native is slow and not necessary for mean t

%% first define z limits

prompt = ['you requested regionex "' regionex '", but there is no croplim file "' regionex '"\nDo you want to define a subset of z slices to be used for regionex "' regionex '"? type 1 for yes, type 0 to use all z slices: '];

commandwindow();
define_z_lim = input(sprintf(prompt));

if define_z_lim
    [iz, stackmnt] = cropz(stackmnt, regionex);
else
    iz = [1,size(stackmnt, 3)];
end

stackmntz = mean(stackmnt, 3);

%% then xy limits

prompt = ['do you want to define a subset of xy pixels for regionex "' regionex '"? type 1 for yes, type 0 to use all xy pixels within selected z: '];

commandwindow();
define_xy_lim = input(sprintf(prompt));

if define_xy_lim

    %then define polygon in mean image across chosen z indices (xy limits is bounding box of polygon)
    title_prefix = ['THIS IS THE MEAN OF SELECTED Z SLICES . . . NOW DRAW A SINGLE POLYGON AND ITS BOUNDING BOX WILL BE THE XY LIMITS FOR regionex "' regionex '"'];

    flag_croplim = 1;
    flag_oneim = 1;
    flag_oneroi = 1;
    flag_allz = 0;
    draw_on_meanzt = 1;
    roi_cropxy = roidraw_onefig(stackmntz, flag_oneim, flag_oneroi, flag_allz, flag_croplim, draw_on_meanzt, title_prefix=title_prefix);
    if ~any(roi_cropxy(:))
        roi_cropxy = ones(size(roi_cropxy));
    end
    [iy, ix] = ind2sub(size(roi_cropxy), find(roi_cropxy));
    iy = [min(iy), max(iy)];
    ix = [min(ix), max(ix)];

else

    iy = [1,size(stack, 1)];
    ix = [1,size(stack, 2)];

end

%% t (all) and c 

it = [1,size(stack,4)];

if numchan==2
    prompt = ['do you want to keep only one channel for regionex "' regionex '"? type type 0 to use both channels, 1 to keep only channel 1, or 2 to keep only channel 2: '];
    commandwindow();
    ccrop = input(sprintf(prompt));
    if ccrop
        ic = [ccrop,ccrop];
    else
        ic = [1,2];
    end
else
    ic = [1,1];
end



%% save to txt 


croplim.y = [iy(1), iy(2)];
croplim.x = [ix(1), ix(2)];
croplim.z = [iz(1), iz(2)];
croplim.t = [it(1), it(2)];
croplim.c = [ic(1), ic(2)];

croplim = structfile(pthcroplim, s=croplim, nm=nmcroplim, useprefix=1);




