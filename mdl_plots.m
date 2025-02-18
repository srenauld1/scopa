
function mdl_plots(mdl, roidat, stack, opt, pthpre, pltstr)

arguments
    mdl
    roidat
    stack
    opt
    pthpre
    pltstr
end

"EVERYTHING IN mdl_plots AND its subfunctions NEED TO BE RE-WRITTEN; IT IS BEING UPDATED AND IS CURRENTLY A MESS"

%plots a square figure to make it easier to ensure native aspect ratios in subfigure
%it may not appear to be a square, but it is, as long as szf does not exceed
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



%% create pixelwise fit for background of hsv plot (if requested) by calling mdlmake here, with pixfit==1

if strcmp(fitopt.hsv_background, 'pixels') && pixfit==0 %only do if pixfit==0, to avoid infinite recursion
    pixfit = 1;
    roipixind2 = logical(sum(roidat.roipx)); %THESE ARE PIXEL INDICES FROM ALLROI MASK, NOT EACH ROI, ALL NOT SUPERSET OF EACH IF IF ANY ROIS ARE OVERLAPPING
    depv2 = reshape(stack, [], size(stack, 4));
    depv2 = depv2(cell2mat(roipixind2), :);
    mdl2.vars.depvp = depv2;
    roidat2 = roidat;
    roidat2.roipx = roipixind2;
    mdlmake(stack, mdl2, roidat2, sampper, fitopt, pixfit); %call mdlmake on pixels if you want a pixel fit background behind your roi fit background
    pixfit = 0; %reset to zero
end



opt.plt.maxnumroiplot = 70;

opt.plt.hackindvdim = 1;
opt.plt.numrows_ts = 6; %how many rows you want to use to spread the timeseries out
opt.plt.max_numfits_to_plot_ts = 0;
opt.plt.max_numfits_to_plot_par = 0;
opt.plt.use_best_global = 1;
opt.plt.numsampnan = 10;
opt.plt.include_best_fit = 1;


opt.plt.plot_indv = 1;
opt.plt.num_total_possible_epochs = 6; %do it this way, rather than numel(unique(cell2mat(epochnum))), so same color is associated weith same epoch across different fits
opt.plt.max_num_indv_to_plot = 2;
opt.plt.num_depv_to_plot = 2; %this should always be 2 for depv and predddepv (unless you have multidimensional outpuut)
opt.plt.epoch_patch_face_alpha = 0.05;
opt.plt.ylim_track_pred = 0;
opt.plt.depv_alpha = 1;
opt.plt.pred_alpha = 0.7;

opt.plt.numcolumns_ts = 1;
opt.plt.marginfg = 0.04;
opt.plt.marginax = 0.02;
opt.plt.splitdim = 'x';
opt.plt.splitfrac = 0.7;
opt.plt.fontsmall = 6;

opt.plt.numrows_ts2 = mdl.op.supp.num_total_model_functions/mdl.op.supp.max_num_fun_per_unit; 
opt.plt.numcolumns_ts2 = mdl.op.supp.max_num_fun_per_unit;

opt.plt.cmap_patch = distinguishable_colors(opt.plt.num_total_possible_epochs+opt.plt.max_num_indv_to_plot+opt.plt.num_depv_to_plot);
opt.plt.cmap_patch = opt.plt.cmap_patch(opt.plt.max_num_indv_to_plot+opt.plt.num_depv_to_plot:end,:); %remove first four colors because they are b, r, g, and (almost) black, which are used for traces already

plot_dimension_order = 'rev';

if strcmp(plot_dimension_order, 'rve') %set order of plot variables prior to model_plots_prepvars, to keep things readable, without saving lots of variables
    fprintf("plot dimension order is: roi, validation, epoch" + newline)
end


%% read / normalize indv and depv (keep seperate from plotvars in case they are large and epoch sets overlap)

indv = mdl_binld(mdl.pth_indvaug_bin);
if ~strcmp(opt.nrmi, 'none')
    indv = mdl.normmdlvar_indv(indv, 'reverse');
end

depv = mdl_binld(mdl.pth_depvp_bin);
if ~strcmp(opt.nrmd, 'none')
    depv = mdl.normmdlvar_depv(depv, 'reverse');
end

%% 


opt.plt.sort_method = 'majoraxis';

enm = fieldnames(mdl.fits);
enm = enm(startsWith(enm, 'e_'));
epochinds_str_all = strjoin(enm, ',,');
for ei = 1:numel(enm)
    vnm = fieldnames(mdl.fits.(enm{ei}));
    vnm = vnm(startsWith(vnm, 'v_'));
    for vi = 1:numel(vnm)
        plotvars.(enm{ei}).(vnm{vi}) = mdl_plots_prepvars(indv, depv, mdl, opt.plt, roidat, ...
            mdl.fits.(enm{ei}).epochnum, mdl.fits.(enm{ei}).(vnm{vi}), ...
            opt.mdlname, opt.nrmd, enm{ei}, pthpre);
    end
end


stackmnt = mean(stack, 4);
if strcmp(opt.plt.plot_class, 'epoch') & ~opt.plt.plot3d
    stackmnt = mean(stackmnt, 3);
end


% pltstr = {'sum', 'ts', 'fov', 'mdl', 'cmp'};


%THIS IS STUPID, DON'T LOOP OVER EPOCH/VALIDATION SETS; NEED TO BE ABLE TO MAKE IT INNER LOOP TOO 

hsv_filename = [pthpre 'hsvfov_.gif'];
opt.plt.fg = 'allrois';
opt.plt.ignoresat = 0;
opt.plt.ignoreval = 0;


for ei = 1:numel(enm)
    vnm = fieldnames(mdl.fits.(enm{ei}));
    vnm = vnm(startsWith(vnm, 'v_'));
    for vi = 1:numel(vnm)
        for fi = pltstr
            switch fi{1}
                case 'sum'
                    mdl_plots_summary(mdl, opt, roidat, stackmnt)
                case 'ts'
                    mdl_plots_timeseries(indv, depv, mdl.op.mdl, plotvars.(enm{ei}).(vnm{vi}), opt.plt, mdl.op.supp, pthpre, epochinds_str_all)
                case 'fov'
                    hsvplt(opt.plt, stackmnt, plotvars.(enm{ei}).(vnm{vi}).hsvmap, roidat.roipx, roidat.roiwt, hsv_filename);
                case 'mdl'
                    if isequal(mdlfcn, @fit_svd)
                        % plot_svd(ft{epi})
                    else
                        mdlfcn(mdl.fits.(enm{ei}).(vnm{vi}).ft, indv{epi}, supp, pthpre);
                    end
                case 'comp'
                    roivpix(depv_allrois{epi}, stack, roipx, pthpre) %make gif showing roi against each of its pixels
            end
        end
    end
end

close all
