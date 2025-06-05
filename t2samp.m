function samp = t2samp(tsub, t)

arguments
    tsub = []
    t = []
end

if isempty(t)
    t = glb('t');
    if isempty(t)
        error("must pass in t or set glb('t')")
    end
end

if isempty(tsub)
    samp = 1:numel(t);
else
    samp = unique(interp1(t, 1:numel(t), tsub, 'nearest'), 'stable');
    samp = samp(~isnan(samp));
end

end
