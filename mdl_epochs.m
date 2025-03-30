function mdl = mdl_epochs(mdl, opt, pthpre, numsyn, ldval, histinc, doplt)

valnum = opt.valnum;
nrmd = opt.nrmd;
num_dim_depvp = mdl.num_dim_depvp;
pth_indvaug = mdl.pth_indvaug;
pth_depvp_bin = mdl.pth_depvp_bin;
supp = mdl.op.supp;
op = mdl.op;

doplt2 = 0;

%% loop over train/validation sets (k-fold cross-validation)

valnames = fieldnames(mdl.ft);
disp(['validation fold is ' num2str(valnum) ' and should ideally be ' num2str(sqrt(supp.num_par_total)) ])

ft_mean_allval = [];
gof_mean_allval = [];
gof_val_mean_allval = [];
indvpf_mean_allval = [];

for vfi = 1:numel(valnames) %this is 1 if there's 0 validation sets, otherwise it matches number validation sets

    inds = mdl.ft.(valnames{vfi});

    %%%% read train/val subsets of indvaug and depvaug from bin file %%%%

    indv = mdl_binld(pth_indvaug, inds.sampinds_indvpaug_train);
    indv = indv.'; %columns of indv and depv should be number samples, could change above or just transpose here
    indv_val = mdl_binld(pth_indvaug, inds.sampinds_indvpaug_val);
    indv_val = indv_val.'; %columns of indv and depv should be number samples, could change above or just transpose here

    depv_all = mdl_binld(pth_depvp_bin, inds.sampinds_depvp_train);
    depv_all = depv_all.';
    depv_all_val = mdl_binld(pth_depvp_bin, inds.sampinds_depvp_val);
    depv_all_val = depv_all_val.';

    %%%% create save path, check if current val set can be loaded %%%%
    
    numchar_timestr = 8; %how many char to use at start of time string in filename when looking for most recent saved file

    timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));

    if isempty(numchar_timestr)
        numchar_timestr = numel(timestr);
    end

    if valnum==0
        pthvalsv = [pthpre '_val_0_' timestr '_.mat'];
    else
        pthvalsv = [pthpre '_val_' num2str(vfi) '_' timestr '_.mat'];
    end

    dofit = 1;
    if ldval
        pthpatld = strrep(pthvalsv, [timestr '_.mat'], [timestr(1:numchar_timestr) '*_.mat']);
        pthvalld = rdir(pthpatld);
        if ~isempty(pthvalld)
            pthvalld = {pthvalld(:).name};
            pthvalld = pthvalld(~cellfun(@isempty, regexp(pthvalld, [timestr(1:numchar_timestr) '\d+_.mat'])));
            pthvalld = natsortfiles(pthvalld);
            if ~isempty(pthvalld)
                if ~isscalar(pthvalld)
                    fprintf("there are multiple saved val files, loading most recent, based on timestamp in filename" + newline)
                end
                load(pthvalld{end}, 'ft', 'pred', 'gof', 'gof_val', 'depv_good_inds')
                dofit = 0;
            end
        end
    end

    if dofit

        %%%% create synthetic data to test optimization (optional) %%%%

        if numsyn %if not 0, replace depv_all with synthetic data
            doplots_syn = 1; %plot synthetic vs real data
            plot_syn_against_single_depv = 1; %plot each synthetic timeseries against a single depv timeseries (the first, arbitrarily)
            [depv_all, num_dim_depvp, ftsyn] = mdl_synthesize_depv(supp.pthspre, supp, op.mdl, depv_all, indv, doplots_syn, numsyn, op.opp, plot_syn_against_single_depv, nrmd);
        end


        %%%% fit model %%%% 


        num_samp_total = inds.num_samp_total; % NOTE! unpack to reduce overhead with large 'inds' struct during parfor
        sampinds_indvdepv_val = inds.sampinds_indvdepv_val; % NOTE! unpack to reduce overhead with large 'inds' struct during parfor
        sampinds_indvdepv_train = inds.sampinds_indvdepv_train; % NOTE! unpack to reduce overhead with large 'inds' struct during parfor
        depvmin = mdl.st.depvp_min_eachdim;% NOTE! unpack to reduce overhead with large 'mdl' struct during parfor
        depvmax = mdl.st.depvp_max_eachdim;% NOTE! unpack to reduce overhead with large 'mdl' struct during parfor

        ft = zeros(num_dim_depvp, supp.num_par_total); % was num_dim_indvp*num_samp_mdl, then num_dim_indvp*supp.num_par_total
        pred = zeros(num_samp_total, num_dim_depvp, class(depv_all));
        resid = zeros(num_samp_total, num_dim_depvp, class(depv_all));
        gof = zeros(num_dim_depvp, 1);
        gof_val = zeros(num_dim_depvp, 1);

        depv_good_inds = ~any(isnan(depv_all));

        partest = 0;
        if partest
            tic
            delete(gcp('nocreate'));
            ppp = parpool('Processes');
            optpp = parforOptions(ppp,RangePartitionMethod="fixed", SubrangeSize=3);
            ticBytes(gcp);
        end

        for ri = 1:num_dim_depvp %(ri=1:num_dim_depvp, optpp) %ri = 1:num_dim_depvp
            if depv_good_inds(ri)

                depv = double(depv_all(:, ri));
                depv_val = double(depv_all_val(:, ri));

                seqft = 0;
                if seqft
                    noeb_seqfit
                else
                    [ ft(ri,:), pred(:,ri), resid(:,ri), gof(ri), gof_val(ri) ] = ...
                        mdl_fit(indv, depv, ri, histinc, ...
                        valnum, indv_val, depv_val, sampinds_indvdepv_train, ...
                        sampinds_indvdepv_val, num_samp_total, supp, op, ...
                        depvmin(ri), depvmax(ri), pthvalsv, nrmd, doplt2);
                end

            end
        end

        if partest
            tocBytes(gcp)
            toc
        end


        save(pthvalsv, 'ft', 'pred', 'gof', 'gof_val', 'depv_good_inds', '-v7.3', '-mat')

    end

    if doplt && ~doplt2
        if valnum
            mdlplt(op.mdl, supp, depv_val, pred(sampinds_indvdepv_val), ft, indv_val, opt.nrmd, gof)
        else
            mdlplt(op.mdl, supp, depv_all, pred, ft, indv, opt.nrmd, gof)
        end
    end

    %% compute some fit metrics to be used later

    depvstd = std(depv_all,1); %2nd arg is 1 to normalize by n, not n-1

    indvpf = zeros(num_dim_depvp, 1);
    for ri = 1:size(pred, 2)
        indvpf(ri) = mean(indv(max(pred(inds.sampinds_indvdepv_train,ri))==pred(inds.sampinds_indvdepv_train,ri))); %mean indv at max predicted response (mean in case there are multiple, which depends on model type)
    end
    indvpf(~depv_good_inds) = nan;

    gof_mean_all = mean(gof); %mean of all depv (e.g. all rois) gof, returns nan if not doing validation since gof_val is empty
    gof_val_mean_all = mean(gof_val); %mean of all depv (e.g. all rois) gof, returns nan if not doing validation since gof_val is empty


    %% output struct (indexed by validation index)

    mdl.ft.(valnames{vfi}).ft = ft;
    mdl.ft.(valnames{vfi}).pred = pred;
    mdl.ft.(valnames{vfi}).gof = gof;
    mdl.ft.(valnames{vfi}).gof_val = gof_val;
    mdl.ft.(valnames{vfi}).gof_mean_all = gof_mean_all;
    mdl.ft.(valnames{vfi}).gof_val_mean_all = gof_val_mean_all;
    mdl.ft.(valnames{vfi}).depv_good_inds = depv_good_inds;
    mdl.ft.(valnames{vfi}).indvpf = indvpf;
    mdl.ft.(valnames{vfi}).depvstd = depvstd;
    mdl.ft.(valnames{vfi}).pthvalsv = pthvalsv;

    ft_mean_allval = cat(ndims(ft)+1, ft_mean_allval, ft);
    gof_mean_allval = cat(ndims(gof)+1, gof_mean_allval, gof);
    gof_val_mean_allval = cat(ndims(gof_val)+1, gof_val_mean_allval, gof_val);
    indvpf_mean_allval = cat(ndims(indvpf)+1, indvpf_mean_allval, indvpf);

end

mdl.ft.ft_mean_allval = mean(ft_mean_allval, ndims(ft_mean_allval), 'omitmissing');
mdl.ft.gof_mean_allval = mean(gof_mean_allval, ndims(gof_mean_allval), 'omitmissing');
mdl.ft.gof_val_mean_allval = mean(gof_val_mean_allval, ndims(gof_val_mean_allval), 'omitmissing');
mdl.ft.indvpf_mean_allval = mean(indvpf_mean_allval, ndims(indvpf_mean_allval), 'omitmissing');


mdl = structsort(mdl);






