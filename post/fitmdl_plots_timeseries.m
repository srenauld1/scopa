function fitmdl_plots_timeseries(indv, depv, mdl, varst, plt, supp, pth_fitdata_prefix, epochinds_str_all)

%use *_cont rather than *_seg, since the timeseries only plot does not truncate for space

fn = fieldnames(varst);
for fi = 1:numel(fn)
    eval([fn{fi} '= varst.(fn{fi});' ]);
end
varst = [];
fn = fieldnames(plt);
for fi = 1:numel(fn)
    eval([fn{fi} '= plt.(fn{fi});' ]);
end
plt = [];
fn = fieldnames(supp);
for fi = 1:numel(fn)
    eval([fn{fi} '= supp.(fn{fi});' ]);
end
plt = [];

indv = indv(:,sampinds_indvpreaug);
indv = indv.';
depv = depv(roiinds_plot,sampinds_depvpre);

title_add_each = 'TIMESERIES';
figext = '.gif';
filename_save = [pth_fitdata_prefix '_' title_add_each '_e_' epochinds_str_all '_' figext];

max_numrois_to_plot_fithist = 5;
if size(depvnan_cont, 1)>1
    max_numfits_to_plot_par = 0;
    max_numfits_to_plot_ts = 0;
else
    max_numfits_to_plot_par = 50;
    max_numfits_to_plot_ts = 50;
end

if size(depvnan_cont, 1)>max_numrois_to_plot_fithist
    rois_to_plot_fithist = round(linspace(1, size(depvnan_cont, 1), max_numrois_to_plot_fithist));
else
    rois_to_plot_fithist = 1:size(depvnan_cont, 1);
end

num_total_subplots = numrows_ts+supp.num_total_model_functions;

%axes
hfg = figure('Units', 'Normalized', 'Color', 'white', 'visible', gif_visibility) ;
hfg.Position = [0 0.2 0.8 0.6];
bgax = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', 'XLim', [0, 1], 'YLim', [0, 1] ) ;



ax = arrange_subplots({[numrows_ts, numcolumns_ts], [numrows_ts2, numcolumns_ts2]}, margins_subplot, margins_fig, splitdim, splitfrac);

%title string
htx = text( 0.02, 1-margins_fig/2, '', 'FontSize', fontsmall, 'HorizontalAlignment', 'left', 'FontWeight', 'bold' ) ;
tittmp = strsplit(filename_save(1:end-4), '/');
htx.String = strrep(tittmp{end}, '_', ' ');


%colormaps

num_indv_to_plot = supp.num_dim_indvpre;
if num_indv_to_plot>max_num_indv_to_plot
    num_indv_to_plot = max_num_indv_to_plot;
end

indv_base_color = [0 0 1];
cmap_indv = repmat(indv_base_color, [num_indv_to_plot 1]);
cmap_indv(:,2) = linspace(1, 0, num_indv_to_plot);
cmap_indv = flip(cmap_indv, 1);
color_depvp = [1 0 0 depvp_alpha];
color_depv = [0 0 0 depv_alpha];

%set whether to copy each frame with and without model response
if max_numfits_to_plot_ts == 0 %num_indv_to_plot==1 && num_indv_to_plot<2
    toggle_depvp_visibility = 0;
else
    toggle_depvp_visibility = 1;
end


%plotting loop

hax = cell(1, num_total_subplots);

framecount = 0;
for ri = 1:numroi_plot %for each unit

    for fhi = 1:size(depvprow{ri,1}, 1) + toggle_depvp_visibility  %for all fits (should be same for all rows so doing first of each roi with {ri, 1}

        if fhi==size(depvprow{ri,1}, 1)+1 %if there's an extra loop iteration, it's to turn off depvp for one frame, to show indv and depv alone, at the end
            plot_depvp = 0;
        else
            plot_depvp = 1;
        end

        framecount = framecount + 1;

        for nsi = 1:numrows_ts %for each subplot row

            if framecount==1 %if on the first frame

                sectorind = 1;
                hax{nsi} = axes( 'Parent', hfg, 'Position', [ax(sectorind).rowmajor.xp(nsi), ax(sectorind).rowmajor.yp(nsi), ax(sectorind).xe(1), ax(sectorind).ye(1)] ); %make the subplot
                hold(hax{nsi}, 'on')
                % yyaxis left
                hpl{nsi} = plot(hax{nsi}, depvrow{nsi}(ri,:), 'Color', color_depv, 'LineStyle', '-');
                hpl2{nsi} = plot(hax{nsi}, depvprow{ri,nsi}(fhi, :), 'Color', color_depvp, 'LineStyle', '-');
                hplp{nsi} = patch(hax{nsi}, shadex{nsi}, shadey{nsi}, shadec{nsi}, 'EdgeColor', 'none', 'FaceAlpha', epoch_patch_face_alpha);
                if plot_indv
                    % yyaxis right
                    for nip = 1:num_indv_to_plot
                        hpl3{nsi} = plot(hax{nsi}, indvrow{nsi}(:, nip), 'Color', cmap_indv(nip,:), 'LineStyle', '-');
                    end
                end
                hold(hax{nsi}, 'off')

                hax{nsi}.XLim = [1 length(depvrow{nsi}(ri,:))];
                hax{nsi}.XAxis.TickValues = [];
                hax{nsi}.XAxis.TickLabels = [];


                if nsi==numrows_ts %if on the final/bottom row, include axis ticks and labels

                    % xlm = hax{nsi}.XLim;
                    % hax{nsi}.XAxis.TickValues = linspace(xlm(1), xlm(2), 6);
                    % hax{nsi}.XAxis.TickLabelFormat = '%.1f';
                    % hax{nsi}.XAxis.FontSize = fontsmall;

                    hax{nsi}.YAxis(1).TickLabelFormat = '%.1f';
                    hax{nsi}.YAxis(1).FontSize = fontsmall;
                    % if plot_indv
                    %     hax{nsi}.YAxis(2).TickLabelFormat = '%.1f';
                    %     hax{nsi}.YAxis(2).FontSize = fontsmall;
                    % end

                else %if not on the final/bottom row, skip axis ticks and labels

                    hax{nsi}.XAxis.TickValues = [];
                    hax{nsi}.XAxis.TickLabels = [];
                    hax{nsi}.YAxis(1).TickLabels = [];
                    % if plot_indv
                    %     hax{nsi}.YAxis(2).TickLabels = [];
                    % end

                end

            else %if not on the first frame

                hpl{nsi}.YData = depvrow{nsi}(ri,:);
                if plot_depvp
                    hpl2{nsi}.YData =  depvprow{ri,nsi}(fhi, :);
                end

            end


            if fhi==size(depvprow{ri,1}, 1) % when showing final model, ylim is min/max all
                hax{nsi}.YAxis(1).Limits = [minis_all maxis_all];
            elseif fhi>size(depvprow{ri,1}, 1) % when not showing prediction, ylim is min/max depv (indv, if shown, has been rescaled to depv)
                hax{nsi}.YAxis(1).Limits = [minis_depv maxis_depv];
            elseif fhi<size(depvprow{ri,1}, 1) %if showing prediction fit history
                if ylim_track_pred %ylim is min/max fit
                    hax{nsi}.YAxis(1).Limits = [min(depvprow{ri,nsi}(fhi, :)) max(depvprow{ri,nsi}(fhi, :))];
                else %ylim is min/max depv
                    hax{nsi}.YAxis(1).Limits = [minis_depv maxis_depv];
                end
            end
            ylm = hax{nsi}.YAxis(1).Limits;
            hax{nsi}.YAxis(1).TickValues = linspace(ylm(1), ylm(2), 3);
            hax{nsi}.YAxis(1).Color = [0 0 0];
            % if plot_indv
            %     hax{nsi}.YAxis(2).Limits = [minis_indv maxis_indv];
            %     ylm = hax{nsi}.YAxis(2).Limits;
            %     hax{nsi}.YAxis(2).TickValues = linspace(ylm(1), ylm(2), 3);
            %     hax{nsi}.YAxis(2).Color = [0 0 1];
            % end

            if plot_depvp
                hpl2{nsi}.Color = color_depvp; %make depvp visible
            else
                hpl2{nsi}.Color = 'none'; %make depvp invisible
            end

        end

        supp.starting_hax = numrows_ts;
        if framecount==1
            sectorind = 2;
            for tffi = 1:supp.num_total_model_functions
                tffi2 = tffi + supp.starting_hax;
                hax{tffi2} = axes( 'Parent', hfg, 'Position', [ax(sectorind).rowmajor.xp(tffi), ax(sectorind).rowmajor.yp(tffi), ax(sectorind).xe(1), ax(sectorind).ye(1)] ); %make the subplot
            end
        end
        supp.framecount = framecount;
        if plot_depvp
            [~, hax, binmns] = mdl(histxsave{ri}(fhi,:), indv, supp, hax); %plot the model components
            hax{supp.starting_hax+1:end}.YLim = [0 1];
        end

        fig2gif(hfg, framecount, filename_save)


    end
end

