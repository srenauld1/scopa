    nol = ts.roi.i18{1};
    nor = ts.roi.i19{1};

    dvl = tsdv('circular', nol, 0.5, 2, 1/md.volrate);
    dvr = tsdv('circular', nor, 0.5, 2, 1/md.volrate);


    cmap = cmapmake(nodes={'r', 'k', 'b'});
    tmpno2 = [dvl; dvr];
    tmpno = [dvl;dvl;dvl;dvl;dvl;dvl;dvl;dvl];
    maxabs = max(abs(vec(tmpno)));
    hfg = figure; 
    hax = axes(Parent=hfg); hpl = imagesc(hax, tmpno);
    hax.Colormap = cmap;
    hax.YDir= 'reverse';
    hax.CLim = [-maxabs maxabs]; %zero-centered lim
    hpl.CDataMapping = 'scaled';
    yyaxis right;
    hold on;
    plot(hax, ts.vis.yaw, 'g-')
    plot(hax, -ts.ball.yaw, 'y-')
    plot(hax, ts.bmp.mu, 'c-')
    title("bump cyan, ball yellow, cue green, GLNO derivative background")

    figure; plot(dvr); hold on; plot(dvr)