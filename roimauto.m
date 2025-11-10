function [roimaskout, opt] = roimauto(stack, opt, opt2)

arguments

    stack %can also be stack mean t (see below, stack just gets averaged if 4th dim is greater than 1)
    
    opt.chan = 1; %1, 2, or [1 2], which channel gets auto roi extraction; this is stack index, not pmt index; (for now all options below are same for each) option where auto rois interact has not been written yet);
    opt.numroi = 128; %partition rgname into numroi morphological rois; a drawn roi, if it exists, masks the rgname prior to automated super-roi extraction; num_roim_auto and number drawn rois cannot both exceed 1 (i.e. the code cannot automatically partition discontiguous rois within a single rgname)
    opt.maskmake = 'nonzero'; % %method for automatically defining morphological roi mask (union of all morphological rois) from stack or union of manually drawn rois, options are 'edge', 'outlier', 'triangle', 'nonzero'
    opt.maskseg = 'uniform'; %'skeleton' for elongated structures or 'uniform'; method for subsampling mask into rois; for 'uniform', o.roi.ma.num_roim_auto_str must be power of 2 and works best for convex structures since for concave structures it will find rois outside the structure but can be masked to remove orois outside the structure afterward
    opt.roirad = []; %radius of roi (circle if 2d, sphere if 3d) centered on roi centroid; make this empty to have voxels mapped to roi centroid using euclidian distance; units are length of pixel in x (if z length is double x and y length, roirad 6 is 2 pixels in x and y, and 1 in z)
    opt.edgethr = [0.1, 0.7]; %two thresholds to detect strong and weak edges; includes weak edges in output only if they are connected to strong edges
    opt.edgesig = [3, 3, 3]; %for edge detection, defines smoothing filter sigma for each dim xyz, or use one value for all dim, if 2d edge detection, first element is used for x and y
    opt.celsz = 8; %for bwmorph close after edge detection, helps connect edges
    opt.do3d = 1; %1 makes 3d mask unless stack is 2d, 0 makes 2d mask for 2d, 3d, or 4d stack input
    
    opt2.md = []
    opt2.widyxz = []
    opt2.roimaskin = []
    opt2.pthstack = []
    opt2.rg = []
    opt2.roiname = []
    opt2.runtype (1,1) {mustBeBinary} = 0 %runtype controls how much of this function to run; 0 to run entire function; 1 to do nothing but validate input arguments and return arguments block struct opt (not any other input arguments, since only opt is under id-control) 

end

if opt2.runtype
    roimaskout = [];
    return
end

chan = opt.chan;
numroi = opt.numroi;
maskmake = opt.maskmake;
maskseg = opt.maskseg;
roirad = opt.roirad;
edgethr = opt.edgethr;
edgesig = opt.edgesig;
celsz = opt.celsz;
do3d = opt.do3d;

md = opt2.md;
widyxz = opt2.widyxz;
roimaskin = opt2.roimaskin;
pthstack = opt2.pthstack;
roiname = opt2.roiname;
rg = opt2.rg;

if size(stack,4)>1
    stackmnt = mean(stack,4);
else
    stackmnt = stack;
end

numchan = size(stackmnt,5);

if isempty(md)
    md = mdsild(pthstack);
end
if isempty(widyxz)
    widyxz = md.widyxz;
end
if isempty(roimaskin)
    roimaskin = cell(numchan,1);
end
if isempty(pthstack)
   error("must set pthstack")
end
if isempty(roiname)
   roiname = 'none';
end
if isempty(rg)
    [~, rg] = rgmake(stack, pthstack=pthstack); %if rg is empty, it's default, which is no crop, so no need to output stack
end
rgname = rg.rgname;


cellout = 0;
if iscell(roimaskin)
    if numel(roimaskin)>1
        cellout = 1;
        if numchan==1
            error("if numchan==1, roimask must be cell with numchan elements")
        end
    end
else
    if numchan>1
        error("if numchan>1, roimask must be cell with numchan elements")
    end
    roimaskin = {roimaskin};
end

pthrec = idmake(pthstack, 'pthrec');
fnsuffix = ['_' rgname '_' roiname '_ma'];
pthma = [pthrec, fnsuffix, '_.mat'];

roimaskout = roimaskin;

try

    load(pthma, 'ma');

    for c = chan
        roimaskout{c} = ma(c).mask;
    end

    if any(~isfield(ma(1), {'mask', 'mask_in', 'rg', 'roiname', 'opt'})) || numel(ma)==2 && any(~isfield(ma(2), {'mask', 'mask_in', 'rg', 'roiname', 'opt'}))
        error("ma struct must contain fields 'mask', 'mask_in', 'rg', 'roiname', 'opt'; you may have loaded an old ma struct")
    end
    if ~isequal(ma(1).rg, rg) || numel(ma)==2 && ~isequal(ma(2).rg, rg)
        error("ma file exists but for at least one channel rg in ma file does not match current rg with same name; did you delete the rg you used to draw this ma?")
    end
    if ~isequal(ma(1).roiname, roiname) || numel(ma)==2 && ~isequal(ma(2).roiname, roiname)
        error("ma file exists but input roimask roiname does not match for at least one channel")
    end
    if ~isequal(ma(1).opt, opt) || numel(ma)==2 && ~isequal(ma(2).opt, opt)
        error("ma file exists but input roimask roiname does not match for at least one channel")
    end

catch ME

    clear ma %in case old ma was loaded and errored, remove this soon

    for c = chan
        roimaskout{c} = roimauto_onechan(stackmnt(:,:,:,:,c), roimaskin{c}, numroi, widyxz, rgname, maskmake, maskseg, roirad, edgethr, edgesig, celsz, do3d);
        ma(c).mask = roimaskout{c};
        ma(c).mask_in = roimaskin{c};
        ma(c).rg = rg;
        ma(c).roiname = roiname;
        ma(c).opt = opt;
    end

    if chan==1 && numchan==2 %do this so that 2-channel data gets empty 2nd element if channel 2 has no auto rois, otherwise 2nd element wouldn't exist, which would mislead user into thinking it's single-channel data
        ma(2) = structfun(@(x) [], ma, 'UniformOutput', false);
    end
    if ~exist('ma', 'var')
        ma = [];
    end

    save(pthma, 'ma', '-v7.3') %save each channel's mask separately (could do it together instead, either way is fine right?)

end

if ~cellout
    roimaskout = cell2mat(roimaskout);
end

end

function roimaskout = roimauto_onechan(stackmnt, roimaskin, numroi, widyxz, rgname, maskmake, maskseg, roirad, edgethr, edgesig, celsz, do3d)

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

roirad = roirad*xwid; %roirad units are xwid (microns in x dimension)


if isempty(roimaskin)
    roimaskin = 1;
end


if strcmp(maskseg, 'torus') && ~strcmp(maskmake, 'nonzero')
    error("for maskseg torus maskmake should be nonzero (everything but any manually drawn mask), otherwise your ellipse might fall outside the mask (still could happen with method 'nonzero'")
end

numroi_roimaskin = size(roimaskin, 4);
numsubroi_roimaskin = size(regionprops3(sum(roimaskin,4)),1); %regionprops3 works for 2d or 3d, output is table, num rows is disconnected components (subrois)
if numroi_roimaskin>1 || numsubroi_roimaskin>1
    error("numroi_roimaskin IS GREATER THAN ONE AND numroiauto IS GREATER THAN ZERO" + newline + ...
        "THIS FUNCTION CURRENTLY ONLY OPERATES ON A SINGLE CONTIGUOUS ROI" + newline + ...
        "DELETE OR RENAME FILE WITH DRAWN ROIS AND DRAW ROIS AGAIN" + newline + ...
        "OR KEEP DRAWN ROIS AND REQUEST 0-1 AUTOMATED MORPHOLOGICAL ROIS" + newline)
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

end

mask_allroi_approx = logical(mask_allroi_approx);

[masky,maskx,maskz] = ind2sub(size(mask_allroi_approx), find(mask_allroi_approx)); %find the cartesian coordinates of points in the mask


%% find 3d mask centroids

if numroi == 1 %for finding a single centroid

    roicen = find_roi_centroids(mask_allroi_approx);

else

    switch maskseg


        case 'e3d'

            if ndims(premask)<3
                error("stackseg 'torus' requires nonsingleton yxz dimensions (can't be planar right now)")
            end

            [premaskup, upfac] = stackiso(premask, widyxz);

            premaskup = stackthr(premaskup);

            [maskyup, maskxup, maskzup] = ind2sub(size(premaskup), find(premaskup)); %find the cartesian coordinates of points in the mask

            XYZ0 = [maskxup, maskyup, maskzup]';

            eFit3d=ellipsoidalFit(XYZ0);
            pFit=planarFit(XYZ0);%Preliminary plane fit
            xy0=pFit.project2D(XYZ0); %Map measured 3D samples to 2D
            eFit=ellipticalFit(xy0); %Perform ellipse fit in 2D
            smp0 = linspace(1,360,numroi+1);
            xyz = pFit.unproject3D(  cell2mat(eFit.sample(smp0(1:end-1)))  ); %Post-sample the ellipse fit and map back to 3D

            roicentmp = xyz([2 1 3],:)';

            
            % [ ecnt, erad, evecs, ~, ~, ~, erts] = ellipsoid_fit_new( [maskxup, maskyup, maskzup] );
            %
            % % ertstmp = [eFit3d.roll, eFit3d.pitch, eFit3d.yaw];
            % % erts = ertstmp([3 1 2]);
            % [X,Y,Z] = ellipsoid2(erad(1), erad(2), erad(3), ecnt(1), ecnt(2), ecnt(3), erts(1), erts(3), erts(2), nface=round(sqrt(numel(premaskup))), plt=0);
            %
            % eft = zeros(size(premaskup));
            % [YY,XX,ZZ] = ind2sub(size(premaskup), 1:numel(premaskup)); %find the cartesian coordinates of points in the mask
            % fk = [YY', XX', ZZ'];
            % qp = [Y(:), X(:), Z(:)]; %[maskyup(:), maskxup(:), maskzup(:)];
            % idx = knnsearch(fk, qp);
            % eft(idx) = 1;
            % stackplt3(cat(5, premaskup, eft));
            % eft = logical(imfill(single(eft))); %imfill works for 3d if it's not logical (seems like a bug); if you don't like converting, just imfill each z slice in loop
            % stackplt(eft)
            %
            % [YY,XX,ZZ] = ind2sub(size(eft), find(eft)); %find the cartesian coordinates of points in the mask
            %
            % XYZ0 = [XX,YY,ZZ]';
            %
            % eFit3d =ellipsoidalFit(XYZ0);
            % pFit=planarFit(XYZ0);%Preliminary plane fit
            % xy0=pFit.project2D(XYZ0); %Map measured 3D samples to 2D
            % eFit=ellipticalFit(xy0); %Perform ellipse fit in 2D
            % smp0 = linspace(1,360,numroi+1);
            % xyz = pFit.unproject3D(  cell2mat(eFit.sample(smp0(1:end-1)))  ); %Post-sample the ellipse fit and map back to 3D
            %
            % roicentmp = xyz([2 1 3],:)';
            % roirad = [];
            %
            figure; hold on;
            scatter3(XYZ0(1,:), XYZ0(2,:), XYZ0(3,:),'b','filled','MarkerFaceAlpha',0.05,'MarkerEdgeColor','none') ;  %Given points
            scatter3(xyz(1,:), xyz(2,:), xyz(3,:),'r','filled') ;  %Fitted points
            xlabel X; ylabel Y; zlabel Z
            view(170,-25)

            roicentmp = roicentmp ./ upfac;

        case 'torus' % create multiple roughly equal-volume roi along skeleton of mask

            if ndims(premask)<3
                error("stackseg 'torus' requires nonsingleton yxz dimensions (can't be planar right now)")
            end

            [premaskup, upfac] = stackiso(premask, widyxz);

            premaskup = stackthr(premaskup);

            [maskyup, maskxup, maskzup] = ind2sub(size(premaskup), find(premaskup)); %find the cartesian coordinates of points in the mask

            rots = -1*[0:5:180];
            stackmnzrot = {};
            for k = 1:numel(rots)
                tmp = stackwarp(premaskup, rot=[rots(k),0,0]); %default output view is followoutput
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
                [stackrot, tform, sr] = stackwarp(premaskup, rot=[drawrot,0,0]); %default output view is followoutput
            else
                stackrot = premaskup;
            end

            stackplt(stackrot, dmplt='yx(z)')

            prompt = sprintf("ENTER Z-INDICES YOU WANT TO SUM TO CREATE BACKGROUND FOR MANUALLY POSITIONING ROI CENTROIDS (MEAN OF CHOSEN Z INDICES WILL BE Z COORDINATE FOR ROI CENTROIDS), OR ENTER NOTHING TO POSITION CENTROIDS ON ALL Z SLICES SEPARATELY: ");
            commandwindow();
            drawslice = input(prompt);

            [roicentmp, midx, midy] = drawcent(stackrot, drawslice, numroi);

            if drawrot
                roicentmp = roicentmp + fix([sr.YWorldLimits(1), sr.XWorldLimits(1), sr.ZWorldLimits(1)]);
                [roicentmp(:,2), roicentmp(:,1), roicentmp(:,3)] = transformPointsInverse(tform, roicentmp(:,2), roicentmp(:,1), roicentmp(:,3));
            end

            roicentmp = roicentmp ./ upfac;

            roicentmp(:,widyxz>roirad*2) = round(roicentmp(:,widyxz>roirad*2)); %round dimension with resolution lower than roi radius to prevent empty rois

            style = "MaximumIntensityProjection"; %"GradientOpacity"
            vwr = viewer3d();
            hfg = vwr.Parent;
            szftmp = figsz();
            hfg.Position = [0 0 szftmp];
            vwr.Lighting='off';
            vwr.BackgroundGradient='off';
            vwr.GradientColor=[0 0 0.2];
            vwr.BackgroundColor=[1 1 1];
            vsh(1) = volshow(premask, Parent=vwr);
            vsh(1).RenderingStyle=style;
            % vsh(1).GradientOpacityValue=0.1;
            % vsh(1).Colormap=cmap;
            % vsh(2).Alphamap=0.1;
            tmp = volmaskmake(roirad, xwid, ywid, zwid, premask, mask_allroi_approx, roicentmp);
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

                xq = linspace(1, length(midy), 2*(numroi) + 1)'; %set query points for interpolation (the number of centroids we want). we'll create twice as many points and take every other so that rois on the edges arent clipped
                roicentmp = [interp1(midy,xq), interp1(midx,xq), interp1(midz,xq)]; %interpolate x and y coordinates, now that they are ordered, into evenly spaced centroids (this allows one to oversample if desired)
                roicentmp = roicentmp(2:2:end-1,:); %take every other so that we dont start at the edges, and all are same size

            else

                error("region '" + rgname + "' is roughly uniform blob, so maskseg 'skeleton' fails; try maskseg 'uniform' for roughly equal-volume ROIs within 2d or 3d rgname")

            end

        case {'uniform'} % create multiple roughly equal-volume roi by partitioning rgname into numroi groups

            if isempty(widyxz)
                error("you did not pass in argument widyxz, or you passed empty widyxz, but you also requested maskseg 'uniform', which requires nonempty argument widyxz")
            end


            if do3d

                [tmp, roicentmp, bin_prctiles] = probability_bin([masky, maskx, maskz], numroi, 1, 0); %iteratively median split along dimension of greatest variance, ties are randomly assigned, so as of 240509, results are not reproducible, although differences are typically not major; so for reproducibility, pipeline loads saves/loads previous results

            else %else split into roughly equal area rois on each slice in mask, rounding number rois for each slice to nearest power of 2 proportional to number of voxels relative to total (typically lots of inaccuracy there)

                uz = unique(maskz);
                for uzi = 1:numel(uz)
                    zinds_each{uzi} = find(maskz==uz(uzi));
                    num_vox_each_slice(uzi) = numel(zinds_each{uzi});
                    frac_vox_each_slice(uzi) = num_vox_each_slice(uzi) / numel(maskz);
                    ideal_roim_auto_each_slice(uzi) = frac_vox_each_slice(uzi) * numroi;
                end
                rnds = pow2(round(log2(ideal_roim_auto_each_slice))); %rnds = round(frac_roim_auto_each_slice);

                numroi_new = sum(rnds);
                if numroi~=numroi_new
                    sprintf("warning, changing numroi from " + num2str(numroi) + " to " + num2str(numroi_new))
                    numroi = numroi_new;
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

    % if strcmp(maskseg, 'e3d')
    %     premask = stackthr(premask);
    %     [masky,maskx,maskz] = ind2sub(size(premask), find(premask)); %find the cartesian coordinates of points in the mask
    % end

    roicenvec = cell2mat(roicen(:));
    flatten_key = cell2mat(arrayfun(@(idx) [repmat(idx,size(roicen{idx},1),1), (1:size(roicen{idx},1)).'], (1:numel(roicen)).', 'uniform', 0));
    [~, maptmp] = pdist2(roicenvec, [masky, maskx, maskz], 'euclidean', 'smallest', 1); %find the index of the centroid that is closest to each voxel in the mask. using euclidean, but maybe chebychev (chessboard)
    idx_vox2roi = uint16(flatten_key(maptmp, 1)); %this records which cell the nearest morph centroid is from

    roiwt = zeros(numroi, numel_stackmnt, 'single'); %size [rois, voxels], describes how each voxel contirbutes to roi response, since roi can occupy less than entire voxel (in z dimension especially)
    for i = 1:numroi
        roiwt(i, sub2ind(size(mask_allroi_approx), masky(idx_vox2roi==i), maskx(idx_vox2roi==i), maskz(idx_vox2roi==i))) = 1; %indices of each roi
    end

    roiwt = roiwt';
    if ndims(stackmnt)==2
        roimaskout = reshape(roiwt, [size(stackmnt), 1, numroi] );
    elseif ndims(stackmnt)==3
        roimaskout = reshape(roiwt, [size(stackmnt), numroi] );
    end

end

%%

% cmap = distinguishable_colors(numroi);
%
% %3d scatter, each roi a different hue
% hfg = figure; hold on
% for k = 1:numroi %overlay each pixel in its indexed color onto the pb image
%     scatter3( maskx(idx_vox2roi == k), masky(idx_vox2roi == k), maskz(idx_vox2roi == k), 'filled', 'MarkerFaceColor', cmap(k,:), 'MarkerFaceAlpha', 0.2 )
% end
% %plot3(midx,midy,midz,'.k', 'MarkerSize',12) %include midline if using 'skeleton'
% %scatter3(roicen(:,2 ), roicen(:,1), roicen(:,3), 80, 'k', 'filled') %show the centroids in each of their colors
% colormap(bone);
% axis image; axis off
% set(gca,'Visible','off')
% set(gca,'CameraViewAngle',8)
% rotinc = 30;
% views = -180:rotinc:180;
% if ~exist('erts', 'var')
%     erts = 70;
% end
% for k = 1:length(views) - 1
%     view(views(k)+2, erts(1))
%     fig2gif(hfg, k)
% end
% %%


end



function [roicen_nonuniform, midx, midy] = drawcent(stack, drawslice, numroi)


if isempty(drawslice)

    ax = axarr(stack);
    h = fg();
    h.im = axim(h.fg, stack, ax=ax, doui=1);

    user_input = [];
    roicen_nonuniform = {};
    numslice = numel(h.im.pl);
    cnt = 0;
    while true
        pause(0.05)
        if isempty(user_input)
            for j = 1:numslice
                user_input = h.im.pl{j}.UserData;
                h.im.pl{j}.UserData = [];
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

    prompt = sprintf("ENTER 1 TO DRAW AN ELLIPSE, 0 TO DRAW A POLYGON: ");
    commandwindow();
    doellipse = input(prompt);

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
    xq = linspace(1,length(midy),numroi)'; %set query points for interpolation (the number of centroids we want). we'll create twice as many points and take every other so that clusters on the edges arent clipped
    roicen_nonuniform = [interp1(1:length(midy),midy,xq),interp1(1:length(midx),midx,xq)]; %interpolate x and y coordinates, now that they are ordered, into evenly spaced centroids (this allows one to oversample the number of pixels, if desired)
    if roicen_nonuniform(1,1) < roicen_nonuniform(end,1)
        % error("should this happen ever?")
        roicen_nonuniform = flipud(roicen_nonuniform);
    end
    roicen_nonuniform(:,3) = mean(drawslice); %previously was mean(1:size(stackmnt,1));

    if doellipse
        doplt = 1;
        roicen_xy = ell2cir([midx, midy], numroi, doplt);
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
    cmap = distinguishable_colors(numroi);
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
