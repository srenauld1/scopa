function fig2gif(hfg, framecount, pthgif, ncol)

arguments
    hfg
    framecount = 1
    pthgif = '';
    ncol = 128
end


persistent pthtmp
if isempty(pthgif)
    if framecount==1
        pthtmp = [];
    end
    if isempty(pthtmp)
        pthtmp = pthauto(suffix='.gif', usetime=1);
    end
    pthgif = pthtmp;
end

frame = getframe(hfg);
im = frame2im(frame);
[imind, cm] = rgb2ind(im, ncol);

if framecount==1
    imwrite(imind, cm, pthgif, 'DelayTime', 0, 'Loopcount', inf);
else
    imwrite(imind, cm, pthgif,'DelayTime', 0, 'WriteMode', 'append');
end