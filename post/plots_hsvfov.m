function img = plots_hsvfov(plt, stackmean, hsvmap, roipx, roivec, filename_save)


% hue is 0 red , 0.2 yellow, 0.4 green, 0.6 blue, 0.8 magenta

if ~exist('filename_save', 'var')
    filename_save = [];
end

num_grayscales_bg = 256; %arbitrary

cmapgray = colormap(gray(num_grayscales_bg));

stackmean = rescale(stackmean, 0, num_grayscales_bg-1);
stackmean = uint16(stackmean); %this will round to nearest int, we use ints because ind2rgb will map 0 to first value in cmap (which is zero/black)

size_imgnew = [size(stackmean, 1)  size(stackmean, 2)  size(stackmean, 3) 3];  %specify size(stackmean, 3) in case it's 1, to keep ndims(size_imgnew)==4
imgtmp = zeros(size_imgnew, 'single');
for si = 1:size(stackmean, 3)
    imgtmp(:,:,si,:) = ind2rgb(stackmean(:,:,si), cmapgray); %create the background FOV intensity grayscale (may not get used though)
end
imgtmp = reshape(imgtmp, [], size(imgtmp, 4)); %collapse spatial dimensions to make pixel by time


if plt.ignorehue
    hsvmap(:,1) = 1;
end
if plt.ignoresat
    hsvmap(:,2) = 1;
end
if plt.ignoreval
    hsvmap(:,3) = 1;
end

switch plt.foreground

    case 'pixels'

        imgtmptmp = imgtmp;
        imgtmptmp(cell2mat(roipx), :) = hsv2rgb( hsvmap );
        img = reshape(imgtmptmp, size_imgnew);
        imgtmptmp = [];

    case 'eachroi'

        imgtmp = repmat(imgtmp, [ones(1, ndims(imgtmp)) length(roipx)]);
        rgbmap = cell(1, length(roipx));
        for ri = 1:length(roipx)
            rgbmap{ri} = hsv2rgb( hsvmap(ri, :));
            rgbmap{ri} = repmat(rgbmap{ri}, [numel(roipx{ri}) 1]);
            imgtmp(roipx{ri}, :, ri) = rgbmap{ri};
        end
        img = reshape(imgtmp, [size_imgnew, size(imgtmp, 3)]);

    case 'allrois'

        roivec_and_background = roivec;
        roivec_and_background(end+1,:) = 1 - sum(roivec); %last row is background (non-roi) contribution to each voxel's signal
        imgtmp = repmat(imgtmp, [ones(1, ndims(imgtmp)) numel(roipx)+1]); %extra one for bg
        imgtmp = permute(imgtmp, [1 3 2]);
        for ri = 1:numel(roipx)
            imgtmp(roipx{ri}, ri, :) = repmat(hsvmap(ri, :), [numel(roipx{ri}) 1]);
        end
        imgtmp = hsv2rgb(imgtmp);
        img = sum(roivec_and_background.'.*imgtmp, 2); %weighted mean
        img = permute(img, [1 3 2]);
        img = reshape(img, [size_imgnew, size(img, 3)]);


    case 'raw'

        error("hsv method raw does not exist yet")

end

imgnew = zeros(size(img), 'uint8');
for k = 1:size(img,3)
    imgnew(:,:,k,:) = im2uint8(img(:,:,k,:));
end
img = imgnew;

if ~isempty(filename_save)
    
    tittmp = strsplit(filename_save(1:end-4), '/');
    figure_title = {strrep(tittmp{end}, '_', ' ')};


    hfg = figure( 'Units', 'Normalized', 'WindowState', 'fullscreen') ;

    framecount = 0;
    for ri = 1:size(img, 5)
        for zi = 1:size(img, 3)
            framecount = framecount+1;

            if zi<size(img, 3)+1
                hat{zi} = axes( 'Parent', hfg, 'Position', [0 0 1 1] );
                hold(hat{zi}, 'on');
                switch plt.foreground
                    case 'pixels'
                        hp1t{zi} = image(hat{zi}, squeeze(img(:,:,zi,:)));
                    case {'eachroi', 'allrois'}
                        hp1t{zi} = image(hat{zi}, squeeze(img(:,:,zi,:,ri)));
                end
                axis image % should not have to call axis image because of how subfig width/height were calculated to maintain aspect ratio above
                axis off
                axis ij
            end

            fig2gif(hfg, framecount, filename_save)

        end
    end

end


