function optout = odist(optin, vbin)

% odist in matlab gives 'each'/'any' functionality (distribute all combos, ie any, within each copybin, ie each), but odist in python just gives 'any' (not 'each') functionality
% optin can be a vbin, or a higher struct containing the vbin (can't remember why i allowed this, but there is a reason, maybe because of how ored works after this)

arguments
    optin
    vbin
end

if isfield(optin, vbin)
    optin = optin.(vbin);
end
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

    optflatcex = struct2cell(optflat);
    expandinds = cellfun(@iscell, optflatcex) & cellfun(@(x) numel(x)>1, optflatcex);
    if any(expandinds)
        fnflatex = fnflat(expandinds);
        optflatcex = optflatcex(expandinds);
        for m = 1:numel(optflatcex)
            if all(cellfun(@isnumeric,optflatcex{m}))
                optflatcex{m} = num2cell(unique(cellfun(@unique, optflatcex{m})));
            else
                optflatcex{m} = unique(optflatcex{m}); %make sure no accidental repeats
            end
        end
        combos = combinations(optflatcex{:});
        for m = 1:size(combos,1)
            fnnew = [copybintmp '_' num2str(m)];
            for mm = 1:numel(fnflatex)
                tmp.(fnnew).(fnflatex{mm}) = combos{m,mm}{1};
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

fn = fieldnames(optout);
for k = 1:numel(fn)
    optout.(fn{k}) = structunflat(optout.(fn{k}));
end


end

