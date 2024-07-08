
%%%%%%% scopa 'post' pipeline for analyzing data output from scopa 'pre' pipeline

% variables are organized into structs to reduce complexity
% variables are sometimes unpacked/repacked when entering/exiting functions in which they're used, unless they are used infrequently, or they are large and must be modified in a way that requires indexing

% struct 'opt' holds input params in various sub-structs, which are each used predominantly in a function below
% struct 'ts' holds timeseries (in various sub-structs) with indices corresponding to md.ti (imaging frame timestamps)
% struct 'roiinfo' holds roi info for morphological and functional rois
% struct 'md' holds metadata
% struct 'pth' holds paths
% numeric array 'stack' is the imaging movie chosen for analysis (using 'opt.mn.suffix_analysis')

% struct 'opt.fitm' holds options that do not change across all calls function 'fitmdl'
% struct 'fitin' (stands for 'fit input') holds data (e.g. depv & indv) used in each individual call to function 'fitmdl' (can change across calls)

% in variable names
%   prefix, infix, or suffix 'ts' denotes 'timeseries'
%   suffix '*_i' denotes imaging sampling, suffix '*_b' denotes behavior sampling (suffix can be used for timeseries variable, or variable used exclusively with one or the other sampling regimes)
%   suffix '*_m' denotes model sampling (e.g., in a linear model integrating 5 imaging samples into the past, num_samp
% display_todos()

function a2p(varargin)


%% params

"move flyg metadata file create into filenames_a2p"
opt = input_params_carl(varargin);

%% loop over recordings


for pai = 1:length(opt.mn.pth_usefile_prefix_all) %for each recording


    %% assign filenames

    [opt, pth, croplim_all, parstr, ids] = filenames_a2p(opt, opt.mn.pth_usefile_prefix_all{pai});


    %% load metadata

    md = load_scanimage_metadata(pth.md, opt.ld, opt.hires.ld);

    %% load and process daq

    if opt.mn.old_project
        [md, ts.vis] = load_stim(md, ids, opt.daq);
    else
        if opt.mn.do_daq
            try
                load(pth.daqrs, 'daqrs')
            catch
                daqrs = load_DAQ(ids.datenum, ids.flynum, ids.trialnum, md.numvol_o, md.numslice_withflyback, md.dtmni, ...
                    pth.daq, pth.daqrs, pth.daqinds, opt.daq.ball_diameter, opt.daq.slopelen_sec, opt.daq.slopeorder, opt.daq.fast_version, opt.daq.doplots);
            end
            [ts.ball, ts.vis, md.ti] = assign_a2p_timeseries(daqrs);
            [md.epochs, ts.vis] = load_stim_epochs(md.ti, pth.epochinfo, ts.vis, pth.fldr, ids, md.dtmni, daqrs, opt.daq.use_carls_epochs);
        end
    end


    %% temporally downsample fictrac video and align with imaging timeseries

    if opt.mn.do_temporal_downsample_align_fictrac_video
        try
            load(pth.ft.vidrs, 'ftvdsrs')
        catch
            ftvdsrs = temporal_downsample_align_fictrac_video(pth.ft.vid, pth.ft.vidrs, md.numvol_o, md.volrate, ...
                opt.ftv.ftvid_spatial_smooth_window_std, opt.ftv.numpix_to_extract_laser_timeseries, opt.ftv.laser_timeseries_smooth_window_std, ...
                opt.ftv.max_peak_distance_change_defining_periodic, opt.ftv.num_periodic_peaks_defining_laser_oscillations, ...
                opt.ftv.doplots, pth.ft.dat, pth.ft.vidlog, pth.ft.log);
        end
    else
        ftvdsrs = [];
    end

    %% load/visualize stack (and optional hires stack)

    stack = load_stack(md.sz_o, md.numslice_withflyback, pth, opt.ld, ids.recid);

    if any(cell2mat(struct2cell(opt.mroi.use_hires)))
        [stack_hires_mnt, map_hires_lores] = load_hires_stack(ids.recid, pth, stack, md, opt.hires);
    else
        stack_hires_mnt = [];
        map_hires_lores = [];
    end

    %% create/load/select rois/responses for each regionex

    for rei = 1:length(opt.mn.regionex_all) %for each regionex

        regionex = opt.mn.regionex_all{rei};

        %%crop movie to regionex cuboid
        [stackcrop, zstartpos_crop, stack_mnt.(regionex), map_hires_lores_crop, hiresmntcrop, croplim_all.(regionex), pth.mroi.(regionex)] = ...
            crop_stacks(stack, croplim_all.(regionex), md.zstartpos, ids.recid, regionex, pth.fldr, pth.tmpfiles, ...
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

    if opt.mn.do_popfeat
        pffn = fieldnames(opt.pf);
        for pfi = 1:numel(pffn)
            ts = compute_population_feature(pffn{pfi}, ts, stack, croplim_all, roiinfo, opt.pf.(pffn{pfi}), md, pth);
        end
    end

    %% model/predict

    if opt.mn.do_fit
        for si = 1:numel(opt.fitm)
            dochoose = 1;
            choosecount = 0;
            while dochoose

                choosecount = choosecount + 1;
                [fitin, dochoose] = choose_timeseries(opt.fitm(si), ts, md, pth.tsuse.fitm, pth.stack_analysis, choosecount, dochoose); %select indv/depv for fit using input params
                stackcrop = crop_stacks(stack, croplim_all.(fitin.regionex), md.zstartpos); %crop stack based on regionex of the depv (stack for plots, not model)

                opt.fitm.mdlname = 'fnet_A01_xsie_A02_xsie_B01-02_f_B03-04_f';
                opt.fitm.mdlname = 'fnet_A01_s_A02_s_B_h16';
                opt.fitm.mdlname = 'fnet_A_xsie';
                opt.fitm.validation_fold = 0; opt.fitm.use_saved_model = 1; opt.fitm.mdl_length_sec = 2; opt.fitm.num_synthetic_depv = 0; opt.fitm.epochinds = {[2 3 4]};
                fitin = fitmdl(stackcrop, fitin, roiinfo.(fitin.regionex).(fitin.parsex), md, opt.fitm(si)); %fit model using any available timeseries

            end
        end
    end

    %% scatterplots

    if opt.mn.do_scatter
        for si = 1:numel(opt.scat)
            dochoose = 1;
            choosecount = 0;
            while dochoose

                choosecount = choosecount + 1;
                [fitin, dochoose] = choose_timeseries(opt.scat(si), ts, md, pth.tsuse.scat, pth.stack_analysis, choosecount, dochoose);
                [stackcrop, zstartpos_crop] = crop_stacks(stack, croplim_all.(fitin.regionex), md.zstartpos); %crop stack for plotting fov/rois

                scatterplots(fitin.x, fitin.y, fitin.z, fitin.fieldspecstr.x_str, fitin.fieldspecstr.y_str, fitin.fieldspecstr.z_str, ...
                    opt.scat(si).epochinds, roiinfo.(fitin.regionex).(fitin.parsex), md.ti, md.dtmni, zstartpos_crop, ...
                    md.epochs.epochinds_ts_i, opt.scat(si).lagsxy_sec, opt.scat(si).lagsz_sec, opt.scat(si).lags_to_plot, ...
                    opt.scat(si).plot_z_as_color, opt.scat(si).gif_visibility, fitin.fn_save_prefix_short, fitin.fn_save_prefix)

            end
        end
    end

    %% plot experiment

    if opt.mn.do_pltexp
        for si = 1:numel(opt.pltexp)
            dochoose = 1;
            choosecount = 0;
            while dochoose

                choosecount = choosecount + 1;
                [fitin, dochoose] = choose_timeseries(opt.pltexp(si), ts, md, pth.tsuse.pltexp, pth.stack_analysis, choosecount, dochoose);
                [stackcrop, zstartpos_crop] = crop_stacks(stack, croplim_all.(fitin.regionex), md.zstartpos); %crop stack for plotting fov/rois

                plot_experiment(stackcrop, fitin.x, fitin.y, fitin.z, fitin.fieldspecstr.x_str, fitin.fieldspecstr.y_str, fitin.fieldspecstr.z_str, ...
                    opt.pltexp(si).epochinds, roiinfo.(fitin.regionex).(fitin.parsex), md.ti, md.dtmni, zstartpos_crop, ...
                    md.epochs.epochinds_ts_i, opt.pltexp(si).gif_visibility, opt.pltexp(si).plotinds, ...
                    opt.pltexp(si).display_range, fitin.fn_save_prefix_short, fitin.fn_save_prefix, ftvdsrs)

            end
        end
    end


end



end