function optout = odist(optin)

%{

for each substruct within struct optin . . . 
for any cell-valued field (option) . . . 
create new struct for each cell element ('distribute')
    copy non-cell fields (options) to all new structs
    give temporary names to the new structs and delete the original struct
    if there are multiple cell-valued fields (options), create all combinations of their elements with the new structs
odist.m is similar to odist.py; the main difference is:
    odist.m has 'any'/'each' functionality: distribute options ('any') within each mosc ('each') 
    odist.py just has 'any' functionality (not 'each')

%}

arguments
    optin
end

delimflat = '__';

fn = fieldnames(optin);

optout = struct;
for k = 1:numel(fn)
    mosctmp = fn{k};
    moscstruct = optin.(mosctmp);
    optflat = structflat(moscstruct, delim=delimflat); % prefix=mosctmp);
    fnflat = fieldnames(optflat);

    % if any(~cellfun(@  , regexp(fnflat,[delimflat '(\d+)' delimflat])))
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

