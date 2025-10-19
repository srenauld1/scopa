
classdef stackmixo < stackfindo
    properties

    end

    methods
        function obj = stackmixo(stack, rgnames, opt)

            % select, rotate, resample multiple regions (rg) of stack and put together in a montage

            arguments
                stack = []
                rgnames = [] %cell array of rgnames, regions to be put into montage
                opt.rot = [0,0,0] %Euler angles in x,y,z-order in degrees, specified as a 3-element numeric vector of the form [rx ry rz]; rgnames k gets rot(k,:), so if size(rot,1)>1, it must equal numel(rgnames), unless rot is empty (no rotations for any rgnames, or is 3-element row vector, in which case it is applied to all rgnames,
                opt.pthstack = []
            end
            pthstack = opt.pthstack;
            rot = opt.rot;

            if isempty(stack)
                if isempty(pthstack)
                    error("must pass in stack or name-value argument 'pthstack'")
                else
                    stack = stackld([], pthstack);
                end
            end
            if ndims(stack)<2 || ndims(stack)>6
                error("stack must be 2d-6d")
            end


            pthscopa = pthscopaget();
            scopausername = userdatfile('scopausername');

            pthrg = [pthscopa 'opt_rg_' scopausername '_.txt'];

            id = idmake(pthstack);

            [rg, nm] = structfile(pthrg, s=[], nm=[], usegit=0, dosort=0);
            fld = fieldmatch(roi, {'recdatenum', id.recdatenum}, lev=1);

            for k = 1:numel(rgnames)
                rgid = [id.recid '_' rgnames{k}];
                fld = fieldmatch(roi, {'rgid', rgid{k}}, lev=1);
            end

            if isscalar(rgnames)
                error("rgnames must contain multiple regions")
            end
            rgnames = convertStringsToChars(rgnames);
            numrg = numel(rgnames);

            if isempty(rot)
                rot = [0,0,0];
            else
                if isvector
                    rot = rot(:)';
                    rot = repmat(rot, [numrg 1]);
                end
                if size(rot,2)~=3
                    error("rot must be empty or (n,3)")
                end
            end


            for k = 1:numel(rgnames)
                stacktmp = stackcrop(stack, pth.stack, rgnames{k});
                stacktmp = stackwarp(stacktmp, rot=rot, doplt=1);
                stacktmp = stackrs(stacktmp, like=stackebrot);
            end


        end
        function obj = stackfind(obj)
            ff=2
        end
    end

end