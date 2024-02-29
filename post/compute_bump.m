function bump = compute_bump(stack, resp, visang, ...
    roiinfo, bumpopts, fitopt, md, fn_save_prefix, regionex)


%% params

bump_method = bumpopts.bump_method; %'pva' for vector average, 'vonmises' for fitting von mises per timepoint doesn't exist yet
domain_method = bumpopts.domain_method; %'functional' to define circular domain with fit to each roi, or 'morphological' to define as circle across region mask
bump_subdomain = bumpopts.bump_subdomain; %'all', 'right', 'left', 'larger', 'weighted', 'random'
slopeorder = bumpopts.slopeorder; %order of polynomial used to fit local slope (e.g. to compute bump speed)
slopelen = bumpopts.slopelen; %order of polynomial used to fit local slope (e.g. to compute bump speed)
smoothwindow_sec = bumpopts.smoothwindow_sec; %full width of gaussian smoothing window (5 times std)
rescale_clusters = bumpopts.rescale_clusters; %just before computing bump, rescale each cluster's timeseries to range 0-1
numcluster_for_bump_domain_resample = bumpopts.numcluster_for_bump_domain_resample.(regionex);
doplots = bumpopts.doplots;

smoothwindow = smoothwindow_sec/md.dtmni;


%% define domain (functionally or morphologically)

if numcluster_for_bump_domain_resample
    numcluster = numcluster_for_bump_domain_resample;
else
    numcluster = size(resp, 1);
end

if numcluster==1
    halfcent = 1;
else
    halfcent = floor(numcluster / 2); %make it floor in case odd, code below is not written for odd, won't matter for anything but plotting, and this will only happen if there's a lot of clusters, so won't matter much
end

if strcmp(domain_method, 'functional')

    [resp_cl, domaintmp] = map_rois_to_head_direction(stack, resp, visang, ...
        roiinfo, md, fitopt, halfcent, fn_save_prefix, ...
        numcluster_for_bump_domain_resample, doplots);

elseif strcmp(domain_method, 'morphological') %morphological domain

    domaintmp = mod(linspace(0,4*pi,numcluster+1), 2*pi) - pi; %this way allows odd number of PB clusters (only occurs if nonoverlapping)
    domaintmp = domaintmp(1:end-1);
    resp_cl = resp; %no downsampling for morph rois

end


if rescale_clusters
    for di = 1:size(resp_cl, 1)
        resp_cl(di,:) = rescale(resp_cl(di,:));
    end
end

%% compute bump with different methods



for fi = 1:length(bump_subdomain)

    if any(strcmp(bump_subdomain{fi}, 'all')) %regular pva, all glomeruli, same as mean of both halves
        centinds = 1:numcluster;
        resptmp = resp_cl;
    elseif any(strcmp(bump_subdomain{fi}, 'right')) %right half
        centinds = 1:halfcent;
        resptmp = resp_cl(centinds,:);
    elseif any(strcmp(bump_subdomain{fi}, 'left')) %left half
        centinds = halfcent+1:numcluster;
        resptmp = resp_cl(centinds,:);
    elseif any(strcmp(bump_subdomain{fi}, 'larger')) %larger amp half
        centinds = 1:halfcent;
        maxinds = sum(resp_cl(centinds,:),1) > sum(resp_cl(centinds+halfcent,:),1);
        resptmp = resp_cl(centinds,:).*maxinds + resp_cl(centinds+halfcent,:).*~maxinds;
    elseif any(strcmp(bump_subdomain{fi}, 'weighted')) %weighted mean of both halves, if you use equal weighting it will be same as all glomeruli
        centinds = 1:halfcent;
        wt1 = 0.5;
        wt2 = 0.5;
        tmp1 = wt1*vec(resp_cl(centinds,:))';
        tmp2 = wt2*vec(resp_cl(centinds+halfcent,:))';
        resptmp = nansum([tmp1; tmp2]) / (wt1+wt2);
        resptmp = reshape(resptmp, size(resp_cl(centinds,:)));
    elseif any(strcmp(bump_subdomain{fi}, 'random')) %random
        centinds = 1:numcluster;
        resptmp = zeros(size(resp_cl));
        resptmp(sub2ind(size(resptmp), randi([1 size(resptmp,1)],1,size(resptmp,2)), 1:size(resptmp,2))) = 1;
    end

    domain = domaintmp(centinds);

    switch bump_method

        case 'pva'

            [mu, rho, circvar] = circular_mean_and_variance(domain, resptmp); %alternative form of circ_mean and circ_var above, same result but ignores nans
            % mu = circ_mean(repmat(domain', [1 size(resptmp, 2)]), resptmp);
            % [rho, ~, sel] = circ_var(repmat(domain', [1 size(resptmp, 2)]), resptmp);
            % for rti = 1:size(resptmp, 2)
            %     mu_true(:, rti) = deg2rad(weighted_circular_mean(rad2deg(domain), resptmp(:,rti))); % "true circular mean", so far results are not very different
            %     rho_true(:, rti) = weighted_circular_std(rad2deg(domain), resptmp(:,rti)); % std based on "true circular mean",
            % end


        case 'vonmises'

            disp("vonmises bump_method (fit vonmises to each timepoint) not written yet")

    end

    mu = mu';
    rho = rho';

    if smoothwindow
        mu = smooth_circular_variable(mu, smoothwindow);
        rho = smoothdata(rho, 'gaussian', smoothwindow);
    end

    bumpvel = differentiate_circular_variable(mu, md.dtmni, slopelen, slopeorder);
    offset = circ_dist_nan(visang, mu);

    [~, ii] = mink(abs(domain -mu), 2, 2); %find indexes corresponding to bump position in each time point
    i2 = ii' + size(resptmp, 1) * [0 : size(resptmp, 2)-1 ]; %find the linear index into the peak of each column (time point) value.
    ampmu = nanmean(resptmp(i2), 1)'; %extract amplitude at mu position
    amppeak = nanmax(resptmp, [], 1)'; %extract max amplitude at each time point
    ampmean = nanmean(resptmp,1)'; %find the amp, which is the mean dff in the whole mask

    bump.(bump_subdomain{fi}).mu = single(mu);
    bump.(bump_subdomain{fi}).rho = single(rho);
    bump.(bump_subdomain{fi}).ampmean = single(ampmean);
    bump.(bump_subdomain{fi}).amppeak = single(amppeak);
    bump.(bump_subdomain{fi}).ampmu = single(ampmu);
    bump.(bump_subdomain{fi}).vel = single(bumpvel);
    bump.(bump_subdomain{fi}).offset = single(offset);
    bump.(bump_subdomain{fi}).domain = single(domain);
    bump.(bump_subdomain{fi}).centinds = single(centinds);

end


%% plots

if doplots

    indz = 1:size(mu,1);

    fn = fieldnames(bump);
    for fni = 1:length(fn)

        mutmp = bump.(fn{fni}).mu;

        figure; plot(mutmp); yyaxis right; plot(visang)
        saveas( gcf, [fn_save_prefix '_bump_v_visang_' fn{fni} '_.png'])

        figure; plot(unwrap(mutmp)); yyaxis right; plot(unwrap(visang))
        saveas( gcf, [fn_save_prefix '_bump_v_visang_uw_' fn{fni} '.png'])

    end


    filename_gif = [fn_save_prefix '_ampsortedglom_' fn{fni} '.gif'];
    epochinds = {num2cell(unique(md.trialepochinds_i))};
    numclusterplot = 8;
    ncolgif = 128;
    dvecc = round(linspace(1, numcluster, numclusterplot));
    countz = 0;
    framecount_gif = 0;
    for epi = 1:length(epochinds)
        framecount_gif = framecount_gif + 1;

        hfg = figure;

        if epochinds{epi}
            indz = find(md.trialepochinds_i==epochinds{epi});
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
    frame = getframe(hfg);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im, ncolgif);

    if framecount_gif==1
        imwrite(imind, cm, filename_gif, 'DelayTime', 0, 'Loopcount', inf);
    else
        imwrite(imind, cm, filename_gif,'DelayTime', 0, 'WriteMode', 'append');
    end


end


