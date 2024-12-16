function [resp, roidat] = roimake(stack, t, sampper, widyxz, zstartpos, pth_dirstack, recid, pth_roim, opt, roiman)

% see docs_roimake.m

arguments
    stack
    t
    sampper
    widyxz
    zstartpos
    pth_dirstack
    recid
    pth_roim
    opt
    roiman = []
end

if isempty(roiman)
    maskinput = 0;
    domm = opt.domm;
    doma = opt.doma;
    docm = opt.docm;
    doqc = opt.doqc;
    if ~isfield(opt, 'doplt') || (isfield(opt, 'doplt') && isempty(opt.doplt))
        doplt = any(strcmp('roi', glb('plt')));
    end
else
    if ~iscell(roiman)
        roiman = {roiman};
    end
    maskinput = 1;
    domm = 0;
    doma = 0;
    docm = 0;
    doqc = 0;
    doplt = 0; 
end
regionex = opt.regionex;

if isfield(opt, 'ma')
    numroiauto = opt.ma.numroi;
else
    numroiauto = 0;
end

pthpre = erase(pth_roim, '.mat');
numchan = size(stack,5);

%% crop movie to regionex cuboid

if ~maskinput
    stack = stackcrop(stack, regionex, zstartpos, recid, pth_dirstack);
end

%% draw rois (polygons/polyhedra)

if domm
    if numroiauto>1
        oneroi = 1;
    else
        oneroi = 0;
    end
    roiman = roidraw(stack, pthpre=pthpre, regionex=regionex, oneroi=oneroi, chan=opt.mm.chan, chancp=opt.mm.chancp, maskname=opt.mm.maskname);
else
    if ~maskinput
        roiman = cell(numchan,1); %make it empty if you didn't draw or pass in mask
    end
end


%% make morphological roi mask (from manual mask plus automated mask, or just manual mask, or just automated mask), and compute some roi info and save in struct roidat

if doma
    for c = 1:numchan
        if ismember(c,opt.ma.chan)
            if ~isequal(numroiauto, 0)
                [roiwt{c}, roicen{c}, num_roim{c}] = roimauto(stack(:,:,:,:,c), roiman{c}, numroiauto, widyxz, regionex, opt.ma);
            end
        end
    end
end

%% load/select functional (caiman) roi responses

if docm
    error("for now, for caiman extraction, run pipeline_init with do_extract=1; soon you will be able to run it from here, as option in a2p")
    roifauto(...
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
end


%% compute roi responses (and normalize)

pth_morphroits = [pthpre '_resp_.mat']; 
try
    load(pth_morphroits, 'resp')
catch
    resp = cell(numchan,1);
    for c = 1:numchan
        if ~isempty(roiwt{c})
            resptmp = roits(stack(:,:,:,:,c), roiwt=roiwt{c}, normpre=opt.nrm.pre, normpost=opt.nrm.post, sampper=sampper, wavp=opt.nrm.wavp, degdtr=opt.nrm.degdtr, channorm=opt.nrm.channorm, t=t, pthpre=pthpre, doplt=0); %if two channel, input resp for 2nd channel gets appended to resp that was output for first channel, with fieldnames identifying channel
            fn = fieldnames(resptmp);
            if numel(fn)>1
                error("there should only be one field because all params have been distributed and assigned optid")
            end
            resp{c} = resptmp.(fn{1}); %each channel
        end
    end
    if ~maskinput
        save(pth_morphroits, 'resp', '-v7.3', '-mat')
    end
end


%% assemble roi data into struct

pth_roimdat = [pthpre '_roimdat_.mat'];
try
    load(pth_roimdat, 'roidat');
catch
    roidat = roidatmake(stack, roiman);
    if ~maskinput
        save(pth_roimdat, 'roidat', '-mat', '-v7.3');
    end
end


%% plots

if doplt %all these are at imaging resolution

    stackmnt = single(mean(stack, 4)); %native is slow and not necessary for mean t

    imhsv = plots_setup_hsv(imhsv);
    hueft = [1:num_roim]';
    hsvmap = hsvcmp(imhsv, hueft=hueft);
    pthhsv = [pthpre 'hsvfov_.gif'];
    plotchannel = 1;
    hsvplt(imhsv, stackmnt(:,:,:,:,plotchannel), hsvmap, roipx, roiwt, dohsv, pthhsv);

    ptholay = [pthpre 'roioverlay_.gif'];
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
    pthgif = [pthpre 'huerois_3dspin_.gif'];
    for framecount = 1:length(views) - 1
        view(views(framecount)+2, 20)
        fig2gif(hfg, framecount, pthgif)
    end



    %mask overlay
    overlayarray = rescale(0.2*rescale(mask_allroi) + rescale(mean(stack, 4), 0, 1));
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



