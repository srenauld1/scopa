
function resp = wavdn(resp, opt)

arguments
    resp
    opt.t = 1:size(resp,2)
    opt.it = 1:size(resp,2)
    opt.ir = 1:size(resp,1)
    opt.pthgifpre = ''
    opt.doplt = 0
end

t = opt.t;
it = opt.it;
ir = opt.ir;
pthgifpre = opt.pthgifpre;
doplt = opt.doplt;

if isempty(pthgifpre)
    pthgifpre = pthauto(suffix='', usetime=1, usefun=1);
end

%% mostly default right now

numsamp = size(resp,2);

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


for k = 1:numel(ir)
    resp(k,it) = wavdn_oneroi(resp(ir(k),it), t(it), fb, fs, wname, pthgifpre, doplt);
end


end

function respnew = wavdn_oneroi(resp, t, fb, fs, wname, pthgifpre, doplt)

numseg = 10;
yconst = 1;
ylim_padfac = 0.1;
ls1 = '-k';
ls2 = '-r';
match_ylim = 0;
gifvis = 'on';

if ~isa(resp, 'double')
    resp = double(resp);
end


%% transform

dodetrend = 0; %wavelet processing can already detrend, so this probably doens't make much sense within this function
dowav = 1;

frng = [nan nan];
prng = [nan nan];


if dodetrend
    pdeg = 2; %polynomial degree
    resp = detrend(resp, pdeg);
end

if dowav
    
    % [wt, wtf, coi] = cwt(resp, FilterBank=fb);
    [wt, wtf, coi] = cwt(resp, fs);

    pmin = linspace(1/wtf(1), 1/wtf(1), 3);
    pmin = 1/wtf(1);
    pmax = linspace(8, 8, 1);
    pmax = 1/wtf(end);
    pmin = 0.3; %min period in seconds
    pmax = 50; %max period in seconds

   
    [ff,gg]=meshgrid(pmin, pmax);
    prng=[ff(:) gg(:)];

    frng = 1./prng;
    frng(frng>wtf(1)) = wtf(1);
    frng(frng<wtf(end)) = wtf(end);
    prng = 1./frng; %recompute in case thresholding changed
end

for m = 1:size(frng,1)

    if dowav
        respnew = icwt(wt, wname, wtf, [frng(m,2) frng(m,1)]) + mean(resp);
        % respnew = rescale(respnew);
    else
        respnew = resp;
    end

    if doplt
        if m==1
            hfg = figure( 'Units', 'Normalized');
            hax = axes('Parent', hfg, 'Units', 'Normalized', 'Position', [0.1 0.6 0.85 0.35]);
            hold(hax, 'on')
            yyaxis left
            hpl1 = plot(hax, t, resp, 'k-');
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

        pthgif = [pthgifpre 'resp_rec_' num2str(round(prng(m,1),2)) '_' num2str(round(prng(m,2),2)) '_.gif'];

        axpos = [0.1 0.1 0.85 0.35];
        tsplt(resp, respnew, pthgif, numseg, titlein, yconst, ylim_padfac, ls1, ls2, match_ylim, gifvis, hfg, axpos)

        % fig2gif(hfg,m,fngif)

    end

end


end

