function fitin = mfit_prepvars2(fitin, opts, md, pth_fitdata_prefix)

%don't unpack fitin.vars.indvp and fitin.vars.depvp from struct in case they're large (they can be updated below, which would double memory)

num_dim_indvp = fitin.num_dim_indvp;
num_samp_indvp = fitin.num_samp_indvp;
num_dim_depvp = fitin.num_dim_depvp;
num_samp_depvp = fitin.num_samp_depvp;
epochts = ts.epochinds;
sampper = md.sampper;

time_dimension = find(size(fitin.vars.indvp)==num_samp_indvp);

%% smooth in time (optional)

if opts.smoothdepv
    error("insert switch for circular")
    fitin.vars.depvp = smoothdata(fitin.vars.depvp, time_dimension, 'gaussian', opts.smoothdepv);
end
if opts.smoothindv
    error("insert switch for circular")
    for i = 1:num_dim_indvp
        fitin.vars.indvp(i,:) = smoothdata(fitin.vars.indvp(i,:), time_dimension, 'gaussian', opts.smoothindv);
    end
end

%% exclude samples (optional)

if ~isempty(opts.excludeopts)
    fitin = mfit_exclude_samples(excludeopts, fitin);
end

%% standardize indv and depv (optional)

indvp_mean_eachdim = mean(fitin.vars.indvp, 2, 'omitmissing');
indvp_std_eachdim = std(fitin.vars.indvp, 1, 2, 'omitmissing'); %2nd arg is 1 to normalize by n, not n-1
indvp_min_eachdim = min(fitin.vars.indvp, [], 2, 'omitmissing');
indvp_max_eachdim = max(fitin.vars.indvp, [], 2, 'omitmissing');

depvp_mean_eachdim = mean(fitin.vars.depvp, 2, 'omitmissing');
depvp_std_eachdim = std(fitin.vars.depvp, 1, 2, 'omitmissing'); %2nd arg is 1 to normalize by n, not n-1
depvp_min_eachdim = min(fitin.vars.depvp, [], 2, 'omitmissing');
depvp_max_eachdim = max(fitin.vars.depvp, [], 2, 'omitmissing');

if strcmp(opts.normalize_indv, 'zscore')
    fitin.normmdlvar_indv = normalize_mdl_var_forward_and_reverse(opts.normalize_indv, indvp_mean_eachdim, indvp_std_eachdim, [], []); %save function handle to forward or reverse standardize later
elseif strcmp(opts.normalize_indv, 'minmax') || strcmp(opts.normalize_indv, 'minmaxcnt')
    fitin.normmdlvar_indv = normalize_mdl_var_forward_and_reverse(opts.normalize_indv, [], [], indvp_min_eachdim, indvp_max_eachdim); %save function handle to forward or reverse standardize later
end
if ~strcmp(opts.normalize_indv, 'none')
    fitin.vars.indvp = fitin.normmdlvar_indv(fitin.vars.indvp, 'forward'); %normalize indv
end

if strcmp(opts.normalize_depv, 'zscore')
    fitin.normmdlvar_depv = normalize_mdl_var_forward_and_reverse(opts.normalize_depv, depvp_mean_eachdim, depvp_std_eachdim, [], []); %save function handle to forward or reverse standardize later
elseif strcmp(opts.normalize_depv, 'minmax') || strcmp(opts.normalize_depv, 'minmaxcnt')
    fitin.normmdlvar_depv = normalize_mdl_var_forward_and_reverse(opts.normalize_depv, [], [], depvp_min_eachdim, depvp_max_eachdim); %save function handle to forward or reverse standardize later
end
if ~strcmp(opts.normalize_depv, 'none')
    fitin.vars.depvp = fitin.normmdlvar_depv(fitin.vars.depvp, 'forward'); %normalize depv
end

%% reorganize indv into size [dimensions, samples]


num_samp_mdl = round(opts.mdl_length_sec/sampper);
if num_samp_mdl==0
    num_samp_mdl = 1; %a convenience, so user can pass opts.mdl_length_sec=0 if they don't know volume rate
end
num_samp_lag = round(opts.mdl_lag_sec/sampper);
if num_samp_lag==0
    num_samp_lag = 1; %a convenience, so user can pass opts.mdl_lag_sec=0 if they don't know volume rate
end

num_dim_indv = num_dim_indvp*num_samp_mdl;
num_samp_indvpaug = num_samp_indvp-(num_samp_mdl-1)-num_samp_lag;

indvpaug = zeros( num_dim_indv, num_samp_indvpaug ); %indv, where for each dimension (of num_dim_indvp total), each of num_samp_mdl offsets into past become an additional dimension; excludes final num_samp_mdl samples; flips timeseries in time to make dot product same as valid convolution
epochinds_ts_i_m = zeros( num_samp_mdl, num_samp_indvpaug );
for i = 1 : num_samp_indvpaug
    indvpaug(:,i) = reshape( flip(fitin.vars.indvp(:,i:i+num_samp_mdl-1), time_dimension), [], 1 ); %indvpaug makes time samples into past just another indv dim, e.g., for model with 2 dims a and b and 4 time samples into past, with lag zero, indvpaug element order in 1st dim, for each sample (2nd dim), is at-3, bt-3, at-2, bt-2, at-1, bt-1, at-0, bt-0 (lag will just shift t by lag)
    epochinds_ts_i_m(:,i) = flip(epochts(i:i+num_samp_mdl-1), time_dimension); %do the same for epochinds, to make sure model doesn't include any samples from wrong epoch
end

%% if mdlname starts with 'ohe', one hot encode indv

if startsWith(opts.mdlname, 'ohe') %one hot encode indv, if mdlname is 'ohe*'
    doplots_hot = 0;
    [indvpaug, num_dim_indv, num_samp_mdl, ~] = ...
        one_hot_encode_input(opts.mdlname, indvpaug, num_dim_indvp, num_samp_mdl, pth_fitdata_prefix, doplots_hot);
end


%% write fitin.vars.depvp and indvpaug to bin to prevent broadcasting a potentially large variable to parfor loop below (e.g., fitin.vars.depvp can be entire stack for pixelwise fits)

if ~isequal([num_dim_indv, num_samp_indvpaug], size(indvpaug))
    error("wrong write size")
end
pth_indvaug_bin = write_mdl_var(indvpaug, pth_fitdata_prefix, 'indvpaug');

if ~isequal([ num_dim_depvp, num_samp_depvp ], size(fitin.vars.depvp))
    error("wrong write size")
end
pth_depvp_bin = write_mdl_var(fitin.vars.depvp, pth_fitdata_prefix, 'depvp');


%% compute basic stats from depv and indv for repeated use later

fitin.stats.indvp_min_alldim = min(abs(fitin.vars.indvp(:)));
fitin.stats.indvp_max_alldim = max(abs(fitin.vars.indvp(:)));
fitin.stats.indvp_lim_alldim = [fitin.stats.indvp_min_alldim fitin.stats.indvp_max_alldim];
fitin.stats.indvp_extreme_alldim = max(abs(fitin.vars.indvp(:)));
fitin.stats.indvp_mean_alldim = mean(fitin.vars.indvp(:), "omitmissing");
fitin.stats.indvp_std_alldim = std(fitin.vars.indvp(:), 1, "omitmissing"); %2nd arg is 1 to normalize by n, not n-1

fitin.stats.depvp_min_alldim = min(abs(fitin.vars.depvp(:)));
fitin.stats.depvp_max_alldim = max(abs(fitin.vars.depvp(:)));
fitin.stats.depvp_lim_alldim = [fitin.stats.depvp_min_alldim fitin.stats.depvp_max_alldim];
fitin.stats.depvp_extreme_alldim = max(abs(fitin.vars.depvp(:)));
fitin.stats.depvp_mean_alldim = mean(fitin.vars.depvp(:), "omitmissing");
fitin.stats.depvp_std_alldim = std(fitin.vars.depvp(:), 1, "omitmissing"); %2nd arg is 1 to normalize by n, not n-1

fitin.stats.indvp_mean_eachdim = indvp_mean_eachdim;
fitin.stats.indvp_std_eachdim = indvp_std_eachdim;
fitin.stats.indvp_min_eachdim = indvp_min_eachdim;
fitin.stats.indvp_max_eachdim = indvp_max_eachdim;
fitin.stats.depvp_mean_eachdim = depvp_mean_eachdim;
fitin.stats.depvp_std_eachdim = depvp_std_eachdim;
fitin.stats.depvp_min_eachdim = depvp_min_eachdim;
fitin.stats.depvp_max_eachdim = depvp_max_eachdim;

fn = fieldnames(fitin.stats);
for fni = 1:numel(fn)
    fitin.stats.(fn{fni}) = double(fitin.stats.(fn{fni}));
end

%% output struct

fitin.num_dim_indv = num_dim_indv;
fitin.num_samp_indvpaug = num_samp_indvpaug;
fitin.num_samp_mdl = num_samp_mdl;
fitin.num_samp_lag = num_samp_lag;
fitin.epochinds_ts_i_m = epochinds_ts_i_m;
fitin.num_dim_indv = num_dim_indv;
fitin.pth_depvp_bin = pth_depvp_bin;
fitin.pth_indvaug_bin = pth_indvaug_bin;


fitin = structsort(fitin);

