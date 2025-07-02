function stack = stackthr(stack, mthd)

arguments
    stack
    mthd = []
end

if isempty(mthd)
    mthd = 'tri';
end

idx = stack~=0;

switch mthd
    case 'tri'
        [histdt, histx] = hist( stack(idx), 1000);
        thrbin_tri = triangle_threshold(histdt, 'R', 1); %last arg 1 to plot
        thr = histx(thrbin_tri);

    case 'knee'
        [~, thrbin_knee] = knee_pt(stack, [], 1, 1);
        thr = stack(thrbin_knee);
end

stack(stack<thr) = 0;