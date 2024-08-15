function hgroup = init_axes_timeseries(hfg, ax, letui, numsamp, vpmapflatids, ti, lims, ticklab, labs, cols, sector_ind, subplot_ind, widfac, htfac, rescale_timeseries, fontsz, axorder)

arguments
    hfg
    ax struct
    letui
    numsamp
    vpmapflatids
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

[axidcnts, axids] = hist(cell2mat(vpmapflatids),unique(cell2mat(vpmapflatids)));
numaxids = numel(axidcnts);

hax = [];
hpl = [];
hlnx = [];

for j = 1:numsubplot

    hax{j} = axes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition');

    hax{j}.InnerPosition(1) = ax(sector_ind).(axorder).xp(subplot_ind(j));
    hax{j}.InnerPosition(2) = ax(sector_ind).(axorder).yp(subplot_ind(j));
    hax{j}.InnerPosition(3) = ax(sector_ind).xe(widfac(j));
    hax{j}.InnerPosition(4) = ax(sector_ind).ye(htfac(j));

    hax{j}.Toolbar.Visible = 'off';

    hold(hax{j}, 'on')

    ticktmp = cell(numaxids,1);
    formspec = cell(numaxids,1);
    cnt = zeros(numaxids,1);
    for k = 1:numel(vpmapflatids) %loop over all variables, placing them in their assigned plot position (k), which includes specification of their axis side (vpmapflatids{k})
        if ~isempty(vpmapflatids{k}) %skip empty variables

            fi = vpmapflatids{k}; %axis side index
            if fi==1
                yyaxis left
            elseif fi==2
                yyaxis right
            end

            cnt(fi) = cnt(fi)+1; %count of nonempty variables for each axis side index

            hpl{j}{fi}{cnt(fi)} = plot(hax{j}, ti, dummyvec);
            hpl{j}{fi}{cnt(fi)}.Color = cols(k,:);
            hpl{j}{fi}{cnt(fi)}.LineStyle = '-';

            hax{j}.YAxis(fi).Label.String{cnt(fi)} = sprintf('\\color[rgb]{%f, %f, %f}%s', cols(k,:), [num2str(k) '. ' labs{k}]);

            if cnt(fi)<axidcnts(axids==fi)
                formspec{vpmapflatids{k}} = [formspec{vpmapflatids{k}} '%s\\newline'];
            else
                formspec{vpmapflatids{k}} = [formspec{vpmapflatids{k}} '%s\n'];
            end

            for tti = 1:numel(ticklab{k})
                ticktmp{vpmapflatids{k}}{cnt(fi),tti} = sprintf('\\color[rgb]{%f, %f, %f}%s', cols(k,:), num2str(ticklab{k}(tti), 4));
            end

        end
    end

    for fi = 1:numaxids

        hax{j}.YAxis(fi).Color = [0 0 0];
        hax{j}.YAxis(fi).FontSize = fontsmall;
        hax{j}.YAxis(fi).FontWeight = 'bold';

        if rescale_timeseries
            hax{j}.YAxis(fi).Limits = lims{k}.rescale_xtra;
            hax{j}.YAxis(fi).TickValues = lims{k}.rescale;
        else
            error("rescale_timeseries is currently required")
        end

        hax{j}.YAxis(fi).TickLabels = strtrim(sprintf(formspec{fi}, ticktmp{fi}{:}));


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





