function out = cx_smooth_circular_var(inp, smoothwindow)

tmpx = cos(inp);
tmpy = sin(inp);
tmpx = smoothdata(tmpx, 'gaussian', smoothwindow, 'omitnan');
tmpy = smoothdata(tmpy, 'gaussian', smoothwindow, 'omitnan');
out = atan2(tmpy, tmpx);

