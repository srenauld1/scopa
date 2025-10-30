function stacknew = stackmix(opt)

% select, rotate, and resample multiple regions (rg) from one or more stacks and put together in a single image (montage)
% pass in stacks, or pthstacks
arguments
    opt.rgnames = [] %cell array of rgnames, regions to be put into montage
    opt.rot = [0,0,0] %Euler angles in x,y,z-order in degrees, specified as a 3-element numeric vector of the form [rx ry rz]; rgnames k gets rot(k,:), so if size(rot,1)>1, it must equal numel(rgnames), unless rot is empty (no rotations for any rgnames, or is 3-element row vector, in which case it is applied to all rgnames,
    opt.s = [] %stack, or cell of stacks; must be empty if you pass in pthstacks or stackids
    opt.pthstacks = [] %cell array of paths to stacks to be mixed; must be empty if you pass in stacks or stackids
    opt.stackids = []%cell array of stackids of stacks to be mixed; stackid is recdate_fly_trial_suffix; must be empty if you pass in stacks or pthstacks
    opt.pthpar = [] %path to folder containing all stacks
    opt.optsld = [] %options for stackld for loading all stacks found; if empty, default are used
end
rgnames = opt.rgnames;
rot = opt.rot;
s = opt.s;
pthstacks = opt.pthstacks;
stackids = opt.stackids;
pthpar = opt.pthpar;
optsld = opt.optsld;

mixstr = strjoin(rgnames, '');
pthmix = [idmake(s.pth, 'pthpre') mixstr '_.mat'];


try

    load(pthmix, 'stacknew');
    
catch


    %%%% GET STACKS %%%%

    if ~isempty(s) + ~isempty(pthstacks) + ~isempty(stackids) ~= 1
        error("must pass in one and only one of the following name-value arguments: 's', 'pthstacks', 'stackids'")
    end
    if isempty(s)
        s = {[]};
        if isempty(pthstacks)
            if ~iscell(stackids)
                stackids = {stackids};
            end
            numspec = numel(stackids);
            pthstacks = cell(1,numel(stackids));
            for k = 1:numel(stackids)
                pthstacks{k} = stackfind(stackid=stackids{k}, pthpar=pthpar);
            end
            pthstacks = cellflat(pthstacks);
            if all(cellfun(@isempty, pthstacks))
                fprintf("no stacks found using name-value argument 'stackids'" + newline)
                pthstacks = [];
            end
        else
            if ~iscell(pthstacks)
                pthstacks = {pthstacks};
            end
            numspec = numel(pthstacks);
        end
    else
        if ~iscell(s)
            s = {s};
        end
        for k = 1:numel(s)
            pthstacks{k} = s{k}.pth;
        end
        numspec = numel(s);
    end

    pthstacks = unique(pthstacks, 'stable');
    numpth = numel(pthstacks);


    %%%% FORMAT RGNAMES %%%%

    if isempty(rgnames)
        rgnames = '';
    end
    if ~iscell(rgnames)
        rgnames = {rgnames};
    end
    if ~all(cellfun(@ischar,cellflat(rgnames)))
        error("rgnames must be all char string")
    end
    if iscellnested(rgnames)
        if numel(rgnames)~=numspec
            error("if rgnames is cell of cell(s), number of inner cells in rgnames must equal number of stack specifiers (" + num2str(numspec) + ")")
        end
    else
        rgnames = repmat({rgnames}, numspec, 1);
    end



    %%%% GET RG %%%%

    if isscalar(cellflat(rgnames)) && isscalar(pthstacks)
        error("stackmix must work with multiple regions (taken from multiple pthstacks or multiple rgnames or both)")
    end

    pthscopa = pthscopaget();
    scopausername = userdatfile('scopausername');

    pthrg = [pthscopa 'opt_rg_' scopausername '_.txt'];
    [~, ~, tmprg] = structfile(pthrg, s=[], nm=[], usegit=0, dosort=0);

    numrg = 0;
    rg = {};
    for k = 1:numpth
        if (k==1 && isempty(s{k})) || k>1
            if isempty(optsld)
                optsld = ofill('sld', unpack=1);
            end
            s{k} = stackld(optsld, pthstacks{k}); %output pthstacks{k} in case tif converted to mat
            pthstacks{k} = s{k}.pth;
        end
        if ndims(s{k}.stack)<2 || ndims(s{k}.stack)>6
            error("stack must be 2d-6d")
        end
        id = idmake(pthstacks{k});
        field = fieldmatch(tmprg, {'recdatenum', id.recdatenum}, {'flynum', id.flynum}, {'trialnum', id.trialnum}, lev=1, multi=1);
        if ~iscell(field)
            field = {field};
        end
        rg{k} = {};
        for q = 1:numel(field)
            kp = strcmp(tmprg.(field{q}).rgname, rgnames{k});
            if any(kp) || isempty(rgnames{k})
                numrg = numrg+1;
                kpi = find(kp);
                rg{k}{kpi} = tmprg.(field{q});
            end
        end
        % if isempty(rg{k})
        %     if isempty(rgnames{k})
        %         error("rgnames is empty for this stack and no rg have been defined")
        %     end
        %     stacktmp = stackcrop(s{k}.stack, rgnames{k}, pthstack=pthstacks{k});
        % end
    end


    %%%% CROP, WARP (OPTIONAL), RESAMPLE, CONCATENATE %%%%

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

    sdf = structfun(@(x) diff(x)+1, rg{1}{2}, 'UniformOutput', false);

    stacknew = [];
    for k = 1:numpth
        for q = 1:numel(rgnames{k})
            stmp = stackcrop(s{k}, rgnames{k}{q});
            stacktmp = stackwarp(stmp.stack, rot=rot(k,:), doplt=0);
            stacktmp = stackrs(stacktmp, [sdf.y, sdf.x, sdf.z]);
            stacknew = cat(2, stacknew, stacktmp);
        end
    end

    save(pthmix, 'stacknew', '-v7.3', '-mat')

end

end
