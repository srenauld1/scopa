function tsout = roits(tsin, roimask, stackmnt, pthpre, sper, t, opt, memthr, doplt)

arguments
    tsin % stack (must be yxztc), or roi timeseries (roi,t,c), (if previously extracted roi timeseries, sent here to be further normalized and/or clustered according to roiwt)
    roimask
    stackmnt
    pthpre
    sper
    t
    opt
    memthr = 1e9 %memory threshold (bytes); input tsin greater than memthr will have roi timeseries extracted in groups, to save ram; this is slower but can avoid crashing session
    doplt = 0
end
normpre = opt.pre; % normalization before clustering of pixels into rois, or subrois into rois (ie normalization applied to each pixel or subroi)
normpost = opt.post; %normalization after clustering of pixels into rois, or subrois into rois (ie normalization applied to each roi)
wavp = opt.wavp; %keep periods in range wavp, using continuous wavelet transform and inverse; empty to skip
degdtr = opt.degdtr; % detrend polynomial degree; 0 to skip detrending
channorm = opt.channorm; %work in progress; 2-channel normalization with wavelet coherence based filtering
mincoh = opt.mincoh; %work in progress min coherence threshold for channorm

if ~iscell(roimask)
    roimask = {roimask};
end

chanuse = ~cellfun(@isempty, roimask);

srate = 1/sper;

if isempty(t) && channorm~=0
    error("must pass t if channorm is true (must have t to apply wavelet cohernece based 2-channel normalization)")
end

numchan = size(stackmnt,5);
roiwt = [];
wtsz = cell(numchan,1);
for k = 1:numchan
    if chanuse(k)
        roiwttmp = roiwtmake(stackmnt(:,:,:,:,k), roimask{k});
        if k==1
            wtsz{k} = [1:size(roiwttmp,1)];
        elseif k==2
            if chanuse(1)
                wtsz{k} = [1:size(roiwttmp,1)] + numel(wtsz{k-1});
            else
                wtsz{k} = [1:size(roiwttmp,1)]; %if channel 1 is not used, don't add channel 1 rois
            end
        end
        roiwt = cat(1, roiwt, roiwttmp);
    end
end

if unique(roiwt)==0
    error("roiwt contains no pixel or subroi indices for any roi")
end

if ndims(tsin)>3 %if tsin is greater than 3d, it is stack (not roi timeseries), since stack must be yxzt
    stack_input = 1;
    if numchan==1
        tsin = reshape(tsin, [], size(tsin, ndims(tsin))); %reshape to (pixel,time)
    elseif numchan==2
        tsin = reshape(tsin, [], size(tsin, ndims(tsin)-1), numchan); %reshape to (pixel,time)
    end
else
    stack_input = 0;
end
% this doesn't do anythign for current data
tsin = tsnorm(tsin, normpre, sper, memthr); %first normalization, optional

if ndims(tsin)~=2 && ndims(tsin)~=3
    error("here, tsin must be 2d (if 1 channel) or 3d (if 2-channel)")
end

goodinds = sum(tsin, 2)>0; %so they don't affect the mean, get rid of bad rois here (goodinds are not all zeros and not any nans along 2nd dimension; this expression is a fast way of checking for that); do before clustering so extraction & normalization param mapping is unaffected, for raw pixels this should do nothing
if ~isempty(goodinds) && ~all(goodinds(:)) && stack_input
    error("for stack input, all pixels should be goodinds")
end


%%%% EXTRACT RESPONSES FOR EACH ROI %%%%

for k = 1:numchan
    tsout{k} = [];
    if chanuse(k)
        if any(goodinds(:,:,k)) %some pre-normalizations (first call to tsnorm, above) will output empty (like dff when F0 is too low, divides by zero); some caiman runs (with bad params) will output all nans
            tsout{k} = zeros(numel(wtsz{k}), size(tsin,2), 'single'); %make it cell since each channel can have different number rois
            varsz = whos('tsin');
            numseg = ceil(varsz.bytes/memthr);
            if numseg>1 %if tsin is larger than memthr, convert to single (double or single required for mtimes, which is by far fastest way to do this part) in segments to use less ram, since tsout, even though it is also single precision, is generally much smaller than tsin
                seglen = ceil(size(tsin,2)/numseg);
                for w = 1:numseg
                    idx = [1:seglen]+seglen*(w-1);
                    idx(idx>size(tsin,2)) = [];
                    if ~isempty(goodinds) && ~all(goodinds(:,:,k))
                        tsout{k}(:,idx) = roiwt(wtsz{k}, goodinds(:,:,k)) * single(tsin(goodinds(:,:,k),idx,k)) ./ sum(roiwt(wtsz{k}, goodinds(:,:,k)),2); %summed fluorescence in each roi, normalized by total intensity
                    else
                        tsout{k}(:,idx) = roiwt(wtsz{k}, :) * single(tsin(:,idx,k)) ./ sum(roiwt(wtsz{k}, :),2); %summed fluorescence in each roi, normalized by total intensity
                    end
                end
            else
                if ~isempty(goodinds) && ~all(goodinds(:,:,k))
                    tsout{k} = roiwt(wtsz{k},goodinds(:,:,k)) * single(tsin(goodinds(:,:,k),:,k)) ./ sum(roiwt(wtsz{k},goodinds(:,:,k)),2); %summed fluorescence in each roi, normalized by total intensity
                else
                    tsout{k} = roiwt(wtsz{k},:) * single(tsin(:,:,k)) ./ sum(roiwt(wtsz{k},:),2); %summed fluorescence in each roi, normalized by total intensity
                end
            end

            %%%% OPTIONALLY PROCESS ROI TIMESERIES IN VARIOUS WAYS %%%%

            if degdtr
                tsout{k} = detrend(tsout{k}, degdtr); %detrending (remove baseline trend); degdtr is degree of polynomial fit
            end

            if ~isempty(wavp)
                tsout{k} = wavflt(tsout{k}, t=t, srate=srate, wavp=wavp, doplt=0); %wavelet bandpass filtering (within range wavp)
            end

            tsout{k} = tsnorm(tsout{k}, normpost, sper, memthr); %second normalization, optional

            if channorm
                tsout{k} = nrmchan(tsout{k}, t=t, srate=srate, pthgifpre=pthpre, mincoh=mincoh); %2-channel normalization based on wavelet coherence, work in progress
            end

        else

            tsout{k} = nan; %if there were no good pixels/rois for channel k

        end
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

