function structout = orderfields_recursive(structin)

for ofi = 1:length(structin) %for struct index in structin
    structout(ofi) = orderfields_recurse(structin(ofi));
end

end

function structin = orderfields_recurse(structin)

fn = fieldnames(structin);
for fi = 1:length(fn)
    if isstruct(structin.(fn{fi}))
        structin.(fn{fi}) = orderfields_recurse(structin.(fn{fi}));
    end
end
structin = orderfields(structin);

end