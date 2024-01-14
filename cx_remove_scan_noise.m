

function cx_remove_scan_noise(pth_datafile, len_window_smooth_t_rsc, do_plots)

fprintf("\n\n\nENTERING cx_remove_scan_noise")

%pth_datafile is full path to tif or mat (if mat is in same folder with
%tif, it will be loaded without reading the tif)

stopband = [10 20]; %set emperically for now, stopband frequency indices keep between 2 and half x length . . . hopefully scan noise is fairly constant across recordings

plotinds_t = -40; %t indices to plot, blank for all, negative for that number equidistant from all available
plotinds_z = []; %z indices to plot, blank for all, negative for that number equidistant from all available
swapdim_plot = 1; %true will flip z and t for plotting to change perspective on registration, recommended for length(plotinds_z)>1
testframes = 0; %make zero to do all frames, nonzeros to do 1:testframes
ncol = 256; %num colors in plot

len_window_smooth_t = len_window_smooth_t_rsc; %helps with filtering the scan noise, make 0 to skip, gaussian window length, std is 1/10th len_window_smooth_t


[~, filnam, ~] = fileparts(pth_datafile);

if ~isempty(regexp(filnam, regexptranslate('wildcard', '_raw'))) || ~isempty(regexp(filnam, regexptranslate('wildcard', '_trial')))
    error(sprintf("ERROR, \nTHIS FUNCTION IS NOT WRITTEN FOR STACKS WITH FLYBACK " + ...
        "('raw' or 'trial' in filename), \n" + ...
        "IF YOU WANT TO PASS THOSE STACKS TO THIS FUNCTION, \n" + ...
        "YOU NEED TO ADJUST size_z_read_from AND inds_z_read_from \n" + ...
        "TO MAKE THEM AS THEY APPEAR IN cx_vis_tif.m"))
end


display(['processing : ' pth_datafile] )

[pth_fldr, fn_datafile, ~] = fileparts(pth_datafile);
pth_fldr = [pth_fldr filesep];
spl = strjoin(strsplit(fn_datafile, '-'), '_'); %if there's a hyphen, separate and then join all with underscore
spl = strsplit(spl, '_'); %then separate by underscore

datenum = str2double(spl{1});
flynum = str2double(spl{2});
trialnum = str2double(spl{3});

recid = [num2str(datenum) '_' num2str(flynum) '_' num2str(trialnum)];
recid_tit = strrep(recid, '_', ' ');

pth_dn_mat = [pth_datafile(1:end-4) '.mat']; %in case pth_datafile is a tif, also look for mat (and if it's mat, this does nothing
pth_dn_nosn_mat = [pth_dn_mat(1:end-4) 'nosn_.mat'];
pth_metadata = [pth_fldr recid '_metadatanew_.mat'];

load(pth_metadata) %file created in initial python part of pipeline
sz = single([md.ypix md.xpix md.numslice md.numvol]);

size_z_read_from = sz(3);
size_t_read_from = sz(4);
inds_z_read_from = 1:size_z_read_from; %can choose to not read the flyback frames here
inds_t_read_from = 1:size_t_read_from;
size_read_to = [length(inds_t_read_from), length(inds_z_read_from) sz(1) sz(2)]; %read the way it was written for speed, permute within cx_read_tif_tzyx


if isempty(plotinds_z)
    plotinds_z = 1:sz(3);
elseif plotinds_z<0
    if -plotinds_z<sz(3)
        plotinds_z = round(linspace(1, sz(3), -plotinds_z));
    else
        plotinds_z = 1:sz(3);
    end
end

if isempty(plotinds_t)
    plotinds_t = 1:sz(4);
elseif plotinds_t<0
    if -plotinds_t<sz(4)
        plotinds_t = round(linspace(1, sz(4), -plotinds_t));
    else
        plotinds_t = 1:sz(4);
    end
end


plotinds_z_str = sprintf('%.0f,', plotinds_z);
plotinds_z_str = plotinds_z_str(1:end-1);% strip final comma

ff=mm
%% load

try
    stack = struct2cell(load(pth_dn_mat));
    stack = stack{1};
catch

    "READING DNEOISED TIF"
    stack = cx_read_tif_tzyx(pth_stack_tif, ...
        size_read_to, size_z_read_from, size_t_read_from, ...
        inds_z_read_from, inds_t_read_from);

    datmin = min(stack(:));
    datmax = max(stack(:));
    if ~isa(stack, 'uint16')
        stack = single(stack);
    end
    stack = stack - double(datmin);
    if ~isa(stack, 'uint16')
        if datmax > 2^16-1
            "ERROR, CLIPPING REQUIRED, CHANGE OUTPUT TYPE"
            error
        end
        stack = uint16(stack);
    end

    "SAVING DENOISED AS MAT"
    save(pth_dn_mat, 'stack', '-v7.3', '-mat')

end


%% smooth


if len_window_smooth_t
    stack = smoothdata(stack, 4, 'gaussian', len_window_smooth_t);
end
"DONE SMOOTHING"



%% plot before filtering

if do_plots

    pth_gif = [pth_fldr 'prefilt_' datestr(now,30) '_.gif'];
    title_str = 'filt';
    cx_plot_gif_fast(rescale(stack(:,:,plotinds_z, plotinds_t), 0, 1), ncol, swapdim_plot, pth_gif, title_str)

end


%% filter


stack = cx_fft_filter_1d(stack, stopband, testframes, 0);
"DONE FILTERING"


%% plot after filtering

if do_plots

    pth_gif = [pth_fldr 'postfilt_' datestr(now,30) '_.gif'];
    title_str = 'filt';
    cx_plot_gif_fast(rescale(single(stack(:,:,plotinds_z, plotinds_t)), 0, 1), ncol, swapdim_plot, pth_gif, title_str)

end


%% save


save(pth_dn_nosn_mat, 'stack', '-v7.3', '-mat')

"FINISHED SAVING"


end

%% function for filtering

function imout = cx_fft_filter_1d(imin, stopband, testframes, doplots)


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
Iv = 1:length(Fv);                                                 % Index Vector
Ivkf = 1:stopband(1);                                                      % 8First keepfreq FFT Frequencies
Fkfth = Fv(stopband(1));                                                     % Frequency Corresponding To keepfreqth Element
Fkfth2 = Fv(stopband(2));                                                     % Frequency Corresponding To keepfreqth Element


FLen = 40;                                                          % Discrete Filter Order
b_filt = fir1(FLen, [Fkfth/Fn Fkfth2/Fn], 'stop', chebwin(FLen+1,30));                                       % Design FIR Filter


imout = zeros(size(imin), 'single');

for indi = 1:size(imin, 2) %loop over lines, filtering

    data = double(imin(:,indi));
    mnd = mean(data);
    data = data - mnd;
    tmpout = fftfilt(b_filt, data);
    imout(:,indi) = tmpout + mnd;

end


%put back in 4d
imout = reshape(imout, szperm);
imout = permute(imout, [2 1 3 4]);
if ~isa(imout, 'single')
    imout = single(imout);
end

datmin_raw = min(imout(:));
datmax_raw = max(imout(:));
imout = imout - datmin_raw;
% if datmax_raw > 2^16-1
%     "ERROR, CLIPPING REQUIRED, CHANGE OUTPUT TYPE"
%     error
% end
% imout = uint16(imout);

end

