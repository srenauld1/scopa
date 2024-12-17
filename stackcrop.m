function [stack, zstartsub, croplim] = stackcrop(stack, regionex, zstartpos, recid, dirstack)

%output croplim in case updated during loop with multiple croplim with same prefix but different suffix, to prevent saving multiple 

regionexdf = glb('regionexdf');
if isempty(regionexdf)
    regionexdf = 'none'; %if you haven't set the global, set it here; this regionex will not cause prompt to create regionex
end

if strcmp(regionex, regionexdf) 

    croplim = [1, size(stack, 1), 1, size(stack, 2), 1, size(stack, 3), 1, size(stack, 4), 1, size(stack, 5)];

else

    spl = strsplit(regionex, '_');
    regionex_nounderscore = spl{1};
    numchan = size(stack,5);

    croplim = croplimld(dirstack, recid, regionex_nounderscore, numchan); %make sure croplim didn't get made during this run of pipeline for a previous regionex with same prefix
    
    if isempty(croplim)
        croplim = croplimmake(stack, dirstack, recid, regionex, regionex_nounderscore, numchan);
    end

    if ~(isequal(croplim(1):croplim(2), 1:size(stack,1)) && isequal(croplim(3):croplim(4), 1:size(stack,2)) && isequal(croplim(5):croplim(6), 1:size(stack,3)) && isequal(croplim(7):croplim(8), 1:size(stack,4)) && isequal(croplim(9):croplim(10), 1:size(stack,5)))
        stack = stack(croplim(1):croplim(2), croplim(3):croplim(4), croplim(5):croplim(6), croplim(7):croplim(8), croplim(9):croplim(10)); %previously converted to single here, not sure why
    end

end

zstartsub = zstartpos(croplim(5):croplim(6));

end
