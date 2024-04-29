function [stackcrop, stack_mnt, map_hires_lores_crop, hiresmntcrop, croplim, pth_mroi] = ...
    crop_stacks(stack, croplim, recid, regionex, pth_fldr, sz_crop, ...
    use_hires, stack_hires_mnt, map_hires_lores, pth_mroi )

%output croplim in case updated during loop with multiple croplim with same prefix but different suffix, to prevent saving multiple 

if ~exist('use_hires', 'var')
    use_hires = 0;
end


if isempty(croplim)
    spl = strsplit(regionex, '_');
    regionex_nounderscore = spl{1};
    
    [croplim, croplimstr] = load_croplim(pth_fldr, recid, regionex_nounderscore ); %make sure croplim didn't get made during this run of pipeline for a previous regionex with same prefix
    if isempty(croplim)
        [croplim, croplimstr] = make_croplim(stack, sz_crop(4), pth_fldr, recid, regionex, regionex_nounderscore);
    end
    pth_mroi = strrep(pth_mroi, 'nocroplim', croplimstr);
end

stackcrop = single(stack(croplim(1):croplim(2), croplim(3):croplim(4), croplim(5):croplim(6), :)); %as of 240426, this is the only time in a2p.m you need to convert uint16 stack to single

stack_mnt = mean(stackcrop, 4);

if use_hires
    if ~isempty(croplim)
        zinds_lores = croplim(5):croplim(6);
        zinds_hires = ismember_single(map_hires_lores, zinds_lores);
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


if ~isa(stackcrop, 'single') & ~isa(stackcrop, 'double') 
    error("stack needs to be single or double, there are negatives coming soon")
end

end
