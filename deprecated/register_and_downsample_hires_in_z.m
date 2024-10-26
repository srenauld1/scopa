function hrlr_shifted = ...
    register_and_downsample_hires_in_z(lores, hires, ...
    hires_t, sindz, zshift, hrlr)

%this was replaced by hiresrg

%right now this is not automated, but hope to automate using image comparison across z shifts 
%averaging chunks to downsample seems more appropriate than more
%sophisticated downsampling approaches (like IIR zero-phase decimation), 
%since specific chunks of the hires correspond to single frames of the lores
%the registration is just shifts of whole hires frames prior to downsampling/averaging 

if ~exist('zshift', 'var')
    zshift = [0];
end
%% 

for plotloops = 1 %loops just to repeats plots for quick comparison
    %close all
    rand_frames = randi([1 size(lores, 4)], hires_t, 1); %average random number of frames matching hires num frames
    meanframe_lores = rescale(double(mean(lores(:,:,:,rand_frames), 4)));
    countz = 0;
    for zsi = zshift
        countz = countz+1;
        hrlr_shifted = zeros(size(hrlr));
        hrlr_shifted_tmp = circshift(hrlr, zsi);
        if zsi<0
            hrlr_shifted(1:end-abs(zsi)) = hrlr_shifted_tmp(1:end-abs(zsi));
        elseif zsi>0
            hrlr_shifted(1+zsi:end) = hrlr_shifted_tmp(1+zsi:end);
        elseif zsi==0
            hrlr_shifted = hrlr_shifted_tmp;
        end
        hires_downsampled = zeros(size(meanframe_lores));
        for hli = 1:length(sindz)
            hires_downsampled(:,:,hli) = mean(hires(:,:,hrlr_shifted==sindz(hli),:), 3);
        end
        hires_downsampled = rescale(hires_downsampled);
        for hli = 1:length(sindz)
            imsim(hli, countz) = ssim(hires_downsampled(:,:,hli),meanframe_lores(:,:,hli));
            imsnr(hli, countz) = psnr(hires_downsampled(:,:,hli),meanframe_lores(:,:,hli));
            imerr(hli, countz) = immse(hires_downsampled(:,:,hli),meanframe_lores(:,:,hli));
        end
        figure; montage(meanframe_lores, "DisplayRange", [0 0.5]); title(["lores, shift " num2str(zsi)])
        %pause(0.5); %pause so the title is not wrong (apparent bug)
        figure; montage(hires_downsampled, "DisplayRange", [0 0.5]); title(["hires, shift " num2str(zsi)])
        %pause(0.5); %pause so the title is not wrong (apparent bug)
    end
end
%% 

