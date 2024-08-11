
function [hndls, framecount, cbflags] = plot_axes(hndls, stack, ftv, framecount, varsp, ti, tinds, cols, roialpha, roipixindp, fngif, figure_title, varsz, letui, timestr_ui, sampinc)


cbflags = reset_cbflags([], 'all');

axsides = fieldnames(varsp);

stack_oneframe = stack(:,:,:,1);
clear make_roi_overlay pltexp_process_callbacks  %clear persistent variables 
[imroi, imalpha] = make_roi_overlay(stack_oneframe, roipixindp, cols, roialpha); %make an overlay for all rois, background is one frame since rois don't change across frames

tinds_use = tinds;
do_write_gif = 1;
tloop = 1;

% dlg = uicontrol();


hndls.httl.String{1} = figure_title;


while tloop

    force_do_write_gif = 0;

    for fr = 1:numel(tinds_use) %for each sample in chosen subset

        %%%% TIMESERIES %%%%
        for j = 1:numel(hndls.ts.hax) %for each subplot
            if fr==1 %only on first frame
                for fi = 1:numel(axsides) %for each side (left and right)
                    for k = 1:numel(hndls.ts.hpl{j}{fi}) %for each variable
                        hndls.ts.hpl{j}{fi}{k}.YData = varsp.(axsides{fi})(k,:);
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
                if ~all(cellfun(@isempty,roipixindp)) %if there are roi variables
                    hndls.st.hol{j}.CData = squeeze(imroi(:,:,j,:)); %squeeze to make it 3d (2d plus color channel)
                    hndls.st.hol{j}.AlphaData = imalpha(:,:,j);
                end
            end

        end


        %%%% FICTRAC VIDEO %%%%
        hndls.ftv.hpl{1}.CData = ftv(:,:,tinds_use(fr)); %fictrac video


        %%%% WRITE TO GIF %%%%
        framecount = framecount + 1;
        drawnow
        if do_write_gif
            fig2gif(hndls.hfg, framecount, fngif) %write to gif
        end


        %%%% PROCESS USER INPUT CALLBACKS %%%%
        if letui
            [cbflags, hndls.httl.String{2}] = pltexp_process_callbacks(cbflags, hndls, varsz, varsp, roipixindp, ti, tinds_use, sampinc);
            tloop = 1;
        else
            tloop = 0;
        end

        if cbflags.restart.v==1
            pause(0.2)
            tloop = 0;
            break; %exit the t for loop 
        end
        if cbflags.restart.t==1
            tloop = 1;
            tinds_use = cbflags.val.tinds;
            cbflags.restart.t = [];
            framecount = 0;
            fngif = erase(fngif, timestr_ui); %make sure timestr is not present, otherwise you'll accumulate with insertBefore
            fngif = insertBefore(fngif, '.gif', timestr_ui);
            force_do_write_gif = 1; %when restarting with new tinds, write to gif the first time through
            pause(0.2)
            clear pltexp_process_callbacks
            break; %exit the t for loop and restart with different t, but same variables
        end

    end

    if force_do_write_gif
        do_write_gif = 1;
    else
        do_write_gif = 0; %after looping through all frames, turn off gif writing (unless it's turned back on by user input)
    end

    if cbflags.restart.v==1 %a new plotvar set was requested
        pause(0.2)
        break; %exit the while loop of the t for loop and restart with changes to variables
    end

end

clear make_roi_overlay %make sure persistent in make_roi_overlay variable is cleared

end





