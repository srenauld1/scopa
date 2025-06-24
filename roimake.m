function roi = roimake(stack, opt, pthstack, md, sper, widyxz, t, pthpy, opt2)

% see docs_roimake.m

arguments
    stack
    opt = []
    pthstack = []
    md = []
    sper = [] %only required nonempty for normalizing by moving window in tsnorm
    widyxz = [] %only required nonempty for maskseg 'uniform' in roimauto
    t = [] %only required nonempty if channorm~=0 in roits
    pthpy = [] %only required to run caiman from matlab (roi.docm=1)
    opt2.doplt = []
    opt2.roimask = []
end
doplt = opt2.doplt;
roimask = opt2.roimask;

[opt, pthstack, doplt] = fset('roi', opt, pthstack, doplt);

if isempty(md)
    md = glb('md');
    if isempty(md)
        md = mdsild(pthstack);
    end
end
if isempty(sper)
    sper = md.sper;
end
if isempty(widyxz)
    widyxz = md.widyxz;
end
if isempty(t)
    t = glb('t');
end

pthroi = [erase(pthstack, '.mat') opt.optid '_roi_.mat'];

if ndims(stack)<4
    error("stack must be 4d or 5d")
end

numchan = size(stack,5);

rg = [];
mm = [];
respcm = [];
if isempty(roimask)
    maskin = 0;
    roimask = cell(numchan,1); %needs to be cell in case 2-channel with different number rois
    if opt.domm
        maskname = opt.mm.maskname;
    else
        maskname = 'none';
    end
else
    maskin = 1;
    if ~iscell(roimask)
        roimask = {roimask};  %needs to be cell in case 2-channel with different number rois
    end
    if ~isequal(numel(roimask), numchan)
        error("roimask must be cell, length numchan")
    end
end



try


    roi = load(pthroi);

    if any(~isfield(roi, {'dat', 'maketime_optfile_roi'})) || isfield(roi, 'ts')
        error("roi struct, at highest level, must contain field and 'dat' (and not field ts); you may have loaded an old roi struct")
    end
    if ~isequal(roi.maketime_optfile_roi, glb('maketime_roi'))
        error("roi id is derived from an optid file different from original")
    end
    [~, rg] = stackcrop([], pthstack, opt.rgname); %don't input or output stack here, just loading rg
    [~, mm] = roidraw([], pthstack, rg=rg, maskname=maskname); %don't input stack here, just loading mm
    if ~isequal(roi.dat(1).rg, rg) || ~isequal(roi.dat(1).mm, mm(1)) || ( numel(roi.dat)==2 && ( ~isequal(roi.dat(2).rg, rg) || ~isequal(roi.dat(2).mm, mm(2)) ) )
        error("roi.dat.rg must match rg and roi.dat.mm must match mm; you may have changed rg or mm since saving roi file")
    end


catch ME


    fprintf("" + ME.message + newline + "creating roi struct now" + newline)

    

    %%%% CROP stack TO rg CUBOID %%%%

    if ~maskin
        [stack, rg] = stackcrop(stack, pthstack, opt.rgname);
    end

    stackmnt = single(mean(stack, 4)); %compute mean t stack after optional stackcrop (don't use glb('stackmnt') because that is the whole fov)


    %%%% DRAW ROIS %%%%

    if opt.domm && ~maskin
        if isfield(opt, 'ma') && ~isempty(fieldnames(opt.ma)) && opt.ma.numroi>1 %if multiple automated morphological rois, only one drawn roi is allowed 
            oneroidraw = 1;
        else
            oneroidraw = 0;
        end
        [roimask, mm] = roidraw(stack, pthstack, roimaskin=roimask, rg=rg, maskname=maskname, methodmm=opt.mm.methodmm, oneroi=oneroidraw);
    end



    %%%% AUTOMATED MORPHOLOGICAL SEGMENTATION %%%%

    if opt.doma && ~maskin
        roimask = roimauto(stackmnt, opt.ma, roimaskin=roimask, widyxz=widyxz, pthstack=pthstack, rg=rg, maskname=maskname); 
    end



    %%%% AUTOMATED FUNCTIONAL SEGMENTATION (CAIMAN) %%%%

    if opt.docm && ~maskin
        stack = [];
        [respcm, roimask] = roifauto(pthpy, opt.cm, rgname=opt.rgname, maskname=maskname);
    end



    %%%% QUALITY CONTROL %%%%

    if opt.doqc && ~maskin
        roimask = roiqc(stackmnt, pth_roif, roitype, opt.qc, trm=trm, roicen=roidat.roicen, mask_allroi=roidat.mask_allroi);
    end



    %%%% COMPUTE ROI RESPONSES AND NORMALIZE %%%%

    [ts, roimask] = roits(opt.nrm, stack=stack, respcm=respcm, roimaskin=roimask, sper=sper, t=t);



    %%%% ASSEMBLE ROI DATA INTO STRUCT %%%%

    roi.dat = roidatmake(stackmnt, roimask, ts, rg, mm, pthstack);



    %%%% SAVE %%%%

    roi.maketime_optfile_roi = glb('maketime_roi');
    save(pthroi, '-struct', 'roi', '-v7.3', '-mat')



end



%%%% PLOTS %%%%

if doplt && ~maskin

    pthpre = erase(pthroi, '.mat');

    stackplt(roi.dat(1).stackmnt, roipx=roi.dat(1).roipx)
    
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
    for k = 1:num_roim %overlay each pixel in its indexed color onto the pb image
        scatter3( maskx(idx_vox2roi == k), masky(idx_vox2roi == k), maskz(idx_vox2roi == k), 'filled', 'MarkerFaceColor', cmap(k,:), 'MarkerFaceAlpha', 0.2 )
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

