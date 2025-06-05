
% see docs_a2p

function a2p(specin)

arguments
    specin = '' %optional; full path to recording (char or cell, wildcards allow matching rules in rdir), or cell array of full paths (char), or struct with recording specifiers (see specin in oset and odf); if missing or empty, recording(s) searched for in oset using specifiers in oset
end


%%

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

    %% rois

    if o.mn.doroi
        for m = transpose(fieldnames(o.roi))
            roi.(m{1}) = roimake(stack, o.roi.(m{1})); %make (manual and/or automated and/or functional/caiman) rois in 2d or 3d, extract their responses, with normalization options
        end
    end

    %% bump

    if o.mn.dobmp
        for m = transpose(fieldnames(o.bmp))
            bmp.(m{1}) = bmpmake(o.bmp.(m{1})); %extract head direction bump
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

    di = cell2mat(fieldnames(o.daq));
    bi = cell2mat(fieldnames(o.bmp));
    nri = 'a65';
    nli = 'a66';
    ebnotmp(stack, {'r'}, daq.(di).vy, daq.(di).by, bmp.(bi).mu, bmp.(bi).respcl, roi.(nri).ts{1}, roi.(nli).ts{1}, glb('t'), md.sper, pth.pre, plt=[1 1 0 0], facealpha=0.2, szthrres=[], szmin=10, szmaxfac=70, nothr='', colsep=0, xyrng=[], epoch={1}, epochts=daq.(di).epochts, lagsampxy=1, lagsampz=[-5:5], yconst=1, slopelensec=[0.4], bmpdomain=bmp.(bi).domain, widyxz=md.widyxz, drawrot=[], sliceeb=[])

    % t5tmp
    % ebtmp
    % mitotmp

    %%

    ebnotmp(stack, {'r'}, daq.(di).vy, daq.(di).by, bmp.(bi).mu, bmp.(bi).respcl, roi.(nri).ts{1}, roi.(nli).ts{1}, glb('t'), md.sper, pth.pre, ...
        plt=[1 0 1 0], ...
        facealpha=1, ...
        szthrres=[], ...
        szmin=15, ...
        szmaxfac=70, ...
        nothr='', ...
        colsep=0, ...
        xyrng=[], ...
        epoch={}, ...{[1], [2], [3], [4], [5], [6]}, ...
        epochts=daq.(di).epochts, ...
        lagsampxy=-1, ...
        lagsampz=0, ...
        yconst=1, ...
        slopelensec=[0.3], ...
        bmpdomain=bmp.(bi).domain, ...
        widyxz=md.widyxz, ...
        tsub=0:.01:1, ...
        dozscore=0, ...
        drawrot=90, ...
        sliceeb=6)


    %%

    % el2 = mean(roi.a64.ts{1}(20:25,:));
    hfg = figure;
    ax = axes('Parent', hfg);
    pax = polaraxes('Units', ax.Units, 'Position', ax.Position);
    tdat = daq.(di).vy;
    hpl = polarscatter(pax, tdat, nan(size(tdat)), '.'); %plot
    hpl = scatter(pax, tdat, nan(size(tdat)), '.'); %plot
    % scatter(el2, daq.(di).vy)
    rdatall = roi.a67.ts{1};
    % rdatall = roi.a66.ts{1};
    limr = axlim(rdatall);
    pax.RLim = limr.allpad;

    for q = 1:size(rdatall,1)
        hpl.RData = rdatall(q,:);
        fig2gif(hfg, q)
    end

    %%

    hfg = figure;
    ax = axes('Parent', hfg);
    xdat = roi.a65.ts{1};
    norz = zscore(roi.(nri).ts{1});
    nolz = zscore(roi.(nli).ts{1});
    xdat = norz-nolz;
    ydatall = mean(roi.a67.ts{1});
    hpl = scatter(ax, xdat, nan(size(xdat)), '.'); %plot
    limy = axlim(ydatall);
    ax.YLim = limy.allpad;

    for q = 1:size(ydatall,1)
        hpl.YData = ydatall(q,:);
        fig2gif(hfg, q)
    end

    %%

    cmap = lines(8);
    cmap = cat(1, cmap, [0 0 0]); %add black
    close all
    figure; hold on;
    norz = zscore(roi.(nri).ts{1});
    nolz = zscore(roi.(nli).ts{1});
    limy = axlim(cat(1, norz, nolz));
    el2rs = rescale(el2, limy.all(1), limy.all(2));
    plot(glb('t'), norz, color=cmap(1,:));
    plot(glb('t'), nolz, color=cmap(2,:));
    % yyaxis right; hold on;
    plot(glb('t'), el2rs, color=cmap(4,:));
    yline(0);
    ylim(limy.allpad)
    yyaxis right; hold on;
    plot(glb('t'), daq.(di).by, color=cmap(3,:));
    plot(glb('t'), daq.(di).vy, color=cmap(9,:), linestyle='-');


end




