function hndls = init_axes_timeseries(hndls, ax, numsamp, varinds, ti, lims, ticklab, labsp, cols, sector_ind, subplot_ind, widfac, htfac, rescale_timeseries, fontsz, figsidelength, gif_visibility, axorder)

arguments
    hndls struct
    ax struct
    numsamp
    varinds
    ti
    lims
    ticklab = []
    labsp = []
    cols = []
    sector_ind = 1
    subplot_ind = 1
    widfac = 1
    htfac = 1
    rescale_timeseries = 1
    fontsz = [6 11 15]
    figsidelength = 0.75
    gif_visibility = 'on'
    axorder char = 'rowmajor'
end


numsubplot = numel(subplot_ind);
if numel(widfac)==1 && numsubplot>1
    widfac = repelem(widfac, numsubplot);
end
if numel(htfac)==1 && numsubplot>1
    htfac = repelem(htfac, numsubplot);
end
fontsmall = fontsz(1);
fontmedium = fontsz(2);
dummyvec = nan(numsamp, 1);
fn = fieldnames(varinds);


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
hpl = [];

for j = 1:numsubplot

    hax{j} = axes( 'Parent', hndls.hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition');
    hax{j}.InnerPosition(1) = ax(sector_ind).(axorder).xp(subplot_ind(j));
    hax{j}.InnerPosition(2) = ax(sector_ind).(axorder).yp(subplot_ind(j));
    hax{j}.InnerPosition(3) = ax(sector_ind).xe(widfac(j));
    hax{j}.InnerPosition(4) = ax(sector_ind).ye(htfac(j));

    hold(hax{j}, 'on')
    for fi = 1:numel(fn)

        ticktmp = [];
        formspec = '';

        eval(['yyaxis ' fn{fi}])
        for k = 1:numel(varinds.(fn{fi})) %for each variable on side fn{fi} (left or right)
            hpl{j}{fi}{k} = plot(hax{j}, ti, dummyvec);
            hpl{j}{fi}{k}.Color = cols(varinds.(fn{fi})(k),:);
            hpl{j}{fi}{k}.LineStyle = '-';
            hax{j}.YAxis(fi).Color = [0 0 0];
            hax{j}.YAxis(fi).Label.String{k} = sprintf('\\color[rgb]{%f, %f, %f}%s', cols(varinds.(fn{fi})(k),:), labsp.(fn{fi}){k});
            hax{j}.YAxis(fi).Label.FontSize = fontsmall;

            hax{j}.YAxis(fi).TickValues = ticklab.(fn{fi}){k};

            if k<numel(varinds.(fn{fi}))
                formspec = [formspec '%s\\newline'];
            else
                formspec = [formspec '%s\n'];
            end

            for tti = 1:numel(ticklab.(fn{fi}){k})
                ticktmp{k,tti} = sprintf('\\color[rgb]{%f, %f, %f}%s', cols(varinds.(fn{fi})(k),:), num2str(ticklab.(fn{fi}){k}(tti), 4));
            end

        end

        YTickString = strtrim(sprintf(formspec, ticktmp{:}));

        hax{j}.YAxis(fi).TickLabels = YTickString;
        hax{j}.YAxis(fi).TickLabelInterpreter = 'tex';
        if rescale_timeseries
            hax{j}.YAxis(fi).Limits = lims.(fn{fi}).rescale_xtra;
            hax{j}.YAxis(fi).TickValues = lims.(fn{fi}).rescale;
        else
            error("rescale_timeseries is currently required")
        end

        hax{j}.YAxis(fi).FontSize = fontsmall;

    end

    hax{j}.XTick = round(max(ti));
    hax{j}.XTickLabel = [num2str(hax{j}.XTick) ' sec'];

    % hax{j}.Color = 'k';

    hax{j}.Box = 'off';
    % hax{j}.XLabel.String = '';

    % hlnx{j} = xline(hax{j}, nan, 'k');
    hlnx{j} = line(hax{j}, [nan nan], lims.(fn{fi}).rescale_xtra, 'color', 'k', 'LineStyle','-');

    hold(hax{j}, 'off')

end


hndls.ts.hax = hax;
hndls.ts.hpl = hpl;
hndls.ts.hlnx = hlnx;



end