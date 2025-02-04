function [r2use, puse] = lfit(stim, resp, opt)

arguments
    stim
    resp
    opt.t = []
    opt.it = 1:numel(stim)
    opt.ir = []
    opt.ipltts = []
    opt.corrtype = 'pearson' %'pearson', 'kendall', 'spearman'
    opt.lagsec = linspace(-1, 1, 1e4); %lag in seconds, rounded to nearest sample, duplicates are removed so to lag every sample within a range just use a larger number of lag samples than data samples
    opt.lagstyle = 'bestall' %zero, besteach, bestall, all (all option doesn't work yet); which lags to output and plot
    opt.minpval = 0.05; %
    opt.stack = [] %yxztc stack for plot
    opt.roipx = [] %cell array, length number of rois, each cell has linear indices of each roi
    opt.roiwt = [] %size [total number rois, total number voxels in yxz stack]; each column represents linear index of voxel in yxz stack; each element in row n is true if voxel is present in roi n, 0 otherwise
    opt.roicen = [] %cell array, length number of rois; cell n is yxz centroid for roi n;
    opt.sortstyle = 'xyz' % 'none', 'corr', 'xyz', 'yxz', 'zyx', 'zxy', 'xzy', 'yzx' (all are ascending order); corr is ascending by correlation, negative to positive; for spatial sort styles (xyz and permutations) first dim changes fastest, last slowest, so xyz is like reading a book
    opt.alignzero = 0
    opt.yconst = 0
    opt.plotlagged = 0 %plot the timeseries at the chosen lag
    opt.usesaved = 0
    opt.chanuse = 1
    opt.imhsv = []
    opt.pos = []
    opt.pixfit = []
    opt.pthgif = []
    opt.doplt = 1
end
t = opt.t;
it = opt.it;
ir = opt.ir;
ipltts = opt.ipltts;
corrtype = opt.corrtype;
lagsec = opt.lagsec;
lagstyle = opt.lagstyle;
minpval = opt.minpval;
stack = opt.stack;
roipx = opt.roipx;
roiwt = opt.roiwt;
roicen = opt.roicen;
sortstyle = opt.sortstyle;
alignzero = opt.alignzero;
yconst = opt.yconst;
plotlagged = opt.plotlagged;
usesaved = opt.usesaved;
chanuse = opt.chanuse;
imhsv = opt.imhsv;
pos = opt.pos;
pixfit = opt.pixfit;
pthgif = opt.pthgif;
doplt = opt.doplt;

gifvis = 'on';
fontmedium = 12;
crosshair_width = 3;
xtralimfac = 0.03;
numtickx = 4;
numticky = 2;

assert(isvector(stim))
assert(ndims(resp)==2)

if isempty(imhsv)
    imhsv = struct;
end


matlab_dimorder_char = 'yxz';

savedatsuffix = ['linfit_' lagstyle '_' num2str(pixfit) '_.mat'];
pthdat = pthauto(suffix=savedatsuffix, usetime=0, usefun=0);

if size(stack,5)~=1 %don't index if channel dimension is singleton, it will create a (potentially large) temporary variable within this function pointlessly
    stack = stack(:,:,:,:,chanuse);
end
stackmnt = glb('stackmnt');
if isempty(stackmnt)
    stackmnt = single(mean(stack, 4)); %native is slow and not necessary for mean t
end

numxpix = size(stackmnt,2);
numypix = size(stackmnt,1);

if pixfit
    if min(stack(:))<0
        error(sprintf("stack should be nonnegative ast this point"))
    end
    resp = stack;
    clear stack
    resp = reshape(resp, [], size(resp,4));
    if pixfit==1
        resp = resp(unique(cell2mat(roipx)),:);
    elseif pixfit==2
        roipx = num2cell(1:numel(stackmnt));
    end
    ir = 1:size(resp,1);
    imhsv.fg = 'pixels';
    roiwt = [];
    roicen = [];
end


if isempty(ir)
    ir = 1:size(resp,1);
end
numroi = numel(ir);

if isempty(ipltts)
    ipltts = 1:numroi;
end

resp = resp(ir,:);
numsamp = size(resp,2);


%% compute correlation after applying lags

runfit = 1;
if usesaved
    try
        load(pthdat, 'suse', 'r2use', 'puse', 'lagsamp_use', 'lagsec_actual_use');
        runfit = 0;
    catch
    end
end


if runfit
    [lagsec_actual, lagsamp, zero_lag_index, numlag] = lagmake(t, lagsec); %actual lags depend on epoch (samples you're using)
    slope_lagall = zeros(numroi, numlag, 'single');
    rsq_lagall = zeros(numroi, numlag, 'single');
    p_lagall = zeros(numroi, numlag, 'single');

    if numroi*numlag>1e9
        parfor k = 1:numroi
            resptmp = resp(k,:);
            for m = 1:numlag
                [slope_lagall(k,m), rsq_lagall(k,m), p_lagall(k,m)] = lag_and_linfit(resptmp, stim, lagsamp(m), minpval, corrtype);
            end
        end
    else
        for k = 1:numroi
            for m = 1:numlag
                [slope_lagall(k,m), rsq_lagall(k,m), p_lagall(k,m)] = lag_and_linfit(resp(k,:), stim, lagsamp(m), minpval, corrtype);
            end
        end
    end
    switch lagstyle
        case 'besteach'
            [~, laguse] = max(rsq_lagall, [], 2);
        case 'bestall'
            [~, laguse] = max(mean(rsq_lagall));
            laguse = repelem(zero_lag_index, numroi, 1);
        case 'zero'
            laguse = repelem(zero_lag_index, numroi, 1);
        case 'all'
            error("lagstyle all not written yet")
    end
    kp = sub2ind(size(slope_lagall), 1:size(slope_lagall,1), laguse');

    suse = slope_lagall(kp);
    r2use = rsq_lagall(kp);
    puse = p_lagall(kp);
    lagsamp_use = lagsamp(laguse);
    lagsec_actual_use = lagsec_actual(laguse);

    save(pthdat, 'suse', 'r2use', 'puse', 'lagsamp_use', 'lagsec_actual_use', '-v7.3', '-mat')
end

%% plotting

if doplt && ~isempty(stackmnt) && ~isempty(roipx)


    %%%%%%%%%%% SETUP PLOT VARS %%%%%%%%%%%

    if isempty(pthgif)
        pthgif = pthauto(suffix='.gif', usetime=1, usefun=1);
    end
    [~, fldr, ~] = fileparts(fileparts(pthgif));
    fldr_title = strrep(strrep(fldr, '-', ' '), '_', ' ');

    if isempty(roiwt)
        roiwt = zeros(numel(roipx), numel(stackmnt), 'logical');  %initialize a logical matrix that is size (centroids, voxels)
        for k = 1:numel(roipx)
            [maskytmp, maskxtmp, maskztmp] = ind2sub(size(stackmnt), roipx{k});
            roiwt(k, sub2ind(size(stackmnt), maskytmp, maskxtmp, maskztmp)) = true; %indices of each roi
        end
    end

    if isempty(roicen)
        roipx = cellfun(@sort, roipx, 'UniformOutput', false); %should be sorted already, but just in case
        chtmp = cellfun(@(x) x(ceil(end/2)), roipx, 'UniformOutput', false);  %middle element, in case centroids aren't provided
        [crosshair(:,1), crosshair(:,2), crosshair(:,3)] = ind2sub(size(stackmnt), cell2mat(chtmp));
        crosshair = num2cell(crosshair, 2)';
    else
        crosshair = cellfun(@round, roicen, 'UniformOutput', false); %will this take it out of bounds? should not
    end

    opttmp.imhsv.ignoresat = 1;
    opttmp.imhsv.ignoreval = 0;
    opttmp = odf(opttmp, 'imhsv');
    imhsv = opttmp.imhsv;
    imhsv = plots_setup_hsv(imhsv);

    if pixfit
        iplttsmax = 30;
        ipltts = unique(round(linspace(1, numel(ipltts), iplttsmax)));
        sprintf(['pixfit is true so only plotting equidistant ' num2str(numel(ipltts)) ' rois in frames of gif, but all in hsvmap'])
        crosshair = [];
        [crosshair(:,1), crosshair(:,2), crosshair(:,3)] = ind2sub(size(stackmnt), cell2mat(roipx));
        crosshair = num2cell(crosshair, 2)';
    else
        roipx = roipx(ir);
        crosshair = crosshair(ir);
        roiwt = roiwt(ir,:);
    end

    respstd = std(resp, 1, 2); %making 2nd argument 1 normalizes by n, making it 0 normalizes by n-1

    notsig = puse>minpval;
    respstd(notsig) = min(respstd(:)); %;nan; %min(respstd(:))/2;
    r2use(notsig) = min(r2use(:)); %nan %min(r2use(:))/2;
    suse(notsig) = 0; %nan %min(suse(:))/2;

    % [histdt, histx] = hist(respstd(:), 1000);
    % thrbin_tri = triangle_threshold(histdt, 'R', 1);
    % thr_tri = histx(thrbin_tri);
    % rnk = percentrank(respstd(:), thr_tri);
    % rnk  = rnk/100;
    % vrangenew = [rnk 1];
    % imhsv.vrange_out_manual = [1-rnk 1];

    [ss,ssi]=sort(suse);
    sneg = find(ss<0);
    ssn = ss(sneg);
    tmp1=r2use(ssi);
    tmp2=respstd(ssi);
    hfg = figure;
    subplot(211); hold on; plot(ss, tmp1); plot(ssn, tmp1(sneg)); title('r squared versus slope for each roi (or pixel)')
    subplot(212); hold on; plot(ss, tmp2); plot(ssn, tmp2(sneg)); title('fluorescence std versus slope for each roi (or pixel)')
    saveas(hfg, strrep(pthgif, '.gif', '.png'))

    laguni = unique(lagsamp_use);
    prevkepins = 0;
    pthgif44 = insertBefore(pthgif, '.gif', 'parsbylagr2use');
    hfg = figure; hold on;
    for k = 1:numel(laguni)
        kepins = r2use(lagsamp_use==laguni(k));
        if ~isempty(kepins)
            kepinsx = [1:numel(kepins)]+prevkepins;
            prevkepins = kepinsx(end)+1;
            hpltmp = plot(kepinsx, kepins);
            yline(mean(r2use(lagsamp_use==laguni(k))), color=hpltmp.Color);
        else
            kepinsx = [1:50]+prevkepins;
            hpltmp = plot(kepinsx, zeros(size(kepinsx)));
            yline(mean(r2use(lagsamp_use==laguni(k))), color=hpltmp.Color);
        end
    end
    saveas(hfg, strrep(pthgif44, '.gif', '.png'))

    prevkepins = 0;
    pthgif44 = insertBefore(pthgif, '.gif', 'parsbylagsuse');
    hfg = figure; hold on;
    for k = 1:numel(laguni)
        kepins = suse(lagsamp_use==laguni(k));
        if ~isempty(kepins)
            kepinsx = [1:numel(kepins)]+prevkepins;
            prevkepins = kepinsx(end)+1;
            hpltmp = plot(kepinsx, kepins);
            yline(mean(suse(lagsamp_use==laguni(k))), color=hpltmp.Color);
        else
            kepinsx = [1:50]+prevkepins;
            hpltmp2 = plot(kepinsx, zeros(size(kepinsx)));
            yline(mean(suse(lagsamp_use==laguni(k))), color=hpltmp.Color);
        end
    end
    saveas(hfg, strrep(pthgif44, '.gif', '.png'))


    hfg = figure; plot(sort(lagsamp_use))
    pthgif44 = insertBefore(pthgif, '.gif', 'sortlags');
    saveas(hfg, strrep(pthgif44, '.gif', '.png'))

    close all

    hsvmap = hsvcmp(imhsv, hueft=suse, satft=r2use, valft=respstd);
    imhsv = hsvplt(imhsv, stackmnt, hsvmap, roipx, roiwt);

    nanresp = nan(1, numsamp);
    nanstim = nan(1, numsamp);

    tsub = t(it);

    switch sortstyle
        case 'slope' %by correlation
            [~, sinds] = sort(suse);
        case 'corr' %by correlation
            [~, sinds] = sort(r2use);
        case {'xyz', 'yxz', 'zyx', 'zxy', 'xzy', 'yzx'}
            [~, sinds] = sortrows(cell2mat(crosshair(:)), cell2mat(regexp(matlab_dimorder_char, cellstr(flip(sortstyle)'))));
        case 'none'
            sinds = 1:numroi;
    end


    %%%%%%%%%%% SETUP AXES %%%%%%%%%%%

    layout = {[2,4], imhsv};
    marginax = [0.05,0.005];
    marginfg = [0.07,0.05];
    splitfrac = 0.55;
    ax = axarr(layout, marginax=marginax, marginfg=marginfg, splitdim='y', splitfrac=splitfrac);

    szf = 0.75;
    szftmp = figsz(szf);
    hfg = figure( 'Units', 'Pixels', 'Color', 'white', 'visible', gifvis, 'WindowStyle', 'normal');
    hfg.Position = [0 0 szftmp];

    haxmain = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', 'XLim', [0, 1], 'YLim', [0, 1] ) ;
    htx = text( haxmain, 0.5, 0.99, '', 'FontSize', fontmedium, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontWeight', 'bold' );


    sectorind = 2;
    for j = 1:size(imhsv, 3)

        st.hax{j} = axes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition' );
        st.hax{j}.InnerPosition(1) = ax(sectorind).x(j);
        st.hax{j}.InnerPosition(2) = ax(sectorind).y(j);
        st.hax{j}.InnerPosition(3) = ax(sectorind).w(1);
        st.hax{j}.InnerPosition(4) = ax(sectorind).h(1);
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
    ts.hax.InnerPosition(1) = ax(sectorind).x(spi);
    ts.hax.InnerPosition(2) = ax(sectorind).y(spi);
    ts.hax.InnerPosition(3) = ax(sectorind).w(widthfac);
    ts.hax.InnerPosition(4) = ax(sectorind).h(heightfac);
    hold(ts.hax, 'on');
    yyaxis left;
    ts.hpl = plot(ts.hax, t, nanresp);
    yyaxis right;
    ts.hpl2 = plot(ts.hax, t, stim);
    hold(ts.hax, 'off');
    ts.xln = yline(0, Color=[0 0 0], Alpha=0.3);
    [ts.hax.XAxis] = axismod(ts.hax.XAxis, t, xtralimfac=xtralimfac, numtick=numtickx, alignzero=0, label='time (seconds)', labeltightfac=0.7);
    [ts.hax.YAxis(1)] = axismod(ts.hax.YAxis(1), resp, xtralimfac=xtralimfac, numtick=numticky, alignzero=alignzero, label='resp',  labeltightfac=0.7);
    [ts.hax.YAxis(2)] = axismod(ts.hax.YAxis(2), stim, xtralimfac=xtralimfac, numtick=numticky, alignzero=alignzero, label='stim',  labeltightfac=0.7);


    sectorind = 1; spi = 5; widthfac = 1; heightfac = 1;
    sc.hax = axes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition' );
    sc.hax.InnerPosition(1) = ax(sectorind).x(spi);
    sc.hax.InnerPosition(2) = ax(sectorind).y(spi);
    sc.hax.InnerPosition(3) = ax(sectorind).w(widthfac);
    sc.hax.InnerPosition(4) = ax(sectorind).h(heightfac);
    sc.hpl = scatter(sc.hax, stim, nanresp, 2.5, 'filled');
    sc.hax.PlotBoxAspectRatio = [1 1 1];
    [sc.hax.XAxis] = axismod(sc.hax.XAxis, stim, xtralimfac=xtralimfac, numtick=numticky, alignzero=alignzero, label='stim',  labeltightfac=0.7);
    [sc.hax.YAxis(1)] = axismod(sc.hax.YAxis(1), resp, xtralimfac=xtralimfac, numtick=numticky, alignzero=alignzero, label='resp',  labeltightfac=0.7); %specify axis(1) otherwise to overwrite entire axis


    sectorind = 1; spi = 6; widthfac = 1; heightfac = 1;
    pt.hax = axes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition' );
    pt.hax.InnerPosition(1) = ax(sectorind).x(spi);
    pt.hax.InnerPosition(2) = ax(sectorind).y(spi);
    pt.hax.InnerPosition(3) = ax(sectorind).w(widthfac);
    pt.hax.InnerPosition(4) = ax(sectorind).h(heightfac);
    pt.hpl = patch(pt.hax, nanresp, nanresp, nanresp, 'EdgeColor',' interp', 'LineWidth', 0.5, 'LineJoin', 'round');
    if ~isempty(pos.x)
        pt.hpl.XData = [pos.x(1:end-1) nan]; %need the nan to make patch work
        pt.hpl.YData = [pos.y(1:end-1) nan]; %need the nan to make patch work
        pt.hpl.CData = [1:numel(nanresp)-1 nan]; %need the nan to make patch work
        pt.hax.PlotBoxAspectRatio = [1 1 1];
        pt.hax.Box = 'on';
        [pt.hax.XAxis] = axismod(pt.hax.XAxis, pos.x, xtralimfac=xtralimfac, numtick=numticky, alignzero=0, label='path (6 m square)',  labeltightfac=0.7, noticks=1);
        [pt.hax.YAxis(1)] = axismod(pt.hax.YAxis(1), pos.y, xtralimfac=xtralimfac, numtick=numticky, alignzero=0, label='',  labeltightfac=0.7, noticks=1);
    end


    sectorind = 1; spi = 7; widthfac = 2; heightfac = 1;
    ts2.hax = axes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition' );
    ts2.hax.InnerPosition(1) = ax(sectorind).x(spi);
    ts2.hax.InnerPosition(2) = ax(sectorind).y(spi);
    ts2.hax.InnerPosition(3) = ax(sectorind).w(widthfac);
    ts2.hax.InnerPosition(4) = ax(sectorind).h(heightfac);
    hold(ts2.hax, 'on');
    yyaxis left;
    ts2.hpl = plot(ts2.hax, tsub, nanresp(it));
    yyaxis right;
    ts2.hpl2 = plot(ts2.hax, tsub, stim(it));
    hold(ts2.hax, 'off');
    ts2.xln = yline(0, Color=[0 0 0], Alpha=0.3);
    [ts2.hax.XAxis] = axismod(ts2.hax.XAxis, tsub, xtralimfac=xtralimfac, numtick=numtickx, alignzero=0, label='time (seconds)',  labeltightfac=0);
    [ts2.hax.YAxis(1)] = axismod(ts2.hax.YAxis(1), resp(it), xtralimfac=xtralimfac, numtick=numticky, alignzero=alignzero, label='resp',  labeltightfac=0.7);
    [ts2.hax.YAxis(2)] = axismod(ts2.hax.YAxis(2), stim(it), xtralimfac=xtralimfac, numtick=numticky, alignzero=alignzero, label='stim',  labeltightfac=0.7);


    %%%%%%%%%%% PLOT %%%%%%%%%%%

    for k2 = 1:numel(sinds)
        k = sinds(k2);
        if ismember(k2, ipltts)
            

            rind = ir(k);

            for j = 1:size(imhsv, 3)
                if j==crosshair{k}(3)
                    st.hlny{j}.Value = crosshair{k}(1);
                    st.hlnx{j}.Value = crosshair{k}(2);
                    st.hlny{j}.LineStyle = '-';
                    st.hlnx{j}.LineStyle = '-';
                else
                    st.hlny{j}.LineStyle = 'none';
                    st.hlnx{j}.LineStyle = 'none';
                end
            end

            if plotlagged
                [resplag, stimlag] = lagvars(resp(k,:), stim, lagsamp_use(k));
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
            else
                sc.hpl.YData = resp(k,:);
                ts.hpl.YData = resp(k,:);
                ts2.hpl.YData = resp(k,it);
            end

            if ~yconst
                [sc.hax.YAxis(1)] = axismod(sc.hax.YAxis(1), resp(k,:), xtralimfac=xtralimfac, numtick=numticky, alignzero=0, label='resp',  labeltightfac=0);
                [ts.hax.YAxis(1)] = axismod(ts.hax.YAxis(1), resp(k,:), xtralimfac=xtralimfac, numtick=numticky, alignzero=0, label='resp',  labeltightfac=0);
                [ts2.hax.YAxis(1)] = axismod(ts2.hax.YAxis(1), resp(k,it), xtralimfac=xtralimfac, numtick=numticky, alignzero=0, label='resp',  labeltightfac=0);
            end


            htx.String = {['rec: ' fldr_title]; ['roi: ' num2str(rind) ', lag (sec): ' num2str(lagsec_actual_use(k)) ', slope: ' num2str(suse(k)) ', r-sq: ' num2str(r2use(k)) ', p: ' num2str(puse(k)), ', std: ' num2str(respstd(k))]};

            fig2gif(hfg, k2, pthgif)

        end
    end


end

end





function [slope_lagall, rsq_lagall, p_lagall] = lag_and_linfit(resp, stim, lagsamp, minpval, corrtype)

[resplag, stimlag] = lagvars(resp, stim, lagsamp);

% [r_lagall, p_lagall] = corr(resplag, stimlag, Type=corrtype);

[pars, stmp, mu] = polyfit(stimlag,resplag,1); %p(1) is slope, p(2) is intercept
slope_lagall = pars(1);
% rsq_lagall = 1 - (stmp.normr/norm(resplag - mean(resplag)))^2;
yfit = polyval(pars,stimlag,[],mu);
yresid = resplag - yfit;
SSresid = sum(yresid.^2);
SStotal = (length(resplag)-1) * var(resplag);
rsq_lagall = 1 - SSresid/SStotal;

tails = 2;
[ci,ptmp] = polyparci(pars,stmp,1-minpval,tails);
p_lagall = ptmp(1);

% %polyfit is fastest but simplest, but good enough for now; polyfit vs fitlm vs fit; fit has many options; fitlm does not center and scale data like polyfit with 3rd output (as above); fitlm has robust option to deal with outliers, polyfit does not
% mdl2 = fitlm(stimlag,resplag, 'poly1');
% slope_lagall2 = mdl2.Coefficients.Estimate(strcmp(mdl2.CoefficientNames, 'x1')); %pval for model diff from null model
% rsq_lagall2 = mdl2.Rsquared.Adjusted;
% p_lagall2 = mdl2.ModelFitVsNullModel.Pvalue;
% % pval_slope_lagall2 = mdl.Coefficients.pValue(strcmp(mdl.CoefficientNames, 'x1')); %pval for slope param
%
% % mdl3 = fit(stimlag,resplag, 'poly1'); %another linear model fitting option

% if p_lagall>minpval
%     r_lagall = 0;
%     rsq_lagall = 0;
% end
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
    opt.labcol = [0 0 0]
    opt.roundprec = 0
end


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
hax.TickLabels = round(hax.TickValues, opt.roundprec);
if hax.TickLabels(1)==hax.TickLabels(2) || str2double(hax.TickLabels)==0
    hax.TickLabels = round(hax.TickValues, opt.roundprec+1);
end
hax.Label.String = opt.label;
hax.Label.Color = opt.labcol;
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