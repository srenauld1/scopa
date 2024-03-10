

clear all
close all
clc

disp("see ricker.m for 1d filter option")
disp("change reample bump to 4pi")
disp("does 2pi ever appear twice as 0 and 1??")
disp("make hemisphere no hemisphere option")


%%%%%%% scopa 'post' pipeline for analyzing data output from scopa 'pre' pipeline

% struct 'opt' holds input params in various sub-structs, which are each used predominantly in a function below
% struct 'ts' holds timeseries (in various sub-structs) with indices corresponding to md.ti (imaging frame timestamps)
% struct 'roiinfo' holds roi info for morphological and functional rois
% struct 'md' holds metadata
% struct 'paths' holds paths
% numeric array 'stack' is the imaging movie chosen for analysis (using 'opt.main.suffix_analysis')

%% params


opt = input_params_carl(); %input_params_default();


%% loop over files

pth_usefile_prefix_all = find_preprocessed_files(opt.main);

for pai = 1:length(pth_usefile_prefix_all)

    resp = [];
    pars_all = [];

    %% assign filenames

    [opt, pth, croplim_all, pars_mroi, pars_froi, datenum, flynum, trialnum, recid] = filenames_scopa(opt, pth_usefile_prefix_all{pai});

    %% load metadata

    md = load_metadata(pth.metadata, opt.md);

    %% load and process stimulus/fictrac data

    
    if opt.main.old_project
        [md, ts.vis] = load_stim(md, datenum, flynum, trialnum, opt.ftrac);
    else
        if opt.ftrac.include_behavior
            [md, ts.ball, ts.vis] = load_fictrac(datenum, flynum, trialnum, md, pth.fictrac, opt.ftrac);
        end
    end


    %% load/visualize movies (stacks)


    stack = load_stack(md, pth, opt.gif, recid);


    %% load high resolution movie (stack)

    if any(cell2mat(struct2cell(opt.mroi.use_hires)))
        [stack_hires_mnt, map_hires_lores] = load_hires_stack(recid, pth, stack, md, opt.hires);
    else
        stack_hires_mnt = [];
        map_hires_lores = [];
    end

    %% create/load/select rois/responses for each regionex 

    for rei = 1:length(opt.main.regionex_all) %for each regionex

        regionex = opt.main.regionex_all{rei};

        %%crop movie to regionex cuboid
        [stackcrop, stack_mnt.(regionex), map_hires_lores_crop, hiresmntcrop] = ...
            crop_stacks(stack, croplim_all.(regionex), recid, regionex, pth.fldr, ...
            md.sz_crop, opt.mroi.use_hires.(regionex), stack_hires_mnt, map_hires_lores);


        %%make (manual and/or automated) morphological rois in 2d or 3d, and extract their responses
        [roiinfo.(regionex).(pars_mroi.(regionex)), ts.resp.(regionex).(pars_mroi.(regionex))] = ...
            make_morphological_rois(stackcrop, opt.mroi, md, pth, hiresmntcrop, map_hires_lores_crop, regionex);


        %%load/select functional (caiman) roi responses
        for rfi = 1:length(pth.froi_all.(regionex)) %for each caiman extraction run (each roi file)
            [roiinfo.(regionex).(pars_froi.(regionex){rfi}), ts.resp.(regionex).(pars_froi.(regionex){rfi})] = ...
                process_functional_rois(stack_mnt.(regionex), roiinfo.(regionex).(pars_mroi.(regionex)), ...
                pth.froi_all.(regionex){rfi}, regionex, md, opt.froi);
        end


    end

    %% bump

    dofit = 1;
    fitcount = 0;
    while dofit

        fitcount = fitcount + 1;
        [fitin, fieldspecstr, dofit] = choose_timeseries(opt.bump.fit, ts, md, pth.parsall_bump, pth.stack_analysis, fitcount, dofit);  %select indv/depv for fit using input params

        stackcrop = crop_stacks(stack, croplim_all.(fitin.regionex)); %crop stack based on regionex of the depv (stack for plots, not model)

        ts.bump.(fitin.regionex).(fitin.parsex).(fitin.parsnorm) = compute_bump(stackcrop, fitin, roiinfo.(fitin.regionex).(fitin.parsex), opt.bump, md, regionex); %fit bump

    end

    %% model/predict

    dofit = 1;
    fitcount = 0;
    while dofit

        fitcount = fitcount + 1;
        [fitin, fieldspecstr, dofit] = choose_timeseries(opt.fit, ts, md, pth.parsall_fit, pth.stack_analysis, fitcount, dofit); %select indv/depv for fit using input params

        stackcrop = crop_stacks(stack, croplim_all.(fitin.regionex)); %crop stack based on regionex of the depv (stack for plots, not model)

        [fittmp, goftmp] = fitmdl(stackcrop, fitin, roiinfo.(fitin.regionex).(fitin.parsex), md, opt.fit); %fit model using any available timeseries

    end


    %% scatterplots

    scatterplots(ts, opt.scatter, fn_save_prefix) %3d scatterplots (2d plus color) of all available timeseries


    %% summary plot

    % plot_experiment


end

