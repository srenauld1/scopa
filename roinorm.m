function ts = roinorm(ts, opt, opt2)

%{

various options to normalize roi timeseries
ts is 2-element cell for 2-channel data (even if only one channel has rois, ie if roimask is cell with one empty element), each cell is size(roi,time); 
for single-channel data, ts is not cell, it is just matrix size (roi,time)

options for extraction/normalization of roi signals
standard normalizations (e.g. rescaling, z-scoring, dff, box-cox) are handled by opt.nrmstr
all normalizations are applied to individual vector timeseries
normalization strings are listed below; they can be combined arbitrarily; if combined, they are applied left to right order (eg 'nnbox' applies 'nn' then 'box'):
    'f': no normalization
    'dffuuuvvv': dff; vvv is sliding window length in seconds over which f0 is computed; if vvv is 000, f0 is computed across the entire timeseries, not a sliding window; uuu is percentile to compute f0 for each window (e.g. dff010008 is 10th percentile over 8-seconde sliding window, dff001000 is 1st percentile over entire timeseries)
    'rscxxxyyy': rescale, sending xxx percentile to 0, yyy percentile to 1 (eg rsc000100 is same as default matlab rescale function)
    'z': zscore
    'nn': nonnegative (subtract min)
    'box': box-cox

%}

arguments

    ts

    opt.nrmstr = ['f']; % (nrmstr means "norm string"); char vector; 'f' is no normalization; nrmstr must be compsed of syllables above; normalization is applied to each roi
    opt.degdtr = 0; %polynomial for detrending before normalization; 0 to skip detrending; wavp detrends by default
    opt.wavp = []; %[0.3 50]; %(n,2) array denoting wavelet filtering min and max period (seconds); if n>1, will use last row in output by default (n>1 is really for exploration, plotting to see how different periods affect output); empty to skip; 0 in first column will not apply lower period threshold; any number larger than max valid period (determined in wavflt) will not apply upper period threshold, but [0 inf] (or 0 and any giant number) is not the proper way to skip wavelet filtering because the algorithm will still be applied (ie timeseries will be unchanged except mean will be lost, pointlessly), so use [] to skip wavelet filtering
    opt.channorm = 0; %work in progress; 0 to skip; leave as 0 for now; which channel to normalize the other with (dampen time-frequency regions of high wavelet coherence)
    opt.mincoh = 0.3; %work in progress; min coherence for channorm
    
    opt2.srate = []
    opt2.t = []
    opt2.memthr = 1e9 %memory threshold (bytes); input tsin greater than memthr will have roi timeseries extracted in groups, to save ram; this is slower but can avoid crashing session
    opt2.doplt (1,1) {mustBeBinary} = 0 % 1 to make plots
    opt2.och (1,1) {mustBeBinary} = 0 %och means "options check"; 1 to exit function and return nothing but arguments block struct opt (not opt2 or any other name-value arguments struct); 0 to skip och (run function normally), which is default

end

if opt2.och
    if isfield(opt, 'optid')
        opt = rmfield(opt, 'optid');
    end
    ts = opt;
    return
end

nrmstr = opt.nrmstr; %normalization after clustering of pixels into rois, or subrois into rois (ie normalization applied to each roi)
degdtr = opt.degdtr; % detrend polynomial degree; 0 to skip detrending
wavp = opt.wavp; %keep periods in range wavp, using continuous wavelet transform and inverse; empty to skip
channorm = opt.channorm; %work in progress; 2-channel normalization with wavelet coherence based filtering
mincoh = opt.mincoh; %work in progress min coherence threshold for channorm

srate = opt2.srate; %sample period in seconds
t = opt2.t; %time vector
memthr = opt2.memthr; %memory threshold above which tsnorm operates in batches to prevent ram from exceeding this value
doplt = opt2.doplt;

if isempty(t) && channorm~=0
    error("must pass in t if channorm is true (must have t to apply wavelet cohernece based 2-channel normalization)")
end

numchan = numel(ts);

for k = 1:numchan

    if degdtr
        ts{k} = detrend(ts{k}, degdtr); %detrending (remove baseline trend); degdtr is degree of polynomial fit
    end

    if ~isempty(wavp)
        ts{k} = wavflt(ts{k}, t=t, srate=srate, wavp=wavp, doplt=doplt); %wavelet bandpass filtering (within range wavp)
    end

    ts{k} = tsnorm(ts{k}, nrmstr, srate=srate, memthr=memthr); %timeseries normalization

    if channorm
        ts{k} = nrmchan(ts{k}, t=t, srate=srate, mincoh=mincoh); %2-channel normalization based on wavelet coherence (work in progress)
    end

end




if doplt

    % numroi = size(tsin,1);
    % indzy = 1:size(tsin,2);
    % colord = distinguishable_colors(numroi);

    % figure;
    % for fni = 1:numnorm
    %     for mi = 1 : 1 : 1
    %         subplot(numnorm,1,fni);
    %         hist(tsin.(fn{fni})(mi,:));
    %         title(strrep(fn{fni}, '_', ' '))
    %         xlim([min(vec(tsin.(fn{fni})(mi,:))), max(vec(tsin.(fn{fni})(mi,:))) ])
    %     end
    % end
    % saveas( gcf, [pthpre 'normhist_roits_.png'])

    % prctcheck = 99;
    % pfn = prctile(cluster_f, prctcheck, 2);
    % pdfn = prctile(cluster_dff, prctcheck, 2);
    % pzfn = prctile(cluster_955, prctcheck, 2);
    %
    % figure;
    % subplot(3,1,1)
    % scat(1:length(pfn), pfn)
    % title("raw")
    %
    % subplot(3,1,2)
    % scat(1:length(pdfn), pdfn)
    % title("dff")
    %
    % subplot(3,1,3)
    % scat(1:length(pzfn), pzfn)
    % title("percentile normalized")
    %
    % saveas( gcf, [pthpre 'normcompprct_.png'])
    %
    %
    % if length(pfn)>1
    %
    %     pfn = rescale(pfn);
    %     pdfn = rescale(pdfn);
    %     pzfn = rescale(pzfn);
    %
    %     figure;
    %     subplot(3,1,1)
    %     plot(pfn)
    %     title(std(pfn, 1)) %2nd arg is 1 to normalize by n, not n-1
    %     subplot(3,1,2)
    %     plot(pdfn)
    %     title(std(pdfn, 1)) %2nd arg is 1 to normalize by n, not n-1
    %     subplot(3,1,3)
    %     plot(pzfn)
    %     title(std(pzfn, 1)) %2nd arg is 1 to normalize by n, not n-1
    %
    %     saveas( gcf, [pthpre 'normcompprctnorm_.png'])
    %
    % end
    %
    %
    % figure;
    % for ci = 1:size(roi_dff, 1)
    %
    %     subplot(3,1,1)
    %     hist(vec(roi_box(ci,:)), 100);
    %     xlim([0 0.5])
    %
    %     subplot(3,1,2)
    %     hist(vec(roi_nn(ci,:)-1), 100);
    %     xlim([0 0.5])
    %
    %     subplot(3,1,3)
    %     indiest = 1:200;
    %     yyaxis left
    %     plot(roi_box(ci,indiest))
    %     yyaxis right
    %     plot(roi_nn(ci,indiest))
    %     pause(.2)
    %
    % end

end


end
