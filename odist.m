function optout = odist(optin, vbin)


% odist in matlab gives 'each'/'any' functionality (distribute all combos, ie any, within each copybin, ie each), but odist in python just gives 'any' (not 'each') functionality
% optin can be a vbin, or a higher struct containing the vbin (can't remember why i allowed this, but there is a reason, maybe because of how ored works after this)

if isfield(optin, vbin)
    optin = optin.(vbin);
end
optin = copybinset(optin, vbin);
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



function optout = copybinset(opt, vbin, copybin)

% put a vbin from the options struct into a copybin
% if no copybin is passed as input, will use the default copybin (copybindf)
% if input opt is already a vbin within a copybin, nothing happens
% will error if apparently wrong struct is passed in (incorrect vbin, for example)
% this is very similar to one of the functions of odf, but this can deal
% with options structs that already have copybins; this function is really
% only used to make sure options struct is formatted correctly before it
% enters some functions, for example, to help prevent errors if the user
% passes in a nested options struct one level lower than it should be, this
% will create the higher level to prevent error downstream

arguments
    opt
    vbin
    copybin = []
end

copybin_glb = glb('copybindf');
if isempty(copybin)
    if isempty(copybin_glb)
        error("you must pass in copybin or set glb('copybindf')")
    else
        copybin = copybin_glb;
    end
else
    if ~isempty(copybin_glb)
        error("you cannot set both copybin and glb('copybindf')")
    end
end

lowered = 0;
if isequal(unique(fieldnames(opt)), {vbin})
    opt = opt.(vbin);
    lowered = 1;
end

for k = numel(opt):-1:1 %backwards to preallocate

    opttmp = opt(k);

    fn = fieldnames(opttmp);
    fndf = fieldnames(odf(vbin, unpack=1));
    fn_invalid = fn(~ismember(fn, fndf) & ~structfun(@isstruct, opttmp) & ~structfun(@isempty, opttmp));

    if ~isempty(fn_invalid) %if there are any fields that are not default, and are not structs, and are not empty, you may have the wrong vbin
        error("you must have passed in the wrong vbin")
    else
        if all(structfun(@isstruct, opttmp))
            opttmpnest = opttmp.(fn{1})(1); %in case it's nonscalar
            fnnest = fieldnames(opttmpnest);
            fn_invalid_nest = fnnest(~ismember(fnnest, fndf) & ~structfun(@isstruct, opttmpnest) & ~structfun(@isempty, opttmpnest));
            if isempty(intersect(fnnest, fndf))
                error("you must have passed in the wrong vbin within a copybin")
            end
            % if isempty(fn_invalid_nest)
            %     error("you must have passed in the intended vbin with the wrong name; like if opt.roi is correctly formatted but named opt.rois")
            % end
            optnew(k) = opttmp;
        else
            optnew.(copybin)(k) = opttmp;
        end
    end
end

if lowered
    optout.(vbin) = optnew;
else
    optout = optnew;
end

end