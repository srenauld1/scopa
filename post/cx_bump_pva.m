function bump = cx_bump_pva(stack, resp, visang, numroi_func, ...
    fn_save_prefix, smoothwindow, stimepochinds_i, dt_i_mean, ...
    pixinds_roi, mapind2ind, fitopt, doplots)



%% input params

method_alpha = 'functional'; %'morphological';
bump_method_index_save = 1; %keep at 1 right now, not written yet to vary
smooth_bump_metrics = 1;
slopeorder_mu = 2;
slopelen_mu = 5;
rescale_clusters = 1;

%% define alpha (functionally or morphologically)

resample_alpha = 0;
if resample_alpha
    numcluster = numroi_func;
else
    numcluster = size(resp, 1);
end

if numcluster==1
    halfcent = 1;
else
    halfcent = floor(numcluster / 2); %make it floor in case odd, code below is not written for odd, won't matter for anything but plotting, and this will only happen if there's a lot of clusters, so won't mattere much
end

if strcmp(method_alpha, 'functional')

    [resp_cl, alphatmp] = cx_map_rois_to_head_direction(stack, resp, visang, pixinds_roi, ...
        mapind2ind, stimepochinds_i, dt_i_mean, fitopt, halfcent, fn_save_prefix, resample_alpha, doplots);

elseif strcmp(method_alpha, 'morphological') %morphological alpha

    alphatmp = mod(linspace(0,4*pi,numcluster+1), 2*pi) - pi; %this way allows odd number of PB clusters (only occurs if nonoverlapping)
    alphatmp = alphatmp(1:end-1);

    resp_cl = resp; %no downsampling for morph rois 

end


if rescale_clusters
    for di = 1:size(resp_cl, 1)
        resp_cl(di,:) = rescale(resp_cl(di,:));
    end
end

%% compute bump with different methods


for fi = 1%:7

    if fi==1 %regular pva, all glomeruli, same as mean of both halves
        centinds = 1:numcluster;
        resptmp = resp_cl;
        fieldstr = 'all';
    elseif fi==2 %right half
        centinds = 1:halfcent;
        resptmp = resp_cl(centinds,:);
        fieldstr = 'right';
    elseif fi==3 %left half
        centinds = halfcent+1:numcluster;
        resptmp = resp_cl(centinds,:);
        fieldstr = 'left';
    elseif fi==5 %larger amp half
        centinds = 1:halfcent;
        maxinds = sum(resp_cl(centinds,:),1) > sum(resp_cl(centinds+halfcent,:),1);
        resptmp = resp_cl(centinds,:).*maxinds + resp_cl(centinds+halfcent,:).*~maxinds;
        fieldstr = 'larger';
    elseif fi==4 %weighted mean of both halves, equal weighting should be same as all glomeruli
        centinds = 1:halfcent;
        wt1 = 0.5;
        wt2 = 0.5;
        tmp1 = wt1*vec(resp_cl(centinds,:))';
        tmp2 = wt2*vec(resp_cl(centinds+halfcent,:))';
        resptmp = nansum([tmp1; tmp2]) / (wt1+wt2);
        resptmp = reshape(resptmp, size(resp_cl(centinds,:)));
        fieldstr = 'weighted';
    elseif fi==6 %random
        centinds = 1:numcluster;
        resptmp = zeros(size(resp_cl));
        resptmp(sub2ind(size(resptmp), randi([1 size(resptmp,1)],1,size(resptmp,2)), 1:size(resptmp,2))) = 1;
        fieldstr = 'random';
    end

    alpha = alphatmp(centinds);

    is_circular = 1;
    [mu, rho] = cx_stim_response_tuning(alpha, resptmp, is_circular);

    mu = mu';
    rho = rho';

    if smooth_bump_metrics
        mu = cx_smooth_circular_var(mu, smoothwindow);
        rho = smoothdata(rho, 'gaussian', smoothwindow);
    end

    bumpvel = cx_differentiate_circular_var(mu, dt_i_mean, slopelen_mu, slopeorder_mu);
    offset = cx_circ_dist_nan(visang, mu);

    [~, ii] = mink(abs(alpha -mu), 2, 2); %find indexes corresponding to bump position in each time point
    i2 = ii' + size(resptmp, 1) * [0 : size(resptmp, 2)-1 ]; %find the linear index into the peak of each column (time point) value. this was clever :)
    ampmu = nanmean(resptmp(i2), 1)'; %extract amplitude at mu position
    amppeak = nanmax(resptmp, [], 1)'; %extract max amplitude at each time point
    ampmean = nanmean(resptmp,1)'; %find the amp, which is the mean dff in the whole mask

    bump.(fieldstr).mu = single(mu);
    bump.(fieldstr).rho = single(rho);
    bump.(fieldstr).ampmean = single(ampmean);
    bump.(fieldstr).amppeak = single(amppeak);
    bump.(fieldstr).ampmu = single(ampmu);
    bump.(fieldstr).vel = single(bumpvel);
    bump.(fieldstr).offset = single(offset);
    bump.(fieldstr).alpha = single(alpha);
    bump.(fieldstr).centinds = single(centinds);

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


    epochinds = {[1]};
    numglom = 8;
    dvecc = round(linspace(1, halfcent, numglom));
    countz = 0;
    figure;
    for epi = 1:length(epochinds)

        if epochinds{epi}
            indz = find(stimepochinds_i==epochinds{epi});
        else
            indz = 1:length(stimepochinds);
        end

        if strcmp(method_alpha, 'morphological')
            [~, md1a]=sort(resp_cl(1:halfcent,indz), 'ascend');
            [~, md2a]=sort(resp_cl(halfcent+1:end,indz), 'ascend');
        else
            [~, md1a]=sort(resp_cl(:,indz), 'ascend');
        end
        minall = min(vec(resp_cl(:,indz)));
        maxall = max(vec(resp_cl(:,indz)));
        for ddi = dvecc
            countz = countz+1;
            spl{countz} = subplot(length(epochinds),numglom,countz);
            hold(spl{countz}, 'on')
            plot(resp_cl(sub2ind(size(resp_cl), vec(md1a(ddi,:)), indz)));
            if strcmp(method_alpha, 'morphological')
                plot(resp_cl(sub2ind(size(resp_cl), vec(md2a(ddi,:))+halfcent, indz)));
            end
            ylim([minall maxall])
            if ddi>1
                xticks([])
                xticklabels([])
                yticks([])
                yticklabels([])
            end
            sgtitle([num2str(length(dvecc)) ' glomerluli, amp-sorted per-timepoint (both hemispheres if blue&red)'])
        end
    end
    saveas( gcf, [fn_save_prefix '_ampsortedglom_' fn{fni} '.png'])


end


