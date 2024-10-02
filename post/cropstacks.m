function [stack, zstartpos_crop, map_hires_lores_crop, hiresmntcrop, croplim, pth_mroi] = ...
    cropstacks(stack, regionex, zstartpos, recid, fldr, pth_tmpfiles, sz_crop, ...
    use_hires, stack_hires_mnt, map_hires_lores, pth_mroi )

%output croplim in case updated during loop with multiple croplim with same prefix but different suffix, to prevent saving multiple 

name_noregionex = globscopa('name_noregionex');

if ~exist('use_hires', 'var')
    use_hires = 0;
end

if strcmp(regionex, name_noregionex) %strcmp(croplim, name_noregionex)

    croplim = [1, size(stack, 1), 1, size(stack, 2), 1, size(stack, 3), 1, size(stack, 4), 1, size(stack, 5)];
    stack = single(stack);

else

    spl = strsplit(regionex, '_');
    regionex_nounderscore = spl{1};
    numchan = size(stack,5);

    [croplim, croplimstr] = load_croplim(fldr, recid, regionex_nounderscore, numchan); %make sure croplim didn't get made during this run of pipeline for a previous regionex with same prefix
    
    if isempty(croplim)
        [croplim, croplimstr_new] = make_croplim(stack, sz_crop(4), fldr, pth_tmpfiles, recid, regionex, regionex_nounderscore);
        pth_mroi = strrep(pth_mroi, croplimstr, croplimstr_new);
    end
    
    stack = single(stack(croplim(1):croplim(2), croplim(3):croplim(4), croplim(5):croplim(6), croplim(7):croplim(8), croplim(9):croplim(10))); %as of 240426, this is the only time in a2p.m you need to convert uint16 stack to single

end

zstartpos_crop = zstartpos(croplim(5):croplim(6));

if use_hires
    if contains(regionex, '_')
        error("you set use_hires=1 with a sub-regionex (ie regionex has an underscore); code isn't written for this yet; just need to crop hires accordingly (or, depending on sub-regionex)")
    end
    if ~isempty(croplim)
        zinds_lores = croplim(5):croplim(6);
        zinds_hires = ismember_each_element(map_hires_lores, zinds_lores);
        map_hires_lores_crop = map_hires_lores(zinds_hires) - (min(croplim(5):croplim(6))-1);
        hiresmntcrop = single(stack_hires_mnt(croplim(1):croplim(2), croplim(3):croplim(4), zinds_hires));
    else
        map_hires_lores_crop = map_hires_lores;
        hiresmntcrop = stack_hires_mnt;
    end
    if ~isa(hiresmntcrop, 'single') & ~isa(hiresmntcrop, 'double')
        error("hires stack needs to be single or double, there are negatives coming soon")
    end
else
    hiresmntcrop = [];
    map_hires_lores_crop = [];
end


if ~isa(stack, 'single') & ~isa(stack, 'double') 
    error("stack needs to be single or double, there are negatives coming soon")
end

end
