%% Uniform ROI Functional Analysis

clusterN = 16;
dataType = 'rs'; % or 'dff'

%% Load Flyg Mask Output File
roiClusterData_all = [];
theta_morph_order_EB_all = [];
theta_morph_order_FB_all = [];

parentDir = uigetdir('\\research.files.med.harvard.edu\neurobio\Wilson Lab\Wenyi\2pData\');
parentDirSplit = strsplit(parentDir, {'\','/'});

% Manually get the '_rois_morph_resp_.mat' file 
fileName = uigetfile(parentDir);
maskName = dir(fullfile(parentDir, [fileName(1:26), '*_rois_maskmanual_.mat']));
maskVecName = dir(fullfile(parentDir, [fileName(1:26), '*_rois_morph_morphroidata_.mat']));

load(fullfile(parentDir, fileName), 'resp');
load(fullfile(maskName.folder, maskName.name), 'maskmanual');
load(fullfile(maskVecName.folder, maskVecName.name), 'mask_roi_vec');

% Make images directory to store imaging plots
imagesDir = fullfile(parentDir,'uniFunctionalRoi');
if ~exist(imagesDir, 'dir')
    mkdir(imagesDir)
end
cd(imagesDir)

%% Generate uniform ROIs timeseries matriximagesDir

expID = parentDirSplit{end};

trialNum = str2double(fileName(12));
if contains(fileName, 'eb')
    region = 'EB';
elseif contains(fileName, 'fb')
    region = 'FB';
end

roiClusterData = table(repmat({expID},clusterN,1), ones(clusterN,1)*trialNum, ...
                repmat({[]}, clusterN,1),repmat({[]}, clusterN,1), ...
                repmat({[]},clusterN,1), repmat({[]},clusterN,1), ...
                'VariableNames', {'expID', 'trialNum', ...
                'roiName', 'rawFl', 'trialRoiBaseline', 'expBaseline'});


% Load the uniform ROI timeseries data
uniROI_timeSeries_raw = resp.in_rawf_pc_f_cl_dff010000_w_no;
uniROI_timeSeries_rs = resp.in_rawf_pc_f_cl_rsc000100_w_no;
uniROI_timeSeries_dff = resp.in_rawf_pc_f_cl_dff010000_w_no;

if strcmp(dataType, 'rs')
    uniROI_timeSeries_toUse = uniROI_timeSeries_rs;
elseif strcmp(dataType, 'dff')
    uniROI_timeSeries_toUse = uniROI_timeSeries_dff;
end


%% Cluster Fitting and PCA analysis

% Hierachial clustering
T = clusterdata(uniROI_timeSeries_toUse,'distance', 'euclidean', 'Linkage','ward','Maxclust',clusterN);

% PCA on the neural response data 
[coeff, ~, ~, ~, explained] = pca(double(uniROI_timeSeries_toUse)');
[centerLoc, circleNormal, radius, circleFit, thetaFit] = CircFit3D(coeff(:,1:3));

% Plot the Percentage of variance explained
figure,
hold on
bar(explained(1:50))
yyaxis right
plot(1:numel(explained(1:50)), cumsum(explained(1:50)),'o-', 'MarkerFaceColor', 'r');
ylim([0 100])
h = gca;
% h.YAxis(2).Limits = [0 100];
h.YAxis(2).Color = h.YAxis(1).Color;
h.YAxis(2).TickLabel = strcat(h.YAxis(2).TickLabel, '%');
title('PCA Variance Explained')
saveas(gcf, fullfile(imagesDir, [region,'_PCA_explained_trial00', num2str(trialNum), '.jpg']));

% Find the mean theta value for each cluster
theta_cluster = zeros(clusterN,1);
for i = 1:clusterN
    theta_cluster(i) = wrapTo2Pi(circ_mean(thetaFit(T==i)));
end
[theta_cluster_sort, sort_idx] = sort(theta_cluster); 

% Reassign cluster number based on PCA result
% So that cluster number is sorted by theta value
T_new = T;
for i = 1:clusterN
    T_new(T==i) = find(sort_idx==i);
end

% Plot pixel timeseries data projected down to PC1/2/3
figure('position', [300 300 1100 400]), 
subplot(1,2,1)
scatter3(coeff(:,1),coeff(:,2),coeff(:,3), 30, thetaFit, 'filled');
colorbar
hold on
plot3(circleFit(1,:), circleFit(2,:), circleFit(3,:), 'r', 'LineWidth',2)
title('Fitted Theta')
xlabel('PC1')
ylabel('PC2')
zlabel('PC3')
axis equal
view(double(circleNormal))

subplot(1,2,2)
scatter3(coeff(:,1),coeff(:,2),coeff(:,3), 30, T_new, 'filled');
colorbar
hold on
plot3(circleFit(1,:), circleFit(2,:), circleFit(3,:), 'r', 'LineWidth',2)
title( '16 Clusters')
xlabel('PC1')
ylabel('PC2')
zlabel('PC3')
axis equal
view(double(circleNormal))
saveas(gcf, fullfile(imagesDir, [region, '_PCA_theta_cluster_summary_trial00', num2str(trialNum), '.jpg']));
saveas(gcf, fullfile(imagesDir, [region, '_PCA_theta_cluster_summary_trial00', num2str(trialNum), '.fig']));

% Plot each cluster in the PCA space
figure('position', [200, 200, 1000, 900]),
for i = 1:clusterN
    subplot(4,4,i)
    scatter3(coeff(:,1), coeff(:,2), coeff(:,3), 5,'k', 'filled', 'MarkerFaceAlpha',0.3);
    hold on
    scatter3(coeff(T_new==i,1), coeff(T_new==i,2), coeff(T_new==i,3), 20,'r', 'filled');
    title( 'cluster ', num2str(i))
    xlabel('PC1')
    ylabel('PC2')
    zlabel('PC3')
    axis equal
    view(double(circleNormal))
end
saveas(gcf, fullfile(imagesDir, [region,'_PCA_theta_cluster_ind_trial00', num2str(trialNum), '.jpg']));
saveas(gcf, fullfile(imagesDir, [region,'_PCA_theta_cluster_ind_trial00', num2str(trialNum), '.fig']));



%% Plot each cluster on all planes

for i = 1:clusterN
    figure('Position', [200 200 1300 600]),
    clusterData = sum(mask_roi_vec(T_new == i,:),1);
    clusterData_reshape = reshape(clusterData, size(maskmanual));
    for j = 1:size(maskmanual,3)
        subplot(3,4,j)
        imagesc(clusterData_reshape(:,:,j)+maskmanual(:,:,j))
        clim([0 2])
        title(['Plane ', num2str(j)])
    end
    sgtitle([region ' Cluster ', num2str(i)]);
end

saveas(gcf, fullfile(imagesDir, [region,'_oneClusterMapToAllPlanes_trial00', num2str(trialNum), '.jpg']));
saveas(gcf, fullfile(imagesDir, [region,'_oneClusterMapToAllPlanes_trial00', num2str(trialNum), '.fig']));


%% Plot all clusters on all planes
clusterData_sum = zeros(size(maskmanual));
for i = 1:clusterN
    clusterData = sum(mask_roi_vec(T_new == i,:),1);
    clusterData_reshape = reshape(clusterData, size(maskmanual)).*i;
    clusterData_sum = clusterData_sum + clusterData_reshape;
end
clusterData_sum(clusterData_sum==0) = nan;

figure('Position', [200 200 1600 600]),
for i = 1:size(maskmanual,3)
    subplot(3,4,i)
    imagesc(clusterData_sum(:,:,i), 'AlphaData',~isnan(clusterData_sum(:,:,i)))
    set(gca,'color',0*[1 1 1]);
    clim([1 clusterN])
    colormap hsv
    title(['Plane ', num2str(i)])
    colorbar
end
sgtitle([region ' All Clusters']);
saveas(gcf, fullfile(imagesDir, [region,'_clustersMapPlanesSummary_trial00', num2str(trialNum), '.jpg']));
saveas(gcf, fullfile(imagesDir, [region,'_clustersMapPlanesSummary_trial00', num2str(trialNum), '.fig']));



%% Determine the cluster order based on morphology
% Need to decide, based on morphology, from left to right FB or ventral to
% dorsal EB, which cluster should be the start, and if the order is clockwise
% or counterclockwise, and if any cluster needs to be excluded (e.g. 0 
% signal cluster)
morph_order = [7:11, 13, 14, 16, 1:6];
theta_morph_order = theta_cluster_sort(morph_order);

for iROI = 1:length(morph_order)
    roiClusterData.roiName{iROI} = [region, '_', num2str(iROI)];
    rawFl_new = mean(uniROI_timeSeries_raw(T_new==morph_order(iROI),:),1);
    roiClusterData.rawFl{iROI} = rawFl_new;
    roiClusterData.trialRoiBaseline{iROI} = prctile(rawFl_new,5,'all');
end

if strcmp(region,'EB')
    theta_morph_order_EB_all(:,trialNum) = wrapTo2Pi(theta_morph_order-theta_morph_order(1));
elseif strcmp(region,'FB')
    theta_morph_order_FB_all(:,trialNum) = wrapTo2Pi(theta_morph_order-theta_morph_order(1));
end

roiClusterData_all = [roiClusterData_all; roiClusterData];


%% Save the variables

save(fullfile(parentDir, [expID(1:10),'_roiData_ROIcluster.mat']), 'roiClusterData_all','theta_morph_order_FB_all','theta_morph_order_EB_all')

