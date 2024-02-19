
disp("see ricker.m for 1d filter option")
disp("see ricker.m for 1d filter option")
disp("see ricker.m for 1d filter option")
disp("see ricker.m for 1d filter option")
disp("see ricker.m for 1d filter option")
disp("see ricker.m for 1d filter option")


%% define params
%
% rval documentation The algorithm also measures the reliability of the spatial mask by comparing the filters in A
%      with the average of the movies over samples where exceptional events happen, after  removing (if possible)
%     frames when neighboring neurons were active

%%g4 frame 0 (in vis.raw) assigned to angle -pi (in vis.ang)

clear all
close all
clc

"IS THE RE WRAPPING EVER OFF BY ONE, WHERE 2PI APPEARS TWICE AS ZERO AND 2PI??"

no_stim_epochs = 0;
do_cropping_session = 0; %skip everything except drawing 2d rois
skip_existing = 0;
plot_stack_stats = 0;

% set(0,'DefaultFigureWindowStyle','docked')

parent_folder_on_scratch = 'stacks';
currdir = split(pwd, '/');
currdir = currdir{end};
envname = getenv('HOSTNAME');
if ~isempty(regexp( envname, 'compute-', 'once' ))
    pth_super = ['/n/scratch/users/'  currdir(1) '/' currdir '/' parent_folder_on_scratch '/'];
else
    pth_super = '~/stacks/';
end

doplots = 0;

recdate = '20230627';
fly = '*';
trial = '*';

suffix_analysis = 'cmrg_dcdn';

regionex_all = {'gar', 'gal', 'nor', 'nol', 'pb'};
% regionex_all = {'eb', 'gar', 'gal', 'nor', 'nol'};
% regionex_all = {'ff', 'gar', 'nol'}; %third char may not exist, if not will be created

use_hires = [0, 0, 0, 0, 1];
use_drawn_rois = [1, 1, 1, 1, 1]; %for each region in regionex, this is how many centroids/glomeruli across the entire region (not hemisphere)
numroi_morph_auto = [1, 1, 1, 1, 32]; %for each region in regionex, this is how many centroids/glomeruli across the entire region (not hemisphere)
numroi_func = [0, 0, 0, 0, 16]; %for each region in regionex, this is how many centroids/glomeruli across the entire region (not hemisphere)

caiman_lr_str_all = {'2_1_0.9_*_*_*_*_1000_*_*_graph_2dex'}; %cell of strings, empty to skip
caiman_lr_str_all = {''}; %cell of strings, empty to skip

use_caiman_on_hires = [0, 0, 0, 0, 0]; %keep at 0 bc pipeline is poorly written for this option (also doens't seem to help)
caiman_hr_str = '*'; %empty to skip

%params for stacks gif
suffixes_plot = {
    % 'cmrg', ...%comment if you don't want to plot (can comment all too)
    %'raw', ... %comment if you don't want to plot (can comment all too)
    %'cmrg_dcdn', ... %comment if you don't want to plot (can comment all too)
    }; %anything missing will be skipped, will be reordered from least to most processed (by suffix length)
plotinds_t = [20.3]; %t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
plotinds_z = []; %z indices to plot, empty for all, negative for that number equidistant from all available
swapdim = 1; %true will flip z and t for plotting to change perspective on registration, recommended for length(plotinds_z)>1
nan_numlines = 4; %how many lines of nans to insert in dim 1 above each subplot
rescale_each_subplot = 1; %rescale each subplot to same range 0-1 before combining
rescalefac_wholeplot = [0 1]; %combined plot rescale arguments, [lower, upper]
smooth_window_temporal = 0;
ncolgif = 128;

%params for response normalization
response_normalization_string = {...
    'rescale0100', ...
    'rescale595', ...
    'zscore', ...
    'nonnegative', ...
    'dffzscore', ...
    'dff595'...
    % 'boxcox'...
    };
normalize_before_roi_clustering = 0;
normalize_after_roi_clustering = 1;
md2.f0_pct = 15; %percentile defining baseline fluorescence in dff computation (for static F0)

%params for stimulus/fictrac processing
md2.num_panel_frames = 192; %don't include extra dark frame . . . panel frames are zero indexed so 192 is 193rd increment of circle, and 193 is 194th unique frame denoting darkness
md2.dark_stim_end_duration = 60; %final seconds
md2.smoothwindow_sec = 0.2; %0.65 full width of gaussian smoothing window (5 times std)
md2.slopeorder = 2; %order of polynomial used to fit local slope
md2.slopelen = 5; %window length used to fit slope
md2.croptimeinds = [0 0]; %this is only relevant for carl's old project

extraction_method_supplemental = 'morphological';
rescale_resp = 1;

%params for modeling responses in cx_fit function

regionpat_bump = {'pb'};
expat_bump = {'moex*'};
normpat_bump = {'in_rawf_pc_f_cl_rsc_w_*'};

opt.fit.regionpat_fit = {'nor'};
opt.fit.expat_fit = {'mo*'};
% opt.fit.normpat_fit = {'in_cmdffr_pc_f_cl_f_w_null', 'in_rawf_pc_f_cl_rsc_w_yes', 'in_rawf_pc_f_cl_rsc_w_no'};
opt.fit.normpat_fit = {'in_rawf_pc_f_cl_f_w_no'};

opt.fit.sdom.nor = {{'ball', 'vel_r_sm_rsmp'}, {'bump', 'mu'}};
opt.fit.sdom.nol = {{'ball', 'vel_r_sm_rsmp'}, {'bump', 'mu'}};
opt.fit.sdom.pb = {'vis', 'ang_sm_rsmp'};
opt.fit.sdom.fullfov = {'vis', 'raw'};

opt.fit.hsv_background = 'rois'; %'rois' or 'pixels' or 'raw';
opt.fit.synthesize_resp = 0;
opt.fit.epochinds = {[4]};
opt.fit.num_samp_lag = 1; %how many samples stim precedes resp for model fit . . . for now, only nonnegative integers (0 to lenfit_samp - 1)
opt.fit.length_model_seconds = 2; %seconds, 0 is one sample

opt.fit.slvrg = 'globalsearch';
opt.fit.slvrl = 'fmincon'; %'lsqcurvefit';
opt.fit.modeltype = 'glno'; %'svd'; %'gaussian', 'vonmises' 'log' 'linear' 'nonadaptive'
opt.fit.huestr = 'loc'; %loc or amp for modeltype linear . . . loc, amp, or wid for modeltype vonmises or gaussian
opt.fit.lnth = 25; %for modeltype svd
opt.fit.pvar = 0.8; %for modeltype svd

opt.fit.huenorm = 'native'; %hue normalization method, see cx_model_setup
opt.fit.satnorm = 'relative'; %sat normalization method, see cx_model_setup
opt.fit.valnorm = 'relative';%val normalization method, see cx_model_setup
opt.fit.hrange_in_manual = []; %manual range for normalizing hue, prior to normalization to plot scale, whose max range is [0 1]), see cx_form_hsv
opt.fit.srange_in_manual = []; %manual range for normalizing sat, prior to normalization to plot scale, whose max range is [0 1]), see cx_form_hsv
opt.fit.vrange_in_manual = []; %manual range for normalizing val, prior to normalization to plot scale, whose max range is [0 1]), see cx_form_hsv
opt.fit.hrange_out_manual = [0.25 1]; %hue plot scale, whose max range is [0 1] hue hange around color circle, defaults to less than full circle for non-periodic plotting domain, but overwrites in cx_model_setup to [0 1] when plotting periodic param (e.g. von mises center, ie modeltype 'vonmises' huestr 'loc'), see cx_form_hsv
opt.fit.srange_out_manual = [0 1]; %sat plot scale, whose max range is [0 1], if you want to force saturation you can reduce (e.g. [0 0.75] will force smaller range to max saturation, see cx_form_hsv
opt.fit.vrange_out_manual = [0 1];  %val plot scale, whose max range is [0 1], if you want to force value you can reduce (e.g. [0 0.75] will force smaller range to max value, see cx_form_hsv
opt.fit.hueshift = 0; % 0-1, circularly shift the hue map around the color circle for change to arbitrary color assignment, applied before any clipping due to, see cx_form_hsv
opt.fit.ignorehue = 0; %1 ignores it, makes constant 1
opt.fit.ignoresat = 1; %1 ignores it, makes constant 1
opt.fit.ignoreval = 1; %1 ignores it, makes constant 1

opt.fit.responseplot_norm = 'each'; %amplotude normalization for the detail plots at bottom, 'all' normalizes to population, 'each' normalizes to each
opt.fit.maxnumplotinds = 100; %number of rois that get detail view on the bottom, one per gif frame
opt.fit.sort_method = 'unbiased'; %'majoraxis', 'unbiased', 'gof', 'custom'; %how to select rois for detail plots, 'unbiased' for equidistant maxnumplotinds, 'gof' for equidistant maxnumplotinds sorted by gof in descending order (so starts with best fit ends with worst)

opt.fit.standardize_stim = 0;
opt.fit.standardize_resp = 1; %1 makes each response mean=0 variance=1 for fitting model (but still uses original scale for plotting), this is useful for comparing gof (if gof is default of mse, at least) of models fit to responses whose amplitudes differ
opt.fit.smoothresp = 0; %gaussian window std is one fifth total length

opt.fit.gif_visibility = 'on'; %on shows gif while plotting/writing/saving, off saves/writes but doesn't show it
opt.fit.max_tinds = 1000; %1000; %for the timeseries view of responses, how many samples to plot at the most (will take indices 1:max_tinds), big number to plot all
opt.fit.timeseries_numsegments = 3; %how many equispaced segments to display in setail view, ending at final frame

opt.fit.plot_class = 'hsv'; %hsv only shows one epoch per plot/gif frame, epoch shows multiple epochs but no hsv map
opt.fit.excludeopts = '';

opt.fit.plot3d = 0;
opt.fit.doplots = 1;
opt.fit.use_saved_model = 1;

opt.fit = orderfields(opt.fit);

% params for scatterplots
epochinds_scatter = {[1 2 3 4 5]; [1 4]; [2 3]; [1]; [2]; [3]; [4]; [5]};


%params for carl's old project
old_project = 0;
if strcmp(recdate(1:2), '22') %override some settings for old project
    old_project = 1;
    md2.croptimeinds = [4 2]; %same as cropdata in rec6 (also applied in metrics2 without variable name cropdata), crop first 4 and last 2 imaging frames (stimulus features, and deprecated responses, have been extracted with this cropping in rec6)
    no_stim_epochs = 1;
    opt.fit.epochinds = {[1]};
    opt.fit.num_samp_lag = 1; %how many samples stim precedes resp for model fit . . . for now, only nonnegative integers (0 to lenfit_samp - 1)
    opt.fit.length_model_seconds = 1.25;
end


opt.fit.timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS')) ;

%% loop over extraction param sets all recordings matching those

for csi = 1:length(caiman_lr_str_all)

    caiman_lr_str = caiman_lr_str_all{csi};

    fn_pattern = [pth_super '**' filesep recdate '_' fly '_' trial '_' suffix_analysis '_.tif'];
    pth_all = rdir(fn_pattern);
    fn_pattern2 = [fn_pattern(1:end-4) '.mat'];
    pth_all2 = rdir(fn_pattern2);
    pth_all = cat(1, pth_all, pth_all2);

    pth_all = unique(cellfun(@(x) x(1:end-3), {pth_all(:).name}, 'UniformOutput', false));

    for pai = 1:length(pth_all)

        pth_use_tmp = pth_all{pai};

        %% assign filenames

        [pth_fldr, pth_use_mat, pth_stacks_prefix, ...
            pth_hires_prefix, pth_hires_mat_matreg, ...
            pth_roi_func_hires, pth_metadata, ...
            pth_roi_morph, pth_roi_func_all, pth_roi_allmethods, ...
            pth_fictrac, pth_savedata_oneregion, ...
            cropdims_all, roiparsm, roiparsf, ...
            plot_stack_order, plot_stack_gif, ...
            datenum, flynum, trialnum, recid] = ...
            cx_filenames(pth_use_tmp, suffixes_plot, suffix_analysis, use_hires, ...
            numroi_morph_auto, numroi_func, ...
            use_caiman_on_hires, ...
            caiman_lr_str, caiman_hr_str, regionex_all);

        if datenum<20230624
            use_hires(:) = 0;
        end

        if all(isfile(pth_savedata_oneregion)) & skip_existing & ~do_cropping_session %if analysis is already done/saved for all regions, proceed to plotting

            if clsai == length(caiman_lr_str_all)
                cx_plots(pth_savedata_oneregion)
            end

        else %otherwise do analysis for any incomplete regions


            %% load and process stimulus/fictrac data and metadata

            load(pth_metadata) %file created in initial python part of pipeline
            ff = @(x,y) cell2struct([struct2cell(md);struct2cell(md2)],[fieldnames(md);fieldnames(md2)]);
            md = ff(md, md2);
            md.numvol_o = md.numvol;
            md = rmfield(md, 'numvol');
            md.sz_o = [md.ypix md.xpix md.numslice md.numvol_o];
            md.numvol_crop = md.numvol_o - sum(md.croptimeinds);
            md.sz_crop = [md.sz_o(1) md.sz_o(2) md.sz_o(3) md.numvol_crop];

            if isfield(md,'md_hires')
                md.md_hires.sz_o = [md.md_hires.ypix md.md_hires.xpix md.md_hires.numslice md.md_hires.numvol];
                md.md_hires.croptimeinds = [0 0];
                hires_struct_tmp = cell2struct(cellfun(@double,struct2cell(md.md_hires),'uni',false),fieldnames(md.md_hires),1); %make everything double bc python made uint64
                md = rmfield(md, 'md_hires');
            else
                hires_struct_tmp = [];
            end
            md = cell2struct(cellfun(@double,struct2cell(md),'uni',false),fieldnames(md),1); %make everything double bc python made uint64
            md.md_hires = hires_struct_tmp;
            md.xwid = md.xfov / md.xpix; %do this after conversion to double
            % md.zwid = md.zfov / md.numslice; %do this after conversion to double
            md = orderfields(md);

            if old_project
                [md, stim] = cx_load_stim_features(md, datenum, flynum, trialnum, no_stim_epochs, doplots);

            else

                [md, stim] = cx_process_fictrac_data(datenum, flynum, trialnum, md, pth_fictrac, no_stim_epochs, doplots);

            end


            %% load/visualize movies

            stack = cx_vis_tif(md, pth_use_mat, pth_stacks_prefix, ...
                pth_fldr, recid, use_hires, pth_hires_prefix, nan_numlines, ...
                rescale_each_subplot, rescalefac_wholeplot, ...
                plotinds_t, plotinds_z, ...
                swapdim, smooth_window_temporal, ...
                plot_stack_stats, plot_stack_order, plot_stack_gif, ncolgif);

            if ndims(stack)~=4
                error(sprintf("ERROR, \nTHIS PIPELINE REQUIRES stack TO BE 4D (xyzt), EVEN IF SOME DIM (e.g., 3rd dim z) ARE SINGLETON"))
            end


            %% load high resolution movie

            if any(use_hires)

                [stack_hires_mnt, map_hires_lores] = cx_load_hires_stack(pth_hires_prefix, ...
                    pth_hires_mat_matreg, stack, md, use_caiman_on_hires, ...
                    pth_roi_func_hires);

            end

            %% rois/responses

            clear resp

            stack_mnt = cell(length(regionex_all), 1);
            for rei = 1:length(regionex_all) %for each region with extracted rois
                if ~isfile(pth_savedata_oneregion{rei}) & ~skip_existing

                    %% crop data

                    regionex = regionex_all{rei};
                    cropdims = cropdims_all{rei};
                    if ~isempty(cropdims)
                        stackcrop = single(stack(cropdims(1):cropdims(2), cropdims(3):cropdims(4), cropdims(5):cropdims(6), :));
                    else
                        [stackcrop, cropdims] = cx_make_croplim(single(stack), md.sz_crop(4), pth_fldr, recid, regionex_all{rei});
                        cropdims_all{rei} = cropdims;
                    end

                    stack_mnt{rei} = mean(stackcrop, 4);

                    if use_hires(rei)
                        if ~isempty(cropdims)
                            zinds_hires = ismember(map_hires_lores, cropdims(5):cropdims(6));
                            map_hires_lores_crop = map_hires_lores(zinds_hires) - (min(cropdims(5):cropdims(6))-1);
                            hiresmntcrop = single(stack_hires_mnt(cropdims(1):cropdims(2), cropdims(3):cropdims(4), zinds_hires));
                        else
                            map_hires_lores_crop = map_hires_lores;
                            hiresmntcrop = stack_hires_mnt;
                        end
                    else
                        hiresmntcrop = [];
                        map_hires_lores_crop = [];
                    end

                    if ~isa(stackcrop, 'single') & ~isa(stackcrop, 'double') & ( use_hires(rei) & ~isa(hiresmntcrop, 'single') & ~isa(hiresmntcrop, 'double') )
                        error("stacks need to be single or double, there are negatives coming soon")
                    end

                    %% make (manual and automated) morphological rois in 2d and 3d

                    [roiinfo.(regionex).(roiparsm{rei})] = ...
                        cx_make_morphological_rois(stackcrop, use_drawn_rois(rei), ...
                        numroi_morph_auto(rei), md.xwid, md.zwid, pth_use_mat, ...
                        hiresmntcrop, map_hires_lores_crop, regionex, doplots);

                    if ~do_cropping_session

                        %% compute morphological roi responses

                        resp.(regionex).(roiparsm{rei}) = ...
                            cx_extract_roi_responses(stackcrop, ...
                            roiinfo.(regionex).(roiparsm{rei}).mask_roi_vec, ...
                            md.f0_pct, pth_roi_morph{rei}, response_normalization_string, ...
                            normalize_before_roi_clustering, normalize_after_roi_clustering, doplots);


                        %% compute functional (caiman) roi responses

                        for rfi = 1:length(pth_roi_func_all{rei})

                            %assign previously extracted functional rois to any morphological rois
                            [roiinfo.(regionex).(roiparsf{rei}{rfi}), resp_roi_func] = ...
                                cx_load_functional_rois(pth_roi_func_all{rei}{rfi}, stack_mnt{rei}, ...
                                roiinfo.(regionex).(roiparsm{rei}).centroids_roi, ...
                                roiinfo.(regionex).(roiparsm{rei}).mask_allroi, ...
                                regionex, md.croptimeinds, doplots);

                            %this version not weighted by area by passing pixinds_roi_func
                            resp.(regionex).(roiparsf{rei}{rfi}) = ...
                                cx_extract_roi_responses(resp_roi_func, ...
                                roiinfo.(regionex).(roiparsf{rei}{rfi}).mask_roi_vec, ...
                                md.f0_pct, pth_roi_func_all{rei}{rfi}, response_normalization_string, ...
                                normalize_before_roi_clustering, normalize_after_roi_clustering, doplots);

                            %this version weighted by area by passing pixinds_roi_func_wt (appends to existing resp)
                            resp.(regionex).(roiparsf{rei}{rfi}) = ...
                                cx_extract_roi_responses(resp_roi_func, ...
                                roiinfo.(regionex).(roiparsf{rei}{rfi}).mask_roi_vec_wt, ...
                                md.f0_pct, pth_roi_func_all{rei}{rfi}, response_normalization_string, ...
                                normalize_before_roi_clustering, normalize_after_roi_clustering, doplots, resp.(regionex).(roiparsf{rei}{rfi}));

                        end


                    end
                end
            end

            %% bump

            if ~do_cropping_session

                for rei = 1:length(regionex_all) %for each region with extracted rois, loop over extraction and normalization runs
                    if ~isfile(pth_savedata_oneregion{rei}) & ~skip_existing
                        regionex = regionex_all{rei};
                        cropdims = cropdims_all{rei};
                        stackcrop = single(stack(cropdims(1):cropdims(2), cropdims(3):cropdims(4), cropdims(5):cropdims(6), :));
                        countz = 0;
                        extraction_params_all = fieldnames(resp.(regionex)); %resp{1} has fewer fieldnames because it doens't have weighted and nonweighted versions (bc there's only 1 roi per morphological roi)
                        for epi = 1:length(extraction_params_all) %for each extraction
                            extraction_params = extraction_params_all{epi};
                            norm_params_all = fieldnames(resp.(regionex).(extraction_params_all{epi})); %resp{1} has fewer fieldnames because it doens't have weighted and nonweighted versions (bc there's only 1 roi per morphological roi)
                            for npi = 1:length(norm_params_all) %for each response normalization
                                norm_params = norm_params_all{npi};
                                if any(~cellfun(@isempty, regexp(extraction_params, regexptranslate('wildcard', expat_bump)))) && ...
                                        any(~cellfun(@isempty, regexp(norm_params, regexptranslate('wildcard', normpat_bump)))) && ...
                                        any(~cellfun(@isempty, regexp(regionex, regexptranslate('wildcard', regionpat_bump)))) %only compute bump and offset for pb right now

                                    fn_save_prefix = [pth_roi_allmethods{rei}{epi}(1:end-4) norm_params];

                                    bump.(regionex).(extraction_params).(norm_params) = ...
                                        cx_bump_pva(stackcrop, resp.(regionex).(extraction_params).(norm_params), ...
                                        stim.(opt.fit.sdom.(regionex){1}).(opt.fit.sdom.(regionex){2}), ...
                                        numroi_func(rei), fn_save_prefix, md.smoothwindow_i, md.stimepochinds_i, md.dt_i_mean, ...
                                        roiinfo.(regionex).(extraction_params_all{epi}).pixinds_roi, ...
                                        roiinfo.(regionex).(extraction_params_all{epi}).mapind2ind, ...
                                        opt.fit, doplots);

                                end
                            end
                        end
                    end
                end

                %% model/predict

                clear params_all

                for rei = 1:length(regionex_all) %for each region with extracted rois, loop over extraction and normalization runs
                    if ~isfile(pth_savedata_oneregion{rei}) & ~skip_existing

                        regionex = regionex_all{rei};
                        cropdims = cropdims_all{rei};
                        stackcrop = single(stack(cropdims(1):cropdims(2), cropdims(3):cropdims(4), cropdims(5):cropdims(6), :));

                        countz = 0;
                        extraction_params_all = fieldnames(resp.(regionex)); %resp{1} has fewer fieldnames because it doens't have weighted and nonweighted versions (bc there's only 1 roi per morphological roi)
                        for epi = 1:length(extraction_params_all) %for each extraction
                            norm_params_all = fieldnames(resp.(regionex).(extraction_params_all{epi})); %resp{1} has fewer fieldnames because it doens't have weighted and nonweighted versions (bc there's only 1 roi per morphological roi)
                            for npi = 1:length(norm_params_all) %for each response normalization
                                if any(~cellfun(@isempty, regexp(extraction_params_all{epi}, regexptranslate('wildcard', opt.fit.expat_fit)))) && ...
                                        any(~cellfun(@isempty, regexp(norm_params_all{npi}, regexptranslate('wildcard', opt.fit.normpat_fit)))) && ...
                                        any(~cellfun(@isempty, regexp(regionex, regexptranslate('wildcard', opt.fit.regionpat_fit)))) %only compute bump and offset for pb right now

                                    countz = countz + 1;
                                    params_all.(regionex){countz, 1} = extraction_params_all{epi};
                                    params_all.(regionex){countz, 2} = epi;
                                    params_all.(regionex){countz, 3} = norm_params_all{npi};
                                    params_all.(regionex){countz, 4} = npi;

                                    fn_save_prefix = [pth_roi_allmethods{rei}{epi}(1:end-4) norm_params];
                                     
                                    % resptmp = cx_choose_responses(resp, regionex, ...
                                    %     extraction_params_all{epi}, norm_params_all{npi}, ...
                                    %     extraction_method_supplemental, rescale_resp);



                                    opt.fit.use_saved_model = 0;
                                    opt.fit.modeltype = 'glno4';
                                    opt.fit.modeltype = 'svd';
                                    opt.fit.length_model_seconds = 2;
                                    
                                    stimfit(1,:) = stim.(opt.fit.sdom.(regionex){1}{1}).(opt.fit.sdom.(regionex){1}{2});
                                    stimfit(2,:) = bump.pb.(extraction_params).('in_rawf_pc_f_cl_rsc_w_yes').all.mu;
                                    % 
                                    % stimfit(1,:) = stim.(opt.fit.sdom.(regionex){1}{1}).(opt.fit.sdom.(regionex){1}{2});
                                    
                                    [fittmp, goftmp] = ...
                                        cx_fit(stackcrop, stimfit, ...
                                        resp.(regionex).(extraction_params_all{epi}).(norm_params_all{npi}), ...
                                        roiinfo.(regionex).(extraction_params_all{epi}).pixinds_roi, ...
                                        roiinfo.(regionex).(extraction_params_all{epi}).mapind2ind, ...
                                        md.stimepochinds_i, md.dt_i_mean, fn_save_prefix, opt.fit);

                                    % [roi_is_not_selective] = cx_test_roi_selectivity(resp, vis, ball, md, regionex, pth_caimanrois, doplots2);
                                    % good_roi_indices = good_roi_indices & ~roi_is_not_selective;


                                    %% scatterplots
                                    % 
                                    % cx_scatterplots(vis.(visang_str), vis.(visvel_str), ball.(ballang_str), ball.(ballvel_str), ...
                                    %     bumptmp.mu, bumptmp.rho, bumptmp.vel, bumptmp.ampmean, bumptmp.amppeak, bumptmp.ampmu, ...
                                    %     resp_gar, resp_gal, resp_nor, resp_nol, resp_ga_mean, resp_no_mean, ...
                                    %     ti, tb, stimepochinds_i, stimepochinds_b, epochinds_scatter, fn_prefix, gif_visibility)
                                    % 


                                    %% plot experiment 

                                    % sorting_targets = {'none'}; %{'none', 'mu'}
                                    % for mji = 1:length(sorting_targets)
                                    % 
                                    %     sorting_target = sorting_targets{mji};
                                    % 
                                    %     if strcmp(sorting_target, 'none') %if not sorting
                                    %         numfram = 1e10;
                                    %         for epi = 1:length(epochinds_plot) %find min epoch length, and plot that many frames (so they can be contiguous)
                                    %             numfram = min([numfram numel(find(stimepochinds_i==epochinds_plot(epi)))]);
                                    %         end
                                    %     else
                                    %         numfram = 150; %if sorting, plot less (not strictly necessary, could plot all)
                                    %     end
                                    % 
                                    % 
                                    %     mask_with_3d_mask = 0;
                                    %     plot_only_outliers = 0; %in the raw fluorescence 3d movie
                                    %     bump_method_index_save = 1; %keep at 1 right now, not written yet to vary
                                    %     bump_method_index_plot = 1; %keep at 1 right now, not written yet to vary
                                    %     pltindz = [1];%[1 2]; %keep at 1 right now, not written yet to vary %indices of fi below
                                    %     ncol = 128; %num colors in gifs
                                    %     makeroomfac_mu = 0.1;
                                    %     makeroomfac_rho = 0.1;
                                    %     epochinds_plot = [2 3 4];
                                    %     percentile_to_plot = 99.5;
                                    %     plotcolz = {[1 0 0], [0.4660 0.6740 0.1880], [0 1 0]};
                                    %     startsec = 1; %only relevant if dosort=0
                                    %     stopsec = 20; %only relevant if dosort=0
                                    %     xlim_makeroomfac = 0.1;
                                    %     nanpadlen_min_input = 20;
                                    %     gif_visibility = 'on';
                                    %     separate_vis_and_bump = 0;
                                    % 
                                    %     % "DONT FORGET ROTATE THE MASK PLOT POSTERIOR TO SHOW ALL GLOM"
                                    %     % cx_plot_bump(alpha_plot, resp_plot, mu_plot, rho_plot, visang, ballang, ...
                                    %     %     ampmu_plot, amppeak_plot, ampmean_plot, resp_gar, resp_gal, resp_nor, resp_nol, ...
                                    %     %     epochinds_plot, md, centinds, halfcent, pltindz, numfram, startsec, stopsec,  ...
                                    %     %     imdata, percentile_to_plot, mask_roi_morph, mask_with_3d_mask, inds_roi, plot_only_outliers, ...
                                    %     %     plotcolz, xlim_makeroomfac, makeroomfac_rho, makeroomfac_mu, ncol, ...
                                    %     %     gif_visibility, separate_vis_and_bump, sorting_target, ...
                                    %     %     bump_method_index_plot, fn_prefix, nanpadlen_min_input)
                                    % 
                                    % end


                                end
                            end
                        end

                        %save(filename_sd{rei}, 'resp', 'vis', 'bump', 'ball', 'offset', 'md', 'regionex', 'cropdims', 'params_all', 'timestr', '-v7.3', '-mat')

                    end
                end

                % if ~isfile(filename_sd_all) | ~skip_existing
                %     save(filename_sd_all, 'resp', 'vis', 'bump', 'ball', 'offset', 'md', 'regionex', 'cropdims', 'params_all', 'timestr', '-v7.3', '-mat')
                % end
                % if clsai == length(caiman_lr_str_all) & ~do_cropping_session
                %     cx_plots(filename_sd)
                % end

            end
        end
    end
end

