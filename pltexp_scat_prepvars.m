function [init_scatter, scatter_type, varsp_sc, labsp_sc, cols_sc, rdummies, cmp_sc_sc, ccr, pval_norm, laginds_to_plot] = ...
    pltexp_scat_prepvars(scinds, numlags, lagsall_xy, lagsall_z, vars, labs, cols, threshold_data, ...
    varaxside_use, plot_z_as_color, polarinds, numsamp_max, zero_lag_index, ...
    lags_to_plot, pval_siglev, bar_contrast)

persistent polarinds_prev

try
    varaxside_use(scinds);
catch ME
    sprintf("scinds requests a nonempty plot index that does not exist, even after removing scinds(3)")
    error(ME.message)
end

nonempty_plotinds = find(varaxside_use(scinds));
if numel(scinds)~=numel(nonempty_plotinds)
    sprintf("SCINDS REQUESTED 3D BUT SCATTERPLOT WILL BE 2D BECAUSE ONE SCIND IS EMPTY")
end
scinds = scinds(nonempty_plotinds);

if numel(nonempty_plotinds)<2
    init_scatter = 0;
    varsp_sc = [];
    rdummies = [];
    cmp_sc_sc = [];
    ccr = [];
    pval_norm = [];
    laginds_to_plot = [];
    scatter_type = [];
    sprintf("SKIPPING BAR PLOT BECAUSE X AND/OR Y IS EMPTY")
    return;
elseif numel(nonempty_plotinds)==2 %update some vars if z turns out to be empty, or if reqauested 2d scatterplot
    z_is_empty = 1;
    lagsall_xy = unique(lagsall_xy, 'stable');
    lagsall_z = zeros(size(lagsall_xy));
    numlags = numel(lagsall_xy);
elseif numel(nonempty_plotinds)>=3 && numel(scinds)==3
    z_is_empty = 0;
end


polarinds = polarinds(scinds);

if any(polarinds)
    scatter_type = 'polar';
else
    scatter_type = 'cartesian';
end

if ~isequal(polarinds, polarinds_prev)
    init_scatter = 1;
else
    init_scatter = 0;
end
polarinds_prev = polarinds;

vars = vars(scinds, :, :);
labsp_sc = labs(scinds);
cols_sc = cols(scinds,:);
numvars = size(vars,1);

varsp_sc = zeros(numvars, numlags, numsamp_max);
rdummies = zeros(numvars, numlags, numsamp_max);
cmp_sc_sc = cell(1, numlags);
ccr = zeros(1, numlags);
ccpv = zeros(1, numlags);


for lagind = 1:numlags
    [varsp_sc(:,lagind,:), rdummies(:,lagind,:), cmp_sc_sc{lagind}, ccr(lagind), ccpv(lagind)] = prepvars_onelag(vars, lagsall_xy(lagind), lagsall_z(lagind), polarinds, threshold_data, z_is_empty, plot_z_as_color, numsamp_max);
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



function [varsp_sc, rdummies, cmp_sc, ccr, ccpv] = prepvars_onelag(vars, lagxy, lagz, polarinds, threshold_data, z_is_empty, plot_z_as_color, numsamp_max)

varx = vars(1,:);
vary = vars(2,:);
if z_is_empty
    varz = [];
    varsp_sc = zeros(2, size(vars,2), 'single');
else
    varz = vars(3,:);
    varsp_sc = zeros(3, size(vars,2), 'single');
end
rdummies = zeros(2, size(vars,2), 'single');

[varx_lagxyz, vary_lagxyz, varz_lagxyz] = lagvars(varx, vary, varz, lagxy, lagz);

%%plotz becomes ones if z_is_empty, is this okay?? 
[plotx, ploty, plotz] = remove_nans_as_group(varx_lagxyz, vary_lagxyz, varz_lagxyz);

if ismember(1, find(polarinds))
    plotx = polarnan(plotx);
end
if ismember(2, find(polarinds))
    ploty = polarnan(ploty);
end
if ismember(3, find(polarinds))
    plotz = polarnan(plotz);
end

if threshold_data
    if contains(laball{1}, 'vel')
        [histdt, histx] = hist(abs(plotx(:)), 500);
        thrbin = triangle_threshold(histdt, 'R', 0);
        thrvel = histx(thrbin);
        excludeinds = abs(plotx)<thrvel;
    elseif contains(laball{2}, 'vel')
        [histdt, histx] = hist(abs(ploty(:)), 500);
        thrbin = triangle_threshold(histdt, 'R', 0);
        thrvel = histx(thrbin);
        excludeinds = abs(ploty)<thrvel;
    end
    plotx(excludeinds) = [];
    ploty(excludeinds) = [];
    plotz(excludeinds) = [];
end


if z_is_empty | (~z_is_empty & ~plot_z_as_color)
    cmp_sc = [0 0 1];
elseif ~z_is_empty & plot_z_as_color  %sort for color plot
    [~, idx4] = sort(plotz);
    plotx = plotx(idx4);
    ploty = ploty(idx4);
    cmp_sc = jet(numel(idx4));
end

%dummy variables for possible double polar plot (ie two polar vars)
rdummy1_lbnd = 0.1; %for double polar plots
rdummy1_ubnd = 0.45;%for double polar plots
rdummy2_lbnd = 0.5;%for double polar plots
rdummy2_ubnd = 0.85;%for double polar plots
r_dummy1 = rdummy1_lbnd + (rdummy1_ubnd-rdummy1_lbnd)*rand(size(plotx));
r_dummy2 = rdummy2_lbnd + (rdummy2_ubnd-rdummy2_lbnd)*rand(size(ploty));

%for now find corr coeffs between first two vars only, will add multiple correlation
switch num2str(find(polarinds(1:2)))
    case '' %no polar
        [ccr ccpv] = corr(plotx, ploty); %linear-linear
        % [ccr ccpv] = corr(plotz, ploty); %linear-linear
    case '1'
        [ccr ccpv] = circ_corrcl(plotx, ploty); %circ-linear
    case '2'
        [ccr ccpv] = circ_corrcl(ploty, plotx); %circ-linear (and switch input order)
    case '1  2'
        [ccr ccpv] = circ_corrcc(plotx, ploty); %circ-circ
end


varsp_sc(1,:) = nanpadvar(plotx, numsamp_max, vecdim=2);
varsp_sc(2,:) = nanpadvar(ploty, numsamp_max, vecdim=2);
if ~z_is_empty
    varsp_sc(3,:) = nanpadvar(plotz, numsamp_max, vecdim=2);
end
rdummies(1,:) = nanpadvar(r_dummy1, numsamp_max, vecdim=2);
rdummies(2,:) = nanpadvar(r_dummy2, numsamp_max, vecdim=2);

end


function [varx_lagxyz, vary_lagxyz, varz_lagxyz] = lagvars(varx, vary, varz, lagxy, lagz)


%first apply xy lag
if lagxy<=0 %negative lag, first variable follows second (first var shifted left) (but should be opposite prob)
    varx_lagxy = vec(varx(1+abs(lagxy):end));
    vary_lagxy = vec(vary(1:end-abs(lagxy)));
else %positive lag first variable precedes second (first var shifted right) (but should be opposite prob)
    varx_lagxy = vec(varx(1:end-abs(lagxy)));
    vary_lagxy = vec(vary(1+abs(lagxy):end));
end

%now apply 3rd variable lag
if lagz<=0 %negative lag, first variable follows second (first var shifted left) (but should be opposite prob)
    varx_lagxyz = vec(varx_lagxy(1+abs(lagz):end));
    vary_lagxyz = vec(vary_lagxy(1+abs(lagz):end));
    varz_lagxyz = vec(varz(1:end - (abs(lagxy)+abs(lagz)) )); %also include lagxy for 3rd var
else %positive lag first variable precedes second (first var shifted right) (but should be opposite prob)
    varx_lagxyz = vec(varx_lagxy(1:end-abs(lagz)));
    vary_lagxyz = vec(vary_lagxy(1:end-abs(lagz)));
    varz_lagxyz = vec(varz( (1+abs(lagxy)+abs(lagz) ) :end));
end

end


function [varx_lagxyz, vary_lagxyz, varz_lagxyz] = remove_nans_as_group(varx_lagxyz, vary_lagxyz, varz_lagxyz)

keepind = ~(isnan(varx_lagxyz) | isnan(vary_lagxyz));
varz_lagxyz_isnan = isnan(varz_lagxyz);
if any(varz_lagxyz_isnan)
    keepind = keepind | varz_lagxyz_isnan;
    varz_lagxyz = varz_lagxyz(keepind);
end
varx_lagxyz = varx_lagxyz(keepind);
vary_lagxyz = vary_lagxyz(keepind);
if ~any(varz_lagxyz_isnan)
    varz_lagxyz = ones(numel(varx_lagxyz), 1);
end

end
