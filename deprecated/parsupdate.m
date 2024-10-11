%script not function to easily modify all workspace variables, put in script becasue it's used repeatedly

varsall = whos;

defpars = cell2struct({varsall.name}.',{varsall.name});
if isfield(defpars, 'pin')
    defpars = rmfield(defpars, 'pin');
end
if isfield(defpars, 'lab')
    defpars = rmfield(defpars, 'lab');
end
if isfield(defpars, 'obj')
    defpars = rmfield(defpars, 'obj');
end
eval(structvars(defpars,0).');

if ~exist('lab', 'var') | isempty(lab)
    nolab = 1;
else
    nolab = 0;
end

if nolab
    labloopnum = 1;
else
    labloopnum = numel(lab);
end

for k = 1:labloopnum
    for m = 1:length(pin) %for struct index in pin
        if nolab
            pout(m) = parsupdate_recursive(pin(m), defpars);
        else
            pout(m).(lab{k}) = parsupdate_recursive(pin(m), defpars);
        end
    end
end

pout = fieldord(pout); 


function pout = parsupdate_recursive(pin, pout)
fn = fieldnames(pout);
for fi = 1:length(fn)
    if isfield(pin, fn{fi})
        if isstruct(pin.(fn{fi}))
            if ~isstruct(pout.(fn{fi})) && ~isobject(pout.(fn{fi})) %struct can refer to object not struct
                error("input struct where there is no default struct")
            else
                pout.(fn{fi}) = parsupdate_recursive(pin.(fn{fi}), pout.(fn{fi}));
            end
        else
            if ~isempty(pin.(fn{fi}))
                pout.(fn{fi}) = pin.(fn{fi}); %overwrite default with user-defined input
            end
        end
    end
end
end



