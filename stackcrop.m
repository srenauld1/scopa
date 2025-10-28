function [s, rg] = stackcrop(s, rgname, opt)

%{

crop stack using user-defined cuboid
stack is in input struct s, fieldname 'stack' (s is output from stackld)
output struct rg; rg means "region"; rg saved to txt file

%}

arguments (Input)
    s struct % struct output from stackld (containing s.stack, pthstack, md, and other fields); s.stack dim order is yxztc (can have singleton trailing dims, so 4d yxzt, 3d yxz, and 2d yx stacks are also valid);
    rgname {mustBeTextScalar, mustBeNonempty} = 'none'; %name of region defined by output struct 'rg'; default rgname 'none' automatically makes rg the full yxz fov; user is not prompted to create an rg when rgname='none'
    opt.usegit (1,1) {mustBeScalarOrEmpty, mustBeBinary(opt.usegit,'emptyok')} = [] % use git to sync rg txt file across filesystems (to prevent conflicting changes)
    opt.justld (1,1) {mustBeBinary} = 0 % justld means "just load"; 1 to just load rg (and skip cropping stack); if justld=1, output s is equal to input s, and output rg is equal to rg loaded from txt file (created earlier with same inputs 's' and 'rgname'); if justld=1 and requested rg does not exist in rg txt file, output rg is empty 
end
arguments (Output)
    s % same as input s, but after cropping s.stack with rg (unless justld=1, in which case s output is same as s input)
    rg % struct containing fields with indices for cropping s.stack (iy, ix, iz, it, ic), field with region short name (rgname) and field with region full name (rgid)
end
usegit = opt.usegit;
justld = opt.justld;

maxnumdims = 5;
rgnamedf = 'none';
if isempty(rgname)
    rgname = rgnamedf;
end

usegit = optorglb(usegit, 0);
if ~ismember(usegit, [0,1])
    error("usegit must be 0 or 1")
end

if ~isempty(s)
    if ndims(s.stack)<2 || ndims(s.stack)>maxnumdims
        error("s.stack input to roidraw must be empty, or have 2-" + num2str(maxnumdims) + " dimensions")
    end
    if ~isfield(s, 'rg') || ~isempty(s.rg)
        error("stackcrop input s must have field named 'rg', and s.rg must be empty (s.stack cannot be an rg, since stackcrop creates rg); if rg is not a field in s, or if it is not empty, you might be using an old s, or using an s that has already been passed through stackcrop; if the former, delete stack mat file (not tif) and run the most recent version of stackld to create stack mat file with the new field rg; if the latter, just run stackld again to reload the uncropped stack")
    end
end

pthrg = [pthscopaget() 'opt_rg_' userdatfile('scopausername') '_.txt'];

rgid = [idmake(s.pth, 'recid') '_' rgname];

rg = [];
[~, ~, rgall] = structfile(pthrg, s=[], nm=[]);
if ~isempty(rgall)
    fn = fieldmatch(rgall, {'id', rgid}, lev=1, multi=0);
    if ~isempty(fn)
        rg = rgall.(fn);
    end
end

if ~justld %if input s.stack is empty, user is just checking if rg exists using structfile; if it doesn't, this prevents entering code to make rg, or apply rg, or both

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

    s.rg = rg; %update field rg

end


end
