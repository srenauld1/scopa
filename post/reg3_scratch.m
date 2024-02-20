

close all
clear all
clc

load('~/Documents/ambrose/leprechaunMat/hirestest.mat')
load('~/Documents/ambrose/leprechaunMat/lorestest.mat')
flyback_lr = 5;
flyback_hr = 51;
regProduct = regProduct(:,:,1:end-flyback_lr, :);
stack_hires = stack_hires(:,:,1:end-flyback_hr, :);
meanvol_lr = rescale(mean(regProduct, 4));
meanvol_hr = rescale(mean(stack_hires, 4));
sz_lr = size(meanvol_lr);
sz_hr = size(meanvol_hr);

plot_gif(rescale(meanvol_lr), ['~/Documents/ambrose/leprechaunMat/lorestest_test_.gif'], 256)
plot_gif(rescale(meanvol_hr), ['~/Documents/ambrose/leprechaunMat/hirestest_test_.gif'], 256)


%% 

load('~/Documents/ambrose/leprechaunMat/2dlores_.mat');
% clip_percentile_for_viz = [3 96];
% meanim = process_stack_for_roi_selection(meanvol_lr, filename_roi2d, clip_percentile_for_viz);
% mask2d = drawrois_cx(meanim, filename_roi2d, 'shji');

tmpup = meanvol_lr .* mask2d;
edgethresh = [.1 .9];
edgesig = sqrt(2)*3;
masktmp = edge3(tmpup,'approxcanny',edgethresh, edgesig);
masktmp = imclose(masktmp, strel('disk',8));
mask3d = boolean(masktmp .* tmpup);
meanvol_lr_masked = meanvol_lr .* mask3d;
idxnz = meanvol_lr_masked~=0; %find nonzero indices
meanvol_lr_masked = padarray(meanvol_lr_masked,[0 0 5],0,'both');

F2 = griddedInterpolant(meanvol_lr_masked, 'linear');
meanvol_lr_masked = F2({ 1:size(meanvol_lr_masked,1), 1:size(meanvol_lr_masked,2), linspace(1, size(meanvol_lr_masked,3), sz_hr(3)) });
meanvol_lr_masked(idxnz) = rescale(meanvol_lr_masked(idxnz));

%plot_gif(rescale(meanvol_lr_masked), ['~/Documents/ambrose/leprechaunMat/lorestest_test_.gif'], 256)

vwr = viewer3d(BackgroundColor="black",BackgroundGradient="off");
volshow(meanvol_lr_masked,...
    Parent=vwr,RenderingStyle="Isosurface",IsosurfaceValue=0.05, ...
    Colormap=[1 0 1],Alphamap=1);

%plot_gif(rescale(masktmp), ['~/Documents/ambrose/leprechaunMat/lr3dmask.gif'], 256)

% cleaning up isolated blobs needs background separation, which requires more work 
% blobvols = regionprops3(double(boolean(meanvol_lr_masked)), meanvol_lr_masked, 'Volume');
% allExceptLargest = boolean(meanvol_lr_masked) & largestBlob;
% meanvol_lr_masked = meanvol_lr_masked .* allExceptLargest;


%%

load('~/Documents/ambrose/leprechaunMat/20230627-2_D05_syt7f_018_syt7f/20230627_2_3047_15_140_256_caimanregtrial_002_00001_roi2d_pb_.mat')

tmpup = meanvol_hr .* mask2d;
edgethresh = [.1 .9];
edgesig = sqrt(2)*3;
masktmp = edge3(tmpup,'approxcanny',edgethresh, edgesig);
masktmp = imclose(masktmp, strel('disk',8));
mask3d = boolean(masktmp .* tmpup);
meanvol_hr_masked = meanvol_hr .* mask3d;
meanvol_hr_masked = padarray(meanvol_hr_masked,[0 0 5],0,'both');


vwr = viewer3d(BackgroundColor="black",BackgroundGradient="off");
volshow(meanvol_hr_masked,...
    Parent=vwr,RenderingStyle="Isosurface",IsosurfaceValue=0.05, ...
    Colormap=[0 1 0],Alphamap=1);


%plot_gif(rescale(meanvol_hr_masked), ['~/Documents/ambrose/leprechaunMat/hr3dmask.gif'], 256)


%% 


pixdist_xyz_hr = [0.751, 0.751, 0.751];
pixdist_xyz_lr = [0.751, 0.751, 6];

upsampled_lores = 1;
if upsampled_lores
    pixdist_xyz_lr = pixdist_xyz_hr;
    sz_lr = sz_hr;
    meanvol_lr = meanvol_lr_masked;
    meanvol_hr = meanvol_hr_masked;
end

zeropos_lr = [1, 1, 1]-1;
zeropos_hr = [1, 1, 1]-1;

cntr_firstpix_lr = zeropos_lr + pixdist_xyz_lr/2;
voxdist_lr{1} = [pixdist_xyz_lr(1) 0 0];
voxdist_lr{2} = [0 pixdist_xyz_lr(2) 0];
voxdist_lr{3} = [0 0 pixdist_xyz_lr(3)];
pos_lr = zeros(sz_lr(3), 3);
for zi = 1:sz_lr(3)
    pos_lr(zi,:) = [cntr_firstpix_lr(1), cntr_firstpix_lr(2), cntr_firstpix_lr(3)+pixdist_xyz_lr(3)*(zi-1)];
end
mr3_lr = medicalref3d(sz_lr,pos_lr,voxdist_lr);
mv_lr = medicalVolume(meanvol_lr,mr3_lr);
vox_lr = mv_lr.Voxels;
volsz_lr = mv_lr.VolumeGeometry.VolumeSize;
voxsp_lr = mv_lr.VoxelSpacing;
r3d_lr = imref3d(volsz_lr,voxsp_lr(2), ...
    voxsp_lr(1),voxsp_lr(3));


cntr_firstpix_hr = zeropos_hr + pixdist_xyz_hr/2;
voxdist_hr{1} = [pixdist_xyz_hr(1) 0 0];
voxdist_hr{2} = [0 pixdist_xyz_hr(2) 0];
voxdist_hr{3} = [0 0 pixdist_xyz_hr(3)];
pos_hr = zeros(sz_hr(3), 3);
for zi = 1:sz_hr(3)
    pos_hr(zi,:) = [cntr_firstpix_hr(1), cntr_firstpix_hr(2), cntr_firstpix_hr(3)+pixdist_xyz_hr(3)*(zi-1)];
end
mr3_hr = medicalref3d(sz_hr,pos_hr,voxdist_hr);
mv_hr = medicalVolume(meanvol_hr,mr3_hr);
vox_hr = mv_hr.Voxels;
volsz_hr = mv_hr.VolumeGeometry.VolumeSize;
voxsp_hr = mv_hr.VoxelSpacing;
r3d_hr = imref3d(volsz_hr,voxsp_hr(2), ...
    voxsp_hr(1),voxsp_hr(3));

%%

% [geomtform,vox_reg_lr] = imregmoment(vox_lr,r3d_lr, ...
%     vox_hr,r3d_hr,...
%     MedianThresholdBitmap=true);

fixed = vox_hr;
fixref = r3d_hr;
moving = vox_lr;
movref = r3d_lr;
%% 

fixed = meanvol_hr_masked;
moving = meanvol_lr_masked;

register_subset = 1; %set to 1 to return tform even though you register whole thing
disttype = 'multimodal'; % multimodal monomodal
regtype = 'similarity';
[vox_reg, tforms] = register(moving, fixed, disttype, register_subset, regtype);

viewerRegistered = viewer3d(BackgroundColor="black",BackgroundGradient="off");
volshow(vox_reg,Parent=viewerRegistered,RenderingStyle="Isosurface",IsosurfaceValue=0.1, ...
    Colormap=[0 1 0],Alphamap=0.1);

volshow(fixed,Parent=viewerRegistered,RenderingStyle="Isosurface",IsosurfaceValue=0.1, ...
    Colormap=[1 0 1],Alphamap=0.1);
% 
% 
% volshow(moving,Parent=viewerRegistered,RenderingStyle="Isosurface",IsosurfaceValue=0.05, ...
%     Colormap=[1 1 1],Alphamap=1);

%% 
% 
% [geomtform,vox_reg2] = imregmoment(fixed,fixref);
% mv_reg = medicalVolume(vox_reg, mv_hr.VolumeGeometry);

%%

viewerRegistered = viewer3d(BackgroundColor="black",BackgroundGradient="off");
volshow(mv_reg,Parent=viewerRegistered,RenderingStyle="Isosurface",IsosurfaceValue=0.05, ...
    Colormap=[0 1 0],Alphamap=1);

% volshow(mv_lr,Parent=viewerRegistered,RenderingStyle="Isosurface",IsosurfaceValue=0.05, ...
%     Colormap=[1 0 1],Alphamap=1);


volshow(mv_hr,Parent=viewerRegistered,RenderingStyle="Isosurface",IsosurfaceValue=0.05, ...
    Colormap=[1 0 1],Alphamap=1);
%%

overlay = rescale(rescale(mv_reg) + rescale(mv_hr));
plot_gif(overlay, ['~/Documents/ambrose/leprechaunMat/lorestest_test_reg_overlay.gif'], 256)

mavis = 2;


% filename = '~/Documents/ambrose/leprechaunMat/20230624-2_D05_syt7f_018_syt7f/20230624-2_D05_syt7f_018_syt7f_174356_trial_001_00001.tif';
% read_datatype = "uint16";
% size_z_read_from = 20;
% size_t_read_from = 3047;
% inds_z_read_from = 1:size_z_read_from;
% inds_t_read_from = 1:size_t_read_from;
% size_read_to = [length(inds_t_read_from) length(inds_z_read_from) 140 256]; %read the way it was written for speed
% regProduct = read_tif_tzyx(filename, ...
%     read_datatype, size_read_to, ...
%     size_z_read_from, size_t_read_from, ...
%     inds_z_read_from, inds_t_read_from);
%
% save(filename, 'regProduct', '-v7.3', '-mat')
%
%
%
% filename = '~/Documents/ambrose/leprechaunMat/20230627-2_D05_syt7f_018_syt7f/20230627_2_hires_.tif';
% read_datatype = "uint16";
% size_z_read_from = 164;
% size_t_read_from = 80;
% inds_z_read_from = 1:size_z_read_from;
% inds_t_read_from = 1:size_t_read_from;
% size_read_to = [length(inds_t_read_from) length(inds_z_read_from) 140 256]; %read the way it was written for speed
% stack_hires = read_tif_tzyx(filename, ...
%     read_datatype, size_read_to, ...
%     size_z_read_from, size_t_read_from, ...
%     inds_z_read_from, inds_t_read_from);
%
% save(filename, 'stack_hires', '-v7.3', '-mat')
