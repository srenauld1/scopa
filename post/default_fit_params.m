function parsout = default_fit_params(parsin)

do = 1;

depvpre_str = {...
    ['resp, *, *, *'], ...
    };
indvpre_str = {...
    {['resp, *, *, *']}...
    };
depv_indv_combine = 'any'; %any or each
ignore_missing_vars = 0;

num_synthetic_depv = 0; %create synthetic data (using requested mdlname params, within any requested bounds) for testing fit; this is number of synthetic responses to fit; 0 to skip
epochinds = {[4]};
mdl_lag_sec = 0; %0 is one sample, how many samples indv precedes depv for model fit . . . for now, must be nonnegative integers, range 0 to lenfit_samp-1
mdl_length_sec = 2; %seconds, 0 is one sample

keep_transition_zones = 0; %1 to keep multi-timepoint model samples that have multiple epochs

validation_fold = 6; %applied to all mdlnames; k in k-fold cross-validation; k non-overlapping validation sets; if numbouts of each epoch in epochinds is divisible by validation_fold, will validate on numbouts/validation_fold bouts for each epoch in epochinds; if only one bout for each epoch, will evenly split each bout into k validation sets; otherwise will error; 0 skips validation
validation_split_style = 'boutsamples'; %'samples' or 'bouts' or 'boutsamples' %applied to all mdlnames; k in k-fold cross-validation; k non-overlapping validation sets; if numbouts of each epoch in epochinds is divisible by validation_fold, will validate on numbouts/validation_fold bouts for each epoch in epochinds; if only one bout for each epoch, will evenly split each bout into k validation sets; otherwise will error; 0 skips validation

slvrg = 'globalsearch';
slvrl = 'fmincon'; %'lsqcurvefit';
mdlname = 'fnet_A01_sh16'; %'svd' or fnet string (see notes_mdlname.m)

excludeopts = '';

normalize_indv = 'minmaxcnt'; %'minmax' range [0,1], 'minmaxcnt' range [-1,1], 'zscore' mean 0 unit var, 'none' . . . normalization used in fitting model but not all plotting . . . don't forget mse sensitive to scale 
normalize_depv = 'minmaxcnt'; %'minmax' range [0,1], 'minmaxcnt' range [-1,1], 'zscore' mean 0 unit var, 'none' . . . normalization used in fitting model but not all plotting . . . don't forget mse sensitive to scale 
smoothdepv = 0; %gaussian window std is one fifth total length
smoothindv = 0; %gaussian window std is one fifth total length

use_saved_model = 1;
omit_time_from_savemodel_datestr = 1; %to prevent too many saved files, setting to 1 will use date suffix in saved model filename, rather than datetime suffix
optim_hist_save_iter_spacing = 2;

plt.hsv_background = 'rois'; %'rois' or 'pixels' or 'raw';
plt.huestr = 'loc'; %loc or amp for mdlname linear . . . loc, amp, or wid for mdlname v (vonmises) or g (gaussian)
plt.huenorm = 'native'; %hue normalization method, see setup_model
plt.satnorm = 'relative'; %sat normalization method, see setup_model
plt.valnorm = 'relative';%val normalization method, see setup_model
plt.hrange_in_manual = []; %manual range for normalizing hue, prior to normalization to plot scale, whose max range is [0 1]), see compute_hsv
plt.srange_in_manual = []; %manual range for normalizing sat, prior to normalization to plot scale, whose max range is [0 1]), see compute_hsv
plt.vrange_in_manual = []; %manual range for normalizing val, prior to normalization to plot scale, whose max range is [0 1]), see compute_hsv
plt.hrange_out_manual = [0.25 1]; %hue plot scale, whose max range is [0 1] hue hange around color circle, defaults to less than full circle for non-periodic plotting domain, but overwrites in setup_model to [0 1] when plotting periodic param (e.g. von mises center, ie mdlname 'v' huestr 'loc'), see compute_hsv
plt.srange_out_manual = [0 1]; %sat plot scale, whose max range is [0 1], if you want to force saturation you can reduce (e.g. [0 0.75] will force smaller range to max saturation, see compute_hsv
plt.vrange_out_manual = [0 1];  %val plot scale, whose max range is [0 1], if you want to force value you can reduce (e.g. [0 0.75] will force smaller range to max value, see compute_hsv
plt.hueshift = 0; % 0-1, circularly shift the hue map around the color circle for change to arbitrary color assignment, applied before any clipping due to, see compute_hsv
plt.ignorehue = 0; %1 ignores it, makes constant 1
plt.ignoresat = 1; %1 ignores it, makes constant 1
plt.ignoreval = 1; %1 ignores it, makes constant 1

plt.depvplot_norm = 'each'; %amplotude normalization for the detail plots at bottom, 'all' normalizes to population, 'each' normalizes to each
plt.maxnumroiplot = 100; %number of rois that get detail view on the bottom, one per gif frame
plt.sort_method = 'unbiased'; %'majoraxis', 'unbiased', 'gof', 'custom'; %how to select rois for detail plots, 'unbiased' for equidistant maxnumroiplot, 'gof' for equidistant maxnumroiplot sorted by gof in descending order (so starts with best fit ends with worst)

plt.gif_visibility = 'on'; %on shows gif while plotting/writing/saving, off saves/writes but doesn't show it
plt.max_tinds = 1000; %1000; %for the timeseries view of depv, how many samples to plot at the most (will take indices 1:max_tinds), big number to plot all
plt.timeseries_numsegments = 3; %how many equispaced segments to display in setail view, ending at final frame

plt.plot_class = 'hsv'; %hsv only shows one epoch per plot/gif frame, epoch shows multiple epochs but no hsv map

plt.plot3d = 0;
plt.doplots = 1;



%%

%character options for different categories in different mdlnames chopt.mdlclass.category (where mdlclass is prefix of mdlname, i.e. before any optional underscore suffixes)

chopt.fnet.lay = {'[A-Z]{1}'}; %layer is any single capital letter 
chopt.fnet.chan = {'^(0*\d{1,2})*(0*\d{1,2}-\d+)*$'}; %channel is zero or more two-digit numbers, with optional hyphens denoting ranges; no channel means all channels 
chopt.fnet.comb = {'x'}; %a single x
chopt.fnet.prefix = {'^x*0*\d*(?=\D)'}; %optional x followed by optional 2-digit number
chopt.fnet.unit = {'^x*\d*((\D)*(h\d+)*(\D)*)+$'}; %optional x followed by optional 2-digit number, followed by one or more non-numeric character or one-hot encoding substring; 
chopt.fnet.lin = {'s','r','d','c','f'}; %linear functions;
chopt.fnet.non = {'e','i','l','g','v'}; %nonlinear functions; 
chopt.fnet.hot = {'h\d+'}; %one-hot encoding function; h followed by one or more numeric characters


%% assign to struct


update_param_struct; %call this script to overwrite any default params above with fields in parsin, and organize into parsout 


end





