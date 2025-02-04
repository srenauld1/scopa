function [o, oreturn] = optreduce(o, vbin)

%remove redundancy in options sets (before writing to options file and assigning options set index)

arguments
    o
    vbin
end

nonfunctional_vbin = {'sp', 'tp', 'imhsv'};

if isfield(o, vbin)
    error("you passed o with substruct " + vbin + " but should pass that substruct itself")
end

oreturn = struct;
for m = 1:numel(nonfunctional_vbin)
    if isfield(o, nonfunctional_vbin{m})
        oreturn.(nonfunctional_vbin{m}) = o.(nonfunctional_vbin{m});
        o = rmfield(o, nonfunctional_vbin{m});
    end
end

switch vbin

    case 'roi'

        o = optreduce_roi(o);

    case 'mdl'

    case 'bmp'

    otherwise

        fprintf("no reduction routine for opt " + vbin + newline)

end


end
