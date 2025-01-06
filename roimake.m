function [resp, roidat] = roimake(stack, pthstack, t, sampper, widyxz, pthpy, roimask, doplt, optroi)

% see docs_roimake.m

arguments
    stack 
    pthstack
    t = [] %only required nonempty if ~isempty(wavp) or channorm~=0 in roits
    sampper = [] %only required nonempty for normalizing by moving window in tsnorm
    widyxz = [] %only required nonempty for maskseg 'uniform' in roimauto
    pthpy = [] %only required to run caiman from matlab (roi.docm=1)
    roimask = []
    doplt = []
    optroi = []
end

if isempty(roimask)
    maskinput = 0;
    domm = optroi.domm;
    doma = optroi.doma;
    docm = optroi.docm;
    doqc = optroi.doqc;
    if isempty(doplt)
        doplt = any(strcmp('roi', glb('plt')));
    end
else
    if ~iscell(roimask)
        roimask = {roimask};
    end
    maskinput = 1;
    domm = 0;
    doma = 0;
    docm = 0;
    doqc = 0;
    doplt = 0; %force 0 here
end
regionex = optroi.regionex;

if isfield(optroi, 'ma')
    numroiauto = optroi.ma.numroi;
else
    numroiauto = 0;
end

pthpre = [erase(pthstack, '.mat') regionex '_'];
numchan = size(stack,5);

%% crop movie to regionex cuboid

if ~maskinput
    stack = stackcrop(stack, pthstack, regionex);
end

%% draw rois (polygons/polyhedra)

if domm
    if numroiauto>1
        oneroi = 1;
    else
        oneroi = 0;
    end
    roimask = roidraw(stack, pthstack=pthstack, regionex=regionex, oneroi=oneroi, chan=optroi.mm.chan, chancp=optroi.mm.chancp, maskname=optroi.mm.maskname);
else
    if ~maskinput
        roimask = cell(numchan,1); %make it empty if you didn't draw or pass in mask
    end
end


%% make morphological roi mask (from manual mask plus automated mask, or just manual mask, or just automated mask), and compute some roi info and save in struct roidat

if doma
    for c = 1:numchan
        if ismember(c,optroi.ma.chan)
            if ~isequal(numroiauto, 0)
                roimask{c} = roimauto(stack(:,:,:,:,c), roimask{c}, numroiauto, widyxz, regionex, optroi.ma);
            end
        end
    end
end

%% functional (caiman) roi responses

if docm

    if isempty(pthpy)
        pthpy = glb('pthpy');
        if isempty(pthpy)
            error("you have not set glb('pthpy'), and you didn't pass in argument pthpy; you must do one or the other" + newline)
        end
    end

    pthscopa = getpathscopa();

    try %run python directly from matlab (ie not using system command to control a shell)
        petmp = pyenv;
        if ~strcmp(petmp.Executable, pthpy) && ~strcmp(petmp.ExecutionMode, 'OutOfProcess')
            try
                pyenv(ExecutionMode="OutOfProcess")
                pyenv(Version=pthpy)
            catch ME
                fprintf(ME.message + newline)
                fprintf("do not use pyenv in the current matlab session with a different Version or ExecutionMode than those specified here" + newline)
            end
        end
        if count(py.sys.path,pthscopa) == 0
            insert(py.sys.path,int32(0),pthscopa);
        end
        py.extract.extract( ...
            pth_prefix='', ...
            pth_tif_read='', ...
            pth_optdf='', ...
            pth_optroi='', ...
            md=2, ...
            extract_in_2d=0, ...
            methodex='1', ...
            regionex=optroi.regionex, ...
            maskname=optroi.mm.maskname, ...
            optall=optroi.cm ...
            );
    catch ME %alternative that uses system command
        fprintf(ME.message + newline)
        fprintf("RUNNING PYTHON DIRECTLY FAILED, USING system TO RUN PYTHON INSTEAD")
        pyfn = [pthscopa 'extract_mat.py'];
        syscmd = [pthpy ' ' pyfn ' ' pthraw ' ' pthmd];
        system(syscmd)
    end

end



%% quality control

if doqc
    roimask = roiqc(...
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
        );
end



%% assemble roi data into struct

pth_roimdat = [pthpre 'roimdat_.mat'];
try
    load(pth_roimdat, 'roidat');
catch
    roidat = roidatmake(stack, roimask);
    if ~maskinput
        save(pth_roimdat, 'roidat', '-mat', '-v7.3');
    end
end

%% compute roi responses (and normalize)

pth_morphroits = [pthpre 'resp_.mat'];
try
    load(pth_morphroits, 'resp')
catch
    resp = cell(numchan,1);
    for c = 1:numchan
        if ~isempty(roimask{c})
            resptmp = roits(stack(:,:,:,:,c), roiwt=roidat{c}.roiwt, normpre=optroi.nrm.pre, normpost=optroi.nrm.post, sampper=sampper, wavp=optroi.nrm.wavp, degdtr=optroi.nrm.degdtr, channorm=optroi.nrm.channorm, t=t, pthpre=pthpre, doplt=0); %if two channel, input resp for 2nd channel gets appended to resp that was output for first channel, with fieldnames identifying channel
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




%% plots

if doplt 

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



