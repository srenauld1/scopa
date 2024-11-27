
% see docs_a2p

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

    glb(1, dirstack=pth.dirstack); %set/update data folder path as global

    %% load metadata

    md = mdsild(pth.md, o.sld, o.hires.sld);

    % md_flyg = mdflygld(ids, pth.mdflyg, pth.dirstack, md); %commenting out since a2p doens't use any flyg metadata except balldia, which is hard coded in input param file since it never changes, and flyg metadata file is created in flyg preprocessing pipeline, which you don't need to run if you're running scopa
    % md = cell2struct([struct2cell(md); struct2cell(md_flyg)], [fieldnames(md); fieldnames(md_flyg)]); %combine mdsi (md) and flyg md into one struct, md

    %% load stim (daq)

    ftvdsrs = []; ts.flypos.x = []; ts.flypos.y = []; stimvid = []; stackmnthr = []; hrlr = []; %init some optional variables
    if o.mn.oldcarl

        [ts.vis.(o.carl.feat), stimvid] = featld(o.id.recid, o.carl.stimtype, o.carl.feat, ...
            pthparent_feat=pth.parent_feat, rep=1, feat2=[], pthsv_plot=[], doplt=0, ...
            getgrid=1, vistype='plane', it=[1:3:250], gridres=256, flipped=0, downsample_template=1, ...
            crop_edges=1, pth_template=pth.template);
        ts.t = md.sampper * [1:md.sz_crop(4)];
        ts.epochinds = ones(numel(ts.t), 1);

    else

        if o.mn.dodaq
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
                usefbf=o.daq.usefbf);
            [ts.ball, ts.vis, ts.t] = daqrename(daqrs);
            [md.epochs, ts.epochinds, ts.vis] = g4epochld(ts.t, pth.epochinfo, ts.vis, pth.dirstack, o.id, md.sampper, daqrs, o.daq.use_carls_epochs);
            [ts.flypos.x, ts.flypos.y] = ficpath(ts.ball.forvel, ts.ball.sidevel, ts.vis.yaw, ts.t, o.daq.balldia);
        end

        if o.mn.doftv
            try
                load(pth.ftvidrs, 'ftvdsrs')
            catch
                try
                    ftvdsrs = ftvproc(pth.ftvid, pth.ftvidrs, md.numvol_o, md.volrate, ...
                        o.ftv.num_periodic_peaks_defining_laser_oscillations, o.ftv.smlenpx, o.ftv.numpix_to_extract_laser_timeseries, ...
                        o.ftv.smsdtime, pth.ftdat, pth.ftvidlog, pth.ftlog);
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
        tcrop = o.sld.tcrop, ...
        cropfb = o.sld.cropfb, ...
        zerostack = o.sld.zerostack, ...
        clip = o.sld.clip, ...
        stackdtype = o.sld.stackdtype, ...
        dostats = o.sld.dostats, ...
        it = o.sld.sp.it, ...
        iz = o.sld.sp.iz, ...
        smlenpx=o.sld.smlenpx, ...
        smlensec = o.sld.smlensec, ...
        dr = o.sld.sp.dr, ...
        imrate = md.volrate);

    if pth.hires_prefix
        [stackmnthr, hrlr] = hiresld(ids.recid, pth, stack, md, o.hires);
    end

    %% create/load/select rois/responses for each optid

    if o.mn.doroi
        fn = fieldnames(o.roi);
        for m = 1:numel(fn) %for each optid
            optid = fn{m};
            [ts.roi.(optid), roidat.(optid)] = roimake(stack, ts.t, md.sampper, md.widyxz, md.zstartpos, md.sz_crop, pth.dirstack, o.id.recid, pth.roi.(optid), stackmnthr, hrlr, o.roi.(optid)); %make (manual and/or automated and/or functional/caiman) rois in 2d or 3d, extract their responses, with normalization options
        end
    end

    lfit(ts.ball.forvel, ts.roi.i4{1}, t=ts.t, doplt=1, usesaved=1, roipx=roidat.i4{1}.roipx, stack=stack, sortstyle='xyz', flypos=ts.flypos, ipltts=round(linspace(1, numel(roidat.i4{1}.roipx), 100)))

    %% feature extraction (e.g. bump), add to ts

    if o.mn.dopop
        fn = fieldnames(o.pop);
        for m = 1:numel(fn)
            ts.pop = popcmp(fn{m}, ts, stack, roidat, o.pop.(fn{m}), md, pth, ids.recid);
        end
    end

    %% model

    if o.mn.dofit
        fn = fieldnames(o.mfit);
        for m = 1:numel(fn)
            ts.fit = mfit(stacksub, fitin, roidat.(fitin.regionex).(fitin.parsex), md, o.mfit(si)); %fit model using any available timeseries
        end
    end

    %% interactive plots

    if o.mn.dopltx
        fn = fieldnames(o.pltx);
        for m = 1:numel(fn)
            fitin.vars.resp_ind1 = ts.roi.i7{1}(1,:);
            fitin.vars.resp_ind2 = ts.roi.i7{1}(2,:);
            fitin.vars.resp_ind3 = ts.roi.i7{1}(3,:);
            fitin.vars.resp_ind4 = ts.roi.i7{1}(4,:);
            fitin.vars.resp_ind5 = ts.roi.i7{1}(5,:);
            fitin.vars.resp_ind6 = ts.roi.i7{1}(6,:);
            fitin.vars.resp_ind7 = ts.roi.i7{1}(7,:);
            fitin.vars.resp_ind8 = ts.roi.i7{1}(8,:);

            fitin.vnm.resp_ind1{1} = '';
            fitin.vnm.resp_ind2{1} = '';
            fitin.vnm.resp_ind3{1} = '';
            fitin.vnm.resp_ind4{1} = '';
            fitin.vnm.resp_ind5{1} = '';
            fitin.vnm.resp_ind6{1} = '';
            fitin.vnm.resp_ind7{1} = '';
            fitin.vnm.resp_ind8{1} = '';
            o.pltx.vpmap.l = o.pltx.vpmapl;
            o.pltx.vpmap.r = o.pltx.vpmapr;
            fitin.fn_save_prefix = [pth.prefix 'fool'];
            fitin.fn_save_prefix_short = fitin.fn_save_prefix;
            pthroiint = '~/stacks/221120_0_f91g_syt/221120_0_1_cmrg_dcdn_i7_roi_inter.mat';
            zstartsub = 0;
            nrm='f';
            pltx(stack, fitin.vars, o.pltx.doui,  ...
                fitin.vnm, o.pltx.vpmap, o.pltx.epochinds, ...
                o.pltx.lagsxy_sec, o.pltx.lagsz_sec, o.pltx.lags_to_plot, ...
                o.pltx.plot_z_as_color, roidat.i7{1}, ts.t, md.sampper, zstartsub, ...
                ts.epochinds, glb('pltvis'), o.pltx.iz, o.pltx.it, ...
                o.pltx.dr, fitin.fn_save_prefix_short, fitin.fn_save_prefix, ...
                pthroiint, nrm, md.widyxz, vid=ftvdsrs, stim=stimvid)
        end
    end


end



