

function plot_bump(aplot, dplot, bumpang, bumprho, cueang, ballang, ...
    ampbumpang_plot, amppeak_plot, ampmean_plot, resp_gar, resp_gal, resp_nor, resp_nol, ...
    epochinds, t, epochts, centinds, halfcent, pltindz, numfram, startsec, stopsec,  ...
    imdata, percentile_to_plot, mask3d, mask_with_3d_mask, roiinds, plot_only_outliers, ...
    plotcolz, xlim_makeroomfac, makeroomfac_rho, makeroomfac_bumpang, ncol, ...
    gifvis, separate_cueang_and_bump, sorting_target_metric, ...
    bump_method_index, fn_prefix, nanpadlen_min_input)

"CONSIDER DUPLICATE ENDPOINT FOR  CIND 2 PLOTS"

%%%%MAKING ballang NEGATIVE FOR PLOT BUT WHAT'S THE RIGHT THING TO DO?%%%%%%%%%%%%%%%%%%%%
%%%%MAKING ballang NEGATIVE FOR PLOT BUT WHAT'S THE RIGHT THING TO DO?%%%%%%%%%%%%%%%%%%%%
%%%%MAKING ballang NEGATIVE FOR PLOT BUT WHAT'S THE RIGHT THING TO DO?%%%%%%%%%%%%%%%%%%%%

ballang = -ballang;

numnanrow_splitLR = 1; %how many "ulieruli" to insert as nans to separate left and right hemispheres
same_y_scale_for_all_epochs = 1;

alpha_min = 0;

linwid = 1.5;

pthgif = [fn_prefix 'e' strrep(num2str(epochinds), ' ', '_') '_sort_' sorting_target_metric '_mthd_' num2str(bump_method_index) '_BUMP_.gif'];

"FLIPPING ORDER OF EPOCHINDS BECAUSE PLOT IS BOTTOM TO TOP"
epochinds = flip(epochinds);


%% create sidelines

sideline{1} = rescale(ampmean_plot);
sideline{2} = rescale(amppeak_plot);
sideline{3} = rescale(ampbumpang_plot);
sideline{4} = resp_gar;
sideline{5} = resp_gal;
sideline{6} = resp_nor;
sideline{7} = resp_nol;


%% apply 2d mask

if 0

    tmp = imdata.*mask3d;
    clear imdata

    tmp(tmp~=0) = rescale(tmp(tmp~=0));
    tmpnewpre = tmp;
    if plot_only_outliers
        idxnz = find(tmp~=0); %find nonzero indices
        %idxout = find(isoutlier(tmp(idxnz), "median", ThresholdFactor=40)); %find outliers among nonzeros
        idxout = find(isoutlier(tmp(idxnz), "percentiles", [0 percentile_to_plot])); %find outliers among nonzeros
        tmpnewpre = zeros(size(tmp));
        tmpnewpre(idxnz(idxout)) = 1;
    end
    clear tmp

    [masky,maskx] = ind2sub(size(mask3d),find(mask3d)); %find the cartesian coordinates of points in the mask


    %% then apply more specific mask if you want

    if mask_with_3d_mask

        clusterindsnew = zeros(size(roiinds));
        clusterindsnew(centinds{pltindz(bump_method_index)},:) = roiinds(centinds{pltindz(bump_method_index)},:);
        if size(roiinds,2) == numel(mask3d)
            sznewmask = size(mask3d);
        else
            sznewmask = [size(mask3d) size(tmpnewpre, 3)];
        end
        newmask = zeros(sznewmask);
        newmask(find(sum(clusterindsnew))) = 1;

        tmpnew = tmpnewpre .* newmask; %newmask just let's you mask by specific rois (centinds) if you want

    else

        tmpnew = tmpnewpre;

    end

    clear tmpnewpre
    tmpnew(tmpnew~=0) = rescale(tmpnew(tmpnew~=0));

end

%% setup subplot positions


numr = length(epochinds)*2;
numc = 4;
numtot = numr*numc;


font1 = 8;
font2 = 10;

room_for_sgtitle = 0.03;
room_for_labels = 0.03;

%positions/size of subplots including labels
xlab = linspace( 0+room_for_labels, 1, numc+1 ) ;
xlab = xlab(1:end-1);
ylab = linspace( 0+room_for_labels, 1-room_for_sgtitle, numr+1 ) ;
ylab = ylab(1:end-1);

wlab = (1 - room_for_sgtitle ) - xlab(end);
hlab = (1 - room_for_sgtitle ) - ylab(end);

%positions/size of subplots excluding labels
xp = xlab + room_for_labels;
wp = wlab - room_for_labels*2;
yp = ylab + room_for_labels;
hp = hlab - room_for_labels;

tittmp = strsplit(pthgif(1:end-4), '/');
figure_title = strrep(tittmp{end}, '_', ' ');

hfg = figure( 'Units', 'normalized', 'Position', [0.4, 0.4, 0.6, 0.6], ...
    'Color', 'white', 'visible', gifvis) ;
bgAxes = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', ...
    'XLim', [0, 1], 'YLim', [0, 1] ) ;
text( 0.5, 0.99, figure_title, 'FontSize', font2, ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold' ) ;

% % subplot labels (still in bgAxes)
% for colind = 1 : numsplcols
%     for rowind = 1 : numsplrows
%         text( xlab(colind)+wlab/2, ylab(rowind), sprintf( 'Label X%d', colind ), ...
%             'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', smallfont ) ;
%         text( xlab(colind), ylab(rowind)+hlab/2, sprintf( 'Label Y%d', rowind ), ...
%             'HorizontalAlignment', 'center', 'Rotation', 90, 'FontWeight', 'bold', 'FontSize', smallfont) ;
%     end
% end


%%

upsample_factor = 4; %for uniformly sampling domain-sorted responses

for pii = 1:length(aplot)

    [aplot_sort{pii}, asort] = sort(aplot{pltindz(pii)});
    dplot_sort{pii} = dplot{pltindz(pii)}(asort,:);

    %leave here bc used regardless of whetyher alpha_is_morphological
    % map bumpang onto cluster index (to deal with non-monotonic domain (two circles), esp when domain midpoint is ill-defined )
    mtmp = interp1(linspace(-pi, pi, 1000), linspace(1, halfcent+1, 1000), bumpang(:,pii));
    mtmp(mtmp==halfcent+1) = 1;
    bumpangasclust(:,pii) = mtmp;


    for ii = 1:numel(aplot_sort{pii})/2 %average two halves
        mnind = [1:2]+2*(ii-1); %domain is only morphological if we believe in mirror symmetric halves
        aplot_sort_tmp(ii) = mean(aplot_sort{pii}(mnind));
        dplot_sort_tmp(ii,:) = mean(dplot_sort{pii}(mnind,:), 1);
    end
    aplot_sort{pii} = aplot_sort_tmp;
    dplot_sort{pii} = dplot_sort_tmp;

    bumpangasclust_for_zeroing = round(bumpangasclust(:,pii));
    bumpangasclust_for_zeroing(bumpangasclust_for_zeroing==halfcent+1) = 1;
    halfcent_new = halfcent/2;
    dpsztmp = dplot_sort{pii};

    mtmp = interp1(linspace(-pi, pi, 1000), linspace(1, halfcent+1, 1000), cueang);
    mtmp(mtmp==halfcent+1) = 1;
    cueangasclust(:,pii) = mtmp;

    mtmp = interp1(linspace(-pi, pi, 1000), linspace(1, halfcent+1, 1000), ballang);
    mtmp(mtmp==halfcent+1) = 1;
    ballangasclust(:,pii) = mtmp;


    %zero the mean
    for ii = 1:size(dplot_sort{pii}, 2)
        if isnan(bumpangasclust_for_zeroing(ii)) %if nan, it's because there is no activity (consequently, no bump position)
            dplot_sort_zero{pii}(:,ii) = circshift(dpsztmp(:,ii), halfcent_new - 0); %in that case subtract 0, won't matter because nothing will be displayed
        else
            try
                dplot_sort_zero{pii}(:,ii) = circshift(dpsztmp(:,ii), halfcent_new - bumpangasclust_for_zeroing(ii)); %why isn't this the same: circshift(dpsztmp, bumpangasclust_upsampled)
            catch
                fuk=2
            end
        end
    end
    bumpangplot_zero(:, pltindz(pii)) = mod(bumpangasclust_for_zeroing + (halfcent_new - bumpangasclust_for_zeroing), size(dplot_sort_zero{pii}, 1));

end
cueang_zero = mod(cueangasclust + (halfcent_new - bumpangasclust_for_zeroing), size(dplot_sort_zero{pii}, 1));
ballang_zero = mod(ballangasclust + (halfcent_new - bumpangasclust_for_zeroing), size(dplot_sort_zero{pii}, 1));


%determine time axis for each epoch and bout
for rind = 1:numr/2

    if epochinds
        indz1 = find(epochts==epochinds(rind));
    else
        indz1 = 1:length(epochts);
    end


    if strcmp(sorting_target_metric, 'none')

        nanpadlen_min = nanpadlen_min_input;

        indz_tmp = indz1;
        xx = t(indz_tmp);
        % [~,idd1] = min(abs(xf-startsec));
        % [~,idd2] = min(abs(xf-stopsec));
        % indz_tmp = idd1:idd2;
        % xf = xf(indz_tmp);

        %now shorten according to numfram
        indz_tmp = indz_tmp(1:numfram);
        xxall{rind} = xx(1:numfram);
        if any(~ismember(unique(diff(xx)), unique(diff(t))))
            %"NONCONTIGUOUS X, X AXIS IS ARTIFICIAL"
            xxall{rind} = t(1:numfram);
        end

    else

        nanpadlen_min = 0;


        switch sorting_target_metric
            case 'bumpang'
                [~, indz_tmp] = sort(bumpang(indz1,pltindz(bump_method_index)));
            case 'rho'
                [~, indz_tmp] = sort(bumprho(indz1,pltindz(bump_method_index)));
        end
        indz_tmp = indz1(indz_tmp);
        xx = t(1:length(indz_tmp));

        %now shorten according to numfram
        indz_tmp = indz_tmp(round(linspace(1, length(indz_tmp), numfram)));
        xxall{rind} = linspace(0, xx(end), numfram);
        %xf = xf(round(linspace(1, length(xf), numgifframes)));

    end


    bout_endpoints = [0; find(diff(indz_tmp)~=1); length(indz_tmp)];
    for bei = 2:length(bout_endpoints)
        bout_indz{rind}{bei-1} = bout_endpoints(bei-1)+1 : bout_endpoints(bei);
    end

    indz{rind} = indz_tmp;

end


%prepare nan padding between bouts, for each epoch
num_full_bouts = min(cellfun(@length, bout_indz));
plotlen_total_withnanpad = 0;
for bni = 1:num_full_bouts
    max_bout_len(bni) = max(cellfun(@(x) length(x{bni}), bout_indz));
    nanpadlen_all(:,bni) = nanpadlen_min + (max_bout_len(bni) - cellfun(@(x) length(x{bni}), bout_indz));
    plotlen_total_withnanpad = plotlen_total_withnanpad + max_bout_len(bni) + nanpadlen_min;
end


%prepare plot quantities by inserting nan padding between bouts
% and for unwrapped cueang, bumpang, and ballang, across discontiguous bouts, shift values within each bout to start where the last bout left off, and normalize whole epoch to common scale

for rind = 1:numr/2

    %create tmp arrays for each epoch by indexing into time
    cueang2_tmp = cueang(indz{rind});
    cueang2z_tmp = cueang_zero(indz{rind});

    ballang2_tmp = ballang(indz{rind});
    ballang2z_tmp = ballang_zero(indz{rind});

    for pii=1:length(pltindz)
        dp_tmp{pltindz(pii)} = dplot{pltindz(pii)}(:,indz{rind});
        dps_tmp{pltindz(pii)} = dplot_sort{pltindz(pii)}(:,indz{rind});
        dpsz_tmp{pltindz(pii)} = dplot_sort_zero{pltindz(pii)}(:,indz{rind});
        mp_tmp{pltindz(pii)} = bumpang(indz{rind}, pltindz(pii))';
        mgh_tmp{pltindz(pii)} = bumpangasclust(indz{rind}, pltindz(pii))';
        rp_tmp{pltindz(pii)} = bumprho(indz{rind}, pltindz(pii))';
        rpr_tmp{pltindz(pii)} = rescale(rp_tmp{pltindz(pii)}, alpha_min, 1);
        mpz_tmp{pltindz(pii)} = bumpangplot_zero(indz{rind}, pltindz(pii))';
    end

    for spi = 1:length(sideline)
        sdln_tmp{spi} = sideline{spi}(indz{rind});
    end


    %create empty arrays for padding
    cueang2{rind} = zeros(plotlen_total_withnanpad, 1);
    cueang2z{rind} = zeros(plotlen_total_withnanpad, 1);
    cueang2u{rind} = zeros(plotlen_total_withnanpad, 1);
    ballang2{rind} = zeros(plotlen_total_withnanpad, 1);
    ballang2z{rind} = zeros(plotlen_total_withnanpad, 1);
    ballang2u{rind} = zeros(plotlen_total_withnanpad, 1);

    for pii=1:length(pltindz)
        dp{rind, pltindz(pii)} = zeros(size(dp_tmp{pltindz(pii)}, 1), plotlen_total_withnanpad);
        dps{rind, pltindz(pii)} = zeros(size(dps_tmp{pltindz(pii)}, 1), plotlen_total_withnanpad);
        dpsz{rind, pltindz(pii)} = zeros(size(dpsz_tmp{pltindz(pii)}, 1), plotlen_total_withnanpad);
        mp{rind, pltindz(pii)} = zeros(plotlen_total_withnanpad, 1);
        mpu{rind, pltindz(pii)} = zeros(plotlen_total_withnanpad, 1);
        mgh{rind, pltindz(pii)} = zeros(plotlen_total_withnanpad, 1);
        rp{rind, pltindz(pii)} = zeros(plotlen_total_withnanpad, 1);
        rpr{rind, pltindz(pii)} = zeros(plotlen_total_withnanpad, 1);
        mpz{rind, pltindz(pii)} = zeros(plotlen_total_withnanpad, 1);
    end


    for spi = 1:length(sideline)
        sdln{rind, spi} = zeros(plotlen_total_withnanpad, 1);
    end

    %create unwrapped versions of cueang, bumpang, and ballang
    cueang2utmp1 = unwrap(cueang2_tmp);
    prevend_cueang = 0;
    ballang2utmp1 = unwrap(ballang2_tmp);
    prevend_ballang = 0;
    for pii=1:length(pltindz)
        mputmp1{pii} = unwrap(mp_tmp{pltindz(pii)});
        prevend_mpu{pii} = 0;
    end

    %x-pad (and for the unwrapped quantities, also y-shift)
    for bei = 1:num_full_bouts

        nanpad = nan(nanpadlen_all(rind,bei),1);

        boutlen = length(bout_indz{rind}{bei});
        nanshift = sum(nanpadlen_all(rind,1:bei-1), 2); %shift bc of previous bout's nan padding
        newboutindzstart = bout_indz{rind}{bei}(1)+nanshift;
        newboutindzstop = (newboutindzstart-1)+boutlen+nanpadlen_all(rind,bei);

        %pad everything but the unwrapped quantities
        tmptmp = cueang2_tmp(bout_indz{rind}{bei});
        cueang2{rind}(newboutindzstart:newboutindzstop) = [tmptmp' nanpad'];
        tmptmp = cueang2z_tmp(bout_indz{rind}{bei});
        cueang2z{rind}(newboutindzstart:newboutindzstop) = [tmptmp' nanpad'];

        tmptmp = ballang2_tmp(bout_indz{rind}{bei});
        ballang2{rind}(newboutindzstart:newboutindzstop) = [tmptmp' nanpad'];
        tmptmp = ballang2z_tmp(bout_indz{rind}{bei});
        ballang2z{rind}(newboutindzstart:newboutindzstop) = [tmptmp' nanpad'];

        for pii=1:length(pltindz)

            tmptmp = dp_tmp{pltindz(pii)}(:,bout_indz{rind}{bei});
            dp{rind, pltindz(pii)}(:,newboutindzstart:newboutindzstop) = [tmptmp repmat(nanpad', [size(dp_tmp{pltindz(pii)}, 1) 1])];
            tmptmp = dps_tmp{pltindz(pii)}(:,bout_indz{rind}{bei});
            dps{rind, pltindz(pii)}(:,newboutindzstart:newboutindzstop) = [tmptmp repmat(nanpad', [size(dps_tmp{pltindz(pii)}, 1) 1])];
            tmptmp = dpsz_tmp{pltindz(pii)}(:,bout_indz{rind}{bei});
            dpsz{rind, pltindz(pii)}(:,newboutindzstart:newboutindzstop) = [tmptmp repmat(nanpad', [size(dpsz_tmp{pltindz(pii)}, 1) 1])];
            tmptmp = mp_tmp{pltindz(pii)}(bout_indz{rind}{bei});
            mp{rind, pltindz(pii)}(newboutindzstart:newboutindzstop) = [tmptmp nanpad'];
            tmptmp = mgh_tmp{pltindz(pii)}(bout_indz{rind}{bei});
            mgh{rind, pltindz(pii)}(newboutindzstart:newboutindzstop) = [tmptmp nanpad'];
            tmptmp = rp_tmp{pltindz(pii)}(bout_indz{rind}{bei});
            rp{rind, pltindz(pii)}(newboutindzstart:newboutindzstop) = [tmptmp nanpad'];
            tmptmp = rpr_tmp{pltindz(pii)}(bout_indz{rind}{bei});
            rpr{rind, pltindz(pii)}(newboutindzstart:newboutindzstop) = [tmptmp nanpad']; %can't have nan's because thios scales the plot intensity (color vector element 4, ie domain)
            tmptmp = mpz_tmp{pltindz(pii)}(bout_indz{rind}{bei});
            mpz{rind, pltindz(pii)}(newboutindzstart:newboutindzstop) = [tmptmp nanpad'];

        end

        for spi = 1:length(sideline)
            tmptmp = vec(sdln_tmp{spi}(bout_indz{rind}{bei}));
            sdln{rind, spi}(newboutindzstart:newboutindzstop) = [tmptmp' nanpad'];
        end

        %y shift and pad unwrapped quantities
        cueang2utmp2 = cueang2utmp1(bout_indz{rind}{bei});
        cueang2utmp2 = cueang2utmp2 - (cueang2utmp2(1) - prevend_cueang);
        %prevend_cueang = cueang2utmp2(end);
        cueang2u{rind}(newboutindzstart:newboutindzstop) = [cueang2utmp2; nanpad];

        ballang2utmp2 = ballang2utmp1(bout_indz{rind}{bei});
        %ballang2utmp2 = ballang2utmp2 - (ballang2utmp2(1) - prevend_ballang);
        ballang2utmp2 = ballang2utmp2 - (ballang2utmp2(1) - prevend_cueang);
        %prevend_ballang = ballang2utmp2(end);
        ballang2u{rind}(newboutindzstart:newboutindzstop) = [ballang2utmp2; nanpad];

        for pii=1:length(pltindz)
            mputmp2 = vec(mputmp1{pii}(bout_indz{rind}{bei}));
            %mputmp2 = mputmp2 - (mputmp2(1) - prevend_mpu{pii});
            mputmp2 = mputmp2 - (mputmp2(1) - prevend_cueang);
            %prevend_mpu{pii} = mputmp2(end);
            mpu{rind, pltindz(pii)}(newboutindzstart:newboutindzstop) = [mputmp2; nanpad];
        end

        prevend_cueang = cueang2utmp2(end); %align cueang bumpang and ballang to the cueang position at the end of previous bout



    end

    % %DONT DO THIS, IT'S MISLEADING BECAUSE UNWRAPPED QUANTITIES ARE STILL
    % MEANINGFUL IN Y RANGE (JUST NOT IN Y ABSOLUTE POSITION, WHICH IS WHY
    % THEY ARE Y REGISTERED AT THE START OF EACH BOUT ABOVE)
    % rescale unwrapped/shifted cueang, bumpang, ballang to cueang scale
    % cueang2u{rind} = rescale_to_range(cueang2u{rind}, cueang2u{rind});
    % ballang2u{rind} = rescale_to_range(ballang2u{rind}, cueang2u{rind});
    % for pii=1:length(pltindz)
    %     mpu{rind, pltindz(pii)} = rescale_to_range(mpu{rind, pltindz(pii)}, cueang2u{rind});
    % end


    xxall{rind} = 1:length(cueang2u{rind});

end

%convert nans to zeros for rpr (which is assigned to plot color and cant have nans)
for rind = 1:numr/2
    for pii=1:length(pltindz)
        tmptmp = rpr{rind, pltindz(pii)};
        tmptmp(isnan(tmptmp)) = 0;
        rpr{rind, pltindz(pii)} = tmptmp;
    end
end

%replace diffs greater than pi with nan in the wrapped bumpang plot because the
%lines make it difficult to read
diff_rep_thresh = pi;
diff_spacing1 = 1;
difffilt1 = [zeros(1,diff_spacing1-1) 1 zeros(1,diff_spacing1-1) -1]; %find diffs across larger num samples since sometimes it takes more than 2 samples to go from max to min (-pi to pi) 
diff_spacing2 = 2;
difffilt2 = [zeros(1,diff_spacing2-1) 1 zeros(1,diff_spacing2-1) -1]; %find diffs across larger num samples since sometimes it takes more than 2 samples to go from max to min (-pi to pi) 
for rind = 1:numr/2
    for pii=1:length(pltindz)
        
        %bump angle
        mp_rep{rind, pltindz(pii)} = mp{rind, pltindz(pii)};

        diffsignal = conv(mp{rind, pltindz(pii)}, difffilt1, 'full');
        diffsignal = diffsignal((length(difffilt1) - 1)+1:end-(length(difffilt1) - (1 + (diff_spacing1-1))));
        diffsignal1 = [zeros((diff_spacing1-1)+1, 1); diffsignal];

        diffsignal = conv(mp{rind, pltindz(pii)}, difffilt2, 'full'); 
        diffsignal = diffsignal((length(difffilt2) - 1)+1:end-(length(difffilt2) - (1 + (diff_spacing2-1)))); 
        diffsignal2 = [zeros((diff_spacing2-1)+1, 1); diffsignal];

        excludeinds = abs(diffsignal1)>diff_rep_thresh | abs(diffsignal2)>diff_rep_thresh;
        mp_rep{rind, pltindz(pii)}(excludeinds) = nan; %get index right by appending 0 to front of diff
        
        %vis angle
        ca2_rep{rind, pltindz(pii)} = cueang2{rind};

        diffsignal = conv(cueang2{rind}, difffilt1, 'full');
        diffsignal = diffsignal((length(difffilt1) - 1)+1:end-(length(difffilt1) - (1 + (diff_spacing1-1))));
        diffsignal1 = [zeros((diff_spacing1-1)+1, 1); diffsignal];

        diffsignal = conv(cueang2{rind}, difffilt2, 'full'); 
        diffsignal = diffsignal((length(difffilt2) - 1)+1:end-(length(difffilt2) - (1 + (diff_spacing2-1)))); 
        diffsignal2 = [zeros((diff_spacing2-1)+1, 1); diffsignal];

        excludeinds = abs(diffsignal1)>diff_rep_thresh | abs(diffsignal2)>diff_rep_thresh;
        ca2_rep{rind, pltindz(pii)}(excludeinds) = nan; %get index right by appending 0 to front of diff
        
          
        %ball angle
        ba2_rep{rind, pltindz(pii)} = ballang2{rind};

        diffsignal = conv(ballang2{rind}, difffilt1, 'full');
        diffsignal = diffsignal((length(difffilt1) - 1)+1:end-(length(difffilt1) - (1 + (diff_spacing1-1))));
        diffsignal1 = [zeros((diff_spacing1-1)+1, 1); diffsignal];

        diffsignal = conv(ballang2{rind}, difffilt2, 'full'); 
        diffsignal = diffsignal((length(difffilt2) - 1)+1:end-(length(difffilt2) - (1 + (diff_spacing2-1)))); 
        diffsignal2 = [zeros((diff_spacing2-1)+1, 1); diffsignal];

        excludeinds = abs(diffsignal1)>diff_rep_thresh | abs(diffsignal2)>diff_rep_thresh;
        ba2_rep{rind, pltindz(pii)}(excludeinds) = nan; %get index right by appending 0 to front of diff        


        %previous approach to just take diff: (left some jumps though) mp_rep{rind, pltindz(pii)}([0; diff(mp_rep{rind, pltindz(pii)})]>diff_rep_thresh) = nan; %get index right by appending 0 to front of diff

    end
end

%insert nans separating left and right hemisphere bumps, and adjust bumpangasclust/mgh (creating left and right versions)
for rind = 1:numr/2
    for pii=1:length(pltindz)
        nanins_splitLR = nan(numnanrow_splitLR, size(dp{rind, pltindz(pii)}, 2));
        dp{rind, pltindz(pii)} = [dp{rind, pltindz(pii)}(1:halfcent,:); nanins_splitLR ; dp{rind, pltindz(pii)}(halfcent+1:end,:)];
        mgh_right{rind, pltindz(pii)} = mgh{rind, pltindz(pii)};
        mgh_left{rind, pltindz(pii)} = mgh{rind, pltindz(pii)} + halfcent + numnanrow_splitLR;
    end
end

max_num_clust_whole = -1;
max_num_clust_half = -1;
for pii=1:length(pltindz)
    max_num_clust_whole = max([max_num_clust_whole size(dp{1, pltindz(1)}, 1)]);
    max_num_clust_half = max([max_num_clust_half size(dpsz{1, pltindz(1)}, 1)]);
end

for rind = 1:numr/2
    for pii=1:length(pltindz)
        minyval(rind, pii) = min(vec(dp{rind, pltindz(pii)}));
        maxyval(rind, pii) = max(vec(dp{rind, pltindz(pii)}));
        medianyval(rind, pii) = median([minyval(rind, pii) maxyval(rind, pii)]);
    end
end
if same_y_scale_for_all_epochs
    for rind = 1:numr/2
        for pii=1:length(pltindz)
            minyval(rind, pii) = min(minyval(:));
            maxyval(rind, pii) = max(maxyval(:));
            medianyval(rind, pii) = median([minyval(rind, pii) maxyval(rind, pii)]);
        end
    end
end


extrax = max_num_clust_whole*xlim_makeroomfac;
extrax2 = 2*pi*xlim_makeroomfac;
extrax3 = max_num_clust_half*xlim_makeroomfac;
line_length = 0.25; %fraction of 1 (whole height of fig)
numsidelines = length(sideline);
sidelinepos = linspace(0, extrax2, numsidelines+2);
sidelinepos = sidelinepos(2:end-1);

colord = distinguishable_colors(numsidelines+5);
colord = colord(end-numsidelines:end-1,:);


numfram = plotlen_total_withnanpad; %update for nan padding

for ii = 1:numfram
    for rind = 1:numr/2

        rindo = rind+rind-1; %odds
        rinde = rind+rind; %evens
        spco = [1:numc]+numc*(rindo-1);
        spce = [1:numc]+numc*(rinde-1);

        xx = xxall{rind};

        cind = 1;
        if ii==1
            hax{spco(cind)} = axes( 'Parent', hfg, 'Position', [xp(cind), yp(rindo), wp, hp*2] );
        end

        for pii=1:length(pltindz)
            if pii==1
                yyaxis left
                hax{spco(cind)}.YAxis(2).Visible='off';
            elseif pii==2
                yyaxis right
                hax{spco(cind)}.YAxis(2).Visible='on';
            end
            if ii==1

                hpl{spco(cind)+numtot*(pii-1)} = plot(hax{spco(cind)}, dp{rind, pltindz(pii)}(:,ii), 'Color', plotcolz{pltindz(pii)}, 'Marker', 'none', 'LineStyle', '-');
                hlin{spco(cind)+numtot*(pii-1)} = xline(hax{spco(cind)}, mgh_right{rind, pltindz(pii)}(ii), 'Color', plotcolz{pltindz(pii)});
                hlin{spco(cind)+numtot*(pii-1)+numtot*length(pltindz)} = xline(hax{spco(cind)}, mgh_left{rind, pltindz(pii)}(ii), 'Color', plotcolz{pltindz(pii)});
                first_clust_index = 1; %it's not 0, at the least it's 1
                hax{spco(cind)}.XLim = [first_clust_index  size(dp{rind, pltindz(1)}, 1)];
                xlm = hax{spco(cind)}.XLim;
                hax{spco(cind)}.XTick = [xlm(1) halfcent halfcent+2 xlm(2)]; %linspace(xlm(1), xlm(2), 3);
                hax{spco(cind)}.XAxis.TickLabel = {1, halfcent, 1, halfcent};
                hax{spco(cind)}.XAxis.TickLabelFormat = '%d';
                hax{spco(cind)}.XAxis.FontSize = font1;
                hax{spco(cind)}.XLim = [first_clust_index - extrax size(dp{rind, pltindz(1)}, 1) + extrax];

                hax{spco(cind)}.YAxis(pii).Limits = [minyval(rind, pii) maxyval(rind, pii)];
                ylm = hax{spco(cind)}.YAxis(pii).Limits;
                hax{spco(cind)}.YAxis(pii).TickValues = linspace(ylm(1), ylm(2), 3);
                hax{spco(cind)}.YAxis(pii).TickLabelFormat = '%.1f';
                hax{spco(cind)}.YAxis(pii).FontSize = font1;
                hax{spco(cind)}.YAxis(pii).Color = plotcolz{pltindz(pii)};
                set(hax{spco(cind)},'box','off')

            else
                hpl{spco(cind)+numtot*(pii-1)}.YData = dp{rind, pltindz(pii)}(:,ii);
                hlin{spco(cind)+numtot*(pii-1)}.Value = mgh_right{rind, pltindz(pii)}(ii);
                hlin{spco(cind)+numtot*(pii-1)+numtot*length(pltindz)}.Value = mgh_left{rind, pltindz(pii)}(ii);
            end
        end


        cind = 2;
        if ii==1
            hax{spco(cind)} = axes( 'Parent', hfg, 'Position', [xp(cind), yp(rindo), wp, hp] );
        end

        for pii=1:length(pltindz)
            if pii==1
                yyaxis left
                hax{spco(cind)}.YAxis(2).Visible='off';
            elseif pii==2
                yyaxis right
                hax{spco(cind)}.YAxis(2).Visible='on';
            end
            if ii==1

                linlenrel = line_length*maxyval(rind, pii);

                hpl{spco(cind)+numtot*(pii-1)} = plot(hax{spco(cind)}, aplot_sort{pltindz(pii)}, dps{rind, pltindz(pii)}(:,ii), 'Marker', 'none', 'LineStyle', '-');
                hpl{spco(cind)+numtot*(pii-1)}.Color = plotcolz{pltindz(pii)};
                hpl{spco(cind)+numtot*(pii-1)}.Color(4) = rpr{rind, pltindz(pii)}(ii);
                hlin{spco(cind)+numtot*(pii-1)} = line(hax{spco(cind)}, repelem(mp{rind, pltindz(pii)}(ii), 2), [minyval(rind, pii) linlenrel], 'Color', 'k', 'LineWidth', linwid);
                hlin{spco(cind)+numtot*(pii-1)+numtot*length(pltindz)} = line(hax{spco(cind)}, repelem(cueang2{rind}(ii), 2), [medianyval(pii)-linlenrel/2 medianyval(pii)+linlenrel/2], 'Color', 'k', 'LineWidth', linwid );
                hlin{spco(cind)+numtot*(pii-1)+numtot*length(pltindz)*2} = line(hax{spco(cind)}, repelem(ballang2{rind}(ii), 2), [maxyval(rind, pii)-linlenrel maxyval(rind, pii)], 'Color', 'k', 'LineWidth', linwid );

                for spi = 1:size(sdln, 2)
                    hlinsd{spco(cind)+numtot*(pii-1)+numtot*length(pltindz)*(spi-1)} = line(hax{spco(cind)}, repelem(-pi - sidelinepos(spi), 2), [minyval(rind, pii) maxyval(rind, pii)*sdln{rind, spi}(ii)], 'Color', colord(spi,:), 'LineWidth', linwid );
                end

                hax{spco(cind)}.XLim = [-pi pi];
                xlm = hax{spco(cind)}.XLim;
                hax{spco(cind)}.XTick = linspace(xlm(1), xlm(2), 3);
                hax{spco(cind)}.XAxis.TickLabelFormat = '%.1f';
                hax{spco(cind)}.XTickLabel = {'-pi', '0', 'pi'};
                hax{spco(cind)}.XAxis.FontSize = font1;
                hax{spco(cind)}.XLim = [-pi - extrax2 pi + extrax2];

                hax{spco(cind)}.YAxis(pii).Limits = [minyval(rind, pii) maxyval(rind, pii)];
                ylm = hax{spco(cind)}.YAxis(pii).Limits;
                hax{spco(cind)}.YAxis(pii).TickValues = linspace(ylm(1), ylm(2), 3);
                hax{spco(cind)}.YAxis(pii).TickLabelFormat = '%.1f';
                hax{spco(cind)}.YAxis(pii).FontSize = font1;
                hax{spco(cind)}.YAxis(pii).Color = plotcolz{pltindz(pii)};
                set(hax{spco(cind)},'box','off')

            else
                hpl{spco(cind)+numtot*(pii-1)}.YData = dps{rind, pltindz(pii)}(:,ii);
                hpl{spco(cind)+numtot*(pii-1)}.Color(4) = rpr{rind, pltindz(pii)}(ii);
                hlin{spco(cind)+numtot*(pii-1)}.XData = repelem(mp{rind, pltindz(pii)}(ii), 2);
                hlin{spco(cind)+numtot*(pii-1)+numtot*length(pltindz)}.XData = repelem(cueang2{rind}(ii), 2);
                hlin{spco(cind)+numtot*(pii-1)+numtot*length(pltindz)*2}.XData = repelem(ballang2{rind}(ii), 2);
                for spi = 1:size(sdln, 2)
                    hlinsd{spco(cind)+numtot*(pii-1)+numtot*length(pltindz)*(spi-1)}.YData = [minyval(rind, pii) maxyval(rind, pii)*sdln{rind, spi}(ii)];
                end
            end
        end


        %%%%%%EXTRA PLOT IN COLUMN 2 (USES EVEN ROW INDEX)%%%%%%
        cind = 2;
        if ii==1
            hax{spce(cind)} = axes(  'Parent', hfg, 'Position', [xp(cind), yp(rinde), wp, hp] );
        end

        for pii=1:length(pltindz)
            if pii==1
                yyaxis left
                hax{spce(cind)}.YAxis(2).Visible='off';
            elseif pii==2
                yyaxis right
                hax{spce(cind)}.YAxis(2).Visible='on';
            end
            if ii==1

                hpl{spce(cind)+numtot*(pii-1)} = plot(hax{spce(cind)}, dpsz{rind, pltindz(pii)}(:,ii), 'Marker', 'none', 'LineStyle', '-');
                hpl{spce(cind)+numtot*(pii-1)}.Color = plotcolz{pltindz(pii)};
                hpl{spce(cind)+numtot*(pii-1)}.Color(4) = rpr{rind, pltindz(pii)}(ii);
                hlin{spce(cind)+numtot*(pii-1)} = line(hax{spce(cind)}, repelem(mpz{rind, pltindz(pii)}(ii), 2), [minyval(rind, pii) linlenrel], 'Color', 'k', 'LineWidth', linwid);
                hlin{spce(cind)+numtot*(pii-1)+numtot*length(pltindz)} = line(hax{spce(cind)}, repelem(cueang2z{rind}(ii), 2), [medianyval(pii)-linlenrel/2 medianyval(pii)+linlenrel/2], 'Color', 'k', 'LineWidth', linwid);
                hlin{spce(cind)+numtot*(pii-1)+numtot*length(pltindz)*2} = line(hax{spce(cind)}, repelem(ballang2z{rind}(ii), 2), [maxyval(rind, pii)-linlenrel maxyval(rind, pii)], 'Color', 'k', 'LineWidth', linwid);

                hax{spce(cind)}.XLim = [1 - extrax3 size(dpsz{rind, pltindz(1)}, 1) + extrax3];
                hax{spce(cind)}.XTick = [];
                hax{spce(cind)}.XTickLabel = [];

                hax{spce(cind)}.YAxis(pii).Limits = [minyval(rind, pii) maxyval(rind, pii)];
                ylm = hax{spce(cind)}.YAxis(pii).Limits;
                hax{spce(cind)}.YAxis(pii).TickValues = linspace(ylm(1), ylm(2), 3);
                hax{spce(cind)}.YAxis(pii).TickLabelFormat = '%.1f';
                hax{spce(cind)}.YAxis(pii).FontSize = font1;
                hax{spce(cind)}.YAxis(pii).Color = plotcolz{pltindz(pii)};
                set(hax{spce(cind)},'box','off')

            else
                hpl{spce(cind)+numtot*(pii-1)}.YData = dpsz{rind, pltindz(pii)}(:,ii);
                hpl{spce(cind)+numtot*(pii-1)}.Color(4) = rpr{rind, pltindz(pii)}(ii);
                hlin{spce(cind)+numtot*(pii-1)}.XData = repelem(mpz{rind, pltindz(pii)}(ii), 2);
                hlin{spce(cind)+numtot*(pii-1)+numtot*length(pltindz)}.XData = repelem(cueang2z{rind}(ii), 2);
                hlin{spce(cind)+numtot*(pii-1)+numtot*length(pltindz)*2}.XData = repelem(ballang2z{rind}(ii), 2);
            end
        end



        cind = 3; %WRAPPED
        if ii==1
            hax{spco(cind)} = axes( 'Parent', hfg,  'Position', [xp(cind), yp(rindo), wp*2, hp] );
        end

        for pii=1:length(pltindz)
            if pii==1
                yyaxis left
                hax{spco(cind)}.YAxis(2).Visible='off';
            elseif pii==2
                yyaxis right
                hax{spco(cind)}.YAxis(2).Visible='on';
            end
            if ii==1

                hold(hax{spco(cind)}, 'on')
                plot(hax{spco(cind)}, xx, mp_rep{rind, pltindz(pii)}, 'Color', plotcolz{pltindz(pii)}, 'Marker', 'none', 'LineStyle', '-'); %hpl{spco(cind)+numtot*(pii-1)} =
                plot(hax{spco(cind)}, xx, ca2_rep{rind, pltindz(pii)}, 'Color', 'k', 'LineStyle', '--'); %hpl{spco(cind)+numtot*(pii)+numtot*length(pltindz)} =
                %plot(hax{spco(cind)}, xx, ba2_rep{rind, pltindz(pii)}, 'Color', 'k', 'LineStyle', ':'); %hpl{spco(cind)+numtot*(pii)+numtot*length(pltindz)*2} =
                %plot(hax{spco(cind)}, xx, rp{rind, pltindz(pii)}, 'Color', plotcolz{pltindz(yaxind)}, 'Marker', 'none', 'LineStyle', ':'); %hpl{spco(cind)+numtot*(pii-1)+numtot*length(pltindz)} =
                hold(hax{spco(cind)}, 'off')

                hax{spco(cind)}.XLim = [xx(1) xx(end)];
                xlm = hax{spco(cind)}.XLim;
                hax{spco(cind)}.XTick = linspace(xlm(1), xlm(2), 3);
                hax{spco(cind)}.XAxis.TickLabelFormat = '%.1f';
                hax{spco(cind)}.XAxis.FontSize = font1;

                hax{spco(cind)}.YAxis(pii).Limits = [-pi pi];
                ylm = hax{spco(cind)}.YAxis(pii).Limits;
                hax{spco(cind)}.YAxis(pii).TickValues = linspace(ylm(1), ylm(2), 3);
                hax{spco(cind)}.YAxis(pii).TickLabel = {'-pi', '0', 'pi'};
                hax{spco(cind)}.YAxis(pii).TickLabelFormat = '%.1f';
                hax{spco(cind)}.YAxis(pii).FontSize = font1;
                hax{spco(cind)}.YAxis(pii).Color = plotcolz{pltindz(pii)};

            end
        end
        if ii==1 %why is this xline separate from above subplot directions?
            hlin{spco(cind)} = xline(hax{spco(cind)}, xx(ii), 'k');
            set(hax{spco(cind)},'box','off')
        else
            hlin{spco(cind)}.Value = xx(ii);
        end


        %%%this one gets color plot ind 1 hard coded for first two lines (style distinguishes
        %%%them instead), and black for 3rd line below
        cind = 3; %UNWRAPPED was cind = 4;
        if ii==1
            hax{spco(cind)} = axes(  'Parent', hfg, 'Position', [xp(cind), yp(rinde), wp*2, hp] );
        end

        for pii=1:length(pltindz)
            yyaxis left
            hax{spco(cind)}.YAxis(2).Visible='off';
            yaxind = 1; %created this var bc not the same as subplots above, where this is same as pii
            if ii==1
                hold(hax{spco(cind)}, 'on')
                plot(hax{spco(cind)}, xx, mpu{rind, pltindz(pii)}, 'Color', plotcolz{pltindz(yaxind)}, 'Marker', 'none', 'LineStyle', '-'); %hpl{spco(cind)+numtot*(pii-1)} =
                plot(hax{spco(cind)}, xx, cueang2u{rind}, 'Color', 'k', 'LineStyle', '--'); %hpl{spco(cind)+numtot*(pii)+numtot*length(pltindz)} =
                plot(hax{spco(cind)}, xx, ballang2u{rind}, 'Color', 'k', 'LineStyle', ':'); %hpl{spco(cind)+numtot*(pii)+numtot*length(pltindz)*2} =
                %plot(hax{spco(cind)}, xx, rp{rind, pltindz(pii)}, 'Color', plotcolz{pltindz(yaxind)}, 'Marker', 'none', 'LineStyle', ':'); %hpl{spco(cind)+numtot*(pii-1)+numtot*length(pltindz)} =
                hold(hax{spco(cind)}, 'off')
                hlin{spco(cind)+numtot*(pii-1)} = xline(hax{spco(cind)}, xx(ii), 'k');

                if separate_cueang_and_bump
                    axis_shift_fac1 = [0 1]; %how close (proportion of y range) the ylim is to y min and max, respectively
                else
                    axis_shift_fac1 = [0 0]; %how close (proportion of y range) the ylim is to y min and max, respectively
                end
                hax{spco(cind)}.XLim = [xx(1) xx(end)];
                xlm = hax{spco(cind)}.XLim;
                hax{spco(cind)}.XTick = linspace(xlm(1), xlm(2), 3);
                hax{spco(cind)}.XAxis.TickLabelFormat = '%.1f';
                hax{spco(cind)}.XAxis.FontSize = font1;

                ylm = hax{spco(cind)}.YAxis(yaxind).Limits;
                ylimrange = range(ylm);
                hax{spco(cind)}.YAxis(yaxind).Limits = [ylm(1)-(ylimrange*axis_shift_fac1(1)) ylm(2)+(ylimrange*axis_shift_fac1(2))];
                ylm = hax{spco(cind)}.YAxis(yaxind).Limits;
                hax{spco(cind)}.YAxis(yaxind).TickValues = linspace(ylm(1), ylm(2), 3);
                hax{spco(cind)}.YAxis(yaxind).TickLabelFormat = '%.1f';
                hax{spco(cind)}.YAxis(yaxind).FontSize = font1;
                hax{spco(cind)}.YAxis(yaxind).Color = plotcolz{pltindz(yaxind)};
                set(hax{spco(cind)},'box','off')
            else
                hlin{spco(cind)+numtot*(pii-1)}.Value = xx(ii);
            end

        end


        if 0% strcmp(sorting_target, 'none')

            yyaxis right
            hax{spco(cind)}.YAxis(2).Visible='on';
            yaxind = 2;

            %%"SKIPPING cueang PLOT SINCE EVERYTHING IS bumpang-SORTED, NOT TIME-SORTED"
            %DECIDED TO NOT SWITCH TO YAXIS RIGHT FOR THESE SINCE THEY ARE
            %ALL NORMALIZEDF
            % yyaxis right
            % yaxind = 2; %on this subplot switch y axis index here, rather than with pii loop
            %yaxind = 2; %on this subplot switch y axis index here, rather than with pii loop
            if ii==1
                hold(hax{spco(cind)}, 'on')
                plot(hax{spco(cind)}, xx, cueang2u{rind},'k', 'LineStyle', '--'); %hpl{spco(cind)+numtot*(pii)+numtot*length(pltindz)} =
                plot(hax{spco(cind)}, xx, ballang2u{rind},'k', 'LineStyle', ':'); %hpl{spco(cind)+numtot*(pii)+numtot*length(pltindz)*2} =

                hold(hax{spco(cind)}, 'off')
                hax{spco(cind)}.XLim = [xx(1) xx(end)];

                if separate_cueang_and_bump
                    axis_shift_fac2 = [1 0]; %how close (proportion of y range) the ylim is to y min and max, respectively
                else
                    axis_shift_fac2 = [0 0]; %how close (proportion of y range) the ylim is to y min and max, respectively
                end
                ylm = hax{spco(cind)}.YAxis(yaxind).Limits;
                ylimrange = range(ylm);
                hax{spco(cind)}.YAxis(yaxind).Limits = [ylm(1)-(ylimrange*axis_shift_fac2(1)) ylm(2)+(ylimrange*axis_shift_fac2(2))];
                ylm = hax{spco(cind)}.YAxis(yaxind).Limits;
                hax{spco(cind)}.YAxis(yaxind).TickValues = linspace(ylm(1), ylm(2), 3);
                hax{spco(cind)}.YAxis(yaxind).TickLabelFormat = '%.1f';
                hax{spco(cind)}.YAxis(yaxind).FontSize = font1;
                hax{spco(cind)}.YAxis(yaxind).Color = [0 0 0];
                set(hax{spco(cind)},'box','off')
            end

        end


    end

    
    fig2gif(hfg, ii, pthgif)


    %
    % for hi = 1:length(hndllin)
    %     delete(hndllin{hi})
    % end
    % for hi = 1:length(hndlpl)
    %     delete(hndlpl{hi})
    % end



end

close all
