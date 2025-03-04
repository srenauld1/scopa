function [o, oreturn] = ored(o, vbin)

% ored ("options reduce") removes options that have no effect on the data (like plotting options), 
% and also removes redundancy (since options can depend on each other) 
% ored is called before assigning id (optid) to an options set (using structfile in oid)

arguments
    o
    vbin
end

nonfunctional_vbin = {'sp', 'tp', 'imhsv', 'optid', 'tg', 'indv', 'depv'};

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
        o = ored_roi(o);
    case 'sld'
        % sld.dostats, sld.savemem
        % o = ored_sld(o);
    otherwise
        fprintf("currently no reduction required for opt " + vbin + newline)

end


end
