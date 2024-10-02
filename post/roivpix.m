function roivpix(resproi, stack, roipx, opt)

arguments
    resproi
    stack
    roipx
    opt.t = []
    opt.it = []
    opt.ir = []
    opt.yconst = 0
    opt.chan = 1
    opt.pthgif = []
end
it = opt.it;
ir = opt.ir;
t = opt.t;
chan = opt.chan;
pthgif = opt.pthgif;
yconst = opt.yconst;

if isempty(it)
    it = 1:size(stack, 4);
end
numsamp = numel(it);

if isempty(t)
    t = 1:numsamp;
end

if isempty(pthgif)
    pthgif = pthauto(vnm=pthgif, suffix='.gif', usetime=1, usefun=1);
end

stack = reshape(stack(:,:,:,it,chan), [], numsamp);
t = t(it);

if ~isa(resproi, 'single') %must be single or double for snr below
    resproi = single(resproi);
end
if ~isa(stack, 'single') %must be single or double for snr below
    stack = single(stack);
end

hfg = figure;
hax = axes('Parent', hfg);
cnt = 0;
for r = 1:size(resproi, 1)
    if ismember(r, ir)

        resproitmp = resproi(r,it);
        resppix = stack(roipx{r}, :);
        snrr = snr(resproitmp);
        ymin = min([resproi(:); resppix(:)]);
        ymax = max([resproi(:); resppix(:)]);

        for p = 1:size(resppix, 1)
            cnt = cnt+1;

            resppixtmp = resppix(p,:);
            snrp = snr(resppixtmp);

            if cnt==1
                hold(hax, 'on')
                yyaxis left
                hpl1 = plot(hax, t, resproitmp, 'b');
                yyaxis right
                hpl2 = plot(hax, t, resppixtmp, 'r');
                hold(hax, 'off')
                htx = title(hax, {['roi ' num2str(r) ' response (blue), pixel ' num2str(p) ' response (red)']; ['snr roi: ' num2str(snrr) ' snr pix: ' num2str(snrp)]});
            else
                hpl1.YData = resproitmp;
                hpl2.YData = resppixtmp;
                htx.String = {['roi ' num2str(r) ' response (blue), pixel ' num2str(p) ' response (red)']; ['snr roi: ' num2str(snrr) ' snr pix: ' num2str(snrp)]};
            end


            if yconst
                hax.YLim = [ymin ymax];
            end

            fig2gif(hfg, cnt, pthgif)

        end
    end
end