function mdl = mdl_exclude_samples(rm, mdl)

if strcmp(rm, 'indv_triangle') %triangle threshold on indv
    [histdt, histx] = hist(abs(mdl.vars.indvp(:)), round(numel(mdl.vars.indvp)/10));
    thrbin = triangle_threshold(histdt, 'R', 0);
    thrvel = histx(thrbin);
    sampinds_exclude = abs(mdl.vars.indvp)<thrvel;
    mdl.vars.indvp(sampinds_exclude) = nan;
end