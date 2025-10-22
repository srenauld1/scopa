
function dv = tsdv(vtype, tsin, slopelensec, slopeord, sper)

% need to generalize this function for nd, and change to vecdv, and make time units optional (something like slopelensec and slopelensamp

arguments
    vtype {mustBeText} %normal, radians, degrees, or catergorical; tsin must be in radians if circular 
    tsin %input variable to be differentiated; must be in radians if vtype is circular
    slopelensec %length of window (in seconds) used to fit sliding window slope (to compute bump speed); rounded to nearest sample
    slopeord %order for polynomial fit to determine local slope 
    sper %sample period
end

if ~ismember(vtype, {'normal', 'radians', 'degrees', 'categorical'})
    error("first argument must be 'normal', 'radians', 'degrees', or 'categorical'")
end
if isempty(slopelensec)
    slopelensec = sper*slopeord+1;
    error("WARNING, IN daqld, slopelensec is too short given slopeord and sample rate, and will cause error in tsdv; you need to make slopelensec longer for this recording; the shortest possible value that will not cause error (and without changing slopeord) is: " + num2str(slopelensec_new))
end
slopelen = round(slopelensec / sper);

if slopelen<slopeord+1
    error("movingslope will error because slopelen is less than slopeord+1; your value of slopelensec, given value of sper (sample period), gives slopelen less than slopeord+1; use a different slopelen and/or slopeord (likely just slopelen should be changed)")
end

if strcmp(vtype, 'radians') || strcmp(vtype, 'degrees') % differentiate circular variable 

    if strcmp(vtype, 'degrees')
        tsin = deg2rad(tsin);
    end

    inpx = cos(tsin);
    inpy = sin(tsin);

    inpdx = movingslope(inpx, slopelen, slopeord, sper);
    inpdy = movingslope(inpy, slopelen, slopeord, sper);

    denom = inpx.^2 + inpy.^2;
    dv = (-inpy ./ denom).*inpdx + (inpx ./ denom).*inpdy; %formula for derivative of atan2(y,x)

elseif strcmp(vtype, 'normal') % differentiate non-circular variable 

    dv = movingslope(tsin, slopelen, slopeord, sper);

elseif strcmp(vtype, 'categorical') %differentiate categorical variable 

    filt = [zeros(1,slopelen-1), 1, zeros(1,slopelen-1), -1];
    dv = conv(tsin, filt, 'full');
    dv = dv((numel(filt) - 1)+1:end-(numel(filt) - (1 + (slopelen-1))));
    dv = cat(1, zeros((slopelen-1)+1, 1), dv);

else

    error("vtype must be circular, normal, or categorical")

end


if strcmp(vtype, 'degrees')
    dv = rad2deg(dv);
end