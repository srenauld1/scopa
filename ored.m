function [o, oreturn] = ored(o, vbin)

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

o = structflat(o);
wcpat = '*';
wcinds = structfun(@(x) any(strcmp(x, wcpat)),o);
if any(wcinds) %hack for now, replace wildcard (from tsget) with 0, which will have same effect in general (but not for cm, but that will be fixed later)
    fn = fieldnames(o);
    o = struct2cell(o);
    o(wcinds) = {0};
    fnwc = fn(wcinds);
    o = cell2struct(o, fn);
end
o = structunflat(o);


switch vbin

    case 'roi'

        o = ored_roi(o);

    otherwise

        fprintf("currently no reduction required for opt " + vbin + newline)

end


if any(wcinds)
    o = structflat(o);
    fn = fieldnames(o);
    wcinds_new = ismember(fn, fnwc);
    o = struct2cell(o);
    o(wcinds_new) = {wcpat};
    o = cell2struct(o, fn);
    o = structunflat(o);
end

end
