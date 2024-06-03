function out = smooth_timeseries(vartypein, inp, smoothwindow_sec, dt)

arguments
    vartypein char
    inp double
    smoothwindow_sec double
    dt double
end

smoothwindow = round(smoothwindow_sec / dt);

if size(inp, 2)>size(inp, 1)
    sprintf("warning, smoothing along first dim, which is smaller than second, be sure this is what you want")
end

if strcmp(vartypein, 'circular')

    tmpx = cos(inp);
    tmpy = sin(inp);
    tmpx = smoothdata(tmpx, 'gaussian', smoothwindow, 'omitnan');
    tmpy = smoothdata(tmpy, 'gaussian', smoothwindow, 'omitnan');
    out = atan2(tmpy, tmpx);

elseif strcmp(vartypein, 'normal')

    out = smoothdata(inp, 'gaussian', smoothwindow, 'omitnan');

elseif strcmp(vartypein, 'categorical')

    error("need to write categorical smooth (?)")

end
