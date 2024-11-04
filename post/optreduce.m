function o = optreduce(o, vbin)

%remove redundancy in options sets (before writing to options file and assigning options set index)

arguments
    o
    vbin
end

if ~iscell(vbin)
    vbin = {vbin};
end

for m = 1:numel(vbin)
    vbintmp = vbin{m};

    switch vbintmp
        case 'roi'

            o = optreduce_roi(o);

        case 'mfit'

        case 'feat'

    end

end

end
