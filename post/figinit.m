function [hfg, hax, htx] = figinit(hfg, hax, htx, numrows_plot, numcolumns_plot, margins_fig, margins_subplot, sizefont)

[axx, axy, axw, axh] = figarr(numrows_plot, numcolumns_plot, margins_fig, margins_subplot);

if isempty(hax)
    hfg = figure( 'Units', 'Normalized', 'Color', 'white', 'visible', 'on') ;
    hfg.Position = [0 0 0.5 0.5]; %make square inner size (excludes top menu bar), plot in bottom left
    bgax = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', 'XLim', [0, 1], 'YLim', [0, 1] ) ;
    htx = text( 0.05, 0.99, '', 'FontSize', sizefont, 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', 'FontWeight', 'bold' ) ;
else
    for si = 1:numel(hax)
        delete(hax{si})
    end
    hax = [];
end

for si = 1:numel(axx)
    hax{si} = axes( 'Parent', hfg, 'Position', [axx(si), axy(si), axw(si), axh(si)] );
end
