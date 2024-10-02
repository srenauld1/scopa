function imout = filter_movie_frequency_domain(imin, fldr, doplt)


%remove pmt ripple noise in 2p images
%noise creates horizontal and vertical lines in 3d frequency domain, especially in spatial part
%code below isolates those lines and removes them

%% params

inpaint_method = 'mask';
spectrum_smooth_window = 5;
line_image_smooth_window = 3;
line_filt_len_short = 3; %short axis of lines to extract from spectrum
line_filt_len_long = 17; %long axis of lines to extract from spectrum
morphological_open_line_len = 17; %cleans up extracted lines in spectrum if length is right


numplotframes = 100;
plotindz = floor(size(imin, 3)*size(imin, 4) / 2) - floor(numplotframes/2) : floor(size(imin, 3)*size(imin, 4) / 2) + floor(numplotframes/2); %time indices to plot (center of spectrum is where noise is worst)
%plotindz = 1:size(imin, 3)*size(imin, 4);
swapdim = 1; %recommend 1 if plotting gif of multiple z slices through time


%% fft then log

%imin = permute(imin, [1 2 4 3]);
imin = reshape(imin, size(imin, 1), size(imin, 2), []);  %collapse z and t because we believe dominant structure is through true time (not volume time)

%stack2fig(rescale(imin(:,:,plotindz)), pthgif=[fldr '/imin.gif'])

imf = fftshift(fftn(imin)); %forward transform (take image into freq domain), then shift

imfm = single(abs(imf)); %keep magnitude discard phase

%stack2fig(rescale(log(imfm(:,:,plotindz))), pthgif=[fldr '/imfm_log.gif'])


%% create background frames

background_mag = log(imfm);
[histbg, histx] = hist(background_mag(:), 256);
thrbinbg = triangle_threshold(histbg, 'R', 0);
thr_bg = histx(thrbinbg);
foregroundinds = background_mag>=thr_bg;
background_mag(foregroundinds) = 0;

%stack2fig(rescale(background_mag(:,:,plotindz)), pthgif=[fldr '/freqfilt_smooththresh.gif'])
clear background_mag

numframes_bg = floor(size(imin, 3)/50);
numbginds_randsamp = size(imin, 1)*size(imin, 2)*numframes_bg;

background = imf;
background(foregroundinds) = [];
background = datasample(background, numbginds_randsamp, 'Replace', false);
background = reshape(background, size(imin, 1), size(imin, 2), numframes_bg);



%% smooth to strengthen spectrum lines

if spectrum_smooth_window
    imfms = smoothdata(imfm, 3, 'gaussian', spectrum_smooth_window); %smooth spectrum through time because noise spectrum is noisy in time but not space
end

%stack2fig(rescale(log(imfm(:,:,plotindz))), pthgif=[fldr '/imfm_logsmooth.gif'])


%%apply std filters (horiz. and vert.) to extract spectrum lines (lines have small std in long axis and relatively large std in ortho axis)


line_filt_short_h = ones(1, line_filt_len_short)'; %short vertical std filter
line_filt_long_h = ones(line_filt_len_long, 1)'; %long vertical std filter
line_filt_short_v = ones(1, line_filt_len_short); %short horizontal std filter
line_filt_long_v = ones(line_filt_len_long, 1); %long horizontal std filter
freqfilt = zeros(size(imfm), 'single');
for i = 1:size(imfm, 3)

    if 1%ismember(i, plotindz)

        tmpim = imfm(:,:,i);

        %extract vertical lines
        imstdshortv = stdfilt(tmpim, line_filt_short_v) / line_filt_len_short;
        imstdlongv = stdfilt(tmpim, line_filt_long_v) / line_filt_len_long;
        filtimv = imstdshortv ./ imstdlongv;
        if morphological_open_line_len
            %filtimv = imgaussfilt(filtimv, 1); %smooth again before threshold to remove some isolated hotspots
            filtimv = imopen(filtimv, strel('line', morphological_open_line_len, 90)); %clean up with imopen
        end

        %extract horizontal lines
        imstdshorth = stdfilt(tmpim, line_filt_short_h) / line_filt_len_short;
        imstdlongh = stdfilt(tmpim, line_filt_long_h) / line_filt_len_long;
        filtimh = imstdshorth ./ imstdlongh;
        if morphological_open_line_len
            %filtimh = imgaussfilt(filtimh, 1); %smooth again before threshold to remove some isolated hotspots
            filtimh = imopen(filtimh, strel('line', morphological_open_line_len, 0)); %clean up with imopen
        end

        freqfilt(:,:,i) = (filtimh + filtimv) / 2; %combine for full h and v line filter
    end
end


%clear imfm
%freqfilt = imgaussfilt3(freqfilt(:,:,plotindz), [2 2 2]); %smooth again before threshold to remove some isolated hotspots
%stack2fig(rescale(freqfilt), pthgif=[fldr '/freqfilt.gif'])

%stack2fig(rescale(freqfilt(:,:,plotindz)), pthgif=[fldr '/freqfilt.gif'])

%%smooth then threshold extracted "line image"

if line_image_smooth_window
    freqfilt = imgaussfilt3(freqfilt, line_image_smooth_window); %smooth again before threshold to remove some isolated hotspots
end

[filtimhist, histx] = hist(freqfilt(:), 1000);
thr_bin = triangle_threshold(filtimhist, 'R', 0);
thr = histx(thr_bin);
freqfilt(freqfilt<=thr) = 0;
freqfilt(freqfilt>thr) = 1;
 

for i = 1:size(freqfilt, 3)
    freqfilt(:,:,i) = bwmorph(freqfilt(:,:,i), 'bridge', Inf);
end

%stack2fig(rescale(freqfilt(:,:,plotindz)), pthgif=[fldr '/freqfilt_smooththresh.gif'])


%%apply filter by replacing corresponding values in spectrum

%freqfilt = freqfilt / numel(find(freqfilt));
%freqfilt = double(reshape(freqfilt, size(imf)));
%
% freqfilt2 = abs(freqfilt - max(freqfilt(:)));
% %stack2fig(rescale(freqfilt2(:,:,plotindz)), pthgif=[fldr '/freqfilt_smooththresh.gif'])
%
% imff = imf .* freqfilt2; %apply frequency filter (which has been designed in the "shifted space")
% logabs = log(abs(imff));
% logabs(isinf(logabs)) = min(logabs(isfinite(logabs)));
% logabs(isinf(logabs)) = max(logabs(isfinite(logabs)));
% stack2fig(rescale(logabs), pthgif=[fldr '/imout.gif'])
%% 

freqfilt = zeros(size(imfm), 'single');
freqfilt(40:80,80:160,:) = 1;

freqfilt = boolean(freqfilt);
imff = complex(zeros(size(imf)), 0);
for i = 1:size(imf, 3)
    tmp = imf(:,:,i);
    tmpfilt = freqfilt(:,:,i);
    switch inpaint_method
        case 'mask'
            mask_fg = tmp.*~tmpfilt;
            mask_bg = background(:,:,randi([1 numframes_bg])).*tmpfilt;
            imff(:,:,i) = mask_fg + mask_bg;
        case 'exemplar'
            imfrf = inpaintExemplar(real(tmp), tmpfilt, 'PatchSize', [3 3]);
            imfif = inpaintExemplar(imag(tmp), tmpfilt, 'PatchSize', [3 3]);
            imff(:,:,i) = complex(imfrf, imfif);
        case 'coherent'
            imfrf = inpaintCoherent(real(tmp), tmpfilt, 'SmoothingFactor', 2, 'Radius', 50);
            imfif = inpaintCoherent(imag(tmp), tmpfilt, 'SmoothingFactor', 2, 'Radius', 50);
            imff(:,:,i) = complex(imfrf, imfif);
    end

end

stack2fig(rescale(log(abs(imff(:,:,plotindz)))), pthgif=[fldr '/fftfilt.gif'])


%% return to spatial domain

%clear imf
imout = single(real(ifftn(ifftshift(imff)))); %inverse shift then inverse transform (to go back to spatial domain), then real component to remove residual imaginary components remaining because of floating point error

stack2fig(rescale(imout(:,:,plotindz)), pthgif=[fldr '/imout.gif'])

%% plots

if doplt
    
    catstack = cat(1, ...
        rescale(imin(:,:,plotindz)), ...
        rescale(log(abs(imfm(:,:,plotindz)))), ...
        rescale(freqfilt(:,:,plotindz)), ...
        rescale(log(abs(imff(:,:,plotindz)))), ...
        rescale(imout(:,:,plotindz)));

    stack2fig( catstack, pthgif=[fldr '/finalcat.gif'])

end