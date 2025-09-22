function roi = roimake(opt, opt2)

% see docs_roimake.m

arguments
    opt = []
    opt2.stack = []
    opt2.pthstack = []
    opt2.md = []
    opt2.sper = [] %only required nonempty for normalizing by moving window in tsnorm
    opt2.widyxz = [] %only required nonempty for maskseg 'uniform' in roimauto
    opt2.t = [] %only required nonempty if channorm~=0 in roits
    opt2.pthpy = [] %only required to run caiman from matlab (roi.docm=1)
    opt2.doplt = []
    opt2.usegit = []
    opt2.roimask = []
end
opt2 = glboropt(opt2);
stack = opt2.stack;
pthstack = opt2.pthstack;
md = opt2.md;
sper = opt2.sper;
widyxz = opt2.widyxz;
t = opt2.t;
pthpy = opt2.pthpy;
doplt = opt2.doplt;
usegit = opt2.usegit;
roimask = opt2.roimask;

[opt, doplt, pthstack] = fset('roi', opt, doplt, pthstack);

if isempty(stack)
    if isempty(pthstack)
        error("if name-value argument stack is empty, name-value argument pthstack must be nonempty")
    end
    stack = stackld(odf('sld', unpack=1), pthstack);
end
if isempty(md)
    md = mdsild(pthstack);
end
if isempty(sper)
    sper = md.sper;
end
if isempty(widyxz)
    widyxz = md.widyxz;
end
if isempty(t)
    t = md.sper:md.sper:md.numvol*md.sper;
end

pthroi = [erase(pthstack, '.mat') opt.optid '_roi_.mat'];

if ndims(stack)<4 || ndims(stack)>5
    error("stack input to roidraw must have 4-5 dimensions")
end

numchan = size(stack,5);

rg = [];
mm = [];
respcm = [];
if isempty(roimask)
    maskin = 0;
    roimask = cell(numchan,1); %needs to be cell in case 2-channel with different number rois
    if opt.domm
        mmname = opt.mm.mmname;
    else
        mmname = 'none';
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
    [~, rg] = stackcrop([], opt.rgname, pthstack=pthstack, usegit=usegit); %don't input or output stack here, just loading rg
    [~, mm] = roidraw(nodraw=1, pthstack=pthstack, rg=rg, mmname=mmname); %don't input stack here, just loading mm
    if ~isequal(roi.dat(1).rg, rg) || ~isequal(roi.dat(1).mm, mm(1)) || ( numel(roi.dat)==2 && ( ~isequal(roi.dat(2).rg, rg) || ~isequal(roi.dat(2).mm, mm(2)) ) )
        error("roi.dat.rg must match rg and roi.dat.mm must match mm; you may have changed rg or mm since saving roi file")
    end
    if ~isfield(roi, 'opt') %doing this check separately from above because added opt to saved variables later than others
        roi.opt = opt;
        save(pthroi, '-struct', 'roi', '-v7.3', '-mat')
    else
        if ~isequal(roi.opt, opt)
            error("opt saved/loaded from roi file does not match input opt")
        end
    end


catch ME


    fprintf("" + ME.message + newline + "creating roi struct now" + newline)



    %%%% CROP stack TO rg CUBOID %%%%

    if ~maskin
        [stack, rg] = stackcrop(stack, opt.rgname, pthstack=pthstack, usegit=usegit);
    end

    stackmnt = single(mean(stack, 4)); %compute mean t stack after optional stackcrop (can't remember why we switch to single precision here)


    %%%% DRAW ROIS %%%%

    if opt.domm && ~maskin
        [roimask, mm] = roidraw(stack=stack, pthstack=pthstack, rg=rg, mmname=mmname, chanstr=opt.mm.chanstr, cellout=1); %cellout=1 because in roimake roimask is cell (one for each channel)
    end



    %%%% AUTOMATED MORPHOLOGICAL SEGMENTATION %%%%

    if opt.doma && ~maskin
        roimask = roimauto(stackmnt, opt.ma, roimaskin=roimask, widyxz=widyxz, pthstack=pthstack, rg=rg, mmname=mmname); 
    end



    %%%% AUTOMATED FUNCTIONAL SEGMENTATION (CAIMAN) %%%%

    if opt.docm && ~maskin
        stack = [];
        [respcm, roimask] = roifauto(pthpy, opt.cm, rgname=opt.rgname, mmname=mmname);
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
    roi.opt = opt;
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

