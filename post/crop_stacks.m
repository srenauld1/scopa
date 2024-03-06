function [stackcrop, stack_mnt, map_hires_lores_crop, hiresmntcrop] = ...
    crop_stacks(stack, croplim, recid, regionex, pth_fldr, sz_crop, ...
    use_hires, stack_hires_mnt, map_hires_lores )
            
if ~exist('use_hires', 'var')
    use_hires = 0;
end

if ~isempty(croplim)
    stackcrop = single(stack(croplim(1):croplim(2), croplim(3):croplim(4), croplim(5):croplim(6), :));
else
    [stackcrop, croplim] = make_croplim(single(stack), sz_crop(4), pth_fldr, recid, regionex);
end

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
