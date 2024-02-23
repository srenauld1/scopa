

function remove_scan_noise(pth_datafile, len_window_smooth_t_rsc, makeplots)

fprintf("\n\n\nENTERING remove_scan_noise")

%pth_datafile is full path to tif or mat (if mat is in same folder with
%tif, it will be loaded without reading the tif)

stopband = [10 20]; %set emperically for now, stopband frequency indices keep between 2 and half x length . . . hopefully scan noise is fairly constant across recordings

plotinds_t = -40; %t indices to plot, blank for all, negative for that number equidistant from all available
plotinds_z = []; %z indices to plot, blank for all, negative for that number equidistant from all available
swapdim_plot = 1; %true will flip z and t for plotting to change perspective on registration, recommended for length(plotinds_z)>1

len_window_smooth_t = len_window_smooth_t_rsc; %helps with filtering the scan noise, make 0 to skip, gaussian window length, std is 1/10th len_window_smooth_t


[~, filnam, ~] = fileparts(pth_datafile);

if ~isempty(regexp(filnam, regexptranslate('wildcard', '_raw'))) || ~isempty(regexp(filnam, regexptranslate('wildcard', '_trial')))
    error(sprintf("ERROR, \nTHIS FUNCTION IS NOT WRITTEN FOR STACKS WITH FLYBACK " + ...
        "('raw' or 'trial' in filename), \n" + ...
        "IF YOU WANT TO PASS THOSE STACKS TO THIS FUNCTION, \n" + ...
        "YOU NEED TO ADJUST size_z_read_from AND inds_z_read_from \n" + ...
        "TO MAKE THEM AS THEY APPEAR IN load_stack.m"))
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
size_read_to = [length(inds_t_read_from), length(inds_z_read_from) sz(1) sz(2)]; %read the way it was written for speed, permute within read_tif_tzyx


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
plotinds_z_str = plotinds_z_str(1:end-1); %strip final comma

%% load

try
    stack = struct2cell(load(pth_dn_mat));
    stack = stack{1};
catch

    "READING DNEOISED TIF"
    stack = read_tif_tzyx(pth_stack_tif, ...
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

if makeplots

    pth_gif = [pth_fldr 'prefilt_' datestr(now,30) '_.gif'];
    title_str = 'filt';
    plot_gif_fast(rescale(stack(:,:,plotinds_z, plotinds_t), 0, 1), swapdim_plot, pth_gif, title_str)

end


%% filter


stack = fft_filter_1d(stack, stopband);
"DONE FILTERING"


%% plot after filtering

if makeplots

    pth_gif = [pth_fldr 'postfilt_' datestr(now,30) '_.gif'];
    title_str = 'filt';
    plot_gif_fast(rescale(single(stack(:,:,plotinds_z, plotinds_t)), 0, 1), swapdim_plot, pth_gif, title_str)

end


%% save


save(pth_dn_nosn_mat, 'stack', '-v7.3', '-mat')

"FINISHED SAVING"


end

%% function for filtering

function imout = fft_filter_1d(imin, stopband)

%% 

sz = size(imin);
numlines = sz(1);
numxpix = sz(2);
fs = numxpix; %sampling frequency (num x pixels)
fn = fs/2; % Nyquist Frequency
fv = linspace(0, 1, fix(numxpix/2)+1)*fn; % Frequency Vector (One-Sided FFT)
% fpass1 = fv(stopband(1)-1); % Frequency Corresponding To stopband(1)
fstop1 = fv(stopband(1)); % Frequency Corresponding To stopband(1)
fstop2 = fv(stopband(2)); % Frequency Corresponding To stopband(2)
% fpass2 = fv(stopband(2)+1); % Frequency Corresponding To stopband(1)

%% make linear phase fir stopband filter to minimize distortion in reconstructed signal 

filtord = 2^6; %longer is better filtering but bigger startup transient 

filt = designfilt(...
       'bandstopfir', ...     
       'FilterOrder', filtord, ...            
       'CutoffFrequency1', fstop1, ...
       'CutoffFrequency2', fstop2, ...
       'DesignMethod','window', ...        
       'SampleRate', fs ...
       );    %same as fir1(filtord, [fstop1 fstop2]/fn, 'stop'); 

% filt2 = fir1(filtord, [fstop1 fstop2]/fn, 'stop', chebwin(filtord+1,30)); 

% filt3 = designfilt(...
%        'bandstopfir', ...     
%        'FilterOrder', filtord, ...            
%        'PassbandFrequency1', fpass1, ...    
%        'StopbandFrequency1', fstop1, ...
%        'StopbandFrequency2', fstop2, ...
%        'PassbandFrequency2', fpass2, ...
%        'DesignMethod','ls', ...        
%        'PassbandWeight1', 1, ...        
%        'StopbandWeight', 1, ...
%        'PassbandWeight2', 1, ...
%        'SampleRate', fs ...
%        );   


% fvtool(filt); %show filter freq and phase 
% fvtool(filt2);
% fvtool(filt3);


%% 

imin = reshape(imin, numlines, numxpix, []);
imin = permute(imin, [2 3 1]);

imout = zeros(size(imin), 'int16');

for indi = 1:numlines %do small loop so that the conversion to double is not too large in ram (output saved as int16, then converted to uint16 after subtracting min)

    data = double(imin(:, :, indi));
    mnd = mean(data);
    data = data - mnd;
    tmpout = filtfilt(filt, data); %zero-phase filtering
    % tmpout = fftfilt(filt, data); %not zero phase
    imout(:,:, indi) = tmpout + mnd;

end

minall = min(imout(:));
maxall = max(imout(:));
imout = imout - minall; %subtract min before converting to uint16
if maxall > 2^16-1
    error("ERROR, CLIPPING REQUIRED, CHANGE OUTPUT TYPE")
end
imout = uint16(imout);

imout = permute(imout, [3 1 2]);
imout = reshape(imout, sz); %put back in 4d

end

