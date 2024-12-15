%this is a script, not function, so all variables from calling file are easily accessible

allvars = whos;
par_defaults = cell2struct({allvars.name}.',{allvars.name});
par_defaults = rmfield(par_defaults, 'parsin');
eval(structvars(par_defaults,0).');
% par_defaults = orderfields(par_defaults);

for ofi = 1:length(parsin) %for struct index in parsin
    parsout(ofi) = update_recursive(parsin(ofi), par_defaults);
end


function parsout = update_recursive(parsin, parsout)
fn = fieldnames(parsout);
for fi = 1:length(fn)
    if isfield(parsin, fn{fi})
        if isstruct(parsin.(fn{fi}))
            if ~isstruct(parsout.(fn{fi})) && ~isobject(parsout.(fn{fi})) %struct can refer to object not struct
                error("input struct where there is no default struct")
            else
                parsout.(fn{fi}) = update_recursive(parsin.(fn{fi}), parsout.(fn{fi}));
                % parsout.(fn{fi}) = orderfields(parsout.(fn{fi}));
            end
        else
            if ~isempty(parsin.(fn{fi}))
                parsout.(fn{fi}) = parsin.(fn{fi}); %overwrite default with user-defined input
            end
        end
    end
               
    % parsout = orderfields(parsout);

end


end