function plot_multi_timeseries(ts1, ts2, xlim_prct, ylimfac)

arguments
    ts1 double
    ts2 double
    xlim_prct double = [0 1]
    ylimfac double = 0.1
end


Alim = numel(ts1) .* xlim_prct; %[2.2e5 2.6e5] in ts1 . . . restrict x axis to small region (which includes abrupt transition)
hfg = figure;
ax1 = axes(hfg);
plot(ax1,1:numel(ts1),ts1,'-k')
ax1.XColor = 'k';
ax1.YColor = 'k';
ax1.XLim = Alim;
ax1.Box = 'off';
ylm = ax1.YLim;
ax1.YLim(1) = ax1.YLim(1) - abs(ax1.YLim(1))*ylimfac;
ax1.YLim(2) = ax1.YLim(2) + abs(ax1.YLim(2))*ylimfac;

ax2 = axes(hfg);
plot(ax2,1:numel(ts2),ts2,'-r')
ax2.XAxisLocation = 'top';
ax2.YAxisLocation = 'right';
ax2.Color = 'none';
ax2.XColor = 'r';
ax2.YColor = 'r';
ax2.Box = 'off';
ax2.XLim = Alim / (numel(ts1) / numel(ts2));
ax2.YLim(1) = ax2.YLim(1) - abs(ax2.YLim(1))*ylimfac;
ax2.YLim(2) = ax2.YLim(2) + abs(ax2.YLim(2))*ylimfac;
