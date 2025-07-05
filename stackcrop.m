function [stack, rg] = stackcrop(stack, pthstack, rgname)

% crop stack using user-defined cuboid (struct rg, abbreviation for region); rg saved to txt file

arguments (Input)
    stack %stack, dim order yxztc (can have singleton trailing dims, so 4d yxzt, 3d yxz, and 2d yx stacks are also valid));
    pthstack %path to stack
    rgname = [] %short name for region (rg, the stack after cropping)
end

arguments (Output)
    stack %after cropping with rg
    rg %rg means region; struct containing indices for cropping stack, region short name (rgname) and region full name (rgid)
end

try
    isTilde = detectOutputSuppression(nargout);
catch
    isTilde = 1;
end
if isempty(stack) && ~isTilde(1)
    error("if input stack is empty, output stack should be suppressed with tilde")
end

rgnamedf = glb('rgnamedf');
if isempty(rgnamedf)
    rgnamedf = 'none'; %if you haven't set the global, glb('rgnamedf'), set a local rgnamedf here; this rgname will not prompt you to create rgname, it will just use the whole fov
end
if isempty(rgname)
    rgname = rgnamedf; %if you haven't set the global, glb('rgnamedf'), set a local rgnamedf here; this rgname will not prompt you to create rgname, it will just use the whole fov
end

pthscopa = getpathscopa();
scopausername = glb('scopausername');
if isempty(scopausername)
    error("you have not set glb('scopausername')")
end
pthrg = [pthscopa 'opt_rg_' scopausername '_.txt'];

id = idmake(pthstack);
rgid = ['a_' id.recid '_' rgname];

rg = structfile(pthrg, s=[], nm=rgid, usegit=0);

if ~isempty(stack) %if input stack is empty, user is just checking if rg exists using structfile; if it doesn't, this prevents entering code to make rg, or apply rg, or both

    if isempty(rg)

        if strcmp(rgname, rgnamedf)

            rg.y = [1, size(stack, 1)];
            rg.x = [1, size(stack, 2)];
            rg.z = [1, size(stack, 3)];
            rg.t = [1, size(stack, 4)];
            rg.c = [1, size(stack, 5)];
            rg.name = rgname;
            rg.id = rgid;

        else

            rg = rgmake(stack, pthrg, rgid, rgname);

        end

        rg = structfile(pthrg, s=rg, nm=rgid, usegit=1);

    end


    if ~(isequal(rg.y, [1,size(stack,1)]) && isequal(rg.x, [1,size(stack,2)]) && isequal(rg.z, [1,size(stack,3)]) && isequal(rg.t, [1,size(stack,4)]) && isequal(rg.c, [1,size(stack,5)]))
        stack = stack(rg.y(1):rg.y(2), rg.x(1):rg.x(2), rg.z(1):rg.z(2), rg.t(1):rg.t(2), rg.c(1):rg.c(2)); %previously converted to single here, not sure why
    end


end


end



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



%% put in struct

rg.y = [iy(1), iy(2)];
rg.x = [ix(1), ix(2)];
rg.z = [iz(1), iz(2)];
rg.t = [it(1), it(2)];
rg.c = [ic(1), ic(2)];
rg.name = rgname;
rg.id = rgid;


end
