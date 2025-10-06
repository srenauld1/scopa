
function [h, framecount, cb] = axplt(h, stack, stackp, vid, framecount, varsp, ...
    varaxside, ti, tinds, cols, roialpha, roipixindp, ...
    pthgif, figure_title, varsz, doui, timestr_ui, sampinc, ...
    varsp_sc, labp_sc, rdummies, cmp, ccr, pval_norm, laginds_to_plot, ...
    cols_sc, scdimmin, scdimsd, vidrot)

cdfool = repmat(reshape([1 0 0], 1, 1, 3), [128 256 1]);
afool = repmat(0.4, [128 256 1]);
vidcenflag = 0;
clear cb_pr

cb = cb_flagdf([], 'all'); %set all flags to default

numvar = size(varsz, 1);
numchan = size(varsp, 3);
numplane = numel(h.im.ax);

imchan2rgb = {[2], [1 3]};
if numchan==1
    blink_on_inc = 1; %roi shown for all frames (ie not blinking)
elseif numchan==2
    blink_on_inc = 5; %roi shown every blink_on_inc frames
    roialpha = 1; %for 2 channel (magenta/green image), rois blink and are saturated, since colors are hard to see
end


if all(cellfun(@isempty,roipixindp))
    do_overlay = 0;
else
    do_overlay = 1;
    stack_oneframe = stack(:,:,:,1);
    [imroi, roialphamask] = roiolmake(imgray=stack_oneframe, roipx=roipixindp, rgb=cols, a=roialpha); %make an overlay for all rois, background is one frame since rois don't change across frames
end

tinds_use = tinds;
do_write_gif = 1;
tloop = 1;

% dlg = uicontrol();

vpmap_nonempty = find(varaxside);
roiplotinds = find(~cellfun(@isempty, roipixindp));
roipixindp_plane = {};
for k = 1:numel(roiplotinds)
    [inds2d, planeind] = ind2sub([size(stack_oneframe,1)*size(stack_oneframe,2, size(stack_oneframe,3))], roipixindp{roiplotinds(k)});
    for j = 1:numplane
        roipixindp_plane{k}{j} = inds2d(planeind==j);
    end
end

h.ttl.String{1} = figure_title;

while tloop

    force_do_write_gif = 0;

    for fr = 1:numel(tinds_use) %for each sample in chosen subset

        %%%% TIMESERIES %%%%

        for j = 1:numel(h.ts.ax) %for each subplot
            cnt = 0;
            for fi = 1:numel(h.ts.pl{j}) %for each axis side
                for k = 1:numel(h.ts.pl{j}{fi}) %for each variable
                    cnt = cnt+1;
                    for c = 1:numel(h.ts.pl{j}{fi}{k}) %for each channel
                        if fr==1 %only on first frame
                            h.ts.pl{j}{fi}{k}{c}.YData = varsp(vpmap_nonempty(cnt),:,c);
                        end
                        % if cnt==1
                        %     h.ts.pl{j}{fi}{k}{c}.Color(4) = 0.2;
                        % end
                        if ~isempty(cb.changed.varalpha) && cb.changed.varalpha(vpmap_nonempty(cnt),c)
                            h.ts.pl{j}{fi}{k}{c}.Color(4) = cb.quick.varalpha(vpmap_nonempty(cnt),c); %it seems 4th element of color can't be saved, or even queried, just written
                        end
                    end
                end
            end

            if j==2
                zoom_margin_sec = 15;
                h.ts.ax{j}.XAxis.Limits = [ti(tinds_use(fr))-zoom_margin_sec, ti(tinds_use(fr))+zoom_margin_sec];
                h.ts.ax{j}.XTick = ti(tinds_use(fr));
                h.ts.ax{j}.XAxis.TickLabels = [num2str(h.ts.ax{j}.XTick, 4) ' sec (+/- 6 sec)']; %same as h.ts.ax{j}.XTickLabel??
            end
            h.ts.lnx{j}.XData = [ti(tinds_use(fr)) ti(tinds_use(fr))];
        end


        %%%% STACK %%%%

        for j = 1:numplane %for each z slice

            if isempty(stackp)
                h.im.pl{j}.CData = stack(:,:,j,tinds_use(fr));
            else
                if ~isempty(cb.quick.imalpha) && any(cb.quick.imalpha(j,:)~=1) %if either channel alpha is not 1, must define each separately, and must do so for every frame like this, since alpha is fraction of every element 
                    for c = 1:numchan
                        if cb.quick.imalpha(j,c)~=1 %if imalpha is not 1 for this channel, multiply imalpha by the image; cb.quick.imalpha will not be empty since cb.quick.imalpha is not empty 
                            h.im.pl{j}.CData(:,:,imchan2rgb{c}) = squeeze(stackp(:,:,j,tinds_use(fr),imchan2rgb{c})).*cb.quick.imalpha(j,c); %scanimage channel 1 gets green adjustment (b in rgb channel 2)
                        else
                            h.im.pl{j}.CData(:,:,imchan2rgb{c}) = squeeze(stackp(:,:,j,tinds_use(fr),imchan2rgb{c})); 
                        end
                    end
                else
                    h.im.pl{j}.CData = squeeze(stackp(:,:,j,tinds_use(fr),:)); %squeeze to make it 3d (2d plus color channel)
                end
            end

            if do_overlay %if there are roi variables
                if fr==1
                    h.im.ol{j}.CData = squeeze(imroi(:,:,j,:)); %squeeze to make it 3d (2d plus color channel)
                    h.im.ol{j}.AlphaData = roialphamask(:,:,j);
                else
                    for k = 1:numel(roiplotinds)
                        if ( ~isempty(cb.changed.varalpha) && any(cb.changed.varalpha(roiplotinds(k),:)) ) || (numchan==2 && mod(fr, blink_on_inc)==0)
                            h.im.ol{j}.AlphaData(roipixindp_plane{k}{j}) = roialpha*max(cb.quick.varalpha(roiplotinds(k)), [], 2); %max across both channels; bug: regions where rois overlap get changed for either roi they belong to
                        elseif numchan==2 && mod(fr, blink_on_inc)==1 %if it's the first "blink off" frame of a blink cycle, which only exists if numchan==2 (don't do every blink off frame to save time updating imroialpha)
                            h.im.ol{j}.AlphaData(:) = 0;
                        end
                    end
                end
            end
        end


        %%%% SCATTERPLOT %%%%

        lagind = laginds_to_plot;
        if isprop(h.sc.pl{1}, 'ThetaData')
            if polar_index==1
                h.sc.pl{1}.ThetaData = varsp_sc(1, lagind,:);
                h.sc.pl{1}.RData = varsp_sc(2, lagind,:);
            elseif polar_index==2
                h.sc.pl{1}.ThetaData = varsp_sc(2, lagind,:);
                h.sc.pl{1}.RData = varsp_sc(1, lagind,:);
            elseif isequal(polar_index, [1 2])
                error("double scatter need to plot two thetas; this is already set up in init, just not here, just meed to cat varsp_sc and dummies")
                h.sc.pl{1}.ThetaData = varsp_sc(1, lagind,:);
                h.sc.pl{1}.RData = rdummies(1, lagind,:);
            end

            % if numel(laby)>maxlablength
            %     labt = cat(2, labt(1:maxlablength), '\newline', labt(maxlablength+1:end)))
            % end
            h.sc.ax{1}.ThetaAxis.Label.String = ['\color{blue} Theta:' labp_sc{1}];
            h.sc.ax{1}.RAxis.Label.String = ['\color{red} Rho: ' labp_sc{2}];
            % if strcmp(ylim_constancy, 'eachvar')
            %     h.sc.ax{1}.RLim = lims.y.eachpad(yi,:);
            %     h.sc.ax{1}.RTick = sort([0, lims.y.each(yi,1), lims.y.each(yi,2)]);
            %     h.sc.ax{1}.RTickLabel = [];
            %     % for tti = 1:numel(h.sc.ax.RTick)
            %     %     h.sc.ax{1}.RTickLabel{tti} = num2str(h.sc.ax{1}.RTick(tti), 4);%'%.2g'
            %     % end
            % end

            % if isempty(regexp(labp_sc{1}, ' CUE yaw'))
            %     h.sc.hln{1}.LineStyle = 'none';
            % else
            %     h.sc.hln{1}.RData = [lims.y.each(yi,2) lims.y.eachpad(yi,2)]; %blindspot red line from data max to xtra max, to be sure it doesn't cover data
            %     h.sc.hln{1}.LineStyle = '-';
            % end

        else

            h.sc.pl{1}.XData = varsp_sc(1,lagind,:);
            h.sc.pl{1}.YData = varsp_sc(2,lagind,:);

            % h.sc.pl{1}.SizeData = linspace(0, 1, numel(h.sc.pl{1}.XData));
            % if ~plot_z_as_color
            %     h.sc.pl{1}.ZData = varsp_sc(3,lagind,:);
            % end

            k = 1; %hack
            h.sc.ax{1}.XLabel.String{1} = sprintf('\\color[rgb]{%f, %f, %f}%s', cols_sc(k,:), [labp_sc{k}]);
            h.sc.ax{1}.XLabel.FontSize = 7;
            k = 2; %hack
            h.sc.ax{1}.YLabel.String{2} = sprintf('\\color[rgb]{%f, %f, %f}%s', cols_sc(k,:), [labp_sc{k}]);
            h.sc.ax{1}.YLabel.FontSize = 7;

            % h.sc.ax{1}.ZLabel.String = labp_sc{3};

        end


        % h.sc.pl{1}.CData = cmp{lagind};
        % if fr==1
        %     h.sc.pl{1}.CData = repmat(cmp{lagind}, size(varsp_sc,3), 1);
        % end
        scdimmu = ti(tinds_use(fr));
        scdimmax = 1;
        scdimmin = 0.02;
        scdimsd = 20;
        dimout = exp(-(((ti-scdimmu).^2)/(2*scdimsd.^2))); %gaussian profile for dimming markers
        dimout = rescale(dimout, scdimmin, scdimmax ); %  plot(ti, dimout);
        h.sc.pl{1}.CData(:,1) = 1-dimout;
        h.sc.pl{1}.CData(:,2) = 1-dimout;
        h.sc.pl{1}.CData(:,3) = 1-dimout;

        if ~isempty(h.sc.br) %bar plot
            h.sc.br{1}.ax.Title.String = ['LAGS (CURR: ' sprintf('%.2g', actual_lags_xy_sec(lagind)) ' SEC)'];
            h.sc.br{1}.pl.FaceColor = 'flat';
            h.sc.br{1}.pl.XData = actual_lags_xy_sec;
            h.sc.br{1}.pl.YData = ccr;
            h.sc.br{1}.pl.CData = repmat([0 0 1], numel(pval_norm), 1);
            h.sc.br{1}.pl.CData(:,1) = pval_norm;
            h.sc.br{1}.pl.CData(:,2) = pval_norm;
            h.sc.br{1}.hln.Value = actual_lags_xy_sec(lagind);
        end


        %%%% FICTRAC VIDEO %%%%
        if ndims(vid)==3
            h.vid.pl{1}.CData = vid(:,:,tinds_use(fr)); %fictrac video
        else
            h.vid.pl{1}.CData = vid(:,:,:,tinds_use(fr)); %fictrac video
        end
        if vidcenflag
            nc1 = cb.val.vidcen{vidcenv}(1);
            nc2 = cb.val.vidcen{vidcenv}(2);
            newinc = 2;
            h.vid.ol{j}.CData(nc1-newinc:nc1+newinc, nc2-newinc:nc2+newinc,:) = cdfool(nc1-2:nc1+2, nc2-2:nc2+2,:); %squeeze to make it 3d (2d plus color channel)
            h.vid.ol{j}.AlphaData(nc1-newinc:nc1+newinc, nc2-newinc:nc2+newinc) = afool(nc1-2:nc1+2, nc2-2:nc2+2);
        end
        if fr==1
            h.vid.ax{1}.View(1) = vidrot;
        end


        %%%% WRITE TO GIF %%%%
        framecount = framecount + 1;
        drawnow
        if do_write_gif
            fig2gif(h.fg, framecount, pthgif) %write to gif
        end


        %%%% PROCESS USER INPUT CALLBACKS %%%%
        if doui
            % cb = cb_flagdf(cb, 'quick'); %set all 'quick' flags to default
            [cb, h.ttl.String{2}] = cb_pr(cb, h, varsz, varsp, roiplotinds, roipixindp_plane, ti, tinds_use, sampinc);
            tloop = 1;
        else
            tloop = 0;
        end

        if cb.restart.v==1
            vidcenflag = 0;
            pause(0.2)
            tloop = 0;
            break; %exit the t for loop
        end
        if cb.restart.t==1
            tloop = 1;
            tinds_use = cb.val.tinds(1):cb.val.sampinc:cb.val.tinds(end);
            if ~isempty(cb.val.vidcen)
                vidcenflag = 1;
                varsp(cb.val.v,:) = rescale(vid(cb.val.vidcen{cb.val.v}(1),cb.val.vidcen{cb.val.v}(2),:,:), 0, 1);
                vidcenv = cb.val.v;
            end
            cb.restart.t = [];
            framecount = 0;
            pthgif = erase(pthgif, timestr_ui); %make sure timestr is not present, otherwise you'll accumulate with insertBefore
            pthgif = insertBefore(pthgif, '.gif', timestr_ui);
            force_do_write_gif = 1; %when restarting with new tinds, write to gif the first time through
            pause(0.2)
            clear cb_pr
            break; %exit the t for loop and restart with different t, but same variables
        end

        if numel(tinds_use)==1
            tloop = 0;
        end


    end

    if force_do_write_gif
        do_write_gif = 1;
    else
        do_write_gif = 0; %after looping through all frames, turn off gif writing (unless it's turned back on by user input)
    end

    if cb.restart.v==1 %a new plotvar set was requested
        pause(0.2)
        break; %exit the while loop of the t for loop and restart with changes to variables
    end

end

end


