function hgroup = init_axes_scatter(hfg, ax, letui, scatter_type, mkrsz, blindspot, numsamp, numlags, actual_lags_xy_sec, plot_z_as_color, labs, cols, sector_ind, subplot_ind, widfac, htfac, fontsz, axorder)

arguments
    hfg
    ax struct
    letui
    scatter_type
    mkrsz
    blindspot
    numsamp
    numlags
    actual_lags_xy_sec
    plot_z_as_color
    labs = []
    cols = []
    sector_ind = 1
    subplot_ind = 1
    widfac = 1
    htfac = 1
    fontsz = [6 8 12]
    axorder char = 'rowmajor'
end

do_bar = 0;
force_square = 0;
numxtick = 20;
bar_axisroomfac = 0.1;

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
dummyvec_lag = nan(numlags, 1);


hax = [];
hpl = [];
hln = [];
br = [];


for j = 1:numsubplot

    tmp_x_extent = ax(sector_ind).xe(widfac(j));
    tmp_y_extent = ax(sector_ind).ye(htfac(j));
    newextent = max(tmp_x_extent, tmp_y_extent); %force this axis to be square, without

    switch scatter_type

        case 'cartesian'

            hax{j} = axes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition');

            hax{j}.InnerPosition(1) = ax(sector_ind).(axorder).xp(subplot_ind(j));
            hax{j}.InnerPosition(2) = ax(sector_ind).(axorder).yp(subplot_ind(j));
            hax{j}.InnerPosition(3) = newextent;
            hax{j}.InnerPosition(4) = newextent;

            hax{j}.Toolbar.Visible = 'off';

            hold(hax{j}, 'on')
            if plot_z_as_color
                hpl{j} = scatter(hax{j}, dummyvec, dummyvec, mkrsz, dummyvec, 'filled');
            else
                hpl{j} = scatter3(hax{j}, dummyvec, dummyvec, dummyvec, mkrsz, dummyvec, 'filled');
            end

            hax{j}.XAxis.TickValues = [];
            hax{j}.YAxis.TickValues = [];
            hax{j}.XAxis.TickLabels = {};
            hax{j}.YAxis.TickLabels = {};

            hax{j}.Box = 'off';
            % if ylim_constancy
            %     % hax{j}.XLim = [0 1];
            %     % hax{j}.YLim = [0 1];
            % end
            % hpl{j}.MarkerFaceColor = 'k';

            hln{j} = [];

            hold(hax{j}, 'off')


        case 'polar'


            hax{j} = polaraxes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition' );

            hax{j}.InnerPosition(1) = ax(sector_ind).(axorder).xp(subplot_ind(j));
            hax{j}.InnerPosition(2) = ax(sector_ind).(axorder).yp(subplot_ind(j));
            hax{j}.InnerPosition(3) = newextent;
            hax{j}.InnerPosition(4) = newextent;


            hax{j}.Toolbar.Visible = 'off';

            hold(hax{j}, 'on')
            hpl{j} = polarscatter(hax{j}, dummyvec, dummyvec, mkrsz, 'filled');
            hln{j} = polarplot(hax{j}, [blindspot blindspot], [0 0], 'r');

            % hpl{j}.MarkerFaceColor = 'k';
            hln{j}.LineStyle = 'none';

            hax{j}.RTickLabel = [];

            hax{j}.ThetaTick = [0 90 180 270];
            hax{j}.ThetaTickLabel = {'0', '90', '180', '270'};

            hax{j}.ThetaAxis.Label.Units = 'normalized';
            hax{j}.ThetaAxis.Label.Position = [0.5, -0.05, 0];
            hax{j}.ThetaAxis.Label.Rotation = 0;
            hax{j}.RAxis.Label.Units = 'normalized';
            hax{j}.RAxis.Label.Position = [-0.13, 0.5, 0];
            hax{j}.RAxis.Label.Rotation = 90;

            % if ylim_constancy
            %     hax{j}.RLim = [0 1];
            % end

            hold(hax{j}, 'off')



    end

    hpl{j}.CData = repmat([0 0 0], numsamp, 1);
    hpl{j}.MarkerFaceAlpha = 0.3;



    if do_bar

        %%INSET BAR PLOT FOR LAG CC%%

        inset_widfac = 0.1;
        inset_htfac = 0.1;

        br{j}.hax = axes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition');
        br{j}.hax.InnerPosition(1) = hax{j}.InnerPosition(1)+0.05;
        br{j}.hax.InnerPosition(2) = hax{j}.InnerPosition(2)+0.05;
        br{j}.hax.InnerPosition(3) = hax{j}.InnerPosition(3)-hax{j}.InnerPosition(3)*inset_widfac;
        br{j}.hax.InnerPosition(4) = hax{j}.InnerPosition(4)-hax{j}.InnerPosition(4)*inset_htfac;

        hold(br{j}.hax, 'on')

        br{j}.hpl = bar(br{j}.hax, dummyvec_lag, dummyvec_lag);
        br{j}.hln = xline(br{j}.hax, nan, 'k');

        br{j}.hax.YLim = [-1 1];
        br{j}.hax.Box = 'off';
        br{j}.hax.Title.String = 'LAG';
        br{j}.hax.XLim = [min(actual_lags_xy_sec) - range(actual_lags_xy_sec)*bar_axisroomfac, max(actual_lags_xy_sec) + range(actual_lags_xy_sec)*bar_axisroomfac];
        br{j}.hax.XTick = [min(actual_lags_xy_sec), 0, max(actual_lags_xy_sec)];
        br{j}.hax.XTickLabels = {sprintf('%.2g', min(actual_lags_xy_sec)), 0, sprintf('%.2g', max(actual_lags_xy_sec))};
        br{j}.hax.Title.String = 'LAGS';
        br{j}.hax.YLabel.String = 'CORR COEFF';

        hold(br{j}.hax, 'off')

    end


end


hgroup.hax = hax;
hgroup.hpl = hpl;
hgroup.hln = hln;
hgroup.br = br;

end

