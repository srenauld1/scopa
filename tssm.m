function tsout = tssm(vtype, tsin, smlensec, sper)

% need to generalize this function for nd

arguments
    vtype {mustBeText}
    tsin
    smlensec
    sper
end

if ~ismember(vtype, {'normal', 'radians', 'degrees', 'categorical'})
    error("first argument must be 'normal', 'radians', 'degrees', or 'categorical'")
end

smlen = round(smlensec / sper);

if size(tsin, 2)>size(tsin, 1)
    sprintf("warning, smoothing along first dim, which is smaller than second, be sure this is what you want")
end

if strcmp(vtype, 'radians') || strcmp(vtype, 'degrees') 

    if strcmp(vtype, 'degrees')
        tsin = deg2rad(tsin);
    end

    tmpx = cos(tsin);
    tmpy = sin(tsin);
    tmpx = smoothdata(tmpx, 'gaussian', smlen, 'omitnan');
    tmpy = smoothdata(tmpy, 'gaussian', smlen, 'omitnan');
    tsout = atan2(tmpy, tmpx);

    if strcmp(vtype, 'degrees')
        tsout = rad2deg(tsout);
    end

elseif strcmp(vtype, 'normal')

    tsout = smoothdata(tsin, 'gaussian', smlen, 'omitnan');

elseif strcmp(vtype, 'categorical')

    error("need to write categorical smooth (?)")

end
