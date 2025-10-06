function ts = tscrop(kp, ts, opt)

arguments (Input)
    kp
end
arguments (Input, Repeating)
    ts
end
arguments (Input)
    opt.dm = []
end
arguments (Output, Repeating)
    ts
end

if isempty(opt.dm)
    opt.dm = 1;
    vecdim = 1; %treat indexing dimension dm as whichever defines vector for ts inputs  
else
    vecdim = 0; %error if indexing dimension dm is wrong 
end

maxnumdim = max(cellfun(@ndims, ts));
c = repmat({':'}, 1, maxnumdim);
c{opt.dm} = kp(:);
for k = 1:numel(ts)
    [~, mxdm] = max(size(ts{k}));
    if vecdim && isvector(ts{k}) && ~isequal(mxdm, opt.dm)
        ts{k} = transpose(ts{k});
    end
    ts{k} = ts{k}(c{:});
    if vecdim && isvector(ts{k}) && ~isequal(mxdm, opt.dm)
        ts{k} = transpose(ts{k});
    end
end

end