function fitin = fitmdl_exclude_samples(excludeopts, fitin)

if strcmp(excludeopts, 'indv_triangle') %triangle threshold on indv
    [histdt, histx] = hist(abs(fitin.vars.indvpre(:)), round(numel(fitin.vars.indvpre)/10));
    thrbin = triangle_threshold(histdt, 'R', 0);
    thrvel = histx(thrbin);
    sampinds_exclude = abs(fitin.vars.indvpre)<thrvel;
    fitin.vars.indvpre(sampinds_exclude) = nan;
end