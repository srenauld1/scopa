
% see docs_a2p

function a2p(specin)

arguments
    specin = '' %optional; full path to recording (char or cell, wildcards allow matching rules in rdir), or cell array of full paths (char), or struct with recording specifiers (see specin in oset and odf); if missing or empty, recording(s) searched for in oset using specifiers in oset
end

clear glb %clear globals

oa = oset(specin); % set options; oa stands for o all (ie all recordings)

for k = 1:numel(oa) % loop over recordings

    o = oa(k); %index into options for one recording, o

    %% paths

    pth = pthmake(o);
    glb(1, pthstackdir=pth.pthstackdir, pthstack=pth.stack); %update some globals

    %% stack

    stack = stackpr(pth.stack, o.spr); %load/process stack

    %% metadata

    md = mdsild(pth.stack); 

    %% stimuli

    for m = transpose(fieldnames(o.daq))
        daq.(m{1}) = daqld(pth.stack, o.daq.(m{1})); %process daq
        t = daq.(m{1}).t; %hack for now
    end

    %% rois

    if o.mn.doroi
        for m = transpose(fieldnames(o.roi))
            roi.(m{1}) = roimake(stack, pth.stack, t, md.sampper, md.widyxz, o.roi.(m{1})); %make (manual and/or automated and/or functional/caiman) rois in 2d or 3d, extract their responses, with normalization options
        end
    end

    %% features (bump, optic flow, etc)

    for f = o.mn.fe
        switch f
            case 'bmp'
                for m = transpose(fieldnames(o.(f)))
                    indv = daq.vy; %hard coding this for now
                    depv = roi.a5.ts{1};
                    bmp.(m{1}) = bmpmake(indv, depv, md.volrate, daq.epochts, pth.stack, o.bmp.(m{1})); %fit bump
                end
            case 'fmf'
                [fmf.(o.fmf.id), fmfvid] = flymaxfe(pth.stack, o.fmf); %extract flymac visual features
        end
    end

    %% models

    if o.mn.dofit
        for m = transpose(fieldnames(o.mdl))
            mdl = mdlmake(o.mdl.(m{1}));
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
    % ebtmp
    % mitotmp


end



