function [ft, gof, pstim] = fitresp(stack, stimin, respin, ...
    pixinds_roi, mapind2ind, stimepochinds_i, ...
    dtmni, pth_fitdata_prefix, fitopt)

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

%% check/correct inputs

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
if isvector(stimin) & iscolumn(stimin)
    stimin = stimin(:)';
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

pth_fitdata_prefix = [pth_fitdata_prefix '_' fitopt.modeltype '_' num2str(fitopt.length_model_seconds) '_' num2str(fitopt.num_samp_lag)];

%% create pixelwise fit for background if requested


if strcmp(fitopt.hsv_background, 'pixels')
    pixinds_roi_2 = logical(sum(pixinds_roi)); %THESE ARE PIXEL INDICES FROM ALLROI MASK, NOT EACH ROI, ALL NOT SUPERSET OF EACH IF IF ANY ROIS ARE OVERLAPPING
    respin2 = reshape(stack, [], size(stack, 4));
    respin2 = respin2(cell2mat(pixinds_roi_2), :);
    pth_fitdata_prefix_pix = [pth_fitdata_prefix '_PIX'];
    fitresp(stack, stimfit, respin2, pixinds_roi, mapind2ind, ... %call fitresp on pixels if you want a pixel fit background behind your roi fit background
        stimepochinds_i, dtmni, pth_fitdata_prefix_pix, opt.fit);
end


%% synthesize responses to test optimization 

if fitopt.synthesize_resp
    synthesize_responses %mock data to test fitting
end

%% check stim/response size

[ num_dim_stimin, num_samp_stimin ] = size( stimin );
[ numresps, num_samp_respin ] = size(respin);

if num_samp_stimin~=num_samp_respin | ndims(respin)~=2 | ndims(stimin)~=2
    error("fix inputs")
else
    time_dimension = 2;
end


%% optional preprocessing of inputs

if fitopt.smoothresp
    smoothdata(respin, time_dimension, 'gaussian', fitopt.smoothresp);
end

% num_stim_bins = 12;
% stimbinned = discretize(stimin, linspace(min(stimin(:)), max(stimin(:)), num_stim_bins));


%% exclude

if strcmp(fitopt.excludeopts, 'triangle')
    [histdt, histx] = hist(abs(stimin(:)), round(numel(stimin)/10));
    thrbin = triangle_threshold(histdt, 'R', 0);
    thrvel = histx(thrbin);
    excludeinds = abs(stimin)<thrvel;
    stimin(excludeinds) = nan;
end

%% standardize stim and response (optional)

if fitopt.standardize_stim
    for ri = 1:num_dim_stimin
        stimin(ri,:) = (stimin(ri,:) - nanmean(stimin(ri,:))) / nanstd(stimin(ri,:));
    end
end

if fitopt.standardize_resp
    respinmeans = zeros(numresps, 1);
    respinstds = zeros(numresps, 1);
    for ri = 1:numresps
        respinmeans(ri) = nanmean(respin(ri,:));
        respinstds(ri) = nanstd(respin(ri,:));
        respin(ri,:) = (respin(ri,:) - respinmeans(ri)) / respinstds(ri);
    end
end


%% create version of stim that can be passed to optimization code (dimensions x sample)


num_samp_model = round(fitopt.length_model_seconds/dtmni);
if num_samp_model==0
    num_samp_model = 1; %a convenience, so user can pass fitopt.length_model_seconds=0 if they don't know volume rate
end

num_dim_stimaug = num_dim_stimin*num_samp_model;
num_samp_stimaug_full = num_samp_stimin-(num_samp_model-1)-fitopt.num_samp_lag;

stimaug = zeros( num_dim_stimaug, num_samp_stimaug_full );
stimepochindsaug = zeros( num_samp_model, num_samp_stimaug_full );
for ii = 1 : num_samp_stimaug_full
    stimaug(:,ii) = reshape( flip(stimin(:,ii:ii+num_samp_model-1), time_dimension), [], 1 ); %stimaug makes time samples into past just another stim dim, for model with 2 dims a and b and 4 time samples into past, with lag zero, stimaug element order in 1st dim, for each sample (2nd dim), is at-3, bt-3, at-2, bt-2, at-1, bt-1, at-0, bt-0 (lag will just shift t by lag)
    stimepochindsaug(:,ii) = flip(stimepochinds_i(ii:ii+num_samp_model-1), time_dimension); %do the same for epoch inds, to make sure model doesn't include any samples from wrong epoch
end


%% set up model fitting and plotting options

[objfcn, lbnd, ubnd, linineq_A, linineq_b, x0, numftpars, ...
    gethue, getsat, getval, gethr_native, gethr_relative, ...
    getsr_native, getsr_relative, getvr_native, getvr_relative, ...
    fitopt.hrange_out_manual, hue_is_periodic, supp] = ...
    model_setup(fitopt.modeltype, fitopt.huestr, ...
    fitopt.hrange_out_manual, ...
    stimaug, num_samp_model, num_dim_stimaug, num_dim_stimin, respin, dtmni);


%% write response to bin (to allow parfor loop without broadcasting)

pth_respin_bin = [pth_fitdata_prefix 'respin_.bin'];
fid = fopen(pth_respin_bin, 'w');
respin_class = class(respin);
fwrite(fid, respin, respin_class); %write full respin, read/index according to epoch right before parfor to avoid large broadcast var
fclose(fid);
clear respin

%% loop over epochs

keepinds_resp = cell(1, length(fitopt.epochinds));
stim_plot = cell(1, length(fitopt.epochinds));
resp_plot = cell(1, length(fitopt.epochinds));
predresp_plot = cell(1, length(fitopt.epochinds));
ft = cell(1, length(fitopt.epochinds));
gof = cell(1, length(fitopt.epochinds));
pstim = cell(1, length(fitopt.epochinds)); %preferred stim (stim at max predicted response, often not the same as a fit param)

for epi = 1:length(fitopt.epochinds) %for each stim epoch, crop stim and response according to epoch indices, then fit model to cropped stim/response

    keepinds_stimaug = find(all(ismember(stimepochindsaug, fitopt.epochinds{epi}), 1)); %only keep samples with one epoch in all timepoints (model may have multiple timepoints), specify dimension (1) in case stimepochaug is singleton
    keepinds_resp{epi} = keepinds_stimaug + (num_samp_model-1) + fitopt.num_samp_lag; %account for desired stim vs resp lag, and number timepoints in model (which includes current so -1)

    stimauge = stimaug(:, keepinds_stimaug);
    stimauge = stimauge.'; %columns of stim and response should be number samples, could change above or just transpose here

    num_samp_data{epi} = length(keepinds_stimaug); %number samples of stim/response given to optimization code

    fid = fopen(pth_respin_bin, 'r');
    respintmp = fread(fid, [ numresps, num_samp_respin ], [respin_class '=>' respin_class]); %read resp then crop, to prevent broadcasting in parfor loop below
    fclose(fid);
    respintmp = respintmp(:, keepinds_resp{epi}).'; %crop to account for fit samples (if >1), respin trails stimin, do this outside parfor

    pth_fitdata_epoch_pattern = [pth_fitdata_prefix '_' epochinds_str{epi} '_*_fitdata_.mat'];
    fitdata_saved_files = rdir(pth_fitdata_epoch_pattern);
    timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS')) ;

    pth_fitdata_epoch = strrep(pth_fitdata_epoch_pattern, '*', timestr);

    dofit = 1;
    if fitopt.use_saved_model && ~isempty(fitdata_saved_files)
        load(fitdata_saved_files(end).name) %load most recent, based on timestamp in filename
        dofit = 0;
    end

    if dofit

        fttmp = zeros(numresps, numftpars); % was num_dim_stimin*num_samp_model, then num_dim_stimin*numftpars
        goftmp = zeros(numresps, 1);
        predresp = zeros(size(respintmp), respin_class);
        hdata = zeros(numresps, 1);
        sdata = zeros(numresps, 1);
        vdata = zeros(numresps, 1);
        pstimtmp = zeros(numresps, 1);

        if strcmp(fitopt.modeltype, 'tm')
            stimauge = stimauge.';
        end
        tic
        for ri = 1:numresps %fit model to each pixel and/or roi

            resp = double(respintmp(:, ri));

            if strcmp(fitopt.modeltype, 'svd')
                pvar = 0.8;
                [ fttmp(ri,:), goftmp(ri), predresp(:,ri), hdata(ri), sdata(ri), vdata(ri), pstimtmp(ri) ] = ...
                    run_svd( objfcn, stimauge, resp, pvar, gethue, getsat, getval)
            else
                if strcmp(fitopt.slvrg, 'globalsearch')
                    [ fttmp(ri,:), goftmp(ri), predresp(:,ri), hdata(ri), sdata(ri), vdata(ri), pstimtmp(ri)] = ...
                        run_gs(fitopt.slvrl, objfcn, resp, stimauge, x0, lbnd, ubnd, linineq_A, linineq_b, gethue, getsat, getval, supp, ri, pth_fitdata_epoch);
                end
            end
            % %if you want to see each fit (before model_plots below), change parfor above to for and uncomment this section
            % if ri==1
            %     hfg = figure;
            %     hax = axes( 'Parent', hfg);
            %     hpl = plot(hax, resp);
            %     hold(hax, 'on')
            %     hpl2 = plot(hax, predresp);
            % else
            %     hpl.YData = resp;
            %     hold(hax, 'on')
            %     hpl2.YData = predresp;
            % end
            % pause(0.2) %pause is required for fig to appear during loop(??)


        end

        if strcmp(fitopt.modeltype, 'tm')
            stimauge = stimauge.';
        end
        toc

        save(pth_fitdata_epoch, 'fttmp', 'goftmp', 'predresp', 'hdata', 'sdata', 'vdata', 'pstimtmp', '-v7.3', '-mat')

    end

    %select which pixels/rois get detail view and how they're sorted
    switch fitopt.sort_method
        case 'unbiased' %equidistant fitopt.maxnumroiplot, or all if there are fewer than fitopt.maxnumroiplot
            sortinds = fliplr(1:numresps);
            sortinds = 1:numresps;
        case 'majoraxis' %equidistant fitopt.maxnumroiplot, or all if there are fewer than fitopt.maxnumroiplot
            [~, sortinds] = sort(mapind2ind,  'descend');
        case 'gof' %sort by gof (sdata), then equidistant fitopt.maxnumroiplot, descending order
            [~, sortinds] = sort(sdata, 'descend');
        case 'custom'
            sortonetmp = find(abs(hdata)>2);
            sorttwotmp = setxor(1:length(hdata), sortonetmp);
            sortinds = [sortonetmp; sorttwotmp];

    end

    if fitopt.maxnumroiplot>=numresps
        roiinds_plot = sortinds;
    else
        roiinds_plot = sortinds(round(linspace(1, numresps, fitopt.maxnumroiplot)));
    end

    %organize and normalize model data into hsv map
    [ hsvmap{epi} ] = form_hsv( stimauge, respintmp, goftmp, ...
        hdata, sdata, vdata, ...
        fitopt.huenorm, fitopt.satnorm, fitopt.valnorm, ...
        gethr_native, gethr_relative, ...
        getsr_native, getsr_relative, ...
        getvr_native, getvr_relative, ...
        fitopt.hrange_in_manual, fitopt.srange_in_manual, fitopt.vrange_in_manual, ...
        fitopt.hrange_out_manual, fitopt.srange_out_manual, fitopt.vrange_out_manual, ...
        fitopt.hueshift, hue_is_periodic);

    %subset to create potentially smaller variables
    stim_plot{epi} = stimauge;
    respintmp = respintmp(:, roiinds_plot).';
    predresptmp = predresp( :, roiinds_plot).';
    if fitopt.standardize_resp
        resp_plot{epi} = respintmp.*respinstds(roiinds_plot) + respinmeans(roiinds_plot); %rescale to original
        predresp_plot{epi} = predresptmp.*respinstds(roiinds_plot) + respinmeans(roiinds_plot); %rescale to original
    else
        resp_plot{epi} = respintmp;
        predresp_plot{epi} = predresptmp;
    end
    pixinds_roi_plot = pixinds_roi(roiinds_plot);
    ft{epi} = fttmp;
    gof{epi} = goftmp;
    pstim{epi} = pstimtmp;

end

clear respintmp predresp goftmp fttmp

%% plot everything

if fitopt.doplots

    doplots = [0 0 1 1 0];

    model_plots(hsvmap, stim_plot, resp_plot, predresp_plot, stack, stackmean, ...
        fitopt.epochinds, pixinds_roi_plot, roiinds_plot, fitopt.hsv_background, ...
        fitopt.max_tinds, fitopt.timeseries_numsegments, ...
        fitopt.ignorehue, fitopt.ignoresat, fitopt.ignoreval, ...
        fitopt.responseplot_norm, fitopt.plot_class, ...
        keepinds_resp, stimepochinds_i, epochinds_str, ...
        pth_fitdata_prefix, fitopt.gif_visibility, objfcn, ft, supp, doplots)


end




