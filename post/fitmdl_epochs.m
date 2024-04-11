function fitin = fitmdl_epochs(fitin, opts, epi, pth_fitdata_prefix)

epochinds = opts.epochinds{epi};
epochinds_ts_i_m = fitin.epochinds_ts_i_m;
num_samp_mdl = fitin.num_samp_mdl;
num_samp_lag = fitin.num_samp_lag;
num_dim_depvpre = fitin.num_dim_depvpre;

epochinds_str = sprintf('%.0f_', epochinds);
epochinds_str = ['e_' epochinds_str(1:end-1)];

fitin.fits.(epochinds_str) = fitmdl_define_indices(fitin, opts, epochinds, epochinds_str, opts.validation_split_style);

%% define indexing variables for taking subset of indv and depv (by epoch and trainset)

epochinds_str = sprintf('%.0f_', epochinds);
epochinds_str = ['e_' epochinds_str(1:end-1)];
num_epochs = numel(epochinds);

epochinds_pure_ts_indvpreaug = zeros(1, size(epochinds_ts_i_m, 2));
for eii = 1:num_epochs
    epochinds_pure_ts_indvpreaug = epochinds_pure_ts_indvpreaug + epochinds(eii) * all(ismember(epochinds_ts_i_m, epochinds(eii)), 1); %epoch indices where the epoch is constant across all model timepoints
end
if any(epochinds_pure_ts_indvpreaug(:)>max(epochinds(:)))
    error("should not have overlapping pure epoch samples")
end

if opts.keep_transition_zones %if multi-sample model, include samples with multiple epochs only if those epochs are listed in epochinds, discards samples with any epochs not listed 
    sampinds_indvpreaug = find(all(ismember_single(epochinds_ts_i_m, epochinds), 1)); % specify dimension (1) in case epochinds_ts_i_m is singleton
else %do not include samples with multiple epochs, even if those epochs listed in epochinds
    sampinds_indvpreaug = find(epochinds_pure_ts_indvpreaug);
end


bout_endpoints = [0 find(diff(epochinds_pure_ts_indvpreaug(sampinds_indvpreaug))~=0) numel(sampinds_indvpreaug)]; %defines bouts as transitions between epochs, but only within sampinds_indvpreaug  
% bout_endpoints = [0 find(diff(sampinds_indvpreaug)~=1) length(sampinds_indvpreaug)]; %defines segments as contiguous regions within deepinds_indv (not always same as bouts)
bout_tinds = cell(1, numel(bout_endpoints)-1);
for bei = 2:numel(bout_endpoints)
    bout_tinds{bei-1} = bout_endpoints(bei-1)+1 : bout_endpoints(bei); %cell of contiguous indices from within sampinds_indvpreaug
end

for i = 1:numel(bout_tinds)
    epochind_per_bout(i) = unique(epochinds_pure_ts_indvpreaug(sampinds_indvpreaug(bout_tinds{i})));
end

for i = 1:num_epochs
    boutind_per_epoch{i} = find(epochind_per_bout==epochinds(i));
    num_bout_per_epoch(i) = numel(boutind_per_epoch{i});
    num_bout_val(i) = numel(boutind_per_epoch{i}) / opts.validation_fold;
end
if strcmp(opts.validation_split_style, 'bouts') && num_epochs>1 & any(mod(num_bout_val(num_bout_per_epoch>1), 1))
    error("there are multiple epochs and at least one epoch has a number of bouts that greater than one and is not evenly divisible by validation_fold")
end

if opts.validation_fold==0
    num_valfold_loop = 1;
else
    num_valfold_loop = opts.validation_fold;
end

gof_val_prev = 1e10;
for vfi = 1:num_valfold_loop

    if opts.validation_fold==0
        sampinds_indv_val = [];
        sampinds_indvpreaug_val = [];
    else
        for i = 1:num_epochs %train/test split eeach epoch individually, then combine, to get equal representation in the split (since each epoch can be distributed differently)
            if strcmp(opts.validation_split_style, 'bouts') && num_bout_per_epoch(i)>1 %for now, set up to allow multi-bout epochs to be train/val split by bout epoch set, may move to making all epochs split by sample, as when an epoch has only one bout (see "else" below)
                boutinds_val{i} = boutind_per_epoch{i}([1:num_bout_val(i)]+num_bout_val(i)*(vfi-1));
                sampinds_indv_val{i} = cell2mat(bout_tinds(boutinds_val{i}));
            else %if split style 'bouts' and epoch has only one bout, or if split style 'sample', just split by sample
                boutinds_val{i} = boutind_per_epoch{i};
                num_samp_allbout = numel(cell2mat(bout_tinds(boutinds_val{i})));
                num_samp_val_allbout = floor(num_samp_allbout / opts.validation_fold);
                sampinds_indv_val{i} = [1:num_samp_val_allbout]+num_samp_val_allbout*(vfi-1);
            end
            sampinds_indvpreaug_val{i} = sampinds_indvpreaug(sampinds_indv_val{i});
        end
        sampinds_indv_val = cell2mat(sampinds_indv_val);
        sampinds_indvpreaug_val = cell2mat(sampinds_indvpreaug_val);
    end
    sampinds_indv_train = setxor(sampinds_indv_val, cell2mat(bout_tinds)); %simpler than previous, which was for each epoch i, setxor(sampinds_indv_val{i}, cell2mat(bout_tinds(bout_ind_per_epoch{i})));
    sampinds_indvpreaug_train = sampinds_indvpreaug(sampinds_indv_train);

    sampinds_depvpre_train = sampinds_indvpreaug_train + (num_samp_mdl-1) + num_samp_lag; %account for desired indv vs depv lag, and number timepoints in model (which includes current so -1)
    sampinds_depvpre_val = sampinds_indvpreaug_val + (num_samp_mdl-1) + num_samp_lag; %account for desired indv vs depv lag, and number timepoints in model (which includes current so -1)

    epochinds_pure_ts_m = vec(epochinds_pure_ts_indvpreaug(union(sampinds_indvpreaug_train, sampinds_indvpreaug_val))); % was vec(epochinds_pure_ts_indvpreaug(sampinds_indvpreaug));
    num_samp_data_train = numel(sampinds_indvpreaug_train); %number samples of indv/depv given to optimization code
    num_samp_data_val = numel(sampinds_indvpreaug_val); %number samples of indv/depv given to optimization code

    %% read full indv and depv from bin, then subsample

    indv = read_mdl_var(fitin.pth_indvaug_bin);
    indv_val = indv(:, sampinds_indvpreaug_val).'; %columns of indv and depv should be number samples, could change above or just transpose here
    indv = indv(:, sampinds_indvpreaug_train).'; %columns of indv and depv should be number samples, could change above or just transpose here

    [depv_allrois, depv_allrois_class] = read_mdl_var(fitin.pth_depvpre_bin);
    depv_allrois_val = depv_allrois(:, sampinds_depvpre_val).';
    depv_allrois = depv_allrois(:, sampinds_depvpre_train).'; %columns of indv and depv should be number samples, could change above or just transpose here

    %% create save path, check if saved model already exists

    [dofit, fitin.pth_fitdata_epoch, ft, depvp, gof, depv_good_inds] = load_fitdata(pth_fitdata_prefix, epochinds_str, opts.omit_time_from_savemodel_datestr, opts.use_saved_model, opts.validation_fold, vfi);

    %% create synthetic data to test optimization (optional)

    if opts.num_synthetic_depv %if not 0, replace depv_allrois with synthetic data
        dofit = 1;
        doplots_syn = 0;
        [depv_allrois, num_dim_depvpre, ftsyn] = synthesize_depv(fitin, depv_allrois(:,opts.num_synthetic_depv), indv, doplots_syn, opts.num_synthetic_depv, fitin.supp.num_par_total, fitin.opop.optimp);
    end

    %% fit model

    if dofit

        ft = zeros(num_dim_depvpre, fitin.supp.num_par_total); % was num_dim_indvpre*num_samp_mdl, then num_dim_indvpre*fitin.supp.num_par_total
        gof = zeros(num_dim_depvpre, 1);
        depvp = zeros(size(depv_allrois), depv_allrois_class);

        tic
        depv_good_inds = ~any(isnan(depv_allrois));
        parfor ri = 1:numel(depv_good_inds)
            if depv_good_inds(ri)

                depv = double(depv_allrois(:, ri));

                if startsWith(opts.modeltype, 'svd')
                    [ ft(ri,:), gof(ri), depvp(:,ri) ] = run_svd( fitin, indv, depv);
                else
                    [ ft(ri,:), gof(ri), depvp(:,ri) ] = run_gs(fitin, indv, depv, ri, opts.save_optim_history);
                end

            end

            %tinds = 1:300; hfg = figure; subplot(2,1,1); plot(double(depvp(tinds, ri))); hold on; plot(depv_allrois(tinds,ri)); subplot(2,1,2); plot(fttmp(ri,:)); hold on; plot(ftsyn(ri,:)); fig2gif(hfg, 1, [fitin.supp.pthspre '_' datestr(now, 30) '_testpred.gif'])
            %tinds = 1:1100; hfg = figure; subplot(2,1,1); plot(double(depvp(tinds, ri))); hold on; plot(depv_allrois(tinds,ri)); subplot(2,1,2); plot(fttmp(ri,:)); fig2gif(hfg, 1, [fitin.supp.pthspre '_' datestr(now, 30) '_testpred.gif'])

        end
        toc
        %fitin.modfun(ftsyn(ri,:), indv, fitin.supp, [fitin.supp.pthspre '_' datestr(now, 30)])
        %fitin.modfun(fttmp(ri,:), indv, fitin.supp, [fitin.supp.pthspre '_' datestr(now, 30)])

        save(fitin.pth_fitdata_epoch, 'ft', 'depvp', 'gof', 'depv_good_inds', '-v7.3', '-mat')

    end

    %validation
    sampinds_depv_tmp = vec(union(sampinds_depvpre_train, sampinds_depvpre_val))';
    if opts.validation_fold~=0
        depvp_new = zeros(numel(sampinds_depv_tmp), numel(depv_good_inds));
        depv_new = zeros(numel(sampinds_depv_tmp), numel(depv_good_inds));
        indv_new = zeros(numel(sampinds_depv_tmp), size(indv, 2));
        gof_val = zeros(1,numel(depv_good_inds));
        for ri = 1:numel(depv_good_inds)
            if depv_good_inds(ri)
                depvp_new(sampinds_indv_val, ri) = fitin.opop.optimp.modfun(ft(ri,:), indv_val, fitin.supp)';
                gof_val(ri) = mse(double(depv_allrois_val(:,ri)), depvp_new(sampinds_indv_val, ri));
                depvp_new(sampinds_indv_train, ri) = depvp(:,ri);
            end
        end
        depv_new(sampinds_indv_val, :) = depv_allrois_val;
        depv_new(sampinds_indv_train, :) = depv_allrois;
        indv_new(sampinds_indv_val, :) = indv_val;
        indv_new(sampinds_indv_train, :) = indv;
        gof_val = mean(gof_val);
        if gof_val<gof_val_prev
            gof_val_prev = gof_val;
            vfi_use = vfi;
            depvp_use = depvp_new;
            depvintmp_use = depv_new;
            indvauge_use = indv_new;
            keepinds_depv_use = sampinds_depv_tmp;
            valinds_raw_use = sampinds_indv_val;
            valinds_indv_use = sampinds_indvpreaug_val;
            valinds_depv_use = sampinds_depvpre_val;
        end
    else
        vfi_use = vfi;
        depvp_use = depvp;
        depvintmp_use = depv_allrois;
        indvauge_use = indvauge;
        keepinds_depv_use = sampinds_depv_tmp;
        valinds_raw_use = sampinds_indv_val;
        valinds_indv_use = sampinds_indvpreaug_val;
        valinds_depv_use = sampinds_depvpre_val;
    end



    %% compute some fit metrics to be used later

    depvstd = std(depv_allrois,1); %2nd arg is 1 to normalize by n, not n-1

    indvpref = zeros(size(depv_allrois, 2), 1);
    for ri = 1:size(depvp, 2)
        indvpref(ri) = mean(indv(max(depvp(:,ri))==depvp(:,ri))); %mean indv at max predicted response (mean in case there are multiple, which depends on model type)
    end
    indvpref(~depv_good_inds) = nan;

end

%% output substruct (specific to the epochinds)

fitin.fits.(epochinds_str).ft = ft;
fitin.fits.(epochinds_str).depvp = depvp;
fitin.fits.(epochinds_str).gof = gof;
fitin.fits.(epochinds_str).depv_good_inds = depv_good_inds;
fitin.fits.(epochinds_str).indvpref = indvpref;
fitin.fits.(epochinds_str).depvstd = depvstd;
fitin.fits.(epochinds_str).sampinds_depvpre = sampinds_depvpre;
fitin.fits.(epochinds_str).sampinds_indvpreaug = sampinds_indvpreaug;
fitin.fits.(epochinds_str).num_samp_data_train = num_samp_data_train;
fitin.fits.(epochinds_str).num_samp_data_val = num_samp_data_val;
fitin.fits.(epochinds_str).epochinds_pure_ts_m = epochinds_pure_ts_m;

