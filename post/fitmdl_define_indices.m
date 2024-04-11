function out = fitmdl_define_indices(fitin, opts, epochinds, validation_split_style)

epochinds_ts_i_m = fitin.epochinds_ts_i_m;
num_samp_mdl = fitin.num_samp_mdl;
num_samp_lag = fitin.num_samp_lag;

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
if strcmp(validation_split_style, 'bouts') && num_epochs>1 & any(mod(num_bout_val(num_bout_per_epoch>1), 1))
    error("there are multiple epochs and at least one epoch has a number of bouts that greater than one and is not evenly divisible by validation_fold")
end

if opts.validation_fold==0
    num_valfold_loop = 1;
else
    num_valfold_loop = opts.validation_fold;
end

for vfi = 1:num_valfold_loop

    if opts.validation_fold==0
        valstr = 'v_0';
        sampinds_indv_val = [];
        sampinds_indvpreaug_val = [];
    else
        valstr = ['v_' num2str(vfi)];
        for i = 1:num_epochs %train/test split eeach epoch individually, then combine, to get equal representation in the split (since each epoch can be distributed differently)
            if strcmp(validation_split_style, 'bouts') && num_bout_per_epoch(i)>1 %for now, set up to allow multi-bout epochs to be train/val split by bout epoch set, may move to making all epochs split by sample, as when an epoch has only one bout (see "else" below)
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


    out.(valstr).num_valfold_loop = num_valfold_loop;

    fuk2 = union(sampinds_indvpreaug_train, sampinds_indvpreaug_val);
    out.(valstr).sampinds_indvpreaug = sampinds_indvpreaug;
    out.(valstr).sampinds_indv_train = sampinds_indv_train;
    out.(valstr).sampinds_indv_val = sampinds_indv_val;
    out.(valstr).sampinds_indvpreaug_train = sampinds_indvpreaug_train;
    out.(valstr).sampinds_indvpreaug_val = sampinds_indvpreaug_val;

    fuk = union(sampinds_depvpre_train, sampinds_depvpre_val);
    out.(valstr).sampinds_depvpre = sampinds_depvpre;
    out.(valstr).sampinds_depvpre_train = sampinds_depvpre_train;
    out.(valstr).sampinds_depvpre_val = sampinds_depvpre_val;

    out.(valstr).num_samp_data_train = num_samp_data_train;
    out.(valstr).num_samp_data_val = num_samp_data_val;
    out.(valstr).epochinds_pure_ts_m = epochinds_pure_ts_m;

end

