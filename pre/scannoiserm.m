
function scannoiserm(pthstack, opt)

arguments
    pthstack %pthstack is full path to tif or mat (if mat is in same folder with tif, it will be loaded without reading the tif)
    opt.stopband = [10 20]; %stopband frequency indices; set emperically for now; keep between 2 and half number of pixels in x dimension . . . hopefully scan noise bandwidth scales simply with imaging temporal frequency
    opt.smlensec = 0
    opt.zerostack = 1
    opt.it = 50.3
    opt.iz = []
    opt.testframes = [] %subset of frames to test filtering much faster (since it it purely spatial filtering, and testframes indexing applied after any temporal smoothing is applied)
    opt.doplt = 1;
end
stopband = opt.stopband;
smlensec = opt.smlensec;
zerostack = opt.zerostack;
it = opt.it;
iz = opt.iz;
testframes = opt.testframes;
doplt = opt.doplt;

fprintf("\n\n\nENTERING scannoiserm.m" + newline)
fprintf("PROCESSING: " + pthstack + newline)
opt

id = idmake(pthstack); %also ran this in a2p earlier, but it's fast and let's us not pass this input if we don't have to
recid = id.recid;
dirstack = id.dirstack;
suffix = id.suffix;

pthstack_nosn = [pthstack(1:end-4) 'nosn_.mat'];

md = mdsild([], pthstack=pthstack);

if smlensec
    smlensamp = smlensec * md.volrate; %does not need to be rounded for smoothdata
    smooth_str = [strrep(num2str(smlensec), '.', 'p') 'smsec'];
else
    smooth_str = 'nosmooth';
end

figtitle_prefix = [recid '_' suffix '_' smooth_str];
filename_prefix = [dirstack figtitle_prefix];

timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS')) ;

pthgif_prefilt = [filename_prefix '_prefilt_' timestr '_.gif'];
pthgif_postfilt = [filename_prefix '_postfilt_' timestr '_.gif'];

%% load

stack = stackld(pthstack, sz=md.sz_o, numslice_withflyback=md.numslice_withflyback, channel_save=md.channel_save, imrate=md.volrate, zerostack=zerostack);


%% smooth (optional, can make noise more bandlimited, so easier to filter)


if smlensec
    stack = smoothdata(stack, 4, 'gaussian', smlensamp);
    fprintf("DONE SMOOTHING" + newline)
end

%% index into testframes, if nonempty


if any(testframes)
    stack=stack(:,:,:,testframes);
    fprintf("TESTFRAMES APPLIED" + newline)
end


%% plot before filtering

if doplt
    stackplt(stack, it=it, iz=iz, pthgif=pthgif_prefilt);
end


%% filter

stack = fft_filter_1d(stack, stopband);
fprintf("DONE FILTERING" + newline)


%% plot after filtering

if doplt
    stackplt(stack, it=it, iz=iz, pthgif=pthgif_postfilt);
end

%% save

if any(testframes)
    fprintf("NOT SAVING BECAUSE USER PASSED ARGUMENT TESTFRAMES (A SUBSET OF ALL FRAMES), AND ONLY THOSE FRAMES GOT FILTERED" + newline)
else
    save(pthstack_nosn, 'stack', '-v7.3', '-mat')
    fprintf("FINISHED SAVING" + newline)
end


end

%% function for filtering

function stackout = fft_filter_1d(stack, stopband)

%%stopband filter each line (cannot recover precise line flyback times, so cannot 1d  filter entire stack as vector)
disp(size(stack));

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

parfor indi = 1:numlines %do small loop so that the conversion to double is not too large in ram (output saved as int16, then converted to uint16 after subtracting min)

    data = double(stack(:, :, indi));
    mnd = mean(data);
    data = data - mnd;
    tmpout = filtfilt(filt, data); %zero-phase filtering
    % tmpout = fftfilt(filt, data); %not zero phase
    stackout(:,:, indi) = tmpout + mnd;

end

minall = min(stackout(:));
maxall = max(stackout(:));
stackout = stackout - minall; %subtract min before converting to uint16
if maxall > 2^16-1
    error("ERROR, CLIPPING REQUIRED, CHANGE OUTPUT TYPE")
end
stackout = uint16(stackout);

stackout = permute(stackout, [3 1 2]);
stackout = reshape(stackout, sz); %put back in 4d

end

