

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

pth_all = find_preprocessed_files(opt.main);

for pai = 1:length(pth_all)


    %% assign filenames

    [opt, pth, croplim_all, mroipars, froipars, datenum, flynum, trialnum, recid] = filenames_scopa(opt, pth_all{pai});

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

    %% rois/responses

    clear resp

    stack_mnt = cell(length(opt.main.regionex_all), 1);
    for rei = 1:length(opt.main.regionex_all) %for each region with extracted rois

            %% crop movie to regionex cuboid

            regionex = opt.main.regionex_all{rei};
            [stackcrop, stack_mnt{rei}, map_hires_lores_crop, hiresmntcrop] = ...
                crop_stacks(stack, croplim_all{rei}, opt.mroi.use_hires.(regionex), recid, regionex, pth.fldr, md.sz_crop);


            %% make (manual and automated) morphological rois in 2d or 3d

            [roiinfo.(regionex).(mroipars{rei}), resp.(regionex).(mroipars{rei})] = ...
                make_morphological_rois(stackcrop, opt.mroi, md, pth, hiresmntcrop, map_hires_lores_crop, regionex);


            %% load functional (caiman) roi responses, remove any that don't meet morphological criteria (if anyare requested)

            for rfi = 1:length(pth.roi_func_all{rei})

                %load/visualize any previously extracted functional rois, assign to any morphological rois
                [roiinfo.(regionex).(froipars{rei}{rfi}), resp_roi_func] = ...
                    load_functional_rois(pth.roi_func_all{rei}{rfi}, stack_mnt{rei}, ...
                    roiinfo.(regionex).(mroipars{rei}).centroids_roi, ...
                    roiinfo.(regionex).(mroipars{rei}).mask_allroi, ...
                    regionex, md.croptimeinds, opt.froi);

                %% compute functional (caiman) roi responses, and also functional (caiman) responses averaged by morphological roi

                %this version not weighted by area by passing pixinds_roi_func
                resp.(regionex).(froipars{rei}{rfi}) = ...
                    extract_roi_responses(resp_roi_func, ...
                    roiinfo.(regionex).(froipars{rei}{rfi}).mask_roi_vec, ...
                    pth.roi_func_all{rei}{rfi}, opt.norm, md.dtmni);

                %this version weighted by area by passing pixinds_roi_func_wt (appends to existing resp)
                resp.(regionex).(froipars{rei}{rfi}) = ...
                    extract_roi_responses(resp_roi_func, ...
                    roiinfo.(regionex).(froipars{rei}{rfi}).mask_roi_vec_wt, ...
                    pth.roi_func_all{rei}{rfi}, opt.norm, md.dtmni, resp.(regionex).(froipars{rei}{rfi}));

            end


    end

    %% bump


    for rei = 1:length(opt.main.regionex_all) %for each region with extracted rois, loop over extraction and normalization runs
        
        regionex = opt.main.regionex_all{rei};
        stackcrop = crop_stacks(stack, croplim_all{rei});

        countz = 0;
        extraction_params_all = fieldnames(resp.(regionex)); 
        for epi = 1:length(extraction_params_all) %for each extraction
            extraction_params = extraction_params_all{epi};
            norm_params_all = fieldnames(resp.(regionex).(extraction_params_all{epi})); 
            for npi = 1:length(norm_params_all) %for each response normalization
                norm_params = norm_params_all{npi};
                if any(~cellfun(@isempty, regexp(extraction_params, regexptranslate('wildcard', opt.bump.expat)))) && ...
                        any(~cellfun(@isempty, regexp(norm_params, regexptranslate('wildcard', opt.bump.normpat)))) && ...
                        any(~cellfun(@isempty, regexp(regionex, regexptranslate('wildcard', opt.bump.regionpat_bump)))) 

                    fn_save_prefix = [pth.roi_allmethods{rei}{epi}(1:end-4) norm_params];

                    bump.(regionex).(extraction_params).(norm_params) = ...
                        compute_bump(stackcrop, resp.(regionex).(extraction_params).(norm_params), ...
                        stim.(opt.fit.sdom.(regionex){1}).(opt.fit.sdom.(regionex){2}), ...
                        numcluster_for_bump_domain_resample(rei), fn_save_prefix, md.stimepochinds_i, md.dtmni, ...
                        roiinfo.(regionex).(extraction_params_all{epi}).pixinds_roi, ...
                        roiinfo.(regionex).(extraction_params_all{epi}).mapind2ind, ...
                        opt.bump, opt.fit, doplots);

                end
            end
        end
    end

    %% model/predict

    clear params_all

    for rei = 1:length(opt.main.regionex_all) %for each region with extracted rois, loop over extraction and normalization runs

        regionex = opt.main.regionex_all{rei};
        stackcrop = crop_stacks(stack, croplim_all{rei});

        countz = 0;
        extraction_params_all = fieldnames(resp.(regionex)); 
        for epi = 1:length(extraction_params_all) %for each extraction
            norm_params_all = fieldnames(resp.(regionex).(extraction_params_all{epi}));
            for npi = 1:length(norm_params_all) %for each response normalization
                if any(~cellfun(@isempty, regexp(extraction_params_all{epi}, regexptranslate('wildcard', opt.fit.expat_fit)))) && ...
                        any(~cellfun(@isempty, regexp(norm_params_all{npi}, regexptranslate('wildcard', opt.fit.normpat_fit)))) && ...
                        any(~cellfun(@isempty, regexp(regionex, regexptranslate('wildcard', opt.fit.regionpat_fit))))

                    countz = countz + 1;
                    params_all.(regionex){countz, 1} = extraction_params_all{epi};
                    params_all.(regionex){countz, 2} = epi;
                    params_all.(regionex){countz, 3} = norm_params_all{npi};
                    params_all.(regionex){countz, 4} = npi;

                    fn_save_prefix = [pth.roi_allmethods{rei}{epi}(1:end-4) norm_params];

                    opt.fit.use_saved_model = 1;
                    opt.fit.modeltype = 'glno4';
                    opt.fit.length_model_seconds = 2;

                    stimfit(1,:) = stim.(opt.fit.sdom.(regionex){1}{1}).(opt.fit.sdom.(regionex){1}{2});
                    stimfit(2,:) = bump.pb.(extraction_params).('in_rawf_pc_f_cl_rsc_w_yes').all.mu;
                    % stimfit(1,:) = stim.(opt.fit.sdom.(regionex){1}{1}).(opt.fit.sdom.(regionex){1}{2});

                    [fittmp, goftmp] = ...
                        fitresp(stackcrop, stimfit, ...
                        resp.(regionex).(extraction_params_all{epi}).(norm_params_all{npi}), ...
                        roiinfo.(regionex).(extraction_params_all{epi}).pixinds_roi, ...
                        roiinfo.(regionex).(extraction_params_all{epi}).mapind2ind, ...
                        md.stimepochinds_i, md.dtmni, fn_save_prefix, opt.fit);

                    % [roi_is_not_selective] = test_roi_selectivity(resp, vis, ball, md, regionex, pth.caimanrois, doplots2);
                    % good_roi_indices = good_roi_indices & ~roi_is_not_selective;


                    %% scatterplots


                    scatterplots(vis.(visang_str), vis.(visvel_str), ball.(ballang_str), ball.(ballvel_str), ...
                        bumptmp.mu, bumptmp.rho, bumptmp.vel, bumptmp.ampmean, bumptmp.amppeak, bumptmp.ampmu, ...
                        resp_gar, resp_gal, resp_nor, resp_nol, resp_ga_mean, resp_no_mean, ...
                        ti, tb, stimepochinds_i, stimepochinds_b, opt.scatter.epochinds, fn_prefix, gif_visibility)


                    %% summary plot

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
                    %     % plot_bump(alpha_plot, resp_plot, mu_plot, rho_plot, visang, ballang, ...
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

        %save_scopa_env()

    end


end

