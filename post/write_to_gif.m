function fig2gif(hfg, framecount_gif, filename_save, ncolgif)

if ~exist('ncolgif', 'var')
    ncolgif = 128;
end

frame = getframe(hfg);
im = frame2im(frame);
[imind, cm] = rgb2ind(im, ncolgif);

if framecount_gif==1
    imwrite(imind, cm, filename_save, 'DelayTime', 0, 'Loopcount', inf);
else
    imwrite(imind, cm, filename_save,'DelayTime', 0, 'WriteMode', 'append');
end