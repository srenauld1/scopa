function o = ochk(o, vbin)

if isfield(o, vbin)
    error("you passed o with substruct " + vbin + " but should pass in that substruct itself")
end

switch vbin %further specialized reduction by vbin
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
    error("rgname is empty, but by this point an empty rgname should have been set to rgnamedf in ofill");
end

end

