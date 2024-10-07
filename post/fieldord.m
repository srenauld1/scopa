function structout = fieldord(structin)

for ofi = 1:numel(structin) %for struct index in structin
    [rind, cind] = ind2sub(size(structin), ofi);
    structout(rind, cind) = orderfields_recurse(structin(rind, cind));
end

end

function structin = orderfields_recurse(structin)

fn = fieldnames(structin);
for fi = 1:numel(fn)
    try
        if isstruct(structin.(fn{fi}))
            structin.(fn{fi}) = orderfields_recurse(structin.(fn{fi}));
        end
    catch
        fuk = 2;
    end
end
% structin = orderfields(structin);
structin = orderfields(structin, natsortrows(fieldnames(structin))); %natural sorting

end