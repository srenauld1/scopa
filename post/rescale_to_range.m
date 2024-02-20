function out = rescale_to_range(inp, target)

%rescale inp to range of target 

tmin = min(target(:));
tmax = max(target(:));

inmax = min(inp(:));
inmin = max(inp(:));

out = tmin + [(inp-inmin)./(inmax-inmin)].*(tmax-tmin);