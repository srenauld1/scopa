
function [hndls, framecount, cbflags] = plot_axes(hndls, stack, ftv, framecount, varsp, ti, tinds, cols, roialpha, pixinds_roi, fngif, figure_title, interactive, pth_tmpfiles, varsz)

clear make_roi_overlay %make sure persistent variable is cleared

cbflags = reset_cbflags();

fn = fieldnames(varsp);

hndls.httl.String = figure_title;

stack_oneframe = stack(:,:,:,1);
[imroi, imalpha] = make_roi_overlay(stack_oneframe, pixinds_roi, cols, roialpha); %make an overlay for all rois, background is one frame since rois don't change across frames

tinds_use = tinds;

tloop = 1;
while tloop

    for fr = 1:numel(tinds_use) %for each sample in chosen subset

        %%%% TIMESERIES %%%%
        for j = 1:numel(hndls.ts.hax) %for each subplot
            if fr==1 %only on first frame
                for fi = 1:numel(fn) %for each side (left and right)
                    for k = 1:numel(hndls.ts.hpl{j}{fi}) %for each variable
                        hndls.ts.hpl{j}{fi}{k}.YData = varsp.(fn{fi})(k,:);
                    end
                end
            end
            if j==2
                hndls.ts.hax{j}.XAxis.Limits = [ti(tinds_use(fr))-6, ti(tinds_use(fr))+6];
                hndls.ts.hax{j}.XTick = ti(tinds_use(fr));
                hndls.ts.hax{j}.XAxis.TickLabels = [num2str(hndls.ts.hax{j}.XTick, 4) ' sec (+/- 6 sec)'];
                % hndls.ts.hax{j}.XTickLabel = [num2str(hndls.ts.hax{j}.XTick) ' sec (+/- 6 sec)'];
            end
            hndls.ts.hlnx{j}.XData = [ti(tinds_use(fr)) ti(tinds_use(fr))];
        end


        %%%% STACK %%%%
        for j = 1:numel(hndls.st.hax) %for each z slice

            hndls.st.hpl{j}.CData = stack(:,:,j,tinds_use(fr));
            if fr==1
                if ~all(cellfun(@isempty,pixinds_roi)) %if there are roi variables
                    hndls.st.hol{j}.CData = squeeze(imroi(:,:,j,:)); %squeeze to make it 3d (2d plus color channel)
                    hndls.st.hol{j}.AlphaData = imalpha(:,:,j);
                end
            end

        end


        %%%% FICTRAC VIDEO %%%%
        hndls.ftv.hpl{1}.CData = ftv(:,:,tinds_use(fr)); %fictrac video


        %%%% WRITE TO GIF %%%%
        framecount = framecount + 1;
        fig2gif(hndls.hfg, framecount, fngif) %write to gif


        %%%% PROCESS CALLBACKS %%%%
        if interactive
            cbflags = process_callback_files(cbflags, pth_tmpfiles, varsz, ti);
            tloop = 1;
        else
            tloop = 0;
        end

        if cbflags.newtitle
            hndls.httl.String = cbflags.newtitle;
        end
        if cbflags.restart==1
            pause(0.2)
            tloop = 0;
            break;
        end
        if cbflags.restart_tloop==1
            tloop = 1;
            tinds_use = find(ti>cbflags.tnew(1) & ti<cbflags.tnew(2));
            cbflags.restart_tloop = [];
            framecount = 0;
            % timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS')); %insert timestring when interactive to record each change in user input
            % fngif = insertBefore(fngif, '.gif', timestr);
            pause(0.2)
            break;
        end

    end

    if cbflags.restart==1
        pause(0.2)
        break;
    end

end

clear make_roi_overlay %make sure persistent variable is cleared

end



