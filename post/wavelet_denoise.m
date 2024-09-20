
function resp1 = wavelet_denoise(resp1, opt)

arguments
    resp1
    opt.t = 1:size(resp1,2)
    opt.it = 1:size(resp1,2)
    opt.roiind = 1:size(resp1,1)
    opt.pthgifpre = ''
end

t = opt.t;
it = opt.it;
roiind = opt.roiind;
pthgifpre = opt.pthgifpre;

%% mostly default right now

numsamp = size(resp1,2);

if ~isa(t, 'double')
    t = double(t);
end

fs = 1/median(diff(t));

num_voices_per_octave = 12; %12 default in wcoherence, 32 default in wsst
numoct = floor(log2(numsamp))-1;
wname = 'morse'; %'amor' default in wcoherence and wsst

[~,maxf] = cwtfreqbounds(numsamp,fs,'Wavelet',wname,'VoicesPerOctave',num_voices_per_octave);
minf = 2^(-numoct)*maxf;
flim = [minf maxf];


fb = cwtfilterbank(SignalLength=numsamp, Wavelet='Morse', VoicesPerOctave=num_voices_per_octave, SamplingFrequency=fs, FrequencyLimits=flim, Boundary='reflection');
% [FourierFactor,sigmaT] = wavCFandSD_cw(fb.Wavelet);


for ri = 1:numel(roiind)
    resp1(ri,it) = wavelet_denoise_oneroi(resp1(roiind(ri),it),t(it),fb,fs,wname,pthgifpre);
end


end

function respnew = wavelet_denoise_oneroi(resp1,t,fb,fs,wname,pthgifpre)

numseg = 10;
constant_ylim = 1;
ylim_padfac = 0.1;
ls1 = '-k';
ls2 = '-r';
match_ylim = 0;
gif_visibility = 'on';

if ~isa(resp1, 'double')
    resp1 = double(resp1);
end


fngif = [pthgifpre 'resp_mra_.gif'];

%% transform

dodetrend = 1;

if dodetrend

    frng = [nan nan];
    prng = [nan nan];

else

    % [wt, wtf, coi] = cwt(resp1, FilterBank=fb);
    [wt, wtf, coi] = cwt(resp1, fs);

    pmin = linspace(1/wtf(1), 1/wtf(1), 3);
    pmin = 1/wtf(1);
    pmax = linspace(8, 8, 1);
    pmax = 1/wtf(end-1);
    [ff,gg]=meshgrid(pmin, pmax);
    prng=[ff(:) gg(:)];

    frng = 1./prng;
    frng(frng>wtf(1)) = wtf(1);
    frng(frng<wtf(end)) = wtf(end);
    prng = 1./frng; %recompute in case thresholding changed
end

for m = 1:size(frng,1)

    if dodetrend
        pdeg = 2; %polynomial degree
        respnew = detrend(resp1, pdeg);
    else
        respnew = icwt(wt, wname, wtf, [frng(m,2) frng(m,1)]) + mean(resp1);
        respnew = rescale(respnew);
    end

    if ~isempty(pthgifpre)
        if m==1
            hfg = figure( 'Units', 'Normalized');
            hax = axes('Parent', hfg, 'Units', 'Normalized', 'Position', [0.1 0.6 0.85 0.35]);
            hold(hax, 'on')
            yyaxis left
            hpl1 = plot(hax, t, resp1, 'k-');
            yyaxis right
            hpl2 = plot(hax, t, respnew, 'r-');
            hold(hax, 'off')
            hax.YAxis(1).Color = 'k';
            hax.YAxis(2).Color = 'r';
        else
            hpl2.YData = respnew;
        end
        titlein = ['period range (sec) ' num2str(round(prng(m,2),2)) ',  ' num2str(round(prng(m,1),2))];
        hax.Title.String = titlein;

        fngif2 = [pthgifpre 'resp_rec_' num2str(round(prng(m,1),2)) '_' num2str(round(prng(m,2),2)) '_.gif'];
        fngif2 = fngif;

        axpos = [0.1 0.1 0.85 0.35];
        plot_multi_timeseries(resp1, respnew, fngif2, numseg, titlein, constant_ylim, ylim_padfac, ls1, ls2, match_ylim, gif_visibility, hfg, axpos)

        % fig2gif(hfg,m,fngif)

    end

end


end

