

clear all
close all
clc

disp("see ricker.m for 1d filter option")
disp("change reample bump to 4pi")
disp("does 2pi ever appear twice as 0 and 1??")
disp("make hemisphere no hemisphere option")

%remove weighting 
%fix normalization strings 
%simplify scatterplots
%fix plot bump
%plot experiment
%include flyg gui 
%index into epochs during experiment, save at end, then get rid of find epochs functions  

%%%%%%% scopa 'post' pipeline for analyzing data output from scopa 'pre' pipeline

% struct 'opt' holds input params in various sub-structs, which are each used predominantly in a function below 
% struct 'ts' holds timeseries (in various sub-structs) with indices corresponding to md.ti (imaging frame timestamps)  
% struct 'roiinfo' holds roi info for morphological and functional rois 
% struct 'md' holds metadata
% struct 'paths' holds paths
% numeric array 'stack' is the imaging movie chosen for analysis (using 'opt.main.suffix_analysis')

%% params


opt = input_params();


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
    end

    %% rois/responses for each regionex


    for rei = 1:length(opt.main.regionex_all) %for each regionex

            %% crop movie to regionex cuboid

            regionex = opt.main.regionex_all{rei};
            [stackcrop, stack_mnt.(regionex), map_hires_lores_crop, hiresmntcrop] = ...
                crop_stacks(stack, croplim_all.(regionex), recid, regionex, pth.fldr, ...
                    md.sz_crop, opt.mroi.use_hires.(regionex), stack_hires_mnt, map_hires_lores);


            %% make (manual and automated) morphological rois in 2d or 3d, extract their responses

            [roiinfo.(regionex).(pars_mroi.(regionex)), ts.resp.(regionex).(pars_mroi.(regionex))] = ...
                make_morphological_rois(stackcrop, opt.mroi, md, pth, hiresmntcrop, map_hires_lores_crop, regionex);


            %% load/process functional (caiman) roi responses

            for rfi = 1:length(pth.froi_all.(regionex)) %for each caiman extraction run
                [roiinfo.(regionex).(pars_froi.(regionex){rfi}), ts.resp.(regionex).(pars_froi.(regionex){rfi})] = ...
                    process_functional_rois(stack_mnt.(regionex), roiinfo.(regionex).(pars_mroi.(regionex)), ...
                        pth.froi_all.(regionex){rfi}, regionex, md, opt.froi);
            end


    end

    %% bump


    for rei = 1:length(opt.main.regionex_all) %for each regionex
        
        regionex = opt.main.regionex_all{rei};
        stackcrop = crop_stacks(stack, croplim_all.(regionex));

        countz = 0;
        parsex_all = fieldnames(ts.resp.(regionex)); 
        for epi = 1:length(parsex_all) %for each extraction
            parsex = parsex_all{epi};
            parsnorm_all = fieldnames(ts.resp.(regionex).(parsex)); 
            for npi = 1:length(parsnorm_all) %for each response normalization
                parsnorm = parsnorm_all{npi};
                if any(~cellfun(@isempty, regexp(parsex, regexptranslate('wildcard', opt.bump.expat)))) && ...
                        any(~cellfun(@isempty, regexp(parsnorm, regexptranslate('wildcard', opt.bump.normpat)))) && ...
                        any(~cellfun(@isempty, regexp(regionex, regexptranslate('wildcard', opt.bump.regionpat)))) 

                    fn_save_prefix = [pth.roi_allmethods.(regionex){epi}(1:end-4) parsnorm];

                    ts.bump.(regionex).(parsex).(parsnorm) = ...
                        compute_bump(stackcrop, ... %imaging movie
                            ts.resp.(regionex).(parsex).(parsnorm), ... %dependent var
                            ts.vis.angsd, ... %independent var
                            roiinfo.(regionex).(parsex), ...
                            opt.bump, md, fn_save_prefix, regionex);

                end
            end
        end
    end

    %% model/predict

    for rei = 1:length(opt.main.regionex_all) %for each region 

        regionex = opt.main.regionex_all{rei};
        stackcrop = crop_stacks(stack, croplim_all.(regionex));

        countz = 0;
        parsex_all = fieldnames(ts.resp.(regionex));
        for epi = 1:length(parsex_all) %for each extraction
            parsex = parsex_all{epi};
            parsnorm_all = fieldnames(ts.resp.(regionex).(parsex));
            for npi = 1:length(parsnorm_all) %for each normalization
                parsnorm = parsnorm_all{npi};
                if any(~cellfun(@isempty, regexp(parsex, regexptranslate('wildcard', opt.fit.expat)))) && ...
                        any(~cellfun(@isempty, regexp(parsnorm, regexptranslate('wildcard', opt.fit.normpat)))) && ...
                        any(~cellfun(@isempty, regexp(regionex, regexptranslate('wildcard', opt.fit.regionpat))))

                    countz = countz + 1;
                    pars_all.(regionex)(countz,:) = {parsex, epi, parsnorm, npi};
                    fn_save_prefix = [pth.roi_allmethods.(regionex){epi}(1:end-4) parsnorm];

                    opt.fit.use_saved_model = 1;
                    opt.fit.modeltype = 'glno4';
                    opt.fit.length_model_seconds = 2;

                    indv(1,:) = ts.(opt.fit.indv.(regionex){1}{1}).(opt.fit.indv.(regionex){1}{2});
                    indv(2,:) = ts.bump.pb.(parsex).(parsnorm).all.mu;
                    % indv(1,:) = ts.(opt.fit.indv.(regionex){1}{1}).(opt.fit.indv.(regionex){1}{2});

                    depv = ts.resp.(regionex).(parsex).(parsnorm);

                    [fittmp, goftmp] = fitmdl(stackcrop, indv, depv, ...
                        roiinfo.(regionex).(parsex), md, fn_save_prefix, opt.fit);

                    % [roi_is_not_selective] = test_roi_selectivity(resp, ts.vis, ts.ball, md, regionex, pth.caimanrois, doplots2);
                    % good_roi_indices = good_roi_indices & ~roi_is_not_selective;


                    %% scatterplots

                    scatterplots(ts, opt.scatter, fn_save_prefix)


                    %% summary plot

                    % plot_experiment

                end
            end
        end

        %save_scopa_env()

    end


end

