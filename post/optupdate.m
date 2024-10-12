function optout = optupdate(optin, optdef, copybinprev, copybin)

arguments
    optin
    optdef
    copybinprev = []
    copybin = []
end

% recursively update struct optdef with entries from struct optin;
% optin and optout can be nonscalar, but optdef must be scalar
% if field is in both optin and optdef, assign to optout the value in optin; if field is only in optdef, assign to optout the value in optdef; if field isn't in optdef, ignore it (don't put in optout)
% optional input copybin copies top level structs in optin into subfields sharing copybin names (convenient way to copy options)

% before entering optudrec (recursive opt update), copy all defaults for top level fields in optin

if isempty(cell2mat(copybin))
    copybin = {}; %make it an empty cell, to be sure
end
if ~iscell(copybin)
    copybin = {copybin};
end
if isempty(cell2mat(copybinprev))
    copybinprev = {}; %make it an empty cell, to be sure
end


if numel(optdef)>1
    error("optdef must be scalar structure")
end

if isempty(fieldnames(optin))
    optout = optdef;
else
    fn1 = fieldnames(optin);
    fn1 = fn1(~ismember(fn1, copybinprev));
    fn1 = fn1(~strcmp(fn1, 'copybinprev')); %this line means copybinprev does not have to exist as a default in odf
    for k = 1:numel(fn1)
        if ~isfield(optdef, fn1{k})
            error(sprintf("d." + fn1{k} + " does not exist in odf"))
        end
        if isempty(copybin)
            if all(ismember(fieldnames(optin.(fn1{k})), copybinprev)) %skip if the vbin is all copybins (ie if there is are no options passed in the vbin)
                optout.(fn1{k}) = optin.(fn1{k});
            else
                optout.(fn1{k}) = optdef.(fn1{k});
            end
            optout.(fn1{k}) = optudrec(optin.(fn1{k}), optout.(fn1{k}), fn1{k});
        else
            fn2 = fieldnames(optin.(fn1{k}));
            tmphold = fn2(ismember(fn2, copybinprev));
            for w = 1:numel(tmphold) %store previous copybin, and remove from current optin to create optout (any nested previous copybin are unmodified within optudrec
                tmphold2.(tmphold{w}) = optin.(fn1{k}).(tmphold{w});
                optin.(fn1{k}) = rmfield(optin.(fn1{k}), tmphold{w});
            end
            for w = 1:numel(copybin)
                optout.(fn1{k}).(copybin{w}) = optdef.(fn1{k});
                optout.(fn1{k}).(copybin{w}) = optudrec(optin.(fn1{k}), optout.(fn1{k}).(copybin{w}), fn1{k});
            end
            for w = 1:numel(tmphold) %add previous copybin back to optout
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

            %for nonscalar struct, find fields that are struct in one index but empty in another (ie not specified) and make them struct so they appear in output tmp, then assign tmp to optout
            fnq = fieldnames(optin);
            yesstruct = cellfun(@isstruct, struct2cell(vec(optin)));
            notstable = ~all(yesstruct==yesstruct(:,1), 2);
            for chx = 1:numel(optin)
                for chi = 1:numel(fnq)
                    if yesstruct(chi,chx)==0 && notstable(chi)==1
                        optin(chx).(fnq{chi}) = struct;
                    end
                end
            end
            for v = numstin:-1:1 %go backwards to preallocate
                tmp(v) = optudrec(optin(v), optout(v), fnparent);
            end
            optout = reshape(tmp, size(optin));
        else
            fn = fieldnames(optin);
            for u = 1:numel(fn)
                if isfield(optout, fn{u})
                    if isstruct(optin.(fn{u}))
                        if ~isstruct(optout.(fn{u})) && ~isobject(optout.(fn{u})) %struct can refer to object not struct
                            error(sprintf("d." + fn{u} + " does not exist in odf"))
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
                        if ismember(fn{u}, copybinprev)
                            optout.(fn{u}) = optin.(fn{u});
                        else
                            if ~isfield(optdef, fn{u})
                                error(sprintf("neither d." + fn{u} + " nor d." + [fnparent '.' fn{u}] + " exist in odf"))
                            else
                                optout.(fn{u}) = optudrec(optin.(fn{u}), optdef.(fn{u}), fn{u});
                            end
                        end
                    else
                        error(sprintf("d." + [fnparent '.' fn{u}] + " does not exist in odf"))
                    end
                end
            end
        end

    end


end
