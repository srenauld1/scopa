function [resp, roidat] = roimake(stack, pthstack, optid, t, sampper, widyxz, pthpy, opt, roimask, doplt)

% see docs_roimake.m

arguments
    stack 
    pthstack
    optid
    t = [] %only required nonempty if ~isempty(wavp) or channorm~=0 in roiresp
    sampper = [] %only required nonempty for normalizing by moving window in tsnorm
    widyxz = [] %only required nonempty for maskseg 'uniform' in roimauto
    pthpy = [] %only required to run caiman from matlab (roi.docm=1)
    opt = []
    roimask = []
    doplt = []
end

if isempty(roimask)
    maskinput = 0;
    saveresp = 1;
    domm = opt.domm;
    doma = opt.doma;
    docm = opt.docm;
    doqc = opt.doqc;
    if isempty(doplt)
        doplt = any(strcmp('roi', glb('plt')));
    end
else
    if ~iscell(roimask)
        roimask = {roimask};
    end
    maskinput = 1;
    saveresp = 0;
    domm = 0;
    doma = 0;
    docm = 0;
    doqc = 0;
    doplt = 0; %force 0 here
end
regionex = opt.regionex;


if ndims(stack)<4
    error("stack must be 4d or 5d")
end

pthpre = [erase(pthstack, '.mat') optid '_'];
numchan = size(stack,5);


%% crop movie to regionex cuboid

if ~maskinput
    stack = stackcrop(stack, pthstack, regionex);
end

stackmnt = single(mean(stack, 4)); %compute mean t stack after optional stackcrop (don't use glb('stackmnt') because that is the whole fov)

%% draw rois 

if domm
    if isfield(opt, 'ma') && opt.ma.numroi>1
        oneroi = 1;
    else
        oneroi = 0;
    end
    roimask = roidraw(stackmnt, pthstack=pthstack, regionex=regionex, oneroi=oneroi, chan=opt.mm.chan, chancp=opt.mm.chancp, maskname=opt.mm.maskname);
else
    if ~maskinput
        roimask = cell(numchan,1); %make it empty if you didn't draw or pass in mask
    end
end


%% make morphological roi mask (from manual mask plus automated mask, or just manual mask, or just automated mask), and compute some roi info and save in struct roidat

if doma
    roimask = roimauto(stackmnt, roimask, widyxz, regionex, opt.ma);
end

%% functional (caiman) roi responses

if docm
    [respcm, roimask] = roifauto(pthpy, opt.cm, regionex=opt.regionex, maskname=opt.mm.maskname);
end

%% quality control

if doqc
    roimask = roiqc(stackmnt, pth_roif, roitype, opt.qc, trm = trm, roicen = roidat.roicen, mask_allroi = roidat.mask_allroi);
end

%% assemble roi data into struct

roidat = roidatmake(stackmnt, roimask);


%% compute roi responses (and normalize)

if docm
    resp = roiresp(respcm, roimask, stackmnt, saveresp, pthpre, sampper, t, opt.nrm); %if two channel, input resp for 2nd channel gets appended to resp that was output for first channel, with fieldnames identifying channel
else
    resp = roiresp(stack, roimask, stackmnt, saveresp, pthpre, sampper, t, opt.nrm); %if two channel, input resp for 2nd channel gets appended to resp that was output for first channel, with fieldnames identifying channel
end

%% plots

if doplt 

    chanplt = 1;

    imhsv = plots_setup_hsv(opt.imhsv);
    hueft = [1:num_roim]';
    hsvmap = hsvcmp(imhsv, hueft=hueft);
    pthhsv = [pthpre 'hsvfov_.gif'];
    hsvplt(imhsv, stackmnt(:,:,:,:,chanplt), hsvmap, roipx, roiwt, dohsv, pthhsv);

    ptholay = [pthpre 'roioverlay_.gif'];
    gifvis = 'on';
    chanplt = 1;
    stackplt(stackmnt(:,:,:,:,chanplt), pthgif=ptholay, gifvis=gifvis, roipx=roipx, ir=roiol.ir, roicols=roiol.roicol, roialpha=roiol.roialpha) %include roipx as argument to plot roi overlay

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
    pthgif = [pthpre 'huerois_3dspin_.gif'];
    for framecount = 1:length(views) - 1
        view(views(framecount)+2, 20)
        fig2gif(hfg, framecount, pthgif)
    end



    %mask overlay
    overlayarray = rescale(0.2*rescale(mask_allroi) + rescale(stackmnt, 0, 1));
    stackplt( overlayarray, pthgif=[pthpre 'maskallroi_overlay_.gif'])

    %manual roi mask
    stackplt(roimaskman, pthgif=[pthpre 'roimaskman_.gif'])

    %mask all rois (without stack background)
    stackplt(mask_allroi, pthgif=[pthpre 'maskallroi_.gif'])

    % %3d surface plot
    % kbnd = boundary([maskx,masky,maskz]);
    % figure;
    % trisurf(kbnd,maskx',masky',maskz','Facecolor','red','FaceAlpha',0.1)
    % axis image
    % saveas( gcf, [pthpre 'maskallroi_surface_.png'])


end

% if ~doma && strcmp(roisrt, morph_long_axis)
%     fprintf("WARNING, cannot implement roisrt 'morph_long_axis' because doma is false" + newline)
% end

end



