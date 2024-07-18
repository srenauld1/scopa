function plot_multi_timeseries(ts1, ts2, pth_gif, xlim_segments, titlein, constant_ylim, ylim_padfac, ls1, ls2, match_ylim, gif_visibility)

% plot two timeseries on one figure, using different x and y axes
% if showing multiple xlim segments, the entire timeseries are only plotted once
% cplotting entire timeseries and changing xlim, rather than taking subsets of each timeseries, gives a more precise alignment
% loop over multiple subregions of x, save as gif

arguments
    ts1 double %timeseries 1, can be different length than ts2
    ts2 double %timeseries 2, can be different length than ts1
    pth_gif char %figure save path
    xlim_segments double = 1 %(n,2) vector of x axis limits as fraction range 0-1, or scalar n for partitioning x axis into n segments and plotting them all in gif, will plot all n
    titlein char = '' %title
    constant_ylim logical = 0 %whether to update y limits for each xlim subset
    ylim_padfac double = 0.1 %percentage of y range to pad above and below
    ls1 char = '-'
    ls2 char = '-'
    match_ylim = 0
    gif_visibility char = 'on'
end

if isempty(ls1)
    ls1 = '-';
end
if isempty(ls2)
    ls2 = '-';
end
if isempty(ts2)
    ts2 = ts1;
    ls2 = 'none';
end

ts1x = 1:numel(ts1);
ts2x = 1:numel(ts2);

dummyvec1 = nan(size(ts1));
dummyvec2 = nan(size(ts2));


if isscalar(xlim_segments)
    xlim_segments = linspace(0, 1, xlim_segments+1); %x axis limits as fraction of total, since two x axes are plotted
    xlim_segments = [xlim_segments(1:end-1) ; xlim_segments(2:end)];
end

if size(xlim_segments, 1)==2 %this will fail to fix transposed (2,2) xlim_segments, but keeping this check to avoid complexity
    xlim_segments = xlim_segments';
end

hfg = figure('Units', 'Normalized', 'Color', 'white', 'visible', gif_visibility) ;

ax1 = axes('Parent', hfg);
hpl1 = plot(ax1,dummyvec1,dummyvec1);
ax2 = axes('Parent', hfg);
hpl2 = plot(ax2,dummyvec1,dummyvec1);

for fi = 1:size(xlim_segments, 1)

    if fi==1

        hpl1.XData = ts1x;
        hpl1.YData = ts1;
        hpl1.Color = 'k';
        ax1.XColor = 'k';
        ax1.YColor = 'k';
        ax1.Box = 'off';

        hpl2.XData = ts2x;
        hpl2.YData = ts2;
        hpl2.Color = 'r';
        % hpl2.LineStyle = ls2;
        if startsWith(ls2, 'o')
            hpl2.Marker = 'o';
        end
        ax2.XAxisLocation = 'top';
        ax2.YAxisLocation = 'right';
        ax2.Color = 'none';
        ax2.XColor = 'r';
        ax2.YColor = 'r';
        ax2.Box = 'off';
        ax2.Title.String = strrep(titlein, '_', ' ');

    end

    Alim = numel(ts1) .* xlim_segments(fi,:);
    ax1.XLim = Alim;
    ax2.XLim = Alim / (numel(ts1) / numel(ts2));

    if constant_ylim
        ylm1 = [min(ts1) max(ts1)];
        ylm2 = [min(ts2) max(ts2)];
    else
        % error("something is wrong with this limit computation when constany_ylim==0, maybe only with nans")
        xrangenew1 = floor(ax1.XLim(1)):ceil(ax1.XLim(2));
        xrangenew1(xrangenew1==0) = []; %remove 0 if it exists
        xrangenew2 = floor(ax2.XLim(1)):ceil(ax2.XLim(2));
        xrangenew2(xrangenew2==0) = []; %remove 0 if it exists
        ylm1 = [min(ts1(xrangenew1), [], 'all', 'omitmissing') max(ts1(xrangenew1), [], 'all', 'omitmissing')];
        ylm2 = [min(ts2(xrangenew2), [], 'all', 'omitmissing') max(ts2(xrangenew2), [], 'all', 'omitmissing')];
    end
    
    if all(isfinite(ylm1))
        ax1.YLim = [ylm1(1) - range(ylm1)*ylim_padfac, ylm1(2) + range(ylm1)*ylim_padfac];
    end

    if match_ylim
        ax2.YLim = ax1.YLim;
    else
        if all(isfinite(ylm2))
            ax2.YLim = [ylm2(1) - range(ylm2)*ylim_padfac, ylm2(2) + range(ylm2)*ylim_padfac];
        end
    end


    fig2gif(hfg, fi, pth_gif)


end