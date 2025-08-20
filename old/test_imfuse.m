

close all
clear all
clc

load('~/stacks/imtest.mat', 'stacksub')

roipixindp = {[1:100], [300:400]};
roicol = [ [0 1 0]; [1 0 0]];
roicol = [1 1 0];
roialpha = [0.3, 0.3];

roipixindp2 = {[350:550], [500:600]};
roicol2 = [ [0 0 1]; [1 1 0]];
roicol2 = [1 1 0];
roialpha2 = [0.3, 0.3];

dr = [0 1];

numypix = size(stacksub, 1);
numxpix = size(stacksub, 2);

stackmin = double(min(stacksub(:)));
stackmax = double(max(stacksub(:)));
stackrange = stackmax-stackmin;

stack1 = stacksub(:,:,2,8,1);
stack2 = stacksub(:,:,15,8,2);



clear cb_pr %clear persistent variables
[imroi, imalpha] = roiolmake(imgray=stack1, roipx=roipixindp, col=roicol, alp=roialpha); %make an overlay for all rois, background is one frame since rois don't change across frames
imroi = squeeze(imroi);

clear cb_pr %clear persistent variables
[imroi2, imalpha2] = roiolmake(imgray=stack1, roipx=roipixindp2, col=roicol2, alp=roialpha2); %make an overlay for all rois, background is one frame since rois don't change across frames
imroi2 = squeeze(imroi2);


hfg = figure( 'Units', 'Normalized', 'Color', 'white', 'visible', 'on');
hax = axes('Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition');

hax.DataAspectRatio = [1 1 1]; %don't think this is necessary
hax.XLim = [1 numxpix]; %why do this instead of axis image or dataaspectratio 1 1 1????
hax.YLim = [1 numypix];%why do this instead of axis image or dataaspectratio 1 1 1 ????
hax.CLim = stackrange*dr+stackmin;
hax.Toolbar.Visible = 'off';
colormap(hax, gray(256));
axis off
axis ij

%%

fused2 = imfuse(stack1, stack2, 'method', 'falsecolor', 'scaling', 'independent');

fused = fusecw(stack1, stack2);


hold(hax, 'on')
hpl = image(hax, 'CData', fused2); %dummy_index_dim5=1 will work to initialize for roi_type pixel and roi
hpl.CDataMapping = 'scaled'; %this way, full range of any data type will be mapped to cmap range
% hpl2 = image(hax, 'CData', stack2); %dummy_index_dim5=1 will work to initialize for roi_type pixel and roi
% hpl2.CDataMapping = 'scaled'; %this way, full range of any data type will be mapped to cmap range
hol = image(hax, 'CData', imroi, 'AlphaData', imalpha);
% hol2 = image(hax, 'CData', imroi2, 'AlphaData', imalpha2);
hold(hax, 'off')


function result = fusecw(A, B)

scaling = 'independent';
channels = [2 1 2];
if size(A,3) > 1
    A = rgb2gray(A);
end
if size(B,3) > 1
    B = rgb2gray(B);
end
switch lower(scaling)
    case 'none'
    case 'joint'
        [A,B] = scaleTwoGrayscaleImages(A,B);
    case 'independent'
        A = scaleGrayscaleImage(A);
        B = scaleGrayscaleImage(B);
end

A = im2uint8(A);
B = im2uint8(B);

result = zeros([size(A,1) size(A,2) 3], class(A));
for p = 1:3
    if (channels(p) == 1)
        result(:,:,p) = A;
    elseif (channels(p) == 2)
        result(:,:,p) = B;
    end
end

end


function image_data = scaleGrayscaleImage(image_data)

if (islogical(image_data))
    return
end
% convert to floating point
image_data = single(image_data);
minData = min(image_data(:));
maxData = max(image_data(:));

if (minData == maxData)
    return
end

% Scale to range [0 1]
image_data = (image_data - minData)/(maxData - minData);

end % scaleGrayscaleImage
