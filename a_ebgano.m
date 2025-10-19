
function a_ebgano(s, roi, daq, bmp, t, opt)


arguments
    s
    roi
    daq
    bmp
    t
    opt.mix = []
    opt.noside = []
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
    opt.slopelensec = []
    opt.slopeord = 2
    opt.fitlinealpha =  0
    opt.yconst = 0
    opt.pltstr = {'ts', 'heat', 'profile', 'hist', 'vol', 'ts2', 'scat', 'surf', 'scat2', 'polar', 'tsepoch'}
    opt.histplt = 0
    opt.vt = []
    opt.dozscore = []
    opt.stackrot = []
    opt.stackslice = []
end
mix = opt.mix;
noside = opt.noside;
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
slopelensec = opt.slopelensec;
slopeord = opt.slopeord;
fitlinealpha = opt.fitlinealpha;
yconst = opt.yconst;
pltstr = opt.pltstr;
histplt = opt.histplt;
vt = opt.vt;
dozscore = opt.dozscore;
stackrot = opt.stackrot;
stackslice = opt.stackslice;


ebmn = mean(stackcrop(s.stack, 'eb'), [1 2 3]);

if ~isempty(mix)
    s = stackmix(s=s, rgnames=mix, rot=stackrot);
    stackrot = []; %set to empty so it doesn't happen below (make this better)
end

stack = s.stack;
pthstack = s.pth;
sper = s.md.sper;
widyxz = s.md.widyxz;

if ndims(stack)~=4
    error("stack must be 4d")
end
if isstring(pltstr)
    pltstr = convertStringsToChars(pltstr);
end
if ~iscell(pltstr)
    pltstr = {pltstr};
end
if isstring(noside)
    noside = convertStringsToChars(noside);
end
if ~iscell(noside)
    noside = {noside};
end

if ~isempty(stackrot) && ( ~isequal(numel(stackrot),3) || ~isvector(stackrot) || iscell(stackrot) )
    error("stackrot must be empty or ordinary length-3 vector")
end

inl = fieldmatch(roi, {'rg.rgname', 'no'}, {'mm.mmname', 'left'}, lev=1);
inr = fieldmatch(roi, {'rg.rgname', 'no'}, {'mm.mmname', 'right'}, lev=1);
igld = fieldmatch(roi, {'rg.rgname', 'gal'}, {'mm.mmname', 'dorsal'}, lev=1);
iglv = fieldmatch(roi, {'rg.rgname', 'gal'}, {'mm.mmname', 'ventral'}, lev=1);
igrd = fieldmatch(roi, {'rg.rgname', 'gar'}, {'mm.mmname', 'dorsal'}, lev=1);
igrv = fieldmatch(roi, {'rg.rgname', 'gar'}, {'mm.mmname', 'ventral'}, lev=1);
ieb = fieldmatch(roi, {'rg.rgname', 'bmpi'}, {'mm.mmname', 'eb4545'}, lev=1);
idaq = fieldmatch(daq, lev=1);
ibmp = fieldmatch(bmp, lev=1);

nol = roi.(inl).dat(1).ts;
nor = roi.(inr).dat(1).ts;
gld = roi.(igld).dat(1).ts;
glv = roi.(iglv).dat(1).ts;
grd = roi.(igrd).dat(1).ts;
grv = roi.(igrv).dat(1).ts;
epochts = daq.(idaq).epochts;
vish = daq.(idaq).vh;
ballh = daq.(idaq).bh;
ballvf = daq.(idaq).bvf;
bmph = bmp.(ibmp).mu;
bmpi = bmp.(ibmp).respcl;
bmpdomain = bmp.(ibmp).domain;

dvlen = sper*3;
dvord = 2;
glddv = tsdv('normal', gld, dvlen, dvord, sper);
glvdv = tsdv('normal', glv, dvlen, dvord, sper);
grddv = tsdv('normal', grd, dvlen, dvord, sper);
grvdv = tsdv('normal', grv, dvlen, dvord, sper);

wsz = 6;
[gld, wsz] = smoothdata(gld, 'sgolay', wsz);
[glv, wsz] = smoothdata(glv, 'sgolay', wsz);
[grd, wsz] = smoothdata(grd, 'sgolay', wsz);
[grv, wsz] = smoothdata(grv, 'sgolay', wsz);


pthpre = erase(s.pth, '.mat');

if isempty(epochts)
    epochts = ones(size(stack,4));
end

for k = 1:numel(noside)
    for m = 1:numel(epoch)
        for q = 1:numel(lagsampz)
            for q2 = 1:numel(lagsampxy)

                tmpfun(stack, noside{k}, vish, ballh, ballvf, bmph, bmpi, nol, nor, t, sper, pthpre, gld, glv, grd, grv, glddv, glvdv, grddv, grvdv, widyxz, lagsampxy(q2), lagsampz(q), szmin, facealpha, ncol, szthrxy, szthrres, szmaxfac, xyrng, nothr, colsep, epoch{m}, epochts, slopelensec, slopeord, fitlinealpha, yconst, pltstr, histplt, bmpdomain, vt, dozscore, stackrot, stackslice, ebmn)
                % close all

                if ~ismember('scat', pltstr) && ~ismember('surf', pltstr) % only loop for scatterplots
                    return
                end

            end
        end
    end
end


end


function tmpfun(stack, noside, vish, ballh, ballvf, bmph, bmpi, nol, nor, t, sper, pthpre, gld, glv, grd, grv, glddv, glvdv, grddv, grvdv, widyxz, lagsampxy, lagsampz, szmin, facealpha, ncol, szthrxy, szthrres, szmaxfac, xyrng, nothr, colsep, epoch, epochts, slopelensec, slopeord, fitlinealpha, yconst, pltstr, histplt, bmpdomain, vt, dozscore, stackrot, stackslice, ebmn)


%%%% PREP VARS %%%%

if ~isempty(szthrxy) && ~isempty(szthrres)
    error("can only use szthrres or szthrxy")
end
if ~isscalar(lagsampxy) || ~isscalar(lagsampz)
    error("make lagsec scalar for now")
end

if ~isequal(epoch, unique(epochts))
    if ~isempty(vt)
        error("cannot pass in name-value argument 'vt' when name-value argument 'epoch' is not equal to all epochs")
    end
    it = find(epochcrop(epochts, epoch));
    vt = t(it);
else
    it = t2i(vt, t); %this works for empty and nonempty vt
end
lim_t = [min(t) max(t)];
lim_it = [min(it) max(it)];
lim_subt = [min(vt) max(vt)];

if strcmp(noside, 'l')
    no = nol;
elseif strcmp(noside, 'r')
    no = nor;
elseif isempty(noside)
    no = ones(size(vish));
end

if isempty(vish)
    vish = nan(size(t));
end
if isempty(widyxz)
    widyxz = [1,1,1];
end

epochstr = sprintf('%.0f,' , epoch);
epochstr = epochstr(1:end-1);

datestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));

cmap = lines(8); % 'lines' predefined colormap is the default for function 'plot'
cmap = cat(1, cmap, [0 0 0]); %add black


noz = zscore(no);
nodv = tsdv('radians', no, slopelensec, slopeord, sper);

bumpdv = tsdv('radians', bmph, slopelensec, slopeord, sper);
bumpdvrs = bumpdv*pi/max(abs(bumpdv));

ballinv = -ballh;
ballinvdv = tsdv('radians', ballinv, slopelensec, slopeord, sper);
ballinvdvrs = ballinvdv*pi/max(abs(ballinvdv));

if yconst
    limxtreme = max(abs(vec([ballinvdvrs bumpdvrs])));
end

bumpnan = polarnan(bmph); %insert nan where wrap
ballinvnan = polarnan(ballinv); %insert nan where wrap
cuenan = polarnan(vish); %insert nan where wrap

slopelensec_eb = sper*3;
slopeord_eb = 2;
eb2 = bmpi;
for k = 1:size(eb2,1)
    % bmpi(k,:) = rescale(bmpi(k,:));
    eb2(k,:) = tsdv('normal', eb2(k,:), slopelensec_eb, slopeord_eb, sper);
    eb2(k,:) = zscore(eb2(k,:));
end
% eb2 = imgaussfilt(eb2, [0.1 0.1]);


bumpmethodnew = 'max';
switch bumpmethodnew
    case 'max'
        eb2 = bmpi;
        [~, tmp] = max(eb2);
        bump2 = interp1(linspace(-pi, pi, size(eb2,1)+1), tmp);
    case 'pva'
        [bump2, bmprho, circvar] = circmnvar(bmpdomain(:)', eb2-min(eb2), 0);
end

bump2nan = polarnan(bump2); %insert nan where wrap

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
    cueplot = tsdv('radians', vish, slopelensec_alt, slopeord_alt, sper);
    bumpplot = tsdv('radians', bmph, slopelensec_alt, slopeord_alt, sper);
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


%%%% TIMESERIES %%%%

if ismember('ts', pltstr)

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

    title(hax, "vish direction black, negative ballh direction red, z-scored glno blue")

    pthsv = [pthpre 'bump_.fig'];
    saveas(gcf, pthsv)

end


%%%% HEATMAP %%%%

if ismember('heat', pltstr)

    dozscore_hm = 1;
    if dozscore_hm
        for k = 1:size(bmpi,1)
            % bmpi(k,:) = rescale(bmpi(k,:));
            % bmpi(k,:) = tsdv('normal', bmpi(k,:), slopelensec_eb, slopeord_eb, sper);
            bmpi(k,:) = zscore(bmpi(k,:));
        end
        % bmpi(bmpi<0) = 0;
        % bmpi = stackthr(bmpi);
    end

    ax = axarr([1,1]);
    h = fg(szf=2);
    h = axim(bmpi, h=h, ax=ax, notim=1, noax=0);
    hold(h.im.ax{1}, "on")
    h.im.pl{1}.XData = t;
    % plot(h.im.ax{1}, t, rescale(bumpnan, 1, size(bmpi,1)), color='m')
    plot(h.im.ax{1}, t, rescale(ballinvnan, 1, size(bmpi,1)), color=cmap(4,:))
    plot(h.im.ax{1}, t, rescale(ballvf, 1, size(bmpi,1)), color=cmap(5,:))
    % plot(h.im.ax{1}, t, rescale(bump2nan, 1, size(bmpi,1)), color='g')
    plot(h.im.ax{1}, t, rescale(cuenan, 1, size(bmpi,1)), color=cmap(3,:))
    plot(h.im.ax{1}, t, rescale(grdtmp, 1, size(bmpi,1)), color=cmap(2,:), linestyle='-', linewidth=2);
    plot(h.im.ax{1}, t, rescale(grvtmp, 1, size(bmpi,1)), color=cmap(2,:), linestyle=':', linewidth=2);

    xlim(lim_t)
    title('bmpi (heatmap), gall left (blue), gall right (red), vish (yellow), ballh yaw (purple)')
    numxtick = 20;
    h.im.ax{1}.XTick = linspace(lim_t(1), lim_t(2), numxtick);
    h.im.ax{1}.XTickLabel = h.im.ax{1}.XTick;
    hold(h.im.ax{1}, "on")

    % idxsubp = 2;
    % htfac = 2;
    % h = axim(eb2, h=h, ax=ax, notim=1, idxsubp=idxsubp, htfac=htfac, noax=0);
    %
    % hold(h.im.ax{1}, "on")
    % h.im.pl{1}.XData = t;
    % plot(h.im.ax{1}, t, rescale(bumpnan, 1, size(bmpi,1)), color='m')
    % plot(h.im.ax{1}, t, rescale(bump2nan, 1, size(bmpi,1)), color=[0.1, 0.8, 0.8])
    % plot(h.im.ax{1}, t, rescale(cuenan, 1, size(bmpi,1)), color='y')
    % xlim(lim_t)
    % title('eb2')
    % numxtick = 20;
    % h.im.ax{1}.XTick = linspace(lim_t(1), lim_t(2), numxtick);
    % h.im.ax{1}.XTickLabel = h.im.ax{1}.XTick;
    % hold(h.im.ax{1}, "on")



    % idxsubp = 1;
    % h.ts = axts(h.fg, no, ax=ax, t=t, idxsubp=idxsubp);

    % title("bmpi pva blue, bmpi max(dv) red, vish yellow", Position=[0 1])

    pthsv = [pthpre 'bump_.fig'];
    saveas(gcf, pthsv)

end


%%%% PROFILE %%%%

if ismember('profile', pltstr)

    dr = [0 1];

    if isempty(dozscore)
        prompt = sprintf("ENTER 1 TO ZSCORE bmpi ROIS, 0 TO NOT: ");
        commandwindow();
        dozscore = input(prompt);
    end

    if dozscore
        for k = 1:size(bmpi,1)
            % bmpi(k,:) = rescale(bmpi(k,:));
            % bmpi(k,:) = tsdv('normal', bmpi(k,:), slopelensec_eb, slopeord_eb, sper);
            bmpi(k,:) = zscore(bmpi(k,:));
        end
    end

    % stack = stackcrop(stack, 'eb');

    stack = stack(:,:,:,it);
    % stack = stackiso(stack, widyxz);

    stackmin = double(min(stack(:)));
    stackmax = double(max(stack(:)));
    stackrange = stackmax-stackmin;
    clim_tmp = stackrange*dr+stackmin; %cdata limits set from whole bmpi region, rather than chosen subset

    if isempty(stackslice)
        stackmnt = mean(stack,4);
        % stackplt(stackmnt, dmplt='yx(z)')
        % prompt = sprintf("ENTER Z-INDICES YOU WANT TO AVERAGE TO PLOT bmpi ACTIVITY, OR ENTER NOTHING TO AVERAGE ALL Z INDICES: ");
        % commandwindow();
        % stackslice = input(prompt);
        if isempty(stackslice)
            stackslice = 1:size(stackmnt, 3);
        end
    end

    stack = mean(stack(:,:,stackslice,:),3);
    % stack = median(stack(:,:,stackslice,:),3);
    stack = squeeze(stack);

    nolz = zscore(nol);
    norz = zscore(nor);

    hfg = figure;
    hax = axes(Parent=hfg);
    ttl = title(hax, '');

    hax = subplot(2,1,1);
    yyaxis left
    hbr1 = bar(-3.4, 1, 0.25); %ball forward vel

    yyaxis right
    hold on
    hpl = plot(hax, bmpdomain, bmpi(:,1), Color=cmap(2,:));
    hbr2 = bar(hax, 3.2, 1, 0.25); %gld
    hbr3 = bar(hax, 3.5, 1, 0.25); %glv
    hbr4 = bar(hax, 4.1, 1, 0.25); %nol
    hbr5 = bar(hax, 4.4, 1, 0.25); %glr
    xline(hax, bmpdomain(1), 'k', LineWidth=3)
    xline(hax, bmpdomain(end), 'k', LineWidth=3)

    % hln1 = xline(hax, 0, color=cmap(1,:));
    hln2 = xline(hax, 0, color=cmap(3,:));
    hln2.LineWidth = 1.8;
    hln3 = xline(hax, 0, color=cmap(4,:));
    hln3.LineWidth = 1.8;
    % hln4 = xline(hax, 0, color=cmap(4,:));
    limy1 = axlim(ballvf, limtype='allpad');
    limy2 = axlim(bmpi, norz, nolz, gld, glv, limtype='allpad');

    bmpirs = rescale(bmpi, limy2(1), limy2(2));
    gldrs = rescale(gld, limy2(1), limy2(2));
    glvrs = rescale(glv, limy2(1), limy2(2));
    norzrs = rescale(norz, limy2(1), limy2(2));
    nolzrs = rescale(nolz, limy2(1), limy2(2));

    hax.XLim = [-3.8 4.5];
    hax.XTick = [-3.4, 0, 3.2, 3.5, 4.1, 4.4];
    hax.XTickLabel = {'bvf', '0', 'nl', 'nr', 'gld', 'glv'};

    hax.YAxis(1).Limits = limy1;
    hax.YAxis(1).Color = cmap(1,:);
    hbr1.FaceColor = cmap(1,:);
    hbr1.ShowBaseLine='off';

    hax.YAxis(2).Limits = limy2;
    hax.YAxis(2).Color = cmap(2,:);
    hbr2.FaceColor = cmap(2,:);
    hbr2.FaceColor = cmap(2,:);
    hbr3.FaceColor = cmap(2,:);
    hbr4.FaceColor = cmap(2,:);
    hbr2.BaseLine.Color = [0,0,0];
    hbr3.BaseLine.Color = [0,0,0];
    hbr4.BaseLine.Color = [0,0,0];
    hbr5.BaseLine.Color = [0,0,0];

    hax2 = subplot(2,1,2);
    hax2.DataAspectRatio = [4 1 1];
    hax2.Colormap = gray(256);
    hax2.CLim = clim_tmp;
    hax2.Visible = 'off';
    hax2.YDir = 'reverse';
    hpl2 = image(hax2, 'CData', stack(:,:,1));
    hpl2.CDataMapping = 'scaled';

    incc = 1;
    for k = 1:incc:numel(it) %for each timepoint, show bmph
        hpl.YData = bmpirs(:,it(k));
        % hpl.YData = eb2(:,limtsamp(k));
        % hln1.Value = bmph(it(k));
        hln2.Value = vish(it(k));
        hln3.Value = ballinv(it(k));
        % hln4.Value = bump2(it(k));
        hbr1.YData = ballvf(k);
        hbr2.YData = norzrs(k);
        hbr3.YData = nolzrs(k);
        hbr4.YData = gldrs(k);
        hbr5.YData = glvrs(k);
        hpl2.CData = stack(:,:,k);
        hax.Title.String = {['ball for vel (blue), vis hd (yellow), ball hd (purple), bump / nor / nol / gld / glv (red)']; ['t: ' num2str(t(it(k))) ', epoch: ' num2str(epochts(it(k)))]};
        fig2gif(hfg,k)
    end

end


%%%% HISTOGRAM %%%%

if ismember('hist', pltstr)
    pthgif = pthauto(suffix='.gif', usetime=1);
    hfg = figure;
    hax = axes(Parent=hfg);
    for k = 1:size(bmpi,1)
        histogram(hax, bmpi(k,:));
        xlim([-max(abs(bmpi(:))) max(abs(bmpi(:)))])
        ylim([0 4000])
        fig2gif(hfg,k,pthgif)
    end
end


%%%% VOLUME %%%%

if ismember('vol', pltstr)
    stackplt3(stack, it=limtsamp, style='MaximumIntensityProjection')
end


%%%% TIMESERIES 2 %%%%

if ismember('ts2', pltstr)

    nozrs = noz*max(abs(nodv))/max(abs(noz)); %put z-score and derivative on same scale

    bg = [nodv; nozrs]; %background; z-scored nodulus and derivative of nodulus

    cuenan = polarnan(vish); %insert nan where wrap
    ballinvnan = polarnan(ballinv); %insert nan where wrap
    bumpnan = polarnan(bmph); %insert nan where wrap

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
    title("bmph cyan, ballh yellow, vish green, " + noside + " GLNO derivative background")

    pthsv = [pthpre noside '_glno_.fig'];
    saveas(gcf, pthsv)

end


%%%% SCATTERPLOT %%%%

if ismember('scat', pltstr)

    nolz3 = zscore(nol);
    norz3 = zscore(nor);
    nodv = nolz3-norz3;
    nodv = vish;
    bumpdvrs = mean(bmpi);
    bumpdvrs = bmpi(30,:);
    ballinvdvrs = norz3;
    ballinvdvrs = nolz3;


    pthsv = [pthpre 'glno_scatter_' datestr '_' noside '_' num2str(lagsampxy) '_' num2str(lagsampz) '_' epochstr '_.fig'];

    xydist = sqrt(ballinvdvrs.^2 + bumpdvrs.^2); %distance from origin

    %%%%% LAG %%%%%

    [ballinvdvrs, bumpdvrs, nodv] = lagvars(ballinvdvrs, bumpdvrs, lagsampxy, nodv, lagsampz);
    if any(any(isnan([ballinvdvrs, bumpdvrs, nodv])))
        % [ballinvdvrs, bumpdvrs, nodv] = remove_nans_as_group(ballinvdvrs, bumpdvrs, nodv);%%plotz becomes ones if z_is_empty, is this okay??
        error("there should not be any nans yet")
    end


    %%%%% COLORMAP %%%%%

    [nodvsrt, idx4] = sort(nodv);
    ballinvdvrs = ballinvdvrs(idx4);
    bumpdvrs = bumpdvrs(idx4);
    kp1sort = kp1(idx4);
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

    kp1sort = kp1sort(1:numel(ballinvdvrs)); %just crop a samples at end to match length of timeseries after lag
    [ballinvdvrs, bumpdvrs, nodvsrt, sztmp, cmap, xydist] = tscrop(kp1sort, ballinvdvrs, bumpdvrs, nodvsrt, sztmp, cmap, xydist);


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
    xlabel("ballh")
    ylabel("bmph")
    if ~yconst
        limxtreme = max(abs([hax.XLim hax.YLim]));
    end
    % hax.XLim = [-limxtreme limxtreme];
    % hax.YLim = [-limxtreme limxtreme];
    title({[noside ' glno derivative red neg blue pos black zero']; ['lagx: ' num2str(lagsampxy) ', lagz: ' num2str(lagsampz) ', epoch: ' epochstr]})

    % saveas(gcf, pthsv)
    fig2gif(h.fg, 1, [pthsv(1:end-4) '.gif']) %save as gif


end


%%%% SURFACE %%%%

if ismember('surf', pltstr)

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
    xlabel("ballh")
    ylabel("bmph")
    zlabel("GLNO")
    colormap(hot(256))
    camlight right
    lighting phong
    pthsv = [pthpre 'glno_surf_' noside '_' num2str(lagsampxy) '_' num2str(lagsampz) '_' epochstr '_' datestr '_.fig'];
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


if ismember('scat2', pltstr)

    iepoch = 1:6;
    hfg = figure;
    hax = axes(parent=hfg);
    hold on;

    for q = 1:numel(iepoch)

        ie = iepoch(q);
        [~, gldtmp, glvtmp, grdtmp, grvtmp] = epochcrop(daq.(idaq).epochts, ie, gld, glv, grd, grv);
        [~, glddv_tmp, glvdv_tmp, grddv_tmp, grvdv_tmp] = epochcrop(daq.(idaq).epochts, ie, glddv, glvdv, grddv, grvdv);

        if dodv
            if q==1
                hsc1 = scatter(hax, glddv_tmp, glvdv_tmp);
                hsc2 = scatter(hax, grddv_tmp, grvdv_tmp);
                limx = axlim(glddv, grddv, limtype='allpad');
                limy = axlim(glvdv, grvdv, limtype='allpad');
                hax.XLim = limx;
                hax.YLim = limy;
            else
                hsc1.XData = glddv_tmp;
                hsc1.YData = glvdv_tmp;
                hsc2.XData = grddv_tmp;
                hsc2.YData = grvdv_tmp;
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

end

if ismember('polar', pltstr)

    tdat = vish;
    rdat = nor;

    hfg = figure;
    ax = axes(Parent=hfg);
    pax = polaraxes(Units=ax.Units, Position=ax.Position);
    hpl = polarscatter(pax, tdat, nan(size(tdat)), '.');
    pax.RLim = axlim(rdat, limtype='allpad');

    for q = 1:size(rdat,1)
        hpl.RData = rdat(q,:);
        fig2gif(hfg, q)
    end

end




if ismember('tsepoch', pltstr)

    epochs_all = {unique(epochts)};

    hfg = figure;
    hax = axes(parent=hfg);
    limy1 = axlim(glddv, glvdv, grddv, grvdv, limtype='allpad');
    limy2 = axlim(glddv, glvdv, grddv, grvdv, limtype='allpad');

    for k = 1:numel(epochs_all)

        esub = epochs_all(k);
        [~, glddv_tmp, glvdv_tmp, grddv_tmp, grvdv_tmp, ebmn_tmp, ballvf_tmp, ttmp] = epochcrop(epochts, esub, glddv, glvdv, grddv, grvdv, squeeze(ebmn), t);

        if k==1
            yyaxis left
            hold on
            hpl11 = plot(hax, glddv_tmp, color=cmap(1,:), linestyle='-');
            hpl12 = plot(hax, glvdv_tmp, color=cmap(1,:), linestyle='-', linewidth=2);
            hpl13 = plot(hax, grddv_tmp, color=cmap(2,:), linestyle='-');
            hpl14 = plot(hax, grvdv_tmp, color=cmap(2,:), linestyle=':', linewidth=2);
            hax.YAxis(1).Limits = limy1;
            yyaxis right
            hold on
            hpl21 = plot(hax, ebmn_tmp, color=cmap(end,:), linestyle='-');
            hpl22 = plot(hax, ballvf_tmp, color=cmap(4,:), linestyle='-');
            hax.YAxis(2).Limits = limy2;
            hax.YAxis(2).Color = [0 0 0];
        else
            hpl11.YData = glddv_tmp;
            hpl12.YData = glvdv_tmp;
            hpl13.YData = grddv_tmp;
            hpl14.YData = grvdv_tmp;
            hpl21.YData = ebmn_tmp;
            hpl22.YData = ballvf;
        end

    end

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




