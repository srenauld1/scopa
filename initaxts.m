function hgroup = initaxts(hfg, ax, ts, opt)

%init axis for timeseries plotting; can have multiple timeseries and right and left axes

arguments
    hfg
    ax struct
    ts
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
    opt.doui = []
    opt.varaxside = [] %length n vector of axis side indices for n timeseries; n=size(ts,1); axis side index is 1 for left, 2 for right, and 0 to skip plotting
    opt.notb = 0
end
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


if isempty(labs)
    labs = repelem({''}, size(ts,1));
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

dummyvec = nan(nsamp, 1);

[ts_per_side, side_index] = hist(varaxside(varaxside~=0),unique(varaxside(varaxside~=0)));
numaxids = numel(ts_per_side);

hax = [];
hpl = [];
hlnx = [];

for j = 1:numsubplot

    hax{j} = axes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition');

    if colmaj
        hax{j}.InnerPosition(1) = ax(sector_ind).colmaj.x(subplot_ind(j));
        hax{j}.InnerPosition(2) = ax(sector_ind).colmaj.y(subplot_ind(j));
    else
        hax{j}.InnerPosition(1) = ax(sector_ind).x(subplot_ind(j));
        hax{j}.InnerPosition(2) = ax(sector_ind).y(subplot_ind(j));
    end
    hax{j}.InnerPosition(3) = ax(sector_ind).w(widfac(j));
    hax{j}.InnerPosition(4) = ax(sector_ind).h(htfac(j));

    if notb
        hax{j}.Toolbar.Visible = 'off';
    end

    hold(hax{j}, 'on')

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
                hpl{j}{fi}{cnt(fi)}{c} = plot(hax{j}, t, ts(k,:,c));
                hpl{j}{fi}{cnt(fi)}{c}.Color = [cols(k,:) 1]; %append 4th element for transparency; this works even though it will not appear in the color property when you check it
                if c==1
                    hpl{j}{fi}{cnt(fi)}{c}.LineStyle = '-';
                else
                    hpl{j}{fi}{cnt(fi)}{c}.LineStyle = ':';
                end
            end

            if j==1
                hax{j}.YAxis(fi).Label.String{cnt(fi)} = sprintf('\\color[rgb]{%f, %f, %f}%s', cols(k,:), [num2str(k) '. ' labs{k}]);
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

        hax{j}.YAxis(fi).Color = [0 0 0];
        hax{j}.YAxis(fi).FontSize = fontsmall;
        hax{j}.YAxis(fi).FontWeight = 'bold';

        if dors
            hax{j}.YAxis(fi).Limits = lim{k}.rspad(:,:,1);
            hax{j}.YAxis(fi).TickValues = lim{k}.rs(:,:,1);
        else
            error("dors is currently required")
        end

        if j==1
            hax{j}.YAxis(fi).TickLabels = strtrim(sprintf(formspec{fi}, ticktmp{fi}{:}));
        end

        if j==1

            if doui
                hax{j}.ButtonDownFcn = @(src,evnt)ui_t_click_fcn(src,evnt);
                hax{j}.PickableParts = 'visible';
                hax{j}.HitTest = 'on';
            end

            hax{j}.XTick = round(linspace(0, max(t), numxtick));
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

        hax{j}.Box = 'off';
        % hax{j}.Color = 'k'; %axis background color
        % hax{j}.XLabel.String = '';

        hlnx{j} = line(hax{j}, [nan nan], hax{j}.YAxis(1).Limits, 'color', 'k', 'LineStyle','-');

        hold(hax{j}, 'off')
    
    end

end


hgroup.hax = hax;
hgroup.hpl = hpl;
hgroup.hlnx = hlnx;


end





