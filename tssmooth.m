function out = tssmooth(vartypein, inp, smlensec, dt)

arguments
    vartypein mustBeText
    inp
    smlensec
    dt
end

smlen = round(smlensec / dt);

if size(inp, 2)>size(inp, 1)
    sprintf("warning, smoothing along first dim, which is smaller than second, be sure this is what you want")
end

if strcmp(vartypein, 'circular')

    tmpx = cos(inp);
    tmpy = sin(inp);
    tmpx = smoothdata(tmpx, 'gaussian', smlen, 'omitnan');
    tmpy = smoothdata(tmpy, 'gaussian', smlen, 'omitnan');
    out = atan2(tmpy, tmpx);

elseif strcmp(vartypein, 'normal')

    out = smoothdata(inp, 'gaussian', smlen, 'omitnan');

elseif strcmp(vartypein, 'categorical')

    error("need to write categorical smooth (?)")

end
