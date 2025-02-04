function y = tsrspad(x, fs_new, fs_old)

if size(x,1) < size(x, 2)
    x = x';
end

default_antialiasing_filter_order_scalefac = 10; %this is matlab default
default_antialiasing_filter_order = 2*default_antialiasing_filter_order_scalefac*max(fs_old,fs_new);
default_antialiasing_filter_length = default_antialiasing_filter_order+1;
padlength = default_antialiasing_filter_length+1;

padfront = repmat(x(1), padlength, 1);
padback = repmat(x(end), padlength, 1);
xpad = cat(1, padfront, x, padback); % extend by 2s on each side
ypad = resample(xpad, fs_new, fs_old);
padfrontnew = floor(padlength/fs_old*fs_new+1);
padbacknew = floor(padlength/fs_old*fs_new);
y = ypad(padfrontnew : length(ypad)-padbacknew);

