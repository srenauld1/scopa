function y = isemptyall(x)

% isempty for ordinary array, cell array, string array, and empty struct
% ordinary, cell, and string arrays can be nested (and mixed in type)
% a struct with fields (empty or not) is not empty; only a struct with no fields is empty

y = 1;
if isstruct(x)
    if ~isempty(fieldnames(x)) %~isempty(fieldnames(structflat(x)))
        y = 0;
    end
elseif iscell(x) || isstring(x)
    y = rectmp(x);
else
    if ~isempty(x)
        y = 0;
    end
end

end

function y = rectmp(x)

y = 1;
x = cellflat(x, str=1); %treat strings like cells in cellflat with option str=1
for k = 1:numel(x)
    if iscell(x{k}) || isstring(x{k})
        y = rectmp(x{k});
    else
        if ~isempty(x{k})
            y = 0;
            return
        end
    end
end

end