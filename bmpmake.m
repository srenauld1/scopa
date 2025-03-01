function bmp = bmpmake(indvp, depvp, opt, imrate, epochts, pthstack, doplt)


arguments
    indvp
    depvp
    opt
    imrate
    epochts
    pthstack
    doplt = []
end
chan = opt.chan;
mthd = opt.mthd;
omitnan = opt.omitnan;
scope = opt.scope;
domtype = opt.domtype;
dorescale = opt.dorescale;
numangrs = opt.numangrs;
maxangrs = opt.maxangrs;
slopelensec = opt.slopelensec;
slopeord = opt.slopeord;
smlensec = opt.smlensec;
optmdl = opt.mdl;

pthpre = [erase(pthstack, '.mat') opt.optid '_bmp_'];
pthbmp = [pthpre '.mat'];

if isempty(doplt)
    doplt = any(strcmp('bmp', glb('plt')));
end

if iscell(indvp)
    indvp = indvp{1};
end
if iscell(depvp)
    depvp = depvp{1};
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
    fprintf("WARNING, numseg IS ODD, SO IF BUMP COMPUTATION INVOLVES HALVING THE COMPASS (scope 'left', 'right', 'max', or a digit, or mthd is 'functional' for rgname pb), BUMP CAN BE INACCURATE, SINCE THOSE METHODS ASSUME EVEN numseg (ONE SEGMENT WILL BE MISSING)" + newline)
end

halfcent = floor(numseg / 2); %make it floor in case odd, code below is not written for odd, won't matter for anything but plotting, and this will only happen if there's a lot of clusters, so won't matter much

sper = 1/imrate;
numroi = size(depvp, 1);
numsamp = size(depvp, 2);


%% define domain (functionally or morphologically)

if dorescale
    for k = 1:size(depvp, 1)
        depvp(k,:) = rescale(depvp(k,:));
    end
end


if strcmp(domtype, 'functional')

    optidmdl = 'a1';
    optmdl.optid = optidmdl;
    mdl = mdlmake(optmdl, indvp, depvp, imrate, pthstack, epochts, doplt, 0, 1);

    angpref = mdl.ft.indvpf_mean_allval(:)'; %row vector of preferred angle;

    if numangrs
        [respcltmp, domaintmp] = compassrs(depvp, angpref, numangrs, maxangrs, doplt);
        % [respcltmp2, domaintmp2] = compassrs_old(depvp, angpref, 2*pi, numangrs, 1, doplt); %old, slower, more ram version; gives slightly different answer (always?)
        % figure; scatter(1:numel(domaintmp), respcltmp(:,100)); yyaxis right; scatter(1:numel(domaintmp), respcltmp2(:,100));
    else
        respcltmp = depvp;
        domaintmp = angpref;
    end

elseif strcmp(domtype, 'morphological') %morphological domain

    domaintmp = mod(linspace(0,4*pi,numseg+1), 2*pi) - pi; %this way allows odd number of clusters (only occurs if nonoverlapping)
    domaintmp = domaintmp(1:end-1);
    respcltmp = depvp; %no downsampling for morphological domain

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

        disp("vonmises mthd (fit vonmises to each timepoint using mdlmake) not written yet")

end

mu = mu';
rho = rho';

if smlensec
    mu = tssm('circular', mu, smlensec, sper);
    rho = tssm('normal', rho, smlensec, sper);
end

bumpvel = tsdv('circular', mu, slopelensec, slopeord, sper);
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

    error("bmpmake plots need to be rewritten")

    indz = 1:size(mu,1);

    fn = fieldnames(bump);
    for fni = 1:length(fn)

        mutmp = bmp.(fn{fni}).mu;

        figure; plot(mutmp); yyaxis right; plot(indvp)
        saveas( gcf, [pthpre '_bump_v_visang_' fn{fni} '_.png'])

        figure; plot(unwrap(mutmp)); yyaxis right; plot(unwrap(indvp))
        saveas( gcf, [pthpre '_bump_v_visang_uw_' fn{fni} '.png'])

    end


    pthgif = [pthpre '_ampsortedclust_' fn{fni} '.gif'];
    epochts = {num2cell(unique(ts.epochts))};
    numclusterplot = 8;
    dvecc = round(linspace(1, numseg, numclusterplot));
    countz = 0;
    cnt = 0;
    for epi = 1:length(epochts)
        cnt = cnt + 1;

        hfg = figure;

        if epochts{epi}
            indz = find(ts.epochts==epochts{epi});
        else
            indz = 1:length(trialepochinds);
        end

        [~, md1a]=sort(respcltmp(:,indz), 'ascend');
        minall = min(vec(respcltmp(:,indz)));
        maxall = max(vec(respcltmp(:,indz)));
        for ddi = dvecc
            countz = countz+1;
            spl{countz} = subplot(length(epochts),numclusterplot,countz);
            hold(spl{countz}, 'on')
            plot(spl{countz}, respcltmp(sub2ind(size(respcltmp), vec(md1a(ddi,:)), indz)));
            ylim([minall maxall])
            if ddi>1
                xticks([])
                xticklabels([])
                yticks([])
                yticklabels([])
            end
            sgtitle({['epoch ' epochts{epi}]; [num2str(length(dvecc)) ' equispaced clusters of ' num2str(numseg) ' total']; ['amp-sorted per-timepoint']})
        end
    end

    fig2gif(hfg, cnt, pthgif)


    if strcmp(rgname, 'pb')

        fprint("doing pb two halves resampling for optional plotting, but this is not used in the data" + newline)

        %resample each half of the compass, then put them together
        %HALVES ARE NOT WELL DEFINED, FIX THIS (use >pi shift in angpref??, or more precise morphology, or user-defined pb center??)
        %resampling 4pi all together only works if you shift angpref from one half of pb up by pi, right?

        rois_left = 1:numroi/2;
        rois_right = numroi/2+1:numroi;

        numangrs_left = floor(numangrs/2);
        numangrs_right = numangrs-numangrs_left;

        pthgif = [pthpre '_leftcompassrs_' fn{fni} '.gif'];
        [dfc_left, domain_left] = compassrs(depvp(rois_left,:), angpref(rois_left), numangrs_left, maxangrs, doplt, pthgif);

        pthgif = [pthpre '_rightcompassrs_' fn{fni} '.gif'];
        [dfc_left, domain_left] = compassrs(depvp(rois_right,:), angpref(rois_right), numangrs_right, maxangrs, doplt, pthgif);

        resptmp_2halves = cat(1, dfc_left, dfc_right);
        resptmp_2halves = rescale(resptmp_2halves);

        domain_2halves = [domain_left domain_right];

    end

    %preferred heading plots
    figure;
    subplot(4,1,1)
    plot(angpref)
    title("preferred angle")
    ylim([-4 4])
    subplot(4,1,2)
    plot(mod(angpref, 2*pi))
    title("preferred angle mod 2pi")
    ylim([0 8])
    subplot(4,1,3)
    uwtmp = unwrap(mod(angpref, 2*pi));
    uwtmp = uwtmp - uwtmp(1);
    plot(uwtmp)
    title("preferred angle unwrapped/zeroed")
    subplot(4,1,4)
    plot(prefang_sorted)
    title("preferred angle sorted")
    ylim([-4 4])
    saveas( gcf, [pthpre '_PREFHD_.png'])



    %resampled compass plot
    if numangrs

        plotfull = 1;
        plotraw = 0;
        plothalves = 0; %will plot halves if rgname is pb, if rgname is not pb this has no effect
        numplotinds = 50;
        tinds = round(linspace(1, numsamp, numplotinds));
        filename_save = [pthpre '_RESAMPCOMP_.gif'];
        gifvis = 'on';
        numroi_rs = size(resptmp,1);
        % numroi_rs = numroi_rs/2

        hfg = figure( 'Units', 'Normalized', 'Color', 'white', 'visible', gifvis);
        hax = axes( 'Parent', hfg, 'Units', 'Normalized');
        hax.Title.String = {"2pi all resampled (black), 2pi merged halves resampled (magenta)"; "pre-resampled angle-sorted (red), pre-resampled native sorting (green)"};


        cnt = 0;
        for ind = tinds
            cnt = cnt + 1;

            if cnt==1
                hold(hax, 'on');
                yyaxis left
                if plotfull
                    % hpl1 = plot(hax, 1:numroi_rs, resptmp(:,ind), 'color', [0 0 0], 'LineStyle','-');
                    hpl1 = plot(hax, domain, resptmp(:,ind), 'color', [0 0 0], 'LineStyle','-');
                end
                hax.YAxis(1).Color = 'k';
                hax.YAxis(1).Limits = [0 1];
                if strcmp(rgname, 'pb') && plothalves
                    %%hpl2 = plot(hax, 1:numroi_rs, resptmp4pi(:,ind), 'color', [0 1 1]);
                    % hpl2 = plot(hax, domain4pi, resptmp4pi(:,ind), 'color', [0 1 1]);
                    % hpl3 = plot(hax, 1:numroi_rs, resptmp_2halves(:,ind), 'color', [1 0 1], 'LineStyle','-');
                    hpl3 = plot(hax, domain_2halves, resptmp_2halves(:,ind), 'color', [1 0 1], 'LineStyle','-');
                end
                yyaxis right;
                % hpl4 = plot(hax, linspace(1, numroi_rs, numroi), rawsort(:,ind), 'color', [1 0 0], 'LineStyle','-');
                hpl4 = plot(hax, prefang_sorted, rawsort(:,ind), 'color', [1 0 0], 'LineStyle','-');
                hax.YAxis(2).Color = 'k';
                hax.YAxis(2).Limits = [0 1];
                if plotraw
                    rawrs = rescale(depvp);
                    hpl5 = plot(hax, linspace(min(angpref), max(angpref), numroi), rawrs(:,ind), 'color', [0.1 0.7 0.1], 'LineStyle','-');
                end

                hold(hax, 'off');
            else
                if plotfull
                    hpl1.YData = resptmp(:,ind);
                end
                if strcmp(rgname, 'pb') && plothalves
                    % hpl2.YData = resptmp4pi(:,ind);
                    hpl3.YData = resptmp_2halves(:,ind);
                end
                hpl4.YData = rawsort(:,ind);
                if plotraw
                    hpl5.YData = rawrs(:,ind);
                end
            end

            fig2gif(hfg, cnt, filename_save)


        end
    end
end


