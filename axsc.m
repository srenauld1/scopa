function h = axsc(x, y, z, opt)

arguments
    x
    y
    z = []
    opt.h = []
    opt.ax = []
    opt.doui = 0
    opt.sctype = 'cartesian'
    opt.mkrsz = 20
    opt.blindspot = NaN
    opt.actual_lags_xy_sec = []
    opt.plot_z_as_color = 1
    opt.labs = []
    opt.cols = []
    opt.idxsect = 1
    opt.idxsubp = 1
    opt.widfac = 1
    opt.htfac = 1
    opt.fontsz = [6 8 12]
    opt.colmaj = 0
    opt.nm = 'sc'
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
idxsect = opt.idxsect;
idxsubp = opt.idxsubp;
widfac = opt.widfac;
htfac = opt.htfac;
fontsz = opt.fontsz;
colmaj = opt.colmaj;
nm = opt.nm;

do_bar = 0;
force_square = 0;
numxtick = 20;
bar_axisroomfac = 0.1;


if isempty(h)
    h = fg();
end
if isfield(h, 'fg') && ~isscalar(h.fg)
    error("h.fg input to axim must be scalar (choose one figure to initialize the axis)")
end
if isfield(h, nm)
    q = numel(h.(nm));
else
    q = 0;
end
q = q+1;

if isempty(ax)
    ax = axarr(1);
end

numsubplot = numel(idxsubp);
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
dummyvec = nan(1, numsamp);

if ~isequal(size(y,2), numsamp)
    if isvector(y) && iscolumn(y)
        y = y';
    end
    if ~isequal(size(y,2), numsamp)
        error("x and y must have same size in 2nd dimenson")
    end
end
if isempty(z)
    z = dummyvec;
end
if ~isequal(size(z,2), numsamp)
    if isvector(z) && iscolumn(z)
        z = z';
    end
    if ~isequal(size(z,2), numsamp)
        error("x and z must have same size in 2nd dimenson")
    end
end



h.(nm)(q).ax = [];
h.(nm)(q).pl = [];
h.(nm)(q).ln = [];
h.(nm)(q).br = [];

for j = 1:numsubplot

    tmp_x_extent = ax(idxsect).w(widfac(j));
    tmp_y_extent = ax(idxsect).h(htfac(j));
    newextent = max(tmp_x_extent, tmp_y_extent); %force this axis to be square, without

    switch sctype

        case 'cartesian'

            h.(nm)(q).ax{j} = axes( 'Parent', h.fg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition');

            if colmaj
                h.(nm)(q).ax{j}.InnerPosition(1) = ax(idxsect).colmaj.x(idxsubp(j));
                h.(nm)(q).ax{j}.InnerPosition(2) = ax(idxsect).colmaj.y(idxsubp(j));
            else
                h.(nm)(q).ax{j}.InnerPosition(1) = ax(idxsect).x(idxsubp(j));
                h.(nm)(q).ax{j}.InnerPosition(2) = ax(idxsect).y(idxsubp(j));
            end
            h.(nm)(q).ax{j}.InnerPosition(3) = newextent;
            h.(nm)(q).ax{j}.InnerPosition(4) = newextent;

            h.(nm)(q).ax{j}.Toolbar.Visible = 'off';

            hold(h.(nm)(q).ax{j}, 'on')
            if plot_z_as_color
                h.(nm)(q).pl{j} = scatter(h.(nm)(q).ax{j}, x(1,:), y(1,:), mkrsz, z(1,:), 'filled');
            else
                h.(nm)(q).pl{j} = scatter3(h.(nm)(q).ax{j}, x(1,:), y(1,:), x(1,:), mkrsz, z(1,:), 'filled');
            end

            h.(nm)(q).ax{j}.XAxis.TickValues = [];
            h.(nm)(q).ax{j}.YAxis.TickValues = [];
            h.(nm)(q).ax{j}.XAxis.TickLabels = {};
            h.(nm)(q).ax{j}.YAxis.TickLabels = {};

            h.(nm)(q).ax{j}.Box = 'off';
            % if ylim_constancy
            %     % h.(nm)(q).ax{j}.XLim = [0 1];
            %     % h.(nm)(q).ax{j}.YLim = [0 1];
            % end
            % h.(nm)(q).pl{j}.MarkerFaceColor = 'k';

            h.(nm)(q).ln{j} = [];

            hold(h.(nm)(q).ax{j}, 'off')


        case 'polar'


            h.(nm)(q).ax{j} = polaraxes( 'Parent', h.fg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition' );

            if colmaj
                h.(nm)(q).ax{j}.InnerPosition(1) = ax(idxsect).colmaj.x(idxsubp(j));
                h.(nm)(q).ax{j}.InnerPosition(2) = ax(idxsect).colmaj.y(idxsubp(j));
            else
                h.(nm)(q).ax{j}.InnerPosition(1) = ax(idxsect).x(idxsubp(j));
                h.(nm)(q).ax{j}.InnerPosition(2) = ax(idxsect).y(idxsubp(j));
            end
            h.(nm)(q).ax{j}.InnerPosition(3) = newextent;
            h.(nm)(q).ax{j}.InnerPosition(4) = newextent;


            h.(nm)(q).ax{j}.Toolbar.Visible = 'off';

            hold(h.(nm)(q).ax{j}, 'on')
            h.(nm)(q).pl{j} = polarscatter(h.(nm)(q).ax{j}, dummyvec, dummyvec, mkrsz, 'filled');
            h.(nm)(q).ln{j} = polarplot(h.(nm)(q).ax{j}, [blindspot blindspot], [0 0], 'r');

            % h.(nm)(q).pl{j}.MarkerFaceColor = 'k';
            h.(nm)(q).ln{j}.LineStyle = 'none';

            h.(nm)(q).ax{j}.RTickLabel = [];

            h.(nm)(q).ax{j}.ThetaTick = [0 90 180 270];
            h.(nm)(q).ax{j}.ThetaTickLabel = {'0', '90', '180', '270'};

            h.(nm)(q).ax{j}.ThetaAxis.Label.Units = 'normalized';
            h.(nm)(q).ax{j}.ThetaAxis.Label.Position = [0.5, -0.05, 0];
            h.(nm)(q).ax{j}.ThetaAxis.Label.Rotation = 0;
            h.(nm)(q).ax{j}.RAxis.Label.Units = 'normalized';
            h.(nm)(q).ax{j}.RAxis.Label.Position = [-0.13, 0.5, 0];
            h.(nm)(q).ax{j}.RAxis.Label.Rotation = 90;

            % if ylim_constancy
            %     h.(nm)(q).ax{j}.RLim = [0 1];
            % end

            hold(h.(nm)(q).ax{j}, 'off')



    end

    h.(nm)(q).pl{j}.CData = repmat([0 0 0], numsamp, 1);
    h.(nm)(q).pl{j}.MarkerFaceAlpha = 0.3;



    if do_bar

        %%INSET BAR PLOT FOR LAG CC%%

        if isempty(numlags) || isempty(actual_lags_xy_sec)
            error("if do_bar is true, numlags and actual_lags_xy_sec cannot be empty")
        end
        dummyvec_lag = nan(numlags, 1);

        inset_widfac = 0.1;
        inset_htfac = 0.1;

        h.(nm)(q).br{j}.ax = axes( 'Parent', h.fg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition');
        h.(nm)(q).br{j}.ax.InnerPosition(1) = h.(nm)(q).ax{j}.InnerPosition(1)+0.05;
        h.(nm)(q).br{j}.ax.InnerPosition(2) = h.(nm)(q).ax{j}.InnerPosition(2)+0.05;
        h.(nm)(q).br{j}.ax.InnerPosition(3) = h.(nm)(q).ax{j}.InnerPosition(3)-h.(nm)(q).ax{j}.InnerPosition(3)*inset_widfac;
        h.(nm)(q).br{j}.ax.InnerPosition(4) = h.(nm)(q).ax{j}.InnerPosition(4)-h.(nm)(q).ax{j}.InnerPosition(4)*inset_htfac;

        hold(h.(nm)(q).br{j}.ax, 'on')

        h.(nm)(q).br{j}.h.(nm)(q).pl = bar(h.(nm)(q).br{j}.ax, dummyvec_lag, dummyvec_lag);
        h.(nm)(q).br{j}.h.(nm)(q).ln = xline(h.(nm)(q).br{j}.ax, nan, 'k');

        h.(nm)(q).br{j}.ax.YLim = [-1 1];
        h.(nm)(q).br{j}.ax.Box = 'off';
        h.(nm)(q).br{j}.ax.Title.String = 'LAG';
        h.(nm)(q).br{j}.ax.XLim = [min(actual_lags_xy_sec) - range(actual_lags_xy_sec)*bar_axisroomfac, max(actual_lags_xy_sec) + range(actual_lags_xy_sec)*bar_axisroomfac];
        h.(nm)(q).br{j}.ax.XTick = [min(actual_lags_xy_sec), 0, max(actual_lags_xy_sec)];
        h.(nm)(q).br{j}.ax.XTickLabels = {sprintf('%.2g', min(actual_lags_xy_sec)), 0, sprintf('%.2g', max(actual_lags_xy_sec))};
        h.(nm)(q).br{j}.ax.Title.String = 'LAGS';
        h.(nm)(q).br{j}.ax.YLabel.String = 'CORR COEFF';

        hold(h.(nm)(q).br{j}.ax, 'off')

    end


end

end

