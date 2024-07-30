function cellout = fieldnames_recursive(structin)

for ofi = 1:numel(structin) %for struct index in structin
    [rind, cind] = ind2sub(size(structin), ofi);
    cellout{rind, cind} = fieldnames_recurse(structin(rind, cind));
end

end

function cellout = fieldnames_recurse(structin)

fn = fieldnames(structin);
for fi = 1:numel(fn)
    if isstruct(structin.(fn{fi}))
        cellout{fi} = fieldnames_recurse(structin.(fn{fi}));
    else
        cellout{fi} = fn{fi};
    end
end

end