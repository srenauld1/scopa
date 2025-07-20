function opt = glboropt(opt)

fn = fieldnames(opt);
for k = 1:numel(fn)
    fntmp = fn{k};
    glbtmp = glb(fntmp);
    if isempty(opt.(fntmp))
        if isempty(glbtmp)
            %error("you have not set glb('" + fntmp + "'), and did not pass in name-value argument '" + fntmp + "'; you must do one or the other (not both)")
        else
            opt.(fntmp) = glbtmp;
        end
    else
        if ~isempty(glbtmp)
            error("cannot pass in name-value argument " + fntmp + " if you have already set glb('" + fntmp  + "'); do one or the other; if you want to remove glb('" + fntmp  + "'), do this: glb(-1, '" + fntmp + "')")
        end
    end
end
