
o = structflat(o);
fn = fieldnames(o);
for k = 1:numel(fn)
    if endsWith(fn{k}, 'doplt') %also remove all doplt, since that's irrelevant to the data processing
        o = rmfield(o, fn{k});
    end
end
o = structunflat(o);