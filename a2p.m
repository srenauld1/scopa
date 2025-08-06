
% see docs_a2p

function a2p(specin)

arguments
    specin = '' %optional; full path to recording (char or cell, wildcards allow matching rules in rdir), or cell array of full paths (char), or struct with recording specifiers (see specin in oset and odf); if missing or empty, recording(s) searched for in oset using specifiers in oset
end

clear glb tsget %clear global/persistent vars


%% options

oa = oset(specin); % set options; oa stands for "o all" (ie options for all recordings)

for k = 1:numel(oa) % loop over recordings

    o = oa(k); %index into options for one recording, o


    %% stack

    for m = transpose(fieldnames(o.sld))
        [stack, pthstack_mat] = stackld(o.sld.(m{1}), o.id.pthstack); %load/process stack
    end
    o.id.pthstack = pthstack_mat; oa(k).id.pthstack = pthstack_mat; %update with .mat extension, in case it was tif going in to stackld
    glb(1, pthstackdir=o.id.pthstackdir, pthstack=o.id.pthstack, recid=o.id.recid, pthrec=o.id.pthrec); %update some globals for this element of o


    %% metadata

    md = mdsild(o.id.pthstack);
    glb(1, md=md, srate=md.volrate, t=md.sper:md.sper:md.numvol*md.sper, epochts=ones(1, md.numvol));


    %% daq

    for m = transpose(fieldnames(o.daq))
        daq.(m{1}) = daqld(o.daq.(m{1})); %process daq
    end
    if ~isempty(daq.(m{1}))
        glb(1, t=daq.(m{1}).t, epochts=daq.(m{1}).epochts); %set global t using daq, overwriting metadata t
    end


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
            [fmf.(o.fmf.(m{1}).id), fmfvid] = flymaxfe(o.id.pthstack, o.fmf.(m{1})); %extract flymax visual features
        end
    end


    %% models

    if o.mn.dofit
        for m = transpose(fieldnames(o.mdl))
            mdl.(m{1}) = mdlmake(o.mdl.(m{1}), doplt=1);
        end
    end


    %% interactive plots

    if o.mn.dopltx
        pltx(o.pltx, stack=stack, daq=daq, roi=roi, bmp=[], mdl=mdl, fmf=fmf, t=glb('t'), stimvid=fmfvid)
    end


    %% specific

    inl = fieldmatch(roi, {'rg.rgname', 'no'}, {'mm.maskname', 'left'}, lev=1);
    inr = fieldmatch(roi, {'rg.rgname', 'no'}, {'mm.maskname', 'right'}, lev=1);
    igld = fieldmatch(roi, {'rg.rgname', 'gal'}, {'mm.maskname', 'dorsal'}, lev=1);
    iglv = fieldmatch(roi, {'rg.rgname', 'gal'}, {'mm.maskname', 'ventral'}, lev=1);
    igrd = fieldmatch(roi, {'rg.rgname', 'gar'}, {'mm.maskname', 'dorsal'}, lev=1);
    igrv = fieldmatch(roi, {'rg.rgname', 'gar'}, {'mm.maskname', 'ventral'}, lev=1);
    ieb = fieldmatch(roi, {'rg.rgname', 'eb'}, {'mm.maskname', 'eb'}, lev=1);
    idaq = fieldmatch(daq, lev=1);
    ibmp = fieldmatch(bmp, lev=1);

    % t5tmp
    % ebtmp
    % mitotmp

%% 

    dodv = 1;
    t = glb('t');

    gld = roi.(igld).dat(1).ts;
    glv = roi.(iglv).dat(1).ts;
    grd = roi.(igrd).dat(1).ts;
    grv = roi.(igrv).dat(1).ts;

    dvlen = md.sper*3;
    dvord = 2;
    glddv = tsdv('normal', gld, dvlen, dvord, md.sper);
    glvdv = tsdv('normal', glv, dvlen, dvord, md.sper);
    grddv = tsdv('normal', grd, dvlen, dvord, md.sper);
    grvdv = tsdv('normal', grv, dvlen, dvord, md.sper);

    iepoch = 1:6;
    hfg = figure;
    hax = axes(parent=hfg);
    hold on;

    for q = 1:numel(iepoch)

        ie = iepoch(q);
        [~, gldtmp, glvtmp, grdtmp, grvtmp] = sampepoch(daq.(idaq).epochts, ie, gld, glv, grd, grv);
        [~, glddvtmp, glvdvtmp, grddvtmp, grvdvtmp] = sampepoch(daq.(idaq).epochts, ie, glddv, glvdv, grddv, grvdv);

        if dodv
            if q==1
                hsc1 = scatter(hax, glddvtmp, glvdvtmp);
                hsc2 = scatter(hax, grddvtmp, grvdvtmp);
                limx = axlim(glddv, grddv, limtype='allpad');
                limy = axlim(glvdv, grvdv, limtype='allpad');
                hax.XLim = limx;
                hax.YLim = limy;
            else
                hsc1.XData = glddvtmp;
                hsc1.YData = glvdvtmp;
                hsc2.XData = grddvtmp;
                hsc2.YData = grvdvtmp;
            end
        else
            if q==1
                hsc1 = scatter(hax, gldtmp, glvtmp);
                hsc2 = scatter(hax, grdtmp, grvtmp);
                limx = axlim(gld, grd, limtype='allpad');
                limy = axlim(glv, grv, limtype='allpad');
                hax.XLim = limx;
                hax.YLim = limy;
            else
                hsc1.XData = gldtmp;
                hsc1.YData = glvtmp;
                hsc2.XData = grdtmp;
                hsc2.YData = grvtmp;
            end
        end
        fig2gif(hfg, q)
    end


    %% 


    stacknew = stackmix(stack, {'gar', 'eb', 'gal'}, rot=[-90,0,0]);
    stackplt(stacknew, dmplt='yx(t)', it=1:3:600)
   
    %%

    ebnotmp(stack, {'r'}, daq.(idaq).vy, daq.(idaq).by, bmp.(ibmp).mu, bmp.(ibmp).respcl, roi.(inr).dat(1).ts, roi.(inl).dat(1).ts, glb('t'), md.sper, o.id.pthpre, ...
        glddv, glvdv, grddv, grvdv, ...
        plt=[1 0 0 0], ...
        facealpha=1, ...
        szthrres=[], ...
        szmin=15, ...
        szmaxfac=70, ...
        nothr='', ...
        colsep=0, ...
        xyrng=[], ...
        epoch={}, ...{[1], [2], [3], [4], [5], [6]}, ...
        epochts=daq.(idaq).epochts, ...
        lagsampxy=-1, ...
        lagsampz=0, ...
        yconst=1, ...
        slopelensec=[0.3], ...
        bmpdomain=bmp.(ibmp).domain, ...
        widyxz=md.widyxz, ...
        tsub=1050:.2:1100, ... 50:.01:200, ...
        dozscore=0, ...
        drawrot=90, ...
        sliceeb=[13])


    %%

    % el2 = mean(roi.a64.dat(1).ts(20:25,:));
    hfg = figure;
    ax = axes('Parent', hfg);
    pax = polaraxes('Units', ax.Units, 'Position', ax.Position);
    tdat = daq.(idaq).vy;
    hpl = polarscatter(pax, tdat, nan(size(tdat)), '.'); %plot
    hpl = scatter(pax, tdat, nan(size(tdat)), '.'); %plot
    % scatter(el2, daq.(di).vy)
    rdatall = roi.a67.dat(1).ts;
    % rdatall = roi.a66.dat(1).ts;
    limr = axlim(rdatall);
    pax.RLim = limr.allpad;

    for q = 1:size(rdatall,1)
        hpl.RData = rdatall(q,:);
        fig2gif(hfg, q)
    end

    %%

    hfg = figure;
    ax = axes('Parent', hfg);
    xdat = roi.a65.dat(1).ts;
    norz = zscore(roi.(inr).dat(1).ts);
    nolz = zscore(roi.(inl).dat(1).ts);
    xdat = norz-nolz;
    ydatall = mean(roi.a67.dat(1).ts);
    hpl = scatter(ax, xdat, nan(size(xdat)), '.'); %plot
    limy = axlim(ydatall);
    ax.YLim = limy.allpad;

    for q = 1:size(ydatall,1)
        hpl.YData = ydatall(q,:);
        fig2gif(hfg, q)
    end



    %%

    dodv = 0;

    cmap = lines(8); %'lines' predefined colormap is the default for function 'plot'
    cmap = cat(1, cmap, [0 0 0]); %add black

    % 
    % h = fg();
    % h.ts = axts(h.fg, glddvtmp, t=t, subplot_ind=1);

    figure;
    hold on;
    if dodv
        plot(t, glddv, color=cmap(1,:), linestyle='-');
        plot(t, glvdv, color=cmap(1,:), linestyle=':', linewidth=2);
        plot(t, grddv, color=cmap(2,:), linestyle='-');
        plot(t, grvdv, color=cmap(2,:), linestyle=':', linewidth=2);
    else
        plot(t, gld, color=cmap(1,:), linestyle='-');
        plot(t, glv, color=cmap(1,:), linestyle=':', linewidth=2);
        plot(t, grd, color=cmap(2,:), linestyle='-');
        plot(t, grv, color=cmap(2,:), linestyle=':', linewidth=2);
    end
    ylim([hax.YLim(1)-hax.YLim(1)*0.05, hax.YLim(2)+hax.YLim(2)*0.05]);
    yyaxis right;
    bfv_rs = rescale(daq.(idaq).bfv, -pi, pi);
    hpl21 = plot(t, daq.(idaq).vy, color=cmap(3,:), linestyle='-');
    hpl23 = plot(t, bfv_rs, color=cmap(4,:), linestyle='-');
    hpl22 = plot(t, -daq.(idaq).by, color=cmap(end,:), linestyle='-');
    hpl21.Parent.YAxis(2).Color = [0 0 0];
    pthsv = ['~/stacks/gall.fig'];
    saveas(gcf, pthsv)

    %%


    hfg = figure;
    hax = axes(parent=hfg);
    hold on;
    plot(t, glddvtmp, color=cmap(1,:), linestyle='-');
    plot(t, glvdvtmp, color=cmap(1,:), linestyle=':', linewidth=2);
    plot(t, grddvtmp, color=cmap(2,:), linestyle='-');
    plot(t, grvdvtmp, color=cmap(2,:), linestyle=':', linewidth=2);
    ylim([hax.YLim(1)-hax.YLim(1)*0.05, hax.YLim(2)+hax.YLim(2)*0.05]);
    yyaxis right;
    hpl21 = plot(t, daq.(idaq).vy, color=cmap(3,:), linestyle='-');
    hpl22 = plot(t, -daq.(idaq).by, color=cmap(end,:), linestyle='-');
    hpl21.Parent.YAxis(2).Color = [0 0 0];

    %%


    cmap = lines(8);
    cmap = cat(1, cmap, [0 0 0]); %add black
    close all
    figure; hold on;
    norz = zscore(roi.(inr).dat(1).ts);
    nolz = zscore(roi.(inl).dat(1).ts);
    limy = axlim(cat(1, norz, nolz));
    el2rs = rescale(el2, limy.all(1), limy.all(2));
    plot(glb('t'), norz, color=cmap(1,:));
    plot(glb('t'), nolz, color=cmap(2,:));
    % yyaxis right; hold on;
    plot(glb('t'), el2rs, color=cmap(4,:));
    yline(0);
    ylim(limy.allpad)
    yyaxis right; hold on;
    plot(glb('t'), daq.(idaq).by, color=cmap(3,:));
    plot(glb('t'), daq.(idaq).vy, color=cmap(9,:), linestyle='-');


    %%

    tic; tmp = stack(:,:,:,800:1200); [fukdb, psfe] = stackdb(tmp, doiso=1, widyxz=md.widyxz, itplt=1:4:400, dmplt='yxz(t)'); toc;


    %%



end


