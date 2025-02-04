function tsout = tssmooth(vtype, tsin, smlensec, dt)

arguments
    vtype mustBeText
    tsin
    smlensec
    dt
end

smlen = round(smlensec / dt);

if size(tsin, 2)>size(tsin, 1)
    sprintf("warning, smoothing along first dim, which is smaller than second, be sure this is what you want")
end

if strcmp(vtype, 'circular')

    tmpx = cos(tsin);
    tmpy = sin(tsin);
    tmpx = smoothdata(tmpx, 'gaussian', smlen, 'omitnan');
    tmpy = smoothdata(tmpy, 'gaussian', smlen, 'omitnan');
    tsout = atan2(tmpy, tmpx);

elseif strcmp(vtype, 'normal')

    tsout = smoothdata(tsin, 'gaussian', smlen, 'omitnan');

elseif strcmp(vtype, 'categorical')

    error("need to write categorical smooth (?)")

end
