function stacknew = stackmix(stack, rgnames, opt)

% select, rotate, resample multiple regions (rg) of stack and put together in a montage

arguments
    stack = []
    rgnames = [] %cell array of rgnames, regions to be put into montage
    opt.rot = [0,0,0] %Euler angles in x,y,z-order in degrees, specified as a 3-element numeric vector of the form [rx ry rz]; rgnames k gets rot(k,:), so if size(rot,1)>1, it must equal numel(rgnames), unless rot is empty (no rotations for any rgnames, or is 3-element row vector, in which case it is applied to all rgnames,
    opt.pthstacks = []
end
opt = glboropt(opt);
pthstacks = opt.pthstacks;
rot = opt.rot;

if isempty(stack) && isempty(pthstacks)
    error("must pass in stack or name-value argument 'pthstacks'")
end
if isempty(pthstacks)
    pthstacks = glb('pthstack');
    if isempty(pthstacks)
        error("must pass in name-value argument 'pthstacks' or set glb('pthstack')")
    end
end
if ~iscell(pthstacks)
    pthstacks = {pthstacks};
end
pthstacks = unique(pthstacks, 'stable');
numpths = numel(pthstacks);
if isscalar(rgnames) && isscalar(pthstacks)
    error("stackmix must work with multiple regions (taken from multiple pthstacks or multiple rgnames or both)")
end
% 
% if isempty(rgnames)
%     rgnames = '';
% end
% if ~iscell(rgnames)
%     rgnames = {rgnames};
% end
% if numel(cellflat(rgnames))==numel(rgnames)
%     rgnames = repmat(rgnames, numpths, 1);
% end
% rgnames_all = cell(1, numpths);
% for k = 1:numpths
%     rgnames_all{k} = rgnames{k};
%     rgnames_all{k} = convertStringsToChars(rgnames_all{k});
% end
% rgnames = rgnames_all;

pthscopa = pathscopaget();
scopausername = userdatfile('scopausername');

pthrg = [pthscopa 'opt_rg_' scopausername '_.txt'];
[~, ~, tmprg] = structfile(pthrg, s=[], nm=[], usegit=0, dosort=0);

numrg = 0;
rg = {};
for k = 1:numpths
    if (k==1 && isempty(stack)) || k>1
        [stack, pthstacks{k}] = stackld([], pthstacks{k}); %output pthstacks{k} in case tif converted to mat
    end
    if ndims(stack)<2 || ndims(stack)>6
        error("stack must be 2d-6d")
    end
    id = idmake(pthstacks{k});
    fld = fieldmatch(tmprg, {'recdatenum', id.recdatenum}, {'flynum', id.flynum}, {'trialnum', id.trialnum}, lev=1, multi=1);
    rg{k} = {};
    if isempty(rg{k})
        if isempty(rgnames{k})
            error("rgnames is empty for this stack and no rg have been defined")
        end
        stacktmp = stackcrop(stack, rgnames{k}, pthstack=pthstacks{k});
    end
    for q = 1:numel(fld)
        numrg = numrg+1;
        if any(strcmp(tmprg.(fld{1}).rgname, rgnames)) || isempty(rgnames)
            rg{k}{q} = tmprg.(fld{1});
        end
    end
end

if isempty(rot)
    rot = [0,0,0];
end
if isvector(rot)
    rot = rot(:)';
    rot = repmat(rot, [numrg 1]);
end
if size(rot,2)~=3
    error("rot must be empty or (n,3)")
end
if size(rot,1)~=numrg
    error("rot must be empty or (numrg,3)")
end

sdf = structfun(@diff, rg{1}{1}, 'UniformOutput', false);
sdf.y = sdf.y+1;
sdf.x = sdf.x+1;
sdf.z = sdf.z+1;


stacknew = [];
for k = 1:numpths
    for q = 1:3%numel(pthstacks{k})
        stacktmp = stackcrop(stack, rgnames{q}, '/Users/wienecke/stacks/ganoeb/20250716-1_d05_s8m_018_s8m/20250716_1_1_ord_.mat');
        stacktmp = stackwarp(stacktmp, rot=rot(k,:), doplt=0);
        % stacktmp = stackrs(stacktmp, like=stackebrot);
        stacktmp = stackrs(stacktmp, [sdf.y, sdf.x, sdf.z]);
        stacknew = cat(2, stacknew, stacktmp);
    end
end


end
