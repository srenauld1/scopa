function [roidat, resp] = roimake(stack, t, sampper, widyxz, pth_roim, stackmnthr, hrlr, opt, roimaskman_allchan)

% see docs_roimake.m

arguments
    stack
    t
    sampper
    widyxz
    pth_roim
    stackmnthr
    hrlr
    opt
    roimaskman_allchan = []
end

if isempty(roimaskman_allchan)
    maskinput = 0;
    domm = opt.domm;
    doma = opt.doma;
    docm = opt.docm;
    doqc = opt.doqc;
    doplt = opt.doplt;
else
    if ~iscell(roimaskman_allchan)
        roimaskman_allchan = {roimaskman_allchan};
    end
    maskinput = 1;
    domm = 0;
    doma = 0;
    docm = 0;
    doqc = 0;
    numroiauto = 0;
    doplt = 0; %skip plots if passing in roimaskman_allchan
end

numchan = size(stack,5);

stackmnt = mean(stack, 4, 'native');

%% crop movie to regionex cuboid

[stack, zstartsub, stackmnthr, hrlr] = stackcrop(stack, regionex, md.zstartpos, o.id.recid, pth.dirstack, md.sz_crop, ma.usehires, stackmnthr, hrlr);


%% draw rois (polygons/polyhedra)

if domm && ~maskinput
    roimaskman_allchan = roidraw(stack, pth_roim, regionex, opt.mm);
end


%% make morphological roi mask (from manual mask plus automated mask, or just manual mask, or just automated mask), and compute some roi info and save in struct roidat


for c = 1:numchan
    if ismember(c,autoopts.chan)
        roimaskman = roimaskman_allchan{c};
        stackmnt_tmp = stackmnt(:,:,:,:,c);
        num_roim_manual = size(roimaskman, 4);
        pth_roimdat = [pth_roim_prefix 'chn' num2str(c) '_roimdat_.mat'];
        try
            load(pth_roimdat, 'roidat');
        catch
            if num_roim_manual>1 || numroiauto==0
                num_roim = num_roim_manual;
                if numroiauto>0
                    error(sprintf(['ERROR \n' ...
                        'num_roim_manual is greater than one AND numroiauto is greater than zero \n' ...
                        'DELETE OR RENAME pth_roimaskman AND DRAW MANUAL MORPHOLOGICAL ROIS AGAIN, \n' ...
                        'OR KEEP MANUAL MORPHOLOGICAL ROIS AND REQUEST 0-1 AUTOMATED MORPHOLOGICAL ROIS']))
                end
                roiwt = zeros(num_roim, numel(sum(roimaskman, 4)), 'logical');  %initialize a logical matrix that is size (centroids, voxels)
                for mi = 1:num_roim
                    tmp = roimaskman(:,:,:,mi);
                    [maskytmp, maskxtmp, maskztmp] = ind2sub(size(tmp), find(tmp));
                    roiwt(mi, sub2ind(size(tmp), maskytmp, maskxtmp, maskztmp)) = true; %indices of each roi
                end
                roicen = find_roi_centroids(roimaskman);
                fprintf("WARNING,\n" + ...
                    "if roisrt is 'morph_long_axis', rois will be sorted by drawn roi index, not morph long axis, \n" + ...
                    "since determining the long axis of extraction currently requires automated morph roi extraction" + newline)
            else
                [roiwt, roicen, num_roim] = ...
                    roimauto(stackmnt_tmp, roimaskman, numroiauto, ...
                    widyxz, stackmnthr, hrlr, pth_roim_prefix, ...
                    regionex, imhsv, doplt, autoopts);
            end
            roidat = roidatmake(stack, roiwt, roicen, num_roim);
            if ~maskinput
                save(pth_roimdat, 'roidat', '-mat', '-v7.3');
            end
        end
    end
end
if ~isempty(chancpma) && numchan==2
    chanreceive = setxor(chancpma, [1,2]);
    fprintf("chancpmm is " + num2str(chancpma) + "; COPYING ROI INFO FROM CHANNEL " + num2str(chancpma) + " ONTO CHANNEL " + num2str(chanreceive) + newline);
    roidat(chanreceive) = roidat(chancpma);
end



%% load/select functional (caiman) roi responses

roifmake(...
    stack, ...
    pth_roif, ...
    roitype, ...
    minpixperreg = minpixperreg, ...
    minroisz = minroisz, ...
    maxroisz = maxroisz, ...
    maxregperroi = maxregperroi, ...
    inmaskthr = inmaskthr, ...
    numbins = numbins, ...
    roisrt = roisrt, ...
    ir = ir, ...
    doplt = doplt, ...
    tcrop = tcrop, ...
    roicen = roidat.roicen, ...
    mask_allroi = roidat.mask_allroi ...
    )


%% compute roi responses

pth_morphroits = [pth_roim_prefix '_resp_.mat']; %don't need channel infix here
try
    load(pth_morphroits, 'resp')
catch
    resp = roits(stack, roiwt=roidat(c).roiwt, normpre=normpre, normpost=normpost, sampper=sampper, wavp=wavp, degdtr=degdtr, channorm=channorm, t=t, pthpre=pth_roim_prefix, doplt=0); %if two channel, input resp for 2nd channel gets appended to resp that was output for first channel, with fieldnames identifying channel
    if ~maskinput
        save(pth_morphroits, 'resp', '-v7.3', '-mat')
    end
end


%% plots

if doplt %all these are at imaging resolution

    imhsv = plots_setup_hsv(imhsv);
    hueft = [1:num_roim]';
    hsvmap = hsvcmp(imhsv, hueft=hueft);
    pthhsv = [pth_roim_prefix 'hsvfov_.gif'];
    plotchannel = 1;
    hsvplt(imhsv, stackmnt(:,:,:,:,plotchannel), hsvmap, roipx, roiwt, dohsv, pthhsv);

    ptholay = [pth_roim_prefix 'roioverlay_.gif'];
    gifvis = 'on';
    plotchannel = 1;
    stackplt(stackmnt(:,:,:,:,plotchannel), pthgif=ptholay, gifvis=gifvis, roipx=roipx, ir=roiol.ir, roicols=roiol.roicol, roialpha=roiol.roialpha) %include roipx as argument to plot roi overlay

    %colormap for each roi
    cmap = distinguishable_colors(size(roiwt,1));
    double_colormap = 0;
    if double_colormap %like for two halves of PB, etc, made this default 0 since the split is just halfway along mask (not functional)
        num_region_periods = 2; %for example, two halves of pb
    else
        num_region_periods = 1;
    end
    cmap = repmat(cmap,num_region_periods,1); %if region is periodic with multiple periods


    %3d scatter, each roi a different hue
    hfg = figure; hold on
    for i = 1:num_roim %overlay each pixel in its indexed color onto the pb image
        scatter3( maskx(idx_vox2roi == i), masky(idx_vox2roi == i), maskz(idx_vox2roi == i), 'filled', 'MarkerFaceColor', cmap(i,:), 'MarkerFaceAlpha', 0.2 )
    end
    %plot3(midx,midy,midz,'.k', 'MarkerSize',12) %include midline if using 'skeleton'
    %scatter3(roicen(:,2 ), roicen(:,1), roicen(:,3), 80, 'k', 'filled') %show the centroids in each of their colors
    colormap(bone);
    axis image; axis off
    set(gca,'Visible','off')
    set(gca,'CameraViewAngle',8)
    rotinc = 30;
    views = -180:rotinc:180;
    pthgif = [pth_roim_prefix 'huerois_3dspin_.gif'];
    for framecount = 1:length(views) - 1
        view(views(framecount)+2, 20)
        fig2gif(hfg, framecount, pthgif)
    end



    %mask overlay
    overlayarray = rescale(0.2*rescale(mask_allroi) + rescale(mean(stack, 4), 0, 1));
    stackplt( overlayarray, pthgif=[pth_roim_prefix 'maskallroi_overlay_.gif'])

    %manual roi mask
    stackplt(roimaskman, pthgif=[pth_roim_prefix 'roimaskman_.gif'])

    %mask all rois (without stack background)
    stackplt(mask_allroi, pthgif=[pth_roim_prefix 'maskallroi_.gif'])

    % %3d surface plot
    % kbnd = boundary([maskx,masky,maskz]);
    % figure;
    % trisurf(kbnd,maskx',masky',maskz','Facecolor','red','FaceAlpha',0.1)
    % axis image
    % saveas( gcf, [pth_roim_prefix 'maskallroi_surface_.png'])


end

end



