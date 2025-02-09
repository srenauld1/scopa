
% see docs_a2p
% roi.optid.superfield{chan}.field %

function a2p(specin)

arguments
    specin = '' %optional; full path to recording (char or cell, wildcards allow matching rules in rdir), or cell array of full paths (char), or struct with recording specifiers (see specin in oset and odf); if missing or empty, recording(s) searched for in oset
end

clear glb %clear globals

odfsv(); %just always write it; why not

oa = oset(specin); % set options; oa stands for o all (ie all recordings)

for k = 1:numel(oa) % loop over recordings

    o = oa(k); %index into options for one recording, o

    osv(o); %save options to txt file

    pth = pthmake(o);

    glb(1, dirstack=pth.dirstack); %set/update data folder path as global (update option since you might be looping over k)

    %% stack

    stack = stackpr(pth.stack, o.spr);

    %% metadata

    md = mdsild(pth.stack, pth.py);

    %% stim

    try
        daqrs = daqld(pth.stack, o.daq);
        [ball, vis, t] = daqrename(daqrs);
        [pos.x, pos.y] = ficpath(ball.forvel, ball.sidevel, vis.yaw, t, o.daq.balldia);
        vis = epochld(t, vis, md.sampper, o.daq.use_carls_epochs);
    catch ME
        fprintf("tried loading/processing daq but it failed with this message: " + newline + ME.message + newline + "will continue without daq data, which may cause error downstream" + newline)
        ball = []; vis = []; pos = []; ftv = []; %init some optional variables
        t = md.sampper * [1:size(stack,4)];
        vis.epochts = ones(numel(t), 1);
    end

    if o.mn.dofeat
        [vis.(o.feat.id), stimvid] = featld(pth.stack, o.feat);
    end

    %% rois

    if o.mn.doroi
        fn = fieldnames(o.roi);
        for m = 1:numel(fn) %for each optid
            optid = fn{m};
            roi.(optid) = roimake(stack, pth.stack, optid, t, md.sampper, md.widyxz, pth.py, o.roi.(optid)); %make (manual and/or automated and/or functional/caiman) rois in 2d or 3d, extract their responses, with normalization options
        end
    end

    %% bump

    if o.mn.dobmp
        fn = fieldnames(o.bmp);
        for m = 1:numel(fn)
            optid = fn{m};
            indv = vis.yaw; %hard coding this for now
            % o2.roi.regionex = 'eb';
            % depv = tsget(o2, chan=o.bmp.(optid).chan);
            depv = roi.a25.ts{o.bmp.(optid).chan};
            bmp.(optid) = bmpmake(indv, depv, md.volrate, vis.epochts, pth.stack, optid, o.bmp.(optid)); %fit bump 
        end
    end

    ebno({'r'}, vis.yaw, ball.yaw, bmp.(optid).mu, bmp.(optid).respcl, roi.a23.ts{1}, roi.a24.ts{1}, t, md.sampper, pth.pre, plt=[0 0 1 0], facealpha=0.2, szthrres=[], szmin=10, szmaxfac=70, nothr='', colsep=0, xyrng=[], epoch={6}, epochts=vis.epochts, lagsampxy=0, lagsampz=[-2:2], yconst=1, slopelensec=[]) 
    
    %% model

    if o.mn.dofit
        fn = fieldnames(o.mdl);
        for m = 1:numel(fn)
            optid = fn{m};
            mdl = mdlmake(indvp, depvp, md.volrate, pth.stack, optid, o.mdl.(optid), vis.epochts);
        end
    end

    %% plots

    if o.mn.dopltx
        fn = fieldnames(o.pltx);
        for m = 1:numel(fn)
            pltx(stack(:,:,:,fk,:), mdl.vars, o.pltx.doui,  ...
                mdl.vnm, o.pltx.vpmap, o.pltx.epochnum, ...
                o.pltx.lagsxy_sec, o.pltx.lagsz_sec, o.pltx.lags_to_plot, ...
                o.pltx.plot_z_as_color, roidat.a1{1}, t, md.sampper, zstartsub, ...
                vis.epochts, glb('pltvis'), o.pltx.iz, o.pltx.it, ...
                o.pltx.dr, mdl.fn_save_prefix_short, mdl.pthpre, ...
                pthroiint, nrm, md.widyxz, vid=ftv, stim=stimvid)
        end
    end


end



