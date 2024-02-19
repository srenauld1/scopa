
function vel = cx_differentiate_circular_var(inp, dt, slopelen, slopeorder)

% differentiate circular variable without using unwrap (unwrapping can
% cause rare artifactual spikes and mistakes/aliases in circular direction) 

inpx = cos(inp);
inpy = sin(inp);

inpdx = movingslope(inpx, slopelen, slopeorder, dt);
inpdy = movingslope(inpy, slopelen, slopeorder, dt);
%inpdx = movmedian(inpdx, [smoothwindow smoothwindow], 'omitnan');
%inpdy = movmedian(inpdy, [smoothwindow smoothwindow], 'omitnan');

denom = inpx.^2 + inpy.^2;
vel = (-inpy ./ denom).*inpdx + (inpx ./ denom).*inpdy; %formula for derivative of atan2(y,x)

