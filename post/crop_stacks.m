function [croplim_all, stack_mnt, zinds_hires, map_hires_lores_crop, hiresmntcrop] = ...
    crop_stacks(stack, croplim, use_hires, recid, regionex, pth_fldr, sz_crop )
               

if ~isempty(croplim)
    stackcrop = single(stack(croplim(1):croplim(2), croplim(3):croplim(4), croplim(5):croplim(6), :));
else
    [stackcrop, croplim] = make_croplim(single(stack), sz_crop(4), pth_fldr, recid, regionex);
    croplim_all{rei} = croplim;
end

stack_mnt{rei} = mean(stackcrop, 4);

if use_hires
    if ~isempty(croplim)
        zinds_hires = ismember(map_hires_lores, croplim(5):croplim(6));
        map_hires_lores_crop = map_hires_lores(zinds_hires) - (min(croplim(5):croplim(6))-1);
        hiresmntcrop = single(stack_hires_mnt(croplim(1):croplim(2), croplim(3):croplim(4), zinds_hires));
    else
        map_hires_lores_crop = map_hires_lores;
        hiresmntcrop = stack_hires_mnt;
    end
else
    hiresmntcrop = [];
    map_hires_lores_crop = [];
end

if ~isa(stackcrop, 'single') & ~isa(stackcrop, 'double') & ( use_hires & ~isa(hiresmntcrop, 'single') & ~isa(hiresmntcrop, 'double') )
    error("stacks need to be single or double, there are negatives coming soon")
end

end
