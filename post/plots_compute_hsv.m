
function hsvmap = plots_compute_hsv( plt, hueft, satft, valft, hueft2, huelimnat, huelimnat2, mdlname)

arguments
    plt struct %structure holding plotting options
    hueft double %feature assigned to hue (required input)
    satft double = 1 %feature assigned to saturation
    valft double = 1 %feature assigned to value
    hueft2 double = hueft %alternative hue feature, unused unless requested in plots_setup_hsv, according to mdlname 
    huelimnat double = [min(hueft(:)) max(hueft(:))] %native full range from which hue feature is drawn, used to normalize hue, (e.g. if hue is an "x" param from fit model, huelimnat would be independent variable min and max)
    huelimnat2 double = [min(hueft(:)) max(hueft(:))] %an alternative to huelimnat, used for some mdlname defaults (e.g. if hue is a "y" param from fit model, huelimnat would be dependent variable min and max)
    mdlname char = '' %can be used to switch among different plotting defaults
end

if strcmp(plt.huenorm, 'native')
    disp("WARNING, requested huenorm 'native', but no huelimnat argument passed, switching to huenorm 'relative'")
    plt.huenorm = 'relative'; %hue normalization method, see setup_model
end


if strcmp(plt.huenorm, 'native') && (strcmp(mdlname, 'linear') || strcmp(mdlname, 'plane') || startsWith(mdlname, 'svd'))
    disp("WARNING, NO NATIVE plt.huenorm FOR MDLNAME svd, SWITCHING TO RELATIVE")
    plt.huenorm = 'relative'; %hue normalization method, see setup_model
end


hdata = zeros(size(hueft,1), 1);
for ii = 1:size(hueft,1)
    hdata(ii) = plt.gethue(hueft(ii,:), hueft2(ii));
end
sdata = zeros(size(satft,1), 1);
for ii = 1:size(satft,1)
    sdata(ii) = plt.getsat(satft(ii));
end
vdata = zeros(size(valft,1), 1);
for ii = 1:size(valft,1)
    vdata(ii) = plt.getval(valft(ii));
end

%use plt.hrange_out_manual to restrict hue range after normalization (e.g. when domain is not
%periodic, since full hue range [0 1] is periodic)

switch plt.huenorm
    case 'native'
        hrange_in = plt.gethr_native(huelimnat, huelimnat2);
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


