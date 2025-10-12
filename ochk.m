function o = ochk(o, obin)

if isfield(o, obin)
    error("you passed o with substruct " + obin + " but should pass in that substruct itself")
end

switch obin %further specialized reduction by obin
    case 'roi'
        o = ochk_roi(o);
    case 'bmp'
        %o = ochk_bmp(o);
end

end

function o = ochk_roi(o)


end

