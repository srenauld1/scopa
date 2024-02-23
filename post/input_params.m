function opt = input_params()

% struct 'opt' holds all input params 
% substructures are (mostly) used within single functions called from analysis2p
% substructure 'main' is (mostly) used in analysis2p directly 


%params for main pipeline control in file analysis2
opt.main.parent_folder = 'stacks'; %folder containing all recording folders (on local or o2)
opt.main.recdate = '20230627';
opt.main.fly = '*';
opt.main.trial = '*';
opt.main.suffix_analysis = 'cmrg_dcdn';
opt.main.regionex_all = {'gar', 'gal', 'no_r', 'no_l', 'pb'}; %USE UNDERSCORE_SUFFIX TO create new regionex for this matlab part of the pipeline, based on the prefix regionex from the python preprocessing part of the pipeline


opt.main.do_cropping_session = 0; %skip everything except drawing 2d rois
opt.main.skip_existing = 0; %skip analysis if savefile exists for a given regionex
opt.main.old_project = 0; %for carl


%params for making morphological rois (manual or automated)
opt.mroi.use_hires = {'pb'}; %empty string to skip, cell array of regionex you want to use_hires for, uses hi-z-res stack to make morph mask
opt.mroi.use_drawn_rois =  {'gar', 'gal', 'no_r', 'no_l', 'pb'}; %empty string to skip, cell array of regionex you want to use_drawn_rois for
opt.mroi.numroi_morph_auto = {'gar-0', 'no_r-1', 'no_l-1', 'pb-32'}; %how many morph rois get automatically defined across the entire region (not hemisphere), cell array of string 'regionex-integer', 'regionex-0', or empty string will skip, or nothing for an existing regionex
opt.mroi.doplots = 1;


%params for making gif of raw data movies in function vis_tif
opt.vistif.suffixes_plot = {
    % 'cmrg', ...%comment if you don't want to plot (can comment all too)
    %'raw', ... %comment if you don't want to plot (can comment all too)
    %'cmrg_dcdn', ... %comment if you don't want toa plot (can comment all too)
    }; %anything missing will be skipped, will be reordered from least to most processed (by suffix length)
opt.vistif.plotinds_t = [10.2]; %t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
opt.vistif.plotinds_z = [2, 3]; %z indices to plot, empty for all, negative for that number equidistant from all available
opt.vistif.swapdim = 1; %true will flip z and t for plotting to change perspective on registration, recommended for length(plotinds_z)>1
opt.vistif.nan_numlines = 4; %how many lines of nans to insert in dim 1 above each subplot
opt.vistif.rescale_each_subplot = 1; %rescale each subplot to same range 0-1 before combining
opt.vistif.rescalefac_wholeplot = [0 1]; %combined ploto rescale arguments, [lower, upper]
opt.vistif.smooth_window_temporal = 0; %smooth the stack in time, 0 to skip
opt.vistif.plot_stack_stats = 0; %function this uses is old and needs to be updated
opt.vistif.ncolgif = 128; %color/grey res

%params for loading/selecting/viewing functional rois (applied in load_functional_rois)
opt.froi.caiman_lr_str = '2_1_0.9_*_*_*_*_1000_*_*_graph_2dex'; %caiman param string, can use wildcards, empty to skip
opt.froi.min_pixels_per_region = 3; %min pix in each distongiguous region, roi selection criterion
opt.froi.min_roi_size = 5;%pixels, roi selection criterion
opt.froi.max_roi_size = 300; %pixels
opt.froi.max_regions_per_roi = 4; %for discontiguous rois
opt.froi.within_mask_threshold = 0.5; %trash roi if more than within_mask_threshold is outside morphological mask (morph mask is all ones if you don't make one)
opt.froi.numbins = 20; %num hist bins for rval and snr caiman output
opt.froi.sort_roi_method = 'majoraxis'; %'snr' sorts by caiman output rsnr, 'none' doens't sort, 'majoraxis' if morphological rois exist, 'majoraxis' will sort along 3d major axis
opt.froi.foreground_plot_style = 'overlay'; %'boundary'; %options to show roi are 'boundary' and 'overlay'
opt.froi.numrois_for_gif = 10; %how many roi to put in gif, empty for all, 0 to skip gif
opt.froi.do_other_plots = 1; %do the other plots
opt.froi.saturation_factor_background = 0.4; %for gif, above this fraction of data is sent to max
opt.froi.saturation_factor_rois = 0.1; %for gif above this fraction of data is sent to max


%params for response extraction/normalization
opt.norm.normalize_before_roi_clustering = 0; %if rois are clustered into larger rois (e.g. functional/caiman rois clustered by morphoplogical roi) 
opt.norm.normalize_after_roi_clustering = 1; %if rois are clustered into larger rois (e.g. functional/caiman rois clustered by morphoplogical roi) 
opt.norm.f0_pct = 15; %percentile defining baseline fluorescence in dff computation applied to morphological rois (whether pixels, morph rois, or morph clustered functional/caiman rois)
opt.norm.response_normalization_string = {... %different normalization methods, default is no normalization, which is given string 'null'
    'rescale0100', ...
    % 'rescale595', ...
    % 'zscore', ...
    % 'nonnegative', ...
    % 'dffzscore', ...
    % 'dff595'...
    % 'boxcox'...
    };
opt.norm.doplots = 0;


%params for stimulus/fictrac processing
opt.ft.include_behavior = 1; %0 to skip behavior
opt.ft.no_stim_epochs = 0; %set to 1 if you have multiple epochs within a trial, epochs defined in load_fictrac or load_stim 
opt.ft.num_panel_frames = 192; %don't include extra dark frame . . . panel frames are zero indexed so 192 is 193rd increment of circle, and 193 is 194th unique frame denoting darkness
opt.ft.dark_stim_end_duration = 60; %final seconds
opt.ft.smoothwindow_sec = 0.2; %full width of gaussian smoothing window (5 times std)
opt.ft.slopeorder = 2; %order of polynomial used to fit local slope
opt.ft.slopelen = 5; %window length used to fit slope
opt.ft.doplots = 0;

%params for bump in compute_bump function
opt.bump.regionpat = {'pb'};
opt.bump.expat = {'moex*'};
opt.bump.normpat = {'in_rawf_pc_f_cl_rsc_w_*'};
opt.bump.bump_method = 'pva'; %'pva' for vector average, 'vonmises' for fitting von mises per timepoint doesn't exist yet 
opt.bump.domain_method = 'functional'; %'functional' to define circular domain with fit to each roi, or 'morphological' to define as circle across region mask
opt.bump.bump_subdomain = 'all'; %'all', 'right', 'left', 'larger', 'weighted', 'random'
opt.bump.slopeorder = 2; %order of polynomial used to fit local slope (e.g. to compute bump speed)
opt.bump.slopelen = 5; %order of polynomial used to fit local slope (e.g. to compute bump speed)
opt.bump.smoothwindow_sec = 0.2; %full width of gaussian smoothing window (5 times std)
opt.bump.numcluster_for_bump_domain_resample = {'pb-16'}; %how many centroids/glomeruli across the entire region (not hemisphere) when resampled uniformly, cell array of string 'regionex-integer', 'regionex-0', or empty string will skip, or nothing for an existing regionex, region must be in opt.bump.regionpat to get used 
opt.bump.rescale_clusters = 1; %just before computing bump, rescale each cluster's timeseries to range 0-1
opt.bump.doplots = 1;


%params for modeling responses in fitresp function
opt.fit.regionpat_fit = {'no_r'};
opt.fit.expat_fit = {'mo*'};
opt.fit.normpat_fit = {'in_rawf_pc_f_cl_f_w_no'};

opt.fit.sdom.no_r = {{'ball', 'vel_r_sm_rsmp'}, {'bump', 'mu'}};
opt.fit.sdom.no_l = {{'ball', 'vel_r_sm_rsmp'}, {'bump', 'mu'}};
opt.fit.sdom.pb = {'vis', 'ang_sm_rsmp'};
opt.fit.sdom.fullfov = {'vis', 'raw'};

opt.fit.hsv_background = 'rois'; %'rois' or 'pixels' or 'raw';
opt.fit.synthesize_resp = 0;
opt.fit.epochinds = {[4]};
opt.fit.num_samp_lag = 1; %how many samples stim precedes resp for model fit . . . for now, only nonnegative integers (0 to lenfit_samp - 1)
opt.fit.length_model_seconds = 2; %seconds, 0 is one sample

opt.fit.slvrg = 'globalsearch';
opt.fit.slvrl = 'fmincon'; %'lsqcurvefit';
opt.fit.modeltype = 'glno'; %'svd'; %'gaussian', 'vonmises' 'log' 'linear' 'nonadaptive'
opt.fit.huestr = 'loc'; %loc or amp for modeltype linear . . . loc, amp, or wid for modeltype vonmises or gaussian
opt.fit.lnth = 25; %for modeltype svd
opt.fit.pvar = 0.8; %for modeltype svd

opt.fit.huenorm = 'native'; %hue normalization method, see model_setup
opt.fit.satnorm = 'relative'; %sat normalization method, see model_setup
opt.fit.valnorm = 'relative';%val normalization method, see model_setup
opt.fit.hrange_in_manual = []; %manual range for normalizing hue, prior to normalization to plot scale, whose max range is [0 1]), see form_hsv
opt.fit.srange_in_manual = []; %manual range for normalizing sat, prior to normalization to plot scale, whose max range is [0 1]), see form_hsv
opt.fit.vrange_in_manual = []; %manual range for normalizing val, prior to normalization to plot scale, whose max range is [0 1]), see form_hsv
opt.fit.hrange_out_manual = [0.25 1]; %hue plot scale, whose max range is [0 1] hue hange around color circle, defaults to less than full circle for non-periodic plotting domain, but overwrites in model_setup to [0 1] when plotting periodic param (e.g. von mises center, ie modeltype 'vonmises' huestr 'loc'), see form_hsv
opt.fit.srange_out_manual = [0 1]; %sat plot scale, whose max range is [0 1], if you want to force saturation you can reduce (e.g. [0 0.75] will force smaller range to max saturation, see form_hsv
opt.fit.vrange_out_manual = [0 1];  %val plot scale, whose max range is [0 1], if you want to force value you can reduce (e.g. [0 0.75] will force smaller range to max value, see form_hsv
opt.fit.hueshift = 0; % 0-1, circularly shift the hue map around the color circle for change to arbitrary color assignment, applied before any clipping due to, see form_hsv
opt.fit.ignorehue = 0; %1 ignores it, makes constant 1
opt.fit.ignoresat = 1; %1 ignores it, makes constant 1
opt.fit.ignoreval = 1; %1 ignores it, makes constant 1

opt.fit.responseplot_norm = 'each'; %amplotude normalization for the detail plots at bottom, 'all' normalizes to population, 'each' normalizes to each
opt.fit.maxnumroiplot = 100; %number of rois that get detail view on the bottom, one per gif frame
opt.fit.sort_method = 'unbiased'; %'majoraxis', 'unbiased', 'gof', 'custom'; %how to select rois for detail plots, 'unbiased' for equidistant maxnumroiplot, 'gof' for equidistant maxnumroiplot sorted by gof in descending order (so starts with best fit ends with worst)

opt.fit.standardize_stim = 0;
opt.fit.standardize_resp = 1; %1 makes each response mean=0 variance=1 for fitting model (but still uses original scale for plotting), this is useful for comparing gof (if gof is default of mse, at least) of models fit to responses whose amplitudes differ
opt.fit.smoothresp = 0; %gaussian window std is one fifth total length

opt.fit.gif_visibility = 'on'; %on shows gif while plotting/writing/saving, off saves/writes but doesn't show it
opt.fit.max_tinds = 1000; %1000; %for the timeseries view of responses, how many samples to plot at the most (will take indices 1:max_tinds), big number to plot all
opt.fit.timeseries_numsegments = 3; %how many equispaced segments to display in setail view, ending at final frame

opt.fit.plot_class = 'hsv'; %hsv only shows one epoch per plot/gif frame, epoch shows multiple epochs but no hsv map
opt.fit.excludeopts = '';

opt.fit.plot3d = 0;
opt.fit.doplots = 1;
opt.fit.use_saved_model = 1;
opt.fit.timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS')) ;


% params for scatterplots
opt.scatter.epochinds = {[1 2 3 4 5]; [1 4]; [2 3]; [1]; [2]; [3]; [4]; [5]};


%params for hires stack (high z resolution version of main stack) . . . this code is a little deprecated
opt.hires.use_caiman_on_hires = [0, 0, 0, 0, 0]; %keep at 0 bc pipeline is poorly written for this option (also doens't seem to help)
opt.hires.caiman_hr_str = '*'; %empty to skip



%params to be added to metadata struct that was created in python preprocessing 
opt.md.croptimeinds = [0 0]; %this is only relevant for carl's old project



%overwrite some params for carl's old project
if strcmp(opt.main.recdate(1:2), '22') %override some settings for old project
    opt.main.old_project = 1;
    opt.main.no_stim_epochs = 1;
    opt.md.croptimeinds = [4 2]; %same as cropdata in rec6 (also applied in metrics2 without variable name cropdata), crop first 4 and last 2 imaging frames (stimulus features, and deprecated responses, have been extracted with this cropping in rec6)
    opt.fit.epochinds = {[1]};
    opt.fit.num_samp_lag = 1; %how many samples stim precedes resp for model fit . . . for now, only nonnegative integers (0 to lenfit_samp - 1)
    opt.fit.length_model_seconds = 1.25;
end

fn = fieldnames(opt);
for fni = 1:length(fn)
    opt.(fn{fni}) = orderfields(opt.(fn{fni}));
end
