function [s, sfile] = partmake(s, sfile, wcpat)

s = structflat(s);
sfile = structflat(sfile);
fnf = fieldnames(s);
for q = 1:numel(fnf)
    if isequal(s.(fnf{q}), wcpat)
        s = rmfield(s, fnf{q});
        if isfield(sfile, fnf{q}) %sfile may not have wildcard field because it's been reduced; but if it does, remove it
            sfile = rmfield(sfile, fnf{q});
        end
    end
end
s = structunflat(s);
sfile = structunflat(sfile);

end