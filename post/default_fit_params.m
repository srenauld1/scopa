function optout = default_fit_params(optin)

do_predict = 1;

depvpre_str = {...
    ['resp, *, *, *'], ...
    };
indvpre_str = {...
    {['resp, *, *, *']}...
    };
depv_indv_combine = 'any'; %any or each
ignore_missing_vars = 0;

num_synthetic_depv = 0; %create synthetic data (using requested modeltype params, within any requested bounds) for testing fit; this is number of synthetic responses to fit; 0 to skip
epochinds = {[4]};
mdl_lag_sec = 0; %0 is one sample, how many samples indv precedes depv for model fit . . . for now, must be nonnegative integers, range 0 to lenfit_samp-1
mdl_length_sec = 2; %seconds, 0 is one sample

keep_transition_zones = 0; %1 to keep multi-timepoint model samples that have multiple epochs

validation_fold = 6; %applied to all modeltypes; k in k-fold cross-validation; k non-overlapping validation sets; if numbouts of each epoch in epochinds is divisible by validation_fold, will validate on numbouts/validation_fold bouts for each epoch in epochinds; if only one bout for each epoch, will evenly split each bout into k validation sets; otherwise will error; 0 skips validation
validation_split_style = 'boutsamples'; %'samples' or 'bouts' or 'boutsamples' %applied to all modeltypes; k in k-fold cross-validation; k non-overlapping validation sets; if numbouts of each epoch in epochinds is divisible by validation_fold, will validate on numbouts/validation_fold bouts for each epoch in epochinds; if only one bout for each epoch, will evenly split each bout into k validation sets; otherwise will error; 0 skips validation

slvrg = 'globalsearch';
slvrl = 'fmincon'; %'lsqcurvefit';
modeltype = 'ann_L1_sh16x'; %'svd'; %'gaussian', 'vonmises' 'log' 'linear' 'nonadaptive'

excludeopts = '';

standardize_indv = 1;%1 makes each indv mean=0 variance=1 for fitting model (but still uses original scale for plotting), this is useful for comparing gof (if gof is default of mse, at least) of models fit to depv whose amplitudes differ
standardize_depv = 1; %1 makes each depv mean=0 variance=1 for fitting model (but still uses original scale for plotting), this is useful for comparing gof (if gof is default of mse, at least) of models fit to depv whose amplitudes differ
smoothdepv = 0; %gaussian window std is one fifth total length
smoothindv = 0; %gaussian window std is one fifth total length

use_saved_model = 1;
omit_time_from_savemodel_datestr = 1; %to prevent too many saved files, setting to 1 will use date suffix in saved model filename, rather than datetime suffix
optim_hist_save_iter_spacing = 2;

plt.hsv_background = 'rois'; %'rois' or 'pixels' or 'raw';
plt.huestr = 'loc'; %loc or amp for modeltype linear . . . loc, amp, or wid for modeltype vonmises or gaussian
plt.huenorm = 'native'; %hue normalization method, see setup_model
plt.satnorm = 'relative'; %sat normalization method, see setup_model
plt.valnorm = 'relative';%val normalization method, see setup_model
plt.hrange_in_manual = []; %manual range for normalizing hue, prior to normalization to plot scale, whose max range is [0 1]), see compute_hsv
plt.srange_in_manual = []; %manual range for normalizing sat, prior to normalization to plot scale, whose max range is [0 1]), see compute_hsv
plt.vrange_in_manual = []; %manual range for normalizing val, prior to normalization to plot scale, whose max range is [0 1]), see compute_hsv
plt.hrange_out_manual = [0.25 1]; %hue plot scale, whose max range is [0 1] hue hange around color circle, defaults to less than full circle for non-periodic plotting domain, but overwrites in setup_model to [0 1] when plotting periodic param (e.g. von mises center, ie modeltype 'vonmises' huestr 'loc'), see compute_hsv
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

%character options for different categories in different modeltypes chopt.modeltypePrefix.category (modeltypePrefix means modeltype string before any optional underscore suffixes)
chopt.ann.lay = {'L'};
chopt.ann.chan = {'C'};
chopt.ann.lin = {'l','s','d','f'};
chopt.ann.act = {'a','e','i'};
chopt.ann.hot = {'h'};
chopt.ann.hotsuf = {'x','c','t','n'};

%% assign to struct


s = whos;
par_defaults = cell2struct({s.name}.',{s.name});
par_defaults = rmfield(par_defaults, 'optin');
eval(structvars(par_defaults,0).');
par_defaults = orderfields(par_defaults);

for ofi = 1:length(optin) %for struct index in optin
    optout(ofi) = param_struct_recurse(optin(ofi), par_defaults);
end


end

function optout = param_struct_recurse(optin, optout)

fn = fieldnames(optout);
for fi = 1:length(fn)
    if isfield(optin, fn{fi})
        if isstruct(optin.(fn{fi}))
            if ~isstruct(optout.(fn{fi})) && ~isobject(optout.(fn{fi})) %optim struct can refer to object not struct
                error("input struct where there is no default struct")
            else
                optout.(fn{fi}) = param_struct_recurse(optin.(fn{fi}), optout.(fn{fi}));
            end
        else
            if ~isempty(optin.(fn{fi}))
                optout.(fn{fi}) = optin.(fn{fi}); %overwrite default with user-defined input
            end
        end
    end
end

end

