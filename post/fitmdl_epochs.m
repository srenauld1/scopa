function fitin = fitmdl_epochs(fitin, opts, epi, pth_fitdata_prefix)

epochinds = opts.epochinds{epi};
trialepochindsaug = fitin.trialepochindsaug;
num_samp_model = fitin.num_samp_model;
num_samp_lag = fitin.num_samp_lag;
num_dim_depv_pre = fitin.num_dim_depv_pre;

%% define indexing variables for taking subset of indv and depv (by epoch and trainset)

epochinds_str = sprintf('%.0f_', epochinds);
epochinds_str = ['e_' epochinds_str(1:end-1)];
num_epochs = numel(epochinds);

pure_epoch_samples = zeros(1, size(trialepochindsaug, 2));
for eii = 1:num_epochs
    pure_epoch_samples = pure_epoch_samples + epochinds(eii) * all(ismember(trialepochindsaug, epochinds(eii)), 1); %epoch indices where the epoch is constant across all model timepoints
end
if any(pure_epoch_samples(:)>max(epochinds(:)))
    error("should not have overlapping pure epoch samples")
end

if opts.keep_transition_zones %includes epoch transition zones if transitioning between epochs listed in epochinds
    keepinds_indv = find(all(ismember_single(trialepochindsaug, epochinds), 1)); %only keep samples with one epoch in all timepoints (model may have multiple timepoints), specify dimension (1) in case indvepochaug is singleton
else %does not include epoch transition zones, even if between epochs listed in epochinds
    keepinds_indv = find(pure_epoch_samples);
end


seg_endpoints = [0 find(diff(keepinds_indv)~=1) length(keepinds_indv)];
tinds_cont = cell(1, numel(seg_endpoints)-1);
for bei = 2:numel(seg_endpoints)
    tinds_cont{bei-1} = seg_endpoints(bei-1)+1 : seg_endpoints(bei); %cell of contiguous indices
end

for i = 1:numel(tinds_cont)
    epoch_ind_per_bout(i) = unique(pure_epoch_samples(keepinds_indv(tinds_cont{i})));
end

for i = 1:num_epochs
    bout_ind_per_epoch{i} = find(epoch_ind_per_bout==epochinds(i));
    num_bout_per_epoch(i) = numel(bout_ind_per_epoch{i});
    num_bout_val(i) = numel(bout_ind_per_epoch{i}) / opts.validation_fold;
end
if num_epochs>1 & any(mod(num_bout_val(num_bout_per_epoch>1), 1))
    error("there are multiple epochs and at least one epoch has a number of bouts that greater than one and is not evenly divisible by validation_fold")
end

if opts.validation_fold==0
    valfold_loop = 1;
else
    valfold_loop = opts.validation_fold;
end


for vfi = 1:valfold_loop

    if opts.validation_fold==0
        boutinds_val = [];
        valinds_indv = [];
    else
        for i = 1:num_epochs %train/test split eeach epoch individually, then combine, to get equal representation in the split (since each epoch can be distributed differently)
            if num_bout_per_epoch(i)>1 %for now, set up to allow multi-bout epochs to be train/val split by bout epoch set, may move to making all epochs split by sample, as when an epoch has only one bout (see "else" below)
                boutinds_val{i} = bout_ind_per_epoch{i}([1:num_bout_val(i)]+num_bout_val(i)*(vfi-1));
                valinds_rawinds{i} = cell2mat(tinds_cont(boutinds_val{i}));
            else %if epoch has only one bout, just split by sample
                boutinds_val{i} = bout_ind_per_epoch{i};
                numsamp_onebout = numel(cell2mat(tinds_cont(boutinds_val{i})));
                numsamp_val_onebout = floor(numsamp_onebout / opts.validation_fold);
                valinds_rawinds{i} = [1:numsamp_val_onebout]+numsamp_val_onebout*(vfi-1);
            end
            valinds_indv{i} = keepinds_indv(valinds_rawinds{i});
            traininds_rawinds{i} = setxor(valinds_rawinds{i}, cell2mat(tinds_cont(bout_ind_per_epoch{i})));
            traininds_indv{i} = keepinds_indv(traininds_rawinds{i});
        end
        valinds_rawinds = cell2mat(valinds_rawinds);
        valinds_indv = cell2mat(valinds_indv);
        traininds_rawinds = cell2mat(traininds_rawinds);
        traininds_indv = cell2mat(traininds_indv);

    end


    traininds_depv = traininds_indv + (num_samp_model-1) + num_samp_lag; %account for desired indv vs depv lag, and number timepoints in model (which includes current so -1)
    valinds_depv = valinds_indv + (num_samp_model-1) + num_samp_lag; %account for desired indv vs depv lag, and number timepoints in model (which includes current so -1)

    pureepoch_keepinds = vec(pure_epoch_samples(traininds_indv)); % was vec(pure_epoch_samples(keepinds_indv));
    num_samp_data_train = length(traininds_indv); %number samples of indv/depv given to optimization code

    %% read full indv and depv from bin, then subsample

    indv = read_mdl_var(fitin.pth_indvaug_bin);
    indv = indv(:, traininds_indv).'; %columns of indv and depv should be number samples, could change above or just transpose here

    [depv_all, depv_all_class] = read_mdl_var(fitin.pth_depv_pre_bin);
    depv_all = depv_all(:, traininds_depv).'; %columns of indv and depv should be number samples, could change above or just transpose here

    %% create save path, check if saved model already exists

    [dofit, fitin.pth_fitdata_epoch, ft, depvp, gof, depv_good_inds] = load_fitdata(pth_fitdata_prefix, epochinds_str, opts.omit_time_from_savemodel_datestr, opts.use_saved_model);

    %% create synthetic data to test optimization (optional)

    if opts.num_synthetic_depv %if not 0, replace depv_all with synthetic data
        dofit = 1;
        doplots_syn = 0;
        [depv_all, num_dim_depv_pre, ftsyn] = synthesize_depv(fitin, depv_all(:,opts.num_synthetic_depv), indv, doplots_syn, opts.num_synthetic_depv, fitin.supp.num_par_total, fitin.opop.optimp);
    end

    %% fit model

    if dofit

        ft = zeros(num_dim_depv_pre, fitin.supp.num_par_total); % was num_dim_indv_pre*num_samp_model, then num_dim_indv_pre*fitin.supp.num_par_total
        gof = zeros(num_dim_depv_pre, 1);
        depvp = zeros(size(depv_all), depv_all_class);

        tic
        depv_good_inds = ~any(isnan(depv_all));
        parfor ri = 1:numel(depv_good_inds)
            if depv_good_inds(ri)

                depv = double(depv_all(:, ri));

                if startsWith(opts.modeltype, 'svd')
                    [ ft(ri,:), gof(ri), depvp(:,ri) ] = run_svd( fitin, indv, depv);
                else
                    [ ft(ri,:), gof(ri), depvp(:,ri) ] = run_gs(fitin, indv, depv, ri, opts.save_optim_history);
                end

            end

            %tinds = 1:300; hfg = figure; subplot(2,1,1); plot(double(depvp(tinds, ri))); hold on; plot(depv_all(tinds,ri)); subplot(2,1,2); plot(fttmp(ri,:)); hold on; plot(ftsyn(ri,:)); fig2gif(hfg, 1, [fitin.supp.pthspre '_' datestr(now, 30) '_testpred.gif'])
            %tinds = 1:1100; hfg = figure; subplot(2,1,1); plot(double(depvp(tinds, ri))); hold on; plot(depv_all(tinds,ri)); subplot(2,1,2); plot(fttmp(ri,:)); fig2gif(hfg, 1, [fitin.supp.pthspre '_' datestr(now, 30) '_testpred.gif'])

        end
        toc
        %fitin.modfun(ftsyn(ri,:), indv, fitin.supp, [fitin.supp.pthspre '_' datestr(now, 30)])
        %fitin.modfun(fttmp(ri,:), indv, fitin.supp, [fitin.supp.pthspre '_' datestr(now, 30)])

        save(fitin.pth_fitdata_epoch, 'ft', 'depvp', 'gof', 'depv_good_inds', '-v7.3', '-mat')

    end



    %% compute some fit metrics to be used later

    depvstd = std(depv_all);

    indvpref = zeros(size(depv_all, 2), 1);
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
fitin.fits.(epochinds_str).keepinds_depv = keepinds_depv;
fitin.fits.(epochinds_str).keepinds_indv = keepinds_indv;
fitin.fits.(epochinds_str).num_samp_data_train = num_samp_data_train;
fitin.fits.(epochinds_str).pureepoch_keepinds = pureepoch_keepinds;

