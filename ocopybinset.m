function optout = ocopybinset(optin, obin, opt2)

%{
--put a obin from the options struct into a copybin
--if no copybin is passed as input, will use the default copybin (copybindf)
--if input optin is already a obin within a copybin, nothing happens
--will error if apparently wrong struct is passed in (obin doesn't match optin, for example)
--if the user passes in a nested options struct one level lower than it should be, this function will create the higher level to prevent error downstream
--this is very similar to one of the functions of ofill, but this can deal
    with options structs that already have copybins; this function is really
    only used to make sure options struct is formatted correctly before it
    enters some other functions (odist, ored, structfile) to help prevent errors 
%}

arguments
    optin
    obin
    opt2.tsgetcall = [] %if tsgetcall, optin will never be in a copybin (since it is default options for specified obin, filled, with wildcards), and otree will need to be grabed from glb
    opt2.copybindf = []
end
opt2 = glboropt(opt2);
tsgetcall = opt2.tsgetcall;
copybindf = opt2.copybindf;

if isempty(copybindf)
    copybindf = 'none'; %in case neither opt2.copybindf nor glb('copybindf') were set
end

if tsgetcall
    copybin = {};
    otree = glb('otree'); %maybe don't put otree anywhere but glb? right now it's also in main oa struct, but we don't have access to that when this function is called from oid>tsget
else
    copybin = glb('copybin');
    otree = glb('otree'); %optin.mn.otree;
end

otree = otree(contains(otree, obin) & ~cellfun(@(x) isequal(x,obin), otree)); %remove otree not in this obin, and otree that match obin itself
otree = erase(otree, [obin '.']);
for k = 1:numel(otree)
    tmp = strsplit(otree{k}, '.');
    otree{k} = tmp{1}; %in case multiple nesting levels, just take first because we are looking for nests just under obin
end

if isfield(optin, obin)
    optin = optin.(obin);
end

unpacked = 0;
if isequal(unique(fieldnames(optin)), {obin})
    optin = optin.(obin);
    unpacked = 1;
end

for k = numel(optin):-1:1

    fn = fieldnames(optin(k));
    fndf = fieldnames(ofill(obin, unpack=1));
    fn_invalid = fn(~ismember(fn, fndf) & ~ismember(fn, copybin) & ~ismember(fn, otree) & ~structfun(@isempty, optin(k)));

    if any(ismember(fn, copybin) & ~structfun(@isstruct, optin(k)))
        error("copybin must be struct, but there is a copybin that is not a struct")
    end
    if any(ismember(fn, otree) & ~structfun(@isstruct, optin(k)))
        error("otree must be struct, but there is a otree that is not a struct")
    end
    if ~isempty(fn_invalid) %if there are any fields that are not default, and are not structs, and are not empty, you may have the wrong obin
        error("you must have passed in the wrong obin because there are nonempty fields that are neither default options nor copybin nor nested obin (otree)")
    end

    if all(ismember(fn, copybin)) %if all fields are copybin
        for q = 1:numel(fn)
            nested_obin = fn{1};
            opttmpnest = optin(k).(nested_obin)(1); %in case it's nonscalar, just take the first, all fields will be the same
            fnnest = fieldnames(opttmpnest);
            if isempty(intersect(fnnest, fndf))
                error("you must have passed in the wrong obin within a copybin")
            end
            fn_invalid_nest = fnnest(~ismember(fnnest, fndf) & ~ismember(fnnest, copybin) & ~ismember(fnnest, otree) & ~structfun(@isempty, opttmpnest));
            if ~isempty(fn_invalid_nest)
                error("you might have passed in the intended obin with the wrong name; for example, if opt.roi is correctly formatted but named opt.rois")
            end
            if q==numel(fn) 
                optnew(k) = optin(k);
            end
        end
    else
        if any(ismember(fn, copybin))
            if all( ismember(fn, fndf) | ismember(fn, otree) )
                error("in obin " + obin + ", some fields are copybin, and some are options or nested obins; obin fields must be all copybin or all options and/or nested obin; you may have passed in an empty copybin along with a nonempty copybin (for example rgname={'eb', []}); if you want the copybin to be empty, use value 'none'")
            else
                error("in obin " + obin + ", some fields are copybin, and some are something other than options or nested obins; obin fields must be all copybin or all options and/or nested obin;")
            end
        end
        optnew.(copybindf)(k) = optin(k);
    end
end

if unpacked
    optout.(obin) = optnew;
else
    optout = optnew;
end

end