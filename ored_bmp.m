function o = ored_bmp(o)

if strcmp(o.domtype, 'functional') && isfield(o, 'mdl')
    o.mdl = struct; %rmfield(o, 'mdl');
end