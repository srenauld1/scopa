function plot_fit_history(histxtmp, pth_prefix, epochinds_str_all)



hfg = figure;
hax = axes('Parent', hfg);
title_add_each = 'HISTXES';
figext = '.gif';
filename_save = [pth_prefix '_' title_add_each '_e_' epochinds_str_all '_' figext];

for hxti = 1:size(histxtmp, 1)
    if hxti==1
        hpl = plot(hax, histxtmp(hxti,:));
    else
        hpl.YData = histxtmp(hxti,:);
    end

    fig2gif(hfg, hxti, filename_save)

end

close(hfg)

