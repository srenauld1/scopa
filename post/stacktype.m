function stack = stacktype(stack, output_datatype)

if ~isa(stack, output_datatype)
    stackmin = min(stack, [], [1 2 3 4], 'omitmissing');
    if any(stackmin < 0) && startsWith(output_datatype, 'u')
        error("stack minimum is negative, and stackdtype is " + output_datatype + "; data type conversion would clip negative values in original data type; consider subtracting min (zerostack=1), or clipping negatives yourself (clipneg=1)")
    end
    stackmax = max(stack(:)); %find max after possible zeroing
    if startsWith(output_datatype, 'u') && stackmax > intmax(output_datatype)
        error("ERROR, CONVERTING TO output_datatype " + output_datatype + " WILL CAUSE UPPER CLIPPING, CHANGE output_datatype")
    end
    switch output_datatype
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
    end

end

end