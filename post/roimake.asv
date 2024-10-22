function [roidat, resp] = roimake(stack, opts_roim, nrm, t, sampper, widyxz, ...
    pth_roim, pth_tmpfiles, stack_hires, hrlr, regionex, parstr_roim, roimaskman_allchan)


%{

region (previously croplim) are unique to recording
maskname are unique to recording 

optid 

optid for all files in stack
for each recording, single file holds all region (croplim), as struct 
for each recording, single file holds all maskman (name), as struct 

extract: optex, search for existing roim matching opts, load if so (make if not)
a2p: 

name defines croplim
name_subname_optind defines regionex (maskman is loaded using name_subname_chan)
maskman just has name_subname in filename, does not need channel in filename, but includes channel as 4th dim, and requested channel must exist 

we want to reuse maskman, index let's us reuse maskman, subname let's us reuse croplim 

rgn = {'fb'}


run extract.py
    seed or mask, lookup maskmanual with name_subname 

pre: 
    background subtraction, scanphase correction, registration, denoising, scannoise removal  
    input: stack
    output: stack and parsed scanimage metadata 
    slow and large files, do not expand opts

rois:
    roimake: roim and/or roif
    input: stack (pre output) and metadata (optional hires)
    output: roi masks and timeseries

post:
    extern/daq
    hires: registration, rois
    feature extraction (from stack and/or timeseries)
    modeling
    visualization

oset simplifies setting options (could be reproduced with csv or json)
pipeline_init does not have oset 

oset vectors are expanded (map2params) to create each o.roi.regionex 
regionex is name_subname_index
name is arbitrary, name is associated with croplim; subname means the same croplim as name, but different regionex; index is opt set index  

all regionex are included in options_.txt
the most recent options_.txt is searched for options matches (or regionex matches)


user can pass regionex and opts will populate, or pass opts and regionex will populate, but not both
there is no reason to make separate map2params for roim and roif, because user will not want to loop through each separately 
if user has duplicate regionex (say, some run in python, some from a2p), the most recent param file is used as lookup
set includes roim and roif opt, since roim seeds roif
python runs of extract will write opts as options_cmex, for lookup when user runs a2p
since roim options will be missing from python runs, they are considered to have default values, as if the user ran a2p and skipped roim (draw and ma)

roi routines 
'seed' means draw/ma seeds caiman extraction
'cluster' means draw/ma clusters caiman rois
    if cluster, draw/ma has nothing to do with extract.py, so regionex run in python will be indexed differently 
    so do we need two indices (fb_l_2_22), one lookup for options_cmex, and another for options 
    an a2p run creates all options, and checks if an options set exists in the most recent options_cmex_.txt, and populates regionexcm, use regionexcm to look up roi file(s) 

run a2p
    expand params, define all regionex, save o
    search for o.roif options in options_cmex
        exists: id regionexcm and its files
            files don't exist; flag to run
        does not exist: flag to run, pass in o.roi options 

run extract.py
    expand params, define all regionexcm, save ocm
    if seeded, check if roim file exists, if so, load and use, if not, draw roim for seed in python

if you want to independently automate mrois from multiple drawn regions, use different regionex
(they can be analzed together after extracting responses), or choose to draw discontiguous roi and that one can get passed to roimauto


for num_roim argument
if number is passed, method is automated
you can have zero morph rois, which means any functional rois will not get morph selection
you can have one morph roi, which will use edge detection to refine and functional rois will get that selection
you can have more than 1 morph roi, which will create automated rois (either with or without hires stack), and those are bad for functional roi selection
if more than zero automated morph rois, option to use manually drawn roi
to help automation (loops over each drawn roi)
if string 'manual' is passed
rois are drawn, either on the mean image (what is drawn is projected through z), or on each z slice

regardless, 3d centroids of each morph roi are found (if zero, then whole fov centroid)


create morphological rois
using the mean-time and mean-z projection of the data,
manually create 2d mask (roimaskman)
that 2d mask is projected into a 3d mask (mask_roim_all_simple)
that is refined using chosen method (edge detection, global threshold, etc)
if creating multiple morphological rois, the 3d mask is refined using
a high-z-res version of the data, and the mask is mapped back to original resolution
find the morphological roi centroids (roicen) of the final 3d mask,
and all voxels that are nearest each centroid (roiwt)
if you draw multiple rois in roimaskman, a different mask_roim_all_simple will be
made for each, but the 3d refining code cannot accommodate
multiple drawn rois currently, so do not do this;
if you want multiple rois within the fov passed to this function,
call this function (roimake)
again with the same inputs, but draw a different single 2d roi,
and assign the outputs of this function a different name (outside this function)

roiwt can be single when it's weighted, boolean otherwise

%}

arguments
    chandraw = opts_roim.chandraw;
    chancpmm = opts_roim.chancpmm;
    channorm = opts_roim.channorm;
    degdtr = opts_roim.degdtr;
    wavp = opts_roim.wavp;
    autoopts = opts_roim.ma.;
    normpre = nrm.pre;
    normpost = nrm.post;
    dodraw = opts_roim.dodraw.(regionex);
    numroiauto = opts_roim.ma.numroi.(regionex);
    normopts = opts_roim.norm;
    imhsv = opts_roim.imhsv;
    roiol = opts_roim.roiol;
    doimhsv = opts_roim.doimhsv;
    doroiol = opts_roim.doroiol;
    doplt = opts_roim.doplt;
end


if exist('roimaskman_allchan', 'var') %if passing in a morph roi mask (interactive mode, upadating roi info)
    roimaskman_allchan = {roimaskman_allchan};
    maskinput = 1;
    dodraw = 0;
    numroiauto = 0;
    normopts = opts_roim.norm;
    doimhsv = 0; %skip plots if passing in roimaskman_allchan
    doroiol = 0; %skip plots if passing in roimaskman_allchan
    doplt = 0; %skip plots if passing in roimaskman_allchan
else
    maskinput = 0;
    dodraw = opts_roim.dodraw.(regionex);
    numroiauto = opts_roim.ma.numroi.(regionex);
    normopts = opts_roim.norm;
    imhsv = opts_roim.imhsv;
    roiol = opts_roim.roiol;
    doimhsv = opts_roim.doimhsv;
    doroiol = opts_roim.doroiol;
    doplt = opts_roim.doplt;
end

chandraw = opts_roim.chandraw;
chancpmm = opts_roim.chancpmm;
channorm = opts_roim.channorm;
degdtr = opts_roim.degdtr;
wavp = opts_roim.wavp;
autoopts = opts_roim.ma;
normpre = nrm.pre;
normpost = nrm.post;

pth_roim_prefix = pth_roim(1:end-4);
numchan = size(stack,5);

stackmnt = mean(stack, 4, 'native');

%% draw rois (polygons/polyhedra)

if ~maskinput
    roimaskman_allchan = repmat({ones(size(stack,1), size(stack,2), size(stack,3), 'logical')}, [numchan, 1]);
    if dodraw
        for c = 1:numchan
            if ismember(c,chandraw)
                pth_roim_manual_prefix = erase(pth_roim_prefix, ['_' parstr_roim]); %different prefix since the parstr_roim are irrelevant for manually drawn rois, allowing manually drawn to be used for different parstr_roim
                pth_roim_manual_prefix = erase(pth_roim_manual_prefix, ['_morph']); %string 'morph' is redundant here, since this has suffix manual
                pth_roimaskman = [pth_roim_manual_prefix 'chn' num2str(c) '_roimaskman_.mat'];
                try
                    roimaskman = struct2cell(load(pth_roimaskman));
                    roimaskman = roimaskman{1};
                    if all(roimaskman(:)==1)
                        sprintf(['WARNING, MASK MANUAL CHANNEL' num2str(c) ' IS ALL ONES FOR REGION: ' regionex])
                    end
                catch
                    flag_limit_one_manual_roi = 0;
                    if numroiauto>1
                        flag_limit_one_manual_roi = 1;
                    end
                    roimaskman = drawrois(stack(:,:,:,:,c), regionex, pth_tmpfiles, flag_limit_one_manual_roi);
                    save(pth_roimaskman, 'roimaskman', '-v7.3', '-mat')
                end
                roimaskman_allchan{c} = roimaskman;
            end
        end
        if ~isempty(chancpmm) && numchan==2
            chanreceive = setxor(chancpmm, [1,2]);
            sprintf("chancpmm is " + num2str(chancpmm) + "; \nCOPYING ANY DRAWN ROIS FROM CHANNEL " + num2str(chancpmm) + " ONTO CHANNEL " + num2str(chanreceive));
            if all(roimaskman_allchan{chancpmm}==1, 'all') && ~all(roimaskman_allchan{chanreceive}==1, 'all')
                sprintf("warning projecting a manual mask of all ones onto a manual mask that is not all ones; you may not intend this");
            end
            roimaskman_allchan(chanreceive) = roimaskman_allchan(chancpmm);
        end
    end
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
                sprintf("WARNING,\n" + ...
                    "if roisrt is 'morph_long_axis', rois will be sorted by drawn roi index, not morph long axis, \n" + ...
                    "since determining the long axis of extraction currently requires automated morph roi extraction")
            else
                [roiwt, roicen, num_roim] = ...
                    roimauto(stackmnt_tmp, roimaskman, numroiauto, ...
                    widyxz, stack_hires, hrlr, pth_roim_prefix, ...
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
    sprintf("chancpmm is " + num2str(chancpma) + "; \nCOPYING ROI INFO FROM CHANNEL " + num2str(chancpma) + " ONTO CHANNEL " + num2str(chanreceive));
    roidat(chanreceive) = roidat(chancpma);
end



%% load/select functional (caiman) roi responses

roifmake(... 
    stacksub, ...
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


if doimhsv %roi as hue
    imhsv = plots_setup_hsv(imhsv);
    hueft = [1:num_roim]';
    hsvmap = hsvcmp(imhsv, hueft=hueft);
    pthhsv = [pth_roim_prefix 'hsvfov_.gif'];
    plotchannel = 1;
    hsvplt(imhsv, stackmnt(:,:,:,:,plotchannel), hsvmap, roipx, roiwt, dohsv, pthhsv);
end

if doroiol %roi overlay
    ptholay = [pth_roim_prefix 'roioverlay_.gif'];
    gifvis = 'on';
    plotchannel = 1;
    stackplt(stackmnt(:,:,:,:,plotchannel), pthgif=ptholay, gifvis=gifvis, roipx=roipx, ir=roiol.ir, roicols=roiol.roicol, roialpha=roiol.roialpha) %include roipx as argument to plot roi overlay
end


if doplt %all these are at imaging resolution

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



