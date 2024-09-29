function fitin = mfit_prepvars(fitin, opts, md, pth_fitdata_prefix)

%don't unpack fitin.vars.indvpre and fitin.vars.depvpre from struct in case they're large (they can be updated below, which would double memory)

num_dim_indvpre = fitin.num_dim_indvpre;
num_samp_indvpre = fitin.num_samp_indvpre;
num_dim_depvpre = fitin.num_dim_depvpre;
num_samp_depvpre = fitin.num_samp_depvpre;
epochinds_ts_i = md.epochs.epochinds_ts_i;
imper = md.imper;

time_dimension = find(size(fitin.vars.indvpre)==num_samp_indvpre);

%% smooth in time (optional)

if opts.smoothdepv
    error("insert switch for circular")
    fitin.vars.depvpre = smoothdata(fitin.vars.depvpre, time_dimension, 'gaussian', opts.smoothdepv);
end
if opts.smoothindv
    error("insert switch for circular")
    for i = 1:num_dim_indvpre
        fitin.vars.indvpre(i,:) = smoothdata(fitin.vars.indvpre(i,:), time_dimension, 'gaussian', opts.smoothindv);
    end
end

%% exclude samples (optional)

if ~isempty(opts.excludeopts)
    fitin = mfit_exclude_samples(excludeopts, fitin);
end

%% standardize indv and depv (optional)

indvpre_mean_eachdim = mean(fitin.vars.indvpre, 2, 'omitmissing');
indvpre_std_eachdim = std(fitin.vars.indvpre, 1, 2, 'omitmissing'); %2nd arg is 1 to normalize by n, not n-1
indvpre_min_eachdim = min(fitin.vars.indvpre, [], 2, 'omitmissing');
indvpre_max_eachdim = max(fitin.vars.indvpre, [], 2, 'omitmissing');

depvpre_mean_eachdim = mean(fitin.vars.depvpre, 2, 'omitmissing');
depvpre_std_eachdim = std(fitin.vars.depvpre, 1, 2, 'omitmissing'); %2nd arg is 1 to normalize by n, not n-1
depvpre_min_eachdim = min(fitin.vars.depvpre, [], 2, 'omitmissing');
depvpre_max_eachdim = max(fitin.vars.depvpre, [], 2, 'omitmissing');

if strcmp(opts.normalize_indv, 'zscore')
    fitin.normmdlvar_indv = normalize_mdl_var_forward_and_reverse(opts.normalize_indv, indvpre_mean_eachdim, indvpre_std_eachdim, [], []); %save function handle to forward or reverse standardize later
elseif strcmp(opts.normalize_indv, 'minmax') || strcmp(opts.normalize_indv, 'minmaxcnt')
    fitin.normmdlvar_indv = normalize_mdl_var_forward_and_reverse(opts.normalize_indv, [], [], indvpre_min_eachdim, indvpre_max_eachdim); %save function handle to forward or reverse standardize later
end
if ~strcmp(opts.normalize_indv, 'none')
    fitin.vars.indvpre = fitin.normmdlvar_indv(fitin.vars.indvpre, 'forward'); %normalize indv
end

if strcmp(opts.normalize_depv, 'zscore')
    fitin.normmdlvar_depv = normalize_mdl_var_forward_and_reverse(opts.normalize_depv, depvpre_mean_eachdim, depvpre_std_eachdim, [], []); %save function handle to forward or reverse standardize later
elseif strcmp(opts.normalize_depv, 'minmax') || strcmp(opts.normalize_depv, 'minmaxcnt')
    fitin.normmdlvar_depv = normalize_mdl_var_forward_and_reverse(opts.normalize_depv, [], [], depvpre_min_eachdim, depvpre_max_eachdim); %save function handle to forward or reverse standardize later
end
if ~strcmp(opts.normalize_depv, 'none')
    fitin.vars.depvpre = fitin.normmdlvar_depv(fitin.vars.depvpre, 'forward'); %normalize depv
end

%% reorganize indv into size [dimensions, samples]


num_samp_mdl = round(opts.mdl_length_sec/imper);
if num_samp_mdl==0
    num_samp_mdl = 1; %a convenience, so user can pass opts.mdl_length_sec=0 if they don't know volume rate
end
num_samp_lag = round(opts.mdl_lag_sec/imper);
if num_samp_lag==0
    num_samp_lag = 1; %a convenience, so user can pass opts.mdl_lag_sec=0 if they don't know volume rate
end

num_dim_indv = num_dim_indvpre*num_samp_mdl;
num_samp_indvpreaug = num_samp_indvpre-(num_samp_mdl-1)-num_samp_lag;

indvpreaug = zeros( num_dim_indv, num_samp_indvpreaug ); %indv, where for each dimension (of num_dim_indvpre total), each of num_samp_mdl offsets into past become an additional dimension; excludes final num_samp_mdl samples; flips timeseries in time to make dot product same as valid convolution
epochinds_ts_i_m = zeros( num_samp_mdl, num_samp_indvpreaug );
for i = 1 : num_samp_indvpreaug
    indvpreaug(:,i) = reshape( flip(fitin.vars.indvpre(:,i:i+num_samp_mdl-1), time_dimension), [], 1 ); %indvpreaug makes time samples into past just another indv dim, e.g., for model with 2 dims a and b and 4 time samples into past, with lag zero, indvpreaug element order in 1st dim, for each sample (2nd dim), is at-3, bt-3, at-2, bt-2, at-1, bt-1, at-0, bt-0 (lag will just shift t by lag)
    epochinds_ts_i_m(:,i) = flip(epochinds_ts_i(i:i+num_samp_mdl-1), time_dimension); %do the same for epochinds, to make sure model doesn't include any samples from wrong epoch
end

%% if mdlname starts with 'ohe', one hot encode indv

if startsWith(opts.mdlname, 'ohe') %one hot encode indv, if mdlname is 'ohe*'
    doplots_hot = 0;
    [indvpreaug, num_dim_indv, num_samp_mdl, ~] = ...
        one_hot_encode_input(opts.mdlname, indvpreaug, num_dim_indvpre, num_samp_mdl, pth_fitdata_prefix, doplots_hot);
end


%% write fitin.vars.depvpre and indvpreaug to bin to prevent broadcasting a potentially large variable to parfor loop below (e.g., fitin.vars.depvpre can be entire stack for pixelwise fits)

if ~isequal([num_dim_indv, num_samp_indvpreaug], size(indvpreaug))
    error("wrong write size")
end
pth_indvaug_bin = write_mdl_var(indvpreaug, pth_fitdata_prefix, 'indvpreaug');

if ~isequal([ num_dim_depvpre, num_samp_depvpre ], size(fitin.vars.depvpre))
    error("wrong write size")
end
pth_depvpre_bin = write_mdl_var(fitin.vars.depvpre, pth_fitdata_prefix, 'depvpre');


%% compute basic stats from depv and indv for repeated use later

fitin.stats.indvpre_min_alldim = min(abs(fitin.vars.indvpre(:)));
fitin.stats.indvpre_max_alldim = max(abs(fitin.vars.indvpre(:)));
fitin.stats.indvpre_lim_alldim = [fitin.stats.indvpre_min_alldim fitin.stats.indvpre_max_alldim];
fitin.stats.indvpre_extreme_alldim = max(abs(fitin.vars.indvpre(:)));
fitin.stats.indvpre_mean_alldim = mean(fitin.vars.indvpre(:), "omitmissing");
fitin.stats.indvpre_std_alldim = std(fitin.vars.indvpre(:), 1, "omitmissing"); %2nd arg is 1 to normalize by n, not n-1

fitin.stats.depvpre_min_alldim = min(abs(fitin.vars.depvpre(:)));
fitin.stats.depvpre_max_alldim = max(abs(fitin.vars.depvpre(:)));
fitin.stats.depvpre_lim_alldim = [fitin.stats.depvpre_min_alldim fitin.stats.depvpre_max_alldim];
fitin.stats.depvpre_extreme_alldim = max(abs(fitin.vars.depvpre(:)));
fitin.stats.depvpre_mean_alldim = mean(fitin.vars.depvpre(:), "omitmissing");
fitin.stats.depvpre_std_alldim = std(fitin.vars.depvpre(:), 1, "omitmissing"); %2nd arg is 1 to normalize by n, not n-1

fitin.stats.indvpre_mean_eachdim = indvpre_mean_eachdim;
fitin.stats.indvpre_std_eachdim = indvpre_std_eachdim;
fitin.stats.indvpre_min_eachdim = indvpre_min_eachdim;
fitin.stats.indvpre_max_eachdim = indvpre_max_eachdim;
fitin.stats.depvpre_mean_eachdim = depvpre_mean_eachdim;
fitin.stats.depvpre_std_eachdim = depvpre_std_eachdim;
fitin.stats.depvpre_min_eachdim = depvpre_min_eachdim;
fitin.stats.depvpre_max_eachdim = depvpre_max_eachdim;

fn = fieldnames(fitin.stats);
for fni = 1:numel(fn)
    fitin.stats.(fn{fni}) = double(fitin.stats.(fn{fni}));
end

%% output struct

fitin.num_dim_indv = num_dim_indv;
fitin.num_samp_indvpreaug = num_samp_indvpreaug;
fitin.num_samp_mdl = num_samp_mdl;
fitin.num_samp_lag = num_samp_lag;
fitin.epochinds_ts_i_m = epochinds_ts_i_m;
fitin.num_dim_indv = num_dim_indv;
fitin.pth_depvpre_bin = pth_depvpre_bin;
fitin.pth_indvaug_bin = pth_indvaug_bin;


fitin = orderfields_recursive(fitin);

