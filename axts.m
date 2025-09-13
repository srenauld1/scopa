function h = axts(ts, opt)

%initialize axis for timeseries plotting; can have multiple timeseries and right and left axes

arguments
    ts
    opt.h = []
    opt.ax = []
    opt.labs = []
    opt.cols = []
    opt.sector_ind = 1
    opt.subplot_ind = 1
    opt.widfac = 1
    opt.htfac = 1
    opt.dors = 1
    opt.fontsz = [6 8 12]
    opt.colmaj = 0
    opt.ticklab = [];
    opt.lim = []
    opt.t = []
    opt.doui = 0
    opt.varaxside = [] %length n vector of axis side indices for n timeseries; n=size(ts,1); axis side index is 1 for left, 2 for right, and 0 to skip plotting
    opt.notb = 0
    opt.nm = 'ts'
end
h = opt.h;
ax = opt.ax;
labs = opt.labs;
cols = opt.cols;
sector_ind = opt.sector_ind;
subplot_ind = opt.subplot_ind;
widfac = opt.widfac;
htfac = opt.htfac;
dors = opt.dors;
fontsz = opt.fontsz;
colmaj = opt.colmaj;
ticklab = opt.ticklab;
lim = opt.lim;
t = opt.t;
doui = opt.doui;
varaxside = opt.varaxside;
notb = opt.notb;
nm = opt.nm;

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
if isempty(labs)
    labs = repelem({''}, size(ts,1));
end
if isvector(ts) && iscolumn(ts)
    ts = ts(:)'; %make sure time is 2nd dim, since time is often what we're plotting and scopa convention makes time 2nd dim
end
if isempty(t)
    t = 1:size(ts,2);
end
if isempty(ticklab)
    ticklabtmp = axlim(ts, limtype='each', roomfac=0.15);
    ticklab = cell(size(ticklabtmp,1),1);
    for k = 1:size(ticklabtmp,1)
        ticklab{k} = ticklabtmp(k,:);
    end
end
if isempty(lim)
    lim = axlim(ts, limtype=[], roomfac=0.15);
    ts = rescale2(ts, lim.each, lim.rs, 0);
    lim = repelem({lim}, size(ts,1));
end
if isempty(cols)
    cols = brewermap(size(ts,1),'Dark2'); %distinguishable_colors(numel(fieldnames(vars)));
end
if isempty(varaxside)
    varaxside = ones(size(ts,1),1);
end

nsamp = size(ts,2);
numchan = max(cell2mat(cellfun(@(x) size(x,3), ticklab, 'UniformOutput', false)));
numxtick = 20;

numsubplot = numel(subplot_ind);
if isscalar(widfac) && numsubplot>1
    widfac = repelem(widfac, numsubplot);
end
if isscalar(htfac) && numsubplot>1
    htfac = repelem(htfac, numsubplot);
end
fontsmall = fontsz(1);
fontmedium = fontsz(2);

dummyvec = nan(1,nsamp);

[ts_per_side, side_index] = hist(varaxside(varaxside~=0),unique(varaxside(varaxside~=0)));
numaxids = numel(ts_per_side);

h.(nm)(q).ax = [];
h.(nm)(q).pl = [];
h.(nm)(q).lnx = [];

for j = 1:numsubplot

    h.(nm)(q).ax{j} = axes( 'Parent', h.fg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition');

    if colmaj
        h.(nm)(q).ax{j}.InnerPosition(1) = ax(sector_ind).colmaj.x(subplot_ind(j));
        h.(nm)(q).ax{j}.InnerPosition(2) = ax(sector_ind).colmaj.y(subplot_ind(j));
    else
        h.(nm)(q).ax{j}.InnerPosition(1) = ax(sector_ind).x(subplot_ind(j));
        h.(nm)(q).ax{j}.InnerPosition(2) = ax(sector_ind).y(subplot_ind(j));
    end
    h.(nm)(q).ax{j}.InnerPosition(3) = ax(sector_ind).w(widfac(j));
    h.(nm)(q).ax{j}.InnerPosition(4) = ax(sector_ind).h(htfac(j));

    if notb
        h.(nm)(q).ax{j}.Toolbar.Visible = 'off';
    end

    hold(h.(nm)(q).ax{j}, 'on')

    ticktmp = cell(numaxids,1);
    formspec = cell(numaxids,1);
    cnt = zeros(numaxids,1);
    for k = 1:numel(varaxside) %loop over all variables, placing them in their assigned plot position (k), which includes specification of their axis side (varaxside(k))
        if varaxside(k) %skip empty variables

            fi = varaxside(k); %axis side index
            if fi==1
                yyaxis left
            elseif fi==2
                yyaxis right
            end

            cnt(fi) = cnt(fi)+1; %count of nonempty variables for each axis side index

            for c = 1:numchan
                h.(nm)(q).pl{j}{fi}{cnt(fi)}{c} = plot(h.(nm)(q).ax{j}, t, ts(k,:,c));
                h.(nm)(q).pl{j}{fi}{cnt(fi)}{c}.Color = [cols(k,:) 1]; %append 4th element for transparency; this works even though it will not appear in the color property when you check it
                if c==1
                    h.(nm)(q).pl{j}{fi}{cnt(fi)}{c}.LineStyle = '-';
                else
                    h.(nm)(q).pl{j}{fi}{cnt(fi)}{c}.LineStyle = ':';
                end
            end

            if j==1
                h.(nm)(q).ax{j}.YAxis(fi).Label.String{cnt(fi)} = sprintf('\\color[rgb]{%f, %f, %f}%s', cols(k,:), [num2str(k) '. ' labs{k}]);
            end

            if cnt(fi)<ts_per_side(side_index==fi)
                formspec{varaxside(k)} = [formspec{varaxside(k)} '%s\\newline'];
            else
                formspec{varaxside(k)} = [formspec{varaxside(k)} '%s\n'];
            end

            for tti = 1:size(ticklab{k},2)
                ticktmp{varaxside(k)}{cnt(fi),tti} = sprintf('\\color[rgb]{%f, %f, %f}%s', cols(k,:), regexprep(num2str(ticklab{k}(1,tti,:), 4), ' +', '/')); %in case there's two channels, replace spaces from num2str with slash
            end

        end
    end

    for fi = 1:numaxids

        h.(nm)(q).ax{j}.YAxis(fi).Color = [0 0 0];
        h.(nm)(q).ax{j}.YAxis(fi).FontSize = fontsmall;
        h.(nm)(q).ax{j}.YAxis(fi).FontWeight = 'bold';

        if dors
            h.(nm)(q).ax{j}.YAxis(fi).Limits = lim{k}.rspad(:,:,1);
            h.(nm)(q).ax{j}.YAxis(fi).TickValues = lim{k}.rs(:,:,1);
        else
            error("dors is currently required")
        end

        if j==1
            h.(nm)(q).ax{j}.YAxis(fi).TickLabels = strtrim(sprintf(formspec{fi}, ticktmp{fi}{:}));
        end

        if j==1

            if doui
                h.(nm)(q).ax{j}.ButtonDownFcn = @(src,event)cb_click(src,event);
                h.(nm)(q).ax{j}.PickableParts = 'visible';
                h.(nm)(q).ax{j}.HitTest = 'on';
            end

            h.(nm)(q).ax{j}.XTick = round(linspace(0, max(t), numxtick));
            for tlx = 1:numel(h.(nm)(q).ax{j}.XTick)
                if tlx==numel(h.(nm)(q).ax{j}.XTick)
                    h.(nm)(q).ax{j}.XTickLabel{tlx} = [num2str(h.(nm)(q).ax{j}.XTick(tlx)) ' sec'];
                else
                    h.(nm)(q).ax{j}.XTickLabel{tlx} = [num2str(h.(nm)(q).ax{j}.XTick(tlx))];
                end
            end
        
        end

        h.(nm)(q).ax{j}.XAxis.FontSize = fontmedium;
        h.(nm)(q).ax{j}.XAxis.TickLength(1) = 0.005;

        h.(nm)(q).ax{j}.Box = 'off';
        % h.(nm)(q).ax{j}.Color = 'k'; %axis background color
        % h.(nm)(q).ax{j}.XLabel.String = '';

        h.(nm)(q).lnx{j} = line(h.(nm)(q).ax{j}, [nan nan], h.(nm)(q).ax{j}.YAxis(1).Limits, 'color', 'k', 'LineStyle','-');

        hold(h.(nm)(q).ax{j}, 'off')
    
    end

end



end





