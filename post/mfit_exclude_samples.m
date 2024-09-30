function fitin = mfit_exclude_samples(excludeopts, fitin)

if strcmp(excludeopts, 'indv_triangle') %triangle threshold on indv
    [histdt, histx] = hist(abs(fitin.vars.indvp(:)), round(numel(fitin.vars.indvp)/10));
    thrbin = triangle_threshold(histdt, 'R', 0);
    thrvel = histx(thrbin);
    sampinds_exclude = abs(fitin.vars.indvp)<thrvel;
    fitin.vars.indvp(sampinds_exclude) = nan;
end