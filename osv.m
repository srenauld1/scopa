function osv(o)

% save scalar options struct output by oset/ofill 

if numel(o)>1
    error("o must be scalar struct at this point (although it can contain nonscalar substructs)")
end
    
if ~isfield(o, 'finished') || o.full~=1
    error("options struct must be 'finished'; you may have removed final call to ofill in oset with argument rec=1")
end

fnopt = [o.id.recid '_opt_.txt'];
pthopt = fullfile(o.id.pthstackdir, fnopt);

structsv(o, pthopt, overwrite=1, readonly=1, dosort=1)

end
