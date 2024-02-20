function [err_cum, err_std] = compute_bump_error(offset)

% err_cum = unwrap(offset, [], 2);
% err_cum = diff(err_cum, [], 2);
% err_cum = abs(err_cum);
% err_cum = cumsum(err_cum, 2);
% err_cum = err_cum(:,end);
err_cum = nan;

err_std = std(offset, 0, 2, 'omitnan');
