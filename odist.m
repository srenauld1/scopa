function optout = odist(optin, mos, opt2)

% odist in matlab gives 'each'/'any' functionality (distribute all combos, ie any, within each mosc, ie each), but odist in python just gives 'any' (not 'each') functionality
% optin can be a mos, or a higher struct containing the mos (can't remember why i allowed this, but there is a reason, maybe because of how ored works after this)

arguments
    optin
    mos
    opt2.delimflat = []
end
opt2 = glboropt(opt2);
delimflat = opt2.delimflat;

if isfield(optin, mos)
    optin = optin.(mos);
end
fn = fieldnames(optin);

optout = struct;
for k = 1:numel(fn)
    mosctmp = fn{k};
    moscstruct = optin.(mosctmp);
    optflat = structflat(moscstruct, delim=delimflat); % prefix=mosctmp);
    fnflat = fieldnames(optflat);

    % if any(~cellfun(@isempty, regexp(fnflat,[delimflat '(\d+)' delimflat])))
    %     error("cannot use nonscalar structs in o")
    % end

    fnnew = [mosctmp '_' num2str(1)];
    tmp = [];
    tmp.(fnnew) = struct;

    optflatcex = struct2cell(optflat);
    expandinds = cellfun(@iscell, optflatcex) & cellfun(@(x) numel(x)>1, optflatcex);
    if any(expandinds)
        fnflatex = fnflat(expandinds);
        optflatcex = optflatcex(expandinds);
        for m = 1:numel(optflatcex)
            if ~isvector(optflatcex{m})
                error("optflatcex{m} must be vector")
            end
            dmtmp = find(size(optflatcex{m})==max(size(optflatcex{m})));
            optflatcex{m} = uniquearray(optflatcex{m}, dmtmp);
        end
        combos = combinations(optflatcex{:});
        for m = 1:size(combos,1)
            fnnew = [mosctmp '_' num2str(m)];
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
                fnnew = [mosctmp '_' num2str(p)];
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
    optout.(fn{k}) = structunflat(optout.(fn{k}), delim=delimflat);
end


end

