function stack = stacktype(stack, typeout)

if ~isa(stack, typeout)
    stackmin = min(stack, [], [1 2 3 4], 'omitmissing');
    if any(stackmin < 0) && startsWith(typeout, 'u')
        error("stack minimum is negative, and stackdtype is " + typeout + "; data type conversion would clip negative values in original data type; consider subtracting min (zerostack=1), or clipping negatives yourself (clipneg=1)")
    end
    stackmax = max(stack(:)); %find max after possible zeroing
    if startsWith(typeout, 'u') && stackmax > intmax(typeout)
        error("ERROR, CONVERTING TO typeout " + typeout + " WILL CAUSE UPPER CLIPPING, CHANGE typeout")
    end
    switch typeout
        case 'uint16'
            stack = uint16(stack);
        case 'uint32'
            stack = uint32(stack);
        case 'uint64'
            stack = uint64(stack);
        case 'int16'
            stack = int16(stack);
        case 'int32'
            stack = int32(stack);
        case 'int64'
            stack = int64(stack);
        case 'single'
            stack = single(stack);
        case 'double'
            stack = double(stack);
        case 'logical'
            stack = logical(stack);
        otherwise
            error("stack class is not in this switch statement; add it")
    end

end

end