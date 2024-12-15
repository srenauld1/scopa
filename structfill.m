function structout = structfill(structin, k)

arguments 
    structin
    k = 1
end

%copy fields from nonscalar struct index k into all other indices; k is 1 if missing/empty 

fn = fieldnames(structin(k));

for m = 1:numel(structin)
    for p = 1:numel(fn)
        if isempty(structin(m).(fn{p}))
            structout(m).(fn{p}) = structin(k).(fn{p});
        else
            structout(m).(fn{p}) = structin(m).(fn{p});
        end
    end
end
