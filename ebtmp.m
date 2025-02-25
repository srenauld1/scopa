
cue = daq.vy;
bump = bmp.a1.mu;
eb = bmp.a1.respcl;
bumpnan = polarnan(bump);
cue = polarnan(cue);

hfg = figure;
hax = axes(Parent=hfg);
imagesc(hax, eb);
colormap(gray(256));
hold on;
plot(hax, rescale(bumpnan, 1, size(eb,1)), 'r')
plot(hax, rescale(cue, 1, size(eb,1)), 'b')

pthpre = [erase(pth.stack, '.mat') optid '_bmp_'];

pthsv = [pthpre 'bump_.fig'];
saveas(gcf, pthsv)