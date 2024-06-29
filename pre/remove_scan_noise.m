
function remove_scan_noise(pth_stack_tif, len_window_smooth_t_rsc)

% len_window_smooth_t_rsc = 0;
pth_stack_tif
disp(pth_stack_tif)
len_window_smooth_t_rsc
disp(len_window_smooth_t_rsc)
sprintf("\n\n\nENTERING remove_scan_noise")
fprintf("\n\n\nENTERING remove_scan_noise")

%pth_stack_tif is full path to tif or mat (if mat is in same folder with
%tif, it will be loaded without reading the tif)

makeplots = 1;
stopband = [10 20]; %set emperically for now, stopband frequency indices keep between 2 and half x length . . . hopefully scan noise is fairly constant across recordings

plotinds.t = 50.4; %t indices to plot, blank for all, negative for that number equidistant from all available
plotinds.z = []; %z indices to plot, blank for all, negative for that number equidistant from all available

zero_stack = 1; %subtract min to make min zero 

cmap = gray(256); %for plotting, if makeplots
framenumdims = 3;%for plotting, if makeplots
dimorder = [1,2,3,4];%for plotting, if makeplots
figsidelen = 0.75;%for plotting, if makeplots


display(['processing : ' pth_stack_tif] )

[pth_fldr, filnam, ~] = fileparts(pth_stack_tif);

if ~isempty(regexp(filnam, regexptranslate('wildcard', '_raw'))) || ~isempty(regexp(filnam, regexptranslate('wildcard', '_trial')))
    error(sprintf("ERROR, \nTHIS FUNCTION IS NOT WRITTEN FOR STACKS WITH FLYBACK " + ...
        "('raw' or 'trial' in filename), \n" + ...
        "IF YOU WANT TO PASS THOSE STACKS TO THIS FUNCTION, \n" + ...
        "YOU NEED TO ADJUST size_z_read_from AND inds_z_read_from \n" + ...
        "TO MAKE THEM AS THEY APPEAR IN load_stack.m"))
end

pth_fldr = [pth_fldr filesep];
spl = strjoin(strsplit(filnam, '-'), '_'); %if there's a hyphen, separate and then join all with underscore
spl = strsplit(spl, '_'); %then separate by underscore

datenum = str2double(spl{1});
flynum = str2double(spl{2});
trialnum = str2double(spl{3});
suffix_analysis = strjoin(spl(4:end));

recid = [num2str(datenum) '_' num2str(flynum) '_' num2str(trialnum)];

pth_dn_mat = [pth_stack_tif(1:end-4) '.mat']; %in case pth_stack_tif is a tif, also look for mat (and if it's mat, this does nothing
pth_dn_nosn_mat = [pth_dn_mat(1:end-4) 'nosn_.mat'];
pth_metadata = [pth_fldr recid '_metadatanew_.mat'];

md = struct2cell(load(pth_metadata)); %file created in initial 'pre' pipeline
md = md{1};
sz = single([md.ypix md.xpix md.numslice md.numvol]);

crop_flyback = 0;
numslice_withflyback = []; %hack, this function currently only takes processed stacks with flyback already removedd
keepinds_t = 1:sz(4);


label_prefix = 't';
[plotinds.t, plotinds.t_str] = make_plot_inds(keepinds_t, plotinds.t, label_prefix, max_num_inds_to_print);

label_prefix = 'z';
[plotinds.z, plotinds.z_str] = make_plot_inds(sz(3), plotinds.z, label_prefix, max_num_inds_to_print);

if isequal(display_range, [0 1])
    dr_str = 'DRfull';
else
    dr_str = ['DR' num2str(display_range(1)) 'to' num2str(display_range(2))];
end

figtitle_prefix = [recid '_' suffix_analysis '_' dr_str];
filename_prefix = [pth_fldr figtitle_prefix '_' plotinds.z_str '_' plotinds.t_str ];

timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS')) ;

fn_gif_prefilt = [filename_prefix 'prefilt_' timestr '_.gif'];
fn_gif_postfilt = [filename_prefix 'postfilt_' timestr '_.gif'];

%% load

try
    stack = struct2cell(load(pth_dn_mat));
    stack = stack{1};
catch
    stack = tif2mat(pth_stack_tif, numslice_withflyback, sz, crop_flyback, zero_stack, keepinds_t);
end


%% smooth


if len_window_smooth_t_rsc
    stack = smoothdata(stack, 4, 'gaussian', len_window_smooth_t_rsc);
end
"DONE SMOOTHING"



%% plot before filtering



if makeplots
    
    index_labels = arrayfun(@(x) 1:x(end), size(stack), 'UniformOutput', false);
    index_labels{3} = plotinds.z;
    index_labels{4} = plotinds.t;

    stack2fig(stack(:,:,plotinds.z, plotinds.t), fn_gif_prefilt, cmap, display_range, framenumdims, dimorder, figtitle_prefix, index_labels, figsidelen)

end


%% filter


stack = fft_filter_1d(stack, stopband);
"DONE FILTERING"


%% plot after filtering

if makeplots

    stack2fig(stack(:,:,plotinds.z, plotinds.t), fn_gif_postfilt, cmap, display_range, framenumdims, dimorder, figtitle_prefix, index_labels, figsidelen)

end


%% save


save(pth_dn_nosn_mat, 'stack', '-v7.3', '-mat')

"FINISHED SAVING"


end

%% function for filtering

function imout = fft_filter_1d(imin, stopband)

%%stopband filter each line (cannot recover precise line flyback times, so cannot 1d  filter entire stack as vector)

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

filtord = 2^6; %for these fir filters, higher order means longer in time domain, means better filtering but longer startup transient

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

parfor indi = 1:numlines %do small loop so that the conversion to double is not too large in ram (output saved as int16, then converted to uint16 after subtracting min)

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

