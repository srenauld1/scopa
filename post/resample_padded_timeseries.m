function y = resample_padded_timeseries(x, fs_new, fs_old, padlensec)

if size(x,1) < size(x, 2)
    x = x';
end

xpad = cat(1, repmat(x(1), fs_old*padlensec, 1), x, repmat(x(end), fs_old*padlensec, 1)); % extend by 2s on each side
ypad = resample(xpad, fs_new, fs_old);
% tpad = [0:(length(ypad)-1)]*(1/fs_new) - padlensec;  % new time vector, shifted by 2s
% t = tpad(fs_new*padlensec+1: length(tpad)-fs_new*padlensec);
y = ypad(fs_new*padlensec+1: length(ypad)-fs_new*padlensec);
