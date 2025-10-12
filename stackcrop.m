function [stack, rg] = stackcrop(stack, rgname, opt)

% crop stack using user-defined cuboid (struct rg, abbreviation for region); rg saved to txt file

arguments (Input)
    stack %stack, dim order yxztc (can have singleton trailing dims, so 4d yxzt, 3d yxz, and 2d yx stacks are also valid));
    rgname = [] %short name for region (rg, the stack after cropping); if empty, default rgname is 'none'
    opt.pthstack = [] %path to stack
    opt.scopausername = []
    opt.usegit = []
end

arguments (Output)
    stack %after cropping with rg
    rg %rg means region; struct containing indices for cropping stack, region short name (rgname) and region full name (rgid)
end

opt = glboropt(opt);
pthstack = opt.pthstack;
scopausername = opt.scopausername;
usegit = opt.usegit;

maxnumdims = 5;
rgnamedf = 'none';

if isempty(pthstack)
    error("name-value argument pthstack or glb('pthstack') must be nonempty")
end
if ~isempty(stack) && (ndims(stack)<2 || ndims(stack)>maxnumdims)
    error("stack input to roidraw must be empty, or have 2-" + num2str(maxnumdims) + " dimensions")
end
if isempty(rgname)
    rgname = rgnamedf; 
end


try
    isTilde = detectOutputSuppression(nargout);
catch
    isTilde = 1;
end
if isempty(stack) && ~isTilde(1)
    error("if input stack is empty, output stack should be suppressed with tilde")
end


pthscopa = pthscopaget();

pthrg = [pthscopa 'opt_rg_' scopausername '_.txt'];

id = idmake(pthstack);
rgid = [id.recid '_' rgname];

rg = [];
[~, ~, rgall] = structfile(pthrg, s=[], nm=[], usegit=usegit);
if ~isempty(rgall)
    fn = fieldmatch(rgall, {'id', rgid}, lev=1, multi=0);
    if ~isempty(fn)
        rg = rgall.(fn);
    end
end

if ~isempty(stack) %if input stack is empty, user is just checking if rg exists using structfile; if it doesn't, this prevents entering code to make rg, or apply rg, or both

    if isempty(rg)

        if strcmp(rgname, rgnamedf)

            rg.id = rgid;
            spl = strsplit(rgid, '_');
            rg.recdatenum = str2double(spl{1});
            rg.flynum = str2double(spl{2});
            rg.trialnum = str2double(spl{3});
            rg.rgname = rgname;
            rg.y = [1, size(stack, 1)];
            rg.x = [1, size(stack, 2)];
            rg.z = [1, size(stack, 3)];
            rg.t = [1, size(stack, 4)];
            rg.c = [1, size(stack, 5)];

        else

            rg = rgmake(stack, rgid, rgname, pthstack);

        end

        rg = structfile(pthrg, s=rg, nm=[], usegit=usegit);

    end

    szrg = diff([rg.y', rg.x', rg.z', rg.t', rg.c'])+1;
    if ~isequal(szrg, size(stack, 1:maxnumdims))
        stack = stack(rg.y(1):rg.y(2), rg.x(1):rg.x(2), rg.z(1):rg.z(2), rg.t(1):rg.t(2), rg.c(1):rg.c(2)); %previously converted to single here, not sure why
    end

end


end



function rg = rgmake(stack, rgid, rgname, pthstack)

arguments
    stack
    rgid
    rgname
    pthstack
end

numchan = size(stack,5);

if numchan==2
    prompt = ['enter channels you want to display for drawing rgname "' rgname '"? press enter only to display the average of all channels, 1 then enter to display only channel 1, or 2 then enter to display only channel 2: '];
    commandwindow();
    icshow = input(sprintf(prompt));
    if icshow
        stack = stack(:,:,:,:,icshow);
    else
        stack = mean(stack, 5);
    end
end

%% define xyz limits (bounding box of what is drawn)

roimask = roidraw(stack=stack, pthstack=pthstack, dorg=1, rgname=rgname);
[iy, ix, iz] = ind2sub(size(roimask), find(roimask));
iy = [min(iy), max(iy)]; %make sure we have bounding box, since rg must be rectangle or cuboid
ix = [min(ix), max(ix)]; %make sure we have bounding box, since rg must be rectangle or cuboid
iz = [min(iz), max(iz)]; %make sure we have bounding box, since rg must be rectangle or cuboid

%% then t (default all) and c

it = [1,size(stack,4)];

if numchan==2
    prompt = ['do you want to keep only one channel for rgname "' rgname '"? press enter only to keep all channels, 1 then enter to keep only channel 1, or 2 then enter to keep only channel 2: '];
    commandwindow();
    ic = input(sprintf(prompt));
    if ic
        ic = [ic,ic];
    else
        ic = [1,2];
    end
else
    ic = [1,1];
end


%% put in struct

rg.id = rgid;
spl = strsplit(rgid, '_');
rg.recdatenum = str2double(spl{1});
rg.flynum = str2double(spl{2});
rg.trialnum = str2double(spl{3});
rg.rgname = rgname;
rg.y = [iy(1), iy(2)];
rg.x = [ix(1), ix(2)];
rg.z = [iz(1), iz(2)];
rg.t = [it(1), it(2)];
rg.c = [ic(1), ic(2)];


end
