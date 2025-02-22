function opt = cmex_opt_derive(opt)

error("you should not be running this function, it will error because it relies on stack info, and at this point in the matlab pipeline the stack hasn't been loaded yet; it is here for reference because it matches optderive which is called within oex, and may one day be used in matlab")


%%%%%%%%%%%% DERIVE main options K, gSiz, AND PATCH options rf, stride, and p_patch, and init options sigma_smooth_snmf, alpha_snmf, and lambda_gnmf, and also morph_gSig, fr, and dxy  %%%%%%%%%%%%

opt.sigma_smooth_snmf = [ opt.sigma_smooth_snmf_time opt.gSig ];
opt.alpha_snmf = opt.sparsity_penalty;
opt.lambda_gnmf = opt.sparsity_penalty;

for m = 1:numel(opt.gSig)
    opt.gSiz(m) = round(2*opt.gSig + 1);
end

if extract_in_2d
    gsiz_use = opt.gSiz(1:2)
else
    gsiz_use = opt.gSiz;
end

if two_channel_ex %patches turned off (process whole fov at once) when seeding functional rois with automatically segmented structural channel rois; PROCESS IN PATCHES AND THEN COMBINE, patches are useful if activity stats vary over fov (e.g. extracting same neurons from regions with varying SNR, patch runs will adapt to local stats)
    opt.rf = []; % setting rf to none will run CNMF on the whole FOV
    opt.stride = [];
    total_vox_ex = prod(dims_spatial_ex);
else
    maxgsiz = max(gsiz_use);
    opt.rf = int(ceil(maxgsiz * opt.patchfac));
    patchFW = opt.rf*2; %patch full width, since rf is half
    opt.stride = int(ceil(maxgsiz * opt.stridefac));
    if extract_in_2d
        total_vox_ex = patchFW*patchFW;
    else
        if patchFW<dims_spatial_ex(3)
            rfz = patchFW;
        else
            rfz = dims_spatial_ex(3);
            total_vox_ex = patchFW*patchFW*rfz;
        end
    end

    if total_vox_ex>=prod(dims_spatial_ex) %reset rf and stride if it turns out the patch is same size as fov or bigger
        error(sprintf("total number voxels in patch is greater than total num voxels in rgname (or full fov, if rgname is 'none'); originally this reverted patch to empty, but this means accurate patch options cannot be set in oset, in the matlab part of the pipeline, because oset occurs before loading stacks, and this exception catches a stack dependent quantity"))
        % total_vox_ex = prod(dims_spatial_ex);
        % opt.rf = []; % setting rf to none will run CNMF on the whole FOV
        % opt.stride = [];
    end
    
end


opt.K = int(round( total_vox_ex / prod(gsiz_use)*opt.roidensity ));  %K is number of components in whole fov (the "whole fov patch")

if opt.deconvolution_in_each_patch && opt.p>0
    opt.p_patch = opt.p; % default is zero (ie do not deconvolution_in_each_patch); if nonzero, run deconvolution in each patch, rather than after merging patches, if nonzero
else
    opt.p_patch = 0;
end

opt.morph_gSig = int(mean(opt.gSig)); %must be odd and greater than 1; only used for cm.base.rois.extract_binary_masks_from_structural_channel (were it's called gSig), which is only used in two_channel_ex when automated structural rois seed the other channel
if opt.morph_gSig<3
    opt.morph_gSig = 3;
end
if mod(opt.morph_gSig,2)~=1
    opt.morph_gSig = opt.morph_gSig + 1;
end

opt.fr = []; %md.volrate; %0.6193  %9.8465 frame period so 1000 / (9.8465 *(113+51)) % approximate frame rate of data - CONFIRMED FPS
opt.dxy = [];
% if md.zfov==0: %md.zfov==0 when stack is xyt (not volumetric xyzt); below, the third element (hard coded 0.0) will be removed
%     opt.dxy = [md.xpix/md.xfov, md.ypix/md.yfov, 0.0 ]; %pixels per micron
% else
%     opt.dxy = [md.xpix/md.xfov, md.ypix/md.yfov, md.numslice/md.zfov]; %pixels per micron
% end
