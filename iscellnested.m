
function isnested = iscellnested(c)
isnested = false;
if ~iscell(c)
    return;
end
for i = 1:numel(c)
    if iscell(c{i})
        isnested = true;
        return;
    end
end
end