
function [vars, labs, lims, roipx, varcombos] = uiapply(cb, vars, labs, roipx, stack, ti, imper, pth_mroi_interactive, normopt, newroirad, newroicen_all, xwid, ywid, zwid, yaxisroomfac, numsamp)

"WARNING, FIX THE HARD-CODED CHANNEL HANDLING IN uiapply "

try

    if ~isempty(cell2mat(cb.val.roicen))

        max_index_available_rois = numel(roipx);

        roimaskman = zeros(size(stack,1), size(stack,2), size(stack,3), 'logical');
        if zwid==0
            [umx, umy] = meshgrid(0:xwid:xwid*(size(roimaskman,2)-1), 0:ywid:ywid*(size(roimaskman,1)-1));
            umz = [];
        else
            [umx, umy, umz] = meshgrid(0:xwid:xwid*(size(roimaskman,2)-1), 0:ywid:ywid*(size(roimaskman,1)-1), 0:zwid:zwid*(size(roimaskman,3)-1));
        end
        cnt = 0;
        for j = 1:numel(cb.val.roicen)
            if ~isempty(cb.val.roicen{j})
                cnt = cnt+1;
                if cb.val.v(cnt)~=j
                    error("v must match cnt")
                end

                [roipixind_new, vars{j}] = make_ui_roi(cb.val.roicen{j}, newroicen_all{j}, xwid, ywid, zwid, roimaskman, umy, umx, umz, newroirad, stack, normopt, ti, imper, pth_mroi_interactive); % cb.delete.roicen{cb.val.v}
                roipx = cat(1, roipx, roipixind_new);
                disp("warning, hard coding ui parsex and parsnorm, fix this now")
                labs{j} = {['resp.fullfov.moex_interactive.in_rawf_pc_f_cl_f_w_no.ind' num2str(max_index_available_rois+cnt)]}; %cell in cell to match output of choose_timeseries
            end
        end

    elseif ~isempty(cell2mat(cb.val.i))

        cnt = 0;
        for j = 1:numel(cb.val.i)
            if ~isempty(cb.val.i{j})
                cnt = cnt+1;
                if cb.val.v(cnt)~=j
                    error("v must match cnt")
                end

                vars{j} = mean(vars{j}(cb.val.i{j},:), 1);
                labs{j} = labs{vind}(cb.val.i{j});
            end
        end

    elseif ~isempty(cell2mat(cb.val.vdel))

        cnt = 0;
        for j = 1:numel(cb.val.vdel)
            if ~isempty(cb.val.vdel{j})
                cnt = cnt+1;
                if cb.val.v(cnt)~=j
                    error("v must match cnt")
                end
                vars{j} = nan(1,numsamp,'single');
                labs{j} = {''};
            end
        end
    end

catch ME
    sprintf("user input for variable change has problem, returning to original variables")
    sprintf(ME.message)
end

for j = 1:numel(vars)
    lims{j} = find_yaxis_limits(vars{j}, yaxisroomfac);
end

varcombos = make_varcombos(vars);

end


function [roipx, resp] = make_ui_roi(roicen, newroicen_all, xwid, ywid, zwid, roimaskman, umy, umx, umz, newroirad, stack, normopt, ti, imper, pth_mroi_interactive)

if ~isempty(roicen)
    if zwid==0
        tmp = [ywid xwid].*(double(roicen(1:2))-1) + [ywid xwid]/2; %add back half width to center
    else
        tmp = [ywid xwid zwid].*(double(roicen)-1) + [ywid xwid zwid]/2; %add back half width to center
    end
    newroicen_all = cat(1, newroicen_all, tmp);
elseif ~isempty(cb.delete.roicen)
    newroicen_all = newroicen_all(1:end-1,:);
end

if isempty(newroicen_all)
    error("deal with deleting roi")
else
    for j = 1:size(newroicen_all, 1)
        newroicen = newroicen_all(j,:);
        if zwid==0
            roimaskman((umy - newroicen(1)).^2 + (umx - newroicen(2)).^2 <= newroirad.^2) = 1;
        else
            roimaskman((umy - newroicen(1)).^2 + (umx - newroicen(2)).^2 + (umz - newroicen(3)).^2 <= newroirad.^2) = 1;
        end
    end


    uitmp = uipars('nofile'); %call uipars to retrieve params used in a2p so you don't have to pass big param structs all the way down into this function; use 'nofile' option to skip the file searching because all we need is the mroi substruct 
    % uitmp.mroi.wavp = [];
    
    [roidat_new, resp] = mroimake(stack, uitmp.mroi, ti, imper, [], [], [], pth_mroi_interactive, [], [], [], [], [], roimaskman);
    hardcodechan = 1;
    hardcodenorm = 'rawf_f_f_n';
    resp = channel_combine_struct(resp);
    resp = resp.(hardcodenorm);
    roipx = roidat_new(hardcodechan).roipx;

end

end