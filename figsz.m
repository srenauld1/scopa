function szf = figsz(sz)

% get fig width, height in pixels given scalar input sz

arguments
    sz = 1 %scalar denoting fig size; 0-1 makes square until 1 makes largest square fig for your screen, 1-2 fills larger dimension until 2 is fullscreen
end


[dms,arat] = pxscreenget();

szf = dms;
if sz<=1
    szf(szf==min(szf)) = szf(szf==min(szf))*sz;
    szf(szf==max(szf)) = szf(szf==max(szf))/arat*sz;
else
    aratrng = range(szf);
    if sz==2
        rmdr = 1;
    else
        rmdr = mod(sz,1);
    end
    szf(szf==max(szf)) = min(szf)+rmdr*aratrng;
end
