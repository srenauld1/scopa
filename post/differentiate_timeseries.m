
function vel = differentiate_timeseries(datatype, inp, slopelen, slopeorder, dt)

arguments
    datatype char
    inp double
    slopelen double
    slopeorder double
    dt double
end

if strcmp(datatype, 'circular')

    % differentiate circular variable without using unwrap (unwrap can cause rare spikes)

    inpx = cos(inp);
    inpy = sin(inp);

    inpdx = movingslope(inpx, slopelen, slopeorder, dt);
    inpdy = movingslope(inpy, slopelen, slopeorder, dt);
    %inpdx = movmedian(inpdx, [smoothwindow smoothwindow], 'omitnan');
    %inpdy = movmedian(inpdy, [smoothwindow smoothwindow], 'omitnan');

    denom = inpx.^2 + inpy.^2;
    vel = (-inpy ./ denom).*inpdx + (inpx ./ denom).*inpdy; %formula for derivative of atan2(y,x)

elseif strcmp(datatype, 'standard')

    try
        vel = movingslope(inp, slopelen, slopeorder, dt);
    catch
        vel=[];
    end

elseif strcmp(datatype, 'categorical')

    sprintf("not differentiating categorical timeseries")
    vel = [];

end
