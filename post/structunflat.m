function sout = structunflat(s)

%unflatten a struct that was flattened with structflat
%this is quick and dirty (uses eval)
%input cannot have any nesting

fn = fieldnames(s);
for k = 1:numel(fn)
    if isstruct(s.(fn{k}))
        error("input to structunflat must be flat struct; you passed a struct with nesting")
    end
    fnnew = regexprep(fn{k},'_([\d]+)_', '($1).'); %nonscalar index
    % fnnew = regexprep(fnnew,'_([\d]+)', '($1)'); %ending number (shouldn't happen, this is a vector index)
    fnnew = strrep(fnnew, '_', '.'); 
    eval(['sout.' fnnew '= s.' (fn{k}) ';']);
end

end