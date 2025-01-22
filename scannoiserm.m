
function scannoiserm(pthstack, stopband, smlensec, zerostack, it, iz, doplt, frameinds)

arguments
    pthstack %pthstack is full path to tif or mat (if mat is in same folder with tif, it will be loaded without reading the tif)
    stopband = [10,20]; %stopband frequency indices; set emperically for now; keep between 2 and half number of pixels in x dimension . . . hopefully scan noise bandwidth scales simply with imaging temporal frequency
    smlensec = 0 %temporal gaussian smooth window in seconds; makes scan noise more bandlimited
    zerostack = 1 %subtract min to make min zero
    it = 50.3 %frames to plot (empty for all); 50.3 means 3 equidistant 50-frame segments 
    iz = [] %z slices to plot (empty for all)
    doplt = 0;
    frameinds = [] %subset of frames to test filtering faster (since it it purely spatial filtering, and frameinds indexing applied after any temporal smoothing is applied); although filtering all frames should not take very long (1-10 minutes at the most)
end


fprintf("\n\n\nENTERING scannoiserm.m" + newline)
fprintf("PROCESSING: " + pthstack + newline)


if iscell(stopband)
    stopband = cell2mat(stopband);
end
if iscell(smlensec)
    smlensec = cell2mat(smlensec);
end

id = idmake(pthstack); %also ran this in a2p earlier, but it's fast and let's us not pass this input if we don't have to

pthstack_nosn = [pthstack(1:end-4) 'nosn_.mat'];

sbstr = [num2str(stopband(1)) 'to' num2str(stopband(2)) 'stopband_'];

if smlensec
    smstr = [strrep(num2str(smlensec), '.', 'p') 'smsec'];
else
    smstr = 'nosmooth';
end

figtitle_prefix = [id.recid '_' id.suffix '_' sbstr '_' smstr];
filename_prefix = [id.dirstack figtitle_prefix];

timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS')) ;

pthgif_prefilt = [filename_prefix '_prefilt_' timestr '_.gif'];
pthgif_postfilt = [filename_prefix '_postfilt_' timestr '_.gif'];

%% load

o.spr.smlensec = smlensec; 
o.spr.zerostack = zerostack; 
o = odf(o, 'spr');

stack = stackpr(pthstack, o.spr);


%% index into frameinds, if nonempty


if isempty(frameinds)
    frameinds = 1:size(stack,4);
else
    frameinds(frameinds>size(stack,4)) = [];
    stack=stack(:,:,:,frameinds);
end

if isequal(frameinds, 1:size(stack,4))
    dosave = 1;
    fprintf("REMOVING SCAN NOISE FOR ALL " + numel(frameinds) + " FRAMES; WILL SAVE OUTPUT STACK" + newline)
else
    dosave = 0;
    fprintf("REMOVING SCAN NOISE FOR " + numel(frameinds) + " FRAMES, FROM " + frameinds(1) + " TO " + frameinds(end) + "; WILL NOT SAVE OUTPUT STACK BECAUSE NOT OPERATING ON ALL FRAMES" + newline)
end

%% plot before filtering

if doplt
    stackplt(stack, it=it, iz=iz, pthgif=pthgif_prefilt);
end


%% filter

for k = 1:size(stack,5)
    stack(:,:,:,:,k) = fft_filter_1d(stack(:,:,:,:,k), stopband, zerostack);
    fprintf("DONE FILTERING CHANNEL INDEX " + num2str(k) + newline)
end


%% plot after filtering

if doplt
    stackplt(stack, it=it, iz=iz, pthgif=pthgif_postfilt);
end

%% save

if dosave
    save(pthstack_nosn, 'stack', '-v7.3', '-mat')
    fprintf("FINISHED SAVING" + newline)
else
    fprintf("NOT SAVING FILTERED STACK BECAUSE ONLY A SUBSET OF FRAMES WERE OPERATED ON (BECAUSE OF ARGUMENT frameinds)" + newline)
end


end


function stackout = fft_filter_1d(stack, stopband, zerostack)

%%stopband filter each line (cannot recover precise line flyback times, so cannot 1d  filter entire stack as vector)

typeout = 'uint16'; %forcing this for now;
if ~isa(stack, typeout)
    error("STACK MUST BE UINT16")
end
if ndims(stack)~=4
    error("stack is not 4d; currently must be 4d (yxzt) for scannoiserm")
end

fprintf("STACK SIZE IS: " + mat2str(size(stack)) + newline);

sz = size(stack);
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


filtord = pow2(floor(log2(numxpix/3))); %for these fir filters, higher order means longer in time domain, means better filtering but longer startup transient

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

stack = reshape(stack, numlines, numxpix, []);
stack = permute(stack, [2 3 1]);

stackout = zeros(size(stack), 'int16');
tic
% parfor_progress(numlines);
for k = 1:numlines %do small loop so that the conversion to double is not too large in ram (output saved as int16, then converted to uint16 after subtracting min)

    data = double(stack(:, :, k));
    mnd = mean(data);
    data = data - mnd;
    tmpout = filtfilt(filt, data); %zero-phase filtering for a single y, all zt, along x dimension (here, x is first dimension); note similar function fftfilt(filt, data) is not zero-phase 
    stackout(:,:, k) = tmpout + mnd;

    % parfor_progress;

end
% parfor_progress(0);
toc

if zerostack
    stackout = stackout - min(stackout, [], 'all', 'omitmissing'); %subtract min
end

stackout = stacktype(stackout, typeout); %convert from int16 to uint16

stackout = permute(stackout, [3 1 2]);
stackout = reshape(stackout, sz); %put back in 4d

end

