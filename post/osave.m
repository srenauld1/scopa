function osave(o)

if numel(o)>1
    error("o must be scalar struct at this point (although it can contain nonscalar substructs)")
end

[pthpar, ~, ~] = fileparts(o.id.pth);
fnopt = [o.id.recid '_options_.txt'];
pthopt = fullfile(pthpar, fnopt);

structtxtsv(o, pthopt)

end
