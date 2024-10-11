
function mfit_plots(fitin, roidat, stack, opts, pth_fitdata_prefix, pltstr)


"EVERYTHING IN mfit_plots AND its subfunctions NEED TO BE RE-WRITTEN; IT IS BEING UPDATED AND IS CURRENTLY A MESS"

%plots a square figure to make it easier to ensure native aspect ratios in subfigure
%it may not appear to be a square, but it is, as long as figsidelength does not exceed
%proportion of your screen's drawing area in its smaller dimension,
% which i've been unable to find programmatically so i recommend staying under 0.75

%top region is for FOV plots, which show each slice of the imaging top,
%either grayscale intensity, or hsv map of model fit params
%top plots can show pixels, or rois (multi-pixel regions)

% when the top aspect ratio is positive (larger
%width than height), as it usually is for our 2p imaging,
% it seems that top plots can be larger if the top plot region is at top, rather than at left
% so that is where they are plotted

%detail plots on individual rois/pixel are in the bottom section of the figure
%if there are multiple indv epochs, each row of the detail plots is a different epoch

%layout on bottom plots is constrained to make all y axes same length, and
%the unity plot square (same x and y axis length), then the fov plots fill
%the remaining space at top, at max size each without changing their aspect
%ratio (which is assumed constant, since they are slices from a single
%imaging movie)

%%plotting dimensions are:
% z slices in fov (can be all on one frame)
% indv dimensions in tuning curve (should be across frames, unless maybe if less than 5ish)
% model params as hsv in fov (can be all on one frame, esp if z slice is not)
% indv epochs in all plots (should be across frames since all plots, but can be all on one frame if z slice / model params are not)
% rois / pixels, in detail and crosshair (should be across frames)
% default should be all z slices on each frame, then across frames, in
% nested order from fastest to slowest changing: indv dim, model params, indv epochs, rois/pixels
% next priority is to make this nesting order variable with user input string
% next priority is changing from this general arrangement (e.g. something
% other than z slices be the param that appears all on one frame (first
% thought is indv epochs, since those are likely least numerous)
% define layout with "all_on_one_frame" string (zslice default), and
% "across_frame_nesting_order" with cell array of strings {indv dim, model
% params, indv epochs, rois/pixels}



opts.plt.maxnumroiplot = 70;

opts.plt.hackindvdim = 1;
opts.plt.numrows_ts = 6; %how many rows you want to use to spread the timeseries out
opts.plt.max_numfits_to_plot_ts = 0;
opts.plt.max_numfits_to_plot_par = 0;
opts.plt.use_best_global = 1;
opts.plt.numsampnan = 10;
opts.plt.include_best_fit = 1;


opts.plt.plot_indv = 1;
opts.plt.num_total_possible_epochs = 6; %do it this way, rather than numel(unique(cell2mat(epochinds))), so same color is associated weith same epoch across different fits
opts.plt.max_num_indv_to_plot = 2;
opts.plt.num_depv_to_plot = 2; %this should always be 2 for depv and predddepv (unless you have multidimensional outpuut)
opts.plt.epoch_patch_face_alpha = 0.05;
opts.plt.ylim_track_pred = 0;
opts.plt.depv_alpha = 1;
opts.plt.pred_alpha = 0.7;

opts.plt.numcolumns_ts = 1;
opts.plt.margins_fig = 0.04;
opts.plt.margins_subplot = 0.02;
opts.plt.splitdim = 'x';
opts.plt.splitfrac = 0.7;
opts.plt.fontsmall = 6;

opts.plt.numrows_ts2 = fitin.opop.supp.num_total_model_functions/fitin.opop.supp.max_num_fun_per_unit; 
opts.plt.numcolumns_ts2 = fitin.opop.supp.max_num_fun_per_unit;

opts.plt.cmap_patch = distinguishable_colors(opts.plt.num_total_possible_epochs+opts.plt.max_num_indv_to_plot+opts.plt.num_depv_to_plot);
opts.plt.cmap_patch = opts.plt.cmap_patch(opts.plt.max_num_indv_to_plot+opts.plt.num_depv_to_plot:end,:); %remove first four colors because they are b, r, g, and (almost) black, which are used for traces already


plot_dimension_order = 'rev';
if strcmp(plot_dimension_order, 'rve') %set order of plot variables prior to model_plots_prepvars, to keep things readable, without saving lots of variables
    disp("plot dimension order is: roi, validation, epoch")
end


%% read / normalize indv and depv (keep seperate from plotvars in case they are large and epoch sets overlap)

indv = read_mdl_var(fitin.pth_indvaug_bin);
if ~strcmp(opts.normalize_indv, 'none')
    indv = fitin.normmdlvar_indv(indv, 'reverse');
end

depv = read_mdl_var(fitin.pth_depvp_bin);
if ~strcmp(opts.normalize_depv, 'none')
    depv = fitin.normmdlvar_depv(depv, 'reverse');
end

%% 


opts.plt.sort_method = 'majoraxis';

enm = fieldnames(fitin.fits);
enm = enm(startsWith(enm, 'e_'));
epochinds_str_all = strjoin(enm, ',,');
for ei = 1:numel(enm)
    vnm = fieldnames(fitin.fits.(enm{ei}));
    vnm = vnm(startsWith(vnm, 'v_'));
    for vi = 1:numel(vnm)
        plotvars.(enm{ei}).(vnm{vi}) = mfit_plots_prepvars(indv, depv, fitin, opts.plt, roidat, ...
            fitin.fits.(enm{ei}).epochinds, fitin.fits.(enm{ei}).(vnm{vi}), ...
            opts.mdlname, opts.normalize_depv, enm{ei}, pth_fitdata_prefix);
    end
end


stackmnt = mean(stack, 4);
if strcmp(opts.plt.plot_class, 'epoch') & ~opts.plt.plot3d
    stackmnt = mean(stackmnt, 3);
end


% pltstr = {'sum', 'ts', 'fov', 'mdl', 'cmp'};


%THIS IS STUPID, DON'T LOOP OVER EPOCH/VALIDATION SETS; NEED TO BE ABLE TO MAKE IT INNER LOOP TOO 

hsv_filename = [pth_fitdata_prefix 'hsvfov_.gif'];
opts.plt.fg = 'allrois';
opts.plt.ignoresat = 0;
opts.plt.ignoreval = 0;


for ei = 1:numel(enm)
    vnm = fieldnames(fitin.fits.(enm{ei}));
    vnm = vnm(startsWith(vnm, 'v_'));
    for vi = 1:numel(vnm)
        for fi = pltstr
            switch fi{1}
                case 'sum'
                    mfit_plots_summary(fitin, opts, roidat, stackmnt)
                case 'ts'
                    mfit_plots_timeseries(indv, depv, fitin.opop.mdl, plotvars.(enm{ei}).(vnm{vi}), opts.plt, fitin.opop.supp, pth_fitdata_prefix, epochinds_str_all)
                case 'fov'
                    hsvplt(opts.plt, stackmnt, plotvars.(enm{ei}).(vnm{vi}).hsvmap, roidat.roipx, roidat.roiwt, hsv_filename);
                case 'mdl'
                    if isequal(mdlfcn, @fit_svd)
                        % plot_svd(ft{epi})
                    else
                        mdlfcn(fitin.fits.(enm{ei}).(vnm{vi}).ft, indv{epi}, supp, pth_fitdata_prefix);
                    end
                case 'comp'
                    roivpix(depv_allrois{epi}, stack, roipx, pth_fitdata_prefix) %make gif showing roi against each of its pixels
            end
        end
    end
end

close all
