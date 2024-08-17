function [plotx, ploty, plotz, r_dummy1, r_dummy2, cmp, ccr, pval_norm, laginds_to_plot] = pltexp_scat_prepvars(numlags, lagsall_xy, lagsall_z, varx, vary, varz, threshold_data, laball, vpmapflat_axid_use, plot_z_as_color, polar_index, numsamp_max, zero_lag_index, lags_to_plot, pval_siglev)


if isempty(vpmapflat_axid_use(3))
    z_is_empty = 1;
else
    z_is_empty = 0;
end

plotx = cell(1, numlags);
ploty = cell(1, numlags);
plotz = cell(1, numlags);
r_dummy1 = cell(1, numlags);
r_dummy2 = cell(1, numlags);
cmp = cell(1, numlags);
ccr = zeros(1, numlags);
ccpv = zeros(1, numlags);

for lagind = 1:numlags

    [varx_lagxyz, vary_lagxyz, varz_lagxyz] = lagvars(varx, vary, varz, lagsall_xy(lagind), lagsall_z(lagind));

    [plotx{lagind}, ploty{lagind}, plotz{lagind}] = remove_nans_as_group(varx_lagxyz, vary_lagxyz, varz_lagxyz);

    if ismember(1, polar_index)
        plotx{lagind} = insert_nan_for_polar_wrap(plotx{lagind});
    end
    if ismember(2, polar_index)
        ploty{lagind} = insert_nan_for_polar_wrap(plotx{lagind});
    end
    if ismember(3, polar_index)
        plotz{lagind} = insert_nan_for_polar_wrap(plotx{lagind});
    end

    %threshold if requested
    if threshold_data
        if contains(laball{1}, 'vel')
            [histdt, histx] = hist(abs(plotx{lagind}(:)), 500);
            thrbin = triangle_threshold(histdt, 'R', 0);
            thrvel = histx(thrbin);
            excludeinds = abs(plotx{lagind})<thrvel;
        elseif contains(laball{2}, 'vel')
            [histdt, histx] = hist(abs(ploty{lagind}(:)), 500);
            thrbin = triangle_threshold(histdt, 'R', 0);
            thrvel = histx(thrbin);
            excludeinds = abs(ploty{lagind})<thrvel;
        end
        plotx{lagind}(excludeinds) = [];
        ploty{lagind}(excludeinds) = [];
        plotz{lagind}(excludeinds) = [];
    end


    %sort for color plot (if plot_z_as_color)
    if z_is_empty | (~z_is_empty & ~plot_z_as_color)
        cmp{lagind} = [0 0 1];
    elseif ~z_is_empty & plot_z_as_color
        [~, idx4] = sort(plotz{lagind});
        plotx{lagind} = plotx{lagind}(idx4);
        ploty{lagind} = ploty{lagind}(idx4);
        cmp{lagind} = jet(numel(idx4));
    end


    %dummy variables for possible double polar plot (ie two polar vars)
    rdummy1_lbnd = 0.1; %for double polar plots
    rdummy1_ubnd = 0.45;%for double polar plots
    rdummy2_lbnd = 0.5;%for double polar plots
    rdummy2_ubnd = 0.85;%for double polar plots
    r_dummy1{lagind} = rdummy1_lbnd + (rdummy1_ubnd-rdummy1_lbnd)*rand(size(plotx{lagind}));
    r_dummy2{lagind} = rdummy2_lbnd + (rdummy2_ubnd-rdummy2_lbnd)*rand(size(ploty{lagind}));

    %find corr coeffs
    switch num2str(polar_index)
        case ''
            [ccr(lagind) ccpv(lagind)] = corr(plotx{lagind}, ploty{lagind}); %linear-linear
            % [ccr(lagind) ccpv(lagind)] = corr(plotz{lagind}, ploty{lagind}); %linear-linear
        case '1'
            [ccr(lagind) ccpv(lagind)] = circ_corrcl(plotx{lagind}, ploty{lagind}); %circ-linear
        case '2'
            [ccr(lagind) ccpv(lagind)] = circ_corrcl(ploty{lagind}, plotx{lagind}); %circ-linear (and switch input order)
        case '1  2'
            [ccr(lagind) ccpv(lagind)] = circ_corrcc(plotx{lagind}, ploty{lagind}); %circ-circ
    end

    [plotx{lagind}, ploty{lagind}, plotz{lagind}, r_dummy1{lagind}, r_dummy2{lagind}] = nanpadvec(numsamp_max, plotx{lagind}, ploty{lagind}, plotz{lagind}, r_dummy1{lagind}, r_dummy2{lagind});

end

pval_norm = pval_siglev-ccpv;
pval_norm(pval_norm<0) = 0;
if ~any(pval_norm)
    pval_norm = 1;
else
    rngpvalnorm = max(pval_norm)-min(pval_norm);
    if rngpvalnorm==0
        pval_norm = 0;
    else
        bar_contrast = 0.3; %to make difference between non-significant (white) and barely significant (0.05) clear in blue saturation 
        pval_norm = 1 - (pval_norm - min(pval_norm)) / rngpvalnorm + bar_contrast;
    end
end

switch lags_to_plot
    case 'zero'
        laginds_to_plot = zero_lag_index;
    case 'best'
        [~, laginds_to_plot] = max(abs(ccr));
    case 'zeroandbest'
        [~, ccrmaxabs] = max(abs(ccr));
        laginds_to_plot = [zero_lag_index ccrmaxabs];
    case 'all'
        laginds_to_plot = 1:numlags;
end


end

