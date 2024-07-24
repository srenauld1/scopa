
function [varcombos, varsc_out, labsc_out, roiinfo_out, newroicen_um_all, limsc] = apply_user_input(cbflags, varsc_in, labsc_in, roiinfo_in, stack, stack_mnt, dtmni, pth_mroi_interactive, normopt, newroirad, timestr, newroicen_um_all, xwid, zwid, limsc, yaxisroomfac)

varsc_out = varsc_in;
labsc_out = labsc_in;

try
    if ~isempty(cbflags.uiroipixind) || ~isempty(cbflags.uiroidelete)

        maskmanual = [];
        maskmanual_oneroi = zeros(size(stack_mnt,1), size(stack_mnt,2), size(stack_mnt,3), 'logical');
        [umy, umx, umz] = meshgrid(0:xwid:xwid*(size(maskmanual_oneroi,2)-1), 0:xwid:xwid*(size(maskmanual_oneroi,1)-1), 0:zwid:zwid*(size(maskmanual_oneroi,3)-1));
        
        newroicen_um_all = cell(1, numel(labsc_in));
        if ~isempty(cbflags.uiroipixind)
            newroicen_um = (double(vec(double(cbflags.uiroipixind)))'-1).*[xwid xwid zwid];
            newroicen_um_all{cbflags.pvarind} = cat(1, newroicen_um_all{cbflags.pvarind}, newroicen_um);
        elseif ~isempty(cbflags.uiroidelete)
            newroicen_um_all{cbflags.pvarind} = newroicen_um_all{cbflags.pvarind}(1:end-1,:);
        end

        max_index_available_rois = [];
        for k = 1:numel(newroicen_um_all)
            [rri, ~]=find_roi_index(labsc_in{k});
            max_index_available_rois = max([max_index_available_rois, cell2mat(rri)], [], 'all');
            if ~isempty(newroicen_um_all{k})
                for j = 1:size(newroicen_um_all{k}, 1)
                    newroicen = newroicen_um_all{k}(j,:);
                    maskmanual_oneroi((umy - newroicen(1)).^2 + (umx - newroicen(2)).^2 + (umz - newroicen(3)).^2 <= newroirad.^2) = 1;
                end
                maskmanual = cat(4, maskmanual, maskmanual_oneroi);
            end
        end
        % pth_mroi_interactive = insertBefore(pth_mroi_interactive, '.mat', timestr);
        [roiinfo_out, resp_new] = make_morphological_rois(stack, stack_mnt, normopt, dtmni, [], [], pth_mroi_interactive, [], [], [], [], [], roiinfo_in, maskmanual);
        % optchts.vars_combine = 'any';
        % optchts.ignore_missing_vars;
        %choose_timeseries

        cnt = 0;
        for k = 1:numel(newroicen_um_all)
            if ~isempty(newroicen_um_all{k})
                cnt = cnt+1;
                varsc_out{k} = resp_new.in_rawf_pc_f_cl_f_w_no(cnt,:);
                labsc_out{k} = {['ts.resp.fullfov.moex_interactive.in_rawf_pc_f_cl_f_w_no.ind' num2str(max_index_available_rois+cnt)]};
                limsc{k} = find_yaxis_limits(varsc_out{k}, yaxisroomfac);
            end
        end
    else
        varsc_out{cbflags.pvarind} = varsc_in{cbflags.pvarind}(cbflags.ivarind,:);
        labsc_out{cbflags.pvarind} = labsc_in{cbflags.pvarind}(cbflags.ivarind);
    end
catch ME
    sprintf("user input for variable change has problem, returning to original variables")
    sprintf(ME.message)
end

varcombos = make_varcombos(varsc_out);


end
