
function differ = tsdv(vartypein, inp, slopelensec, slopeord, dt)

arguments
    vartypein char
    inp double
    slopelensec double
    slopeord double
    dt double
end

slopelen = round(slopelensec / dt);

if strcmp(vartypein, 'circular')

    % differentiate circular variable 

    inpx = cos(inp);
    inpy = sin(inp);

    inpdx = movingslope(inpx, slopelen, slopeord);
    inpdy = movingslope(inpy, slopelen, slopeord);

    denom = inpx.^2 + inpy.^2;
    differ = (-inpy ./ denom).*inpdx + (inpx ./ denom).*inpdy; %formula for derivative of atan2(y,x)

elseif strcmp(vartypein, 'normal')

    differ = movingslope(inp, slopelen, slopeord);

elseif strcmp(vartypein, 'categorical')

    filt = [zeros(1,slopelen-1), 1, zeros(1,slopelen-1), -1]; %find diffs across larger num samples since sometimes it takes more than 2 samples to go from max to min (-pi to pi)
    differ = conv(inp, filt, 'full');
    differ = differ((numel(filt) - 1)+1:end-(numel(filt) - (1 + (slopelen-1))));
    differ = cat(1, zeros((slopelen-1)+1, 1), differ);

end
