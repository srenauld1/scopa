

close all
clear all
clc

% %% for each region or full fov 
% %% register lores and hires individually in caiman
% %% extract rois from lores in caiman 
% %% load hires in matlab, draw/apply 2d mask 
% %% create 3d mask an centroids 
% %% load lores in matlab, draw/apply 2d mask, and 3d register to hires (or to 3d mask?) 
% %% find new caiman roi centroids 
% %% map them to hires centroids 

%% 

% filename = '~/Documents/ambrose/leprechaunMat/20230624-2_D05_syt7f_018_syt7f/20230624-2_D05_syt7f_018_syt7f_174356_trial_001_00001.tif';
% read_datatype = "uint16";
% size_z_read_from = 20;
% size_t_read_from = 3047;
% inds_z_read_from = 1:size_z_read_from;
% inds_t_read_from = 1:size_t_read_from;
% size_read_to = [length(inds_t_read_from) length(inds_z_read_from) 140 256]; %read the way it was written for speed
% regProduct = cx_read_tif_tzyx(filename, ...
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
% stack_hires = cx_read_tif_tzyx(filename, ...
%     read_datatype, size_read_to, ...
%     size_z_read_from, size_t_read_from, ...
%     inds_z_read_from, inds_t_read_from);
%
% save(filename, 'stack_hires', '-v7.3', '-mat')


%% 

load('~/Documents/ambrose/leprechaunMat/hirestest.mat')
load('~/Documents/ambrose/leprechaunMat/lorestest.mat')
flyback_lr = 5;
flyback_hr = 51;
regProduct = regProduct(:,:,1:end-flyback_lr, :);
stack_hires = stack_hires(:,:,1:end-flyback_hr, :);
meanvol_lr = rescale(mean(regProduct, 4));
meanvol_hr = rescale(mean(stack_hires, 4));

plot_gif(rescale(meanvol_lr), ['~/Documents/ambrose/leprechaunMat/lorestest_test_.gif'], 256)
plot_gif(rescale(meanvol_hr), ['~/Documents/ambrose/leprechaunMat/hirestest_test_.gif'], 256)


%%

load('~/Documents/ambrose/leprechaunMat/20230627-2_D05_syt7f_018_syt7f/20230627_2_3047_15_140_256_caimanregtrial_002_00001_roi2d_pb_.mat')


tmpup = meanvol_hr .* mask2d;
edgethresh = [.1 .9];
edgesig = sqrt(2)*3;
masktmp = edge3(tmpup,'approxcanny',edgethresh, edgesig);
masktmp = imclose(masktmp, strel('disk',8));
mask3d = boolean(masktmp .* tmpup);
meanvol_hr_masked = meanvol_hr .* mask3d;
zpadframes = 5;
meanvol_hr_masked = padarray(meanvol_hr_masked,[0 0 zpadframes],0,'pre');
idxnz = meanvol_hr_masked~=0;
meanvol_hr_masked(idxnz) = rescale(meanvol_hr_masked(idxnz));
meanvol_hr_masked = double(boolean(meanvol_hr_masked));

% vwr = viewer3d(BackgroundColor="black",BackgroundGradient="off");
% volshow(meanvol_hr_masked,...
%     Parent=vwr,RenderingStyle="Isosurface",IsosurfaceValue=0.05, ...
%     Colormap=[0 1 0],Alphamap=1);

%plot_gif(rescale(meanvol_hr_masked), ['~/Documents/ambrose/leprechaunMat/hr3dmask.gif'], 256)

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
zpadframes = 5;
meanvol_lr_masked = padarray(meanvol_lr_masked,[0 0 zpadframes],0,'pre');
idxnz = meanvol_lr_masked~=0; %find nonzero indices

F2 = griddedInterpolant(meanvol_lr_masked, 'linear');
meanvol_lr_masked = F2({ 1:size(meanvol_lr_masked,1), 1:size(meanvol_lr_masked,2), linspace(1, size(meanvol_lr_masked,3), size(meanvol_hr_masked, 3)) });
meanvol_lr_masked(idxnz) = rescale(meanvol_lr_masked(idxnz));


%plot_gif(rescale(meanvol_lr_masked), ['~/Documents/ambrose/leprechaunMat/lorestest_test_.gif'], 256)

% vwr = viewer3d(BackgroundColor="black",BackgroundGradient="off");
% volshow(meanvol_lr_masked,...
%     Parent=vwr,RenderingStyle="Isosurface",IsosurfaceValue=0.05, ...
%     Colormap=[1 0 1],Alphamap=1);


%% 

fixed = meanvol_hr_masked;
moving = meanvol_lr_masked;

disttype = 'multimodal'; % multimodal monomodal
regtype = 'affine';
register_subset = 1; %set to 1 to return tform even though you register whole thing
[reg, tforms] = cx_register(moving, fixed, disttype, register_subset, regtype);

% to get hires caiman roi centroid 
% add zpadframes to z
% then interp1 to new z scale
% then apply tform to new xyz   

viewerRegistered = viewer3d(BackgroundColor="black",BackgroundGradient="off");
volshow(reg,Parent=viewerRegistered,RenderingStyle="Isosurface",IsosurfaceValue=0.1, ...
    Colormap=[0 1 0],Alphamap=0.1);
volshow(fixed,Parent=viewerRegistered,RenderingStyle="Isosurface",IsosurfaceValue=0.1, ...
    Colormap=[1 0 1],Alphamap=0.1);

overlay = rescale(rescale(reg) + rescale(boolean(fixed)*0.3));
plot_gif(overlay, ['~/Documents/ambrose/leprechaunMat/lorestest_test_reg_overlay.gif'], 256)

mavis = 2;

