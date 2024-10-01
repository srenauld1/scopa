function img = hsvplt(plt, stackmnt, hsvmap, roipx, roiwt, doplt, pthgif)

% hue: 0 red , 0.2 yellow, 0.4 green, 0.6 blue, 0.8 magenta

arguments
    plt
    stackmnt
    hsvmap
    roipx
    roiwt = []
    doplt = 0
    pthgif = ''
end

if strcmp(plt.foreground, 'allrois') && isempty(roiwt)
    error("for foreground 'allrois' you must also pass roiwt")
end

if isempty(pthgif)
    pthgif = pthauto(vnm=pthgif, suffix='.gif', usetime=1, usefun=1);
end

numscalebg = 256; %background intensity depth

if plt.ignorehue
    hsvmap(:,1) = 1;
end
if plt.ignoresat
    hsvmap(:,2) = 1;
end
if plt.ignoreval
    hsvmap(:,3) = 1;
end


cmapgray = colormap(gray(numscalebg));

stackmnt = rescale(stackmnt, 0, numscalebg-1);
stackmnt = uint16(stackmnt); %this will round to nearest int, we use ints because ind2rgb will map 0 to first value in cmap (which is zero/black)

size_imgnew = [size(stackmnt, 1)  size(stackmnt, 2)  size(stackmnt, 3) 3];  %specify size(stackmean, 3) in case it's 1, to keep ndims(size_imgnew)==4
imgtmp = zeros(size_imgnew, 'single');
for si = 1:size(stackmnt, 3)
    imgtmp(:,:,si,:) = ind2rgb(stackmnt(:,:,si), cmapgray); %create the background FOV intensity grayscale (may not get used though)
end
imgtmp = reshape(imgtmp, [], size(imgtmp, 4)); %collapse spatial dimensions to make pixel by time


switch plt.foreground

    case 'pixels'

        imgtmp(cell2mat(roipx), :) = hsv2rgb( hsvmap );
        imgtmp = reshape(imgtmp, size_imgnew);

    case 'eachroi'

        imgtmp = repmat(imgtmp, [ones(1, ndims(imgtmp)) numel(roipx)]);
        rgbmap = cell(1, length(roipx));
        for ir = 1:numel(roipx)
            rgbmap{ir} = hsv2rgb( hsvmap(ir, :));
            rgbmap{ir} = repmat(rgbmap{ir}, [numel(roipx{ir}) 1]);
            imgtmp(roipx{ir}, :, ir) = rgbmap{ir};
        end
        imgtmp = reshape(imgtmp, [size_imgnew, size(imgtmp, 3)]);

    case 'allrois'

        roiwt(end+1,:) = 1 - sum(roiwt); %last row is background (non-roi) contribution to each voxel's signal
        roiwt = reshape(roiwt.', size(roiwt,2), 1, size(roiwt,1));
        imgtmp = repmat(imgtmp, [ones(1, ndims(imgtmp)) numel(roipx)+1]); %extra one for bg
        for ir = 1:numel(roipx)
            rgbmap{ir} = hsv2rgb( hsvmap(ir, :));
            rgbmap{ir} = repmat(rgbmap{ir}, [numel(roipx{ir}) 1]);
            imgtmp(roipx{ir}, :, ir) = rgbmap{ir};
        end
        imgtmp = sum(roiwt.*imgtmp, 3); %for each voxel, weighted mean of contribution from all rois and background (can be range 0-1 for some roi extractions methods); this only occurs in 'allrois' foreground because must deal with how voxels can be shared among rois
        imgtmp = reshape(imgtmp, size_imgnew);


    case 'raw'

        error("hsv method raw does not exist yet")

end

img = zeros(size(imgtmp), 'uint8');
for ir = 1:size(imgtmp,5) %each roi, if foreground is 'eachroi'
    for iz = 1:size(imgtmp,3)
        img(:,:,iz,:,ir) = im2uint8(imgtmp(:,:,iz,:,ir));
    end
end


if doplt

    tittmp = strsplit(pthgif(1:end-4), '/');
    ttl = {strrep(tittmp{end}, '_', ' ')};

    hfg = figure( 'Units', 'Normalized', 'WindowState', 'fullscreen') ;

    cnt = 0;
    for ir = 1:size(img, 5)
        for iz = 1:size(img, 3)
            cnt = cnt+1;

            if cnt==1
                hax = axes( 'Parent', hfg, 'Position', [0 0 1 1] );
                hpl = image(hax, squeeze(img(:,:,iz,:,ir)));
                axis image
                axis off
                axis ij
            else
                hpl.CData = img(:,:,iz,:,ir);
            end

            fig2gif(hfg, cnt, pthgif)

        end
    end

end


