
function model_plots(fitin, roiinfo, stack, opts, pth_fitdata_prefix)

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

plot_dimension_order = 'rev';
if strcmp(plot_dimension_order, 'rve') %set order of plot variables prior to model_plots_prepvars, to keep things readable, without saving lots of variables
    disp("plot dimension order is: roi, validation, epoch")
end

enm = fieldnames(fitin.fits);
for ei = 1:numel(enm)
    vnm = fieldnames(fitin.fits.(enm{ei}));
    for vi = 1:numel(vnm)
        [plotvars, do_read_indv, do_read_depv] = model_plots_prepvars(fitin, fitin.plt, roiinfo, fitin.fits.(enm{ei}).(vnm{vi}), opts.modeltype, opts.standardize_indv, opts.standardize_depv, do_read_indv, do_read_depv);
    end
end


stackmean = mean(stack, 4);
if strcmp(fitin.plt.plot_class, 'epoch') & ~fitin.plt.plot3d
    stackmean = mean(stackmean, 3);
end


frm.a.type = 'timeseries';
frm.b.type = 'fov';

fn = fieldnames(frm);
for fi = 1:numel(frm)
    switch frm.(fn{fi}).type
        case 'timeseries'
            model_plots_timeseries
        case 'fov'
            model_plots_fov
        case 'model'
            modfun
    end
end

%% various plots

if fitin.plt.doplots(1)
    model_plots_summary(fitin, opts, roiinfo, stackmean)
end

if doplots(1)
    model_plots_fov
end

if doplots(1)
    model_plots_timeseries
end

if doplots(4)
    if isequal(modfun, @fit_svd)
        % plot_svd(ft{epi})
    else
        modfun(ft{epi}, indv{epi}, supp, pth_fitdata_prefix);
    end
end

if doplots(5)
    compare_roi_with_pix(depv_all{epi}, stack, pixinds_roi, pth_fitdata_prefix) %make gif showing roi against each of its pixels
end

close all



