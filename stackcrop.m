function [stack, rg] = stackcrop(stack, pthstack, rgname)

% crop stack using user-defined region (struct rg); rg saved to txt file 

arguments (Input)
    stack %stack, dim order yxztc (can have singleton trailing dims, so 4d yxzt, 3d yxz, and 2d yx stacks are also valid))
    pthstack %path to stack
    rgname %short name for region (rg, the stack after cropping) 
end

arguments (Output)
    stack %after cropping with rg
    rg %rg means region; struct containing indices for cropping stack, region short name (rgname) and region full name (rgid)
end

pthscopa = getpathscopa();
user = glb('user');
if isempty(user)
    error("you have not set glb('user')")
end
pthrg = [pthscopa 'rg_' user '_*_.txt'];

[~, nmstack] = fileparts(pthstack);
if ~endsWith(nmstack, '_')
    nmstack = [nmstack '_'];
end
rgid = [nmstack rgname];

rgnamedf = glb('rgnamedf');
if isempty(rgnamedf)
    rgnamedf = 'none'; %if you haven't set the global, glb('rgnamedf'), set a local rgnamedf here; this rgname will not prompt you to create rgname, it will just use the whole fov
end


rg.name = rgname; 
rg.id = rgid; 

if strcmp(rgname, rgnamedf)

    rg.y = [1, size(stack, 1)];
    rg.x = [1, size(stack, 2)];
    rg.z = [1, size(stack, 3)];
    rg.t = [1, size(stack, 4)];
    rg.c = [1, size(stack, 5)];

    rg = structfile(pthrg, s=rg, nm=rgid, useprefix=1);

else

    rg = structfile(pthrg, s=[], nm=rgid, useprefix=1);

    if isempty(rg)
        rg = rgmake(stack, pthrg, rgid, rgname);
    end


    if ~(isequal(rg.y, [1,size(stack,1)]) && isequal(rg.x, [1,size(stack,2)]) && isequal(rg.z, [1,size(stack,3)]) && isequal(rg.t, [1,size(stack,4)]) && isequal(rg.c, [1,size(stack,5)]))
        stack = stack(rg.y(1):rg.y(2), rg.x(1):rg.x(2), rg.z(1):rg.z(2), rg.t(1):rg.t(2), rg.c(1):rg.c(2)); %previously converted to single here, not sure why
    end

end

end
