
function vel = differentiate_timeseries(vartype, inp, slopelen_sec, slopeorder, dt)

arguments
    vartype char
    inp double
    slopelen_sec double
    slopeorder double
    dt double
end

slopelen = round(slopelen_sec / dt);

if strcmp(vartype, 'circular')

    % differentiate circular variable without using unwrap (unwrap can cause rare spikes)

    inpx = cos(inp);
    inpy = sin(inp);

    inpdx = movingslope(inpx, slopelen, slopeorder, dt);
    inpdy = movingslope(inpy, slopelen, slopeorder, dt);
    %inpdx = movmedian(inpdx, [smoothwindow smoothwindow], 'omitnan');
    %inpdy = movmedian(inpdy, [smoothwindow smoothwindow], 'omitnan');

    denom = inpx.^2 + inpy.^2;
    vel = (-inpy ./ denom).*inpdx + (inpx ./ denom).*inpdy; %formula for derivative of atan2(y,x)

elseif strcmp(vartype, 'normal')

    vel = movingslope(inp, slopelen, slopeorder, dt);

elseif strcmp(vartype, 'categorical')

    sprintf("not differentiating categorical timeseries")
    vel = [];

end
