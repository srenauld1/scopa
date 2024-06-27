function fitin = fitmdl_epochs(fitin, opts, epi, pth_fitdata_prefix)

epochinds = opts.epochinds{epi};
validation_fold = opts.validation_fold;
keep_transition_zones = opts.keep_transition_zones;
mdlname = opts.mdlname;
optim_hist_save_iter_spacing = opts.optim_hist_save_iter_spacing;
validation_split_style = opts.validation_split_style;
omit_time_from_savemodel_datestr = opts.omit_time_from_savemodel_datestr;
use_saved_model = opts.use_saved_model;
num_synthetic_depv = opts.num_synthetic_depv;
num_dim_depvpre = fitin.num_dim_depvpre;
epochinds_ts_i_m = fitin.epochinds_ts_i_m;
num_samp_mdl = fitin.num_samp_mdl;
num_samp_lag = fitin.num_samp_lag;
pth_indvaug_bin = fitin.pth_indvaug_bin;
pth_depvpre_bin = fitin.pth_depvpre_bin;
supp = fitin.opop.supp;
opop = fitin.opop;

epochinds_str = regexprep( mat2str(epochinds), {'\[', '\]', '\s+'}, {'', '', '-'});

%% define indexing variables for taking subset of indv and depv (by epoch, and by train/validation set )

fitin.fits.(epochinds_str) = fitmdl_define_indices(epochinds_ts_i_m, num_samp_mdl, num_samp_lag, keep_transition_zones, validation_fold, validation_split_style, epochinds);

%% loop over train/validation sets, for k-fold cross-validation

valnames = fieldnames(fitin.fits.(epochinds_str));
disp(['validation fold is ' num2str(validation_fold) ' and should ideally be ' num2str(sqrt(supp.num_par_total)) ])

ft_mean_allval = [];
gof_mean_allval = [];
gof_val_mean_allval = [];
indvpref_mean_allval = [];

for vfi = 1:numel(valnames) %this is 1 if there's 0 validation sets, otherwise it matches number validation sets

    inds = fitin.fits.(epochinds_str).(valnames{vfi});

    %% read full indv and depv from bin, then subsample

    indv = read_mdl_var(pth_indvaug_bin);
    indv_val = indv(:, inds.sampinds_indvpreaug_val).'; %columns of indv and depv should be number samples, could change above or just transpose here
    indv = indv(:, inds.sampinds_indvpreaug_train).'; %columns of indv and depv should be number samples, could change above or just transpose here

    [depv_allrois, depv_allrois_class] = read_mdl_var(pth_depvpre_bin);
    depv_allrois_val = depv_allrois(:, inds.sampinds_depvpre_val).';
    depv_allrois = depv_allrois(:, inds.sampinds_depvpre_train).'; %columns of indv and depv should be number samples, could change above or just transpose here

    %% create save path, check if saved model already exists

    [dofit, pth_fitdata, ft, depvp, gof, gof_val, depv_good_inds] = load_fitdata(pth_fitdata_prefix, epochinds_str, omit_time_from_savemodel_datestr, use_saved_model, validation_fold, vfi);

    %% create synthetic data to test optimization (optional)

    ftsyn = [];
    if num_synthetic_depv %if not 0, replace depv_allrois with synthetic data
        dofit = 1; %always do fit if synthesizing data anew
        doplots_syn = 0; %plot synthetic vs real data
        plot_syn_against_single_depv = 1; %plot each synthetic timeseries against a single depv timeseries (the first, arbitrarily)
        [depv_allrois, num_dim_depvpre, ftsyn] = fitmdl_synthesize_depv(supp.pthspre, supp, opop.mdl, depv_allrois, indv, doplots_syn, num_synthetic_depv, opop.optimp, plot_syn_against_single_depv);
    end

    %% fit model

    if dofit

        num_samp_total = inds.num_samp_total; %unpack to reduce overhead with large 'inds' struct during parfor
        sampinds_indvdepv_val = inds.sampinds_indvdepv_val; %unpack to reduce overhead with large 'inds' struct during parfor
        sampinds_indvdepv_train = inds.sampinds_indvdepv_train; %unpack to reduce overhead with large 'inds' struct during parfor
        depvmin = fitin.stats.depvpre_min_eachdim;%unpack to reduce overhead with large 'fitin' struct during parfor
        depvmax = fitin.stats.depvpre_max_eachdim;%unpack to reduce overhead with large 'fitin' struct during parfor

        ft = zeros(num_dim_depvpre, supp.num_par_total); % was num_dim_indvpre*num_samp_mdl, then num_dim_indvpre*supp.num_par_total
        depvp = zeros(num_samp_total, num_dim_depvpre, depv_allrois_class);
        gof = zeros(num_dim_depvpre, 1);
        gof_val = zeros(num_dim_depvpre, 1);

        tic
        depv_good_inds = ~any(isnan(depv_allrois));
        for ri = 1:num_dim_depvpre
            if depv_good_inds(ri)
                depv = double(depv_allrois(:, ri));
                depv_val = double(depv_allrois_val(:, ri));
                
                [ ft(ri,:), depvp(:,ri), gof(ri), gof_val(ri) ] = ...
                    fitmdl_fit(indv, depv, ri, optim_hist_save_iter_spacing, ...
                    mdlname, validation_fold, indv_val, depv_val, sampinds_indvdepv_train, ...
                    sampinds_indvdepv_val, num_samp_total, supp, opop, ...
                    depvmin(ri), depvmax(ri), pth_fitdata);
                %% 
                
                tinds = 300:400;
                fitmdl_plot_single_mdl(ri, opop.mdl, supp, depv, depvp(:, ri), ft(ri,:), indv, ftsyn, opts.normalize_depv, tinds) %this only works within for not parfor
            %% 
            
            end
        end
        toc

        save(pth_fitdata, 'ft', 'depvp', 'gof', 'gof_val', 'depv_good_inds', '-v7.3', '-mat')

    end


    %% compute some fit metrics to be used later

    depvstd = std(depv_allrois,1); %2nd arg is 1 to normalize by n, not n-1

    indvpref = zeros(num_dim_depvpre, 1);
    for ri = 1:size(depvp, 2)
        indvpref(ri) = mean(indv(max(depvp(inds.sampinds_indvdepv_train,ri))==depvp(inds.sampinds_indvdepv_train,ri))); %mean indv at max predicted response (mean in case there are multiple, which depends on model type)
    end
    indvpref(~depv_good_inds) = nan;

    gof_mean_allrois = mean(gof); %mean of all depv (e.g. all rois) gof, returns nan if not doing validation since gof_val is empty
    gof_val_mean_allrois = mean(gof_val); %mean of all depv (e.g. all rois) gof, returns nan if not doing validation since gof_val is empty


    %% output struct (indexed by epochinds and valind)

    fitin.fits.(epochinds_str).(valnames{vfi}).ft = ft;
    fitin.fits.(epochinds_str).(valnames{vfi}).depvp = depvp;
    fitin.fits.(epochinds_str).(valnames{vfi}).gof = gof;
    fitin.fits.(epochinds_str).(valnames{vfi}).gof_val = gof_val;
    fitin.fits.(epochinds_str).(valnames{vfi}).gof_mean_allrois = gof_mean_allrois;
    fitin.fits.(epochinds_str).(valnames{vfi}).gof_val_mean_allrois = gof_val_mean_allrois;
    fitin.fits.(epochinds_str).(valnames{vfi}).depv_good_inds = depv_good_inds;
    fitin.fits.(epochinds_str).(valnames{vfi}).indvpref = indvpref;
    fitin.fits.(epochinds_str).(valnames{vfi}).depvstd = depvstd;
    fitin.fits.(epochinds_str).(valnames{vfi}).pth_fitdata = pth_fitdata;

    ft_mean_allval = cat(ndims(ft)+1, ft_mean_allval, ft);
    gof_mean_allval = cat(ndims(gof)+1, gof_mean_allval, gof);
    gof_val_mean_allval = cat(ndims(gof_val)+1, gof_val_mean_allval, gof_val);
    indvpref_mean_allval = cat(ndims(indvpref)+1, indvpref_mean_allval, indvpref);

end

fitin.fits.(epochinds_str).ft_mean_allval = mean(ft_mean_allval, ndims(ft_mean_allval), 'omitmissing');
fitin.fits.(epochinds_str).gof_mean_allval = mean(gof_mean_allval, ndims(gof_mean_allval), 'omitmissing');
fitin.fits.(epochinds_str).gof_val_mean_allval = mean(gof_val_mean_allval, ndims(gof_val_mean_allval), 'omitmissing');
fitin.fits.(epochinds_str).indvpref_mean_allval = mean(indvpref_mean_allval, ndims(indvpref_mean_allval), 'omitmissing');


fitin = orderfields_recursive(fitin);




