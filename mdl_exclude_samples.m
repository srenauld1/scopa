function mdl = mdl_exclude_samples(rm, mdl)

if strcmp(rm, 'indv_triangle') %triangle threshold on indv
    [histdt, histx] = hist(abs(indvp(:)), round(numel(indvp)/10));
    thrbin = triangle_threshold(histdt, 'R', 0);
    thrvel = histx(thrbin);
    sampinds_exclude = abs(indvp)<thrvel;
    indvp(sampinds_exclude) = nan;
end