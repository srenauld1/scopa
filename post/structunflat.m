function sout = structunflat(s, delim)

arguments
    s
    delim = []
end

if isempty(delim)
    % fprintf("USING DEFAULT DELIMITER DOUBLE UNDERSCORE IN structunflat" + newline)
    delim = '__';
end


%unflatten a struct that was flattened with structflat
%this is quick and dirty (uses eval)
%input cannot have any nesting

fn = fieldnames(s);
for k = 1:numel(fn)
    if isstruct(s.(fn{k}))
        error("input to structunflat must be flat struct; you passed a struct with nesting")
    end
    fnnew = regexprep(fn{k}, [delim '(\d+)' delim], '($1).'); %nonscalar index
    % fnnew = regexprep(fnnew, [delim '(\d+)', '($1)'); %ending number (shouldn't happen, this is an array index not a struct index)
    fnnew = strrep(fnnew, delim, '.'); 
    eval(['sout.' fnnew '= s.' (fn{k}) ';']);
end

end