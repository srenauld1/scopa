function bmp = bumpcmp(stack, indvp, depvp, regionex, roidat, imrate, epochts, pth_dirstack, recid, opt, doplt)


arguments
    stack
    indvp
    depvp
    regionex
    roidat
    imrate
    epochts
    pth_dirstack
    recid
    opt
    doplt = []
end

eval(structvars(opt).'); %bad practice; turn opt into local variables with the same name as opt fields; using this function because there are so many here, but it's bad practice

pthpre = fullfile(pth_dirstack, recid);

if isempty(doplt)
    doplt = any(strcmp('bmp', glb('plt')));
end


if numangrs
    numseg = numangrs;
else
    numseg = size(depvp, 1);
end

if numseg==1
    error("numseg must be greater than 1")
end

if isodd(numseg)
    fprintf("WARNING, numseg IS ODD, SO IF BUMP COMPUTATION INVOLVES HALVING THE COMPASS (scope 'left', 'right', 'max', or a digit, or mthd is 'functional' for regionex pb), BUMP CAN BE INACCURATE, SINCE THOSE METHODS ASSUME EVEN numseg (ONE SEGMENT WILL BE MISSING)" + newline)
end

halfcent = floor(numseg / 2); %make it floor in case odd, code below is not written for odd, won't matter for anything but plotting, and this will only happen if there's a lot of clusters, so won't matter much

sampper = 1/imrate;

%% crop stack 

stack = stackcrop(stack, regionex, recid, pth_dirstack);


%% define domain (functionally or morphologically)


if strcmp(domaintype, 'functional')

    [respcltmp, domaintmp] = roi2hd(stack, regionex, indvp, depvp, pthpre, roidat, imrate, mf, numangrs, smfac, doplt, epochts);

elseif strcmp(domaintype, 'morphological') %morphological domain

    domaintmp = mod(linspace(0,4*pi,numseg+1), 2*pi) - pi; %this way allows odd number of clusters (only occurs if nonoverlapping)
    domaintmp = domaintmp(1:end-1);
    respcltmp = depvp; %no downsampling for morphological domain

end

if rs
    for di = 1:size(respcltmp, 1)
        respcltmp(di,:) = rescale(respcltmp(di,:));
    end
end

%% compute bump

switch scope
    case 'all' %regular pva, all clusters, same as mean of both halves
        centinds = 1:numseg;
        resptmp = respcltmp;
    case 'left'%left half
        centinds = halfcent+1:numseg;
        resptmp = respcltmp(centinds,:);
    case 'right' %right half
        centinds = 1:halfcent;
        resptmp = respcltmp(centinds,:);
    case 'max '%max amp half
        centinds = 1:halfcent;
        maxinds = sum(respcltmp(centinds,:),1) > sum(respcltmp(centinds+halfcent,:),1);
        resptmp = respcltmp(centinds,:).*maxinds + respcltmp(centinds+halfcent,:).*~maxinds;
    case 'random' %random
        centinds = 1:numseg;
        resptmp = zeros(size(respcltmp));
        resptmp(sub2ind(size(resptmp), randi([1 size(resptmp,1)],1,size(resptmp,2)), 1:size(resptmp,2))) = 1;
    otherwise % weighted mean of both halves, if you use equal weighting (scope=50) it will be same as scope='all'
        if isnumeric(scope)
            wtl = scope/100;
        else
            wtl = str2double(scope)/100; 
        end
        if isnan(wtl)
            error("scope must be 'all', 'right', 'left', 'max', 'random', or a digit (text or numeric)")
        end
        if wtl<0 || wtl>1
            error("scope must be range 0-100 if it's a digit")
        end
        wtr = 1-wtl;
        centinds = 1:halfcent;
        tmp1 = wtl*vec(respcltmp(centinds,:))';
        tmp2 = wtr*vec(respcltmp(centinds+halfcent,:))';
        resptmp = nansum([tmp1; tmp2]) / (wtl+wtr);
        resptmp = reshape(resptmp, size(respcltmp(centinds,:)));
end

domain = domaintmp(centinds);

switch mthd

    case 'pva'

        [mu, rho, circvar] = circmnvar(domain, resptmp, omitnan); %alternative form of circ_mean and circ_var above, same result but ignores nans
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

if smlensec
    mu = tssmooth('circular', mu, smlensec, sampper);
    rho = tssmooth('normal', rho, smlensec, sampper);
end

bumpvel = tsdv('circular', mu, slopelensec, slopeord, sampper);
offset = circ_dist_nan(indvp.', mu);

[~, ii] = mink(abs(domain -mu), 2, 2); %find indexes corresponding to bump position in each time point
i2 = ii' + size(resptmp, 1) * [0 : size(resptmp, 2)-1 ]; %find the linear index into the peak of each column (time point) value.
ampmu = mean(resptmp(i2), 1, 'omitmissing')'; %extract amplitude at mu position
amppeak = max(resptmp, [], 1, 'omitmissing')'; %extract max amplitude at each time point
ampmean = mean(resptmp, 1, 'omitmissing')'; %find the amp, which is the mean dff in the whole mask


%% output struct 

bmp.scope = scope;
bmp.mthd = mthd;

bmp.respcl = single(resptmp);

bmp.domain = vec(single(domain));
bmp.centinds = vec(single(centinds));

bmp.mu = transpose(vec(single(mu)));
bmp.rho = transpose(vec(single(rho)));
bmp.ampmean = transpose(vec(single(ampmean)));
bmp.amppeak = transpose(vec(single(amppeak)));
bmp.ampmu = transpose(vec(single(ampmu)));
bmp.vel = transpose(vec(single(bumpvel)));
bmp.offset = transpose(vec(single(offset)));


%% plots

if doplt

    indz = 1:size(mu,1);

    fn = fieldnames(bump);
    for fni = 1:length(fn)

        mutmp = bmp.(fn{fni}).mu;

        figure; plot(mutmp); yyaxis right; plot(indvp)
        saveas( gcf, [pthpre '_bump_v_visang_' fn{fni} '_.png'])

        figure; plot(unwrap(mutmp)); yyaxis right; plot(unwrap(indvp))
        saveas( gcf, [pthpre '_bump_v_visang_uw_' fn{fni} '.png'])

    end


    filename_gif = [pthpre '_ampsortedclust_' fn{fni} '.gif'];
    epochinds = {num2cell(unique(ts.epochinds))};
    numclusterplot = 8;
    dvecc = round(linspace(1, numseg, numclusterplot));
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

        [~, md1a]=sort(respcltmp(:,indz), 'ascend');
        minall = min(vec(respcltmp(:,indz)));
        maxall = max(vec(respcltmp(:,indz)));
        for ddi = dvecc
            countz = countz+1;
            spl{countz} = subplot(length(epochinds),numclusterplot,countz);
            hold(spl{countz}, 'on')
            plot(spl{countz}, respcltmp(sub2ind(size(respcltmp), vec(md1a(ddi,:)), indz)));
            ylim([minall maxall])
            if ddi>1
                xticks([])
                xticklabels([])
                yticks([])
                yticklabels([])
            end
            sgtitle({['epoch ' epochinds{epi}]; [num2str(length(dvecc)) ' equispaced clusters of ' num2str(numseg) ' total']; ['amp-sorted per-timepoint']})
        end
    end

    fig2gif(hfg, framecount_gif, filename_gif)



end


