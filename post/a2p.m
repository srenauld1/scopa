

clear all
close all
clc

disp("make hemisphere option (eg option to analyze left or right or both)")
disp("fix hsv spec for internal periodic components (vonmises in fnet gets periodic hue spec)")
disp("need to make fitmdl_parse_mdlname_string run with other inputs ignored during param setting to check the syntax (so you don't find out later, halfway through the pipeline")
disp("allow recursive mdl")
disp("constrain amplitude of all intermediate functions")
disp("time in all functions")
%%%%%%% scopa 'post' pipeline for analyzing data output from scopa 'pre' pipeline

% variables are organized into structs to reduce complexity
% variables are sometimes unpacked/repacked when entering/exiting functions in which they're used, unless they are used infrequently, or they are large and must be modified in a way that requires indexing

% struct 'opt' holds input params in various sub-structs, which are each used predominantly in a function below
% struct 'ts' holds timeseries (in various sub-structs) with indices corresponding to md.ti (imaging frame timestamps)
% struct 'roiinfo' holds roi info for morphological and functional rois
% struct 'md' holds metadata
% struct 'paths' holds paths
% numeric array 'stack' is the imaging movie chosen for analysis (using 'opt.main.suffix_analysis')

% struct 'opt.fit' holds options that do not change across all calls function 'fitmdl'
% struct 'fitin' (stands for 'fit input') holds data (e.g. depv & indv) used in each individual call to function 'fitmdl' (can change across calls)


% in variable names
%   prefix, infix, or suffix 'ts' denotes 'timeseries'
%   suffix '*_i' denotes imaging sampling, suffix '*_b' denotes behavior sampling (suffix can be used for timeseries variable, or variable used exclusively with one or the other sampling regimes)
%   suffix '*_m' denotes model sampling (e.g., in a linear model integrating 5 imaging samples into the past, num_samp

%% params


opt = input_params_carl();

%% loop over recordings

[pth_usefile_prefix_all, pth_grandparent] = find_preprocessed_files(opt.main);

for pai = 1:length(pth_usefile_prefix_all) %for each recording

    resp = [];
    pars_all = [];

    %% assign filenames

    [opt, pth, croplim_all, parstr, ids] = filenames_a2p(opt, pth_usefile_prefix_all{pai}, pth_grandparent);


    %% load metadata

    md = load_scanimage_metadata(pth.metadata, opt.md);
    md = load_flyg_metadata(ids, pth.fldr, md);


    %% load and process daq 

    if opt.main.old_project
        [md, ts.vis] = load_stim(md, ids, opt.daq);
    else
        if ~opt.daq.ignore_daq
            try
                load(pth.daq_resamp, 'daqdata_resamp')
            catch
                daqdata_resamp = load_DAQ(ids.datenum, ids.flynum, ids.trialnum, md.numvol_o, md.numslice_withflyback, ...
                    md.dtmni, md.ball_diameter, pth.daq, pth.daq_resamp, ...
                    opt.daq.slopelen_sec, opt.daq.slopeorder, opt.daq.fast_version, opt.daq.doplots);
            end
            [ts.ball, ts.vis, md.ti] = assign_a2p_timeseries(daqdata_resamp);
            [md.epochs, ts.vis] = load_stim_epochs(md.ti, pth.epochinfo, ts.vis, pth.fldr, ids, md.dtmni, daqdata_resamp, opt.daq.use_carls_epochs);
        end
    end


    %% load/visualize movies (stacks)


    stack = load_stack(md, pth, opt.gif, ids.recid);


    %% load high resolution movie (stack)

    if any(cell2mat(struct2cell(opt.mroi.use_hires)))
        [stack_hires_mnt, map_hires_lores] = load_hires_stack(ids.recid, pth, stack, md, opt.hires);
    else
        stack_hires_mnt = [];
        map_hires_lores = [];
    end

    %% create/load/select rois/responses for each regionex

    for rei = 1:length(opt.main.regionex_all) %for each regionex

        regionex = opt.main.regionex_all{rei};

        %%crop movie to regionex cuboid
        [stackcrop, stack_mnt.(regionex), map_hires_lores_crop, hiresmntcrop, croplim_all.(regionex), pth.mroi.(regionex)] = ...
            crop_stacks(stack, croplim_all.(regionex), ids.recid, regionex, pth.fldr, pth.tmpfiles, ...
            md.sz_crop, opt.mroi.use_hires.(regionex), stack_hires_mnt, map_hires_lores, pth.mroi.(regionex));

        %%make (manual and/or automated) morphological rois in 2d or 3d, and extract their responses
        [roiinfo.(regionex).(parstr.mroi.(regionex)), ts.resp.(regionex).(parstr.mroi.(regionex))] = ...
            make_morphological_rois(stackcrop, stack_mnt.(regionex), opt.mroi, md, pth, hiresmntcrop, map_hires_lores_crop, regionex, parstr.mroi.(regionex));


        %%load/select functional (caiman) roi responses
        for rfi = 1:length(pth.froi_all.(regionex)) %for each caiman extraction run (each roi file)
            [roiinfo.(regionex).(parstr.froi.(regionex){rfi}), ts.resp.(regionex).(parstr.froi.(regionex){rfi})] = ...
                process_functional_rois(stack_mnt.(regionex), roiinfo.(regionex).(parstr.mroi.(regionex)), ...
                pth.froi_all.(regionex){rfi}, regionex, md, opt.froi);
        end

    end

    %% compute population features (e.g. bump), add them to ts

    pffn = fieldnames(opt.pf);
    for pfi = 1:numel(pffn)
        ts = compute_population_feature(pffn{pfi}, ts, stack, croplim_all, roiinfo, opt.pf.(pffn{pfi}), md, pth);
    end

    %% model/predict


    for si = 1:numel(opt.fit)
        dofit = 1;
        fitcount = 0;
        while dofit && opt.fit(si).do

            fitcount = fitcount + 1;
            [fitin, dofit] = choose_timeseries(opt.fit(si), ts, md, pth.tsuse.fit, pth.stack_analysis, fitcount, dofit); %select indv/depv for fit using input params
            stackcrop = crop_stacks(stack, croplim_all.(fitin.regionex)); %crop stack based on regionex of the depv (stack for plots, not model)

            opt.fit.mdlname = 'fnet_A01_xsie_A02_xsie_B01-02_f_B03-04_f';
            opt.fit.mdlname = 'fnet_A01_s_A02_s_B_h16';
            opt.fit.mdlname = 'fnet_A_xsie';
            opt.fit.validation_fold = 0; opt.fit.use_saved_model = 1; opt.fit.mdl_length_sec = 2; opt.fit.num_synthetic_depv = 0; opt.fit.epochinds = {[2 3 4]};
            fitin = fitmdl(stackcrop, fitin, roiinfo.(fitin.regionex).(fitin.parsex), md, opt.fit(si)); %fit model using any available timeseries

        end
    end


    %% scatterplots

    if opt.scatter.do
        scatterplots(ts, opt.scatter, fn_save_prefix) %3d scatterplots (2d plus color) of all available timeseries
    end

    %% summary plot

    % plot_experiment


end

