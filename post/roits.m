function resp = roits(respin, opt)

arguments
    respin % response; numeric array or struct; if numeric array, must be yxztc (can be singleton c); if struct, each field is a numeric array, size [roi,time]
    opt.roiwt = [] % weighting; size [n,s] where each row n is a roi, and each column s is a subroi; subroi is pixel if respin is stack, otherwise subroi is a roi within response n
    opt.normpre = 'f' % normalization before clustering of pixels into rois, or subrois into rois (ie normalization applied to each pixel or subroi)
    opt.normpost = 'f'%n ormalization after clustering of pixels into rois, or subrois into rois (ie normalization applied to each roi)
    opt.sampper = [] % sample period
    opt.resp = struct % if resp is passed as input, this function's output resp is appended to it
    opt.wavp = [] % keep periods in range wavp, using continuous wavelet transform and inverse; empty to skip
    opt.degdtr = 0 % detrend polynomial degree; 0 to skip detrending
    opt.channorm = 0
    opt.t = [] % time for timeseries
    opt.pthpre = [] % save path prefix for figures; if empty, one will be generated
    opt.doplt = 0 %whether to do plots
end
roiwt = opt.roiwt;
normpre = opt.normpre;
normpost = opt.normpost;
sampper = opt.sampper;
resp = opt.resp;
wavp = opt.wavp;
degdtr = opt.degdtr;
t = opt.t;
pthpre = opt.pthpre;
doplt = opt.doplt;

if isempty(roiwt)
    roiwt = 1;
end
if isempty(pthpre)
    pthpre = pthauto(suffix='.gif', usetime=1);
end
if isempty(t) && ( ~isempty(wavp) || ~isempty(channorm) )
    error("must pass t if passing wavp or channorm (must have t to apply wavelet filtering or wavelet cohernece based 2-channel normalization)")
end
if isempty(resp)
    resp = struct;
end

if isstruct(respin)
    fn = fieldnames(respin);
    chanused = [any(endsWith(fn, 'chn1')) any(endsWith(fn, 'chn2'))];
    if sum(chanused)==0
        chanused = [1 0];
    end
else
    chanused = boolean([1 size(respin, 5)==2]);
end

for c = 1:numel(chanused)
    if chanused(c)
        if sum(chanused)==2
            chanpat = ['_chn' num2str(c)]; %only use chan suffix for fieldname if there are two channels (and use suffix for both channels)
        else
            chanpat = '';
        end
        if isstruct(respin)
            respin_onechan = struct2cell(respin);
            kp = endsWith(fn, chanpat);
            respin_onechan = respin_onechan(kp);
            fntmp = erase(fn(kp), chanpat); %erase because channel fieldname suffix is moved from end of current fieldname to end of new fieldname, which begins with the current prefix
            respin_onechan = cell2struct(respin_onechan, fntmp);
            resp = roits_onechan(respin_onechan, roiwt, normpre, normpost, sampper, chanpat, resp, wavp, degdtr, t, pthpre, doplt);
        else
            resp = roits_onechan(respin(:,:,:,:,c), roiwt, normpre, normpost, sampper, chanpat, resp, wavp, degdtr, t, pthpre, doplt);
        end
    end
end

if channorm 
    norm_cross_chan(resp, t=t, pthgifpre=pthpre, mincoh=0.3); %2-channel normalization based on wavelet coherence, work in progress
end

end


function resp = roits_onechan(respin, roiwt, normpre, normpost, sampper, fnchan, resp, wavp, degdtr, t, pthpre, doplt)

arguments
    respin
    roiwt
    normpre
    normpost
    sampper
    fnchan
    resp
    wavp
    degdtr
    t
    pthpre
    doplt
end

nowt = 0;
uwt = unique(roiwt);
if uwt==0
    error("roiwt contains no pixel or subroi indices for any roi")
elseif uwt(uwt~=0)==1
    wtstr = 'n'; %no pixel weighting, just indices
    if uwt==1
        nowt = 1; %if roiwt is all ones, or is just 1, or is empty when passed to roits, or wasn't passed to roits
    end
else
    wtstr = 'y'; %pixel indices with weighting
end

if ~isstruct(respin) %if input is raw image f
    raw_image_input = 1;
    respintmp.imf = reshape(respin, [], size(respin, ndims(respin))); %reshape
    respin = respintmp;
    clear respintmp
else
    raw_image_input = 0;
end

fnin = fieldnames(respin);
cnt = 0;

for k = 1:length(fnin)

    resp1.f = respin.(fnin{k}); %assign the no-normalization default

    resp1 = respnorm(resp1.f, normpre, sampper);

    fn1 = fieldnames(resp1);

    for m = 1:length(fn1)

        cnt = cnt+1;

        tmp2d = resp1.(fn1{m});

        assert(ndims(tmp2d)==2)

        goodinds = any(tmp2d, 2) & ~any(isnan(tmp2d), 2); %so they don't affect the mean, get rid of bad rois here (all zeros or any nans); do before clustering so extraction & normalization param mapping is unaffected, for raw pixels this should do nothing
        if raw_image_input & numel(find(goodinds)) ~= size(tmp2d, 1)
            error("for raw pixel input, all pixels should be goodinds")
        end

        tmp2d = tmp2d(goodinds, :);
        if nowt
            roiwt_tmp = 1;
        else
            roiwt_tmp = roiwt(:, goodinds);
        end

        if ~isempty(tmp2d) %some normalizations will be empty (like dff when F0 is too low, divides by zero)
            resp2.f = roiwt_tmp * tmp2d ./ sum(roiwt_tmp,2); %default no normalization, this is the summed fluorescence in each roi, normalized by total intensity
        else
            resp2.f = nan;
        end

        if degdtr
            resp2.f = detrend(resp2.f, degdtr); %degdtr is polynomial degree
        end

        if ~isempty(wavp)
            resp2.f = wavflt(resp2.f, t=t, wavp=wavp, doplt=0); %pth_roim_prefix
        end

        resp2 = respnorm(resp2.f, normpost, sampper);

        fn2 = fieldnames(resp2);
        for fni2 = 1:length(fn2)
            fntmp = [fnin{k} '_' fn1{m} '_'  fn2{fni2} '_' wtstr fnchan];
            resp.(fntmp) = resp2.(fn2{fni2});
        end

    end
end

%assign the no-normalization/no-clustering fields for functional rois (just plain caiman output)
%(morph rois get clustered at least, since otherwise they're just single pixels)
%note these can have different size than the fields that were clustered
%pc gets f, cl and w get null since there is no clustering for this field
if ~raw_image_input
    for k = 1:length(fnin)
        fntmp = [fnin{k} '_f_null_null'];
        resp.(fntmp) = respin.(fnin{k});
    end
end


if doplt

    fn = fieldnames(resp);
    numnorm = length(fn);
    numroi = size(resp.(fn{1}),1);
    indzy = 1:size(resp.(fn{1}),2);
    colord = distinguishable_colors(numroi);

    figure;
    for fni = 1:numnorm
        cnt = 0;
        for mi = 1 : 1 : numroi
            cnt = cnt+1;
            xinds = [1:length(indzy)]+length(indzy)*(cnt-1);
            sp1 = subplot(numnorm,1,fni);
            hold(sp1, 'on')
            plot(xinds, resp.(fn{fni})(mi,indzy), 'color', colord(cnt,:));
            title(strrep(fn{fni}, '_', ' '))
        end
    end
    saveas( gcf, [pthpre 'normcompresp_.png'])

    %
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
    %

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

