function stout = structupdate(stin, storig)

%recursively update struct storig with entries from struct stin; stin and stout can be nonscalar, but storig cannot
% loop over fields in storig, if struct field in stin, recurse, if non-strct field in stin, overwrite 

stout = repelem(storig, numel(stin));

if numel(stin)>1
    for m = 1:numel(stin)
        stout(m) = structupdate(stin(m), storig);
    end
else
    fn = fieldnames(storig);
    for k = 1:numel(fn)
        if isfield(stin, fn{k})
            if isstruct(stin.(fn{k}))
                if ~isstruct(storig.(fn{k})) && ~isobject(storig.(fn{k})) %struct can refer to object not struct
                    error(sprintf("there is no default struct corresponding to input struct or substruct '" + fn{k}) + "'")
                else
                    stout.(fn{k}) = structupdate(stin.(fn{k}), storig.(fn{k}));
                end
            else
                if ~isempty(stin.(fn{k}))
                    stout.(fn{k}) = stin.(fn{k}); %update
                end
            end
        end
    end
end

