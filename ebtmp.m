
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




epochtmp = 6; 
inc = 5;
te2 = find(daq.a3.epochts==epochtmp);
te2 = te2(1):te2(find(diff(te2)~=1, 1)); %one bout of epoch epochtmp . . . 
te2 = [te2(1)-numel(te2):te2(end)]; % . . . and preceding bout of closed loop
te2 = te2(1) : inc : te2(end);
stackplt3(stack, it=te2, style='MaximumIntensityProjection')


            o.mdl.(m{1}).indv.tg=[];
            o.mdl.(m{1}).depv.tg=[];

            bmpmu = bmp.a1.mu;
            bmpvel = tsdv('radians', bmpmu, 0.2, 2, md.sper);
            ballyaw = daq.a1.by;
            ballvel = tsdv('radians', -ballyaw, 0.2, 2, md.sper);
            cueyaw = daq.a1.vy;
            cuevel = tsdv('radians', cueyaw, 0.2, 2, md.sper);

            indv = [ballvel; bmpvel];
            indv = [ballvel; cuevel];
            % indv = [ballvel; cueyaw];
            %indv = [ballyaw; cueyaw];
            % indv = [ballvel];
            % indv = [ballyaw; cueyaw];

            noresp = roi.a2.ts{1};
            noz = zscore(noresp);
            % nodv = tsdv('normal', noresp, 0.2, 2, md.sper);
            % nozdv = tsdv('normal', noz, 0.2, 2, md.sper);
            depv = noz;
            % depv = nozdv;


            o.mdl.(m{1}).epochnum = [2 3 4 5];
            o.mdl.(m{1}).mdlname = 'svd_0.9999999';
            o.mdl.(m{1}).mdlname = 'fnet_A01_v_A02_v_B_f';
            o.mdl.(m{1}).mdlname = 'svd_0.9';
            o.mdl.(m{1}).lensec = 0.5;
            o.mdl.(m{1}).lagsec = 0;
            o.mdl.(m{1}).valnum = 1;
            o.mdl.(m{1}).opl.MaxFunctionEvaluations = Inf;
            o.mdl.(m{1}).opl.MaxIterations = Inf;
            dopltmdl = 1;
            ldval = 0;
            mdl.(m{1}) = mdlmake(o.mdl.(m{1}), indv, depv, pth.stack, md.volrate, daq.a1.epochts, dopltmdl, ldval);
