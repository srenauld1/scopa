
function dv = tsdv(vartypein, tsin, slopelensec, slopeord, dt)

arguments
    vartypein %normal, circular, or catergorical; tsin must be in radians if circular 
    tsin %input variable to be differentiated; must be in radians if vartypein is circular
    slopelensec %slope length in seconds; rounded to nearest sample
    slopeord %order for polynomial fit to determine local slope 
    dt %sample period
end

slopelen = round(slopelensec / dt);

if slopelen<slopeord+1
    error("movingslope will error because slopelen is less than slopeord+1; your value of slopelensec, given value of dt (sample period), gives slopelen less than slopeord+1; use a different slopelen and/or slopeord (likely just slopelen should be changed)")
end

if strcmp(vartypein, 'circular') % differentiate circular variable 

    fprintf("USER REQUESTED 'circular' vartypein, input must be in radians; assuming that it is and proceeding" + newline)

    inpx = cos(tsin);
    inpy = sin(tsin);

    inpdx = movingslope(inpx, slopelen, slopeord, dt);
    inpdy = movingslope(inpy, slopelen, slopeord, dt);

    denom = inpx.^2 + inpy.^2;
    dv = (-inpy ./ denom).*inpdx + (inpx ./ denom).*inpdy; %formula for derivative of atan2(y,x)

elseif strcmp(vartypein, 'normal') % differentiate non-circular variable 

    dv = movingslope(tsin, slopelen, slopeord, dt);

elseif strcmp(vartypein, 'categorical') % differentiate categorical variable 

    filt = [zeros(1,slopelen-1), 1, zeros(1,slopelen-1), -1]; %find diffs across larger num samples since sometimes it takes more than 2 samples to go from max to min (-pi to pi)
    dv = conv(tsin, filt, 'full');
    dv = dv((numel(filt) - 1)+1:end-(numel(filt) - (1 + (slopelen-1))));
    dv = cat(1, zeros((slopelen-1)+1, 1), dv);

end
