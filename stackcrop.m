function [stack, croplim] = stackcrop(stack, pthstack, regionex)

%output croplim in case updated during loop with multiple croplim with same prefix but different suffix, to prevent saving multiple 

pthscopa = getpathscopa();
pthcroplim = [pthscopa 'croplim_*_.txt'];

[~, nmstack] = fileparts(pthstack); 
if ~endsWith(nmstack, '_')
    nmstack = [nmstack '_'];
end
nmcroplim = [nmstack regionex];

regionexdf = glb('regionexdf');
if isempty(regionexdf)
    regionexdf = 'none'; %if you haven't set the global, glb('regionexdf'), set regionexdf here; this regionex will not prompt you to create regionex, it will just use the whole fov
end

if strcmp(regionex, regionexdf) 

    croplim.y = [1, size(stack, 1)];
    croplim.x = [1, size(stack, 2)];
    croplim.z = [1, size(stack, 3)];
    croplim.t = [1, size(stack, 4)];
    croplim.c = [1, size(stack, 5)];

else
    
    croplim = structfile(pthcroplim, s=[], nm=nmcroplim, useprefix=1);

    if isempty(croplim)
        croplim = croplimmake(stack, pthcroplim, nmcroplim, regionex);
    end

    if ~(isequal(croplim.y, [1,size(stack,1)]) && isequal(croplim.x, [1,size(stack,2)]) && isequal(croplim.z, [1,size(stack,3)]) && isequal(croplim.t, [1,size(stack,4)]) && isequal(croplim.c, [1,size(stack,5)]))
        stack = stack(croplim.y(1):croplim.y(2), croplim.x(1):croplim.x(2), croplim.z(1):croplim.z(2), croplim.t(1):croplim.t(2), croplim.c(1):croplim.c(2)); %previously converted to single here, not sure why
    end

end

end
