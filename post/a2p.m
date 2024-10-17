

%%%%%%%%%%%%%% a2p %%%%%%%%%%%%%%

%{

ap2 (analysis 2-photon)
    scopa 'post' pipeline for analyzing data output from scopa 'pre' pipeline
    primarily for defining/processing rois, fitting models, and visualizing data (including interactively)
    can run on single recordings, or in loop on batch of recordings
    can run locally, or on O2
    many subroutines can be run on electrophysiological data too; full pipeline could be easily adapted to run on electrophysiological data 

overview: 
    load/process stack(s)
    load/process stimulus (daq)
    load/process fictrac video
    load metadata
    draw and/or automatically extract morphological rois
    load/process functional rois
    extract features from stack and/or timeseries 
    fit models
    explore data interactively 

variables: 
    o: struct; input options in various sub-structs; each substruct is (predominantly) used in one function below, although substruct fields are passed individually as arguments to make the function more portable
    ts: struct; timeseries (in various sub-structs) with temporal indices corresponding to ts.t (imaging frame timestamps)
    roidat: struct; roi info for morphological and functional rois
    md: struct; metadata
    pth: struct; paths
    stack: numeric array; imaging movie chosen for analysis; dimensions y, x, z, t, c (channel)
    iy, ix, iz, it, ic: index for each dimension of stack, y, x, z, t, c (channel)
    ir: roi index
    y, x, z, t, c: reserved for stack dimensions
    k, m, p, q, s, u, v, w: reserved for loop indices
    b: reserved for model parameters
    cmc, cmdff, cmdffr, cms, cma, cmb, cmsnr, cmval: caiman roi extraction output variables (loaded/processed in froiproc)


main processing functions:
    stackld: load stacks; plot stacks for comparison
    daqld: load/process daq data
    mroimake: make manual (drawn) and/or automated morphological rois
    froiproc: process functional rois extracted in pre pipeline with caiman
    bumpcmp: compute bump in various ways
    popcmp: compute poulation features, currently only holds bumpcmp; eventually will be general stack and timeseries feature extraction routine, to make extracted features available to mfit routine
    mfit: fit models to any available timeseries (derived from roi code, or feature extraction code, or direct experimental timeseries (e.g stimulus, fictrac timeseries, etc)

utility functions (and visualization functions):
    stackplt: plot stack(s) 
    pltx: pltx means plot experiment; versatile and interactive plotting function; can plot fictrac video, fictrac paths, scatterplots, brain images with rois 
    pthauto: create path (e.g. for saving figures)
    oset: set options
    odf: invoke default options, overwriting defaults with input
    tsget: choose timeseries from highly nested struct ts using string pattern matching (wildards allowed)
    figarr: arrange subplots, including automatically arranging frames of imaging stack to optimally fill available space while maintaining aspect ratio 


abbreviations
    stack: imaging volume; o: options, md: metadata, df: default, pars: parameters, ts: timeseries, vel: velocity, dv: derivative, fb: flyback, ftv: fictrac video, ft: fictrac, mroi: morphological roi, froi: functional roi, ld: load, pth: path, plt: plot, px: pixel, resp: response/neural activity timeseries; stim: stimulus; depv: dependent variable; indv: independent variable; cnt: count (loop index); cm: caiman; proc: process; fn: filename and fieldname (need to disambiguate) 


variables are organized into structs, which are sometimes unpacked when entering functions, unless they are used infrequently, or they are large and are modified with indexing
pixel (abbr. px) can mean both pixel and voxel in scopa variable names (because pixel is so often used to mean voxel); occasionally the term voxel is used in comments 


%}

function a2p(recin)

arguments
    recin = [] %optional; full path to recording (char or cell, wildcards allowed matching rules in rdir), or cell array of full paths (char), or struct with recording specifiers (see recin in oset and odf); if missing or empty, recording(s) found in oset
end

clear glb %clear globals

oa = oset(recin); % set options; oa stands for o all (ie all recordings)

for k = 1:numel(oa) % loop over recordings

    o = oa(k); %index into options for one recording, o

    osave(o); %save all options to txt file

    pth = fnmake(o);

    glb(1, pthfldr=pth.fldr); %set/update data folder path as global

    %% load metadata

    md = mdsild(pth.md, o.sld, o.hires.sld);

    % md_flyg = mdflygld(ids, pth.mdflyg, pth.fldr, md); %commenting out since a2p doens't use any flyg metadata except balldia, which is hard coded in input param file since it never changes, and flyg metadata file is created in flyg preprocessing pipeline, which you don't need to run if you're running scopa
    % md = cell2struct([struct2cell(md); struct2cell(md_flyg)], [fieldnames(md); fieldnames(md_flyg)]); %combine mdsi (md) and flyg md into one struct, md

    %% load daq / stim

    ftvdsrs = []; ts.flypos.x = []; ts.flypos.y = []; stimvid = []; stack_hires_mnt = []; map_hires_lores = []; %init some optional variables
    if o.mn.oldcarl

        try
            load(pth.featsave, 'ts', 'stimvid')
        catch
            [ts.vis.(o.carl.feat), stimvid] = featld(ids.recdate, ids.fly, ids.trial, o.carl.stimtype, o.carl.feat, ...
                pthparent_feat=pth.parent_feat, rep=1, feat2=[], pthsv_plot=[], doplt=0, ...
                getgrid=1, vistype='plane', it=[1:3:250], gridres=256, flipped=0, downsample_template=1, ...
                crop_edges=1, pth_template=pth.template);
            save(pth.featsave, 'ts', 'stimvid', '-v7.3', '-mat')
        end
        ts.t = md.sampper * [1:md.sz_crop(4)];
        ts.epochinds = ones(numel(ts.t), 1);

    else

        if o.mn.dodaq
            try
                load(pth.daqrs, 'daqrs')
            catch
                daqrs = daqld(md.numvol_o, md.numslice, md.numslice_withflyback, md.sampper, o.daq.balldia, o.daq.voltmin, o.daq.voltmax, ...
                    vnormal=o.daq.vnormal, ...
                    vcircular=o.daq.vcircular, ...
                    vcategorical=o.daq.vcategorical, ...
                    toballscale=o.daq.toballscale, ...
                    tounwrap=o.daq.tounwrap, ...
                    tozero=o.daq.tozero, ...
                    pth_daq=pth.daq, ...
                    pth_daqrs=pth.daqrs, ...
                    slopelensec=o.daq.slopelensec, ...
                    slopeord=o.daq.slopeord, ...
                    useinds=o.daq.useinds, ...
                    usefbl=o.daq.usefbl, ...
                    usefbf=o.daq.usefbf, ...
                    doplt=o.daq.doplt);
            end
            [ts.ball, ts.vis, ts.t] = daqrename(daqrs);
            [md.epochs, ts.epochinds, ts.vis] = g4epochld(ts.t, pth.epochinfo, ts.vis, pth.fldr, o.id, md.sampper, daqrs, o.daq.use_carls_epochs);
            [ts.flypos.x, ts.flypos.y] = ficpath(ts.ball.forvel, ts.ball.sidevel, ts.vis.yaw, ts.t, o.daq.balldia);
        end

        if o.mn.doftv
            try
                load(pth.ftvidrs, 'ftvdsrs')
            catch
                try
                    ftvdsrs = ftvproc(pth.ftvid, pth.ftvidrs, md.numvol_o, md.volrate, ...
                        o.ftv.num_periodic_peaks_defining_laser_oscillations, o.ftv.smsdspace, o.ftv.numpix_to_extract_laser_timeseries, ...
                        o.ftv.smsdtime, ...
                        o.ftv.doplt, pth.ftdat, pth.ftvidlog, pth.ftlog);
                catch ME
                    sprintf(ME.message)
                end
            end
        end

    end


    %% load/visualize stack (and optional hires stack)

    stack = stackld(pth.stack, ...   %can just pass pth.stack if it's mat; if tif need to also pass sz to read tif into stack's native shape, or if you don't pass sz it will read tif with tzc collapsed into 3rd dim;
        suffixplt=o.sld.suffixplt, ... %pass nonempty suffixplt and it will plot whichever suffixes are in same folder as pth.stack, along with pth.stack
        sz = md.sz_o, ...
        numslice_withflyback = md.numslice_withflyback, ...
        channel_save = md.channel_save, ...
        chanuse = o.sld.chanuse, ...
        tcropfront = o.sld.tcropfront, ...
        tcropback = o.sld.tcropback, ...
        cropfb = o.sld.cropfb, ...
        zerostack = o.sld.zerostack, ...
        stackdtype = o.sld.stackdtype, ...
        dostats = o.sld.dostats, ...
        it = o.sld.sp.it, ...
        iz = o.sld.sp.iz, ...
        smsdspace=o.sld.smsdspace, ...
        smsdtimesec = o.sld.smsdtimesec, ...
        dr = o.sld.sp.dr, ...
        imrate = md.volrate);

    if pth.hires_prefix
        [stack_hires_mnt, map_hires_lores] = hiresld(ids.recid, pth, stack, md, o.hires);
    end

    % stackplt(stack, it=20.3, fdimnum=3) %view stack in various ways

    %% create/load/select rois/responses for each regionex

    for rei = 1:numel(o.mn.regionex) %for each regionex

        if ~strcmp(o.mn.regionex, 'default')

            %%crop movie to regionex cuboid
            [stackcrop, zstartpos_crop, map_hires_lores_crop, hiresmntcrop, croplim_all.(regionex), pth.mroi.(regionex)] = ...
                cropstacks(stack, regionex, md.zstartpos, ids.recid, pth.fldr, pth.tmpfiles, ...
                md.sz_crop, o.mroi.seg.usehires.(regionex), stack_hires_mnt, map_hires_lores, pth.mroi.(regionex));

            %%make (manual and/or automated) morphological rois in 2d or 3d, and extract their responses
            [roidat.(regionex).(parstr.mroi.(regionex)), ts.resp.(regionex).(parstr.mroi.(regionex))] = ...
                mroimake(stackcrop, o.mroi, ts.t, md.sampper, md.xwid, md.ywid, md.zwid, ...
                pth.mroi.(regionex), pth.tmpfiles, hiresmntcrop, map_hires_lores_crop, regionex, parstr.mroi.(regionex));

            %%load/select functional (caiman) roi responses
            for rfi = 1:numel(pth.froi_all.(regionex)) %for each caiman extraction run (each roi file)
                [roidat.(regionex).(parstr.froi.(regionex){rfi}), ts.resp.(regionex).(parstr.froi.(regionex){rfi})] = ...
                    froiproc(stackcrop, roidat.(regionex).(parstr.mroi.(regionex)), ...
                    pth.froi_all.(regionex){rfi}, regionex, md, o.froi);
            end

        end

    end

    % save([pth.fldr 'ts.mat'], 'ts', '-v7.3', '-mat') %save timeseries struct 'ts' before adding modeling timeseries to it below


    %% compute population features (e.g. bump), add them to ts

    if o.mn.dopop
        pffn = fieldnames(o.pop);
        for pfi = 1:numel(pffn)
            ts = popcmp(pffn{pfi}, ts, stack, croplim_all, roidat, o.pop.(pffn{pfi}), md, pth, ids.recid);
        end
    end

    %% model/predict

    if o.mn.dofit
        for si = 1:numel(o.mfit)
            dochoose = 1;
            cnt = 0;
            while dochoose

                cnt = cnt + 1;
                [fitin, dochoose] = tsget(o.mfit(si).vnm, ts, ts.t, pth.tsuse_nms_prefix.mfit, pth.stack, cnt, dochoose); %select indv/depv for fit using input options
                stackcrop = cropstacks(stack, fitin.regionex, md.zstartpos, ids.recid, pth.fldr); %crop stack based on regionex of the depv (stack for plots, not model)

                fitin = mfit(stackcrop, fitin, roidat.(fitin.regionex).(fitin.parsex), md, o.mfit(si)); %fit model using any available timeseries

            end
        end
    end


    %% plot experiment

    if o.mn.dopltx
        for si = 1:numel(o.pltx)
            dochoose = 1;
            cnt = 0;
            while dochoose

                cnt = cnt + 1;
                [fitin, dochoose] = tsget(o.pltx(si).vnm, ts, ts.t, pth.tsuse_nms_prefix.pltx, pth.stack, cnt, dochoose);
                [stackcrop, zstartpos_crop] = cropstacks(stack, fitin.regionex, md.zstartpos, ids.recid, pth.fldr); %crop stack for plotting fov/rois

                pltx(stackcrop, fitin.vars, o.pltx(si).letui,  ...
                    fitin.vnm, o.pltx(si).vpmap, o.pltx(si).epochinds, ...
                    o.pltx(si).lagsxy_sec, o.pltx(si).lagsz_sec, o.pltx(si).lags_to_plot, ...
                    o.pltx(si).plot_z_as_color, roidat.(fitin.regionex).(fitin.parsex), ts.t, md.sampper, zstartpos_crop, ...
                    ts.epochinds, o.pltx(si).gifvis, o.pltx(si).iz, o.pltx(si).it, ...
                    o.pltx(si).dr, fitin.fn_save_prefix_short, fitin.fn_save_prefix, ...
                    pth.mroi_interactive.(fitin.regionex), o.mroi.norm, md.xwid, md.ywid, md.zwid, vid=ftvdsrs, stim=stimvid)


            end
        end
    end

end



end