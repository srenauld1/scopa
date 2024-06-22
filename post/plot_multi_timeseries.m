function plot_multi_timeseries(ts1, ts2, pth_gif, xlim_segments, titlein, constant_ylim, ylim_padfac)

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
end

if isscalar(xlim_segments)
    xlim_segments = linspace(0, 1, xlim_segments+1); %x axis limits as fraction of total, since two x axes are plotted
    xlim_segments = [xlim_segments(1:end-1) ; xlim_segments(2:end)];
end

if size(xlim_segments, 1)==2 %this will fail to fix transposed (2,2) xlim_segments, but keeping this check to avoid complexity
    xlim_segments = xlim_segments';
end

hfg = figure;

ax1 = axes('Parent', hfg);
ax2 = axes('Parent', hfg);

for fi = 1:size(xlim_segments, 1)

    if fi==1

        plot(ax1,1:numel(ts1),ts1,'-k');
        ax1.XColor = 'k';
        ax1.YColor = 'k';
        ax1.Box = 'off';



        plot(ax2,1:numel(ts2),ts2,'-r');
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
        xrangenew1 = floor(ax1.XLim(1)):ceil(ax1.XLim(2));
        xrangenew1(xrangenew1==0) = []; %remove 0 if it exists
        xrangenew2 = floor(ax2.XLim(1)):ceil(ax2.XLim(2));
        xrangenew2(xrangenew2==0) = []; %remove 0 if it exists
        ylm1 = [min(ts1(xrangenew1)) max(ts1(xrangenew1))];
        ylm2 = [min(ts2(xrangenew2)) max(ts2(xrangenew2))];
    end
    ax1.YLim(1) = ylm1(1) - range(ylm1)*ylim_padfac;
    ax1.YLim(2) = ylm1(2) + range(ylm1)*ylim_padfac;
    ax2.YLim(1) = ylm2(1) - range(ylm2)*ylim_padfac;
    ax2.YLim(2) = ylm2(2) + range(ylm2)*ylim_padfac;


    fig2gif(hfg, fi, pth_gif)


end