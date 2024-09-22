function [ruse, puse] = lincor(stim, resp, opt)

arguments
    stim
    resp
    opt.t = []
    opt.it = 1:numel(stim)
    opt.ir = []
    opt.lagsec = linspace(-1, 1, 1e4);
    opt.lagstyle = 'bestall' %zero, besteach, bestall, all (which lags to plot)
    opt.minpval = 0.05;
    opt.stackmnt = []
    opt.roipixinds = []
    opt.mask_roi_vec = []
    opt.centroids_roi = []
    opt.sortstyle = 'none' % 'none', 'corr', 'xyz', 'yxz', 'zyx', 'zxy', 'xzy', 'yzx' (all are ascending order; corr is ascending by correlation); for spatial styles (xyz and permutations) first dim changes fastest 
    opt.alignzero = 0
    opt.chan = 1
    opt.hsvopt = []
    opt.flypos = []
    opt.pthgif = []
    opt.doplots = 1
end
t = opt.t;
it = opt.it;
ir = opt.ir;
lagsec = opt.lagsec;
lagstyle = opt.lagstyle;
minpval = opt.minpval;
stackmnt = opt.stackmnt;
roipixinds = opt.roipixinds;
mask_roi_vec = opt.mask_roi_vec;
centroids_roi = opt.centroids_roi;
sortstyle = opt.sortstyle;
alignzero = opt.alignzero;
chan = opt.chan;
hsvopt = opt.hsvopt;
flypos = opt.flypos;
pthgif = opt.pthgif;
doplots = opt.doplots;

gif_visibility = 'on';
fontmedium = 12;
axord = 'rowmajor';
crosshair_width = 3;
xtralimfac = 0.03;
numtickx = 4;
numticky = 2;

assert(isvector(stim))
assert(ndims(resp)==2)

if ~isempty(ir)
    error("don't pass ir option yet")
end

if isempty(ir)
    ir = 1:size(resp,1);
end

matlab_dimorder_char = 'yxz';

%% compute correlation after applying lags

[lagsec_actual, lagsamp, zero_lag_index, numlags] = compute_lags(t, lagsec); %actual lags depend on epoch (samples you're using)

stim = double(stim);
resp = double(resp);

ruse = zeros(numel(ir), 1);
lagsamp_use = zeros(numel(ir), 1);
lagsec_actual_use = zeros(numel(ir), 1);
r_lagall = zeros(numel(ir), numel(lagsamp));
p_lagall = zeros(numel(ir), numel(lagsamp));
for k = 1:numel(ir)
    [r_lagall(k,:), p_lagall(k,:)] = corlagvecs(resp(ir(k),:), stim, lagsamp, minpval);
    switch lagstyle
        case 'besteach'
            [~, lagind_best_each] = max(abs(r_lagall(k,:)));
            ruse(k) = r_lagall(k,lagind_best_each);
            puse(k) = p_lagall(k,lagind_best_each);
            lagsamp_use(k) = lagsamp(lagind_best_each);
            lagsec_actual_use(k) = lagsec_actual(lagind_best_each);
        case 'bestall'
            if k==numel(ir)
                [~, lagind_best_all] = max(mean(abs(r_lagall)));
                ruse(:) = r_lagall(:,lagind_best_all);
                puse(:) = p_lagall(:,lagind_best_all);
                lagsamp_use(:) = lagsamp(lagind_best_all);
                lagsec_actual_use(:) = lagsec_actual(lagind_best_all);
            end
        case 'zero'
            if k==numel(ir)
                ruse(:) = r_lagall(:,zero_lag_index);
                puse(:) = p_lagall(:,zero_lag_index);
                lagsamp_use(:) = lagsamp(zero_lag_index);
                lagsec_actual_use(:) = lagsec_actual(zero_lag_index);
            end
        case 'all'
            error("lagstyle all not written yet")
    end
end

%% plotting

if doplots && ~isempty(stackmnt) && ~isempty(roipixinds)


    %%%%%%%%%%% SETUP PLOT VARS %%%%%%%%%%%

    if isempty(pthgif)
        pthgif = pthauto(pthgif, suffix='.gif', usetime=1, usefun=1);
    end

    stackmnt = stackmnt(:,:,:,chan);

    if isempty(mask_roi_vec)
        mask_roi_vec = zeros(numel(roipixinds), numel(stackmnt), 'logical');  %initialize a logical matrix that is size (centroids, voxels)
        for k = 1:numel(roipixinds)
            [maskytmp, maskxtmp, maskztmp] = ind2sub(size(stackmnt), roipixinds{k});
            mask_roi_vec(k, sub2ind(size(stackmnt), maskytmp, maskxtmp, maskztmp)) = true; %indices of each roi
        end
    end

    if isempty(centroids_roi)
        roipixinds = cellfun(@sort, roipixinds, 'UniformOutput', false); %should be sorted already, but just in case
        chtmp = cellfun(@(x) x(ceil(end/2)), roipixinds, 'UniformOutput', false);  %middle element, in case centroids aren't provided
        [crosshair(:,1), crosshair(:,2), crosshair(:,3)] = ind2sub(size(stackmnt), cell2mat(chtmp));
        crosshair = num2cell(crosshair, 2)';
    else
        crosshair = cellfun(@round, centroids_roi, 'UniformOutput', false); %will this take it out of bounds? should not
    end

    if isempty(hsvopt)
        hsvopt = default_hsv_opts();
    end
    hsvopt = plots_setup_hsv(hsvopt);

    roipixinds = roipixinds(ir);
    crosshair = crosshair(ir);
    mask_roi_vec = mask_roi_vec(ir,:);

    hsvmap = plots_compute_hsv(hsvopt, hueft=ruse);
    imhsv = plots_hsvfov(hsvopt, stackmnt, hsvmap, roipixinds, mask_roi_vec);

    nanresp = nan(1, size(resp,2));
    nanstim = nan(1, size(resp,2));

    numxpix = size(stackmnt,2);
    numypix = size(stackmnt,1);

    tsub = t(it);

    switch sortstyle
        case 'corr' %by correlation
            [~, sinds] = sort(ruse);
        case {'xyz', 'yxz', 'zyx', 'zxy', 'xzy', 'yzx'}
            [~, sinds] = sortrows(cell2mat(crosshair(:)), cell2mat(regexp(matlab_dimorder_char, cellstr(flip(sortstyle)'))));
        case 'none'
            sinds = 1:numel(ir);
    end


    %%%%%%%%%%% SETUP AXES %%%%%%%%%%%

    subplot_layout = {[2,4], imhsv};
    margins_subplot = [0.05,0.005];
    margins_fig = [0.07,0.05];
    splitdim = 'y';
    splitfrac = 0.55;
    ax = arrange_subplots(subplot_layout, margins_subplot, margins_fig, splitdim, splitfrac);


    hfg = figure;
    aspect_screen = hfg.Parent.ScreenSize(3) / hfg.Parent.ScreenSize(4); %get screen aspect ratio
    close(hfg)

    figsidelength = 0.75;
    hfg = figure( 'Units', 'Normalized', 'Color', 'white', 'visible', gif_visibility, 'Position', [0, 0, 1, 1]);
    if aspect_screen>1
        hfg.Position = [0 0 figsidelength/aspect_screen figsidelength]; %make square inner size (excludes top menu bar), plot in bottom left
    else
        hfg.Position = [0 0 figsidelength figsidelength/aspect_screen]; %make square inner size (excludes top menu bar), plot in bottom left
    end

    haxmain = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', 'XLim', [0, 1], 'YLim', [0, 1] ) ;
    htx = text( haxmain, 0.5, 0.99, '', 'FontSize', fontmedium, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontWeight', 'bold' );


    sectorind = 2;
    for j = 1:size(imhsv, 3)

        st.hax{j} = axes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition' );
        st.hax{j}.InnerPosition(1) = ax(sectorind).(axord).xp(j);
        st.hax{j}.InnerPosition(2) = ax(sectorind).(axord).yp(j);
        st.hax{j}.InnerPosition(3) = ax(sectorind).xe(1);
        st.hax{j}.InnerPosition(4) = ax(sectorind).ye(1);
        st.hax{j}.DataAspectRatio = [1 1 1]; %don't think this is necessary
        st.hax{j}.XLim = [1 numxpix];
        st.hax{j}.YLim = [1 numypix];

        st.hlnx{j} = xline(st.hax{j}, nan, 'w', 'LineStyle', 'none', 'LineWidth', crosshair_width);
        st.hlny{j} = yline(st.hax{j}, nan, 'w', 'LineStyle', 'none', 'LineWidth', crosshair_width);

        hold(st.hax{j}, 'on')
        st.hpl{j} = image(st.hax{j}, 'CData', squeeze(imhsv(:,:,j,:)));
        axis off
        axis ij
        hold(st.hax{j}, 'off')

    end

    sectorind = 1; spi = 1; widthfac = 4; heightfac = 1;
    ts.hax = axes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition' );
    ts.hax.InnerPosition(1) = ax(sectorind).(axord).xp(spi);
    ts.hax.InnerPosition(2) = ax(sectorind).(axord).yp(spi);
    ts.hax.InnerPosition(3) = ax(sectorind).xe(widthfac);
    ts.hax.InnerPosition(4) = ax(sectorind).ye(heightfac);
    hold(ts.hax, 'on');
    yyaxis left;
    ts.hpl = plot(ts.hax, t, nanresp);
    yyaxis right;
    ts.hpl2 = plot(ts.hax, t, nanresp);
    hold(ts.hax, 'off');
    ts.xln = yline(0, Color=[0 0 0], Alpha=0.3);
    [ts.hax.XAxis] = axismod(ts.hax.XAxis, t, xtralimfac=xtralimfac, numtick=numtickx, alignzero=0, label='time (seconds)', labeltightfac=0.7);
    [ts.hax.YAxis(1)] = axismod(ts.hax.YAxis(1), resp, xtralimfac=xtralimfac, numtick=numticky, alignzero=alignzero, label='resp',  labeltightfac=0.7);
    [ts.hax.YAxis(2)] = axismod(ts.hax.YAxis(2), stim, xtralimfac=xtralimfac, numtick=numticky, alignzero=alignzero, label='stim',  labeltightfac=0.7);


    sectorind = 1; spi = 5; widthfac = 1; heightfac = 1;
    sc.hax = axes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition' );
    sc.hax.InnerPosition(1) = ax(sectorind).(axord).xp(spi);
    sc.hax.InnerPosition(2) = ax(sectorind).(axord).yp(spi);
    sc.hax.InnerPosition(3) = ax(sectorind).xe(widthfac);
    sc.hax.InnerPosition(4) = ax(sectorind).ye(heightfac);
    sc.hpl = scatter(sc.hax, nanresp, nanresp, 2.5, 'filled');
    sc.hax.PlotBoxAspectRatio = [1 1 1];
    [sc.hax.XAxis] = axismod(sc.hax.XAxis, stim, xtralimfac=xtralimfac, numtick=numticky, alignzero=alignzero, label='stim',  labeltightfac=0.7);
    [sc.hax.YAxis(1)] = axismod(sc.hax.YAxis(1), resp, xtralimfac=xtralimfac, numtick=numticky, alignzero=alignzero, label='resp',  labeltightfac=0.7); %specify axis(1) otherwise to overwrite entire axis


    sectorind = 1; spi = 6; widthfac = 1; heightfac = 1;
    pt.hax = axes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition' );
    pt.hax.InnerPosition(1) = ax(sectorind).(axord).xp(spi);
    pt.hax.InnerPosition(2) = ax(sectorind).(axord).yp(spi);
    pt.hax.InnerPosition(3) = ax(sectorind).xe(widthfac);
    pt.hax.InnerPosition(4) = ax(sectorind).ye(heightfac);
    pt.hpl = patch(pt.hax, nanresp, nanresp, nanresp, 'EdgeColor',' interp', 'LineWidth', 0.5, 'LineJoin', 'round');
    pt.hpl.XData = [flypos.x(1:end-1) nan]; %need the nan to make patch work
    pt.hpl.YData = [flypos.y(1:end-1) nan]; %need the nan to make patch work
    pt.hpl.CData = [1:numel(nanresp)-1 nan]; %need the nan to make patch work
    pt.hax.PlotBoxAspectRatio = [1 1 1];
    pt.hax.Box = 'on';
    [pt.hax.XAxis] = axismod(pt.hax.XAxis, flypos.x, xtralimfac=xtralimfac, numtick=numticky, alignzero=0, label='path (6 m square)',  labeltightfac=0.7, noticks=1);
    [pt.hax.YAxis(1)] = axismod(pt.hax.YAxis(1), flypos.y, xtralimfac=xtralimfac, numtick=numticky, alignzero=0, label='',  labeltightfac=0.7, noticks=1);


    sectorind = 1; spi = 7; widthfac = 2; heightfac = 1;
    ts2.hax = axes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition' );
    ts2.hax.InnerPosition(1) = ax(sectorind).(axord).xp(spi);
    ts2.hax.InnerPosition(2) = ax(sectorind).(axord).yp(spi);
    ts2.hax.InnerPosition(3) = ax(sectorind).xe(widthfac);
    ts2.hax.InnerPosition(4) = ax(sectorind).ye(heightfac);
    hold(ts2.hax, 'on');
    yyaxis left;
    ts2.hpl = plot(ts2.hax, tsub, nanresp(it));
    yyaxis right;
    ts2.hpl2 = plot(ts2.hax, tsub, nanresp(it));
    hold(ts2.hax, 'off');
    ts2.xln = yline(0, Color=[0 0 0], Alpha=0.3);
    [ts2.hax.XAxis] = axismod(ts2.hax.XAxis, tsub, xtralimfac=xtralimfac, numtick=numtickx, alignzero=0, label='time (seconds)',  labeltightfac=0);
    [ts2.hax.YAxis(1)] = axismod(ts2.hax.YAxis(1), resp, xtralimfac=xtralimfac, numtick=numticky, alignzero=alignzero, label='resp',  labeltightfac=0.7);
    [ts2.hax.YAxis(2)] = axismod(ts2.hax.YAxis(2), stim, xtralimfac=xtralimfac, numtick=numticky, alignzero=alignzero, label='stim',  labeltightfac=0.7);


    %%%%%%%%%%% PLOT %%%%%%%%%%%

    for k = 1:numel(sinds)

        rind = sinds(k);

        for j = 1:size(imhsv, 3)
            if j==crosshair{rind}(3)
                st.hlny{j}.Value = crosshair{rind}(1);
                st.hlnx{j}.Value = crosshair{rind}(2);
                st.hlny{j}.LineStyle = '-';
                st.hlnx{j}.LineStyle = '-';
            else
                st.hlny{j}.LineStyle = 'none';
                st.hlnx{j}.LineStyle = 'none';
            end
        end

        [resplag, stimlag] = lagvars(resp(rind,:), stim, lagsamp_use(rind));
        nanresp(:) = nan;
        nanstim(:) = nan;
        nanresp(1:numel(resplag)) = resplag;
        nanstim(1:numel(stimlag)) = stimlag;

        sc.hpl.XData = nanstim;
        sc.hpl.YData = nanresp;
        ts.hpl.YData = nanresp;
        ts.hpl2.YData = nanstim;
        ts2.hpl.YData = nanresp(it);
        ts2.hpl2.YData = nanstim(it);

        htx.String = ['roi: ' num2str(ir(rind)) ', lag (sec): ' num2str(lagsec_actual_use(rind)) ', r: ' num2str(ruse(rind)) ', p: ' num2str(puse(rind))];

        fig2gif(hfg, k, pthgif)

    end


end

end



function [lagsec_actual, lagsamp, zero_lag_index, numlags] = compute_lags(t, lags_sec)

ticumdiff = t - t(1);
if isequal(lags_sec, 0)
    lagsamp = 0;
    lagsec_actual = 0;
else
    ticumdiff = ticumdiff(:); %make sure it's a column vector
    lags_sec = lags_sec(:)';  %make sure it's a row vector
    lags_sec_neg = abs(lags_sec(lags_sec<0));
    [~, lags_samp_neg] = min(abs(ticumdiff-lags_sec_neg));
    lags_sec_pos = lags_sec(lags_sec>=0);
    [~, lags_samp_pos] = min(abs(ticumdiff-lags_sec_pos));
    lagsamp = [-lags_samp_neg, 0, lags_samp_pos];
    lagsamp = unique(lagsamp);
    lagsec_actual = [vec(-ticumdiff(abs(lagsamp(lagsamp<0))+1)); vec(ticumdiff(lagsamp(lagsamp>=0)+1))];
    lagsec_actual = unique(lagsec_actual);
end


zero_lag_index = find(lagsamp==0);
numlags = numel(lagsamp);

end


function [r_lagall, p_lagall] = corlagvecs(resp, stim, lagsamp, minpval)

r_lagall = zeros(numel(lagsamp), 1);
p_lagall = zeros(numel(lagsamp), 1);
for k = 1:numel(lagsamp)
    [resplag, stimlag] = lagvars(resp, stim, lagsamp(k));
    [r_lagall(k), p_lagall(k)] = corr(resplag, stimlag);
    if p_lagall(k)>minpval
        r_lagall(k) = 0;
    end
end

end

function [x, y] = lagvars(x, y, lag)
if lag>0 %positive lag, first variable follows second (first var shifted left)
    x = vec(x(1+abs(lag):end));
    y = vec(y(1:end-abs(lag)));
else %negative lag first variable precedes second (first var shifted right)
    x = vec(x(1:end-abs(lag)));
    y = vec(y(1+abs(lag):end));
end
end

function [hax] = axismod(hax, dat, opt)
arguments
    hax %preexisting axis object
    dat %data
    opt.xtralimfac = 0.03
    opt.numtick = 2
    opt.alignzero = 0
    opt.label = ''
    opt.labeltightfac = 0
    opt.noticks = 0
end

roundprecision = 0;

mindat = min(dat(:));
maxdat = max(dat(:));
xtremedat = max(abs(dat(:)));
rngdat = range(dat(:));
if opt.alignzero
    hax.Limits = [-xtremedat-rngdat*opt.xtralimfac xtremedat+rngdat*opt.xtralimfac];
    hax.TickValues = linspace(-xtremedat, xtremedat, opt.numtick);
else
    hax.Limits = [mindat-rngdat*opt.xtralimfac maxdat+rngdat*opt.xtralimfac];
    hax.TickValues = linspace(mindat, maxdat, opt.numtick);
end
hax.TickLabels = round(hax.TickValues, roundprecision);
hax.Label.String = opt.label;
hax.Label.Units = 'normalized';

ii = hax.Label.Position<0 | hax.Label.Position>1; %adjust the position for dimension that is outside plotbox (outside 0-1 range after normalizing units)
if hax.Label.Position(ii)<0
    moveamount = opt.labeltightfac*hax.Label.Position(ii);
elseif hax.Label.Position(ii)>1
    moveamount = opt.labeltightfac*(hax.Label.Position(ii)-1);
end
hax.Label.Position(ii) = hax.Label.Position(ii) - moveamount;

if opt.noticks
    hax.TickValues = [];
    hax.TickLabels = [];
end

end
