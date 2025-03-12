function plotvars = mdl_plots_prepvars(indv, depv, mdl, plt, roidat, epochs_oneset, ...
    fitdata, mdlname, nrmd, epochstr, pthpre)

hackindvdim = plt.hackindvdim;
numrows_ts = plt.numrows_ts; %how many rows you want to use to spread the timeseries out
max_numfits_to_plot_ts = plt.max_numfits_to_plot_ts;
max_numfits_to_plot_par = plt.max_numfits_to_plot_par;
use_best_global = plt.use_best_global;
numsampnan = plt.numsampnan;
include_best_fit = plt.include_best_fit;
cmap_patch = plt.cmap_patch;

%% organize and normalize model data into hsv map

%% plotting vars

epochstr = strrep(epochstr, '_', ',');
plt = plots_setup_hsv(plt, mdlname);

hsvmap = hsvcmp( plt, hueft=fitdata.ft, satft=fitdata.gof, valft=fitdata.depvstd, hueft2=fitdata.indvpf, huelimnat=mdl.st.indvp_lim_alldim, huelimnat2=mdl.st.depvp_lim_alldim, mdlname=mdlname);

%% select which rois get plotted and how they're sorted

switch plt.sort_method
    case 'unbiased' %equidistant plt.maxnumroiplot, or all if there are fewer than fitopt.maxnumroiplot
        sortinds = fliplr(1:mdl.num_dim_depvp);
        sortinds = 1:mdl.num_dim_depvp;
    case 'majoraxis' %equidistant plt.maxnumroiplot, or all if there are fewer than plt.maxnumroiplot
        % [~, sortinds] = sort(roidat.idx_vox2roi,  'descend');
        [~, sortinds] = sort(fitdata.indvpf,  'descend');
    case 'gof' %sort by gof (sdata), then equidistant plt.maxnumroiplot, descending order
        [~, sortinds] = sort(fitdata.gof, 'descend');
    case 'custom' %ad hoc sort method, checking for an error
        sortonetmp = find(abs(hsvmap(:,1))>2);
        sorttwotmp = setxor(1:length(hsvmap), sortonetmp);
        sortinds = [sortonetmp; sorttwotmp];
end

roiinds_plot = unique(sortinds(round(linspace(1, mdl.num_dim_depvp, plt.maxnumroiplot))), 'stable'); %unique lets this work when plt.maxnumroiplot>=mdl.num_dim_depvp
numroi_plot = numel(roiinds_plot);

roipx = roidat.roipx(roiinds_plot);
roiwt = roidat.roiwt(roiinds_plot);


%% subsample indv, depv, pred

indv = indv(:, fitdata.sampinds_indvpaug); %columns of indv and depv should be number samples, could change above or just transpose here
depv = depv(roiinds_plot, fitdata.sampinds_depvp); %columns of indv and depv should be number samples, could change above or just transpose here

fitdata.pred = fitdata.pred.';
if ~strcmp(nrmd, 'none')
    fitdata.pred = mdl.normmdlvar_depv(fitdata.pred, 'reverse');
    fitdata.pred = fitdata.pred(roiinds_plot, :); %columns of indv and depv should be number samples, could change above or just transpose here
end

minis_indv = min(indv(:)); %min depv across all epochs
maxis_indv = max(indv(:)); %min depv across all epochs
minis_depv = min(depv(:)); %min depv across all epochs
maxis_depv = max(depv(:)); %min depv across all epochs
minis_pred = min(fitdata.pred(:)); %min depv across all epochs
maxis_pred = max(fitdata.pred(:)); %min depv across all epochs
minis_all = min(minis_depv, minis_pred);
maxis_all = max(maxis_depv, maxis_pred);

%% pad timeseries discontinuities

plotvars = pad_timeseries_discontinuities(indv, depv, fitdata.pred, fitdata.epochinds_pure_ts_m, fitdata.sampinds_depvp, mdl.num_dim_indvp, numroi_plot, plt.max_tinds, plt.timeseries_numsegments, numsampnan);


%% per row variables to plot

[indvsort, indvsortidx] = sort(indv(hackindvdim,:));
pred_sort = fitdata.pred(:, indvsortidx);

contseg_per_row = ceil(numel(plotvars.tinds_cont_nan) / numrows_ts); %how many continuous segments per row

indvnan_cont_rescale = rescale(plotvars.indvnan_cont, minis_depv, maxis_depv);

% numroi_plot = size(tmpvars.depvnan_cont, 1);
predrow = cell(numroi_plot, numrows_ts);
pred_hist = cell(1, numroi_plot); %original full history, not split by row
histxsave = cell(1, numroi_plot); %original full history, not split by row

shadex = cell(1, numrows_ts);
shadey = cell(1, numrows_ts);
shadec = cell(1, numrows_ts);
depvrow = cell(1, numrows_ts);
indvrow = cell(1, numrows_ts);
if max_numfits_to_plot_ts>0
    for ri = 1:numroi_plot %for each unit, concatenate hitfit (do before plotting loop )
        pthvalsv_pattern = [pthpre '_' epochstr '_*_' num2str(ri) '_HISTFIT_.mat'];
        fitdata_saved_files = rdir(pthvalsv_pattern);
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
            %     plot_fit_history(histxtmp(:,keepinds_histfit_par), pthpre, epochstr_all) %this way you can plot entire history before subset with keepinds_histfit
            % end

            if size(histxtmp, 2)>max_numfits_to_plot_ts
                keepinds_histfit_ts = round(linspace(1, size(histxtmp, 2), max_numfits_to_plot_ts));
            else
                keepinds_histfit_ts = 1:size(histxtmp, 2);
            end

            numfits_to_plot = length(keepinds_histfit_ts);
            pred_hist{ri} = zeros(numfits_to_plot, size(indv, 1), 'single');
            histxsave{ri} = zeros(numfits_to_plot, size(histxtmp, 1));

            for hxi = 1:numfits_to_plot
                histxsave{ri}(hxi,:) = histxtmp(:,keepinds_histfit_ts(hxi))';
                pred_hist{ri}(hxi,:) = mdl(histxsave{ri}(hxi,:), indv, supp);
                % if nrmd
                %     pred_hist{ri}(hxi,:) = pred_hist{ri}(hxi,:).*depvinstds_plot{epi}(ri) + depvinmeans_plot{epi}(ri);
                % end
            end
            if nrmd
                pred_hist{ri} = revstandvar_depv(pred_hist{ri}.');
            end


        end
    end
end


for nsi = 1:numrows_ts %for each row (arbitrarily divided into rows for visualization)
    contseginds = [1:contseg_per_row]+contseg_per_row*(nsi-1); %indices of contiguous segments for row nsi
    contseginds(contseginds>length(plotvars.tinds_cont_nan)) = [];
    tinds_cont_row = cell2mat(plotvars.tinds_cont(contseginds));
    tinds_row = cell2mat(plotvars.tinds_cont_nan(contseginds));
    tinds_row_nonan = cell2mat(plotvars.tinds_cont_nan_nonan(contseginds));
    tinds_row_nonan = tinds_row_nonan-(min(tinds_row_nonan)-numsampnan)+1; %subtract to start each row after numsampnan
    count = 0;
    for epi2 = 1:length(epochs_oneset) %for each epoch within epochnum
        tmp = find(plotvars.pureepochnan_cont==epochs_oneset(epi2));
        tmp = tmp(tmp>=min(tinds_row) & tmp<=max(tinds_row));
        shadextmp = [0 find(diff(tmp)~=1) length(tmp)];
        for bei = 2:length(shadextmp) %for each pure epoch segment in a single row
            count = count + 1;
            x1 = tmp(shadextmp(bei-1)+1);
            x2 = tmp(shadextmp(bei));
            shadex{nsi}(:, count) = [x1; x2; x2; x1] - min(tinds_row) + 1; %subtract indices to shift on x axis for each row, since time is modified in this plot
            shadey{nsi}(:, count) = [minis_all; minis_all; maxis_all; maxis_all];
            shadec{nsi}(count, 1, :) = reshape(cmap_patch(epochs_oneset(epi2), :), [1 1 3]); %put color triplet in 3rd dim for patch arg c
        end
    end

    %subset to get one row, and also add nan to end for symmetry at same time
    depvrow{nsi} = cat(2, plotvars.depvnan_cont(:, tinds_row), plotvars.nanpad_depv);%add nan to end of each line for symmetry, since nan is at beginning of each line
    predrow_tmp = cat(2, plotvars.prednan_cont(:, tinds_row), plotvars.nanpad_depv);%add nan to end of each line for symmetry, since nan is at beginning of each line
    %indvrow{nsi} = cat(2, indvnan_cont(:, tinds_row), tmpvars.nanpad_indv);%add nan to end of each line for symmetry, since nan is at beginning of each line
    indvrow{nsi} = cat(2, indvnan_cont_rescale(:, tinds_row), plotvars.nanpad_indv);%add nan to end of each line for symmetry, since nan is at beginning of each line

    for ri = 1:numroi_plot
        if max_numfits_to_plot_ts>0
            predrow{ri,nsi} = nan(size(pred_hist{ri}, 1)+include_best_fit, size(depvrow{nsi}, 2)); %fit by time, plus optional one for final/best fit
            predrow{ri,nsi}(1:end-1,tinds_row_nonan) = pred_hist{ri}(:,tinds_cont_row); %history of fits
            % predrow{ri,nsi}(end,tinds_row_nonan) = pred_hist{ri}(end,tinds_cont_row); %best validation fit at end
            % predrow{ri,nsi}(end,:) = pred_hist{ri}(bestindall{ri},tinds_cont_row); %best validation fit at end
            predrow{ri,nsi}(end,:) = predrow_tmp(ri,:); %best fit at end
        else
            % predrow{ri,nsi} = pred_hist{ri}(end,tinds_cont_row); %best validation fit at end
            % predrow{ri,nsi} = pred_hist{ri}(bestindall{ri},tinds_cont_row); %best validation fit at end
            predrow{ri,nsi} = predrow_tmp(ri,:); %just the best fit
        end
    end

end
pred_hist = [];

for ri = 1:numel(roiinds_plot)
    if max_numfits_to_plot_ts>0
        histxsave{ri} = cat(1, histxsave{ri}, fitdata.ft(roiinds_plot(ri),:)); %cat the final model to history
    else
        histxsave{ri} = fitdata.ft(ri,:); %assign the final model as only
    end
end

minis_pa =  min(cell2mat(cellfun(@(x) min(x(:)),  predrow,  'UniformOutput',  false))); %min pred depv across all epochs
maxis_pa =  max(cell2mat(cellfun(@(x) max(x(:)),  predrow,  'UniformOutput',  false))); %max pred depv across all epochs


%% output struct



plotvars.minis_indv = minis_indv;
plotvars.maxis_indv = maxis_indv;
plotvars.minis_depv = minis_depv;
plotvars.maxis_depv = maxis_depv;
plotvars.minis_pred = minis_pred;
plotvars.maxis_pred = maxis_pred;
plotvars.minis_all = minis_all;
plotvars.maxis_all = maxis_all;
plotvars.minis_pa = minis_pa;
plotvars.maxis_pa = maxis_pa;

plotvars.sampinds_indvpaug = fitdata.sampinds_indvpaug;
plotvars.sampinds_depvp = fitdata.sampinds_depvp;
plotvars.numroi_plot = numroi_plot;
plotvars.roiinds_plot = roiinds_plot;
plotvars.roiwt = roiwt;
plotvars.roipx = roipx;
plotvars.pred_sort = pred_sort;
plotvars.indvsort = indvsort;

plotvars.histxsave = histxsave;

plotvars.indvrow = indvrow;
plotvars.depvrow = depvrow;
plotvars.predrow = predrow;

plotvars.shadex = shadex;
plotvars.shadey = shadey;
plotvars.shadec = shadec;

plotvars.hsvmap = hsvmap;


