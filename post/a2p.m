

%%%%%%% scopa 'post' pipeline for analyzing data output from scopa 'pre' pipeline

% variables are organized into structs to reduce complexity
% for readability, variables are sometimes unpacked/repacked when entering/exiting functions in which they're used, unless they are used infrequently, or they are large and must be modified in a way that requires indexing

% struct 'ui' holds input params in various sub-structs; each substruct is (predominantly) used in one function below, although substruct fields are passed individually as arguments to make the function more portable
% struct 'ts' holds timeseries (in various sub-structs) with temporal indices corresponding to md.ti (imaging frame timestamps)
% struct 'roiinfo' holds roi info for morphological and functional rois
% struct 'md' holds metadata
% struct 'pth' holds paths
% numeric array 'stack' is the imaging movie chosen for analysis (using 'ui.mn.suffix_analysis')

function a2p(pthstacks)


arguments
    pthstacks = [] %optional cell array of full paths to recordings
end

clear globals_a2p

ui = input_params_carl(pthstacks); % params

for pai = 1:numel(ui.mn.pthstacks) % loop over recordings

    clear globals_a2p

    ids = get_ids_a2p(ui.mn.pthstacks{pai});

    [pth, parstr] = filenames_a2p(ui, ids, ui.mn.pthstacks{pai});

    gset.pthfldr = pth.fldr;
    gset.name_noregionex = 'default';
    gset.valid_fnsuffixes = ui.mn.valid_fnsuffixes;
    globals_a2p(gset);

    %% load metadata

    md = load_scanimage_metadata(pth.md, ui.ld, ui.hires.ld);
    % md_flyg = load_flyg_metadata(ids, pth.flyg_md, pth.fldr, md); %commenting out since a2p doens't use any flyg metadata except ball_diameter, which is hard coded in input param file since it never changes, and flyg metadata file is created in flyg preprocessing pipeline, which you don't need to run if you're running scopa
    % ff = @(x,y) cell2struct([struct2cell(md);struct2cell(md_flyg)],[fieldnames(md);fieldnames(md_flyg)]);
    % md = ff(md, md_flyg);

    %% load and process daq

    if ui.mn.old_project
        [md, ts.vis] = load_stim(md, ids, ui.daq);
    else
        if ui.mn.do_daq
            try
                load(pth.daqrs, 'daqrs')
            catch
                daqrs = load_DAQ(ids.recdatenum, ids.flynum, ids.trialnum, md.numvol_o, md.numslice_withflyback, md.dtmni, ...
                    pth.daq, pth.daqrs, pth.daqinds, ui.daq.ball_diameter, ui.daq.slopelen_sec, ui.daq.slopeorder, ui.daq.fast_version, ui.daq.doplots);
            end
            [ts.ball, ts.vis, md.ti] = rename_daq_timeseries(daqrs);
            [md.epochs, ts.vis] = load_stim_epochs(md.ti, pth.epochinfo, ts.vis, pth.fldr, ids, md.dtmni, daqrs, ui.daq.use_carls_epochs);
        end
    end


    %% temporally downsample fictrac video and align with imaging timeseries

    if ui.mn.do_temporal_downsample_align_fictrac_video
        try
            load(pth.ft.vidrs, 'ftvdsrs')
        catch
            try
                ftvdsrs = temporal_downsample_align_fictrac_video(pth.ft.vid, pth.ft.vidrs, md.numvol_o, md.volrate, ...
                    ui.ftv.num_periodic_peaks_defining_laser_oscillations, ui.ftv.ftvid_spatial_smooth_window_std, ui.ftv.numpix_to_extract_laser_timeseries, ...
                    ui.ftv.laser_timeseries_smooth_window_std, ...
                    ui.ftv.doplots, pth.ft.dat, pth.ft.vidlog, pth.ft.log);
            catch ME
                sprintf(ME.message)
                ftvdsrs = [];
            end
        end
    else
        ftvdsrs = [];
    end

    %% load/visualize stack (and optional hires stack)

    stack = load_stack(md.sz_o, md.numslice_withflyback, md.channel_save, pth, ui.mn, ui.ld, ids);

    if any(cell2mat(struct2cell(ui.mroi.auto.use_hires)))
        [stack_hires_mnt, map_hires_lores] = load_hires_stack(ids.recid, pth, stack, md, ui.hires);
    else
        stack_hires_mnt = [];
        map_hires_lores = [];
    end

    %% create/load/select rois/responses for each regionex

    for rei = 1:numel(ui.mn.regionex_all) %for each regionex

        regionex = ui.mn.regionex_all{rei};

        %%crop movie to regionex cuboid
        [stackcrop, zstartpos_crop, stack_mnt.(regionex), map_hires_lores_crop, hiresmntcrop, croplim_all.(regionex), pth.mroi.(regionex)] = ...
            crop_stacks(stack, croplim_all.(regionex), md.zstartpos, ids.recid, regionex, pth.fldr, pth.tmpfiles, ...
            md.sz_crop, ui.mroi.auto.use_hires.(regionex), stack_hires_mnt, map_hires_lores, pth.mroi.(regionex));

        %%make (manual and/or automated) morphological rois in 2d or 3d, and extract their responses
        [roiinfo.(regionex).(parstr.mroi.(regionex)), ts.resp.(regionex).(parstr.mroi.(regionex))] = ...
            make_morphological_rois(stackcrop, stack_mnt.(regionex), ui.mroi, md.dtmni, md.xwid, md.zwid, ...
            pth.mroi.(regionex), pth.tmpfiles, hiresmntcrop, map_hires_lores_crop, regionex, parstr.mroi.(regionex));

        %%load/select functional (caiman) roi responses
        for rfi = 1:numel(pth.froi_all.(regionex)) %for each caiman extraction run (each roi file)
            [roiinfo.(regionex).(parstr.froi.(regionex){rfi}), ts.resp.(regionex).(parstr.froi.(regionex){rfi})] = ...
                process_functional_rois(stack_mnt.(regionex), roiinfo.(regionex).(parstr.mroi.(regionex)), ...
                pth.froi_all.(regionex){rfi}, regionex, md, ui.froi);
        end

    end

    %% compute population features (e.g. bump), add them to ts

    if ui.mn.do_popfeat
        pffn = fieldnames(ui.pf);
        for pfi = 1:numel(pffn)
            ts = compute_population_feature(pffn{pfi}, ts, stack, croplim_all, roiinfo, ui.pf.(pffn{pfi}), md, pth);
        end
    end

    %% model/predict

    if ui.mn.do_fit
        for si = 1:numel(ui.fitm)
            dochoose = 1;
            choosecount = 0;
            while dochoose

                choosecount = choosecount + 1;
                [fitin, dochoose] = choose_timeseries(ui.fitm(si).varnms, ts, md.ti, pth.tsuse_nms_prefix.fitm, pth.stack, choosecount, dochoose); %select indv/depv for fit using input params
                stackcrop = crop_stacks(stack, croplim_all.(fitin.regionex), md.zstartpos); %crop stack based on regionex of the depv (stack for plots, not model)

                ui.fitm.mdlname = 'fnet_A01_xsie_A02_xsie_B01-02_f_B03-04_f';
                ui.fitm.mdlname = 'fnet_A01_s_A02_s_B_h16';
                ui.fitm.mdlname = 'fnet_A_xsie';
                ui.fitm.validation_fold = 0; ui.fitm.use_saved_model = 1; ui.fitm.mdl_length_sec = 2; ui.fitm.num_synthetic_depv = 0; ui.fitm.epochinds = {[2 3 4]};
                fitin = fitmdl(stackcrop, fitin, roiinfo.(fitin.regionex).(fitin.parsex), md, ui.fitm(si)); %fit model using any available timeseries

            end
        end
    end


    %% plot experiment

    if ui.mn.do_pltexp
        for si = 1:numel(ui.pltexp)
            dochoose = 1;
            choosecount = 0;
            while dochoose

                choosecount = choosecount + 1;
                [fitin, dochoose] = choose_timeseries(ui.pltexp(si).varnms, ts, md.ti, pth.tsuse_nms_prefix.pltexp, pth.stack, choosecount, dochoose);
                [stackcrop, zstartpos_crop, stack_mnt] = crop_stacks(stack, croplim_all.(fitin.regionex), md.zstartpos); %crop stack for plotting fov/rois

                plot_experiment(ui.pltexp(si).letui, stackcrop, stack_mnt, fitin.vars, ...
                    fitin.varnms, ui.pltexp(si).vpmap, ui.pltexp(si).epochinds, ...
                    ui.pltexp(si).lagsxy_sec, ui.pltexp(si).lagsz_sec, ui.pltexp(si).lags_to_plot, ...
                    ui.pltexp(si).plot_z_as_color, roiinfo.(fitin.regionex).(fitin.parsex), md.ti, md.dtmni, zstartpos_crop, ...
                    md.epochs.epochinds_ts_i, ui.pltexp(si).gif_visibility, ui.pltexp(si).plotinds, ...
                    ui.pltexp(si).display_range, fitin.fn_save_prefix_short, fitin.fn_save_prefix, ftvdsrs, ...
                    pth.mroi_interactive.(regionex), ui.mroi.norm, md.xwid, md.zwid)

            end
        end
    end


end



end