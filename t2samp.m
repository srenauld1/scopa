function samp = t2samp(tsub, t)

arguments
    tsub = []
    t = []
end

t_glb = glb('t');
if isempty(t)
    if isempty(t_glb)
        error("you must pass t or set glb('t')")
    else
        t = t_glb;
    end
else
    if ~isempty(t_glb)
        error("you cannot set both t and glb('t')")
    end
end

if isempty(tsub)
    samp = 1:numel(t);
else
    samp = unique(interp1(t, 1:numel(t), tsub, 'nearest'), 'stable');
    samp = samp(~isnan(samp));
end

end
