function osv(o)

% save scalar options struct output by oset/odf 

if numel(o)>1
    error("o must be scalar struct at this point (although it can contain nonscalar substructs)")
end
    
if ~isfield(o, 'filled') || o.filled~=1
    error("options struct must be 'filled'; you may have removed final call to odf in oset with argument fill=1")
end

fnopt = [o.id.recid '_options_.txt'];
pthopt = fullfile(o.id.dirstack, fnopt);

structtxtsv(o, pthopt, overwrite=1, readonly=1)

end
