function optout = optupdate(optin, optdef, sub, subsused)

arguments
    optin
    optdef
    sub = []
    subsused = []
end

% recursively update struct optdef with entries from struct optin;
% optin and optout can be nonscalar, but optdef must be scalar
% if field is in both optin and optdef, assign to optout the value in optin; if field is only in optdef, assign to optout the value in optdef; if field isn't in optdef, ignore it (don't put in optout)
% optional input sub copies top level structs in optin into subfields sharing sub names (convenient way to copy options)

% before entering optudrec (recursive opt update), copy all defaults for top level fields in optin

if isempty(sub)
    sub = {}; %make it an empty cell, to be sure
end
if isempty(subsused)
    subsused = {}; %make it an empty cell, to be sure
end


if numel(optdef)>1
    error("optdef must be scalar structure")
end

if isempty(fieldnames(optin))
    optout = optdef;
else
    fn1 = fieldnames(optin);
    fn1 = fn1(~ismember(fn1, subsused));
    fn1 = fn1(~strcmp(fn1, 'subsused'));
    for k = 1:numel(fn1)
        if ~isfield(optdef, fn1{k}) 
            error(sprintf(fn1{k} + " IS NOT A FIELD OF d IN odf"))
        end
        if isempty(sub)
            optout.(fn1{k}) = optdef.(fn1{k});
            optout.(fn1{k}) = optudrec(optin.(fn1{k}), optout.(fn1{k}), fn1{k});
        else
            fn2 = fieldnames(optin.(fn1{k}));
            tmphold = fn2(ismember(fn2, subsused));
            for w = 1:numel(tmphold) %store previous sub, and remove from current optin to create optout (any nested previous sub are unmodified within optudrec 
                tmphold2.(tmphold{w}) = optin.(fn1{k}).(tmphold{w});
                optin.(fn1{k}) = rmfield(optin.(fn1{k}), tmphold{w});
            end
            for w = 1:numel(sub)
                optout.(fn1{k}).(sub{w}) = optdef.(fn1{k});
                optout.(fn1{k}).(sub{w}) = optudrec(optin.(fn1{k}), optout.(fn1{k}).(sub{w}), fn1{k});
            end
            for w = 1:numel(tmphold) %add previous sub back to optout
                optout.(fn1{k}).(tmphold{w}) = tmphold2.(tmphold{w});
            end
            % o = cell2struct([struct2cell(o); struct2cell(osub)],[fieldnames(o); fieldnames(osub)]);
        end
    end
end



    function optout = optudrec(optin, optout, fnparent)
        numstin = numel(optin);
        numstorig = numel(optout);

        if numstin>1
            if numstorig==1
                optout = repelem(optout, numstin);
            elseif numstorig~=numstin
                error("optdef must be scalar struct, or match length of optin")
            end
            for v = 1:numstin
                optout(v) = optudrec(optin(v), optout(v), fnparent);
            end
        else
            fn = fieldnames(optin);
            for u = 1:numel(fn)
                if isfield(optout, fn{u})
                    if isstruct(optin.(fn{u}))
                        if ~isstruct(optout.(fn{u})) && ~isobject(optout.(fn{u})) %struct can refer to object not struct
                            error(sprintf("optdef." + fn{u} + " DOES NOT EXIST"))
                        else
                            optout.(fn{u}) = optudrec(optin.(fn{u}), optout.(fn{u}), fn{u});
                        end
                    else
                        if ~isempty(optin.(fn{u})) %in case we're in an index of nonscalar struct where optin wasnt specified
                            optout.(fn{u}) = optin.(fn{u}); %update
                        end
                    end
                else
                    if isstruct(optin.(fn{u}))
                        if ismember(fn{u}, subsused)
                            optout.(fn{u}) = optin.(fn{u});
                        else
                            if ~isfield(optdef, fn{u})
                                error(sprintf("IN odf, " + fn{u} + " IS NOT A FIELD OF d, nor is it a subfield of " + fnparent + ", BUT YOU PLACED IT IN YOUR OPT STRUCT AS IF IT WERE ONE OF THESE"))
                            else
                                optout.(fn{u}) = optudrec(optin.(fn{u}), optdef.(fn{u}), fn{u});
                            end
                        end
                    else
                        sprintf("ignoring field " + fn{u} + " because it is not a field of d." + fnparent + " in odf")
                    end
                end
            end
        end

    end


end
