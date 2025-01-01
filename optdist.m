function optout = optdist(optin)

% optdist in matlab gives each any functionality (distribute all combos,ie any, within each copybin, ie each), but optdist in python just gives any functionality

fn = fieldnames(optin);
optout = struct;
for k = 1:numel(fn)
    copybintmp = fn{k};
    copybinstruct = optin.(copybintmp);
    optflat = structflat(copybinstruct); % prefix=copybintmp);
    fnflat = fieldnames(optflat);

    % if any(~cellfun(@isempty, regexp(fnflat,[delim '(\d+)' delim])))
    %     error("cannot use nonscalar structs in o")
    % end

    fnnew = [copybintmp '_' num2str(1)];
    tmp = [];
    tmp.(fnnew) = struct;
    expandinds = zeros(numel(fnflat), 1, 'logical');
    for m = 1:numel(fnflat)
        tmpset = fieldnames(tmp);
        optidnums = numel(tmpset);
        tmpval = optflat.(fnflat{m});
        if isstring(tmpval) && numel(tmpval)>1
            error("string arrays are not allowed in vbin that can undergo expansion / optid mapping; strings must be scalar, or in cell arrays (to be expanded)")
        elseif iscell(tmpval) && numel(tmpval)>1
            expandinds(m) = 1;
            for w = 1:numel(tmpval)
                for p = 1:optidnums
                    newind = p+numel(optidnums)*(w-1);
                    fnnew = [copybintmp '_' num2str(newind)];
                    tmp.(fnnew).(fnflat{m}) = tmpval{w};
                end
            end
        end
    end
    tmpset = fieldnames(tmp);
    optidnums = numel(tmpset);
    for m = 1:numel(fnflat)
        if ~expandinds(m)
            for p = 1:optidnums
                fnnew = [copybintmp '_' num2str(p)];
                if iscell(optflat.(fnflat{m}))
                    tmp.(fnnew).(fnflat{m}) = optflat.(fnflat{m}){1}; %since singleton, take it out of cell
                else
                    tmp.(fnnew).(fnflat{m}) = optflat.(fnflat{m});
                end
            end
        end
    end

    optout = cell2struct([struct2cell(optout); struct2cell(tmp)], [fieldnames(optout); fieldnames(tmp)]); %combine
    optout = structsort(optout, vectype='row');

end