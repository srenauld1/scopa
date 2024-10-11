function imout = filter_movie_frequency_domain_1d(imin, fldr, doplt)

numfreqtozero = 50;

imin = double(imin);
fd = fft(imin); % Discrete Fourier-transform of your data

doplt = 1;
imout = zeros(size(imin));
for indi = 1:size(imin, 2)


    imint = imin(:,indi);
    fdt = fd(:,indi);
    % idx = flip(1:length(fdt));
    [~,idx] = sort(abs(fdt),'descend'); % Sort in descending order, this makes indexing simpler
    fdtt = fdt;
    %fdtt(idx([1:numfreqtozero*2])) = 0;  %zero strongest n components
    fdtt(idx([1:numfreqtozero*2]+1)) = 0;  %zero strongest n components
    ifd = ifft(fdtt);    % inverse-Fourier-transform
    if ~isreal(ifd)
        fuk=2;
    end
    imout(:,indi) = ifd;

    if mod(indi, 120)==10 & doplt
        subplot(4,2,1)
        plot(log(abs(fdt)))
        hold on;
        plot(idx(2:5),log(abs(fdt(idx(2:5)))),'r.') % DC-component first, then positive and negative components have equal magnitudes and appear consecutively in idx
        hold off
        subplot(4,2,3)
        plot(log(abs(fdtt)))
        subplot(4,2,5)
        plot(imint)
        subplot(4,2,7)
        plot(ifd)
    end

    if mod(indi, 120)==90 & doplt
        subplot(4,2,2)
        plot(log(abs(fdt))) % Plot of its absolute values
        hold on;
        plot(idx(2:5),log(abs(fdt(idx(2:5)))),'r.') % DC-component will be the first, then the positive and negative components will have equal magnitudes and appear consecutively in idx
        hold off
        subplot(4,2,4)
        plot(log(abs(fdtt)))      % Yup, they're gone.
        subplot(4,2,6)
        plot(imint)
        subplot(4,2,8)
        plot(ifd)
    end

end


if 0

    imf = fftshift(fft(imin, [], 2));
    %%

    imfm = abs(imf); %keep magnitude discard phase

    imfm_log = log(imfm);
    [filtimhist, histx] = hist(imfm_log, 1000);
    thr_bin = triangle_threshold(filtimhist, 'R', 0);
    thr = histx(thr_bin);
    imfm(imfm_log>thr) = 0;

    [x,y]=pol2cart(angle(imf), double(imfm));
    imff = complex(x,y);

    %imff = imf .* filt;
    imout = single(real(ifft(ifftshift(imff)))); %inverse shift then inverse transform (to go back to spatial domain), then real component to remove residual imaginary components remaining because of floating point error
    imout = reshape(imout, size(imin));


    if doplt

        plotindz = 1:500;
        imfm = reshape(imfm, size(imin));
        imff = reshape(imff, size(imin));


        %%

        swapdim = 1;
        ncol = 128;
        pthgif = [fldr '/imout.gif'];
        hfg = figure;
        for mmi = 1:300
            plot(imfm_log(:,mmi))
            fig2gif(hfg, mmi, pthgif)
        end
        %%

        stackplt(rescale(imin(:,1:30)), pthgif=[fldr '/imout.gif'])


        catstack = cat(1, ...
            rescale(imin(:,:,plotindz)), ...
            rescale(log(abs(imfm(:,:,plotindz)))), ...
            rescale(log(abs(imff(:,:,plotindz)))), ...
            rescale(imout(:,:,plotindz)));

        stackplt( catstack, pthgif=[fldr '/finalcat.gif'])

    end
end