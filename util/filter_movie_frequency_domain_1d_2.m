function imout = filter_movie_frequency_domain_1d_2(stack, keepfreq, pthstackdir, doplt)

stack = double(stack);

Ts = 1;                                                             % Sampling Interval
Fs = 1/Ts;                                                          % Sampling Frequency
Fn = Fs/2;                                                          % Nyquist Frequency
L = size(stack,1);                                                   % Length Of ‘data’ Vector
t = 1:L*Ts;
%t = linspace(0, 1, L)*Ts;% Time Vector

FTdataall = fft(stack)./L;                                               % Fourier Transform
Fv = linspace(0, 1, fix(L/2)+1)*Fn;                                 % Frequency Vector (One-Sided FFT)
Iv = 1:length (Fv);                                                 % Index Vector
Ivkf = 1:keepfreq;                                                      % 8First keepfreq FFT Frequencies
Fkfth = Fv(keepfreq);                                                     % Frequency Corresponding To keepfreqth Element
FLen = 48;                                                          % Discrete Filter Order


if doplt
    figure;
end

imout = zeros(size(stack));
for indi = 1:size(FTdataall, 2)

    data = stack(:,indi);
    b_filt = fir1(FLen, Fkfth/Fn, chebwin(FLen+1,30));                                       % Design FIR Filter
    imout(:,indi) = fftfilt(b_filt, data);

    if (mod(indi, 120)==90 |  mod(indi, 120)==10) & doplt

        if mod(indi, 120)==10
            spi = 0;
        elseif mod(indi, 120)==90
            spi = 1;
        end

        FTdata = FTdataall(:,indi);

        subplot(5,2,1+spi)
        plot(Fv, log(abs(FTdata(Iv)))*2)
        grid

        subplot(5,2,3+spi)
        plot(Fv(Ivkf), log(abs(FTdata(Ivkf)))*2)
        grid

        FLen = 48;                                                          % Discrete Filter Order
        b_filt = fir1(FLen, Fkfth/Fn, chebwin(FLen+1,30));                                       % Design FIR Filter

        subplot(5,2,5+spi)
        [hout, hf] = freqz(b_filt, 1, 4096, Fs);
        plot(hf, abs(hout))
        hold on
        plot(hf, angle(hout))

        imout = fftfilt(b_filt, data);

        subplot(5,2,7+spi)
        plot(t, data)
        title('Original Data')
        grid
        subplot(5,2,9+spi)
        plot(t, imout)
        title('Filtered Data')
        grid
        "done"
    end


end