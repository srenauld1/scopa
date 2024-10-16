function bump = bumpcmp(stack, fitin, roidat, opts, md, regionex, si)


%% params

mthd = opts.mthd; %'pva' for vector average, 'vonmises' for fitting von mises per timepoint doesn't exist yet
domaintype = opts.domaintype; %'functional' to define circular domain with fit to each roi, or 'morphological' to define as circle across region mask
domain = opts.domain; %'all', 'right', 'left', 'larger', 'weighted', 'random'
slopeord = opts.slopeord; %order of polynomial used to fit local slope (e.g. to compute bump speed)
slopelensec = opts.slopelensec; %order of polynomial used to fit local slope (e.g. to compute bump speed)
smoothwindow_sec = opts.smoothwindow_sec; %full width of gaussian smoothing window (5 times std)
rescale_clusters = opts.rescale_clusters; %just before computing bump, rescale each cluster's timeseries to range 0-1
numcluster_for_bump_domain_resample = opts.numcluster_for_bump_domain_resample.(regionex);
resample_smoothfac = opts.resample_smoothfac;
omitnan_bump = opts.omitnan;
doplt = opts.doplt;

fitopts = opts.mfit(si);

fn_save_prefix = fitin.fn_save_prefix;


%% define domain (functionally or morphologically)

if numcluster_for_bump_domain_resample
    numcluster = numcluster_for_bump_domain_resample;
else
    numcluster = size(fitin.vars.depvp, 1);
end

if numcluster==1
    halfcent = 1;
else
    halfcent = floor(numcluster / 2); %make it floor in case odd, code below is not written for odd, won't matter for anything but plotting, and this will only happen if there's a lot of clusters, so won't matter much
end

if strcmp(domaintype, 'functional')

    [resp_cl, domaintmp] = map_rois_to_head_direction(stack, fitin, roidat, md, fitopts, halfcent, numcluster_for_bump_domain_resample, resample_smoothfac, doplt);

elseif strcmp(domaintype, 'morphological') %morphological domain

    domaintmp = mod(linspace(0,4*pi,numcluster+1), 2*pi) - pi; %this way allows odd number of clusters (only occurs if nonoverlapping)
    domaintmp = domaintmp(1:end-1);
    resp_cl = fitin.vars.depvp; %no downsampling for morphological domain

end

if rescale_clusters
    for di = 1:size(resp_cl, 1)
        resp_cl(di,:) = rescale(resp_cl(di,:));
    end
end

%% compute bump with different methods



for fi = 1:length(domain)

    if any(strcmp(domain{fi}, 'all')) %regular pva, all clusters, same as mean of both halves
        centinds = 1:numcluster;
        resptmp = resp_cl;
    elseif any(strcmp(domain{fi}, 'right')) %right half
        centinds = 1:halfcent;
        resptmp = resp_cl(centinds,:);
    elseif any(strcmp(domain{fi}, 'left')) %left half
        centinds = halfcent+1:numcluster;
        resptmp = resp_cl(centinds,:);
    elseif any(strcmp(domain{fi}, 'larger')) %larger amp half
        centinds = 1:halfcent;
        maxinds = sum(resp_cl(centinds,:),1) > sum(resp_cl(centinds+halfcent,:),1);
        resptmp = resp_cl(centinds,:).*maxinds + resp_cl(centinds+halfcent,:).*~maxinds;
    elseif any(strcmp(domain{fi}, 'weighted')) %weighted mean of both halves, if you use equal weighting it will be same as all clusters
        centinds = 1:halfcent;
        wt1 = 0.5;
        wt2 = 0.5;
        tmp1 = wt1*vec(resp_cl(centinds,:))';
        tmp2 = wt2*vec(resp_cl(centinds+halfcent,:))';
        resptmp = nansum([tmp1; tmp2]) / (wt1+wt2);
        resptmp = reshape(resptmp, size(resp_cl(centinds,:)));
    elseif any(strcmp(domain{fi}, 'random')) %random
        centinds = 1:numcluster;
        resptmp = zeros(size(resp_cl));
        resptmp(sub2ind(size(resptmp), randi([1 size(resptmp,1)],1,size(resptmp,2)), 1:size(resptmp,2))) = 1;
    end

    domain = domaintmp(centinds);

    switch mthd

        case 'pva'

            [mu, rho, circvar] = circular_mean_and_variance(domain, resptmp, omitnan_bump); %alternative form of circ_mean and circ_var above, same result but ignores nans
            % mu2 = circ_mean(repmat(domain', [1 size(resptmp, 2)]), resptmp);
            % [rho, ~, sel] = circ_var(repmat(domain', [1 size(resptmp, 2)]), resptmp);
            % for rti = 1:size(resptmp, 2)
            %     mu_true(:, rti) = deg2rad(weighted_circular_mean(rad2deg(domain), resptmp(:,rti))); % "true circular mean", so far results are not very different
            %     rho_true(:, rti) = weighted_circular_std(rad2deg(domain), resptmp(:,rti)); % std based on "true circular mean",
            % end


        case 'vonmises'

            disp("vonmises mthd (fit vonmises to each timepoint using mfit) not written yet")

    end

    mu = mu';
    rho = rho';

    if smoothwindow_sec
        mu = smooth_timeseries('circular', mu, smoothwindow_sec, md.sampper);
        rho = smooth_timeseries('normal', rho, smoothwindow_sec, md.sampper);
    end

    bumpvel = tsdv('circular', mu, slopelensec, slopeord, md.sampper);
    offset = circ_dist_nan(fitin.vars.indvp.', mu);

    [~, ii] = mink(abs(domain -mu), 2, 2); %find indexes corresponding to bump position in each time point
    i2 = ii' + size(resptmp, 1) * [0 : size(resptmp, 2)-1 ]; %find the linear index into the peak of each column (time point) value.
    ampmu = mean(resptmp(i2), 1, 'omitmissing')'; %extract amplitude at mu position
    amppeak = max(resptmp, [], 1, 'omitmissing')'; %extract max amplitude at each time point
    ampmean = mean(resptmp, 1, 'omitmissing')'; %find the amp, which is the mean dff in the whole mask

    bump.(domain{fi}).mu = single(mu);
    bump.(domain{fi}).rho = single(rho);
    bump.(domain{fi}).ampmean = single(ampmean);
    bump.(domain{fi}).amppeak = single(amppeak);
    bump.(domain{fi}).ampmu = single(ampmu);
    bump.(domain{fi}).vel = single(bumpvel);
    bump.(domain{fi}).offset = single(offset);
    bump.(domain{fi}).domain = single(domain);
    bump.(domain{fi}).centinds = single(centinds);

end


%% plots

if doplt

    indz = 1:size(mu,1);

    fn = fieldnames(bump);
    for fni = 1:length(fn)

        mutmp = bump.(fn{fni}).mu;

        figure; plot(mutmp); yyaxis right; plot(fitin.vars.indvp)
        saveas( gcf, [fn_save_prefix '_bump_v_visang_' fn{fni} '_.png'])

        figure; plot(unwrap(mutmp)); yyaxis right; plot(unwrap(fitin.vars.indvp))
        saveas( gcf, [fn_save_prefix '_bump_v_visang_uw_' fn{fni} '.png'])

    end


    filename_gif = [fn_save_prefix '_ampsortedclust_' fn{fni} '.gif'];
    epochinds = {num2cell(unique(ts.epochinds))};
    numclusterplot = 8;
    dvecc = round(linspace(1, numcluster, numclusterplot));
    countz = 0;
    framecount_gif = 0;
    for epi = 1:length(epochinds)
        framecount_gif = framecount_gif + 1;

        hfg = figure;

        if epochinds{epi}
            indz = find(ts.epochinds==epochinds{epi});
        else
            indz = 1:length(trialepochinds);
        end

        [~, md1a]=sort(resp_cl(:,indz), 'ascend');
        minall = min(vec(resp_cl(:,indz)));
        maxall = max(vec(resp_cl(:,indz)));
        for ddi = dvecc
            countz = countz+1;
            spl{countz} = subplot(length(epochinds),numclusterplot,countz);
            hold(spl{countz}, 'on')
            plot(spl{countz}, resp_cl(sub2ind(size(resp_cl), vec(md1a(ddi,:)), indz)));
            ylim([minall maxall])
            if ddi>1
                xticks([])
                xticklabels([])
                yticks([])
                yticklabels([])
            end
            sgtitle({['epoch ' epochinds{epi}]; [num2str(length(dvecc)) ' equispaced clusters of ' num2str(numcluster) ' total']; ['amp-sorted per-timepoint']})
        end
    end

    fig2gif(hfg, framecount_gif, filename_gif)



end


