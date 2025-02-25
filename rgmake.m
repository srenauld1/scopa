
function rg = rgmake(stack, pthrg, rgid, rgname)

arguments
    stack
    pthrg
    rgid
    rgname
end

numchan = size(stack,5);

if numchan==2
    fprintf("averaging both channels to create the images for defining rg" + newline)
end

stackmnt = glb('stackmnt');
if isempty(stackmnt)
    stackmnt = single(mean(stack, [4 5])); %option 'native' is slow, uses more memory, and not necessary for mean t anyway
end

%% first define z limits

prompt = "\n\n\nyou requested rgname '" + rgname + "'" + newline + "but there is no record of rg with rgid '" + rgid + "' in rg file " + pthrg + newline + "You will now be prompted to define z, and then xy indices for this rg" + newline + "Do you want to define a subset of z slices for rgname '" + rgname + "'?" + newline + "Type 1 for yes, or type 0 to use all z slices: ";

commandwindow();
define_z_lim = input(sprintf(prompt));

if define_z_lim
    [iz, stackmnt] = cropz(stackmnt, rgname);
else
    iz = [1,size(stackmnt, 3)];
end

stackmntz = mean(stackmnt, 3);

%% then xy limits

prompt = "\n\n\nDo you want to define a subset of xy pixels for rgname '" + rgname + "'?" + newline + "Type 1 for yes, or type 0 to use all xy pixels: ";

commandwindow();
define_xy_lim = input(sprintf(prompt));

if define_xy_lim

    %then define polygon in mean image across chosen z indices (xy limits is bounding box of polygon)
    title_prefix = ['THIS IS THE MEAN OF SELECTED Z SLICES . . . NOW DRAW A SINGLE POLYGON AND ITS BOUNDING BOX WILL BE THE XY LIMITS FOR rgname "' rgname '"'];

    flag_rg = 1;
    flag_oneim = 1;
    flag_oneroi = 1;
    flag_allz = 0;
    draw_on_meanzt = 1;
    roi_cropxy = roidraw_onefig(stackmntz, flag_oneim, flag_oneroi, flag_allz, flag_rg, draw_on_meanzt, title_prefix=title_prefix);
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
    prompt = ['do you want to keep only one channel for rgname "' rgname '"? type type 0 to use both channels, 1 to keep only channel 1, or 2 to keep only channel 2: '];
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

rg.name = rgname;
rg.id = rgid;
rg.y = [iy(1), iy(2)];
rg.x = [ix(1), ix(2)];
rg.z = [iz(1), iz(2)];
rg.t = [it(1), it(2)];
rg.c = [ic(1), ic(2)];





