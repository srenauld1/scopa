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

isTilde = detectOutputSuppression(nargout);
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
user = glb('user');
if isempty(user)
    error("you have not set glb('user')")
end
pthrg = [pthscopa 'opt_rg_' user '_*_.txt'];

[~, nmstack] = fileparts(pthstack);
if ~endsWith(nmstack, '_')
    nmstack = [nmstack '_'];
end
rgid = [nmstack rgname];



rg = structfile(pthrg, s=[], nm=rgid, useprefix=1);

if ~isempty(stack) %if input stack is empty, user is just checking if rg exists using structfile; if it doesn't, this prevents entering code to make rg, or apply rg, or both

    if isempty(rg)
        if strcmp(rgname, rgnamedf)

            rg.y = [1, size(stack, 1)];
            rg.x = [1, size(stack, 2)];
            rg.z = [1, size(stack, 3)];
            rg.t = [1, size(stack, 4)];
            rg.c = [1, size(stack, 5)];

        else

            rg = rgmake(stack, pthrg, rgid, rgname);

        end

        rg.name = rgname;
        rg.id = rgid;

        rg = structfile(pthrg, s=rg, nm=rgid, useprefix=1);

    end


    if ~(isequal(rg.y, [1,size(stack,1)]) && isequal(rg.x, [1,size(stack,2)]) && isequal(rg.z, [1,size(stack,3)]) && isequal(rg.t, [1,size(stack,4)]) && isequal(rg.c, [1,size(stack,5)]))
        stack = stack(rg.y(1):rg.y(2), rg.x(1):rg.x(2), rg.z(1):rg.z(2), rg.t(1):rg.t(2), rg.c(1):rg.c(2)); %previously converted to single here, not sure why
    end


end


end
