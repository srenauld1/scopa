function [stack, zstartsub, hrlrsub, hiresmntsub, croplim] = ...
    stackcrop(stack, regionex, zstartpos, recid, fldr, sz, ...
    usehires, stackmnthr, hrlr )

%output croplim in case updated during loop with multiple croplim with same prefix but different suffix, to prevent saving multiple 

regionexdf = glb('regionexdf');
if isempty(regionexdf)
    regionexdf = 'default'; %if you haven't set the global
end

if ~exist('usehires', 'var')
    usehires = 0;
end


if strcmp(regionex, regionexdf) %strcmp(croplim, regionexdf)

    croplim = [1, size(stack, 1), 1, size(stack, 2), 1, size(stack, 3), 1, size(stack, 4), 1, size(stack, 5)];
    stack = single(stack);

else

    spl = strsplit(regionex, '_');
    regionex_nounderscore = spl{1};
    numchan = size(stack,5);

    [croplim, croplimstr] = load_croplim(fldr, recid, regionex_nounderscore, numchan); %make sure croplim didn't get made during this run of pipeline for a previous regionex with same prefix
    
    if isempty(croplim)
        [croplim, croplimstr] = croplimmake(stack, sz(4), fldr, recid, regionex, regionex_nounderscore, numchan);
    end
    
    stack = single(stack(croplim(1):croplim(2), croplim(3):croplim(4), croplim(5):croplim(6), croplim(7):croplim(8), croplim(9):croplim(10))); %as of 240426, this is the only time in a2p.m you need to convert uint16 stack to single

end

zstartsub = zstartpos(croplim(5):croplim(6));

if usehires
    if contains(regionex, '_')
        error("you set usehires=1 with a sub-regionex (ie regionex has an underscore); code isn't written for this yet; just need to crop hires accordingly (or, depending on sub-regionex)")
    end
    if ~isempty(croplim)
        zinds_lores = croplim(5):croplim(6);
        zinds_hires = ismember_each_element(hrlr, zinds_lores);
        hrlrsub = hrlr(zinds_hires) - (min(croplim(5):croplim(6))-1);
        hiresmntsub = single(stackmnthr(croplim(1):croplim(2), croplim(3):croplim(4), zinds_hires));
    else
        hrlrsub = hrlr;
        hiresmntsub = stackmnthr;
    end
    if ~isa(hiresmntsub, 'single') & ~isa(hiresmntsub, 'double')
        error("hires stack needs to be single or double (for now)")
    end
else
    hiresmntsub = [];
    hrlrsub = [];
end


if ~isa(stack, 'single') & ~isa(stack, 'double') 
    error("stack needs to be single or double (for now)")
end

end
