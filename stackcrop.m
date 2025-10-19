function [s, rg] = stackcrop(s, rgname, opt)

% crop s.stack using user-defined cuboid (struct rg, abbreviation for region); rg saved to txt file

arguments (Input)
    s % struct output from stackld (containing s.stack, pthstack, md, and other fields); s.s.stack dim order is yxztc (can have singleton trailing dims, so 4d yxzt, 3d yxz, and 2d yx stacks are also valid));
    rgname = [] % short name for region (rg, s.s.stack after cropping); if empty, default rgname assigned is 'none'; if user sets rgname='none', user is not prompted to crop s.stack (none means entire fov)
    opt.usegit {mustBeMember(opt.usegit,[0,1,[]])} = [] % use git to sync file pth across filesystems (to prevent conflicting changes)
end
arguments (Output)
    s % after cropping s.s.stack with rg
    rg % rg (means "region") struct containing indices for cropping s.stack (iy, ix, iz, it, ic), region short name (rgname) and region full name (rgid)
end
usegit = opt.usegit;

maxnumdims = 5;
rgnamedf = 'none';

if isempty(usegit)
    usegit = glb('usegit');
    if isempty(usegit)
        error("must set name-value argument 'usegit', or glb('usegit')")
    end
end

if ~isempty(s.stack) && (ndims(s.stack)<2 || ndims(s.stack)>maxnumdims)
    error("s.stack input to roidraw must be empty, or have 2-" + num2str(maxnumdims) + " dimensions")
end
if isempty(rgname)
    rgname = rgnamedf;
end


try
    isTilde = detectOutputSuppression(nargout);
catch
    isTilde = 1;
end
if isempty(s.stack) && ~isTilde(1)
    error("if input s.stack is empty, output s.stack should be suppressed with tilde")
end

pthscopa = pthscopaget();
scopausername = userdatfile('scopausername');

pthrg = [pthscopa 'opt_rg_' scopausername '_.txt'];

id = idmake(s.pthstack);
rgid = [id.recid '_' rgname];

rg = [];
[~, ~, rgall] = structfile(pthrg, s=[], nm=[]);
if ~isempty(rgall)
    fn = fieldmatch(rgall, {'id', rgid}, lev=1, multi=0);
    if ~isempty(fn)
        rg = rgall.(fn);
    end
end

if ~isempty(s.stack) %if input s.stack is empty, user is just checking if rg exists using structfile; if it doesn't, this prevents entering code to make rg, or apply rg, or both

    if isempty(rg)

        if strcmp(rgname, rgnamedf)

            rg.id = rgid;
            spl = strsplit(rgid, '_');
            rg.recdatenum = str2double(spl{1});
            rg.flynum = str2double(spl{2});
            rg.trialnum = str2double(spl{3});
            rg.rgname = rgname;
            rg.y = [1, size(s.stack, 1)];
            rg.x = [1, size(s.stack, 2)];
            rg.z = [1, size(s.stack, 3)];
            rg.t = [1, size(s.stack, 4)];
            rg.c = [1, size(s.stack, 5)];

        else

            numchan = size(s.stack,5);

            if numchan==2
                prompt = ['enter channels you want to display for drawing rgname "' rgname '"? return for all channels, 1+return for channel 1, 2+return for channel 2: '];
                commandwindow();
                icshow = input(sprintf(prompt));
                if icshow
                    s.stack = s.stack(:,:,:,:,icshow);
                else
                    s.stack = mean(s.stack, 5);
                end
            end

            %%%% define xyz limits (bounding box of what is drawn) %%%%

            roimask = roidraw(s, dorg=1, rgname=rgname);
            [iy, ix, iz] = ind2sub(size(roimask), find(roimask));
            iy = [min(iy), max(iy)]; %make sure we have bounding box, since rg must be rectangle or cuboid
            ix = [min(ix), max(ix)]; %make sure we have bounding box, since rg must be rectangle or cuboid
            iz = [min(iz), max(iz)]; %make sure we have bounding box, since rg must be rectangle or cuboid

            %%%% then t (default all) and c %%%%

            it = [1,size(s.stack,4)];

            if numchan==2 %just keep all channels, having multiple rg with some channels
                % prompt = ['do you want to keep only one channel for rgname "' rgname '"? press enter only to keep all channels, 1 then enter to keep only channel 1, or 2 then enter to keep only channel 2: '];
                % commandwindow();
                % ic = input(sprintf(prompt));
                if 0%ic
                    ic = [ic,ic]; %if 2 channel, keeping both channels by default (it complicates downstream)
                else
                    ic = [1,2];
                end
            else
                ic = [1,1];
            end


            %%%% put in struct %%%%

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

        rg = structfile(pthrg, s=rg, nm=[], usegit=usegit);

    end

    szrg = diff([rg.y', rg.x', rg.z', rg.t', rg.c'])+1;
    if ~isequal(szrg, size(s.stack, 1:maxnumdims))
        s.stack = s.stack(rg.y(1):rg.y(2), rg.x(1):rg.x(2), rg.z(1):rg.z(2), rg.t(1):rg.t(2), rg.c(1):rg.c(2)); %previously converted to single here, not sure why
    end

end


end
