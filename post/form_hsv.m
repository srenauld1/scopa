
function [ hsvmap ] = form_hsv( stim, resp, gof, ...
    hdata, sdata, vdata, ...
    huenorm, satnorm, valnorm, ...
    gethr_native, gethr_relative, ...
    getsr_native, getsr_relative, ...
    getvr_native, getvr_relative, ...
    hrange_in_manual, srange_in_manual, vrange_in_manual, ...
    hrange_out_manual, srange_out_manual, vrange_out_manual, ...
    hueshift, hue_is_periodic)

%use hrange_out_manual to restrict hue range after normalization (e.g. when domain is not
%periodic, since full hue range [0 1] is periodic)

switch huenorm
    case 'native'
        hrange_in = gethr_native(hdata, stim, resp);
    case 'relative'
        hrange_in = gethr_relative(hdata);
    case 'manual'
        hrange_in = hrange_in_manual;
end

switch satnorm
    case 'native'
        srange_in = getsr_native(sdata);
    case 'relative'
        srange_in = getsr_relative(sdata);
    case 'manual'
        srange_in = srange_in_manual;
end

switch valnorm
    case 'native'
        vrange_in = getvr_native(vdata);
    case 'relative'
        vrange_in = getvr_relative(vdata);
    case 'manual'
        vrange_in = vrange_in_manual;

end


if ~exist( 'hrange_out_manual', 'var' ) || isempty( hrange_out_manual )
    hrange_out = [0 1];
else
    hrange_out = hrange_out_manual;
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
    if hue_is_periodic
        hdata = mod(hdata, 2*pi);
    end
    hdata = scale_range( hdata, hrange_in, hrange_out );
    hdata = clip_to_range( hdata, hrange_out );
    if exist( 'hueshift', 'var' ) & ~isempty(hueshift)
        hdata = mod( hdata + hueshift, 1 ); %shift hue circularly around circle (fine even if hrange_out is not [0 1])
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


