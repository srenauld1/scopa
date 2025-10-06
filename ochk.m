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

if o.doma==1
    if o.ma.numroi<1
        error("o.mm.numroi must be greater than 0")
    end
end

if isempty(o.rgname)
    error("rgname is empty, but by this point an empty rgname should have been set to rgnamedf in structfill");
end

end

