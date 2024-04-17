function fitmdl_plots_timeseries


%% TIMESERIES PLOTS ONLY

%use *_cont rather than *_seg, since the timeseries only plot does not truncate for space


plot_indv = 1;
use_best_global = 1;
include_best_fit = 1;
num_total_possible_epochs = 6; %do it this way, rather than numel(unique(cell2mat(epochinds))), so same color is associated weith same epoch across different fits
max_num_indv_to_plot = 2;
num_depv_to_plot = 2; %this should always be 2 for depv and predddepv (unless you have multidimensional outpuut)
epoch_patch_face_alpha = 0.05;
ylim_track_pred = 0;
depv_alpha = 1;
depvp_alpha = 0.7;

numrows_ts = 6; %no functional significance, just how many rows you want to spread the timeseries out
numcolumns_ts = 1;
margins_fig = 0.04;
margins_subfig = 0.02;

title_add_each = 'TIMESERIES';
figext = '.gif';
filename_save = [pth_fitdata_prefix '_' title_add_each '_e_' epochinds_str_all '_' figext];

max_numrois_to_plot_fithist = 5;
if size(depvnan_cont{epi}, 1)>1
    max_numfits_to_plot_par = 0;
    max_numfits_to_plot_ts = 0;
else
    max_numfits_to_plot_par = 50;
    max_numfits_to_plot_ts = 50;
end

if size(depvnan_cont{epi}, 1)>max_numrois_to_plot_fithist
    rois_to_plot_fithist = round(linspace(1, size(depvnan_cont{epi}, 1), max_numrois_to_plot_fithist));
else
    rois_to_plot_fithist = 1:size(depvnan_cont{epi}, 1);
end

num_total_subplots = numrows_ts+supp.num_total_model_functions;

%axes
hfg = figure('Units', 'Normalized', 'Color', 'white', 'visible', gif_visibility) ;
hfg.Position = [0 0.2 0.8 0.6];
bgax = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', 'XLim', [0, 1], 'YLim', [0, 1] ) ;
[axx, axy, axw, axh] = arrange_subplots(numrows_ts, numcolumns_ts, margins_fig, margins_subfig);
leftfrac = 0.6;
axw = axw*leftfrac;

numrows_ts2 = supp.num_total_model_functions/supp.max_num_fun_per_unit; %no functional significance, just how many rows you want to spread the timeseries out, i like 4
numcolumns_ts2 = supp.max_num_fun_per_unit;
[axx2, axy2, axw2, axh2] = arrange_subplots(numrows_ts2, numcolumns_ts2, margins_fig, margins_subfig);

axw2 = axw2*(1-leftfrac)-margins_subfig;
for axxi = 1:numel(axx2)
    onecolumn_lefside_hack = 1;
    axx2(axxi) = axx(onecolumn_lefside_hack)+axw(onecolumn_lefside_hack)+axw2(axxi)*((ceil(axxi/numrows_ts2))-1)+margins_subfig;
    if axh2>axh(1)
        axh2(:) = axh(onecolumn_lefside_hack);
    end
end

axx = cat(1, axx, axx2);
axy = cat(1, axy, axy2);
axw = cat(1, axw, axw2);
axh = cat(1, axh, axh2);

%title string
htx = text( 0.02, 1-margins_fig/2, '', 'FontSize', fontsmall, 'HorizontalAlignment', 'left', 'FontWeight', 'bold' ) ;
tittmp = strsplit(filename_save(1:end-4), '/');
htx.String = strrep(tittmp{end}, '_', ' ');

%mins and maxes constant scale across gif
minis_indv =  min(cell2mat(cellfun(@(x) min(x(:)),  indv,  'UniformOutput',  false))); %min depv across all epochs
maxis_indv =  max(cell2mat(cellfun(@(x) max(x(:)),  indv,  'UniformOutput',  false))); %max depv across all epochs
minis_depv =  min(cell2mat(cellfun(@(x) min(x(:)),  depv,  'UniformOutput',  false))); %min depv across all epochs
maxis_depv =  max(cell2mat(cellfun(@(x) max(x(:)),  depv,  'UniformOutput',  false))); %max depv across all epochs
minis_depvp =  min(cell2mat(cellfun(@(x) min(x(:)),  depvp,  'UniformOutput',  false))); %min pred depv across all epochs
maxis_depvp =  max(cell2mat(cellfun(@(x) max(x(:)),  depvp,  'UniformOutput',  false))); %max pred depv across all epochs
minis_all = min(minis_depv, minis_depvp);
maxis_all = max(maxis_depv, maxis_depvp);

%colormaps

num_indv_to_plot = supp.num_dim_indvpre;
if num_indv_to_plot>max_num_indv_to_plot
    num_indv_to_plot = max_num_indv_to_plot;
end
cmap_patch = distinguishable_colors(num_total_possible_epochs+max_num_indv_to_plot+num_depv_to_plot);
cmap_patch = cmap_patch(max_num_indv_to_plot+num_depv_to_plot:end,:); %remove first four colors because they are b, r, g, and (almost) black, which are used for traces already
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

                hax{nsi} = axes( 'Parent', hfg, 'Position', [axx(nsi), axy(nsi), axw(nsi), axh(nsi)] ); %make the subplot
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
            for tffi = 1:supp.num_total_model_functions
                tffi2 = tffi + supp.starting_hax;
                hax{tffi2} = axes( 'Parent', hfg, 'Position', [axx(tffi2), axy(tffi2), axw(tffi2), axh(tffi2)] ); %make the subplot
            end
        end
        supp.framecount = framecount;
        if plot_depvp
            [~, hax, binmns] = mdl(histxsave{ri}(fhi,:), indv{epi}, supp, hax); %plot the model components
        end

        fig2gif(hfg, framecount, filename_save)


    end
end

