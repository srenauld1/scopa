
function resp = wavflt(resp, opt)

arguments
    resp %response
    opt.wavp (:,2) = [] %(n,2) array denoting wavelet filtering min and max period (seconds); if n>1, will use last row in output by default (n>1 is really for exploration, plotting to see how different periods affect output); empty to skip; 0 in first column will not apply lower period threshold; any number larger than max valid period (determined in wavflt) will not apply upper period threshold, but [0 inf] (or 0 and any giant number) is not the proper way to skip wavelet filtering because the algorithm will still be applied (ie timeseries will be unchanged except mean will be lost, pointlessly), so use [] to skip wavelet filtering
    opt.t = 1:size(resp,2) %time vector
    opt.it = 1:size(resp,2) %subset of t for plotting (full timeseries gets filtered by wavelet regardless)
    opt.ir = [] %subset of rois for plotting (all rois gets filtered by wavelet regardless)
    opt.pthgifpre = '' %prefix to gif
    opt.doplt = 0 %do plot or not
    opt.onlyir = [] %only apply wavelet filtering to rois being plotted (listed in ir); convenient for quickly plotting but not using output; if left empty or not passed, this mode applies when there is no output argument and ir is not empty
end

t = opt.t;
it = opt.it;
ir = opt.ir;
pthgifpre = opt.pthgifpre;
wavp = opt.wavp;
doplt = opt.doplt;
onlyir = opt.onlyir;

if isempty(onlyir)
    if nargout==0 && ~isempty(ir) %if no output argument and ir is not empty, only apply wavelet filtering to rois being plotted (listed in ir);
        onlyir = 1;
    else
        onlyir = 0;
    end
end

if isempty(ir)
    ir = 1:size(resp,1);
end

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


for k = 1:size(resp,1)
    if ~onlyir || (onlyir && ismember(k, ir))
        resp(k,:) = wavdn_oneroi(resp(k,:), t, k, ir, it, fb, fs, wname, pthgifpre, wavp, doplt);
    end
end


end

function respnew = wavdn_oneroi(resp, t, k, ir, it, fb, fs, wname, pthgifpre, wavp, doplt)


if ~isa(resp, 'double')
    resp = double(resp);
end


%% transform

% [wt, wtf, coi] = cwt(resp, FilterBank=fb);
[wt, wtf, coi] = cwt(resp, fs);

if isempty(wavp)
    pmin = 1/wtf(1);
    pmax = 1/wtf(end);
else
    pmin = wavp(:,1); %0.3; %min period in seconds
    pmax = wavp(:,2); %50; %max period in seconds
end

[ff,gg] = meshgrid(pmin, pmax);
prng = [ff(:) gg(:)];

if any(prng(:,1)>prng(:,2))
    error("all min periods must be greater than max periods")
end

frng = 1./prng;
tmpmaxf = frng(:,1);
tmpmaxf(tmpmaxf>wtf(1)) = wtf(1); %threshold in case user requested min period outside valid range
tmpminf = frng(:,2);
tmpminf(tmpminf<wtf(end)) = wtf(end); %threshold in case user requested max period outside valid range
frng = [tmpmaxf tmpminf];
prng = 1./frng; %recompute in case thresholding changed

for m = 1:size(frng,1)

    respnew = icwt(wt, wname, wtf, [frng(m,2) frng(m,1)]) + mean(resp);
    % respnew = rescale(respnew);

    if doplt && ismember(k, ir)
        hfg = figure( 'Units', 'Normalized');
        hax = axes('Parent', hfg, 'Units', 'Normalized', 'Position', [0.1 0.6 0.85 0.35]);
        hold(hax, 'on')
        yyaxis left
        hpl1 = plot(hax, t(it), resp(it), 'k-');
        yyaxis right
        hpl2 = plot(hax, t(it), respnew(it), 'm-');
        hold(hax, 'off')
        hax.YAxis(1).Color = 'k';
        hax.YAxis(2).Color = 'm';
        titlein = ['roi ' num2str(k) ' period range (sec) ' num2str(round(prng(m,2),2)) ',  ' num2str(round(prng(m,1),2))];
        hax.Title.String = titlein;

        pthgif = [pthgifpre 'resp_wavflt_roi_' num2str(k) '_pmin_' num2str(round(prng(m,1),2)) '_pmax_' num2str(round(prng(m,2),2)) '_.gif'];

        xseg = 10;
        yconst = 1;
        gifvis = 'on';
        axpos = [0.1 0.1 0.85 0.35];
        tsplt(resp, y2=respnew, pthgif=pthgif, xseg=xseg, titlein=titlein, yconst=yconst, gifvis=gifvis, hfg=hfg, axpos=axpos);

        % fig2gif(hfg,m,fngif)

    end

end


end

