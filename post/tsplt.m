function [hfg, hax] = tsplt(y1, opt)

% plot 1 or 2 timeseries on one figure with different x and y axes
% optionally sequentially display over one or more segments of x, optionally saving each segment as frame of gif
% option to pass existing figure handle and add axes to that

arguments
    y1 {mustBeVector} %timeseries 1, can be different length than y2
    opt.x1 {mustBeVector} = 1:numel(y1); %x for timeseries 1
    opt.y2 = [] %timeseries 2, can be different length than y1
    opt.x2 = []; %x for timeseries 2
    opt.xseg {mustBeNumeric} = 1 %(n,2) vector of x axis limits as fraction range 0-1, or scalar n for partitioning x axis into n segments; will plot each n and optionally save each as different frame in gif
    opt.yconst {mustBeNumeric} = 0 %whether to update y limits for each xlim subset
    opt.ymatch {mustBeNumeric} = 0 %match y axes if plotting two timeseries (force y axis for 2nd timeseries to match y axis for first timeseries)
    opt.ypadfac {mustBeNumeric} = 0.1 %percentage of y range to pad above and below
    opt.ls1 {mustBeText} = '-' %linestyle for line 1
    opt.ls2 {mustBeText} = '-' %linestyle for line 2
    opt.mkr1 {mustBeText} = 'none' %marker for line 1
    opt.mkr2 {mustBeText} = 'none' %marker for line 2
    opt.titlein {mustBeText} = '' %title
    opt.pthgif {mustBeText} = '' %figure save path
    opt.gifvis {mustBeText} = 'on'
    opt.hfg = [] %can pass figure handle to add to existing figure
    opt.axpos = []; %axis position
end

x1 = opt.x1;
y2 = opt.y2;
x2 = opt.x2;
xseg = opt.xseg;
yconst = opt.yconst;
ymatch = opt.ymatch;
ypadfac = opt.ypadfac;
ls1 = opt.ls1;
ls2 = opt.ls2;
mkr1 = opt.mkr1;
mkr2 = opt.mkr2;
titlein = opt.titlein;
pthgif = opt.pthgif;
gifvis = opt.gifvis;
hfg = opt.hfg;
axpos = opt.axpos;

if isempty(pthgif)
    pthgif = pthauto(suffix='.gif', usetime=1, usefun=1);
end
if isempty(x1)
    x1 = 1:numel(y1);
end
if isempty(x2)
    default_x2 = 1;
    x2 = 1:numel(y2);
else
    default_x2 = 0;
end
if ~isempty(axpos) && isempty(hfg)
    error("must not pass axpos without hfg")
end
if isempty(axpos)
    if isempty(hfg)
        axpos = [0.1300 0.1100 0.7750 0.8150];
    else
        error("must pass axpos if you pass hfg")
    end
end


dummyvec1 = nan(size(y1));
dummyvec2 = nan(size(y2));


if isscalar(xseg)
    xseg = linspace(0, 1, xseg+1); %x axis limits as fraction of total, since two x axes are plotted
    xseg = [xseg(1:end-1); xseg(2:end)];
end

if size(xseg, 1)==2 %this will fail to fix transposed (2,2) xseg, but keeping this check to avoid complexity
    xseg = xseg';
end

if isempty(hfg)
    dosave = 1;
    hfg = figure('Units', 'Normalized', 'Color', 'white', 'visible', gifvis);
else
    dosave = 1; %1 for now but eventually 0 here; not set up to save outside this function because of the loop, but that would be better 
end

hax{1} = axes('Parent', hfg, 'Position', axpos);
hpl{1} = plot(hax{1},dummyvec1,dummyvec1);
if ~isempty(y2)
    hax{2} = axes('Parent', hfg, 'Position', axpos);
    hpl{2} = plot(hax{2},dummyvec1,dummyvec1);
end

for fi = 1:size(xseg, 1)

    if fi==1 %plot on first frame, change x lim on subsequent frames (if there are any)

        hpl{1}.XData = x1;
        hpl{1}.YData = y1;
        hpl{1}.Color = 'k';
        hpl{2}.LineStyle = ls1;
        hpl{2}.Marker = mkr1;
        hax{1}.XColor = 'k';
        hax{1}.YColor = 'k';
        hax{1}.Box = 'off';

        if ~isempty(y2)
            hpl{2}.XData = x2;
            hpl{2}.YData = y2;
            hpl{2}.Color = 'm';
            hpl{2}.LineStyle = ls2;
            hpl{2}.Marker = mkr2;
            hax{2}.XAxisLocation = 'top';
            hax{2}.YAxisLocation = 'right';
            hax{2}.Color = 'none';
            hax{2}.XColor = 'm';
            hax{2}.YColor = 'm';
            hax{2}.Box = 'off';
            hax{2}.Title.String = strrep(titlein, '_', ' ');
        end

    end

    limtmp = numel(y1) .* xseg(fi,:);
    hax{1}.XLim = limtmp;
    if ~isempty(y2)
        if default_x2 %if no x2 provided, x2 is 1:number samples, so rescale x segment in case y1 and y2 have different lengths (eg are differently sampled from same time segment)
            hax{2}.XLim = limtmp / (numel(y1) / numel(y2));
        else
            hax{2}.XLim = limtmp;
        end
    end

    if yconst
        ylm1 = [min(y1) max(y1)];
        if ~isempty(y2)
            ylm2 = [min(y2) max(y2)];
        end
    else
        % error("something is wrong with this limit computation when constany_ylim==0, maybe only with nans")
        xrangenew1 = floor(hax{1}.XLim(1)):ceil(hax{1}.XLim(2));
        xrangenew1(xrangenew1==0) = []; %remove 0 if it exists
        ylm1 = [min(y1(xrangenew1), [], 'all', 'omitmissing') max(y1(xrangenew1), [], 'all', 'omitmissing')];

        if ~isempty(y2)
            % error("something is wrong with this limit computation when constany_ylim==0, maybe only with nans")
            xrangenew2 = floor(hax{2}.XLim(1)):ceil(hax{2}.XLim(2));
            xrangenew2(xrangenew2==0) = []; %remove 0 if it exists
            ylm2 = [min(y2(xrangenew2), [], 'all', 'omitmissing') max(y2(xrangenew2), [], 'all', 'omitmissing')];
        end
    end


    if all(isfinite(ylm1)) %why did i do this? nans from dividing by zero when rescaling?
        if ylm1(1)~=ylm1(2) %in case segment is constant, just skip setting new scale
            hax{1}.YLim = [ylm1(1) - range(ylm1)*ypadfac, ylm1(2) + range(ylm1)*ypadfac];
        end
    end
    if ~isempty(y2)
        if ymatch
            hax{2}.YLim = hax{1}.YLim;
        else
            if all(isfinite(ylm2)) %why did i do this?  nans from dividing by zero when rescaling?
                if ylm2(1)~=ylm2(2) %in case segment is constant, , just skip setting new scale
                    hax{2}.YLim = [ylm2(1) - range(ylm2)*ypadfac, ylm2(2) + range(ylm2)*ypadfac];
                end
            end
        end
    end


    if dosave
        fig2gif(hfg, fi, pthgif)
    end

end