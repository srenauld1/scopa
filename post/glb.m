function outp = glb(inp)

% set globals, can be used in two ways (be sure to clear glb) before setting
    % a=2; b=3; glb(v=a, w=b) or simply glb(v=2, w=3); glb('v')==2, glb('w')==3
    % a.v=2; a.w=3; glb(a); glb('v')==2, glb('w')==3

arguments (Repeating)
    inp
end
persistent gset

if numel(inp)==1
    inp = inp{1};
end

if isstruct(inp)
    if isempty(gset)
        gset = inp;
    else
        error("trying to set gset after it's already been set")
    end
elseif iscell(inp)
    if isempty(gset)
        gset = struct;
        for k = 1:2:numel(inp)
            gset.(char(inp{k})) = inp{k+1};
        end
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