
% see docs_a2p

function a2p(specin)

arguments
    specin = '' %optional; full path to recording (char or cell, wildcards allow matching rules in rdir), or cell array of full paths (char), or struct with recording specifiers (see specin in oset and odf); if missing or empty, recording(s) searched for in oset using specifiers in oset
end

clear glb %clear globals

odfsv(); %write default options to txt file

oa = oset(specin); % set options; oa stands for o all (ie all recordings)

for k = 1:numel(oa) % loop over recordings

    o = oa(k); %index into options for one recording, o

    %% paths

    pth = pthmake(o);
    glb(1, pthstackdir=pth.pthstackdir, pthstack=pth.stack); %update some globals

    %% stack

    stack = stackpr(pth.stack, o.spr);

    %% metadata

    md = mdsild(pth.stack, pth.py);

    %% stimuli

    daq = daqld(pth.stack, o.daq);
    t = daq.t;

    %% rois

    if o.mn.doroi
        fn = fieldnames(o.roi);
        for m = 1:numel(fn) %for each optid (unique set of options)
            optid = fn{m};
            roi.(optid) = roimake(stack, pth.stack, t, md.sampper, md.widyxz, pth.py, o.roi.(optid)); %make (manual and/or automated and/or functional/caiman) rois in 2d or 3d, extract their responses, with normalization options
        end
    end

    %% features

    if o.mn.dofe
        fn = fieldnames(o.fe);
        for m = 1:numel(fn)
            optid = fn{m};
            fe.(optid) = femake(stack, pth.stack, t, o.fe.(optid)); %extract features from stack, stim, or behavior (e.g. bump from stack, optic flow from visual stimulus)
        end
    end

    %% models

    if o.mn.dofit
        fn = fieldnames(o.mdl);
        for m = 1:numel(fn)
            optid = fn{m};
            
            tgi.roi.rgname = 'tm';
            tgi.roi.domm = 1;
            tgi.roi.mm.maskname = 'ten';
            indv = tsget(tgi);
            
            tgd.roi.rgname = 't5';
            tgd.roi.domm = 1;
            tgd.group = '1';
            depv = tsget(tgd);

            o.mdl.a1.mdlname = 'svd_0.97';
            mdl = mdlmake(indv, depv, md.volrate, pth.stack, o.mdl.(optid), vis.epochts);
            
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


    %% specialized

    % ebno({'r'}, vis.yaw, ball.yaw, fe.(optid).mu, fe.(optid).respcl, roi.a23.ts{1}, roi.a24.ts{1}, t, md.sampper, pth.pre, plt=[0 0 1 0], facealpha=0.2, szthrres=[], szmin=10, szmaxfac=70, nothr='', colsep=0, xyrng=[], epoch={6}, epochts=vis.epochts, lagsampxy=0, lagsampz=[-2:2], yconst=1, slopelensec=[])
    % t5tmp
    % mitotmp


end



