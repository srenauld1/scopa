function optout = default_fit_params(optin)

depv = {...
    ['resp, *, *, *'], ...
    };
indv = {...
    {['resp, *, *, *']}...
    };
outercellcombine = 'any'; %any or each


hsv_background = 'rois'; %'rois' or 'pixels' or 'raw';
synthesize_depv = 0; %create toy data for testing fit
epochinds = {[4]};
num_samp_lag = 1; %how many samples indv precedes depv for model fit . . . for now, must be nonnegative integers, range 0 to lenfit_samp-1
length_model_seconds = 2; %seconds, 0 is one sample

slvrg = 'globalsearch';
slvrl = 'fmincon'; %'lsqcurvefit';
modeltype = 'glno'; %'svd'; %'gaussian', 'vonmises' 'log' 'linear' 'nonadaptive'
huestr = 'loc'; %loc or amp for modeltype linear . . . loc, amp, or wid for modeltype vonmises or gaussian
pvar = 0.8; %for modeltype svd, fraction of the data variance that the linear fit should account for; if not 1.0, pvar eliminates smaller singular values from pseudoinverse;

huenorm = 'native'; %hue normalization method, see model_setup
satnorm = 'relative'; %sat normalization method, see model_setup
valnorm = 'relative';%val normalization method, see model_setup
hrange_in_manual = []; %manual range for normalizing hue, prior to normalization to plot scale, whose max range is [0 1]), see form_hsv
srange_in_manual = []; %manual range for normalizing sat, prior to normalization to plot scale, whose max range is [0 1]), see form_hsv
vrange_in_manual = []; %manual range for normalizing val, prior to normalization to plot scale, whose max range is [0 1]), see form_hsv
hrange_out_manual = [0.25 1]; %hue plot scale, whose max range is [0 1] hue hange around color circle, defaults to less than full circle for non-periodic plotting domain, but overwrites in model_setup to [0 1] when plotting periodic param (e.g. von mises center, ie modeltype 'vonmises' huestr 'loc'), see form_hsv
srange_out_manual = [0 1]; %sat plot scale, whose max range is [0 1], if you want to force saturation you can reduce (e.g. [0 0.75] will force smaller range to max saturation, see form_hsv
vrange_out_manual = [0 1];  %val plot scale, whose max range is [0 1], if you want to force value you can reduce (e.g. [0 0.75] will force smaller range to max value, see form_hsv
hueshift = 0; % 0-1, circularly shift the hue map around the color circle for change to arbitrary color assignment, applied before any clipping due to, see form_hsv
ignorehue = 0; %1 ignores it, makes constant 1
ignoresat = 1; %1 ignores it, makes constant 1
ignoreval = 1; %1 ignores it, makes constant 1

depvplot_norm = 'each'; %amplotude normalization for the detail plots at bottom, 'all' normalizes to population, 'each' normalizes to each
maxnumroiplot = 100; %number of rois that get detail view on the bottom, one per gif frame
sort_method = 'unbiased'; %'majoraxis', 'unbiased', 'gof', 'custom'; %how to select rois for detail plots, 'unbiased' for equidistant maxnumroiplot, 'gof' for equidistant maxnumroiplot sorted by gof in descending order (so starts with best fit ends with worst)

standardize_indv = 0;
standardize_depv = 1; %1 makes each depv mean=0 variance=1 for fitting model (but still uses original scale for plotting), this is useful for comparing gof (if gof is default of mse, at least) of models fit to depv whose amplitudes differ
smoothdepv = 0; %gaussian window std is one fifth total length

gif_visibility = 'on'; %on shows gif while plotting/writing/saving, off saves/writes but doesn't show it
max_tinds = 1000; %1000; %for the timeseries view of depv, how many samples to plot at the most (will take indices 1:max_tinds), big number to plot all
timeseries_numsegments = 3; %how many equispaced segments to display in setail view, ending at final frame

plot_class = 'hsv'; %hsv only shows one epoch per plot/gif frame, epoch shows multiple epochs but no hsv map
excludeopts = '';

plot3d = 0;
doplots = 1;
use_saved_model = 1;
timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS')) ;


%% assign to struct 


s = whos;
par_defaults = cell2struct({s.name}.',{s.name});
par_defaults = rmfield(par_defaults, 'optin');
eval(structvars(par_defaults,0).');
par_defaults = orderfields(par_defaults);


for ofi = 1:length(optin) %for struct index in optin
    optout(ofi) = par_defaults;
    fn = fieldnames(optout(ofi));
    for fi = 1:length(fn)
        if isfield(optin(ofi), fn{fi})
            optout(ofi).(fn{fi}) = optin(ofi).(fn{fi}); %overwrite default with user-defined input 
        end
    end
end

