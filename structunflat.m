function sout = structunflat(s, opt)

arguments
    s
    opt.delim = []
    opt.nonest = 0 %1 does not allow nested input structs, 0 does
end
delim = opt.delim;
nonest = opt.nonest;

if isempty(delim)
    % fprintf("USING DEFAULT DELIMITER DOUBLE UNDERSCORE IN structunflat" + newline)
    delim = '__';
end


%unflatten a struct that was flattened with structflat
%this is quick and dirty (uses eval)
%input cannot have any nesting

fn = fieldnames(s);
for k = 1:numel(fn)
    if nonest && isstruct(s.(fn{k}))
        error("input to structunflat must be flat struct; you passed a struct with nesting")
    end
    fnnew = regexprep(fn{k}, [delim '(\d+)' delim], '($1).'); %nonscalar index
    % fnnew = regexprep(fnnew, [delim '(\d+)', '($1)'); %ending number (shouldn't happen, this is an array index not a struct index)
    fnnew = strrep(fnnew, delim, '.'); 
    eval(['sout.' fnnew '= s.' (fn{k}) ';']); %using eval as hack to deal with nesting, there is a safer with recursive loop, needs to be written
end

end