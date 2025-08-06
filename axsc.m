function h = axsc(x, y, opt)

arguments
    x
    y
    opt.h = []
    opt.ax = []
    opt.doui = 0
    opt.sctype = 'cartesian'
    opt.mkrsz = 8
    opt.blindspot = NaN
    opt.actual_lags_xy_sec = []
    opt.plot_z_as_color = 1
    opt.labs = []
    opt.cols = []
    opt.sector_ind = 1
    opt.subplot_ind = 1
    opt.widfac = 1
    opt.htfac = 1
    opt.fontsz = [6 8 12]
    opt.colmaj = 0
end
h = opt.h;
ax = opt.ax;
doui = opt.doui;
sctype = opt.sctype;
mkrsz = opt.mkrsz;
blindspot = opt.blindspot;
actual_lags_xy_sec = opt.actual_lags_xy_sec;
plot_z_as_color = opt.plot_z_as_color;
labs = opt.labs;
cols = opt.cols;
sector_ind = opt.sector_ind;
subplot_ind = opt.subplot_ind;
widfac = opt.widfac;
htfac = opt.htfac;
fontsz = opt.fontsz;
colmaj = opt.colmaj;

do_bar = 0;
force_square = 0;
numxtick = 20;
bar_axisroomfac = 0.1;

if isempty(h)
    h = fg;
end
if isempty(ax)
    ax = axarr(1);
end

numsubplot = numel(subplot_ind);
if numel(widfac)==1 && numsubplot>1
    widfac = repelem(widfac, numsubplot);
end
if numel(htfac)==1 && numsubplot>1
    htfac = repelem(htfac, numsubplot);
end

if isvector(x) && iscolumn(x)
    x = x(:)'; %make it a row vector, since time should be 2nd dim (in case we are plotting time, which we often are)
end
numsamp = size(x,2);
if ~isequal(size(y,2), numsamp)
    if isvector(y) && iscolumn(y)
        y = y';
    end
    if ~isequal(size(y,2), numsamp)
        error("x and y must have same size in 2nd dimenson")
    end
end

dummyvec = nan(numsamp, 1);


h.ax = [];
h.pl = [];
h.ln = [];
h.br = [];

for j = 1:numsubplot

    tmp_x_extent = ax(sector_ind).w(widfac(j));
    tmp_y_extent = ax(sector_ind).h(htfac(j));
    newextent = max(tmp_x_extent, tmp_y_extent); %force this axis to be square, without

    switch sctype

        case 'cartesian'

            h.ax{j} = axes( 'Parent', h.fg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition');

            if colmaj
                h.ax{j}.InnerPosition(1) = ax(sector_ind).colmaj.x(subplot_ind(j));
                h.ax{j}.InnerPosition(2) = ax(sector_ind).colmaj.y(subplot_ind(j));
            else
                h.ax{j}.InnerPosition(1) = ax(sector_ind).x(subplot_ind(j));
                h.ax{j}.InnerPosition(2) = ax(sector_ind).y(subplot_ind(j));
            end
            h.ax{j}.InnerPosition(3) = newextent;
            h.ax{j}.InnerPosition(4) = newextent;

            h.ax{j}.Toolbar.Visible = 'off';

            hold(h.ax{j}, 'on')
            if plot_z_as_color
                h.pl{j} = scatter(h.ax{j}, dummyvec, dummyvec, mkrsz, dummyvec, 'filled');
            else
                h.pl{j} = scatter3(h.ax{j}, dummyvec, dummyvec, dummyvec, mkrsz, dummyvec, 'filled');
            end

            h.ax{j}.XAxis.TickValues = [];
            h.ax{j}.YAxis.TickValues = [];
            h.ax{j}.XAxis.TickLabels = {};
            h.ax{j}.YAxis.TickLabels = {};

            h.ax{j}.Box = 'off';
            % if ylim_constancy
            %     % h.ax{j}.XLim = [0 1];
            %     % h.ax{j}.YLim = [0 1];
            % end
            % h.pl{j}.MarkerFaceColor = 'k';

            h.ln{j} = [];

            hold(h.ax{j}, 'off')


        case 'polar'


            h.ax{j} = polaraxes( 'Parent', h.fg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition' );

            if colmaj
                h.ax{j}.InnerPosition(1) = ax(sector_ind).colmaj.x(subplot_ind(j));
                h.ax{j}.InnerPosition(2) = ax(sector_ind).colmaj.y(subplot_ind(j));
            else
                h.ax{j}.InnerPosition(1) = ax(sector_ind).x(subplot_ind(j));
                h.ax{j}.InnerPosition(2) = ax(sector_ind).y(subplot_ind(j));
            end
            h.ax{j}.InnerPosition(3) = newextent;
            h.ax{j}.InnerPosition(4) = newextent;


            h.ax{j}.Toolbar.Visible = 'off';

            hold(h.ax{j}, 'on')
            h.pl{j} = polarscatter(h.ax{j}, dummyvec, dummyvec, mkrsz, 'filled');
            h.ln{j} = polarplot(h.ax{j}, [blindspot blindspot], [0 0], 'r');

            % h.pl{j}.MarkerFaceColor = 'k';
            h.ln{j}.LineStyle = 'none';

            h.ax{j}.RTickLabel = [];

            h.ax{j}.ThetaTick = [0 90 180 270];
            h.ax{j}.ThetaTickLabel = {'0', '90', '180', '270'};

            h.ax{j}.ThetaAxis.Label.Units = 'normalized';
            h.ax{j}.ThetaAxis.Label.Position = [0.5, -0.05, 0];
            h.ax{j}.ThetaAxis.Label.Rotation = 0;
            h.ax{j}.RAxis.Label.Units = 'normalized';
            h.ax{j}.RAxis.Label.Position = [-0.13, 0.5, 0];
            h.ax{j}.RAxis.Label.Rotation = 90;

            % if ylim_constancy
            %     h.ax{j}.RLim = [0 1];
            % end

            hold(h.ax{j}, 'off')



    end

    h.pl{j}.CData = repmat([0 0 0], numsamp, 1);
    h.pl{j}.MarkerFaceAlpha = 0.3;



    if do_bar

        %%INSET BAR PLOT FOR LAG CC%%

        if isempty(numlags) || isempty(actual_lags_xy_sec)
            error("if do_bar is true, numlags and actual_lags_xy_sec cannot be empty")
        end
        dummyvec_lag = nan(numlags, 1);

        inset_widfac = 0.1;
        inset_htfac = 0.1;

        h.br{j}.h.ax = axes( 'Parent', h.fg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition');
        h.br{j}.h.ax.InnerPosition(1) = h.ax{j}.InnerPosition(1)+0.05;
        h.br{j}.h.ax.InnerPosition(2) = h.ax{j}.InnerPosition(2)+0.05;
        h.br{j}.h.ax.InnerPosition(3) = h.ax{j}.InnerPosition(3)-h.ax{j}.InnerPosition(3)*inset_widfac;
        h.br{j}.h.ax.InnerPosition(4) = h.ax{j}.InnerPosition(4)-h.ax{j}.InnerPosition(4)*inset_htfac;

        hold(h.br{j}.h.ax, 'on')

        h.br{j}.h.pl = bar(h.br{j}.h.ax, dummyvec_lag, dummyvec_lag);
        h.br{j}.h.ln = xline(h.br{j}.h.ax, nan, 'k');

        h.br{j}.h.ax.YLim = [-1 1];
        h.br{j}.h.ax.Box = 'off';
        h.br{j}.h.ax.Title.String = 'LAG';
        h.br{j}.h.ax.XLim = [min(actual_lags_xy_sec) - range(actual_lags_xy_sec)*bar_axisroomfac, max(actual_lags_xy_sec) + range(actual_lags_xy_sec)*bar_axisroomfac];
        h.br{j}.h.ax.XTick = [min(actual_lags_xy_sec), 0, max(actual_lags_xy_sec)];
        h.br{j}.h.ax.XTickLabels = {sprintf('%.2g', min(actual_lags_xy_sec)), 0, sprintf('%.2g', max(actual_lags_xy_sec))};
        h.br{j}.h.ax.Title.String = 'LAGS';
        h.br{j}.h.ax.YLabel.String = 'CORR COEFF';

        hold(h.br{j}.h.ax, 'off')

    end


end

end

