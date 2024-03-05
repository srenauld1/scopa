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
trialepochinds_i = md.trialepochinds_i;
dtmni = md.dtmni;

%% check/correct inputs

if ~exist('pixfitflag', 'var')
    pixfitflag = 0;
    pixfitflagstr = '';
else
    if pixfitflag==1
        pixfitflagstr = 'PIX';
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
    fitopt.huenorm = 'relative'; %hue normalization method, see model_setup
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

pth_fitdata_prefix = [fitin.fn_save_prefix  '_' fitopt.modeltype '_' num2str(fitopt.length_model_seconds) '_' num2str(fitopt.num_samp_lag) '_' pixfitflagstr];
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

[ num_dim_indvin, num_samp_indvin ] = size( indvin );
[ numdepvs, num_samp_depvin ] = size(depvin);

if num_samp_indvin~=num_samp_depvin | ndims(depvin)~=2 | ndims(indvin)~=2
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
    for ri = 1:num_dim_indvin
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


num_samp_model = round(fitopt.length_model_seconds/dtmni);
if num_samp_model==0
    num_samp_model = 1; %a convenience, so user can pass fitopt.length_model_seconds=0 if they don't know volume rate
end

num_dim_indvaug = num_dim_indvin*num_samp_model;
num_samp_indvaug_full = num_samp_indvin-(num_samp_model-1)-fitopt.num_samp_lag;

indvaug = zeros( num_dim_indvaug, num_samp_indvaug_full );
trialepochindsaug = zeros( num_samp_model, num_samp_indvaug_full );
for ii = 1 : num_samp_indvaug_full
    indvaug(:,ii) = reshape( flip(indvin(:,ii:ii+num_samp_model-1), time_dimension), [], 1 ); %indvaug makes time samples into past just another indv dim, for model with 2 dims a and b and 4 time samples into past, with lag zero, indvaug element order in 1st dim, for each sample (2nd dim), is at-3, bt-3, at-2, bt-2, at-1, bt-1, at-0, bt-0 (lag will just shift t by lag)
    trialepochindsaug(:,ii) = flip(trialepochinds_i(ii:ii+num_samp_model-1), time_dimension); %do the same for epoch inds, to make sure model doesn't include any samples from wrong epoch
end


%% set up model fitting and plotting options

[objfcn, lbnd, ubnd, linineq_A, linineq_b, x0, numftpars, ...
    gethue, getsat, getval, gethr_native, gethr_relative, ...
    getsr_native, getsr_relative, getvr_native, getvr_relative, ...
    fitopt.hrange_out_manual, hue_is_periodic, supp] = ...
    model_setup(...
    fitopt.modeltype, fitopt.huestr, ...
    fitopt.hrange_out_manual,indvaug, num_samp_model, ...
    num_dim_indvaug, num_dim_indvin, depvin, dtmni);


%% write depv to bin (to allow parfor loop without broadcasting)

pth_depvin_bin = [pth_fitdata_prefix 'depvin_.bin'];
fid = fopen(pth_depvin_bin, 'w');
depvin_class = class(depvin);
fwrite(fid, depvin, depvin_class); %write full depvin, read/index according to epoch right before parfor to avoid large broadcast var
fclose(fid);
clear depvin

%% loop over epochs

keepinds_depv = cell(1, length(fitopt.epochinds));
indv_plot = cell(1, length(fitopt.epochinds));
depv_plot = cell(1, length(fitopt.epochinds));
preddepv_plot = cell(1, length(fitopt.epochinds));
ft = cell(1, length(fitopt.epochinds));
gof = cell(1, length(fitopt.epochinds));
indvpref = cell(1, length(fitopt.epochinds)); %preferred indv (indv at max predicted depv, often not the same as a fit param)
pureepoch_keepinds = cell(1, length(fitopt.epochinds));

for epi = 1:length(fitopt.epochinds) %for each indv epoch, crop indv and depv according to epoch indices, then fit model to cropped indv/depv

    puretmp = zeros(1, size(trialepochindsaug, 2));
    for eii = 1:length(fitopt.epochinds{epi})
        puretmp = puretmp + fitopt.epochinds{epi}(eii) * all(ismember(trialepochindsaug, fitopt.epochinds{epi}(eii)), 1); %epoch indices where the epoch is constant across all model timepoints 
    end
    if any(puretmp(:)>max(fitopt.epochinds{epi}(:)))
        error("should not have overlapping pure epoch samples")
    end

    keep_transition_zones = 0;
    if keep_transition_zones %includes epoch transition zones if transitioning between epochs listed in epochinds
        keepinds_indvaug = find(all(ismember_single(trialepochindsaug, fitopt.epochinds{epi}), 1)); %only keep samples with one epoch in all timepoints (model may have multiple timepoints), specify dimension (1) in case indvepochaug is singleton
    else %does not include epoch transition zones, even if between epochs listed in epochinds
        keepinds_indvaug = find(puretmp);
    end

    keepinds_depv{epi} = keepinds_indvaug + (num_samp_model-1) + fitopt.num_samp_lag; %account for desired indv vs depv lag, and number timepoints in model (which includes current so -1)

    indvauge = indvaug(:, keepinds_indvaug);
    indvauge = indvauge.'; %columns of indv and depv should be number samples, could change above or just transpose here

    num_samp_data{epi} = length(keepinds_indvaug); %number samples of indv/depv given to optimization code

    pureepoch_keepinds{epi} = puretmp(keepinds_indvaug);

    fid = fopen(pth_depvin_bin, 'r');
    depvintmp = fread(fid, [ numdepvs, num_samp_depvin ], [depvin_class '=>' depvin_class]); %read depv then crop, to prevent broadcasting in parfor loop below
    fclose(fid);
    depvintmp = depvintmp(:, keepinds_depv{epi}).'; %crop to account for fit samples (if >1), depvin trails indvin, do this outside parfor

    pth_fitdata_epoch_pattern = [pth_fitdata_prefix '_' epochinds_str{epi} '_*_fitdata_.mat'];
    fitdata_saved_files = rdir(pth_fitdata_epoch_pattern);
    timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS')) ;

    pth_fitdata_epoch{epi} = strrep(pth_fitdata_epoch_pattern, '*', timestr);

    dofit = 1;
    if fitopt.use_saved_model && ~isempty(fitdata_saved_files)
        load(fitdata_saved_files(end).name) %load most recent, based on timestamp in filename
        dofit = 0;
    end

    if dofit

        fttmp = zeros(numdepvs, numftpars); % was num_dim_indvin*num_samp_model, then num_dim_indvin*numftpars
        goftmp = zeros(numdepvs, 1);
        preddepv = zeros(size(depvintmp), depvin_class);
        hdata = zeros(numdepvs, 1);
        sdata = zeros(numdepvs, 1);
        vdata = zeros(numdepvs, 1);
        indvpreftmp = zeros(numdepvs, 1);

        if strcmp(fitopt.modeltype, 'tm')
            indvauge = indvauge.';
        end
        tic
        for ri = 1:numdepvs %fit model to each pixel and/or roi

            depv = double(depvintmp(:, ri));

            if strcmp(fitopt.modeltype, 'svd')
                pvar = 0.8;
                [ fttmp(ri,:), goftmp(ri), preddepv(:,ri), hdata(ri), sdata(ri), vdata(ri), indvpreftmp(ri) ] = ...
                    run_svd( objfcn, indvauge, depv, pvar, gethue, getsat, getval);
            else
                if strcmp(fitopt.slvrg, 'globalsearch')
                    [ fttmp(ri,:), goftmp(ri), preddepv(:,ri), hdata(ri), sdata(ri), vdata(ri), indvpreftmp(ri)] = ...
                        run_gs(fitopt.slvrl, objfcn, depv, indvauge, x0, lbnd, ubnd, linineq_A, linineq_b, gethue, getsat, getval, supp, ri, pth_fitdata_epoch{epi});
                end
            end
            % %if you want to see each fit (before model_plots below), change parfor above to for and uncomment this section
            % if ri==1
            %     hfg = figure;
            %     hax = axes( 'Parent', hfg);
            %     hpl = plot(hax, depv);
            %     hold(hax, 'on')
            %     hpl2 = plot(hax, preddepv);
            % else
            %     hpl.YData = depv;
            %     hold(hax, 'on')
            %     hpl2.YData = preddepv;
            % end
            % pause(0.2) %pause is required for fig to appear during loop(??)


        end

        if strcmp(fitopt.modeltype, 'tm')
            indvauge = indvauge.';
        end
        toc

        save(pth_fitdata_epoch{epi}, 'fttmp', 'goftmp', 'preddepv', 'hdata', 'sdata', 'vdata', 'indvpreftmp', '-v7.3', '-mat')

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
    [ hsvmap{epi} ] = form_hsv( indvauge, depvintmp, goftmp, ...
        hdata, sdata, vdata, ...
        fitopt.huenorm, fitopt.satnorm, fitopt.valnorm, ...
        gethr_native, gethr_relative, ...
        getsr_native, getsr_relative, ...
        getvr_native, getvr_relative, ...
        fitopt.hrange_in_manual, fitopt.srange_in_manual, fitopt.vrange_in_manual, ...
        fitopt.hrange_out_manual, fitopt.srange_out_manual, fitopt.vrange_out_manual, ...
        fitopt.hueshift, hue_is_periodic);

    %subset to create potentially smaller variables
    indv_plot{epi} = indvauge;
    depvintmp = depvintmp(:, roiinds_plot).';
    preddepvtmp = preddepv( :, roiinds_plot).';
    if fitopt.standardize_depv
        depv_plot{epi} = depvintmp.*depvinstds(roiinds_plot) + depvinmeans(roiinds_plot); %rescale to original
        preddepv_plot{epi} = preddepvtmp.*depvinstds(roiinds_plot) + depvinmeans(roiinds_plot); %rescale to original
    else
        depv_plot{epi} = depvintmp;
        preddepv_plot{epi} = preddepvtmp;
    end
    pixinds_roi_plot = pixinds_roi(roiinds_plot);
    ft{epi} = fttmp;
    gof{epi} = goftmp;
    indvpref{epi} = indvpreftmp;

end

clear depvintmp preddepv goftmp fttmp

%% plot everything

if fitopt.doplots

    doplots = [0 0 1 1 0];

    model_plots(hsvmap, indv_plot, depv_plot, preddepv_plot, stack, stackmean, ...
        fitopt.epochinds, pixinds_roi_plot, roiinds_plot, fitopt.hsv_background, ...
        fitopt.max_tinds, fitopt.timeseries_numsegments, ...
        fitopt.ignorehue, fitopt.ignoresat, fitopt.ignoreval, ...
        fitopt.depvplot_norm, fitopt.plot_class, ...
        keepinds_depv, epochinds_str, pureepoch_keepinds, ...
        pth_fitdata_prefix, fitopt.gif_visibility, objfcn, ft, supp, doplots)


end




