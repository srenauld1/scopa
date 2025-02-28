function nb = bytespersamp(v)

if isnumeric(v) || islogical(v)
    v = class(v);
else
    if ~isstring(v) && ~ischar(v)
        error("input must be numeric or the name (as a string or char) of a numeric class")
    end
end

switch v
    case {'int64', 'uint64', 'double'}
        nb = 8;
    case {'int32', 'uint32', 'single'}
        nb = 4;
    case {'int16', 'uint16'}
        nb = 2;
    case {'int8', 'uint8', 'logical'}
        nb = 1;
    otherwise
        error("input must be numeric or the name (as a string or char) of a numeric class")
end

end

