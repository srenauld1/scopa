
function [varcombos, vars, labs, roipixind, limsc, vpmap] = apply_user_input(cbflags, vars, vpmap, labs, roipixind, stack, stack_mnt, dtmni, pth_mroi_interactive, normopt, newroirad, newroicen_all, xwid, zwid, limsc, yaxisroomfac)

try

    if ~isempty(cbflags.val.roicen) && any(~cellfun(@isempty, cbflags.val.roicen)) % || any(~cellfun(@isempty, cbflags.delete.roicen))


        max_index_available_rois = numel(roipixind);

        maskmanual = zeros(size(stack_mnt,1), size(stack_mnt,2), size(stack_mnt,3), 'logical');
        [umy, umx, umz] = meshgrid(0:xwid:xwid*(size(maskmanual,2)-1), 0:xwid:xwid*(size(maskmanual,1)-1), 0:zwid:zwid*(size(maskmanual,3)-1));

        cnt = 0;
        for j = 1:numel(cbflags.val.roicen)
            if ~isempty(cbflags.val.roicen{j})
                cnt = cnt+1;
                if cbflags.val.v(cnt)~=j
                    error("v must match cnt")
                end
                vind = cbflags.val.v(cnt);
                [roipixind_new, vars(j,:)] = make_ui_roi(cbflags.val.roicen{j}, newroicen_all{j}, xwid, zwid, maskmanual, umy, umx, umz, newroirad, stack, stack_mnt, normopt, dtmni, pth_mroi_interactive); % cbflags.delete.roicen{cbflags.val.v}
                roipixind = cat(1, roipixind, roipixind_new);
                disp("warning, hard coding ui parsex and parsnorm, fix this now")
                labs{j} = {['resp.fullfov.moex_interactive.in_rawf_pc_f_cl_f_w_no.ind' num2str(max_index_available_rois+cnt)]};
            end
        end

    else
        for j = 1:numel(cbflags.val.v)
            vind = cbflags.val.v(j);
            vars{vind} = mean(vars{vind}(cbflags.val.i{vind},:));
            labs{vind} = labs{vind}(cbflags.val.i{vind});
        end
    end

catch ME
    sprintf("user input for variable change has problem, returning to original variables")
    sprintf(ME.message)
end

for j = 1:numel(vars)
    limsc{j} = find_yaxis_limits(vars(j,:), yaxisroomfac);
end

varcombos = make_varcombos(vars);

axsides = fieldnames(vpmap);
for fi = 1:numel(axsides) 
    vpmap.(axsides{fi}) = [1:numel(vpmap.(axsides{fi}))]+numel(vpmap.(axsides{fi}))*(fi-1); %once user input is applied, vpmap must become default (it loses meaning after user input)
end


end


function [roipixind, vars] = make_ui_roi(roicen, newroicen_all, xwid, zwid, maskmanual, umy, umx, umz, newroirad, stack, stack_mnt, normopt, dtmni, pth_mroi_interactive)

if ~isempty(roicen)
    tmp = [xwid xwid zwid].*(double(roicen)-1);
    newroicen_all = cat(1, newroicen_all, tmp);
elseif ~isempty(cbflags.delete.roicen)
    newroicen_all = newroicen_all(1:end-1,:);
end

if isempty(newroicen_all)
    error("deal with deleting roi")
else
    for j = 1:size(newroicen_all, 1)
        newroicen = newroicen_all(j,:);
        maskmanual((umy - newroicen(1)).^2 + (umx - newroicen(2)).^2 + (umz - newroicen(3)).^2 <= newroirad.^2) = 1;
    end

    [roiinfo_new, resp_new] = make_morphological_rois(stack, stack_mnt, normopt, dtmni, [], [], pth_mroi_interactive, [], [], [], [], [], maskmanual);

    roipixind = roiinfo_new.roipixind;
    vars = resp_new.in_rawf_pc_f_cl_f_w_no;

end

end