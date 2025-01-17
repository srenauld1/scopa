function v = vtype(v, typeout)

if ~isa(v, typeout)
    vmin = min(v, [], 'all', 'omitmissing');
    if any(vmin < 0) && startsWith(typeout, 'u')
        error("v minimum is negative, and stackdtype is " + typeout + "; data type conversion would clip negative values in original data type; consider subtracting min (zerostack=1), or clipping negatives yourself (clipneg=1)")
    end
    vmax = max(v(:)); %find max after possible zeroing
    if startsWith(typeout, 'u') && vmax > intmax(typeout)
        error("ERROR, CONVERTING TO typeout " + typeout + " WILL CAUSE UPPER CLIPPING, CHANGE typeout")
    end
    switch typeout
        case 'uint16'
            v = uint16(v);
        case 'uint32'
            v = uint32(v);
        case 'uint64'
            v = uint64(v);
        case 'int16'
            v = int16(v);
        case 'int32'
            v = int32(v);
        case 'int64'
            v = int64(v);
        case 'single'
            v = single(v);
        case 'double'
            v = double(v);
        case 'logical'
            v = logical(v);
        otherwise
            error("v class is not in this switch statement; add it")
    end

end

end