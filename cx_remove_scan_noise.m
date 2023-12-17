

function cx_remove_scan_noise(recdate_in, fly_in, trial_in, smooth_window_temporal_in, indx_in)

recdate_in
fly_in
trial_in
smooth_window_temporal_in
indx_in


%% determine which recordings to do based on last input


numfil = 5;
if isstring(indx_in)
    indx_in = strsplit(indx_in, ':');
    indx_in = str2num(indx_in{end});
    indx = indx_in;
else
    indx = indx_in;
end
dofil = [1:numfil]+numfil*(indx-1);

dofil

%% params

enclosing_folder_on_scratch = 'stacks';
currdir = split(pwd, '/');
currdir = currdir{end};
envname = getenv('HOSTNAME');
if ~isempty(regexp( envname, 'compute-', 'once' ))
    pth_super = ['/n/scratch3/users/'  currdir(1) '/' currdir '/' enclosing_folder_on_scratch '/'];
    plotgif = 0;
else
    pth_super = '~/Documents/stacks/';
    plotgif = 1;
end

recdate = recdate_in;
fly = fly_in;
trial = trial_in;
smooth_window_temporal = smooth_window_temporal_in; %this helps with filtering the scannoise, make 0 to skip, gaussian window length, std is 1/10th smooth_window_temporal

stopband = [10 20]; %set emperically for now, stopband frequency indices keep between 2 and half x length . . . hopefully scan noise is fairly constant across recordings

plotinds_t = -40; %t indices to plot, blank for all, negative for that number equidistant from all available
plotinds_z = []; %z indices to plot, blank for all, negative for that number equidistant from all available
swapdim_plot = 1; %true will flip z and t for plotting to change perspective on registration, recommended for length(plotinds_z)>1
testframes = 0; %make zero to do all frames, nonzeros to do 1:testframes
ncol = 256; %num colors in plot


%% filenames


fn_pattern = [pth_super '**' filesep recdate '_' fly '_' trial '_cmrg_dcdn_.tif'];
pth_all = rdir(fn_pattern);
fn_pattern
pth_all

%% loop over recordings

for ri = 1:length(pth_all)

    if ismember(ri, dofil)

        pth_dn_tif = pth_all(ri).name;
        display(['processing : ' pth_dn_tif] )

        [pth_fldr, fn_raw_tif, ~] = fileparts(pth_dn_tif);
        pth_fldr = [pth_fldr '/'];
        spl = strjoin(strsplit(fn_raw_tif, '-'), '_'); %if there's a hyphen, separate and then join all with underscore
        spl = strsplit(spl, '_'); %then separate by underscore

        datenum = str2double(spl{1});
        flynum = str2double(spl{2});
        trialnum = str2double(spl{3});

        recid = [num2str(datenum) '_' num2str(flynum) '_' num2str(trialnum)];
        recid_tit = strrep(recid, '_', ' ');

        pth_dn_mat = [pth_dn_tif(1:end-4) '.mat'];
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
            plotinds_z = round(linspace(1, sz(3), -plotinds_z));
        end

        if isempty(plotinds_t)
            plotinds_t = 1:sz(4);
        elseif plotinds_t<0
            plotinds_t = round(linspace(1, sz(4), -plotinds_t));
        end

        plotinds_z_str = sprintf('%.0f,', plotinds_z);
        plotinds_z_str = plotinds_z_str(1:end-1);% strip final comma


        %% load

        try
            load(pth_dn_mat)
            if exist('stackreg', 'var')
                stackdn = stackreg;
                clear stackreg
            end
        catch
            out_datatype = "uint16"; %UINT16 HERE BECAUSE WRITTEN THAT WAY IN PYTHON
            stackdn = cx_read_tif_tzyx(pth_dn_tif, ...
                out_datatype, size_read_to, ...
                size_z_read_from, size_t_read_from, ...
                inds_z_read_from, inds_t_read_from);
            save(pth_dn_mat, 'stackdn', '-v7.3', '-mat')
        end


        %% smooth


        if smooth_window_temporal
            stackdn = smoothdata(stackdn, 4, 'gaussian', smooth_window_temporal);
        end



        %% plot before filtering

        if plotgif

            pth_gif = [pth_fldr 'prefilt_' datestr(now,30) '_.gif'];
            title_str = 'filt';
            cx_plot_gif_fast(rescale(stackdn(:,:,plotinds_z, plotinds_t), 0, 1), ncol, swapdim_plot, pth_gif, title_str)

        end


        %% filter


        stackdn = cx_fft_filter_1d(stackdn, stopband, testframes, 0);


        %% plot after filtering

        if plotgif

            pth_gif = [pth_fldr 'postfilt_' datestr(now,30) '_.gif'];
            title_str = 'filt';
            cx_plot_gif_fast(rescale(single(stackdn(:,:,plotinds_z, plotinds_t)), 0, 1), ncol, swapdim_plot, pth_gif, title_str)

        end


        %% save


        save(pth_dn_nosn_mat, 'stackdn', '-v7.3', '-mat')



    end

end

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

