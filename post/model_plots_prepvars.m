function [plotvars, do_read_indv, do_read_depv] = ...
    model_plots_prepvars(fitin, plt, roiinfo, fitdata, modeltype, standardize_indv, standardize_depv, do_read_indv, do_read_depv)

%% organize and normalize model data into hsv map

fitdata.hsvmap = compute_hsv( fitdata.ft, fitdata.gof, fitdata.indvpref, fitdata.depvstd, plt, modeltype, fitin.stats);


%% select which rois get plotted and how they're sorted

switch plt.sort_method
    case 'unbiased' %equidistant plt.maxnumroiplot, or all if there are fewer than fitopt.maxnumroiplot
        sortinds = fliplr(1:fitin.num_dim_depvpre);
        sortinds = 1:fitin.num_dim_depvpre;
    case 'majoraxis' %equidistant plt.maxnumroiplot, or all if there are fewer than plt.maxnumroiplot
        [~, sortinds] = sort(roiinfo.mapind2ind,  'descend');
    case 'gof' %sort by gof (sdata), then equidistant plt.maxnumroiplot, descending order
        [~, sortinds] = sort(fitdata.gof, 'descend');
    case 'custom' %ad hoc sort method, checking for an error
        sortonetmp = find(abs(plt.hsvmap(:,1))>2);
        sorttwotmp = setxor(1:length(plt.hsvmap), sortonetmp);
        sortinds = [sortonetmp; sorttwotmp];
end

roiinds_plot = unique(sortinds(round(linspace(1, fitin.num_dim_depvpre, plt.maxnumroiplot)))); %unique lets this work when plt.maxnumroiplot>=fitin.num_dim_depvpre


%% read full indv and depv from bin, then subsample

if do_read_indv
    indv = read_mdl_var(fitin.pth_indvaug_bin);
    indv = indv(:, fitdata.sampinds_indvpreaug).'; %columns of indv and depv should be number samples, could change above or just transpose here
    if standardize_indv
        indv = fitin.standmdlvar_indv(indv, 'reverse');
    end
    do_read_indv = 0;
end
if do_read_depv
    depv_allrois = read_mdl_var(fitin.pth_depvpre_bin);
    depv_allrois = depv_allrois(roiinds_plot, fitdata.sampinds_depvpre).'; %columns of indv and depv should be number samples, could change above or just transpose here
    if standardize_depv
        depv_allrois = fitin.standmdlvar_indv(depv_allrois, 'reverse');
        fitdata.depvp = fitin.standmdlvar_indv(fitdata.depvp, 'reverse');
    end
    do_read_depv = 0;
end
if standardize_depv
    plotvars.depvp = fitdata.depvp(:, roiinds_plot);
end
plotvars.pixinds_roi = roiinfo.pixinds_roi(roiinds_plot);

%% pad timeseries discontinuities

pad_timeseries_discontinuities

%% per row variables to plot




contseg_per_row = ceil(length(tinds_cont_nan) / numrows_ts); %how many continuous segments per row


indvnan_cont_rescale = rescale(indvnan_cont{epi}, minis_depv, maxis_depv);

numroi_plot = size(depvnan_cont{epi}, 1);
depvprow = cell(numroi_plot, numrows_ts);
depvp_hist = cell(1, numroi_plot); %original full history, not split by row
histxsave = cell(1, numroi_plot); %original full history, not split by row

shadex = cell(1, numrows_ts);
shadey = cell(1, numrows_ts);
shadec = cell(1, numrows_ts);
depvrow = cell(1, numrows_ts);
indvrow = cell(1, numrows_ts);


if max_numfits_to_plot_ts>0
    for ri = 1:numroi_plot %for each neuron, concatenate hitfit (do before plotting loop )
        pth_fitdata_epoch_pattern = [pth_fitdata_prefix '_' epochinds_str{epi} '_*_' num2str(ri) '_HISTFIT_.mat'];
        fitdata_saved_files = rdir(pth_fitdata_epoch_pattern);
        if ~isempty(fitdata_saved_files)
            fitdata_saved_files = natsortfiles(fitdata_saved_files);
            load(fitdata_saved_files(end).name, 'histfit') %load most recent, based on timestamp in filename
            % histfit_all(ri) = hxistfit;
            if use_best_global
                [~,globalkeepinds] = min(histfit.fval_g);
            else
                globalkeepinds = 1:size(histfit.x_l, 3);
            end
            histxtmp = reshape(histfit.x_l(:,:,globalkeepinds), size(histfit.x_l,1), []);
            histxtmp = histxtmp(:,~all(histxtmp==0));

            if size(histxtmp, 2)>max_numfits_to_plot_par %can shorten these bc too many on x axis is hard to read
                keepinds_histfit_par = round(linspace(1, size(histxtmp, 2), max_numfits_to_plot_par));
            else
                keepinds_histfit_par = 1:size(histxtmp, 2);
            end

            % if ismember(ri, rois_to_plot_fithist)
            %     plot_fit_history(histxtmp(:,keepinds_histfit_par), pth_fitdata_prefix, epochinds_str_all) %this way you can plot entire history before subset with keepinds_histfit
            % end

            if size(histxtmp, 2)>max_numfits_to_plot_ts
                keepinds_histfit_ts = round(linspace(1, size(histxtmp, 2), max_numfits_to_plot_ts));
            else
                keepinds_histfit_ts = 1:size(histxtmp, 2);
            end

            numfits_to_plot = length(keepinds_histfit_ts);
            depvp_hist{ri} = zeros(numfits_to_plot, size(indv{epi}, 1), 'single');
            histxsave{ri} = zeros(numfits_to_plot, size(histxtmp, 1));

            for hxi = 1:numfits_to_plot
                histxsave{ri}(hxi,:) = histxtmp(:,keepinds_histfit_ts(hxi))';
                depvp_hist{ri}(hxi,:) = mdlfcn(histxsave{ri}(hxi,:), indv{epi}, supp);
                % if standardize_depv
                %     depvp_hist{ri}(hxi,:) = depvp_hist{ri}(hxi,:).*depvinstds_plot{epi}(ri) + depvinmeans_plot{epi}(ri);
                % end
            end
            if standardize_depv
                depvp_hist{ri} = revstandvar_depv(depvp_hist{ri}.');
            end


        end
    end
end


for nsi = 1:numrows_ts %for each row (arbitrarily divided into rows for visualization)
    contseginds = [1:contseg_per_row]+contseg_per_row*(nsi-1); %indices of contiguous segments for row nsi
    contseginds(contseginds>length(tinds_cont_nan)) = [];
    tinds_cont_row = cell2mat(tinds_cont(contseginds));
    tinds_row = cell2mat(tinds_cont_nan(contseginds));
    tinds_row_nonan = cell2mat(tinds_cont_nan_nonan(contseginds));
    tinds_row_nonan = tinds_row_nonan-(min(tinds_row_nonan)-numsampnan)+1; %subtract to start each row after numsampnan
    count = 0;
    for epi2 = 1:length(epochinds{epi}) %for each epoch within epochinds
        tmp = find(pureepochnan_cont{epi}==epochinds{epi}(epi2));
        tmp = tmp(tmp>=min(tinds_row) & tmp<=max(tinds_row));
        shadextmp = [0 find(diff(tmp)~=1) length(tmp)];
        for bei = 2:length(shadextmp) %for each pure epoch segment in a single row
            count = count + 1;
            x1 = tmp(shadextmp(bei-1)+1);
            x2 = tmp(shadextmp(bei));
            shadex{nsi}(:, count) = [x1; x2; x2; x1] - min(tinds_row) + 1; %subtract indices to shift on x axis for each row, since time is modified in this plot
            shadey{nsi}(:, count) = [minis_all; minis_all; maxis_all; maxis_all];
            shadec{nsi}(count, 1, :) = reshape(cmap_patch(epochinds{epi}(epi2), :), [1 1 3]); %put color triplet in 3rd dim for patch arg c
        end
    end

    %subset to get one row, and also add nan to end for symmetry at same time
    depvrow{nsi} = cat(2, depvnan_cont{epi}(:, tinds_row), nanpad_depv);%add nan to end of each line for symmetry, since nan is at beginning of each line
    depvprow_tmp = cat(2, depvpnan_cont{epi}(:, tinds_row), nanpad_depv);%add nan to end of each line for symmetry, since nan is at beginning of each line
    % indvrow{nsi} = cat(1, indvnan_cont{epi}(tinds_row, :), nanpad_indv);%add nan to end of each line for symmetry, since nan is at beginning of each line
    indvrow{nsi} = cat(1, indvnan_cont_rescale(tinds_row, :), nanpad_indv);%add nan to end of each line for symmetry, since nan is at beginning of each line

    for ri = 1:numroi_plot
        if max_numfits_to_plot_ts>0
            depvprow{ri,nsi} = nan(size(depvp_hist{ri}, 1)+include_best_fit, size(depvrow{nsi}, 2)); %fit by time, plus optional one for final/best fit
            depvprow{ri,nsi}(1:end-1,tinds_row_nonan) = depvp_hist{ri}(:,tinds_cont_row); %history of fits
            % depvprow{ri,nsi}(end,tinds_row_nonan) = depvp_hist{ri}(end,tinds_cont_row); %best validation fit at end
            % depvprow{ri,nsi}(end,:) = depvp_hist{ri}(bestindall{ri},tinds_cont_row); %best validation fit at end
            depvprow{ri,nsi}(end,:) = depvprow_tmp(ri,:); %best fit at end
        else
            % depvprow{ri,nsi} = depvp_hist{ri}(end,tinds_cont_row); %best validation fit at end
            % depvprow{ri,nsi} = depvp_hist{ri}(bestindall{ri},tinds_cont_row); %best validation fit at end
            depvprow{ri,nsi} = depvprow_tmp(ri,:); %just the best fit
        end
    end

end
depvp_hist = [];

for ri = 1:numroi_plot
    if max_numfits_to_plot_ts>0
        histxsave{ri} = cat(1, histxsave{ri}, ft{epi}(ri,:)); %cat the final model to history
    else
        histxsave{ri} = ft{epi}(ri,:); %assign the final model as only
    end
end

minis_pa =  min(cell2mat(cellfun(@(x) min(x(:)),  depvprow,  'UniformOutput',  false))); %min pred depv across all epochs
maxis_pa =  max(cell2mat(cellfun(@(x) max(x(:)),  depvprow,  'UniformOutput',  false))); %max pred depv across all epochs
% minis_all = min(minis_all, minis_pa);
% maxis_all = max(maxis_all, maxis_pa);


%% output struct

fitdata.roiinds_plot = roiinds_plot;
