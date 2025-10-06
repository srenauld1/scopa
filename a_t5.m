
close all
t5o = 'z99';
tmo = 'z100';
tmi = [1:4];
t5i = 2;

tinds = [4000:5000];
roi.(tmo).dat.ts(isinf(roi.(tmo).dat.ts)) = nan;
roi.(t5o).dat.ts(isinf(roi.(t5o).dat.ts)) = nan;
roi.(tmo).dat.ts = fillmissing(roi.(tmo).dat.ts, 'nearest', 2);
roi.(t5o).dat.ts = fillmissing(roi.(t5o).dat.ts, 'nearest', 2);

nt5 = size(roi.(t5o).dat.ts, 1);
ntm = size(roi.(tmo).dat.ts, 1);
hfg = figure;
hax = axes(Parent=hfg);
hplt5 = plot(hax, roi.(t5o).dat.ts(t5i,tinds));
yyaxis right
hold on
hpltm = plot(hax, roi.(tmo).dat.ts(tmi,tinds));
% hplv = plot(hax, rescale(fmf.CON_51(1,tinds), 0, 0.2));
cnt = 0;
% for q=4%1:nt5
%     hplt5.YData = rescale(roi.(t5o).dat.ts(q,tinds), 0, 1);
%     % hplt5.Parent.YLim(1) = 0;
%     % hplt5.Parent.YLim(2) = 0.3;
%     for k=1:ntm
%         cnt = cnt+1;
%         hpltm.YData = rescale(roi.(tmo).dat.ts(k,tinds), 0, 1);
%         % hpltm.Parent.YLim(2) = 0.3;
%         fig2gif(hfg, k)
%     end
% end