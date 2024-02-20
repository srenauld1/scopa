function filter_rois(bwMaskStack)


%% ensure that ROIs do not overlap
% bwMaskStack = bwMaskStack .* repmat( ~logical( sum( bwMaskStack, 3 ) > 1 ), [1 1 size( bwMaskStack, 3 )] ); % discard all overlapping pixels
for roiInd = 1 : size( bwMaskStack, 3 ) % assign overlapping pixels to the bigger/stronger ROI (ROI odering above)
    bwMaskStack(:, :, [roiInd + 1 : size( bwMaskStack, 3 )] ) = repmat( ~bwMaskStack(:, :, roiInd), [1 1 numel( [roiInd + 1 : size( bwMaskStack, 3 )] )] ) .* ...
        bwMaskStack(:, :, [roiInd + 1 : size( bwMaskStack, 3 )] );
end
bwMaskStack = bwMaskStack( :, :, squeeze( logical( sum( sum( bwMaskStack ) ) ) ) );

%% bwareaopen

%minPixelsPerRegion = 3; 

for roiInd = 1 : size( bwMaskStack, 3 )
    bwMaskStack(:, :, roiInd) = bwareaopen( bwMaskStack(:, :, roiInd), minPixelsPerRegion );
end

roiInds = find( sum( sum( bwMaskStack ) ) > 0 );
[bwMask, bwLabel, nROIs, bwMaskStack] = UpdateROIData_Subsample( bwMaskStack, roiInds );

disp( [num2str( nROIs ) ' ROIs left after bwareaopen.'] );
if diagnosticFlag figure; imagesc( bwLabel ); axis image; pause; end

%% filter ROIs based on size

sizeInterval = [5 15000];

for roiInd = 1 : size( bwMaskStack, 3 )
    tmp = sum( sum( bwMaskStack(:, :, roiInd) ) );
    if tmp < sizeInterval(1) || tmp > sizeInterval(2)
        bwMaskStack(:,:, roiInd) = 0;
    end
end

roiInds = find( sum( sum( bwMaskStack ) ) > 0 );
[bwMask, bwLabel, nROIs, bwMaskStack] = UpdateROIData_Subsample( bwMaskStack, roiInds );

disp( [num2str( nROIs ) ' ROIs left after restriction on size.'] );
if diagnosticFlag figure; imagesc( bwLabel ); axis image; pause; end

%% filter ROIs based on number of disconnected components

%maxRegionsPerROI = 8;

for roiInd = 1 : size( bwMaskStack, 3 )
    tmp = bwconncomp( bwMaskStack(:, :, roiInd) );
    if tmp.NumObjects > maxRegionsPerROI
        bwMaskStack(:,:, roiInd) = 0;
    end
end

roiInds = find( sum( sum( bwMaskStack ) ) > 0 );
[bwMask, bwLabel, nROIs, bwMaskStack] = UpdateROIData_Subsample( bwMaskStack, roiInds );

disp( [num2str( nROIs ) ' ROIs left after restriction on number of disconnected components.'] );
if diagnosticFlag figure; imagesc( bwLabel ); axis image; pause; end
