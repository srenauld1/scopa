

%%%%%%% scopa 'post' pipeline for analyzing data output from scopa 'pre' pipeline

% variables are organized into structs to reduce complexity
% for readability, variables are sometimes unpacked/repacked when entering/exiting functions in which they're used, unless they are used infrequently, or they are large and must be modified in a way that requires indexing

% struct 'ui' holds input params in various sub-structs; each substruct is (predominantly) used in one function below, although substruct fields are passed individually as arguments to make the function more portable
% struct 'ts' holds timeseries (in various sub-structs) with temporal indices corresponding to md.ti (imaging frame timestamps)
% struct 'roidat' holds roi info for morphological and functional rois
% struct 'md' holds metadata
% struct 'pth' holds paths
% numeric array 'stack' is the imaging movie chosen for analysis (using 'ui.mn.suffix_analysis')

% if you get error "Invalid argument at position n. Function requires exactly 5-1 positional input(s)" check that you're not passing a nonscalar struct into a function (eg if you want to pass channel 1 roi weights, and there are two channels, pass roidat(1).roiwt, instead of roidat.roiwt)

function a2p(pthstacks)

arguments
    pthstacks = [] %optional cell array of full paths to recordings
end

sprintf("\n\n\nENTERING a2p.m")

"FIX NO REGIONEX OPTION"
"FIX DIFFERENT MROI OPTS FOR EACH REGIONEX, OR MAYBE TRANSFER MANY PARAMS TO OPTS IN THEIR FUNCTIONS"
"CAN STACK REMAIN INT16?? zero in uint16 is nice though"
"MAKE ALL INDICES CONSISTENTLY REPRESENT START, CENTER, OR END . . . daq starts at 0, so maybe do start indexed, but singleton 0 indexed samples don't tell you width; but currently default daq downsampling makes time represent center, since it takeds average"

clear globals_a2p

ui = uipars(pthstacks); % params

for pai = 1:numel(ui.mn.pthstacks) % loop over recordings

    clear globals_a2p

    ids = get_ids_a2p(ui.mn.pthstacks{pai});

    [pth, parstr] = fna2p(ui, ids, ui.mn.pthstacks{pai});

    gset.pthfldr = pth.fldr;
    gset.name_noregionex = 'default';
    gset.valid_fnsuffixes = ui.mn.valid_fnsuffixes;
    globals_a2p(gset);

    %% load metadata

    md = mdsild(pth.md, ui.ld, ui.hires.ld);
    % md_flyg = mdflygld(ids, pth.flyg_md, pth.fldr, md); %commenting out since a2p doens't use any flyg metadata except balldia, which is hard coded in input param file since it never changes, and flyg metadata file is created in flyg preprocessing pipeline, which you don't need to run if you're running scopa
    % ff = @(x,y) cell2struct([struct2cell(md);struct2cell(md_flyg)],[fieldnames(md);fieldnames(md_flyg)]);
    % md = ff(md, md_flyg);

    %% load and process daq

    ftvdsrs = []; ts.flypos.x = []; ts.flypos.y = []; stimvid = [];
    if ui.mn.old_project

        try
            load(pth.featsave, 'ts', 'stimvid')
        catch
            [ts.vis.(ui.carl.feat), stimvid] = load_feat(ids.recdate, ids.fly, ids.trial, ui.carl.stimtype, ui.carl.feat, ...
                pthparent_feat=pth.parent_feat, rep=1, feat2=[], pthsv_plot=[], doplt=0, ...
                getgrid=1, vistype='plane', it=[1:3:250], gridres=256, flipped=0, downsample_template=1, ...
                crop_edges=1, pth_template=pth.template);
            save(pth.featsave, 'ts', 'stimvid', '-v7.3', '-mat')
        end
        md.ti = md.imper * [1:md.sz_crop(4)];
        md.epochs.epochinds_ts_i = ones(numel(md.ti), 1);

    else

        if ui.mn.do_daq
            try
                load(pth.daqrs, 'daqrs')
            catch
                daqrs = daqld(ids.recdatenum, ids.flynum, ids.trialnum, md.numvol_o, md.numslice, md.numslice_withflyback, md.imper, ui.daq.balldia, ui.daq.voltmin, ui.daq.voltmax, ...
                    vnormal=ui.daq.vnormal, ...
                    vcircular=ui.daq.vcircular, ...
                    vcategorical=ui.daq.vcategorical, ...
                    toballscale=ui.daq.toballscale, ...
                    tounwrap=ui.daq.tounwrap, ...
                    tozero=ui.daq.tozero, ...
                    pth_fldr=pth.fldr, ...
                    slopelensec=ui.daq.slopelensec, ...
                    slopeord=ui.daq.slopeord, ...
                    useinds=ui.daq.useinds, ...
                    use_flyback_lines=ui.daq.use_flyback_lines, ...
                    use_flyback_frames=ui.daq.use_flyback_frames, ...
                    doplots=ui.daq.doplots);
            end
            [ts.ball, ts.vis, ts.ti] = daqrename(daqrs);
            md.ti = ts.ti;
            [md.epochs, ts.vis] = load_g4_epochs(md.ti, pth.epochinfo, ts.vis, pth.fldr, ids, md.imper, daqrs, ui.daq.use_carls_epochs);
            [ts.flypos.x, ts.flypos.y] = ficpath(ts.ball.forvel, ts.ball.sidevel, ts.vis.yaw, md.ti, ui.daq.balldia);
        end

        if ui.mn.do_ftvproc
            try
                load(pth.ft.vidrs, 'ftvdsrs')
            catch
                try
                    ftvdsrs = ftvproc(pth.ft.vid, pth.ft.vidrs, md.numvol_o, md.volrate, ...
                        ui.ftv.num_periodic_peaks_defining_laser_oscillations, ui.ftv.ftvid_spatial_smooth_window_std, ui.ftv.numpix_to_extract_laser_timeseries, ...
                        ui.ftv.laser_timeseries_smooth_window_std, ...
                        ui.ftv.doplots, pth.ft.dat, pth.ft.vidlog, pth.ft.log);
                catch ME
                    sprintf(ME.message)
                end
            end
        end

    end


    %% load/visualize stack (and optional hires stack)

    stack = stackld(pth.stack, ...   %can just pass pth.stack if it's mat; if tif need to also pass sz to read tif into stack's native shape, or if you don't pass sz it will read tif with tzc collapsed into 3rd dim;
        suffixes_plot=ui.ld.gif.suffixes_plot, ... %pass nonempty suffixes_plot and it will plot whichever suffixes are in same folder as pth.stack, along with pth.stack
        sz = md.sz_o, ...
        numslice_withflyback = md.numslice_withflyback, ...
        channel_save = md.channel_save, ...
        channel_use = ui.ld.channel_use, ...
        tcropfront = ui.ld.tcropfront, ...
        tcropback = ui.ld.tcropback, ...
        crop_flyback = ui.ld.crop_flyback, ...
        zero_stack = ui.ld.zero_stack, ...
        stack_make_datatype = ui.ld.stack_make_datatype, ...
        do_plot_stack_stats = ui.ld.do_plot_stack_stats, ...
        it = ui.ld.gif.it, ...
        iz = ui.ld.gif.iz, ...
        smsdspace=ui.ld.smsdspace, ...
        smooth_window_temporal = ui.ld.gif.smooth_window_temporal, ...
        display_range = ui.ld.gif.display_range);

    % stackreg = register_stack_new(stack(:,:,:,:,1)); %this is just exploratory

    if any(cell2mat(struct2cell(ui.mroi.auto.use_hires)))
        [stack_hires_mnt, map_hires_lores] = load_hires_stack(ids.recid, pth, stack, md, ui.hires);
    else
        stack_hires_mnt = [];
        map_hires_lores = [];
    end

    % stack2fig(stack, it=20.3, fdimnum=3) %view stack in various ways

    %% create/load/select rois/responses for each regionex

    for rei = 1:numel(ui.mn.regionex_all) %for each regionex

        regionex = ui.mn.regionex_all{rei};

        %%crop movie to regionex cuboid
        [stackcrop, zstartpos_crop, map_hires_lores_crop, hiresmntcrop, croplim_all.(regionex), pth.mroi.(regionex)] = ...
            cropstacks(stack, regionex, md.zstartpos, ids.recid, pth.fldr, pth.tmpfiles, ...
            md.sz_crop, ui.mroi.auto.use_hires.(regionex), stack_hires_mnt, map_hires_lores, pth.mroi.(regionex));

        %%make (manual and/or automated) morphological rois in 2d or 3d, and extract their responses
        [roidat.(regionex).(parstr.mroi.(regionex)), ts.resp.(regionex).(parstr.mroi.(regionex))] = ...
            mroimake(stackcrop, ui.mroi, md.ti, md.imper, md.xwid, md.ywid, md.zwid, ...
            pth.mroi.(regionex), pth.tmpfiles, hiresmntcrop, map_hires_lores_crop, regionex, parstr.mroi.(regionex));

        %%load/select functional (caiman) roi responses
        for rfi = 1:numel(pth.froi_all.(regionex)) %for each caiman extraction run (each roi file)
            [roidat.(regionex).(parstr.froi.(regionex){rfi}), ts.resp.(regionex).(parstr.froi.(regionex){rfi})] = ...
                froiproc(stackcrop, roidat.(regionex).(parstr.mroi.(regionex)), ...
                pth.froi_all.(regionex){rfi}, regionex, md, ui.froi);
        end

    end

    % save([pth.fldr 'ts.mat'], 'ts', '-v7.3', '-mat') %save timeseries struct 'ts' before adding modeling timeseries to it below


    %% linear fit and hsv map (work in progress, but it does work)

    if ui.mn.do_lfit
%% 

        ui.lc.chanuse = 1;

        rindy = 1;
        rsp = ts.resp.(regionex).(parstr.mroi.(regionex)).(['rawf_f_f_n_chn' num2str(ui.lc.chanuse)]);

        rsp = wavelet_denoise(rsp, t=ti, it=1:numel(ti), pthgifpre=''); %pth_mroi_prefix

        %% 


        rsp1 = rsp(rindy,:);

        fvd = ts.ball.forvel;
        fvd = abs(fvd);
        fvd = smoothdata(fvd, 'gaussian', 12, 'omitnan');
        %%fvd = tsdv('normal', fvd, 0.4, 2, md.imper);

        yvd = ts.ball.yawvel;
        % yvd = abs(yvd);
        yvd = smoothdata(yvd, 'gaussian', 12, 'omitnan');
        %%yvd = tsdv('normal', yvd, 0.4, 2, md.imper);

        tinds = 3000:4000;
        xtrem = max(abs([vec(fvd(tinds)); vec(ts.ball.forvel(tinds))]));
        xtrem = max(abs([vec(fvd(tinds))]));
        figure; plot(rescale(ts.ball.forvel(tinds), -xtrem/1, xtrem/1), Color=[0 0 1 0.1]); yyaxis right; plot(fvd(tinds)); ylim([-xtrem xtrem]); hold on; plot(rescale(rsp1(tinds), -xtrem/8, xtrem/8), 'm-')

        stim = [fvd; yvd];

        % roivpix( ...
        %     ts.resp.(regionex).(parstr.mroi.(regionex)).in_rawf_pc_f_cl_f_w_no_chn1, ...
        %     stackcrop, ...
        %     roidat.(regionex).(parstr.mroi.(regionex))(ui.lc.chanuse).roipx, ...
        %     t=md.ti, ...
        %     ir=[1:50:1024], ...
        %     it=[1000:1500], ...
        %     yconstant=0 ...
        %     );

        lfit_riw2( ...
            stim, ..., ts.ball.forvel, ...
            rsp, ... ts.resp.(regionex).(parstr.mroi.(regionex)).in_rawf_pc_f_cl_f_w_no_chn1, ...
            t = md.ti, ...
            it = 3000:4000, ...
            ir = [], ...
            plotinds = [1:3], ...
            corrtype = 'pearson', ...
            lagsec = linspace(0.1, 0.1, 1e4), ...
            lagstyle = 'besteach', ...
            minpval = 0.05, ...
            stack = stackcrop, ...
            roipx = roidat.(regionex).(parstr.mroi.(regionex))(ui.lc.chanuse).roipx, ...
            roiwt = roidat.(regionex).(parstr.mroi.(regionex))(ui.lc.chanuse).roiwt, ...
            roicen = roidat.(regionex).(parstr.mroi.(regionex))(ui.lc.chanuse).roicen, ...
            sortstyle = 'slope', ...
            alignzero = 1, ...
            yconstant = 0, ...
            plotlagged = 0, ...
            usesaved = 0, ...
            chanuse = ui.lc.chanuse, ...
            hsvopt = [], ...
            flypos = ts.flypos, ...
            pixfit = 0, ...
            pthgif = [], ...
            doplots = 1 ...
            );

    end

    %% compute population features (e.g. bump), add them to ts

    if ui.mn.do_popfeat
        pffn = fieldnames(ui.pf);
        for pfi = 1:numel(pffn)
            ts = popcomp(pffn{pfi}, ts, stack, croplim_all, roidat, ui.pf.(pffn{pfi}), md, pth, ids.recid);
        end
    end

    %% model/predict

    if ui.mn.do_fit
        for si = 1:numel(ui.mfit)
            dochoose = 1;
            choosecount = 0;
            while dochoose

                choosecount = choosecount + 1;
                [fitin, dochoose] = choose_timeseries(ui.mfit(si).varnms, ts, md.ti, pth.tsuse_nms_prefix.mfit, pth.stack, choosecount, dochoose); %select indv/depv for fit using input params
                stackcrop = cropstacks(stack, fitin.regionex, md.zstartpos, ids.recid, pth.fldr); %crop stack based on regionex of the depv (stack for plots, not model)

                fitin = mfit(stackcrop, fitin, roidat.(fitin.regionex).(fitin.parsex), md, ui.mfit(si)); %fit model using any available timeseries

            end
        end
    end


    %% plot experiment

    if ui.mn.do_pltexp
        for si = 1:numel(ui.pltx)
            dochoose = 1;
            choosecount = 0;
            while dochoose

                choosecount = choosecount + 1;
                [fitin, dochoose] = choose_timeseries(ui.pltx(si).varnms, ts, md.ti, pth.tsuse_nms_prefix.pltx, pth.stack, choosecount, dochoose);
                [stackcrop, zstartpos_crop] = cropstacks(stack, fitin.regionex, md.zstartpos, ids.recid, pth.fldr); %crop stack for plotting fov/rois

                pltx(stackcrop, fitin.vars, ui.pltx(si).letui,  ...
                    fitin.varnms, ui.pltx(si).vpmap, ui.pltx(si).epochinds, ...
                    ui.pltx(si).lagsxy_sec, ui.pltx(si).lagsz_sec, ui.pltx(si).lags_to_plot, ...
                    ui.pltx(si).plot_z_as_color, roidat.(fitin.regionex).(fitin.parsex), md.ti, md.imper, zstartpos_crop, ...
                    md.epochs.epochinds_ts_i, ui.pltx(si).gif_visibility, ui.pltx(si).iz, ui.pltx(si).it, ...
                    ui.pltx(si).display_range, fitin.fn_save_prefix_short, fitin.fn_save_prefix, ...
                    pth.mroi_interactive.(fitin.regionex), ui.mroi.norm, md.xwid, md.ywid, md.zwid, vid=ftvdsrs, stim=stimvid)


            end
        end
    end

end



end