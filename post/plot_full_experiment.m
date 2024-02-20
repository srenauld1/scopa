function plot_full_experiment(cue, mu, intHD, ...
    amp_PB_standin, dff_ga_hf, dff_no_hf, tb, splits2, openinds, ...
    closedinds, alp, stradd, pth_save, offset, rho)

dopbamp = 1;
pth_save = strrep(pth_save, '*', 'S');
axis_shift_fac1 = [1 0]; %how close (proportion of y range) the ylim is to y min and max, respectively
axis_shift_fac2 = [0 1]; %how close (proportion of y range) the ylim is to y min and max, respectively

titleadd = strrep(stradd, '_', '-');

figure;
subplot(2,1,1)
scatter(amp_PB_standin(openinds), dff_ga_hf(openinds), '.')
title([titleadd ' vs gall dff (open loop)'])

subplot(2,1,2)
scatter(amp_PB_standin(closedinds), dff_ga_hf(closedinds), '.')
title([titleadd ' vs gall dff (closed loop)'])

saveas( gcf, [pth_save(1:end-4) 'scatter_' stradd '.png'])


figure;
subplot(2,1,1)
scatter(diff(mu(openinds)), dff_ga_hf(openinds(1:end-1)), '.')
title([titleadd ' vs gall dff (open loop)'])

subplot(2,1,2)
scatter(diff(mu(closedinds)), dff_ga_hf(closedinds(1:end-1)), '.')
title([titleadd ' vs gall dff (closed loop)'])

saveas( gcf, [pth_save(1:end-4) 'scatter_bumpspeed.png'])

figure;
hold on
plot(tb,unwrap(cue),'k','linewidth',2)
plot(tb, -unwrap(mu),'b','linewidth',2)
plot(tb, -unwrap(intHD),'r','linewidth',2)

if exist('offset', 'var')

    %     offset = unwrap(offset);
    %     rho_idx = rho>0.1;
    %     a = plot(xf(rho_idx),offset(rho_idx),'k','linewidth',0.5);
    %     try
    %         a.YData(abs(diff(a.YData))>pi) = nan; %get rid of lines that connect top and bottom
    %     catch
    %         "DIDNT' WORK"
    %     end

end

ylabel('accumulated rotation', 'FontSize', 20)
%set(gca,'ytick',[])
%set(gca,'yticklabel',[])
ax1 = gca;
yl = ax1.YLim;
ylimrange = range(yl);
ylim([yl(1)-(ylimrange*axis_shift_fac1(1)) yl(2)+(ylimrange*axis_shift_fac1(2))])

line(xlim(), [0,0], 'LineWidth', 1, 'Color', 'k');

yyaxis right


if exist('offset', 'var')

    offset = unwrap(offset);
    rho_idx = rho>0;
    a = plot(tb(rho_idx),offset(rho_idx),'k','linewidth',0.5);
    try
       a.YData(abs(diff(a.YData))>pi) = nan; %get rid of lines that connect top and bottom
    catch
        "DIDNT' WORK"
    end

else

if dopbamp
    plot(tb, amp_PB_standin,'magenta','linewidth',0.05, 'LineStyle','-');
end
    plot(tb, dff_ga_hf,'color',[0.4660 0.6740 0.1880],'linewidth',0.05, 'LineStyle','-');
    plot(tb, dff_no_hf,'color',[1 0.5 0], 'linewidth',0.05, 'LineStyle','-');


end

ax1 = gca;
yl = ax1.YLim;
ylimrange = range(yl);
ylim([yl(1)-(ylimrange*axis_shift_fac2(1)) yl(2)+(ylimrange*axis_shift_fac2(2))])
ylabel('df/F', 'FontSize',20, 'Color','k')
%set(gca,'ytick',[])
%set(gca,'yticklabel',[])

xlabel('seconds', 'FontSize',20, 'Color','k')
line(xlim(), [0,0], 'LineWidth', 1, 'Color', 'k');

if dopbamp
    title({[titleadd ' : bar in open loop (shading) or closed loop (no shading)']; '\color{black}CUE, \color{blue}BUMP, \color{red}BALL';'\color{magenta}PB, \color[rgb]{0.4660 0.6740 0.1880}GA, \color[rgb]{1 0.5 0}NO' }, 'FontSize',15)
else
    title({[titleadd ' : bar in open loop (shading) or closed loop (no shading)']; '\color{black}CUE, \color{blue}BUMP, \color{red}BALL';', \color[rgb]{0.4660 0.6740 0.1880}GA, \color[rgb]{1 0.5 0}NO' }, 'FontSize',15)
end

hold on
for si = 1:size(splits2,1)
    xbars = [splits2(si,1) splits2(si,2)];
    patch([xbars(1) xbars(1), xbars(2) xbars(2)], [min(ylim) max(ylim) max(ylim) min(ylim)], alp, 'FaceAlpha', 0.2)
end
xline(closedinds(end))
hold off

saveas( gcf, [pth_save(1:end-4) 'timecourses_' stradd '.png'])
