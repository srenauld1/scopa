function [err_cum, err_std] = bumpcmp_error(offset)

error("function needs to be updated")

% err_cum = unwrap(offset, [], 2);
% err_cum = diff(err_cum, [], 2);
% err_cum = abs(err_cum);
% err_cum = cumsum(err_cum, 2);
% err_cum = err_cum(:,end);
err_cum = nan;

err_std = std(offset, 1, 2, 'omitmissing'); %2nd arg is 1 to normalize by n, not n-1
