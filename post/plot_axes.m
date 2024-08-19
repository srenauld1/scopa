
function [hndls, framecount, cbflags] = plot_axes(hndls, stack, ftv, framecount, varsp, ...
    vpmapflat_axid, ti, tinds, cols, roialpha, roipixindp, ...
    pthgif, figure_title, varsz, letui, timestr_ui, sampinc, ...
    varsp_sc, labp_sc, rdummies, cmp, ccr, pval_norm, laginds_to_plot, cols_sc, scdimmin, scdimsd)


cbflags = default_cbflags([], 'all'); %set all flags to default

if all(cellfun(@isempty,roipixindp))
    do_overlay = 0;
else
    do_overlay = 1;
    stack_oneframe = stack(:,:,:,1);
    clear make_roi_overlay pltexp_process_callbacks %clear persistent variables
    [imroi, imalpha] = make_roi_overlay(stack_oneframe, roipixindp, cols, roialpha); %make an overlay for all rois, background is one frame since rois don't change across frames
end

tinds_use = tinds;
do_write_gif = 1;
tloop = 1;

% dlg = uicontrol();

vpmap_nonempty = find(vpmapflat_axid);
roiplotinds = find(~cellfun(@isempty, roipixindp));


hndls.httl.String{1} = figure_title;


while tloop

    force_do_write_gif = 0;
    ctmp = ones(numel(hndls.ts.hax),size(varsz, 1));
    change_overlay_alpha = 0;

    for fr = 1:numel(tinds_use) %for each sample in chosen subset

        %%%% TIMESERIES %%%%

        for j = 1:numel(hndls.ts.hax) %for each subplot
            cnt = 0;
            for fi = 1:numel(hndls.ts.hpl{j}) %for each axis side
                for k = 1:numel(hndls.ts.hpl{j}{fi}) %for each variable
                    cnt = cnt+1;
                    if fr==1 %only on first frame
                        hndls.ts.hpl{j}{fi}{k}.YData = varsp(vpmap_nonempty(cnt),:);
                    end
                    if ~isempty(cbflags.quick.linealpha) && cbflags.quick.linealpha{vpmap_nonempty(cnt)}
                        ctmp(j,vpmap_nonempty(cnt)) = change_alpha_ts(ctmp(j,vpmap_nonempty(cnt)), cbflags.quick.linealpha{vpmap_nonempty(cnt)});
                        hndls.ts.hpl{j}{fi}{k}.Color(4) = ctmp(j,vpmap_nonempty(cnt));
                    end
                end
            end
            if j==2
                hndls.ts.hax{j}.XAxis.Limits = [ti(tinds_use(fr))-6, ti(tinds_use(fr))+6];
                hndls.ts.hax{j}.XTick = ti(tinds_use(fr));
                hndls.ts.hax{j}.XAxis.TickLabels = [num2str(hndls.ts.hax{j}.XTick, 4) ' sec (+/- 6 sec)']; %same as hndls.ts.hax{j}.XTickLabel??
            end
            hndls.ts.hlnx{j}.XData = [ti(tinds_use(fr)) ti(tinds_use(fr))];
        end


        %%%% STACK %%%%

        if ~isempty(cbflags.quick.linealpha) && do_overlay && fr>1
            alpha_changes_for_rois = cell2mat(cbflags.quick.linealpha(roiplotinds));
            if any(alpha_changes_for_rois) %if any alpha changes apply to roi variables
                roiinds_for_alphachange = roiplotinds(find(alpha_changes_for_rois));
                imalpha = change_alpha_st(imalpha, roipixindp(roiinds_for_alphachange), cbflags.quick.linealpha(roiinds_for_alphachange), roialpha);
                change_overlay_alpha = 1;
            end
        end

        for j = 1:numel(hndls.st.hax) %for each z slice

            hndls.st.hpl{j}.CData = stack(:,:,j,tinds_use(fr));
            if do_overlay %if there are roi variables
                if fr==1
                    hndls.st.hol{j}.CData = squeeze(imroi(:,:,j,:)); %squeeze to make it 3d (2d plus color channel)
                end
                if fr==1 || change_overlay_alpha==1
                    hndls.st.hol{j}.AlphaData = imalpha(:,:,j);
                end
            end

        end


        %%%% SCATTERPLOT %%%%

        lagind = laginds_to_plot;
        if isprop(hndls.sc.hpl{1}, 'ThetaData')


            if polar_index==1
                hndls.sc.hpl{1}.ThetaData = varsp_sc(1, lagind,:);
                hndls.sc.hpl{1}.RData = varsp_sc(2, lagind,:);
            elseif polar_index==2
                hndls.sc.hpl{1}.ThetaData = varsp_sc(2, lagind,:);
                hndls.sc.hpl{1}.RData = varsp_sc(1, lagind,:);
            elseif isequal(polar_index, [1 2])
                error("double scatter need to plot two thetas; this is already set up in init, just not here, just meed to cat varsp_sc and dummies")
                hndls.sc.hpl{1}.ThetaData = varsp_sc(1, lagind,:);
                hndls.sc.hpl{1}.RData = rdummies(1, lagind,:);
            end

            % if numel(laby)>maxlablength
            %     labt = cat(2, labt(1:maxlablength), '\newline', labt(maxlablength+1:end)))
            % end
            hndls.sc.hax{1}.ThetaAxis.Label.String = ['\color{blue} Theta:' labp_sc{1}];
            hndls.sc.hax{1}.RAxis.Label.String = ['\color{red} Rho: ' labp_sc{2}];
            % if strcmp(ylim_constancy, 'eachvar')
            %     hndls.sc.hax{1}.RLim = lims.y.each_xtra(yi,:);
            %     hndls.sc.hax{1}.RTick = sort([0, lims.y.each(yi,1), lims.y.each(yi,2)]);
            %     hndls.sc.hax{1}.RTickLabel = [];
            %     % for tti = 1:numel(hndls.sc.hax.RTick)
            %     %     hndls.sc.hax{1}.RTickLabel{tti} = num2str(hndls.sc.hax{1}.RTick(tti), 4);%'%.2g'
            %     % end
            % end

            % if isempty(regexp(labp_sc{1}, ' CUE yaw'))
            %     hndls.sc.hln{1}.LineStyle = 'none';
            % else
            %     hndls.sc.hln{1}.RData = [lims.y.each(yi,2) lims.y.each_xtra(yi,2)]; %blindspot red line from data max to xtra max, to be sure it doesn't cover data
            %     hndls.sc.hln{1}.LineStyle = '-';
            % end


        else


            hndls.sc.hpl{1}.XData = varsp_sc(1,lagind,:);
            hndls.sc.hpl{1}.YData = varsp_sc(2,lagind,:);

            % hndls.sc.hpl{1}.SizeData = linspace(0, 1, numel(hndls.sc.hpl{1}.XData));
            % if ~plot_z_as_color
            %     hndls.sc.hpl{1}.ZData = varsp_sc(3,lagind,:);
            % end

            k = 1; %hack
            hndls.sc.hax{1}.XLabel.String{1} = sprintf('\\color[rgb]{%f, %f, %f}%s', cols_sc(k,:), ['X. ' labp_sc{k}]);
            k = 2; %hack
            hndls.sc.hax{1}.XLabel.String{2} = sprintf('\\color[rgb]{%f, %f, %f}%s', cols_sc(k,:), ['Y. ' labp_sc{k}]);

            % hndls.sc.hax{1}.ZLabel.String = labp_sc{3};

        end


        % hndls.sc.hpl{1}.CData = cmp{lagind};
        % if fr==1
        %     hndls.sc.hpl{1}.CData = repmat(cmp{lagind}, size(varsp_sc,3), 1);
        % end
        scdimmu = ti(tinds_use(fr)); 
        scdimmax = 1;
        scdimmin = 0.02;
        scdimsd = 20;
        dimout = exp(-(((ti-scdimmu).^2)/(2*scdimsd.^2))); %gaussian profile for dimming markers
        dimout = rescale(dimout, scdimmin, scdimmax ); %  plot(ti, dimout);
        hndls.sc.hpl{1}.CData(:,1) = 1-dimout;
        hndls.sc.hpl{1}.CData(:,2) = 1-dimout;
        hndls.sc.hpl{1}.CData(:,3) = 1-dimout;

        if ~isempty(hndls.sc.br) %bar plot
            hndls.sc.br{1}.hax.Title.String = ['LAGS (CURR: ' sprintf('%.2g', actual_lags_xy_sec(lagind)) ' SEC)'];
            hndls.sc.br{1}.hpl.FaceColor = 'flat';
            hndls.sc.br{1}.hpl.XData = actual_lags_xy_sec;
            hndls.sc.br{1}.hpl.YData = ccr;
            hndls.sc.br{1}.hpl.CData = repmat([0 0 1], numel(pval_norm), 1);
            hndls.sc.br{1}.hpl.CData(:,1) = pval_norm;
            hndls.sc.br{1}.hpl.CData(:,2) = pval_norm;
            hndls.sc.br{1}.hln.Value = actual_lags_xy_sec(lagind);
        end


        %%%% FICTRAC VIDEO %%%%
        hndls.ftv.hpl{1}.CData = ftv(:,:,tinds_use(fr)); %fictrac video


        %%%% WRITE TO GIF %%%%
        framecount = framecount + 1;
        drawnow
        if do_write_gif
            fig2gif(hndls.hfg, framecount, pthgif) %write to gif
        end


        %%%% PROCESS USER INPUT CALLBACKS %%%%
        if letui
            cbflags = default_cbflags(cbflags, 'quick'); %set all 'quick' flags to default
            change_overlay_alpha = 0;
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
            tinds_use = cbflags.val.tinds(1):cbflags.val.sampinc:cbflags.val.tinds(end);
            cbflags.restart.t = [];
            framecount = 0;
            pthgif = erase(pthgif, timestr_ui); %make sure timestr is not present, otherwise you'll accumulate with insertBefore
            pthgif = insertBefore(pthgif, '.gif', timestr_ui);
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



function ctmp = change_alpha_ts(ctmp, dalpha)

ctmp = ctmp + dalpha;
if ctmp<0
    ctmp = 0;
end
if ctmp>1
    ctmp = 1;
end

end


function imalpha = change_alpha_st(imalpha, roipixindp, dalpha, roialpha)

%overlapping rois will get changed multiple times, oh well

for j = 1:numel(roipixindp)
    imalpha(roipixindp{j}) = imalpha(roipixindp{j}) + roialpha*dalpha{j};
    imalpha(imalpha<0) = 0;
    imalpha(imalpha>roialpha) = roialpha;
end

end





