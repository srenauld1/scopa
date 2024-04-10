function plt = setup_model_plotting(modeltype, plt)

%would be nice to make this more general, but currently switches by modeltype
%some of these anonymous functions are just lookups, but kept this way for possible future expansion   

huestr = plt.huestr;
hrange_out_manual = plt.hrange_out_manual;

iif = @(varargin) varargin{2 * find([varargin{1:2:end}], 1, 'first')}(); %how to do "inline if" (iif)

%% model-specific vars

hue_is_periodic = 0;
if strcmp(modeltype, 'vonmises') & strcmp(huestr, 'loc') %only if the param assigned to hue is periodic, make hrange the full circle
    "WARNING, CHANGING hrange_out_manual TO [0 1] BECAUSE HUE PARAM IS PERIODIC"
    hue_is_periodic = 1;
    hrange_out_manual = [0 1];
end


if startsWith(modeltype, 'svd')

    switch huestr
        case 'loc'
            gethue = @(ft, indvpref) ft(1);
            gethr_native = @(limi,limd) error("NO NATIVE LOC NORMALIZATION FOR LINEAR MODEL, SINCE SLOPE IS UNBOUNDED"); %was [-1 1] which doesn't make sense;
        case 'wid'
            error("NO WID PARAM FOR LINEAR MODEL")
        case 'amp'
            gethue = @(ft, indvpref) ft(2);
            gethr_native = @(limi,limd) limd;
    end


elseif startsWith(modeltype, 'linear')

    switch huestr
        case 'loc'
            gethue = @(ft, indvpref) ft(1);
            gethr_native = @(limi,limd) error("NO NATIVE LOC NORMALIZATION FOR LINEAR MODEL, SINCE SLOPE IS UNBOUNDED"); %was [-1 1] which doesn't make sense;
        case 'wid'
            error("NO WID PARAM FOR LINEAR MODEL")
        case 'amp'
            gethue = @(ft, indvpref) ft(2);
            gethr_native = @(limi,limd) limd;
    end


elseif startsWith(modeltype, 'plane')

    switch huestr
        case 'loc'
            gethue = @(ft, indvpref) ft(2);
            gethr_native = @(limi,limd) error("NO NATIVE LOC NORMALIZATION FOR LINEAR MODEL, SINCE SLOPE IS UNBOUNDED"); %was [-1 1] which doesn't make sense;
        case 'wid'
            error("NO WID PARAM FOR LINEAR MODEL")
        case 'amp'
            gethue = @(ft, indvpref) ft(2);
            gethr_native = @(limi,limd) limd;
    end

elseif startsWith(modeltype, 'genlog')

    switch huestr
        case 'loc'
            gethue = @(ft, indvpref) ft(1);
            gethr_native = @(limi,limd) error("NO NATIVE LOC NORMALIZATION FOR LINEAR MODEL, SINCE SLOPE IS UNBOUNDED"); %was [-1 1] which doesn't make sense;
        case 'wid'
            error("NO WID PARAM FOR GENLOG MODEL")
        case 'amp'
            gethue = @(ft, indvpref) ft(2);
            gethr_native = @(limi,limd) limd;
    end


elseif startsWith(modeltype, 'vonmises')

    switch huestr
        case 'loc'
            gethue = @(ft, indvpref) indvpref; 
            gethr_native = @(limi,limd) [0 2*pi];
        case 'wid'
            gethue = @(ft, indvpref) 2 * abs( acos( 1/ft(2) * log( 1/2 *( exp(ft(2)) + exp(-ft(2)) ))));
            gethr_native = @(limi,limd) [0 2*pi];
        case 'amp'
            gethue = @(ft, indvpref) ft(1) * ( exp(ft(2)) - exp(-ft(2)) );
            gethr_native = @(limi,limd) limd;
    end


elseif startsWith(modeltype, 'gaussian')

    switch huestr
        case 'loc'
            gethue = @(ft, indvpref) ft(2);
            gethr_native = @(limi,limd) limi;
        case 'wid'
            gethue = @(ft, indvpref) 2 * ((2 * log( 2 )) ^ 0.5) * abs(ft(3)); %fwhm
            gethr_native = @(limi,limd) limi;
        case 'amp'
            gethue = @(ft, indvpref) ft(1);
            gethr_native = @(limi,limd) limd;
    end

elseif startsWith(modeltype, 'ann')

    switch huestr
        case 'loc'
            gethue = @(ft, indvpref) indvpref; 
            gethr_native = @(limi,limd) [0 2*pi];
        case 'wid'
            gethue = @(ft, indvpref) 2 * abs( acos( 1/ft(2) * log( 1/2 *( exp(ft(2)) + exp(-ft(2)) ))));
            gethr_native = @(limi,limd) [0 2*pi];
        case 'amp'
            gethue = @(ft, indvpref) ft(1) * ( exp(ft(2)) - exp(-ft(2)) );
            gethr_native = @(limi,limd) limd;
    end

elseif startsWith(modeltype, 'tm')

    switch huestr
        case 'loc'
            gethue = @(ft, indvpref) indvpref; 
            gethr_native = @(limi,limd) [0 2*pi];
        case 'wid'
            gethue = @(ft, indvpref) 2 * abs( acos( 1/ft(2) * log( 1/2 *( exp(ft(2)) + exp(-ft(2)) ))));
            gethr_native = @(limi,limd) [0 2*pi];
        case 'amp'
            gethue = @(ft, indvpref) ft(1) * ( exp(ft(2)) - exp(-ft(2)) );
            gethr_native = @(limi,limd) limd;
    end

end


%% plotting vars

getsat = @(gof) 1/gof;
getval = @(depvstd) depvstd;

gethr_relative = @(ft) iif( ...
    length(ft)>1,   @() [min(ft(:)) max(ft(:))], ...
    length(ft)==1,  @() [0 ft] ... %hack to deal with normalizing length 1 vector, will arbitrarily make hue the max hue
    );

getsr_native = @(sdata) [0 100]; %need to input values depnding on gof metric
getsr_relative = @(sdata) iif( ...
    length(sdata)>1,   @() [min(sdata(:)) max(sdata(:))], ...
    length(sdata)==1,  @() [0 sdata] ... %hack to deal with normalizing length 1 vector, will arbitrarily make sat the max sat
    );

getvr_native = @(vdata) [0 3]; %need to input values depending on indicator
getvr_relative = @(vdata) iif( ...
    length(vdata)>1,   @() [min(vdata(:)) max(vdata(:))], ...
    length(vdata)==1,  @() [0 vdata] ... %hack to deal with normalizing length 1 vector, will arbitrarily make val the max val
    );


plt.gethue = gethue;
plt.getsat = getsat;
plt.getval = getval;
plt.gethr_native = gethr_native;
plt.gethr_relative = gethr_relative;
plt.getsr_native = getsr_native;
plt.getsr_relative = getsr_relative;
plt.getvr_native = getvr_native;
plt.getvr_relative = getvr_relative;
plt.hrange_out_manual = hrange_out_manual;
plt.hue_is_periodic = hue_is_periodic;
plt.huestr = huestr;
plt = orderfields(plt);

