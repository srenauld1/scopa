function out = rescale_to_range(inp, source, target, skipnan)

%rescale inp from source to target
% normal rescale would use inp as source, and target of [0 1]

if skipnan
    tmin = min(target, [], 'all', 'omitmissing');
    tmax = max(target, [], 'all', 'omitmissing');
else
    tmin = min(target, [], 'all');
    tmax = max(target, [], 'all');
end
if skipnan
    smin = min(source, [], 'all', 'omitmissing');
    smax = max(source, [], 'all', 'omitmissing');
else
    smin = min(source, [], 'all');
    smax = max(source, [], 'all');
end

out = tmin + [(inp-smin)./(smax-smin)].*(tmax-tmin);