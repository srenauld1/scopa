
function hsvmap = compute_hsv( ft, gof, indvpref, depvstd, plt, modeltype, stats)

numroi = size(ft,1);
hdata = zeros(numroi, 1);
sdata = zeros(numroi, 1);
vdata = zeros(numroi, 1);
for ri = 1:numroi
    hdata(ri) = plt.gethue(ft(ri,:), indvpref(ri));
    sdata(ri) = plt.getsat(gof(ri));
    vdata(ri) = plt.getval(depvstd(ri));
end

if strcmp(plt.huenorm, 'native') && (strcmp(modeltype, 'linear') || strcmp(modeltype, 'plane') || startsWith(modeltype, 'svd'))
    disp("WARNING, NO NATIVE plt.huenorm FOR MODELTYPES linear, plane, or svd, SWITCHING TO RELATIVE")
    plt.huenorm = 'relative'; %hue normalization method, see setup_model
end

%use plt.hrange_out_manual to restrict hue range after normalization (e.g. when domain is not
%periodic, since full hue range [0 1] is periodic)

switch plt.huenorm
    case 'native'
        hrange_in = plt.gethr_native(stats.indv_pre_lim_alldim, stats.depv_pre_lim_alldim);
    case 'relative'
        hrange_in = plt.gethr_relative(hdata);
    case 'manual'
        hrange_in = plt.hrange_in_manual;
end

switch plt.satnorm
    case 'native'
        srange_in = plt.getsr_native(sdata);
    case 'relative'
        srange_in = plt.getsr_relative(sdata);
    case 'manual'
        srange_in = plt.srange_in_manual;
end

switch plt.valnorm
    case 'native'
        vrange_in = plt.getvr_native(vdata);
    case 'relative'
        vrange_in = plt.getvr_relative(vdata);
    case 'manual'
        vrange_in = plt.vrange_in_manual;

end


if ~isfield( plt, 'hrange_out_manual' ) || isempty( plt.hrange_out_manual )
    hrange_out = [0 1];
else
    hrange_out = plt.hrange_out_manual;
end

if ~exist( 'srange_out_manual', 'var' ) || isempty( srange_out_manual )
    srange_out = [0 1];
else
    srange_out = srange_out_manual;
end

if ~exist( 'vrange_out_manual', 'var' ) || isempty( vrange_out_manual )
    vrange_out = [0 1];
else
    vrange_out = vrange_out_manual;
end

hsvmap = zeros( [length(hdata) 3] );

if ~exist( 'hdata', 'var' ) || isempty( hdata )
    hsvmap(:,1) = 1;
else
    if plt.hue_is_periodic
        hdata = mod(hdata, 2*pi);
    end
    hdata = scale_range( hdata, hrange_in, hrange_out );
    hdata = clip_to_range( hdata, hrange_out );
    if isfield( plt, 'hueshift' ) & ~isempty(plt.hueshift)
        hdata = mod( hdata + plt.hueshift, 1 ); %shift hue circularly around circle (fine even if hrange_out is not [0 1])
    end
    hsvmap(:,1) = hdata;
end

if ~exist( 'sdata', 'var' ) || isempty( sdata )
    hsvmap(:,2) = 1;
else
    sdata = scale_range( sdata, srange_in, srange_out );
    sdata = clip_to_range( sdata, srange_out);
    hsvmap(:,2) = sdata;
end

if ~exist( 'vdata', 'var' ) || isempty( vdata )
    hsvmap(:,3) = 1;
else
    vdata = scale_range( vdata, vrange_in, vrange_out );
    vdata = clip_to_range( vdata, vrange_out );
    hsvmap(:,3) = vdata;
end


end


