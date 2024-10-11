function fig2gif(hfg, framecount, pthgif, ncol)

arguments
    hfg
    framecount
    pthgif = '';
    ncol = 128
end

if isempty(pthgif)
    pthgif = pthauto(suffix='.gif', usetime=1);
end

frame = getframe(hfg);
im = frame2im(frame);
[imind, cm] = rgb2ind(im, ncol);

if framecount==1
    imwrite(imind, cm, pthgif, 'DelayTime', 0, 'Loopcount', inf);
else
    imwrite(imind, cm, pthgif,'DelayTime', 0, 'WriteMode', 'append');
end