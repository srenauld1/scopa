function o = ochk(o, mos)

if isfield(o, mos)
    error("you passed o with substruct " + mos + " but should pass in that substruct itself")
end

switch mos %further specialized reduction by mos
    case 'roi'
        o = ochk_roi(o);
    case 'bmp'
        %o = ochk_bmp(o);
end

end

function o = ochk_roi(o)

if ~isempty(o.nrm) && isempty(o.nrm.nrmstr)
    o.nrm.nrmstr = 'f';
end

end

