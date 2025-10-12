function optout = moscset(o, mos, mostree, opt)

%{
--put a mos from the options struct into a mosc
--if no mosc is passed as input, will use the default mosc (moscdf)
--if input o is already a mos within a mosc, nothing happens
--will error if apparently wrong struct is passed in (mos doesn't match o, for example)
--if the user passes in a nested options struct one level lower than it should be, this function will create the higher level to prevent error downstream
--this is very similar to one of the functions of ofill, but this can deal
    with options structs that already have mosc; this function is really
    only used to make sure options struct is formatted correctly before it
    enters some other functions (odist, ored, structfile) to help prevent errors 
%}

arguments
    o
    mos
    mostree
    opt.tsgetcall = [] %if tsgetcall, o will never be in a mosc (since it is default options for specified mos, filled, with wildcards), and mostree will need to be grabed from glb
end
opt = glboropt(opt);
tsgetcall = opt.tsgetcall;

moscdf = 'none'; %in case neither opt.moscdf nor glb('moscdf') were set

if tsgetcall
    mosc = {};
else
    mosc = glb('mosc');
    if ~isempty(mosc)
        mosc = mosc(:,2);
    end
end

mostree = mostree(startsWith(mostree, mos) & ~cellfun(@(x) isequal(x,mos), mostree)); %remove mostree not in this mos, and mostree that match mos itself
mostree = erase(mostree, [mos '.']);
for k = 1:numel(mostree)
    tmp = strsplit(mostree{k}, '.');
    mostree{k} = tmp{1}; %in case multiple nesting levels, just take first because we are looking for nests just under mos
end

if isfield(o, mos)
    o = o.(mos);
end

unpacked = 0;
if isequal(unique(fieldnames(o)), {mos})
    o = o.(mos);
    unpacked = 1;
end

for k = numel(o):-1:1

    fn = fieldnames(o(k));
    fndf = fieldnames(ofill(mos, unpack=1));
    fn_invalid = fn(~ismember(fn, fndf) & ~ismember(fn, mosc) & ~ismember(fn, mostree) & ~structfun(@isemptyall, o(k)));

    if ~isempty(fn_invalid) %if there are any fields that are not default, and are not structs, and are not empty, you may have the wrong mos
        error("you must have passed in the wrong mos because there are nonempty fields that are neither default options nor mosc nor nested mos (mostree)")
    end
    if any(ismember(fn, mosc) & ~structfun(@isstruct, o(k)))
        error("mosc must be struct, but there is a mosc that is not a struct")
    end

    if all(ismember(fn, mosc)) %if all fields are mosc
        for q = 1:numel(fn)
            nested_mos = fn{1};
            opttmpnest = o(k).(nested_mos)(1); %in case it's nonscalar, just take the first, all fields will be the same
            fnnest = fieldnames(opttmpnest);
            if isempty(intersect(fnnest, fndf))
                error("you must have passed in the wrong mos within a mosc")
            end
            fn_invalid_nest = fnnest(~ismember(fnnest, fndf) & ~ismember(fnnest, mosc) & ~ismember(fnnest, mostree) & ~structfun(@isempty, opttmpnest));
            if ~isempty(fn_invalid_nest)
                error("you might have passed in the intended mos with the wrong name; for example, if opt.roi is correctly formatted but named opt.rois")
            end
            if q==numel(fn) 
                optnew(k) = o(k);
            end
        end
    else
        if any(ismember(fn, mosc))
            if all( ismember(fn, fndf) | ismember(fn, mostree) )
                error("in mos " + mos + ", some fields are mosc, and some are options or nested mos; mos fields must be all mosc or all options and/or nested mos; you may have passed in an empty mosc along with a nonempty mosc (for example rgname={'eb', []}); if you want the mosc to be empty, use value 'none'")
            else
                error("in mos " + mos + ", some fields are mosc, and some are something other than options or nested mos; mos fields must be all mosc or all options and/or nested mos;")
            end
        end
        optnew.(moscdf)(k) = o(k);
    end
end

if unpacked
    optout.(mos) = optnew;
else
    optout = optnew;
end

end