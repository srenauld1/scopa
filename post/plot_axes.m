
function [hndls, framecount] = plot_axes(hndls, stack, ftv, roi_index, crosshair, framecount, varsp, tinew, fngif, roi_type, figure_title, roiim, alphaim)


fn = fieldnames(varsp);

hndls.httl.String = figure_title;

for j = 1:numel(hndls.ts.hax) %for each subplot
    for fi = 1:numel(fn) %for each side (left and right)
        for k = 1:numel(hndls.ts.hpl{j}{fi}) %for each variable
            hndls.ts.hpl{j}{fi}{k}.YData = varsp.(fn{fi})(k,:);
        end
    end
end

for fr = 1:size(stack,4) %for each frame (sample)

    %%%% TIMESERIES %%%%
    for j = 1:numel(hndls.ts.hax) %for each subplot
        if j==2
            hndls.ts.hax{j}.XAxis.Limits = [tinew(fr)-6, tinew(fr)+6];
            hndls.ts.hax{j}.XAxis.TickLabels = num2str(tinew(fr)+6, 4);
            hndls.ts.hax{j}.XTick = tinew(fr);
            hndls.ts.hax{j}.XTickLabel = [num2str(hndls.ts.hax{j}.XTick) ' sec (+/- 6 sec)'];
        end
        hndls.ts.hlnx{j}.XData = [tinew(fr) tinew(fr)];
    end

    %%%% STACK %%%%
    for j = 1:numel(hndls.st.hax) %for each z slice

        if strcmp(roi_type, 'rois') %roi_type pixels image never changes
            hndls.st.hpl{j}.CData = stack(:,:,j,fr);
            if fr==1 && ~isempty(alphaim) %if there are roi variables
                hndls.st.hol{j}.CData = squeeze(roiim(:,:,j,:)); %squeeze to make it 3d (2d plus color channel)
                hndls.st.hol{j}.AlphaData = alphaim(:,:,j);
            end
        end

        % if fr==1
        %     if j==crosshair{roi_index}(3)
        %         hndls.st.hlny{j}{ri}.Value = crosshair{roi_index}(1);
        %         hndls.st.hlnx{j}{ri}.Value = crosshair{roi_index}(2);
        %         hndls.st.hlny{j}{ri}.LineStyle = '-';
        %         hndls.st.hlnx{j}{ri}.LineStyle = '-';
        %     else
        %         hndls.st.hlny{j}{ri}.LineStyle = 'none';
        %         hndls.st.hlnx{j}{ri}.LineStyle = 'none';
        %     end
        % end
    end


    %%%% FICTRAC VID %%%%
    hndls.ftv.hpl{1}.CData = ftv(:,:,fr); %fictrac video


    framecount = framecount + 1;
    fig2gif(hndls.hfg, framecount, fngif) %write to gif

end


end