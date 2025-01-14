function resp = roiresp(resp, roimask, stackmnt, saveresp, pthpre, sampper, t, opt, doplt)

arguments
    resp % stack (must be yxztc), or roi timeseries (roi,t,c), (if previously extracted roi timeseries, sent here to be further normalized and/or clustered according to roiwt)
    roimask
    stackmnt
    saveresp
    pthpre
    sampper
    t
    opt
    doplt = 0
end
normpre = opt.pre; % normalization before clustering of pixels into rois, or subrois into rois (ie normalization applied to each pixel or subroi)
normpost = opt.post; %normalization after clustering of pixels into rois, or subrois into rois (ie normalization applied to each roi)
wavp = opt.wavp; %keep periods in range wavp, using continuous wavelet transform and inverse; empty to skip
degdtr = opt.degdtr; % detrend polynomial degree; 0 to skip detrending
channorm = opt.channorm; %work in progress; 2-channel normalization with wavelet coherence based filtering
mincoh = opt.mincoh; %work in progress min coherence threshold for channorm


pthresp = [pthpre 'resp_.mat'];
try

    resp = struct2cell(load(pthresp)); %make sure loaded stack is named 'stack'
    resp = resp{1};

catch

    if isempty(t) && ( ~isempty(wavp) || channorm~=0 )
        error("must pass t if passing wavp or channorm (must have t to apply wavelet filtering or wavelet cohernece based 2-channel normalization)")
    end

    numchan = size(stackmnt,5);
    roiwt = [];
    for c = 1:numchan
        if ~isempty(roimask{c})
            roiwttmp = roiwtmake(stackmnt(:,:,:,:,c), roimask{c});
            if c==1
                szchan1 = size(roiwttmp,1);
            elseif c==2
                szchan2 = size(roiwttmp,1);
            end
            roiwt = cat(1, roiwt, roiwttmp);
        end
    end

    if unique(roiwt)==0
        error("roiwt contains no pixel or subroi indices for any roi")
    end

    if ndims(resp)>3 %if resp is greater than 3d, it is stack (not roi timeseries), since stack must be yxzt
        stack_input = 1;
        resp = reshape(resp, [], size(resp, ndims(resp))); %reshape
    else
        stack_input = 0;
    end

    resp = tsnorm(resp, normpre, sampper);

    if ndims(resp)~=3
        error("tmp2d must be 2d at this point")
    end

    goodinds = any(resp, 2) & ~any(isnan(resp), 2); %so they don't affect the mean, get rid of bad rois here (all zeros or any nans); do before clustering so extraction & normalization param mapping is unaffected, for raw pixels this should do nothing
    if ~isempty(goodinds) && ~all(goodinds)
        if stack_input
            error("for stack input, all pixels should be goodinds")
        end
        resp = resp(goodinds, :); %okay to create the temp variable here because only roi timeseries input (clustering caiman rois) will have not goodinds, and in this case resp is not huge
        roiwt = roiwt(:, goodinds);
    end

    if ~isempty(resp) %some normalizations will be empty (like dff when F0 is too low, divides by zero)
        varsz = whos('resp');
        numseg = ceil(varsz.bytes/1e9);
        if numseg>1 %do mtimes (convert to single) in segments to not crash ram
            resp = zeros(size(roiwt,1), size(resp,2), 'single');
            seglen = ceil(size(resp,2)/numseg);
            for w = 1:numseg %if integer, do it one frame at a time in case stack is big you want to avoid converting the whole thing at once; it's slower but tolerable and better than crashing ram
                idx = [1:seglen]+seglen*(w-1);
                idx(idx>size(resp,2)) = [];
                resp(:,idx) = roiwt * single(resp(:,idx)) ./ sum(roiwt,2); %default no normalization, this is the summed fluorescence in each roi, normalized by total intensity
            end
        else
            resp = roiwt * single(resp) ./ sum(roiwt,2); %default no normalization, this is the summed fluorescence in each roi, normalized by total intensity
        end
    else
        resp = nan;
    end

    if degdtr
        resp = detrend(resp, degdtr); %degdtr is polynomial degree
    end

    if ~isempty(wavp)
        resp = wavflt(resp, t=t, wavp=wavp, doplt=0); %pth_roim_prefix
    end

    resp = tsnorm(resp, normpost, sampper);

    if channorm
        resp = norm_cross_chan(resp, t=t, pthgifpre=pthpre, mincoh=mincoh); %2-channel normalization based on wavelet coherence, work in progress
    end

    if saveresp
        save(pthresp, 'resp', '-v7.3', '-mat')
    end

    if doplt

        % numroi = size(resp,1);
        % indzy = 1:size(resp,2);
        % colord = distinguishable_colors(numroi);


        % figure;
        % for fni = 1:numnorm
        %     for mi = 1 : 1 : 1
        %         subplot(numnorm,1,fni);
        %         hist(resp.(fn{fni})(mi,:));
        %         title(strrep(fn{fni}, '_', ' '))
        %         xlim([min(vec(resp.(fn{fni})(mi,:))), max(vec(resp.(fn{fni})(mi,:))) ])
        %     end
        % end
        % saveas( gcf, [pthpre 'normhistsresp_.png'])

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
