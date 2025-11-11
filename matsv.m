function matsv(pth, field, opt)

arguments
    pth {mustBeTextScalar}
end
arguments (Repeating)
    field
end
arguments
    opt.s = [] %if saving select fields from struct, pass in struct in name-value argument s; if just saving variables, leave empty
end
s = opt.s;


m = matfile(pth, 'writable', true); %use matfile to append the new data to the s file without having to save the entire s

if isempty(opt.s)
    error("need to test when not saving struct (ie when s empty)")
    for k = 1:numel(field)
        m.(field) = field{k}; %save field only
    end
else
    for k = 1:numel(field)
        mustBeTextScalar(field{k})
        m.(field{k}) = s.(field{k}); %save field only, from struct s
    end
end