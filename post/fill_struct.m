function structout = fill_struct(structin)

fn = fieldnames(structin(1));

for j = 1:numel(structin)
    for fi = 1:numel(fn)
        if isempty(structin(j).(fn{fi}))
            structout(j).(fn{fi}) = structin(1).(fn{fi});
        else
            structout(j).(fn{fi}) = structin(j).(fn{fi});
        end
    end
end
