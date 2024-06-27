function hndls = init_axes_timeseries(hndls, ax, numsamp, varsleft, varsright, ti, lims, sector_ind, subplot_ind, widfac, htfac, fontsz, figsidelength, gif_visibility, axorder)

arguments
    hndls struct
    ax struct
    numsamp
    varsleft
    varsright
    ti
    lims = []
    sector_ind = 1
    subplot_ind = 1
    widfac = 1
    htfac = 1
    fontsz = [6 11 15]
    figsidelength = 0.75
    gif_visibility = 'on'
    axorder char = 'rowmajor'
end

numsubplot = numel(subplot_ind);
fontsmall = fontsz(1);
fontmedium = fontsz(2);
fontlarge = fontsz(3);
numvarsleft = size(varsleft,1);
numvarsright = size(varsright,1);
dummyvec = nan(numsamp, 1);


if ~isfield(hndls, 'hfg') %if no figure has been initialized yet, initialize the axes that won't change

    hfg = figure;
    aspect_screen = hfg.Parent.ScreenSize(3) / hfg.Parent.ScreenSize(4); %get screen aspect ratio
    close(hfg)


    hfg = figure( 'Units', 'Normalized', 'Color', 'white', 'visible', gif_visibility) ;
    if aspect_screen>1
        hfg.Position = [0 0 figsidelength/aspect_screen figsidelength]; %make square inner size (excludes top menu bar), plot in bottom left
    else
        hfg.Position = [0 0 figsidelength figsidelength/aspect_screen]; %make square inner size (excludes top menu bar), plot in bottom left
    end
    haxmain = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', 'XLim', [0, 1], 'YLim', [0, 1] ) ;
    httl = text( haxmain, 0.5, 0.99, '', 'FontSize', fontmedium, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontWeight', 'bold' );

    hndls.hfg = hfg;
    hndls.haxmain = haxmain;
    hndls.httl = httl;

end

hax = [];
hpll = [];
hplr = [];


for j = 1:numsubplot

    hax{j} = axes( 'Parent', hndls.hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition');
    hax{j}.InnerPosition(1) = ax(sector_ind).(axorder).xp(subplot_ind(j));
    hax{j}.InnerPosition(2) = ax(sector_ind).(axorder).yp(subplot_ind(j));
    hax{j}.InnerPosition(3) = ax(sector_ind).xe(widfac);
    hax{j}.InnerPosition(4) = ax(sector_ind).ye(htfac);


    hold(hax{j}, 'on')
    yyaxis left
    for k = 1:numvarsleft
        hpll{j}{k} = plot(hax{j}, dummyvec, dummyvec);
        hpll{j}{k}.Color = [0 0 1];
        hax{j}.YAxis(1).Color = [0 0 1];
    end
    yyaxis right
    for k = 1:numvarsright
        hplr{j}{k} = plot(hax{j}, dummyvec, dummyvec);
        hplr{j}{k}.Color = [1 0 0];
        hax{j}.YAxis(2).Color = [1 0 0];
    end


    hlnx{j} = xline(hax{j}, nan, 'k');

    hax{j}.XTick = round(max(ti));
    hax{j}.XTickLabel = [num2str(hax{j}.XTick) ' sec'];

    if ~isempty(lims) %initialize to the limits of all variables (later can change to each if requested)
        hax{j}.YAxis(1).Limits = lims.x.all_xtra;
        hax{j}.YAxis(2).Limits = lims.y.all_xtra;
        hndls.ts.hax.YAxis(1).Limits = lims.x.all_xtra;
        hndls.ts.hax.YAxis(2).Limits = lims.y.all_xtra;
        hndls.ts.hax.YAxis(1).TickValues = sort([0, lims.x.all(1), lims.x.all(2)]);
        hndls.ts.hax.YAxis(2).TickValues = sort([0, lims.y.all(1), lims.y.all(2)]);
        hndls.ts.hax.YAxis(1).TickLabels = [];
        hndls.ts.hax.YAxis(2).TickLabels = [];
        for tti = 1:numel(hndls.ts.hax.YAxis(2).TickValues)
            hndls.ts.hax.YAxis(1).TickLabels{tti} = num2str(hndls.ts.hax.YAxis(1).TickValues(tti), 4);%'%.2g'
            hndls.ts.hax.YAxis(2).TickLabels{tti} = num2str(hndls.ts.hax.YAxis(2).TickValues(tti), 4);%'%.2g'
        end
    end

    hax{j}.Box = 'off';
    hax{j}.XLabel.String = '';
    hax{j}.YLabel.String = '';

    hold(hax{j}, 'off')

end


hndls.ts.hax = hax;
hndls.ts.hpll = hpll;
hndls.ts.hplr = hplr;
hndls.ts.hlnx = hlnx;



end