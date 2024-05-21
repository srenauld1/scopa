
function vel = differentiate_timeseries(iscircular, inp, dt, slopelen, slopeorder)

arguments
    iscircular logical
    inp double
    dt double
    slopelen double
    slopeorder double
end

if iscircular

    % differentiate circular variable without using unwrap (unwrap can cause rare spikes)

    inpx = cos(inp);
    inpy = sin(inp);

    inpdx = movingslope(inpx, slopelen, slopeorder, dt);
    inpdy = movingslope(inpy, slopelen, slopeorder, dt);
    %inpdx = movmedian(inpdx, [smoothwindow smoothwindow], 'omitnan');
    %inpdy = movmedian(inpdy, [smoothwindow smoothwindow], 'omitnan');

    denom = inpx.^2 + inpy.^2;
    vel = (-inpy ./ denom).*inpdx + (inpx ./ denom).*inpdy; %formula for derivative of atan2(y,x)

else

    vel = movingslope(inp, slopelen, slopeorder, dt);


end
