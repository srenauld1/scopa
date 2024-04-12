function [ft, gof, indvpref] = fitmdl(stack, fitin, roiinfo, md, fitopt, pixfitflag)

% notes on fitting
% default is to use globalsearch with solver fmincon
% multistart and globalsearch are from global optim toolbox
% multistart can run parallel, can accept user input start points, and will test all start points, and can use different solvers, globalsearch cannot run parallel and will skip "bad" startpoints and can only use fmincon
% fmincon and lsqcurvefit are from optimization toolbox
% lsqcurvefit uses the same algorithm as lsqnonlin (also in optimization toolbox) - lsqcurvefit simply provides a convenient interface for data-fitting problems
% for lsqcurvefit, custom function should return fun(x,xdata), and not the sum-of-squares sum((fun(x,xdata)-ydata).^2). lsqcurvefit implicitly computes the sum of squares of the components of fun(x,xdata)-ydata.
% fmincon could be used instead of lsqcurvefit, but i haven't found a reason to prefer it yet (perhaps if we aren't doing regression),
% if using fmincon for least squares regression, custom function should explicitly return the sum-of-squares sum((fun(x,xdata)-ydata).^2)
% for choosing lsqcurvefit algorithm, docs say
% --For problems with bound constraints only, try 'trust-region-reflective' or 'levenberg-marquardt' first.
% --If your bound-constrained problem is underdetermined (fewer equations than dimensions), try 'levenberg-marquardt' first.
% --If your problem has linear or nonlinear constraints, use 'interior-point'.
% fmincon and lsqcurvefit will both use interior-point algorithm if using constraints
% some online resources say fmincon take constraints and lsqcurvefit doesn't, but that is not true (perhaps it used to be)

% fitnlm and nlfit are from SML toolbox, have lots of useful options and outputs
% fitnlm is shell around and nlinfit, but neither can take constraints
% so fitnlm may be useful as alternative approach when there are no constraints
% fitnlm finds least squares, and can use the same objective function as lsqcurvefit, just cannot take constraints or bounds as arguments
% for nlinfit and fitnlm:
% --nlinfit treats NaN values in Y or modelfun(beta0,X) as missing data, and ignores the corresponding observations,
% --For nonrobust estimation, nlinfit uses the Levenberg-Marquardt nonlinear least squares algorithm
% --For robust estimation, nlinfit uses the algorithm of Iteratively Reweighted Least Squares. At each iteration, the robust weights are recalculated based on each observation-s residual from the previous iteration. These weights downweight outliers, so that their influence on the fit is decreased. Iterations continue until the weights converge.
% --When you specify a function handle for observation weights, the weights depend on the fitted model. In this case, nlinfit uses an iterative generalized least squares algorithm to fit the nonlinear regression model.

% fit is from curve fitting toolbox, is very general, has useful output stats, but can only take 2d independent variables, and cannot take constraints

% using above to fit linear models can be very inefficient, but should still find the best solution
% For reduced computation time on high-dimensional data sets, fit a linear regression model using the fitrlinear function.
% for linear regression, can use fitlm
% alternatives to fitlm include
% --To regularize a regression, use fitrlinear, lasso, ridge, or plsregress.
% --fitrlinear regularizes a regression for high-dimensional data sets using lasso or ridge regression.
% --lasso removes redundant predictors in linear regression using lasso or elastic net.
% --ridge regularizes a regression with correlated terms using ridge regression.
% --plsregress regularizes a regression with correlated terms using partial least squares.

%it's not clear to me yet how to include categorical predictors, which i do have need for

% slmengine is a completely different approach from file exchange, not appropriate for large scale automated fitting, but useful for single-case exploration

% there are other options still, but above seems to me to be the most general, small set of functions for our purposes

%% params

depvin = fitin.depv;
indvin = fitin.indv;
regionex = fitin.regionex;
parsex = fitin.parsex;
parsnorm = fitin.parsnorm;
fitcount = fitin.fitcount;
pixinds_roi = roiinfo.pixinds_roi;
mapind2ind = roiinfo.mapind2ind;
epochinds_ts_i = md.epochinds_ts_i;
dtmni = md.dtmni;

%% check/correct inputs

if ~exist('pixfitflag', 'var')
    pixfitflag = 0;
    pixfitflagstr = '';
else
    if pixfitflag==1
        pixfitflagstr = '_PIX';
    end
end
if ~exist('plot_3d', 'var')
    fitopt.plot3d = 1;
end
if ~exist('fitopt.maxnumroiplot', 'var')
    fitopt.maxnumroiplot = 100;
end
if strcmp(fitopt.huenorm, 'native') && (strcmp(fitopt.modeltype, 'linear') || strcmp(fitopt.modeltype, 'plane') || strcmp(fitopt.modeltype, 'svd'))
    disp("WARNING, NO NATIVE HUENORM FOR MODELTYPES linear, plane, or svd, SWITCHING TO RELATIVE")
    fitopt.huenorm = 'relative'; %hue normalization method, see setup_model
end
if isvector(indvin) & iscolumn(indvin)
    indvin = indvin(:)';
end
if ~exist('stack', 'var')
    stack = [];
else
    stackmean = mean(stack, 4);
    if strcmp(fitopt.plot_class, 'epoch') & ~fitopt.plot3d
        stackmean = mean(stackmean, 3);
    end
end

for epi = 1:length(fitopt.epochinds)
    epochinds_str{epi} = sprintf('%.0f,', fitopt.epochinds{epi});
    epochinds_str{epi} = epochinds_str{epi}(1:end-1);
end

pth_fitdata_prefix = [fitin.fn_save_prefix  '_' fitopt.modeltype '_' num2str(fitopt.mdl_length_sec) '_' num2str(fitopt.mdl_lag_sec) pixfitflagstr];
pth_fitdata_prefix = strrep(pth_fitdata_prefix, '.', 'p');

%% create pixelwise fit for background if requested by recursively calling fitmdl with pixfitflag==1


if strcmp(fitopt.hsv_background, 'pixels') && pixfitflag==0 %only do if pixfitflag==0, to avoid infinite recursion
    pixfitflag = 1;
    pixinds_roi2 = logical(sum(pixinds_roi)); %THESE ARE PIXEL INDICES FROM ALLROI MASK, NOT EACH ROI, ALL NOT SUPERSET OF EACH IF IF ANY ROIS ARE OVERLAPPING
    depv2 = reshape(stack, [], size(stack, 4));
    depv2 = depv2(cell2mat(pixinds_roi2), :);
    fitin2.depv = depv2;
    roiinfo2 = roiinfo;
    roiinfo2.pixinds_roi = pixinds_roi2;
    fitmdl(stack, fitin2, roiinfo2, md, fitopt, pixfitflag); %call fitmdl on pixels if you want a pixel fit background behind your roi fit background
    pixfitflag = 0; %reset to zero
end


%% synthesize depv to test optimization

if fitopt.synthesize_depv
    synthesize_depv %mock data to test fitting
end

%% check indv/depv size

[ num_dim_indvpre, num_samp_indvpre ] = size( indvin );
[ numdepvs, num_samp_depvpre ] = size(depvin);

if num_samp_indvpre~=num_samp_depvpre | ndims(depvin)~=2 | ndims(indvin)~=2
    error("fix inputs")
else
    time_dimension = 2;
end


%% optional preprocessing of inputs

if fitopt.smoothdepv
    smoothdata(depvin, time_dimension, 'gaussian', fitopt.smoothdepv);
end

% num_indv_bins = 12;
% indv_binned = discretize(indvin, linspace(min(indvin(:)), max(indvin(:)), num_indv_bins));


%% exclude

if strcmp(fitopt.excludeopts, 'triangle')
    [histdt, histx] = hist(abs(indvin(:)), round(numel(indvin)/10));
    thrbin = triangle_threshold(histdt, 'R', 0);
    thrvel = histx(thrbin);
    excludeinds = abs(indvin)<thrvel;
    indvin(excludeinds) = nan;
end

%% standardize indv and depv (optional)

if fitopt.standardize_indv
    for ri = 1:num_dim_indvpre
        indvin(ri,:) = (indvin(ri,:) - nanmean(indvin(ri,:))) / nanstd(indvin(ri,:));
    end
end

if fitopt.standardize_depv
    depvinmeans = zeros(numdepvs, 1);
    depvinstds = zeros(numdepvs, 1);
    for ri = 1:numdepvs
        depvinmeans(ri) = nanmean(depvin(ri,:));
        depvinstds(ri) = nanstd(depvin(ri,:));
        depvin(ri,:) = (depvin(ri,:) - depvinmeans(ri)) / depvinstds(ri);
    end
end


%% create version of indv that can be passed to optimization code (dimensions x sample)


num_samp_mdl = round(fitopt.mdl_length_sec/dtmni);
if num_samp_mdl==0
    num_samp_mdl = 1; %a convenience, so user can pass fitopt.mdl_length_sec=0 if they don't know volume rate
end

num_dim_indv = num_dim_indvpre*num_samp_mdl;
num_samp_indvpreaug = num_samp_indvpre-(num_samp_mdl-1)-fitopt.num_samp_lag;

indvpreaug = zeros( num_dim_indv, num_samp_indvpreaug );
epochinds_ts_i_m = zeros( num_samp_mdl, num_samp_indvpreaug );
for ii = 1 : num_samp_indvpreaug
    indvpreaug(:,ii) = reshape( flip(indvin(:,ii:ii+num_samp_mdl-1), time_dimension), [], 1 ); %indvpreaug makes time samples into past just another indv dim, for model with 2 dims a and b and 4 time samples into past, with lag zero, indvpreaug element order in 1st dim, for each sample (2nd dim), is at-3, bt-3, at-2, bt-2, at-1, bt-1, at-0, bt-0 (lag will just shift t by lag)
    epochinds_ts_i_m(:,ii) = flip(epochinds_ts_i(ii:ii+num_samp_mdl-1), time_dimension); %do the same for epoch inds, to make sure model doesn't include any samples from wrong epoch
end


%% set up model options


[fitin, gethue, getsat, getval, gethr_native, gethr_relative, ...
    getsr_native, getsr_relative, getvr_native, getvr_relative, ...
    fitopt.hrange_out_manual, hue_is_periodic] = ...
    setup_model(fitopt, indvpreaug, num_samp_mdl, ...
    num_dim_indv, num_dim_indvpre, depvin, dtmni);


%% write depv to bin (to allow parfor loop without broadcasting)

pth_depvin_bin = [pth_fitdata_prefix '_depvin_.bin'];
fid = fopen(pth_depvin_bin, 'w');
depvin_class = class(depvin);
fwrite(fid, depvin, depvin_class); %write full depvin, read/index according to epoch right before parfor to avoid large broadcast var
fclose(fid);
clear depvin

%% loop over epochs

sampinds_depvpre = cell(1, length(fitopt.epochinds));
indv_plot = cell(1, length(fitopt.epochinds));
depv_plot = cell(1, length(fitopt.epochinds));
depvp_plot = cell(1, length(fitopt.epochinds));
ft = cell(1, length(fitopt.epochinds));
gof = cell(1, length(fitopt.epochinds));
indvpref = cell(1, length(fitopt.epochinds)); %preferred indv (indv at max predicted depv, often not the same as a fit param)
pureepoch = cell(1, length(fitopt.epochinds));
hsvmap = cell(1, length(fitopt.epochinds));
depvinstds_plot = cell(1, length(fitopt.epochinds));
depvinmeans_plot = cell(1, length(fitopt.epochinds));

for epi = 1:length(fitopt.epochinds) %for each indv epoch, crop indv and depv according to epoch indices, then fit model to cropped indv/depv

    pureepochtmp = zeros(1, size(epochinds_ts_i_m, 2));
    for eii = 1:length(fitopt.epochinds{epi})
        pureepochtmp = pureepochtmp + fitopt.epochinds{epi}(eii) * all(ismember(epochinds_ts_i_m, fitopt.epochinds{epi}(eii)), 1); %epoch indices where the epoch is constant across all model timepoints
    end
    if any(pureepochtmp(:)>max(fitopt.epochinds{epi}(:)))
        error("should not have overlapping pure epoch samples")
    end

    keep_transition_zones = 0;
    if keep_transition_zones %includes epoch transition zones if transitioning between epochs listed in epochinds
        keepinds_indvaug = find(all(ismember_single(epochinds_ts_i_m, fitopt.epochinds{epi}), 1)); %only keep samples with one epoch in all timepoints (model may have multiple timepoints), specify dimension (1) in case indvepochaug is singleton
    else %does not include epoch transition zones, even if between epochs listed in epochinds
        keepinds_indvaug = find(pureepochtmp);
    end

    tinds_cont = [];
    seg_endpoints = [0 find(diff(keepinds_indvaug)~=1) length(keepinds_indvaug)];
    for bei = 2:length(seg_endpoints)
        tinds_cont{bei-1} = seg_endpoints(bei-1)+1 : seg_endpoints(bei); %cell of contiguous indices
    end


    numepochval = length(tinds_cont)/fitopt.validation_fold;
    if fitopt.validation_fold==0
        valfold_loop = 1;
    else
        valfold_loop = fitopt.validation_fold;
    end

    gof_val_mean_allrois_prev = 1e10;
    for vfi = 1:valfold_loop

        if fitopt.validation_fold==0
            boutvalinds = [];
            valinds_indvaug = [];
        else
            boutvalinds = [1:numepochval]+numepochval*(vfi-1);
            sampinds_indvdepv_val = cell2mat(tinds_cont(boutvalinds));
            valinds_indvaug = keepinds_indvaug(sampinds_indvdepv_val);
        end

        bouttraininds = setxor(boutvalinds, [1:length(tinds_cont)]);
        sampinds_indvdepv_train = cell2mat(tinds_cont(bouttraininds));
        traininds_indvaug = keepinds_indvaug(sampinds_indvdepv_train);

        sampinds_depvpre_train = traininds_indvaug + (num_samp_mdl-1) + fitopt.num_samp_lag; %account for desired indv vs depv lag, and number timepoints in model (which includes current so -1)
        sampinds_depvpre_val = valinds_indvaug + (num_samp_mdl-1) + fitopt.num_samp_lag; %account for desired indv vs depv lag, and number timepoints in model (which includes current so -1)

        indvauge = indvpreaug(:, traininds_indvaug);
        indvauge = indvauge.'; %columns of indv and depv should be number samples, could change above or just transpose here

        % num_samp_data_train{epi} = length(traininds_indvaug); %number samples of indv/depv given to optimization code

        fid = fopen(pth_depvin_bin, 'r');
        depvintmp = fread(fid, [ numdepvs, num_samp_depvpre ], [depvin_class '=>' depvin_class]); %read depv then crop, to prevent broadcasting in parfor loop below
        fclose(fid);
        depvintmp2 = depvintmp(:, sampinds_depvpre_train).'; %crop to account for fit samples (if >1), depvin trails indvin, do this outside parfor


        if fitopt.validation_fold==0
            pth_fitdata_pattern = [pth_fitdata_prefix '_' epochinds_str{epi} '_0_*_fitdata_.mat'];
        else
            pth_fitdata_pattern = [pth_fitdata_prefix '_' epochinds_str{epi} '_' num2str(vfi) '_*_fitdata_.mat'];
        end
        fitdata_saved_files = rdir(pth_fitdata_pattern);
        timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS')) ;

        fitin.pth_fitdata = strrep(pth_fitdata_pattern, '*', timestr);

        dofit = 1;
        if fitopt.use_saved_model && ~isempty(fitdata_saved_files)
            fitdata_saved_files = natsortfiles(fitdata_saved_files);
            load(fitdata_saved_files(end).name) %load most recent, based on timestamp in filename
            dofit = 0;
        end

        if dofit

            fttmp = zeros(numdepvs, fitin.supp.num_par_total); % was num_dim_indvpre*num_samp_mdl, then num_dim_indvpre*fitin.supp.num_par_total
            goftmp = zeros(numdepvs, 1);
            depvp = zeros(size(depvintmp2), depvin_class);
            hdata = zeros(numdepvs, 1);
            sdata = zeros(numdepvs, 1);
            vdata = zeros(numdepvs, 1);
            indvpreftmp = zeros(numdepvs, 1);

            if strcmp(fitopt.modeltype, 'tm')
                indvauge = indvauge.';
            end

            tic
            depv_good_inds = ~any(isnan(depvintmp2));
            for ri = 1:numel(depv_good_inds)

                if depv_good_inds(ri)

                    depv = double(depvintmp2(:, ri));

                    if strcmp(fitopt.modeltype, 'svd')
                        [ fttmp(ri,:), goftmp(ri), depvp(:,ri) ] = run_svd( fitin.objfcn, indvauge, depv, fitopt.pvar);
                    else
                        if strcmp(fitopt.slvrg, 'globalsearch')
                            [ fttmp(ri,:), goftmp(ri), depvp(:,ri) ] = run_gs(fitin, indvauge, depv, ri);
                        end
                    end

                    hdata(ri) = gethue(fttmp(ri,:), indvauge, depvp(:,ri));
                    sdata(ri) = getsat(goftmp(ri));
                    vdata(ri) = getval(depv);
                    indvpreftmp(ri) = indvauge(find(max(depvp(:,ri))==depvp(:,ri), 1));

                else
                    indvpreftmp(ri) = nan;
                end

            end
            toc

            if strcmp(fitopt.modeltype, 'tm')
                indvauge = indvauge.';
            end

            save(fitin.pth_fitdata, 'fttmp', 'goftmp', 'depvp', 'hdata', 'sdata', 'vdata', 'indvpreftmp', 'depv_good_inds', '-v7.3', '-mat')

        end



        %validation
        keepinds_depv_tmp = vec(union(sampinds_depvpre_train, sampinds_depvpre_val))';
        if fitopt.validation_fold~=0
            depvp_new = zeros(length(keepinds_depv_tmp), numel(depv_good_inds));
            depv_new = zeros(length(keepinds_depv_tmp), numel(depv_good_inds));
            indv_new = zeros(length(keepinds_depv_tmp), size(indvauge, 2));
            gof_val = zeros(1,numel(depv_good_inds));
            for ri = 1:numel(depv_good_inds)
                if depv_good_inds(ri)
                    depvp_new(sampinds_indvdepv_val, ri) = fitin.objfcn(fttmp(ri,:), indvpreaug(:, valinds_indvaug), fitin.supp)';
                    gof_val(ri) = mse(double(depvintmp(ri, sampinds_depvpre_val).'), depvp_new(sampinds_indvdepv_val, ri));
                    depvp_new(sampinds_indvdepv_train, ri) = depvp(:,ri);
                end
            end
            depv_new(sampinds_indvdepv_val, :) = depvintmp(:, sampinds_depvpre_val).';
            depv_new(sampinds_indvdepv_train, :) = depvintmp2;
            indv_new(sampinds_indvdepv_val, :) = indvpreaug(:, valinds_indvaug).';
            indv_new(sampinds_indvdepv_train, :) = indvpreaug(:, traininds_indvaug).';
            gof_val = mean(gof_val);
            if gof_val<gof_val_mean_allrois_prev
                gof_val_mean_allrois_prev = gof_val;
                vfi_use = vfi;
                depvp_use = depvp_new;
                depvintmp_use = depv_new;
                indvauge_use = indv_new;
                keepinds_depv_use = keepinds_depv_tmp;
                valinds_raw_use = sampinds_indvdepv_val;
                valinds_indv_use = valinds_indvaug;
                valinds_depv_use = sampinds_depvpre_val;
            end
        else
            vfi_use = vfi;
            depvp_use = depvp;
            depvintmp_use = depvintmp2;
            indvauge_use = indvauge;
            keepinds_depv_use = keepinds_depv_tmp;
            valinds_raw_use = sampinds_indvdepv_val;
            valinds_indv_use = valinds_indvaug;
            valinds_depv_use = sampinds_depvpre_val;
        end

    end

    %select which pixels/rois get detail view and how they're sorted
    switch fitopt.sort_method
        case 'unbiased' %equidistant fitopt.maxnumroiplot, or all if there are fewer than fitopt.maxnumroiplot
            sortinds = fliplr(1:numdepvs);
            sortinds = 1:numdepvs;
        case 'majoraxis' %equidistant fitopt.maxnumroiplot, or all if there are fewer than fitopt.maxnumroiplot
            [~, sortinds] = sort(mapind2ind,  'descend');
        case 'gof' %sort by gof (sdata), then equidistant fitopt.maxnumroiplot, descending order
            [~, sortinds] = sort(sdata, 'descend');
        case 'custom'
            sortonetmp = find(abs(hdata)>2);
            sorttwotmp = setxor(1:length(hdata), sortonetmp);
            sortinds = [sortonetmp; sorttwotmp];

    end

    if fitopt.maxnumroiplot>=numdepvs
        roiinds_plot = sortinds;
    else
        roiinds_plot = sortinds(round(linspace(1, numdepvs, fitopt.maxnumroiplot)));
    end

    %organize and normalize model data into hsv map
    [ hsvmap{epi} ] = compute_hsv( indvauge_use, depvintmp_use, goftmp, ...
        hdata, sdata, vdata, ...
        fitopt.huenorm, fitopt.satnorm, fitopt.valnorm, ...
        gethr_native, gethr_relative, ...
        getsr_native, getsr_relative, ...
        getvr_native, getvr_relative, ...
        fitopt.hrange_in_manual, fitopt.srange_in_manual, fitopt.vrange_in_manual, ...
        fitopt.hrange_out_manual, fitopt.srange_out_manual, fitopt.vrange_out_manual, ...
        fitopt.hueshift, hue_is_periodic);

    %subset to create potentially smaller variables
    depvinstds_plot{epi} = depvinstds(roiinds_plot);
    depvinmeans_plot{epi} = depvinmeans(roiinds_plot);
    indv_plot{epi} = indvauge_use;
    depvintmp_use = depvintmp_use(:, roiinds_plot).';
    depvptmp = depvp_use( :, roiinds_plot).';
    if fitopt.standardize_depv
        depv_plot{epi} = depvintmp_use.*depvinstds_plot{epi} + depvinmeans_plot{epi}; %rescale to original
        depvp_plot{epi} = depvptmp.*depvinstds_plot{epi} + depvinmeans_plot{epi}; %rescale to original
    else
        depv_plot{epi} = depvintmp_use;
        depvp_plot{epi} = depvptmp;
    end
    pixinds_roi_plot = pixinds_roi(roiinds_plot);
    ft{epi} = fttmp;
    gof{epi} = goftmp;
    indvpref{epi} = indvpreftmp;

    sampinds_depvpre{epi} = keepinds_depv_use;
    pureepoch{epi} = pureepochtmp(sampinds_depvpre{epi});


end

clear depvintmp depvintmp2 depvintmp_use depvp depvp_use goftmp fttmp

%% plot everything

if fitopt.doplots

    doplots = [0 0 1 0 0];

    model_plots(hsvmap, indv_plot, depv_plot, depvp_plot, stack, stackmean, ...
        fitopt.epochinds, pixinds_roi_plot, roiinds_plot, fitopt.hsv_background, ...
        fitopt.max_tinds, fitopt.timeseries_numsegments, ...
        fitopt.ignorehue, fitopt.ignoresat, fitopt.ignoreval, ...
        fitopt.depvplot_norm, fitopt.plot_class, ...
        sampinds_depvpre, epochinds_str, pureepoch, ...
        pth_fitdata_prefix, fitopt.gif_visibility, fitin.objfcn, ft, fitin.supp, doplots, ...
        fitopt.validation_fold, vfi_use, fitopt.standardize_depv, depvinstds_plot, depvinmeans_plot, ...
        valinds_depv_use, valinds_indv_use, valinds_raw_use)


end




