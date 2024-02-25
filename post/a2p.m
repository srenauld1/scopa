

clear all
close all
clc

disp("see ricker.m for 1d filter option")
disp("change reample bump to 4pi")
disp("does 2pi ever appear twice as 0 and 1??")

%remove weighting 
%fix normalization strings 
%simplify scatterplots
%fix plot bump
%plot experiment
%include flyg gui 

%%%%%%% scopa 'post' pipeline for analyzing data output from scopa 'pre' pipeline



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
        [md, stim] = load_stim(md, datenum, flynum, trialnum, opt.ft);
    else
        if opt.ft.include_behavior
            [md, stim] = load_fictrac(datenum, flynum, trialnum, md, pth.fictrac, opt.ft);
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

            [roiinfo.(regionex).(pars_mroi.(regionex)), resp.(regionex).(pars_mroi.(regionex))] = ...
                make_morphological_rois(stackcrop, opt.mroi, md, pth, hiresmntcrop, map_hires_lores_crop, regionex);


            %% load/process functional (caiman) roi responses

            for rfi = 1:length(pth.froi_all.(regionex)) %for each caiman extraction run
                [roiinfo.(regionex).(pars_froi.(regionex){rfi}), resp.(regionex).(pars_froi.(regionex){rfi})] = ...
                    process_functional_rois(stack_mnt.(regionex), roiinfo.(regionex).(pars_mroi.(regionex)), ...
                        pth.froi_all.(regionex){rfi}, regionex, md, opt.froi);
            end


    end

    %% bump


    for rei = 1:length(opt.main.regionex_all) %for each regionex
        
        regionex = opt.main.regionex_all{rei};
        stackcrop = crop_stacks(stack, croplim_all.(regionex));

        countz = 0;
        parsex_all = fieldnames(resp.(regionex)); 
        for epi = 1:length(parsex_all) %for each extraction
            extraction_params = parsex_all{epi};
            parsnorm_all = fieldnames(resp.(regionex).(parsex_all{epi})); 
            for npi = 1:length(parsnorm_all) %for each response normalization
                norm_params = parsnorm_all{npi};
                if any(~cellfun(@isempty, regexp(extraction_params, regexptranslate('wildcard', opt.bump.expat)))) && ...
                        any(~cellfun(@isempty, regexp(norm_params, regexptranslate('wildcard', opt.bump.normpat)))) && ...
                        any(~cellfun(@isempty, regexp(regionex, regexptranslate('wildcard', opt.bump.regionpat)))) 

                    fn_save_prefix = [pth.roi_allmethods.(regionex){epi}(1:end-4) norm_params];

                    bump.(regionex).(extraction_params).(norm_params) = ...
                        compute_bump(stackcrop, resp.(regionex).(extraction_params).(norm_params), ...
                            stim.(opt.fit.sdom.(regionex){1}).(opt.fit.sdom.(regionex){2}), ...
                            numcluster_for_bump_domain_resample.(regionex), fn_save_prefix, md.stimepochinds_i, md.dtmni, ...
                            roiinfo.(regionex).(parsex_all{epi}).pixinds_roi, ...
                            roiinfo.(regionex).(parsex_all{epi}).mapind2ind, ...
                            opt.bump, opt.fit, doplots);

                end
            end
        end
    end

    %% model/predict

    for rei = 1:length(opt.main.regionex_all) %for each region with extracted rois, loop over extraction and normalization runs

        regionex = opt.main.regionex_all{rei};
        stackcrop = crop_stacks(stack, croplim_all.(regionex));

        countz = 0;
        parsex_all = fieldnames(resp.(regionex)); 
        for epi = 1:length(parsex_all) %for each extraction
            parsnorm_all = fieldnames(resp.(regionex).(parsex_all{epi}));
            for npi = 1:length(parsnorm_all) %for each response normalization
                if any(~cellfun(@isempty, regexp(parsex_all{epi}, regexptranslate('wildcard', opt.fit.expat)))) && ...
                        any(~cellfun(@isempty, regexp(parsnorm_all{npi}, regexptranslate('wildcard', opt.fit.normpat)))) && ...
                        any(~cellfun(@isempty, regexp(regionex, regexptranslate('wildcard', opt.fit.regionpat))))

                    countz = countz + 1;
                    pars_all.(regionex)(countz,:) = {parsex_all{epi}, epi, parsnorm_all{npi}, npi};
                    fn_save_prefix = [pth.roi_allmethods.(regionex){epi}(1:end-4) norm_params];

                    opt.fit.use_saved_model = 1;
                    opt.fit.modeltype = 'glno4';
                    opt.fit.length_model_seconds = 2;

                    stimfit(1,:) = stim.(opt.fit.sdom.(regionex){1}{1}).(opt.fit.sdom.(regionex){1}{2});
                    stimfit(2,:) = bump.pb.(extraction_params).('in_rawf_pc_f_cl_rsc_w_yes').all.mu;
                    % stimfit(1,:) = stim.(opt.fit.sdom.(regionex){1}{1}).(opt.fit.sdom.(regionex){1}{2});

                    [fittmp, goftmp] = fitresp(stackcrop, stimfit, ...
                        resp.(regionex).(parsex_all{epi}).(parsnorm_all{npi}), ...
                        roiinfo.(regionex).(parsex_all{epi}).pixinds_roi, ...
                        roiinfo.(regionex).(parsex_all{epi}).mapind2ind, ...
                        md.stimepochinds_i, md.dtmni, fn_save_prefix, opt.fit);

                    % [roi_is_not_selective] = test_roi_selectivity(resp, vis, ball, md, regionex, pth.caimanrois, doplots2);
                    % good_roi_indices = good_roi_indices & ~roi_is_not_selective;


                    %% scatterplots

                    scatterplots(vis.(visang_str), vis.(visvel_str), ball.(ballang_str), ball.(ballvel_str), ...
                        bumptmp.mu, bumptmp.rho, bumptmp.vel, bumptmp.ampmean, bumptmp.amppeak, bumptmp.ampmu, ...
                        resp_gar, resp_gal, resp_nor, resp_nol, resp_ga_mean, resp_no_mean, ...
                        ti, tb, stimepochinds_i, stimepochinds_b, opt.scatter.epochinds, fn_prefix, gif_visibility)


                    %% summary plot

                    % plot_experiment

                end
            end
        end

        %save_scopa_env()

    end


end

