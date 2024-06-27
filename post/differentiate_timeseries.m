
function differ = differentiate_timeseries(vartypein, inp, slopelen_sec, slopeorder, dt)

arguments
    vartypein char
    inp double
    slopelen_sec double
    slopeorder double
    dt double
end

slopelen = round(slopelen_sec / dt);

if strcmp(vartypein, 'circular')

    % differentiate circular variable 

    inpx = cos(inp);
    inpy = sin(inp);

    inpdx = movingslope(inpx, slopelen, slopeorder);
    inpdy = movingslope(inpy, slopelen, slopeorder);

    denom = inpx.^2 + inpy.^2;
    differ = (-inpy ./ denom).*inpdx + (inpx ./ denom).*inpdy; %formula for derivative of atan2(y,x)

elseif strcmp(vartypein, 'normal')

    differ = movingslope(inp, slopelen, slopeorder);

elseif strcmp(vartypein, 'categorical')

    sprintf("not differentiating categorical timeseries")
    differ = [];

end
