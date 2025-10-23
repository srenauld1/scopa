function stack = stacktype(stack, dtype)

if ~isa(stack, dtype)
    if startsWith(dtype, 'u')
        stackmin = min(stack, [], [1 2 3 4], 'omitmissing'); %compute min for each channel
        if any(stackmin < 0)
            stack = stack - stackmin; %subtract min for all channels
            fprintf("WARNING: SUBTRACTING STACK MIN TO PREVENT CLIPPING NEGATIVE VALUES WHEN CONVERTING TO REQUESTED dtype " + dtype + newline)
        end
    end
    if contains(dtype, 'int')
        stackmax = max(stack(:)); %find max (also could have changed after possible zeroing above)
        if stackmax > intmax(dtype)
            error("ERROR, CONVERTING TO dtype " + dtype + " WILL CAUSE UPPER CLIPPING, CHANGE dtype")
        end
    end
    switch dtype
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
            error("stack class is not in this switch statement; add it if you need it")
    end

end

end