function o = moscset(o, mos)

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
end

moscdf = 'none'; %in case neither opt.moscdf nor glb('moscdf') were set

pthoptdf = [pthscopaget() 'optdf.txt'];
dall = structld(pthoptdf, nocells=1, dosort=0);
mostree = dall.mostree;
du = dall.du;
fndf = fieldnames(du.(mos));

mostree = mostree(startsWith(mostree, mos) & ~cellfun(@(x) isequal(x,mos), mostree)); %remove mostree not in this mos, and mostree that match mos itself
mostree = erase(mostree, [mos '.']);
for k = 1:numel(mostree)
    tmp = strsplit(mostree{k}, '.');
    mostree{k} = tmp{1}; %in case multiple nesting levels, just take first because we are looking for top-level submos
end

o = o.(mos);

fn = fieldnames(o);
fn_invalid = fn(~ismember(fn, fndf) & ~ismember(fn, mostree) & ~structfun(@isemptyall, o) & ~structfun(@isstruct, o));
if ~isempty(fn_invalid) %if there are any fields that are not default, and are not structs, and are not empty, you may have the wrong mos
    error("you must have passed in the wrong mos because there are nonempty fields that are neither default options nor mosc nor nested mos (mostree)")
end

if all(structfun(@isstruct, o)) %if all fields are structs
    for k = 1:numel(fn)
        nested_mos = fn{k};
        opttmpnest = o.(nested_mos);
        fnnest = fieldnames(opttmpnest);
        if isempty(intersect(fnnest, fndf))
            error("you must have passed in the wrong mos within a mosc")
        end
        fnnest_invalid = fnnest(~ismember(fnnest, fndf) & ~ismember(fnnest, mostree) & ~structfun(@isemptyall, opttmpnest) & ~structfun(@isstruct, opttmpnest));
        if ~isempty(fnnest_invalid) %if there are any fields that are not default, and are not structs, and are not empty, you may have the wrong mos
            error("you must have passed in the wrong mos because there are nonempty fields that are neither default options nor mosc nor nested mos (mostree)")
        end
    end
else
    o.(moscdf) = o;
    o = rmfield(o, fn);
end

end