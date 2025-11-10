function [s, rg] = rgmake(s, rgname, opt)

%{

create subregion of stack using user-defined cuboid (rg means "region")
stack is in struct s output from smake
output struct rg; rg also saved to struct s.rg
new modified struct s output after applying rg
output s is similar to input s, but some fields are missing
input s is for full fov (and has record of all rg that have been created in substruct rg), 
while output s is for stack subregion and does not contain substruct rg

%}

arguments (Input)
    s struct % struct output from smake (containing s.stack, pthstack, md, and other fields); s.stack dim order is yxztc (can have singleton trailing dims, so 4d yxzt, 3d yxz, and 2d yx stacks are also valid);
    rgname {mustBeTextScalar, mustBeNonempty} = glbfile('rgnamedf'); %name of region defined by output struct 'rg'; default rgname 'none' automatically makes rg the full yxz fov; user is not prompted to create an rg when rgname='none'
    opt.justld {mustBeBinary} = 0 % justld means "just load"; 1 to just load rg (and skip cropping stack); if justld=1, output s is equal to input s, and output rg is equal to rg loaded from txt file (created earlier with same inputs 's' and 'rgname'); if justld=1 and requested rg does not exist in rg txt file, output rg is empty
end
arguments (Output)
    s % same as input s, but after cropping s.stack with rg (unless justld=1, in which case s output is same as s input)
    rg % struct containing fields with indices for cropping s.stack (iy, ix, iz, it, ic), field with region short name (rgname) and field with region full name (rgid)
end
justld = opt.justld;

maxnumstackdim = 5;
rgnamedf = glbfile('rgnamedf');

if ~isequal(s.rgname, glbfile('rgnamedf'))
    error("s must contain full stack (s.rgname must be'" + glbfile('rgnamedf') + "'")
end

if ndims(s.stack)<2 || ndims(s.stack)>maxnumstackdim
    error("s.stack input to rgmake must have 2-" + num2str(maxnumstackdim) + " dimensions")
end

rgid = [idmake(s.pth, 'stackid') '_' rgname];

rg = s.rg(strcmp(rgid, {s.rg.id})); %see if requested rg exists in s.rg; if not, make it

if strcmp(rgname, rgnamedf) % IF rgname IS DEFAULT, JUST RETURN s
    fprintf("exiting rgmake without change because requested rgname (" + rgname + ") denotes full fov" + newline)
    return
end

if ~justld %if justld, user is just checking if rg exists

    if isempty(rg) %if rg doesn't exist, make it


        %%%% DRAW ROI TO DEFINE XYZ LIMITS OF rg %%%%

        mmrg = roidraw(s, roiname=rgname, dorg=1); %for drawing an rg, the roiname is the rgname, and the rgname is none (drawing on full fov)


        %%%% FIND BOUNDING VOLUME OF DRAWN ROI %%%%

        [iy, ix, iz] = ind2sub(size(mmrg.mask), find(mmrg.mask));
        iy = [min(iy), max(iy)]; %make sure we have bounding volume, since rg must be rectangle or cuboid
        ix = [min(ix), max(ix)]; %make sure we have bounding volume, since rg must be rectangle or cuboid
        iz = [min(iz), max(iz)]; %make sure we have bounding volume, since rg must be rectangle or cuboid


        %%%% KEEP ALL t AND ALL c %%%%

        it = [1,size(s.stack,4)];
        ic = [1,size(s.stack,5)];


        %%%% PUT IN STRUCT %%%%

        rgtmp.id = rgid;
        rgtmp.rgname = rgname;
        rgtmp.y = [iy(1), iy(2)];
        rgtmp.x = [ix(1), ix(2)];
        rgtmp.z = [iz(1), iz(2)];
        rgtmp.t = [it(1), it(2)];
        rgtmp.c = [ic(1), ic(2)];
        rg = rgtmp;


        %%%% APPEND NEW rg TO STRUCT HOLDING ALL rg AND SAVE %%%%

        s.rg = cat(2, s.rg, rg); %add current rg
        matsv(s.pth, 'rg', s=s) %save rg in s


    end




    %%%% CREATE FIELDS FOR CURRENT rg IN NEW s %%%%

    s.rgname = rgname;

    if ~isequal(diff([rg.y', rg.x', rg.z', rg.t', rg.c'])+1, size(s.stack, 1:maxnumstackdim)) %these don't change if you made rg the full fov

        s.stack = s.stack(rg.y(1):rg.y(2), rg.x(1):rg.x(2), rg.z(1):rg.z(2), rg.t(1):rg.t(2), rg.c(1):rg.c(2));
        s.sz = size(s.stack, 1:maxnumstackdim); %size of stack
        s.minc = double(min(s.stack, [], [1 2 3 4], 'omitmissing')); % min for each channel
        s.maxc = double(max(s.stack, [], [1 2 3 4], 'omitmissing')); % max for each channel
        s.min = min(s.minc); % min for entire stack
        s.max = max(s.maxc); % max for entire stack
        s.mnt = stacktype(mean(s.stack, 4), class(s.stack)); %mean t stack
        s.mnzt = stacktype(mean(s.mnt, 3), class(s.stack)); %mean zt stack
        s.mnztc = stacktype(mean(s.mnzt, 5), class(s.stack)); %mean ztc stack

        %%%% UPADATE SOME METADATA THAT MIGHT HAVE CHANGED WITH rg %%%%

        s.md.sz = s.sz;
        s.md.dims = [s.sz(4), s.sz(3), s.sz(1), s.sz(2)]; %dims is just the python stack size, without channel (pointless since sz is used in matlab instead)
        s.md.yfov = s.md.ywid*s.sz(1); %update some metadata for this rg
        s.md.xfov = s.md.xwid*s.sz(2); %update some metadata for this rg
        s.md.zfov = s.md.zwid*s.sz(3); %update some metadata for this rg
        s.md.numslice = s.sz(3); %update some metadata for this rg
        s.md.numslice_withflyback = s.sz(3)+s.md.flyback; %update some metadata for this rg
        s.md.zstartpos = s.md.zstartpos(rg.z(1):rg.z(2));

    end

    %%%% REMOVE FIELDS (including s.rg) THAT BELONG IN s BUT NOT rg VERSION OF s (FOR NOW WE INCLUDE mm AS HACK EVEN THOUGH IT'S MISLEADING BECAUSE IT'S ALL DRAWN ROIS NOT JUST THOSE DRAWN ON THIS rg) %%%%

    s = rmfield(s, {'rg', 'dq', 'roi', 'bmp', 'mdl', 'fmf', 'pthtif', 'pthdaq', 'opt', 'maketime_optfile_s'});

    s = structsort(s);

end




