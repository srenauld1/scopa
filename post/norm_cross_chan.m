
function resp1 = norm_cross_chan(resp1, resp2, opt)

arguments
    resp1
    resp2
    opt.t = 1:size(resp1,2)
    opt.it = 1:size(resp1,2)
    opt.roiind = 1:size(resp1,1)
    opt.pthgifpre = ''
    opt.mincoh = 0.7
end

t = opt.t;
it = opt.it;
roiind = opt.roiind;
pthgifpre = opt.pthgifpre;
mincoh = opt.mincoh;

for ri = 1:numel(roiind)
    resp1(ri,it) = normcrosschan_oneroi(resp1(roiind,it),resp2(roiind,it),t(it),pthgifpre,mincoh);
end


end

function respnew = normcrosschan_oneroi(resp1,resp2,t,pthgifpre,mincoh)

titlein = '';
yconst = 1;
ylim_padfac = 0.1;
ls1 = '-k';
ls2 = '-r';
match_ylim = 0;
maxseg = 128;

plotstring = 'hertz';

if ~isa(resp1, 'double')
    resp1 = double(resp1);
end
if ~isa(resp2, 'double')
    resp2 = double(resp2);
end
if ~isa(t, 'double')
    t = double(t);
end

numsamp = numel(resp1);
fs = 1/median(diff(t));
lev = floor(log2(numsamp));

fngif = [pthgifpre(1:end-4) 'resp_mra_.gif'];

%% set up wavelet filters using the default used in wsst, but not wcoherence

num_voices_per_octave = 32; %12 default in wcoherence, 32 default in wsst
numoct = floor(log2(numsamp))-1;
wname = 'amor'; %'amor' default in wcoherence and wsst
normalizedfreq = 0;

[~,maxf] = cwtfreqbounds(numsamp,fs,'Wavelet',wname,'VoicesPerOctave',num_voices_per_octave);
minf = 2^(-numoct)*maxf;
flim = [minf maxf];

fb = cwtfilterbank(SignalLength=numel(resp1), Wavelet='amor', VoicesPerOctave=num_voices_per_octave, SamplingFrequency=fs, FrequencyLimits=flim, Boundary='reflection');
[FourierFactor,sigmaT] = wavCFandSD_cw(fb.Wavelet);

%% filter using wavelet coherence from wsst 

%default doesn't use same filterbank as wsst and wcoherence_cw, so will be a little dfferent 
[wcoh,wcs,wf,coi,wtx,wty] = wcoherence(resp1, resp2, fs);
plot_coh_freq(wcoh,wcs,FourierFactor,sigmaT,wf,t,num_voices_per_octave,mincoh,normalizedfreq); %plot should look like figure; wcoherence(resp1, resp2, fs);
% plot_coh_period(wcoh,wcs,wf,t,coi,num_voices_per_octave,mincoh,plotstring)

%%why is cwt manual version failing??
% [wtx2, cwtf] = cwt(resp1, FilterBank=fb);
% plot_wt_freq(wtx2, t, cwtf, coi) %should look like figure;cwt(resp1, FilterBank=fb);
% 
% [wty2, ~] = cwt(resp2, FilterBank=fb);
% plot_wt_freq(wtx2, t, cwtf, coi) %should look like figure;cwt(resp1, FilterBank=fb);
% 
% [wcoh_man, wcs_man] = wcoherence_cw(wtx2, wty2, fb.Scales, fb.VoicesPerOctave);
% plot_coh_freq(wcoh_man,wcs_man,FourierFactor,sigmaT,fb.Scales,t,num_voices_per_octave,mincoh,normalizedfreq); %plot should look like figure; wcoherence(resp1, resp2, fs);
% subind = 270:numel(fb.Scales);subindt = 1:100; plot_coh_freq(wcoh_man(subind,subindt),wcs_man(subind,subindt),FourierFactor,sigmaT,fb.Scales(subind),t(subindt),num_voices_per_octave,mincoh,normalizedfreq); %plot should look like figure; wcoherence(resp1, resp2, fs);
% % plot_coh_period(wcoh_man,wcs_man,wf,t,coi,num_voices_per_octave,mincoh,plotstring)


[wsstx, wsstf] = wsst(resp1, fs); %try ExtendSignal=true
[wssty, ~] = wsst(resp2, fs);

plot_wt_freq(wsstx, t, wsstf) %no coi output from wsst; should look like figure;cwt(resp1, FilterBank=fb); does except frequency scale is log

[wsstcoh_man, wsstcs_man] = wcoherence_cw(wsstx, wssty, wsstf, fb.VoicesPerOctave);
plot_coh_freq(wsstcoh_man,wsstcs_man,FourierFactor,sigmaT,wsstf,t,num_voices_per_octave,mincoh,normalizedfreq); %plot should look like figure; wcoherence(resp1, resp2, fs);

th = angle(wsstcs_man);

ffrng = [1 2.5];
badf = wsstf<ffrng(2) & wsstf>ffrng(1);
badco = wsstcoh_man > mincoh;
badang = abs(th) < pi/16;
badcf = repmat(badf', [1 numsamp]) & badco & badang;
subindt = 1:100; 
plot_coh_freq(wsstcoh_man(badf,subindt),wsstcs_man(badf,subindt),FourierFactor,sigmaT,wsstf(badf),t(subindt),num_voices_per_octave,mincoh,normalizedfreq); %plot should look like figure; wcoherence(resp1, resp2, fs);
% plot_coh_period(wsstcoh_man,wsstcs_man,seconds(wf),t,seconds(coi),num_voices_per_octave,mincoh,plotstring)

figure; imagesc(badco(badf,subindt))
figure; imagesc(badang(badf,subindt))
figure; imagesc(badcf(badf,subindt))

wsstx(badcf) = 0;
respnew = iwsst(wsstx)+mean(resp1);

% badco = wcoh > mincoh;
% badco = wcoh > mincoh & (abs(th) < pi/16 | abs(th) < pi/16); %motion affecting both channels should be in-phase or antiphase (one channel gets brighter, another gets brighter or darker at similar rate and time) 
% respnew = icwt(wtx,SignalMean=mean(resp1));
% prange = seconds([wf(1) wf(end)]);
% respnew = icwt(wtx, [], wf, prange, SignalMean=mean(resp1));

plotinds = 1:100;
figure; hold on; 
plot(resp1(plotinds), 'k'); ylim([0 1])
plot(respnew(plotinds), 'b'); 
yyaxis right; hplr = plot(resp2(plotinds), 'r'); ylim([0 1]); hplr.Parent.YAxis(2).Color =  'r';

%% modwt

% w = modwt(resp1,lev); %decompose into lev(k) subbands
% mra = modwtmra(w); %multiresolution analysis
% 
% w2 = modwt(resp2,lev); %decompose into lev(k) subbands
% mra2 = modwtmra(w2); %multiresolution analysis
% 
% 
% for m = 1:size(mra,1)
% 
%     cfs = w;
%     rem = [1 5:13];
%     cfs(rem,:) = 0; %set approximation coefficients for level lev to zero
%     respnew2 = imodwt(cfs); % inverse modwt with zeroed coeffs to remove trend
% 
%     if m==1
%         hfg = figure( 'Units', 'Normalized');
%         hax = axes('Parent', hfg, 'Units', 'Normalized', 'Position',[0.1 0.6 0.85 0.35]);
%         hold(hax, 'on')
%         yyaxis left
%         hpl1 = plot(hax, t, resp1, 'k-');
%         hpl2 = plot(hax, t, respnew, 'r-');
%         yyaxis right
%         hpl3 = plot(hax, t, mra(m,:), 'b-');
%         hpl4 = plot(hax, t, mra(m,:)+mean(mra(m,:)), 'c-');
%         hold(hax, 'off')
%         hax.YAxis(1).Color = 'k';
%         hax.YAxis(2).Color = 'b';
%         hax2 = axes('Parent', hfg, 'Units', 'Normalized', 'Position',[0.1 0.1 0.85 0.35]);
%         hold(hax2, 'on')
%         yyaxis left
%         % hpl21 = plot(hax2, t, resp1, 'k-');
%         % hpl22 = plot(hax2, t, resp2, 'r-');
%         yyaxis right
%         hpl23 = plot(hax2, t, w(m,:), 'b-');
%         hpl24 = plot(hax2, t, w2(m,:), 'c-');
%         hold(hax2, 'off')
%         hax2.YAxis(1).Color = 'k';
%         hax2.YAxis(2).Color = 'b';
%     else
%         hpl2.YData = respnew;
%         % hpl3.YData = mra(m,:);
%         % hpl4.YData = mra(m,:)+mean(mra(m,:)); %don't apply plotinds when computing the mean
%         hpl23.YData = w(m,:);
%         hpl24.YData = w2(m,:);
%     end
%     hax.Title.String = ['lev ' num2str(lev) ', mra ' num2str(m) ', chan 1 sig (black) & recon (red), approx blue, approx cent. cyan)'];
%     hax2.Title.String = ['lev ' num2str(lev) ', mra ' num2str(m) ', chan 1 & 2 coeffs blue & cyan'];
%     % hax2.Title.String = ['chan 1 (black) & 2(red), lev ' num2str(lev) ', mra ' num2str(m) ', coeffs blue & cyan'];
% 
%     fig2gif(hfg,m,fngif)
% 
% 
%     wlen = ceil(numsamp./2.^(size(mra,1)-m));
%     numseg = ceil(numsamp/wlen);
%     numseg(numseg>maxseg) = maxseg;
% 
%     % fngif2 = [pthgifpre(1:end-4) 'resp_mracoeffs_' num2str(m) '_.gif'];
%     % tsplt(w(m,:), w2(m,:), fngif2, numseg, titlein, yconst, ylim_padfac, ls1, ls2, match_ylim)
% 
%     fngif3 = [pthgifpre(1:end-4) 'resp_rec_' num2str(m) '_.gif'];
%     tsplt(resp1, respnew, fngif3, numseg, titlein, yconst, ylim_padfac, ls1, ls2, match_ylim)
% 
% 
% end

end


function plot_wt_period(wt, t, period, coi)

figure;
h = pcolor(t,log2(period),abs(wt));
h.EdgeColor = "none";
ax = gca;
% ytick=round(pow2(ax.YTick),3);
ytick=round(ax.YTick,3);
ax.YTickLabel=ytick;
ax.XLabel.String="Time";
ax.YLabel.String="Period (seconds)";
ax.Title.String = "cwt";
hcol = colorbar;
hcol.Label.String = "Magnitude";
hold on
plot(ax,t,log2(coi),"w--",linewidth=2)
hold off

end



function plot_wt_freq(wt, t, f, coi)

figure;
h = pcolor(t,f,abs(wt));
shading interp
h.EdgeColor = "none";
ax = gca;
ytick=round(pow2(ax.YTick),3);
ax.YTickLabel=ytick;
ax.XLabel.String="Time";
ax.YLabel.String="frequency (Hz)";
ax.Title.String = "cwt";
hcol = colorbar;
hcol.Label.String = "Magnitude";
hold on
if exist('coi', 'var') && ~isempty(coi)
    plot(ax,t,log2(coi),"w--",linewidth=2)
end
hold off

end
