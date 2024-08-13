function hgroup = init_axes_timeseries(hfg, ax, letui, numsamp, vars, ti, lims, ticklab, labs, cols, sector_ind, subplot_ind, widfac, htfac, rescale_timeseries, fontsz, axorder)

arguments
    hfg
    ax struct
    letui
    numsamp
    vars
    ti
    lims
    ticklab = []
    labs = []
    cols = []
    sector_ind = 1
    subplot_ind = 1
    widfac = 1
    htfac = 1
    rescale_timeseries = 1
    fontsz = [6 8 12]
    axorder char = 'rowmajor'
end

numxtick = 20;

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
fn = fieldnames(vars);


hax = [];
hpl = [];

for j = 1:numsubplot

    hax{j} = axes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition');
    hax{j}.InnerPosition(1) = ax(sector_ind).(axorder).xp(subplot_ind(j));
    hax{j}.InnerPosition(2) = ax(sector_ind).(axorder).yp(subplot_ind(j));
    hax{j}.InnerPosition(3) = ax(sector_ind).xe(widfac(j));
    hax{j}.InnerPosition(4) = ax(sector_ind).ye(htfac(j));

    hax{j}.Toolbar.Visible = 'off';


    hold(hax{j}, 'on')
    for fi = 1:numel(fn)

        ticktmp = [];
        formspec = '';

        eval(['yyaxis ' fn{fi}])
        for k = 1:size(vars.(fn{fi}), 1) %for each variable on fn{fi} (left or right side)
            hpl{j}{fi}{k} = plot(hax{j}, ti, dummyvec);
            hpl{j}{fi}{k}.Color = cols.(fn{fi}){k};
            hpl{j}{fi}{k}.LineStyle = '-';
            hax{j}.YAxis(fi).Color = [0 0 0];
            hax{j}.YAxis(fi).Label.String{k} = sprintf('\\color[rgb]{%f, %f, %f}%s', cols.(fn{fi}){k}, labs.(fn{fi}){k});
            hax{j}.YAxis(fi).Label.FontSize = fontsmall;

            hax{j}.YAxis(fi).TickValues = ticklab.(fn{fi}){k};

            if k<size(vars.(fn{fi}), 1)
                formspec = [formspec '%s\\newline'];
            else
                formspec = [formspec '%s\n'];
            end

            for tti = 1:numel(ticklab.(fn{fi}){k})
                ticktmp{k,tti} = sprintf('\\color[rgb]{%f, %f, %f}%s', cols.(fn{fi}){k}, num2str(ticklab.(fn{fi}){k}(tti), 4));
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

    if j==1

        if letui
            hax{j}.ButtonDownFcn = @(src,evnt)ui_t_click_fcn(src,evnt);
            hax{j}.PickableParts = 'visible';
            hax{j}.HitTest = 'on';
        end

        hax{j}.XTick = round(linspace(0, max(ti), numxtick));
        for tlx = 1:numel(hax{j}.XTick)
            if tlx==numel(hax{j}.XTick)
                hax{j}.XTickLabel{tlx} = [num2str(hax{j}.XTick(tlx)) ' sec'];
            else
                hax{j}.XTickLabel{tlx} = [num2str(hax{j}.XTick(tlx))];
            end
        end
    end
    hax{j}.XAxis.FontSize = fontmedium;
    hax{j}.XAxis.TickLength(1) = 0.005;

    % hax{j}.Color = 'k';

    hax{j}.Box = 'off';
    % hax{j}.XLabel.String = '';

    % hlnx{j} = xline(hax{j}, nan, 'k');
    hlnx{j} = line(hax{j}, [nan nan], lims.(fn{fi}).rescale_xtra, 'color', 'k', 'LineStyle','-');

    hold(hax{j}, 'off')

end


hgroup.hax = hax;
hgroup.hpl = hpl;
hgroup.hlnx = hlnx;


end





