function roimaskout = roimauto(stack, roimaskin, widyxz, opt, opt2)

arguments
    stack %can also be stack mean t (see below, stack just gets averaged if 4th dim is greater than 1)
    roimaskin
    widyxz
    opt
    opt2.pthstack = []
    opt2.rg = []
    opt2.maskname = []
end

chan = opt.chan;
numroi_init = opt.numroi;
maskmake = opt.maskmake;
maskseg = opt.maskseg;
roirad = opt.roirad;
edgethr = opt.edgethr;
edgesig = opt.edgesig;
celsz = opt.celsz;
do3d = opt.do3d;

pthstack = opt2.pthstack;
rg = opt2.rg;
maskname = opt2.maskname;

if isempty(rg)
    [~, rg] = stackcrop(stack, pthstack); %if rg is empty, it's default, which is no crop, so no need to output stack
end
rgname = rg.name;

if size(stack,4)>1
    stackmnt = mean(stack,4);
else
    stackmnt = stack;
end

id = idmake(pthstack);
fnsuffix = ['_' rgname '_' maskname '_ma'];
pthma = [id.pthrec, fnsuffix, '_.mat'];


numchan = size(stackmnt,5);

try

    load(pthma, 'ma');

    for c = 1:numchan
        if ismember(c,chan)
            if ~isequal(numroi_init, 0)
                roimaskout{c} = ma{c}.mask;
            end
        end
    end

    if any(~isfield(ma{1}, {'mask', 'mask_in', 'rg', 'maskname', 'opt'})) || numel(ma)==2 && any(~isfield(ma{2}, {'mask', 'mask_in', 'rg', 'maskname', 'opt'}))
        error("ma struct must contain fields 'mask', 'mask_in', 'rg', 'maskname', 'opt'; you may have loaded an old ma struct")
    end
    if ~isequal(ma{1}.rg, rg) || numel(ma)==2 && ~isequal(ma{2}.rg, rg)
        error("ma file exists but for at least one channel rg in ma file does not match current rg with same name; did you delete the rg you used to draw this ma?")
    end
    if ~isequal(ma{1}.maskname, maskname) || numel(ma)==2 && ~isequal(ma{2}.maskname, maskname)
        error("ma file exists but input roimask maskname does not match for at least one channel")
    end
    if ~isequal(ma{1}.opt, opt) || numel(ma)==2 && ~isequal(ma{2}.opt, opt)
        error("ma file exists but input roimask maskname does not match for at least one channel")
    end

catch ME

    for c = 1:numchan
        if ismember(c,chan)
            if ~isequal(numroi_init, 0)
                roimaskout{c} = roimauto_onechan(stackmnt(:,:,:,:,c), roimaskin{c}, numroi_init, widyxz, rgname, maskmake, maskseg, roirad, edgethr, edgesig, celsz, do3d);
                ma{c}.mask = roimaskout{c};
                ma{c}.mask_in = roimaskin{c};
                ma{c}.rg = rg;
                ma{c}.maskname = maskname;
                ma{c}.opt = opt;
            end
        end
    end

    save(pthma, 'ma', '-v7.3') %save each channel's mask separately (could do it together instead, either way is fine right?)

end


end

function roimaskout = roimauto_onechan(stackmnt, roimaskin, numroi_init, widyxz, rgname, maskmake, maskseg, roirad, edgethr, edgesig, celsz, do3d)

%this function has several partially overlapping control features,
%organization is meant to make it easy to add new methods (e.g. by
%creating new maskseg and inserting in switch statement)
%stackmnt must be 3d (xyz), although 3rd dim (z) can be singleton
%roimaskin must match dimensionality of stackmnt, or be lower dimensional

%% preprocess stackmnt, make mean stackmnt


stackmnt = rescale(stackmnt);
numel_stackmnt = numel(stackmnt);

ywid = widyxz(1);
xwid = widyxz(2);
zwid = widyxz(3);

if isempty(roimaskin)
    roimaskin = 1;
end

num_roim_manual = size(roimaskin, 4);

if strcmp(maskseg, 'torus') && ~strcmp(maskmake, 'none')
    error("for maskseg torus maskmake should be none, otherwise your ellipse might fall outside the mask (ellipse should determine the mask itself)")
end

if num_roim_manual>1
    error(sprintf("num_roim_manual is greater than one AND numroiauto is greater than zero" + newline + ...
        "DELETE OR RENAME pth_roimaskman AND DRAW MANUAL MORPHOLOGICAL ROIS AGAIN" + newline + ...
        "OR KEEP MANUAL MORPHOLOGICAL ROIS AND REQUEST 0-1 AUTOMATED MORPHOLOGICAL ROIS" + newline))
end


if do3d==1 && size(stackmnt, 3)==1 %if z dim is singleton
    fprintf("WARNING, cannot make requested 3d mask because stackmnt is 2d, making 2d mask instead" + newline)
    do3d = 0; %override if stackmnt is only 2d
end

% if do3d==0 && size(stackmnt, 3)>1
%     stackmnt = rescale(mean(stackmnt, 3));
% end


%% mask mean stackmnt with any available manual mask (if none was made, roimaskin is all ones, ie has no effect)

roimaskman_allrois = logical(sum(roimaskin, 4)); %if there's a 4th dim, it's rois co collapse it
premask = stackmnt.*roimaskman_allrois; %don't change this variable because you need it below


%% threshold premask to create mask

mask_allroi_approx = zeros(size(premask));

switch maskmake

    case 'edge' %find 3d mask edges, smooth them, apply morphological close

        if do3d && size(premask, 3)>1
            bookend = zeros(size(premask, 1), size(premask, 2));
            premask = cat(3, bookend, premask, bookend); %bookend with zeros to help 3d edge detection in z
            mask_allroi_approx = edge3(premask, 'approxcanny', edgethr, edgesig);
            premask = premask(:,:,2:end-1);
            mask_allroi_approx = mask_allroi_approx(:,:,2:end-1);
        else
            for tui = 1:size(premask, 3)
                mask_allroi_approx(:,:,tui) = edge(premask(:,:,tui), 'canny', edgethr, edgesig(1));
            end
        end
        mask_allroi_approx = imclose(mask_allroi_approx, strel('disk',celsz)); %this is a 2d closing element so works in 2d or 3d basically the same, 2d keeps this section of code shorter,

    case 'outlier' %mask is outlier

        idxnz = find(premask~=0); %find nonzero indices (use find because you index into this below, so you don't want a logical array)
        premask(idxnz) = rescale(premask(idxnz));
        mask_allroi_approx(idxnz(isoutlier(premask(idxnz)))) = 1;

    case 'triangle' %triangle threshold (and similar alternative in knee_pt)

        premask_nz = premask(premask~=0);

        [histdt, histx] = hist( premask_nz, 1000);
        thrbin_tri = triangle_threshold(histdt, 'R', 0); %last arg 1 to plot
        thr_tri = histx(thrbin_tri);

        [~, thrbin_knee] = knee_pt(premask_nz, [], 1, 1);
        thr_knee = premask_nz(thrbin_knee);

        mask_allroi_approx(premask<thr_tri) = 1;

    case 'nonzero' %all nonzero elements

        mask_allroi_approx = logical(premask);

    case 'none' %all nonzero elements

        mask_allroi_approx = ones(size(premask), 'logical');

end

mask_allroi_approx = logical(mask_allroi_approx);

[masky,maskx,maskz] = ind2sub(size(mask_allroi_approx), find(mask_allroi_approx)); %find the cartesian coordinates of points in the mask


%% find 3d mask centroids

numroi_final = numroi_init; %as of 240605 these will match for all cases except 'uniform' or 'uniformp' where do3d~=0

if numroi_init == 1 %for finding a single centroid

    roicen = find_roi_centroids(mask_allroi_approx);

else

    switch maskseg

        case 'torus' % create multiple roughly equal-volume roi along skeleton of mask

            if ndims(stackmnt)<3
                error("stackseg 'torus' requires nonsingleton yxz dimensions (can't be planar right now)")
            end

            widmin = min(widyxz);
            upfac = widyxz / widmin;
            sz = size(stackmnt);
            szup = round(sz.*upfac);

            stackup = imresize3(stackmnt, szup, 'linear');
            rots = -1*[0:5:180];
            stackmnzrot = {};
            for k = 1:numel(rots)
                tform = rigidtform3d([rots(k),0,0], [0,0,0]);
                [tmp, ov2] = imwarp(stackup, imref3d(size(stackup)), tform); %default output view is centeroutput
                tmp = mean(tmp, 3);
                stackmnzrot{k} = tmp;
            end
            szmx = max(cell2mat(cellfun(@size, stackmnzrot, 'UniformOutput', false)'));
            tmp = zeros([szmx, numel(stackmnzrot)]);
            for k = 1:numel(stackmnzrot)
                tmp(1:size(stackmnzrot{k},1), 1:size(stackmnzrot{k},2), k) = stackmnzrot{k};
            end
            stackplt(tmp, dmplt='yx(z)', title_prefix=['rotations: ' num2str(rots)]);
            stackplt(tmp, title_prefix=['rotations: ' num2str(rots)]);

            prompt = sprintf("ENTER DEGREES TO ROTATE STACK FORWARD (ALONG X AXIS), OR EMPTY TO NOT ROTATE: ");
            commandwindow();
            drawrot = input(prompt);
            drawrot = drawrot * -1;
            if drawrot
                tform = rigidtform3d([drawrot,0,0], [0,0,0]);
                [stackrot, ov2] = imwarp(stackup, imref3d(size(stackup)), tform); %default output view is centeroutput
            else
                stackrot = stackup;
            end

            stackplt(stackrot, dmplt='yx(z)')
            prompt = sprintf("ENTER Z-INDICES YOU WANT TO SUM TO CREATE BACKGROUND FOR MANUALLY POSITIONING ROI CENTROIDS (MEAN OF CHOSEN Z INDICES WILL BE Z COORDINATE FOR ROI CENTROIDS), OR ENTER NOTHING TO POSITION CENTROIDS ON ALL Z SLICES SEPARATELY: ");
            commandwindow();
            drawslice = input(prompt);

            [roicentmp, midx, midy] = drawcent(stackrot, drawslice, numroi_init);

            roicentmp = roicentmp + fix([ov2.YWorldLimits(1), ov2.XWorldLimits(1), ov2.ZWorldLimits(1)]);
            [roicentmp(:,2), roicentmp(:,1), roicentmp(:,3)] = transformPointsInverse(tform, roicentmp(:,2), roicentmp(:,1), roicentmp(:,3));

            roicentmp = roicentmp ./ upfac;

            roicentmp(:,widyxz>roirad) = round(roicentmp(:,widyxz>roirad)); %round dimension with resolution lower than roi radius to prevent empty rois

            style = "MaximumIntensityProjection"; %"GradientOpacity"
            vwr = viewer3d();
            hfg = vwr.Parent;
            szftmp = figsz();
            hfg.Position = [0 0 szftmp];
            vwr.Lighting='off';
            vwr.BackgroundGradient='off';
            vwr.GradientColor=[0 0 0.2];
            vwr.BackgroundColor=[1 1 1];
            vsh(1) = volshow(stackmnt, Parent=vwr);
            vsh(1).RenderingStyle=style;
            % vsh(1).GradientOpacityValue=0.1;
            % vsh(1).Colormap=cmap;
            % vsh(2).Alphamap=0.1;
            tmp = volmaskmake(roirad, xwid, ywid, zwid, stackmnt, mask_allroi_approx, roicentmp);
            tmp = logical(sum(tmp,4));
            vsh(2) = volshow(tmp, Parent=vwr);
            % vsh(2).RenderingStyle=style;
            % vsh(2).OverlayRenderingStyle="GradientOverlay";
            fig2gif(hfg)

        case 'skeleton' % create multiple roughly equal-volume roi along skeleton of mask

            if do3d
                min_axis = min([range(maskx),range(masky),range(maskz)]);
                max_axis = max([range(maskx),range(masky),range(maskz)]);
            else
                min_axis = min([range(maskx),range(masky)]);
                max_axis = max([range(maskx),range(masky)]);
            end
            mid = bwskel(mask_allroi_approx,'MinBranchLength',min_axis); %find the midline as the skeleton, shaving out all sub branches that are smaller than the minimum axis length
            ep = (convn(double(mid),ones(3,3,3),'same')<3).*mid;
            [y0,x0,z0] = ind2sub(size(ep),find(ep,1)); %the "starting point" endpoint

            [midy,midx,midz] = ind2sub(size(mid),find(mid));

            if length(midy)>1

                midz_check = midz;
                [midx,midy,midz] = graph_sort3(midx,midy,midz); %here set up to work for 2d and 3d align the points of the midline starting at the first point and going around in a circle. this requires that the midline be continuous!
                if numel(midz)~=numel(midz_check)
                    error("you are attempting to use maskseg skeleton for 2d extraction from a 3d stack with a manual mask that is discontiguous in z; maskseg skeleton cannot yet accommodate that, but uniform and uniformp can; or your skeleton is just discontiguous in 3d")
                end
                xq = [-min_axis:(length(midx)+min_axis)]; %extend the midline so that it reaches the border of the mask. extrapolate as many points as the minimum axis length

                midx = round(interp1(midx,xq,'linear','extrap'));
                midy = round(interp1(midy,xq,'linear','extrap'));
                midz = round(interp1(midz,xq,'linear','extrap'));

                idxmidkeep = ismember([midx',midy',midz'],[maskx,masky,maskz],'rows'); %keep only the points that exist within the mask
                midx = midx(idxmidkeep);
                midy = midy(idxmidkeep);
                midz = midz(idxmidkeep);

                xq = linspace(1, length(midy), 2*(numroi_init) + 1)'; %set query points for interpolation (the number of centroids we want). we'll create twice as many points and take every other so that rois on the edges arent clipped
                roicentmp = [interp1(midy,xq), interp1(midx,xq), interp1(midz,xq)]; %interpolate x and y coordinates, now that they are ordered, into evenly spaced centroids (this allows one to oversample if desired)
                roicentmp = roicentmp(2:2:end-1,:); %take every other so that we dont start at the edges, and all are same size

            else

                error(sprintf("region '" + rgname + "' is roughly uniform blob, so maskseg 'skeleton' fails; try maskseg 'uniform' for roughly equal-volume ROIs within 2d or 3d rgname"))

            end

        case {'uniform'} % create multiple roughly equal-volume roi by partitioning rgname into numroi_init groups

            if isempty(widyxz)
                error("you did not pass argument widyxz, or you passed empty widyxz, but you also requested maskseg 'uniform', which requires nonempty argument widyxz")
            end


            if do3d

                [tmp, roicentmp, bin_prctiles] = probability_bin([masky, maskx, maskz], numroi_init, 1, 0); %iteratively median split along dimension of greatest variance, ties are randomly assigned, so as of 240509, results are not reproducible, although differences are typically not major; so for reproducibility, pipeline loads saves/loads previous results

            else %else split into roughly equal area rois on each slice in mask, rounding number rois for each slice to nearest power of 2 proportional to number of voxels relative to total (typically lots of inaccuracy there)

                uz = unique(maskz);
                for uzi = 1:numel(uz)
                    zinds_each{uzi} = find(maskz==uz(uzi));
                    num_vox_each_slice(uzi) = numel(zinds_each{uzi});
                    frac_vox_each_slice(uzi) = num_vox_each_slice(uzi) / numel(maskz);
                    ideal_roim_auto_each_slice(uzi) = frac_vox_each_slice(uzi) * numroi_init;
                end
                rnds = pow2(round(log2(ideal_roim_auto_each_slice))); %rnds = round(frac_roim_auto_each_slice);

                numroi_final = sum(rnds);
                if numroi_init~=numroi_final
                    sprintf("warning, changing numroi_init is " + num2str(numroi_init) + " while numroi_final is " + num2str(numroi_final))
                    pause(2)
                end

                tmp = zeros([numel(masky) 2], 'uint16');
                roicentmp = [];
                bin_prctiles = [];
                rndsprev = 0;
                for uzi = 1:numel(rnds)
                    [tmp_xy, centmp_xy, bin_prctiles_xy] = probability_bin([masky(zinds_each{uzi}), maskx(zinds_each{uzi})], rnds(uzi), 1, 0); %iteratively median split along dimension of greatest variance, ties are randomly assigned, so as of 240509, results are not reproducible, although differences are typically not major; so for reproducibility, pipeline loads saves/loads previous results
                    kpinds = ~isnan(sum(centmp_xy));
                    centmp_xy = centmp_xy(:,kpinds);
                    bin_prctiles_xy = bin_prctiles_xy(kpinds);
                    currslice = uz(uzi);
                    tmp(zinds_each{uzi},:) = tmp_xy+rndsprev;
                    rndsprev = max(vec(tmp));
                    centmp_xyz = [centmp_xy; ones(1, size(centmp_xy, 2))*currslice];
                    roicentmp = [roicentmp centmp_xyz];
                    bin_prctiles = [bin_prctiles; bin_prctiles_xy];
                end
            end
            if size(unique(tmp.', 'rows'), 1)~=1
                error("each row must have constant value")
            end
            % idx_vox2roi = tmp(:,1); %previously this was an alternative to deriving idx_vox2roi below; it is very similar
            roicentmp = roicentmp.';
            roicentmp2 = roicentmp;
            roicentmp(:,1) = roicentmp2(:,2);
            roicentmp(:,2) = roicentmp2(:,1);
    end

    roicen = cell(1, size(roicentmp, 1));
    for crmi = 1:size(roicentmp, 1)
        roicen{crmi} = roicentmp(crmi, :); %convert to cell, since roicen is cell elsewhere (to support rois with varying number of discontiguous parts, even though that doesn't occur when using maskseg 'equidistant')
    end

end

%% assign voxels in mask to roi centroids

if roirad %if roirad is not empty, make little spheres (or circles, if 2d) around each centroid, radius roirad

    roimaskout = volmaskmake(roirad, xwid, ywid, zwid, stackmnt, mask_allroi_approx, roicen);

else %otherwise each centroid gets nearest voxels

    roicenvec = cell2mat(roicen(:));
    flatten_key = cell2mat(arrayfun(@(idx) [repmat(idx,size(roicen{idx},1),1), (1:size(roicen{idx},1)).'], (1:numel(roicen)).', 'uniform', 0));
    [~, maptmp] = pdist2(roicenvec, [masky, maskx, maskz], 'euclidean', 'smallest', 1); %find the index of the centroid that is closest to each voxel in the mask. using euclidean, but maybe chebychev (chessboard)
    idx_vox2roi = uint16(flatten_key(maptmp, 1)); %this records which cell the nearest morph centroid is from

    roiwt = zeros(numroi_final, numel_stackmnt, 'single'); %size [rois, voxels], describes how each voxel contirbutes to roi response, since roi can occupy less than entire voxel (in z dimension especially)
    for i = 1:numroi_final
        roiwt(i, sub2ind(size(mask_allroi_approx), masky(idx_vox2roi==i), maskx(idx_vox2roi==i), maskz(idx_vox2roi==i))) = 1; %indices of each roi
    end

    roiwt = roiwt';
    if ndims(stackmnt)==2
        roimaskout = reshape(roiwt, [size(stackmnt), 1, numroi_final] );
    elseif ndims(stackmnt)==3
        roimaskout = reshape(roiwt, [size(stackmnt), numroi_final] );
    end

end



end



function [roicen_nonuniform, midx, midy] = drawcent(stack, drawslice, numroi_init)


if isempty(drawslice)

    ax = axarr(stack);
    h = initfig();
    h.st = initaxim(h.hfg, ax, stack, doui=1);

    user_input = [];
    roicen_nonuniform = {};
    numslice = numel(h.st.hpl);
    cnt = 0;
    while true
        pause(0.05)
        if isempty(user_input)
            for j = 1:numslice
                user_input = h.st.hpl{j}.UserData;
                h.st.hpl{j}.UserData = [];
                if ~isempty(user_input)
                    cnt = cnt + 1;
                    user_input = [user_input j];
                    roicen_nonuniform{cnt} = user_input;
                end
            end
        end
        currkey = get(gcf, 'CurrentKey');
        if strcmp(currkey , 'return')
            break;
        end
    end
    roicen_nonuniform = cell2mat(roicen_nonuniform');
    roicen_nonuniform(end+1,:) = roicen_nonuniform(1,:);

    midx = [];
    midy = [];

    % figure; hold on
    % for k = 2:size(uiall,1)
    %     pts = [uiall(k-1,:); uiall(k,:)];
    %     hpl3 = plot3(pts(:,1), pts(:,2), pts(:,3));
    % end

else

    doellipse = 0;

    stack = mean(stack(:,:,drawslice),3);
    hfg = figure;
    imagesc(stack);
    axis image
    if doellipse
        hell = drawellipse();
    else
        hell = drawpolygon(); % previously was drawellipse(), but eb is often not elliptica, so changed to polygonl
    end
    input('') %move on once user presses enter, after adjusting the ellipse
    mask = createMask(hell);
    close(hfg);
    mid = bwmorph(mask, 'remove');
    [midy,midx] = find(mid); %by definition, the skeleton has to be at least as long as the min width of the roi, so shave out subbranches that are shorter than that.
    [midx,midy] = graph_sort(midx,midy); %align the points of the midline starting at the first pointpoint and going around in a circle. this requires that the midline be continuous!
    xq = linspace(1,length(midy),numroi_init)'; %set query points for interpolation (the number of centroids we want). we'll create twice as many points and take every other so that clusters on the edges arent clipped
    roicen_nonuniform = [interp1(1:length(midy),midy,xq),interp1(1:length(midx),midx,xq)]; %interpolate x and y coordinates, now that they are ordered, into evenly spaced centroids (this allows one to oversample the number of pixels, if desired)
    if roicen_nonuniform(1,1) < roicen_nonuniform(end,1)
        % error("should this happen ever?")
        roicen_nonuniform = flipud(roicen_nonuniform);
    end
    roicen_nonuniform(:,3) = mean(drawslice); %previously was mean(1:size(stackmnt,1));

    if doellipse
        doplt = 1;
        roicen_xy = e2c([midx, midy], numroi_init, doplt);
        roicen(:,1:2) = [roicen_xy(:,2) roicen_xy(:,1)];
    else
        roicen(:,1:2) = roicen_nonuniform(:,1:2);
    end
    roicen(:,3) = mean(drawslice); %previously was mean(1:size(stackmnt,1));

    hfg = figure;
    imagesc(stack)
    colormap(bone)
    hold on
    plot(midx, midy, 'w')
    cmap = distinguishable_colors(numroi_init);
    scatter(roicen(:,2), roicen(:,1), [], cmap, 'filled')
    axis image tight
    fig2gif(hfg)
    close(hfg);

end




end


function roimaskout = volmaskmake(roirad, xwid, ywid, zwid, stackmnt, mask_allroi_approx, roicen)

if ~iscell(roicen)
    roicentmp = cell(1, size(roicen, 1));
    for crmi = 1:size(roicen, 1)
        roicentmp{crmi} = roicen(crmi, :); %convert to cell, since roicen is cell elsewhere (to support rois with varying number of discontiguous parts, even though that doesn't occur when using maskseg 'equidistant')
    end
    roicen = roicentmp;
end
roirad = roirad*xwid; %roirad units are xwid (microns in x dimension)

if zwid==0
    [umx, umy] = meshgrid(0:xwid:xwid*(size(stackmnt,2)-1), 0:ywid:ywid*(size(stackmnt,1)-1)); %microns
    %[umx, umy] = meshgrid(0:size(stackmnt,2)-1, 0:size(stackmnt,1)-1); %pixels
    umz = [];
else
    [umx, umy, umz] = meshgrid(0:xwid:xwid*(size(stackmnt,2)-1), 0:ywid:ywid*(size(stackmnt,1)-1), 0:zwid:zwid*(size(stackmnt,3)-1)); %microns
    %[umx, umy, umz] = meshgrid(0:size(stackmnt,2)-1, 0:size(stackmnt,1)-1, 0:size(stackmnt,3)-1); %pixels
end

roimaskout = zeros([size(mask_allroi_approx) numel(roicen)], 'logical');
roimaskout_tmp = zeros(size(mask_allroi_approx), 'logical');
for j = 1:numel(roicen)
    roimaskout_tmp(:) = 0;
    roicentmp = [ywid*roicen{j}(1)-1, xwid*roicen{j}(2)-1, zwid*roicen{j}(3)-1];
    if zwid==0
        roimaskout_tmp((umy - roicentmp(1)).^2 + (umx - roicentmp(2)).^2 <= roirad.^2) = 1;
    else
        roimaskout_tmp((umy - roicentmp(1)).^2 + (umx - roicentmp(2)).^2 + (umz - roicentmp(3)).^2 <= roirad.^2) = 1;
    end
    roimaskout(:,:,:,j) = roimaskout_tmp;
end

end
