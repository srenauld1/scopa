function hgroup = init_axes_timeseries(hfg, ax, letui, numsamp, vpmapflat_axid, ti, lims, ticklab, labs, cols, sector_ind, subplot_ind, widfac, htfac, rescale_timeseries, fontsz, axorder)

arguments
    hfg
    ax struct
    letui
    numsamp
    vpmapflat_axid
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

numchan = max(cell2mat(cellfun(@(x) size(x,3), ticklab, 'UniformOutput', false)));
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

[axidcnts, axids] = hist(vpmapflat_axid(vpmapflat_axid~=0),unique(vpmapflat_axid(vpmapflat_axid~=0)));
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
    for k = 1:numel(vpmapflat_axid) %loop over all variables, placing them in their assigned plot position (k), which includes specification of their axis side (vpmapflat_axid(k))
        if vpmapflat_axid(k) %skip empty variables

            fi = vpmapflat_axid(k); %axis side index
            if fi==1
                yyaxis left
            elseif fi==2
                yyaxis right
            end

            cnt(fi) = cnt(fi)+1; %count of nonempty variables for each axis side index

            for c = 1:numchan
                hpl{j}{fi}{cnt(fi)}{c} = plot(hax{j}, ti, dummyvec);
                hpl{j}{fi}{cnt(fi)}{c}.Color = [cols(k,:) 1]; %append 4th element for transparency; this works even though it will not appear in the color property when you check it
                if c==1
                    hpl{j}{fi}{cnt(fi)}{c}.LineStyle = '-';
                else
                    hpl{j}{fi}{cnt(fi)}{c}.LineStyle = '--';
                end
            end

            if j==1
                hax{j}.YAxis(fi).Label.String{cnt(fi)} = sprintf('\\color[rgb]{%f, %f, %f}%s', cols(k,:), [num2str(k) '. ' labs{k}]);
            end

            if cnt(fi)<axidcnts(axids==fi)
                formspec{vpmapflat_axid(k)} = [formspec{vpmapflat_axid(k)} '%s\\newline'];
            else
                formspec{vpmapflat_axid(k)} = [formspec{vpmapflat_axid(k)} '%s\n'];
            end

            for tti = 1:size(ticklab{k},2)
                ticktmp{vpmapflat_axid(k)}{cnt(fi),tti} = sprintf('\\color[rgb]{%f, %f, %f}%s', cols(k,:), regexprep(num2str(ticklab{k}(1,tti,:), 4), ' +', '/')); %in case there's two channels, replace spaces from num2str with slash
            end

        end
    end

    for fi = 1:numaxids

        hax{j}.YAxis(fi).Color = [0 0 0];
        hax{j}.YAxis(fi).FontSize = fontsmall;
        hax{j}.YAxis(fi).FontWeight = 'bold';

        if rescale_timeseries
            hax{j}.YAxis(fi).Limits = lims{k}.rescale_xtra(:,:,1);
            hax{j}.YAxis(fi).TickValues = lims{k}.rescale(:,:,1);
        else
            error("rescale_timeseries is currently required")
        end

        if j==1
            hax{j}.YAxis(fi).TickLabels = strtrim(sprintf(formspec{fi}, ticktmp{fi}{:}));
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





