function mdl = mdl_prepvars(mdl, opts, imrate, pthpre, epochts)

%don't unpack mdl.vars.indvp and mdl.vars.depvp from struct in case they're large (they can be updated below, which would double memory)

num_dim_indvp = mdl.num_dim_indvp;
num_samp_indvp = mdl.num_samp_indvp;
num_dim_depvp = mdl.num_dim_depvp;
num_samp_depvp = mdl.num_samp_depvp;

time_dimension = find(size(mdl.vars.indvp)==num_samp_indvp);


%% exclude samples (optional)

if ~isempty(opts.rm)
    mdl = mdl_exclude_samples(rm, mdl);
end

%% standardize indv and depv (optional)

indvp_mean_eachdim = mean(mdl.vars.indvp, 2, 'omitmissing');
indvp_std_eachdim = std(mdl.vars.indvp, 1, 2, 'omitmissing'); %2nd arg is 1 to normalize by n, not n-1
indvp_min_eachdim = min(mdl.vars.indvp, [], 2, 'omitmissing');
indvp_max_eachdim = max(mdl.vars.indvp, [], 2, 'omitmissing');

depvp_mean_eachdim = mean(mdl.vars.depvp, 2, 'omitmissing');
depvp_std_eachdim = std(mdl.vars.depvp, 1, 2, 'omitmissing'); %2nd arg is 1 to normalize by n, not n-1
depvp_min_eachdim = min(mdl.vars.depvp, [], 2, 'omitmissing');
depvp_max_eachdim = max(mdl.vars.depvp, [], 2, 'omitmissing');

if strcmp(opts.nrmi, 'zscore')
    mdl.normmdlvar_indv = mdl_nrmvar(opts.nrmi, indvp_mean_eachdim, indvp_std_eachdim, [], []); %save function handle to forward or reverse standardize later
elseif strcmp(opts.nrmi, 'minmax') || strcmp(opts.nrmi, 'minmaxcnt')
    mdl.normmdlvar_indv = mdl_nrmvar(opts.nrmi, [], [], indvp_min_eachdim, indvp_max_eachdim); %save function handle to forward or reverse standardize later
end
if ~isempty(opts.nrmi)
    mdl.vars.indvp = mdl.normmdlvar_indv(mdl.vars.indvp, 'forward'); %normalize indv
end

if strcmp(opts.nrmd, 'zscore')
    mdl.normmdlvar_depv = mdl_nrmvar(opts.nrmd, depvp_mean_eachdim, depvp_std_eachdim, [], []); %save function handle to forward or reverse standardize later
elseif strcmp(opts.nrmd, 'minmax') || strcmp(opts.nrmd, 'minmaxcnt')
    mdl.normmdlvar_depv = mdl_nrmvar(opts.nrmd, [], [], depvp_min_eachdim, depvp_max_eachdim); %save function handle to forward or reverse standardize later
end
if ~isempty(opts.nrmd)
    mdl.vars.depvp = mdl.normmdlvar_depv(mdl.vars.depvp, 'forward'); %normalize depv
end

%% reorganize indv into size [dimensions, samples]


num_samp_mdl = round(opts.lensec*imrate);
if num_samp_mdl==0
    num_samp_mdl = 1; %a convenience, so user can pass opts.lensec=0 if they don't know volume rate
end
num_samp_lag = round(opts.lagsec*imrate);
% if num_samp_lag==0
%     num_samp_lag = 1; %a convenience, so user can pass opts.lagsec=0 if they don't know volume rate
% end

num_dim_indv = num_dim_indvp*num_samp_mdl;
num_samp_indvpaug = num_samp_indvp-(num_samp_mdl-1)-num_samp_lag;

indvpaug = zeros( num_dim_indv, num_samp_indvpaug ); %indv, where for each dimension (of num_dim_indvp total), each of num_samp_mdl offsets into past become an additional dimension; excludes final num_samp_mdl samples; flips timeseries in time to make dot product same as valid convolution
epochtsaug = zeros( num_samp_mdl, num_samp_indvpaug );
for k = 1 : num_samp_indvpaug
    indvpaug(:,k) = reshape( flip(mdl.vars.indvp(:,k:k+num_samp_mdl-1), time_dimension), [], 1 ); %indvpaug makes time samples into past just another indv dim, e.g., for model with 2 dims a and b and 4 time samples into past, with lag zero, indvpaug element order in 1st dim, for each sample (2nd dim), is at-3, bt-3, at-2, bt-2, at-1, bt-1, at-0, bt-0 (lag will just shift t by lag)
    epochtsaug(:,k) = flip(epochts(k:k+num_samp_mdl-1), time_dimension); %do the same for epochts, to make sure model doesn't include any samples from wrong epoch
end

%% if mdlname starts with 'ohe', one hot encode indv

if startsWith(opts.mdlname, 'ohe') %one hot encode indv, if mdlname is 'ohe*'
    doplots_hot = 0;
    [indvpaug, num_dim_indv, num_samp_mdl, ~] = ...
        mdl_ohevar(opts.mdlname, indvpaug, num_dim_indvp, num_samp_mdl, pthpre, doplots_hot);
end


%% write mdl.vars.depvp and indvpaug to bin to prevent broadcasting a potentially large variable to parfor loop below (e.g., mdl.vars.depvp can be entire stack for pixelwise fits)

if ~isequal([num_dim_indv, num_samp_indvpaug], size(indvpaug))
    error("wrong write size")
end
pth_indvaug_bin = mdl_binsv(indvpaug, pthpre, 'indvpaug');

if ~isequal([ num_dim_depvp, num_samp_depvp ], size(mdl.vars.depvp))
    error("wrong write size")
end
pth_depvp_bin = mdl_binsv(mdl.vars.depvp, pthpre, 'depvp');


%% compute basic stats from depv and indv for repeated use later

mdl.stats.indvp_min_alldim = min(abs(mdl.vars.indvp(:)));
mdl.stats.indvp_max_alldim = max(abs(mdl.vars.indvp(:)));
mdl.stats.indvp_lim_alldim = [mdl.stats.indvp_min_alldim mdl.stats.indvp_max_alldim];
mdl.stats.indvp_extreme_alldim = max(abs(mdl.vars.indvp(:)));
mdl.stats.indvp_mean_alldim = mean(mdl.vars.indvp(:), "omitmissing");
mdl.stats.indvp_std_alldim = std(mdl.vars.indvp(:), 1, "omitmissing"); %2nd arg is 1 to normalize by n, not n-1

mdl.stats.depvp_min_alldim = min(abs(mdl.vars.depvp(:)));
mdl.stats.depvp_max_alldim = max(abs(mdl.vars.depvp(:)));
mdl.stats.depvp_lim_alldim = [mdl.stats.depvp_min_alldim mdl.stats.depvp_max_alldim];
mdl.stats.depvp_extreme_alldim = max(abs(mdl.vars.depvp(:)));
mdl.stats.depvp_mean_alldim = mean(mdl.vars.depvp(:), "omitmissing");
mdl.stats.depvp_std_alldim = std(mdl.vars.depvp(:), 1, "omitmissing"); %2nd arg is 1 to normalize by n, not n-1

%recompute these after optional normalization before assigning to mdl.stats
indvp_mean_eachdim = mean(mdl.vars.indvp, 2, 'omitmissing');
indvp_std_eachdim = std(mdl.vars.indvp, 1, 2, 'omitmissing'); %2nd arg is 1 to normalize by n, not n-1
indvp_min_eachdim = min(mdl.vars.indvp, [], 2, 'omitmissing');
indvp_max_eachdim = max(mdl.vars.indvp, [], 2, 'omitmissing');

depvp_mean_eachdim = mean(mdl.vars.depvp, 2, 'omitmissing');
depvp_std_eachdim = std(mdl.vars.depvp, 1, 2, 'omitmissing'); %2nd arg is 1 to normalize by n, not n-1
depvp_min_eachdim = min(mdl.vars.depvp, [], 2, 'omitmissing');
depvp_max_eachdim = max(mdl.vars.depvp, [], 2, 'omitmissing');

mdl.stats.indvp_mean_eachdim = indvp_mean_eachdim;
mdl.stats.indvp_std_eachdim = indvp_std_eachdim;
mdl.stats.indvp_min_eachdim = indvp_min_eachdim;
mdl.stats.indvp_max_eachdim = indvp_max_eachdim;
mdl.stats.depvp_mean_eachdim = depvp_mean_eachdim;
mdl.stats.depvp_std_eachdim = depvp_std_eachdim;
mdl.stats.depvp_min_eachdim = depvp_min_eachdim;
mdl.stats.depvp_max_eachdim = depvp_max_eachdim;

fn = fieldnames(mdl.stats);
for fni = 1:numel(fn)
    mdl.stats.(fn{fni}) = double(mdl.stats.(fn{fni}));
end

%% output struct

mdl.num_dim_indv = num_dim_indv;
mdl.num_samp_indvpaug = num_samp_indvpaug;
mdl.num_samp_mdl = num_samp_mdl;
mdl.num_samp_lag = num_samp_lag;
mdl.epochtsaug = epochtsaug;
mdl.num_dim_indv = num_dim_indv;
mdl.pth_depvp_bin = pth_depvp_bin;
mdl.pth_indvaug_bin = pth_indvaug_bin;


mdl = structsort(mdl);

