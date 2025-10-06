function opt = glboropt(opt)

fn = fieldnames(opt);
for k = 1:numel(fn)
    fntmp = fn{k};
    fn_glb = glb(fntmp);
    if isempty(opt.(fntmp))
        if isempty(fn_glb)
            %error("you have not set glb('" + fntmp + "'), and did not pass in name-value argument '" + fntmp + "'; you must do one or the other (not both)")
        else
            opt.(fntmp) = fn_glb;
        end
    else
        if ~isempty(fn_glb)
            if ~isequal(opt.(fntmp), fn_glb)
                error("cannot pass in name-value argument " + fntmp + " if you have already set glb('" + fntmp  + "') to a different value; do one or the other, or make them equal; if you want to remove glb('" + fntmp  + "'), do this: glb(-1, '" + fntmp + "')")
            end
        end
    end
end
