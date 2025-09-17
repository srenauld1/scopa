
function ebnotmp(stack, side, cue, ball, ballfv, bump, eb, nol, nor, t, sper, pthpre, gld, glv, grd, grv, opt)


arguments
    stack
    side
    cue
    ball
    ballfv
    bump
    eb
    nol
    nor
    t
    sper
    pthpre
    gld
    glv
    grd
    grv
    opt.widyxz = []
    opt.lagsampxy = 0
    opt.lagsampz = 0
    opt.facealpha = 0.3;
    opt.ncol = 1 %if <=1, number colors as proportion of total number of plotted samples, otherwise number colors
    opt.szthrxy = []
    opt.szthrres = []
    opt.szmin = 2;
    opt.szmaxfac = 10
    opt.xyrng = []
    opt.nothr = []
    opt.colsep = 0
    opt.epoch = []
    opt.epochts = []
    opt.slopelensec = []
    opt.slopeord = 2
    opt.fitlinealpha =  0
    opt.yconst = 0
    opt.plt = []
    opt.histplt = 0
    opt.bmpdomain = [];
    opt.tsub = []
    opt.dozscore = []
    opt.drawrot = []
    opt.sliceeb = []
end
widyxz = opt.widyxz;
lagsampxy = opt.lagsampxy;
lagsampz = opt.lagsampz;
szmin = opt.szmin;
facealpha = opt.facealpha;
ncol = opt.ncol;
szthrxy = opt.szthrxy;
szthrres = opt.szthrres;
szmaxfac = opt.szmaxfac;
xyrng = opt.xyrng;
nothr = opt.nothr;
colsep = opt.colsep;
epoch = opt.epoch;
epochts = opt.epochts;
slopelensec = opt.slopelensec;
slopeord = opt.slopeord;
fitlinealpha = opt.fitlinealpha;
yconst = opt.yconst;
plt = opt.plt;
histplt = opt.histplt;
bmpdomain = opt.bmpdomain;
tsub = opt.tsub;
dozscore = opt.dozscore;
drawrot = opt.drawrot;
sliceeb = opt.sliceeb;

if isempty(epochts)
    epochts = ones(size(cue));
end
if isempty(epoch)
    epoch = {unique(epochts)};
end

for k = 1:numel(side)
    for m = 1:numel(epoch)
        for q = 1:numel(lagsampz)
            for q2 = 1:numel(lagsampxy)

                ebno_one(stack, side{k}, cue, ball, ballfv, bump, eb, nol, nor, t, sper, pthpre, gld, glv, grd, grv, widyxz, lagsampxy(q2), lagsampz(q), szmin, facealpha, ncol, szthrxy, szthrres, szmaxfac, xyrng, nothr, colsep, epoch{m}, epochts, slopelensec, slopeord, fitlinealpha, yconst, plt, histplt, bmpdomain, tsub, dozscore, drawrot, sliceeb)
                % close all

                if ~plt(3) && ~plt(4) %don't loop over conditions if you're just plotting timeseries or bump (only loop for scatterplots)
                    return
                end

            end
        end
    end
end


end


function ebno_one(stack, side, cue, ball, ballfv, bump, eb, nol, nor, t, sper, pthpre, gld, glv, grd, grv, widyxz, lagsampxy, lagsampz, szmin, facealpha, ncol, szthrxy, szthrres, szmaxfac, xyrng, nothr, colsep, epoch, epochts, slopelensec, slopeord, fitlinealpha, yconst, plt, histplt, bmpdomain, tsub, dozscore, drawrot, sliceeb)



datestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));


epochstr = sprintf('%.0f,' , epoch);
epochstr = epochstr(1:end-1);

if isempty(widyxz)
    widyxz = [1,1,1];
end

if ~isempty(szthrxy) && ~isempty(szthrres)
    error("can only use szthrres or szthrxy")
end

kp1 = sampepoch(epochts, epoch);

if ~isscalar(lagsampxy) || ~isscalar(lagsampz)
    error("make lagsec scalar for now")
end

if strcmp(side, 'l')
    no = nol;
elseif strcmp(side, 'r')
    no = nor;
elseif isempty(side)
    no = ones(size(cue));
end

if isempty(cue)
    cue = nan(size(t));
end


noz = zscore(no);
nodv = tsdv('radians', no, slopelensec, slopeord, sper);

bumpdv = tsdv('radians', bump, slopelensec, slopeord, sper);
bumpdvrs = bumpdv*pi/max(abs(bumpdv));

ballinv = -ball;
ballinvdv = tsdv('radians', ballinv, slopelensec, slopeord, sper);
ballinvdvrs = ballinvdv*pi/max(abs(ballinvdv));

if yconst
    limxtreme = max(abs(vec([ballinvdvrs bumpdvrs])));
end

it = t2samp(tsub, t);
lim_t = [min(t) max(t)];
lim_it = [min(it) max(it)];
lim_tsub = [min(tsub) max(tsub)];

%% bump only

if ~isempty(plt) && plt(1)

    maxnumts = 8;
    cmap = lines(maxnumts); %'lines' predefined colormap is the default for function 'plot'
    cmap = cat(1, cmap, [0 0 0]); %add black

    % stackplt3(stack, it=limtsamp, style='MaximumIntensityProjection')

    bumpnan = polarnan(bump); %insert nan where wrap
    ballinvnan = polarnan(ballinv); %insert nan where wrap
    cuenan = polarnan(cue); %insert nan where wrap


    slopelensec_eb = sper*3;
    slopeord_eb = 2;
    eb2 = eb;
    for k = 1:size(eb2,1)
        % eb(k,:) = rescale(eb(k,:));
        eb2(k,:) = tsdv('normal', eb2(k,:), slopelensec_eb, slopeord_eb, sper);
        eb2(k,:) = zscore(eb2(k,:));
    end
    % eb2 = imgaussfilt(eb2, [0.1 0.1]);

    % pthgif = pathauto(suffix='.gif', usetime=1);
    % hfg = figure;
    % hax = axes(Parent=hfg);
    % for k = 1:size(eb2,1)
    %     histogram(hax, eb2(k,:));
    %     xlim([-max(abs(eb2(:))) max(abs(eb2(:)))])
    %     ylim([0 4000])
    %     fig2gif(hfg,k,pthgif)
    % end


    bumpmethodnew = 'max';
    switch bumpmethodnew
        case 'max'
            eb2 = eb;
            [~, tmp] = max(eb2);
            bump2 = interp1(linspace(-pi, pi, size(eb2,1)+1), tmp);
        case 'pva'
            [bump2, bmprho, circvar] = circmnvar(bmpdomain(:)', eb2-min(eb2), 0);
    end

    bump2nan = polarnan(bump2); %insert nan where wrap

    %%


    nozinv = -noz;
    nozmaxabs = max(abs(nozinv));
    nozmaxabspad = nozmaxabs+range(nozinv)*0.1;
    limnopad = [-nozmaxabs nozmaxabs];
    limpad = [-nozmaxabspad nozmaxabspad];

    slopelensec_alt = sper*3;
    slopeord_alt = 2;

    dodv = 0;
    if dodv %all derivatives
        ballplot = tsdv('radians', ballinv, slopelensec_alt, slopeord_alt, sper);
        cueplot = tsdv('radians', cue, slopelensec_alt, slopeord_alt, sper);
        bumpplot = tsdv('radians', bump, slopelensec_alt, slopeord_alt, sper);
        bump2plot = tsdv('radians', bump2, slopelensec_alt, slopeord_alt, sper);
    else
        ballplot = ballinvnan;
        cueplot = cuenan;
        bumpplot = bumpnan;
        bump2plot = bump2nan;
    end


    ballplot = ballplot*nozmaxabs/max(abs(ballplot));  %put on same scale
    cueplot = cueplot*nozmaxabs/max(abs(cueplot));  %put on same scale
    bumpplot = bumpplot*nozmaxabs/max(abs(bumpplot));  %put on same scale
    bump2plot = bump2plot*nozmaxabs/max(abs(bump2plot));  %put on same scale

    %% timeseries


    hfg = figure;
    hax = axes(parent=hfg);
    hold(hax, 'on')
    plot(hax, t, zscore(nor), color=cmap(1,:));
    % plot(hax, t, zscore(nol), color=cmap(2,:));
    plot(hax, t, cueplot, color=cmap(3,:));
    plot(hax, t, ballplot, color=cmap(4,:));
    plot(hax, t, bumpplot, color=cmap(5,:));
    % plot(hax, t, bump2plot, color=cmap(5,:), linestyle='--');
    xlim(hax, lim_t)
    ylim(hax, limpad)
    yline(hax, 0, '-k')
    hold(hax, 'off')

    title(hax, "cue direction black, negative ball direction red, z-scored glno blue")

    pthsv = [pthpre 'bump_.fig'];
    saveas(gcf, pthsv)

    %% bump as heatmap


    dozscore_hm = 1;
    if dozscore_hm
        for k = 1:size(eb,1)
            % eb(k,:) = rescale(eb(k,:));
            % eb(k,:) = tsdv('normal', eb(k,:), slopelensec_eb, slopeord_eb, sper);
            eb(k,:) = zscore(eb(k,:));
        end
        % eb(eb<0) = 0;
        % eb = stackthr(eb);
    end



    ax = axarr([1,1]);
    h = fg(szf=2);

    subplot_ind = 1;
    htfac = 1;
    h = axim(eb, h=h, ax=ax, notim=1, subplot_ind=subplot_ind, htfac=htfac, noax=0);
    hold(h.im.ax{1}, "on")
    h.im.pl{1}.XData = t;
    % plot(h.im.ax{1}, t, rescale(bumpnan, 1, size(eb,1)), color='m')
    plot(h.im.ax{1}, t, rescale(ballinvnan, 1, size(eb,1)), color=cmap(4,:))
    plot(h.im.ax{1}, t, rescale(ballfv, 1, size(eb,1)), color=cmap(5,:))
    % plot(h.im.ax{1}, t, rescale(bump2nan, 1, size(eb,1)), color='g')
    plot(h.im.ax{1}, t, rescale(cuenan, 1, size(eb,1)), color=cmap(3,:))
    wsz = 30;
    [gldtmp, wsz] = smoothdata(gld, 'sgolay', wsz);
    [glvtmp, wsz] = smoothdata(glv, 'sgolay', wsz);
    % plot(h.im.ax{1}, t, rescale(gldtmp, 1, size(eb,1)), color=cmap(1,:), linestyle='-', linewidth=2);
    % plot(h.im.ax{1}, t, rescale(glvtmp, 1, size(eb,1)), color=cmap(1,:), linestyle=':', linewidth=2);
    [grdtmp, wsz] = smoothdata(grd, 'sgolay', wsz);
    [grvtmp, wsz] = smoothdata(grv, 'sgolay', wsz);
    plot(h.im.ax{1}, t, rescale(grdtmp, 1, size(eb,1)), color=cmap(2,:), linestyle='-', linewidth=2);
    plot(h.im.ax{1}, t, rescale(grvtmp, 1, size(eb,1)), color=cmap(2,:), linestyle=':', linewidth=2);

    xlim(lim_t)
    title('eb (heatmap), gall left (blue), gall right (red), cue (yellow), ball yaw (purple)')
    numxtick = 20;
    h.im.ax{1}.XTick = linspace(lim_t(1), lim_t(2), numxtick);
    h.im.ax{1}.XTickLabel = h.im.ax{1}.XTick;
    hold(h.im.ax{1}, "on")

    % subplot_ind = 2;
    % htfac = 2;
    % h = axim(eb2, h=h, ax=ax, notim=1, subplot_ind=subplot_ind, htfac=htfac, noax=0);
    %
    % hold(h.im.ax{1}, "on")
    % h.im.pl{1}.XData = t;
    % plot(h.im.ax{1}, t, rescale(bumpnan, 1, size(eb,1)), color='m')
    % plot(h.im.ax{1}, t, rescale(bump2nan, 1, size(eb,1)), color=[0.1, 0.8, 0.8])
    % plot(h.im.ax{1}, t, rescale(cuenan, 1, size(eb,1)), color='y')
    % xlim(lim_t)
    % title('eb2')
    % numxtick = 20;
    % h.im.ax{1}.XTick = linspace(lim_t(1), lim_t(2), numxtick);
    % h.im.ax{1}.XTickLabel = h.im.ax{1}.XTick;
    % hold(h.im.ax{1}, "on")



    % subplot_ind = 1;
    % h.ts = axts(h.fg, no, ax=ax, t=t, subplot_ind=subplot_ind);

    % title("eb pva blue, eb max(dv) red, cue yellow", Position=[0 1])

    pthsv = [pthpre 'bump_.fig'];
    saveas(gcf, pthsv)
    %
    %%
    %
    % glom = 20;
    % epochx = [2:5];
    % figure
    % for k = 1:numel(epochx)
    %     kp11 = zeros(size(epochts), 'logical');
    %     kp11 = kp11 | ismember(epochts, epochx(k));
    %     kp11 = kp11(1:numel(ballinvdvrs)); %just crop a samples at end to match length of timeseries after lag
    %     cuedv = tsdv('radians', cue, slopelensec_alt, slopeord_alt, sper);
    %     subplot(2,2,k)
    %     scatter(eb(glom,kp11), cuedv(kp11), 'filled')
    %     ylim([-3.4,3.4])
    %     xlim([20,150])
    %     title(k)
    % end
    % sgtitle("down roi")
    %
    % glom = 25;
    % epochx = [2:5];
    % figure;
    % for k = 1:numel(epochx)
    %     kp11 = zeros(size(epochts), 'logical');
    %     kp11 = kp11 | ismember(epochts, epochx(k));
    %     kp11 = kp11(1:numel(ballinvdvrs)); %just crop a samples at end to match length of timeseries after lag
    %     cuedv = tsdv('radians', cue, slopelensec_alt, slopeord_alt, sper);
    %     subplot(2,2,k)
    %     scatter(eb(glom,kp11), cuedv(kp11), 'filled')
    %     ylim([-3.4,3.4])
    %     xlim([20,150])
    %     title(k)
    % end
    % sgtitle("up roi")

    if 1
        %% bump as curve over time

        if isempty(dozscore)
            prompt = sprintf("ENTER 1 TO ZSCORE EB ROIS, 0 TO NOT: ");
            commandwindow();
            dozscore = input(prompt);
        end

        if dozscore
            for k = 1:size(eb,1)
                % eb(k,:) = rescale(eb(k,:));
                % eb(k,:) = tsdv('normal', eb(k,:), slopelensec_eb, slopeord_eb, sper);
                eb(k,:) = zscore(eb(k,:));
            end
        end

        sznew = 40; %max(size(stackmnt));
        % stackeb = stackcrop(stack, 'eb');

        stack = stack(:,:,:,it);
        stackeb = stack;
        % stackeb = stackiso(stackeb, widyxz);

        stackeb_mnt = mean(stackeb,4);

        if isempty(drawrot)

            rots = -1*[0:10:180];
            stackmnzrot = {};
            for k = 1:numel(rots)
                tform = rigidtform3d([rots(k),0,0], [0,0,0]);
                tmp = imwarp(stackeb_mnt, imref3d(size(stackeb_mnt)), tform); %default output view is centeroutput
                stackmnzrot{k} = mean(tmp, 3);
            end
            szmx = max(cell2mat(cellfun(@size, stackmnzrot, 'UniformOutput', false)'));
            tmp = zeros([szmx, numel(stackmnzrot)]);
            for k = 1:numel(stackmnzrot)
                tmp(1:size(stackmnzrot{k},1), 1:size(stackmnzrot{k},2), k) = stackmnzrot{k};
            end
            stackplt(tmp, dmplt='yx(z)', title_prefix=['rotations: ' num2str(rots)]);
            stackplt(tmp, title_prefix=['rotations: ' num2str(rots)]);


            prompt = sprintf("ENTER DEGREES TO ROTATE STACK FORWARD (ALONG X AXIS), OR EMPTY TO NOT ROTATE: ");
            commandwindow();
            drawrot = input(prompt);

        end

        if drawrot
            drawrot = drawrot * -1;
            tform = rigidtform3d([drawrot,0,0], [0,0,0]);
            rf = imref3d(size(stackeb_mnt));
            for k = 1:size(stackeb,4)
                tmp = imwarp(stackeb(:,:,:,k), rf, tform); %default output view is centeroutput
                if k==1
                    stackebrt = zeros([size(tmp) size(stackeb,4)], class(stackeb));
                end
                stackebrt(:,:,:,k) = tmp;
            end
            stackeb = stackebrt;
            stackebrt = [];
        end

        stackeb_mnt = mean(stackeb,4);

        dr = [0 1];

        stackmin = double(min(stackeb(:)));
        stackmax = double(max(stackeb(:)));
        stackrange = stackmax-stackmin;
        clim_tmp = stackrange*dr+stackmin; %cdata limits set from whole EB region, rather than chosen subset

        if isempty(sliceeb)
            stackplt(stackeb_mnt, dmplt='yx(z)')
            prompt = sprintf("ENTER Z-INDICES YOU WANT TO AVERAGE TO PLOT EB ACTIVITY, OR ENTER NOTHING TO AVERAGE ALL Z INDICES: ");
            commandwindow();
            sliceeb = input(prompt);
        end

        if isempty(sliceeb)
            sliceeb = 1:size(stackeb_mnt, 3);
        end
        stackeb = mean(stackeb(:,:,sliceeb,:),3);
        % stackeb = median(stackeb(:,:,sliceeb,:),3);
        stackeb = squeeze(stackeb);

        nolz = zscore(nol);
        norz = zscore(nor);

        hfg = figure;

        hax = subplot(2,1,1);
        hpl = plot(hax, bmpdomain, eb(:,1));

        ttl = title(hax, '');
        yyaxis right
        hold on
        hbr1 = bar(3.2, 1, 0.25);
        hbr2 = bar(3.5, 1, 0.25);
        hbr4 = bar(-3.4, 1, 0.25);

        contrastfac = 1;

        hax2 = subplot(2,1,2);
        hax2.DataAspectRatio = [1 1 1];
        hax2.Colormap = gray(256);
        hax2.CLim = clim_tmp*contrastfac;
        hax2.Visible = 'off';
        hax2.YDir = 'reverse';
        hpl2 = image(hax2, 'CData', stackeb(:,:,1));
        hpl2.CDataMapping = 'scaled';

        % hln1 = xline(hax, 0, color=cmap(1,:));
        hln2 = xline(hax, 0, color=cmap(2,:));
        hln3 = xline(hax, 0, color=cmap(3,:));

        % hln4 = xline(hax, 0, color=cmap(4,:));
        limy = axlim(eb);
        hax.YAxis(1).Limits = limy.allpad;
        hax.YAxis(2).Limits = [min([norz nolz]) max([norz nolz])];
        % hax.YLim = [-4 4];
        % hax.YLim = [0 1];
        hax.XLim = [-pi pi]*1.2;
        incc = 1;
        for k = 1:incc:numel(it) %for each timepoint, show bump
            hpl.YData = eb(:,it(k));
            % hpl.YData = eb2(:,limtsamp(k));
            % hln1.Value = bump(it(k));
            hln2.Value = cue(it(k));
            hln3.Value = ballinv(it(k));
            % hln4.Value = bump2(it(k));
            hpl2.CData = stackeb(:,:,k);
            hbr1.YData = nolz(k);
            hbr2.YData = norz(k);
            hbr4.YData = ballfv(k);
            ttl.String = {['cue (red), ball (yellow)']; ['t: ' num2str(t(it(k))) ', epoch: ' num2str(epochts(it(k)))]};
            fig2gif(hfg,k)
        end

    end


    %%
end

%% timeseries plot

if ~isempty(plt) && plt(2)

    nozrs = noz*max(abs(nodv))/max(abs(noz)); %put z-score and derivative on same scale

    bg = [nodv; nozrs]; %background; z-scored nodulus and derivative of nodulus

    cuenan = polarnan(cue); %insert nan where wrap
    ballinvnan = polarnan(ballinv); %insert nan where wrap
    bumpnan = polarnan(bump); %insert nan where wrap

    cmap = cmapmake(nodes={'r', 'k', 'b'});
    maxabs = max(abs(vec(bg)));
    hfg = figure;
    hax = axes(Parent=hfg);
    hpl = imagesc(hax, bg);
    hax.Colormap = cmap;
    hax.YDir= 'reverse';
    hax.CLim = [-maxabs maxabs]; %zero-centered lim
    hpl.CDataMapping = 'scaled';
    yyaxis right;
    hold on;
    plot(hax, cuenan, 'g-')
    plot(hax, ballinvnan, 'y-')
    % plot(hax, ballinvdvrs, 'm-')
    % plot(hax, bumpnan, 'c-')
    % plot(hax, bumpdvrs, 'w-')
    title("bump cyan, ball yellow, cue green, " + side + " GLNO derivative background")

    pthsv = [pthpre side '_glno_.fig'];
    saveas(gcf, pthsv)

end

%% scatterplot

if ~isempty(plt) && plt(3)


    nolz3 = zscore(nol);
    norz3 = zscore(nor);
    nodv = nolz3-norz3;
    nodv = cue;
    bumpdvrs = mean(eb);
    bumpdvrs = eb(30,:);
    ballinvdvrs = norz3;
    ballinvdvrs = nolz3;


    pthsv = [pthpre 'glno_scatter_' datestr '_' side '_' num2str(lagsampxy) '_' num2str(lagsampz) '_' epochstr '_.fig'];

    xydist = sqrt(ballinvdvrs.^2 + bumpdvrs.^2); %distance from origin

    %%%%% LAG %%%%%

    [ballinvdvrs, bumpdvrs, nodv] = lagvars(ballinvdvrs, bumpdvrs, nodv, lagsampxy, lagsampz);
    if any(any(isnan([ballinvdvrs, bumpdvrs, nodv])))
        % [ballinvdvrs, bumpdvrs, nodv] = remove_nans_as_group(ballinvdvrs, bumpdvrs, nodv);%%plotz becomes ones if z_is_empty, is this okay??
        error("there should not be any nans yet")
    end


    %%%%% COLORMAP %%%%%

    [nodvsrt, idx4] = sort(nodv);
    ballinvdvrs = ballinvdvrs(idx4);
    bumpdvrs = bumpdvrs(idx4);
    kp1 = kp1(idx4);
    if ncol<=1
        ncol = round(numel(nodvsrt)*ncol);
    end
    cmap = cmapmake(nodes={'r', 'k', 'b'}, ncol=floor(ncol/2));
    if colsep %separate scales for neg and pos, but still zero centered
        halflen = size(cmap,1)/2;
        xref = linspace(min(nodvsrt), 0, halflen); %zero-centered colormap
        cmapneg = interp1(xref, cmap(1:halflen,:), nodvsrt(nodvsrt<0));
        xref = linspace(0, max(nodvsrt), halflen); %zero-centered colormap
        cmappos = interp1(xref, cmap(halflen+1:end,:), nodvsrt(nodvsrt>=0));
        cmap = [cmapneg; cmappos];
    else %single scale for neg and pos, and zero centered
        maxabs = max(abs(vec(nodvsrt)));
        xref = linspace(-maxabs, maxabs, size(cmap,1)); %zero-centered colormap
        cmap = interp1(xref, cmap, nodvsrt);
    end


    %%%%% LLS FIT %%%%%

    ft = polyfit(ballinvdvrs, bumpdvrs, 1); %also do this after color sorting so you don't have to sort
    fty = polyval(ft, ballinvdvrs);
    resid = sqrt((fty-bumpdvrs).^2 );
    xrng = linspace(min(ballinvdvrs), max(ballinvdvrs), 100);
    ftline = polyval(ft, xrng);


    %%%%% ADJUST MARKER SIZE BY DISTANCE FROM FIT LINE OR ORIGIN %%%%%


    if ~isempty(szthrres)
        sztmp = resid;
        szthr = szthrres;
    elseif ~isempty(szthrxy)
        sztmp = xydist;
        szthr = szthrxy;
    else
        szthr = ones(size(xydist));
        sztmp = ones(size(xydist));
    end
    % szthr = szthr*max(abs(sztmp));
    szthr = quantile(sztmp, szthr);
    isminsz = sztmp<=szthr;
    sztmp(isminsz) = min(sztmp(:)); %below threshold is given baseline marker size
    sztmp = rescale(sztmp, szmin, szmin*szmaxfac); %and above is scaled up to max marker size



    %%%%% EXCLUDE BY GLNO RESPONSE AMPLITUDE %%%%%

    % nodvtmp = tsdv('radians', nodv, 0.3, 2, sper);
    % kp33 = nodvtmp<0;
    % % kp33 = nodvtmp>0;
    % [ballinvdvrs, bumpdvrs, nodvsrt, sztmp, cmap, xydist] = tscrop(kp33, ballinvdvrs, bumpdvrs, nodvsrt, sztmp, cmap, xydist);


    if ~isempty(nothr)
        if ischar(nothr)
            if strcmp(nothr, 't')
                [hcnt, hed] = histcounts(abs(nodvsrt));
                thrbin = triangle_threshold(hcnt, 'R', histplt, [pthsv(1:end-4) 'histABS_.gif']);
                thrval(1) = hed(thrbin) + mean(diff(hed))/2;
            elseif strcmp(nothr, 'tn')
                if ~any(nodvsrt<0) || ~any(nodvsrt>0)
                    error("must have positive and negative values to use nothr tn")
                end
                [hcnt, hed] = histcounts(nodvsrt);
                thrbin = triangle_threshold(hcnt, 'R', histplt, [pthsv(1:end-4) 'histR_.gif']);
                thrval(1) = hed(thrbin) + mean(diff(hed))/2;
                thrbin = triangle_threshold(hcnt, 'L', histplt, [pthsv(1:end-4) 'histL_.gif']);
                thrval(2) = hed(thrbin) - mean(diff(hed))/2;
            end
        else
            thrval = max(abs(nodvsrt))*nothr;
        end

        if isscalar(thrval)
            kp2 = nodvsrt>thrval(1);
        else
            if thrval(1)<thrval(2)
                kp2 = nodvsrt>thrval(1) & nodvsrt<thrval(2);
            else
                kp2 = nodvsrt>thrval(1) | nodvsrt<thrval(2);
            end
        end

        [ballinvdvrs, bumpdvrs, nodvsrt, sztmp, cmap, xydist] = tscrop(kp2, ballinvdvrs, bumpdvrs, nodvsrt, sztmp, cmap, xydist);

    end


    %%%%% EXCLUDE BY EPOCH %%%%%

    kp1 = kp1(1:numel(ballinvdvrs)); %just crop a samples at end to match length of timeseries after lag
    [ballinvdvrs, bumpdvrs, nodvsrt, sztmp, cmap, xydist] = tscrop(kp1, ballinvdvrs, bumpdvrs, nodvsrt, sztmp, cmap, xydist);


    %%%%% EXCLUDE BY DISTANCE FROM ORIGIN %%%%%

    if ~isempty(xyrng)
        xyrng = xyrng*max(abs(xydist));
        kp3 = xydist<xyrng;
        [ballinvdvrs, bumpdvrs, nodvsrt, sztmp, cmap, xydist] = tscrop(kp3, ballinvdvrs, bumpdvrs, nodvsrt, sztmp, cmap, xydist);
    end


    %%%%% PLOT %%%%%

    h = fg();
    hax = axes(Parent=h.fg);
    hold(hax, 'on')
    plot(hax, xrng, ftline, color=[0 0 0 fitlinealpha])
    scatter(hax, ballinvdvrs, bumpdvrs, sztmp, cmap, 'filled', MarkerFaceAlpha=facealpha);
    hold(hax, 'off')
    axis square
    xlabel("ball")
    ylabel("bump")
    if ~yconst
        limxtreme = max(abs([hax.XLim hax.YLim]));
    end
    % hax.XLim = [-limxtreme limxtreme];
    % hax.YLim = [-limxtreme limxtreme];
    title({[side ' glno derivative red neg blue pos black zero']; ['lagx: ' num2str(lagsampxy) ', lagz: ' num2str(lagsampz) ', epoch: ' epochstr]})

    % saveas(gcf, pthsv)
    fig2gif(h.fg, 1, [pthsv(1:end-4) '.gif']) %save as gif


end

%% surface fit to scatter above

if ~isempty(plt) && plt(4)

    numnodes = 50;
    xg = linspace(min(ballinvdvrs),max(ballinvdvrs),numnodes);
    yg = linspace(min(bumpdvrs),max(bumpdvrs),numnodes);
    zsgf = gridfit( double(ballinvdvrs), double(bumpdvrs), double(nodvsrt), double(xg), double(yg));
    hfg = figure;
    hax = axes(Parent=hfg);
    hpl = surf(hax,xg,yg,zsgf);
    if ~yconst
        limxtreme = max(abs([hax.XLim hax.YLim]));
    end
    hax.XLim = [-limxtreme limxtreme];
    hax.YLim = [-limxtreme limxtreme];
    hax.ZLim = [-max(abs(hax.ZLim(:))) max(abs(hax.ZLim(:)))];
    axis( hax, 'vis3d' )
    xlabel("ball")
    ylabel("bump")
    zlabel("GLNO")
    colormap(hot(256))
    camlight right
    lighting phong
    pthsv = [pthpre 'glno_surf_' side '_' num2str(lagsampxy) '_' num2str(lagsampz) '_' epochstr '_' datestr '_.fig'];
    vwel = linspace(0, 50, 10);
    vwel = vwel(1:end-1);
    vwaz = linspace(0, 50, 10);
    vwaz = vwaz(1:end-1);
    [vwaz, vwel] = meshgrid(vwaz, vwel);
    vws = [vwaz(:) vwel(:)];

    fig2gif(hfg, 1, [pthsv(1:end-4) '.gif'])
    % for k = 1:size(vws,1)
    %     hax.View = hax.View + [vws(k,1) vws(k,2)];
    %     fig2gif(hfg, k, [pthsv(1:end-4) '.gif'])
    % end


end


end


function [varx_lagxyz, vary_lagxyz, varz_lagxyz] = lagvars(varx, vary, varz, lagxy, lagz)

%negative lag, first variable follows second (first var shifted right) (but should be opposite prob)
%positive lag first variable precedes second (first var shifted left) (but should be opposite prob)

%first apply xy lag
if lagxy<=0
    varx_lagxy = vec(varx(1+abs(lagxy):end));
    vary_lagxy = vec(vary(1:end-abs(lagxy)));
else
    varx_lagxy = vec(varx(1:end-abs(lagxy)));
    vary_lagxy = vec(vary(1+abs(lagxy):end));
end

%now apply z lag
if lagz<=0
    varx_lagxyz = vec(varx_lagxy(1+abs(lagz):end));
    vary_lagxyz = vec(vary_lagxy(1+abs(lagz):end));
    varz_lagxyz = vec(varz(1:end - (abs(lagxy)+abs(lagz)))); %also include lagxy for 3rd var
else
    varx_lagxyz = vec(varx_lagxy(1:end-abs(lagz)));
    vary_lagxyz = vec(vary_lagxy(1:end-abs(lagz)));
    varz_lagxyz = vec(varz( (1+abs(lagxy)+abs(lagz) ):end));
end

end



function [varx_lagxyz, vary_lagxyz, varz_lagxyz] = remove_nans_as_group(varx_lagxyz, vary_lagxyz, varz_lagxyz)

keepind = ~(isnan(varx_lagxyz) | isnan(vary_lagxyz));
varz_lagxyz_isnan = isnan(varz_lagxyz);
if any(varz_lagxyz_isnan)
    keepind = keepind | varz_lagxyz_isnan;
    varz_lagxyz = varz_lagxyz(keepind);
end
varx_lagxyz = varx_lagxyz(keepind);
vary_lagxyz = vary_lagxyz(keepind);
if ~any(varz_lagxyz_isnan)
    varz_lagxyz = ones(numel(varx_lagxyz), 1);
end

end




