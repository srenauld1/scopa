function outp = globals_a2p(inp)
persistent gset
if isstruct(inp)
    if isempty(gset)
        gset = inp;
    else
        error("trying to set gset after it's already been set")
    end
elseif ischar(inp)
    if isequal(inp,'all')
        outp = gset;
    elseif ~isfield(gset,inp)
        sprintf("parameter " + inp + " does not exist in gset; need to set first; returning empty array")
        outp = [];
    else
        outp = gset.(inp);
    end
end
end