function imout = fftfilter_eachline(imin, freqin, testframes, doplots)

maxnumplots = 5;

if testframes
    doframes = 1:testframes;
else
    doframes = 1:size(imin, 4);
end

szperm = [size(imin, 2), size(imin, 1), size(imin, 3), length(doframes)];
imin = permute(imin, [2 1 3 4]);
imin = reshape(imin(:,:,:,doframes), size(imin, 1), []);  %collapse z and t because we believe dominant structure is through true time (not volume time)


Ts = 1;                                                             % Sampling Interval
Fs = 1/Ts;                                                          % Sampling Frequency
Fn = Fs/2;                                                          % Nyquist Frequency
L = size(imin,1);                                                   % Length Of ‘data’ Vector
t = 1:L*Ts;
%t = linspace(0, 1, L)*Ts;% Time Vector

if doplots
    FTdataall = fft(imin)./L;                                               % Fourier Transform
end
Fv = linspace(0, 1, fix(L/2)+1)*Fn;                                 % Frequency Vector (One-Sided FFT)
Iv = 1:length (Fv);                                                 % Index Vector
Ivkf = 1:freqin(1);                                                      % 8First keepfreq FFT Frequencies

Fkfth = Fv(freqin(1));                                                     % Frequency Corresponding To keepfreqth Element
if length(freqin)==2
    Fkfth2 = Fv(freqin(2));                                                     % Frequency Corresponding To keepfreqth Element
end

FLen = 40;                                                          % Discrete Filter Order
if length(freqin)==1
    b_filt = fir1(FLen, Fkfth/Fn, chebwin(FLen+1,30));                                       % Design FIR Filter
else
    b_filt = fir1(FLen, [Fkfth/Fn Fkfth2/Fn], 'stop', chebwin(FLen+1,30));                                       % Design FIR Filter
end


plotcount = 0;
imout = zeros(size(imin), 'single');

for indi = 1:size(imin, 2)

    data = double(imin(:,indi));
    mnd = mean(data);
    data = data - mnd;
    tmpout = fftfilt(b_filt, data);


    imout(:,indi) = tmpout + mnd;

    % if (mod(indi, 120)==90 |  mod(indi, 120)==10) & plotcount <= maxnumplots & doplots
    %
    %     if mod(indi, 120)==10
    %         figure
    %     end
    %
    %     plotcount = plotcount + 1;
    %
    %     if mod(indi, 120)==10
    %         spi = 0;
    %     elseif mod(indi, 120)==90
    %         spi = 1;
    %     end
    %
    %     FTdata = FTdataall(:,indi);
    %
    %     subplot(5,2,1+spi)
    %     plot(Fv, log(abs(FTdata(Iv)))*2)
    %     grid
    %
    %     subplot(5,2,3+spi)
    %     plot(Fv(Ivkf), log(abs(FTdata(Ivkf)))*2)
    %     grid
    %
    %     FLen = 48;                                                          % Discrete Filter Order
    %     b_filt = fir1(FLen, Fkfth/Fn, chebwin(FLen+1,30));                                       % Design FIR Filter
    %
    %     subplot(5,2,5+spi)
    %     [hout, hf] = freqz(b_filt, 1, 4096, Fs);
    %     plot(hf, abs(hout))
    %     hold on
    %     plot(hf, angle(hout))
    %
    %     imout = fftfilt(b_filt, data);
    %
    %     subplot(5,2,7+spi)
    %     plot(t, data)
    %     title('Original Data')
    %     grid
    %     subplot(5,2,9+spi)
    %     plot(t, imout)
    %     title('Filtered Data')
    %     grid
    % end


end


imout = reshape(imout, szperm);
imout = permute(imout, [2 1 3 4]);
if ~isa(imout, 'single')
    imout = single(imout);
end
