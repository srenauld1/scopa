
function [varcombos, varsc, labsc, roipixind, newroicen_all, limsc] = apply_user_input(cbflags, varsc, labsc, roipixind, stack, stack_mnt, dtmni, pth_mroi_interactive, normopt, newroirad, newroicen_all, xwid, zwid, limsc, yaxisroomfac)

try

    if ~isempty(cbflags.val.roicen) || ~isempty(cbflags.delete.roi)

        maskmanual = zeros(size(stack_mnt,1), size(stack_mnt,2), size(stack_mnt,3), 'logical');
        [umy, umx, umz] = meshgrid(0:xwid:xwid*(size(maskmanual,2)-1), 0:xwid:xwid*(size(maskmanual,1)-1), 0:zwid:zwid*(size(maskmanual,3)-1));
        
        if ~isempty(cbflags.val.roicen)
            tmp = (double(vec(double(cbflags.val.roicen)))'-1).*[xwid xwid zwid];
            newroicen_all{cbflags.val.v} = cat(1, newroicen_all{cbflags.val.v}, tmp);
        elseif ~isempty(cbflags.delete.roi)
            newroicen_all{cbflags.val.v} = newroicen_all{cbflags.val.v}(1:end-1,:);
        end

        max_index_available_rois = [];
        for k = 1:numel(labsc)
            [rri, ~] = find_roi_index(labsc{k});
            max_index_available_rois = max([max_index_available_rois, cell2mat(rri)], [], 'all');
        end

        if isempty(newroicen_all{cbflags.val.v})
            error("deal with deleting roi")
        else
            for j = 1:size(newroicen_all{cbflags.val.v}, 1)
                newroicen = newroicen_all{cbflags.val.v}(j,:);
                maskmanual((umy - newroicen(1)).^2 + (umx - newroicen(2)).^2 + (umz - newroicen(3)).^2 <= newroirad.^2) = 1;
            end
            % pth_mroi_interactive = insertBefore(pth_mroi_interactive, '.mat', timestr);
            [roiinfo_new, resp_new] = make_morphological_rois(stack, stack_mnt, normopt, dtmni, [], [], pth_mroi_interactive, [], [], [], [], [], maskmanual);
            % optchts.vars_combine = 'any';
            % optchts.ignore_missing_vars;
            %choose_timeseries

            roipixind{cbflags.val.v} = roiinfo_new.roipixind;
            varsc{cbflags.val.v} = resp_new.in_rawf_pc_f_cl_f_w_no;
            labsc{cbflags.val.v} = {['ts.resp.fullfov.moex_interactive.in_rawf_pc_f_cl_f_w_no.ind1']};

        end
    else
        varsc{cbflags.val.v} = varsc{cbflags.val.v}(cbflags.val.i,:);
        labsc{cbflags.val.v} = labsc{cbflags.val.v}(cbflags.val.i);
    end

catch ME
    sprintf("user input for variable change has problem, returning to original variables")
    sprintf(ME.message)
end

for k = 1:numel(varsc)
    limsc{k} = find_yaxis_limits(varsc{k}, yaxisroomfac);
end

varcombos = make_varcombos(varsc);


end
