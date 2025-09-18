function [it, subt] = t2i(vt, t)

%{

output sample indices 'it' for input timestamp vector 'vt' using nearest-neighbor interpolation into vector of timestamps t
also output timestamps 'subt' forresponding to each sample index in 'it'

%}

arguments
    vt = [] %timestamp values to select from t; if empty, output it is all indices in t, and output subt=t
    t = [] %timestamps; if empty, tries to find t in glb; if doesn't exist there, error
end

if ~isempty(vt) && ( iscell(vt) || ~isvector(vt) )
    error("t must be empty or ordinary vector")
end
if ~isempty(t) && ( iscell(t) || ~isvector(t) )
    error("t must be empty or ordinary vector")
end

t_glb = glb('t');
if isempty(t)
    if isempty(t_glb)
        error("you must pass in t or set glb('t')")
    else
        t = t_glb;
    end
else
    if ~isempty(t_glb)
        if ~isequal(t, t_glb)
            error("you have set both name-value argument t and glb('t'), but they are not equal")
        end
    end
end

if isempty(vt)
    it = 1:numel(t);
else
    it = unique(interp1(t, 1:numel(t), vt, 'nearest'), 'stable');
    it = it(~isnan(it));
end

subt = t(it);

end
