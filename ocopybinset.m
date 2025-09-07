function optout = ocopybinset(optin, vbin, opt2)

%{
--put a vbin from the options struct into a copybin
--if no copybin is passed as input, will use the default copybin (copybindf)
--if input optin is already a vbin within a copybin, nothing happens
--will error if apparently wrong struct is passed in (vbin doesn't match optin, for example)
--if the user passes in a nested options struct one level lower than it should be, this function will create the higher level to prevent error downstream
--this is very similar to one of the functions of odf, but this can deal
    with options structs that already have copybins; this function is really
    only used to make sure options struct is formatted correctly before it
    enters some other functions (odist, ored, structfile) to help prevent errors 
%}

arguments
    optin
    vbin
    opt2.copybindf = []
end
opt2 = glboropt(opt2);
copybindf = opt2.copybindf;

if isempty(copybindf)
    error("you must pass in copybindf or set glb('copybindf')")
end

copybin = optin.copybin;
nestvalid = optin.nestvalid;

nestvalid = nestvalid(contains(nestvalid, vbin) & ~cellfun(@(x) isequal(x,vbin), nestvalid)); %remove nestvalid not in this vbin, and nestvalid that match vbin itself
nestvalid = erase(nestvalid, [vbin '.']);
for k = 1:numel(nestvalid)
    tmp = strsplit(nestvalid{k}, '.');
    nestvalid{k} = tmp{1}; %in case multiple nesting levels, just take first because we are looking for nests just under vbin
end

if isfield(optin, vbin)
    optin = optin.(vbin);
end

unpacked = 0;
if isequal(unique(fieldnames(optin)), {vbin})
    optin = optin.(vbin);
    unpacked = 1;
end

for k = numel(optin):-1:1

    fn = fieldnames(optin(k));
    fndf = fieldnames(odf(vbin, unpack=1));
    fn_invalid = fn(~ismember(fn, fndf) & ~ismember(fn, copybin) & ~ismember(fn, nestvalid) & ~structfun(@isempty, optin(k)));

    if any(ismember(fn, copybin) & ~structfun(@isstruct, optin(k)))
        error("copybin must be struct, but there is a copybin that is not a struct")
    end
    if any(ismember(fn, nestvalid) & ~structfun(@isstruct, optin(k)))
        error("nestvalid must be struct, but there is a nestvalid that is not a struct")
    end
    if ~isempty(fn_invalid) %if there are any fields that are not default, and are not structs, and are not empty, you may have the wrong vbin
        error("you must have passed in the wrong vbin because there are nonempty fields that are neither default options nor copybin nor nested vbin (nestvalid)")
    end

    if all(ismember(fn, copybin)) %if all fields are copybin
        for q = 1:numel(fn)
            nested_vbin = fn{1};
            opttmpnest = optin(k).(nested_vbin)(1); %in case it's nonscalar, just take the first, all fields will be the same
            fnnest = fieldnames(opttmpnest);
            if isempty(intersect(fnnest, fndf))
                error("you must have passed in the wrong vbin within a copybin")
            end
            fn_invalid_nest = fnnest(~ismember(fnnest, fndf) & ~ismember(fnnest, copybin) & ~ismember(fnnest, nestvalid) & ~structfun(@isempty, opttmpnest));
            if ~isempty(fn_invalid_nest)
                error("you might have passed in the intended vbin with the wrong name; for example, if opt.roi is correctly formatted but named opt.rois")
            end
            if q==numel(fn) 
                optnew(k) = optin(k);
            end
        end
    else
        if any(ismember(fn, copybin))
            if all( ismember(fn, fndf) | ismember(fn, nestvalid) )
                error("in vbin " + vbin + ", some fields are copybin, and some are options or nested vbins; vbin fields must be all copybin or all options and/or nested vbin; you may have passed in an empty copybin along with a nonempty copybin (for example rgname={'eb', []}); if you want the copybin to be empty, use value 'none'")
            else
                error("in vbin " + vbin + ", some fields are copybin, and some are something other than options or nested vbins; vbin fields must be all copybin or all options and/or nested vbin;")
            end
        end
        optnew.(copybindf)(k) = optin(k);
    end
end

if unpacked
    optout.(vbin) = optnew;
else
    optout = optnew;
end

end