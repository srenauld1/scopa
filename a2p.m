
% see docs_a2p
% smr test

function a2p(specin)

arguments
    specin = '' %optional; full path to recording (char or cell, wildcards allow matching rules in rdir), or cell array of full paths (char), or struct with recording specifiers (see specin in oset and odf); if missing or empty, recording(s) searched for in oset using specifiers in oset
end

clear glb tsget %clear global/persistent vars

oa = oset(specin); % set options; oa stands for "o all" (ie options for all recordings)

for k = 1:numel(oa) % loop over recordings

    o = oa(k); %index into options for one recording, o
    glb(1, pthstackdir=o.id.pthstackdir, pthstack=o.id.pthstack, recid=o.id.recid, pthrec=o.id.pthrec); %update some globals for this element of o

    %% paths

    pth = pthmake(o.id.pthstack);

    %% stack

    for m = transpose(fieldnames(o.sld))
        stack = stackld(o.sld.(m{1})); %load/process stack
    end

    %% metadata

    md = mdsild(pth.stack);
    glb(1, md=md, t=md.sper:md.sper:md.numvol*md.sper, epochts=ones(1, md.numvol));

    %% daq

    for m = transpose(fieldnames(o.daq))
        daq.(m{1}) = daqld(o.daq.(m{1})); %process daq
    end
    glb(1, t=daq.(m{1}).t, epochts=daq.(m{1}).epochts); %set global t using daq, overwriting metadata t

    %% normalize for PMT offset
    minval = prctile(stack(:), 2);
    stack_minremove=stack - minval;
    
    %% rois

    if o.mn.doroi
        for m = transpose(fieldnames(o.roi))
            roi.(m{1}) = roimake(stack_minremove, o.roi.(m{1})); %make (manual and/or automated and/or functional/caiman) rois in 2d or 3d, extract their responses, with normalization options
        end
    end

    %% bump

    if o.mn.dobmp
        for m = transpose(fieldnames(o.bmp))
            bmp.(m{1}) = bmpmake(o.bmp.(m{1})); %fit bump
        end
    end

    %% flymax

    if o.mn.dofmf
        for m = transpose(fieldnames(o.fmf))
            [fmf.(o.fmf.(m{1}).id), fmfvid] = flymaxfe(pth.stack, o.fmf.(m{1})); %extract flymax visual features
        end
    end

    %% models

    if o.mn.dofit
        for m = transpose(fieldnames(o.mdl))
            mdl.(m{1}) = mdlmake(o.mdl.(m{1}), doplt=1);
        end
    end

    %% plots

    if o.mn.dopltx
        fn = fieldnames(o.pltx);
        for m = 1:numel(fn)
            pltx(stack(:,:,:,fk,:), mdl.vars, o.pltx.doui,  ...
                mdl.vnm, o.pltx.vpmap, o.pltx.epochnum, ...
                o.pltx.lagsxy_sec, o.pltx.lagsz_sec, o.pltx.lags_to_plot, ...
                o.pltx.plot_z_as_color, roidat.a1{1}, t, md.sper, zstartsub, ...
                vis.epochts, glb('pltvis'), o.pltx.iz, o.pltx.it, ...
                o.pltx.dr, mdl.fn_save_prefix_short, mdl.pthpre, ...
                pthroiint, nrm, md.widyxz, vid=ftv, stim=stimvid)
        end
    end


    %% specific

    % ebnotmp(stack, {'r'}, daq.a1.vy, daq.a1.by, bmp.a1.mu, bmp.a1.respcl, roi.a2.ts{1}, roi.a3.ts{1}, t, md.sper, pth.pre, plt=[0 0 1 0], facealpha=0.2, szthrres=[], szmin=10, szmaxfac=70, nothr='', colsep=0, xyrng=[], epoch={1}, epochts=daq.a1.epochts, lagsampxy=1, lagsampz=[-5:5], yconst=1, slopelensec=[0.4], bmpdomain=bmp.a1.domain)

    % t5tmp
    % ebtmp
    % mitotmp


end



