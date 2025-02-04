function [actual_lags_xy_sec, actual_lags_z_sec, lagsall_xy, lagsall_z, zero_lag_index, numlags] = pltexp_compute_lags(ti, lagsxy_sec, lagsz_sec, lag_style)

[lagsxy, actual_lags_xy_sec] = compute_lags_onedim(ti, lagsxy_sec);
[lagsz, actual_lags_z_sec] = compute_lags_onedim(ti, lagsz_sec);

switch lag_style
    case 'each'
        lgn = 0;
        for zitmp = lagsz
            for xyitmp = lagsxy
                lgn = lgn + 1;
                lagsall_xy(lgn) = xyitmp;
                lagsall_z(lgn) = zitmp;
            end
        end
    case 'any'
        error("lag_style 'any' not yet available")
end

zero_lag_index = find(lagsall_xy==0 & lagsall_z==0);
numlags = numel(lagsall_xy);

end



function [lags_samp, actual_lags_sec] = compute_lags_onedim(ti, lags_sec)


ticumdiff = ti - ti(1);
if isequal(lags_sec, 0)
    lags_samp = 0;
    actual_lags_sec = 0;
else
    ticumdiff = ticumdiff(:); %make sure it's a column vector
    lags_sec = lags_sec(:)';  %make sure it's a row vector
    lags_sec_neg = abs(lags_sec(lags_sec<0));
    [~, lags_samp_neg] = min(abs(ticumdiff-lags_sec_neg));
    lags_sec_pos = lags_sec(lags_sec>=0);
    [~, lags_samp_pos] = min(abs(ticumdiff-lags_sec_pos));
    if isempty(lags_samp_neg)
        lags_samp = lags_samp_pos;
    elseif isempty(lags_samp_pos)
        lags_samp = lags_samp_neg;
    else
        lags_samp = [-lags_samp_neg, 0, lags_samp_pos];
    end
    lags_samp = unique(lags_samp);
    actual_lags_sec = [vec(-ticumdiff(abs(lags_samp(lags_samp<0))+1)); vec(ticumdiff(lags_samp(lags_samp>=0)+1))];
    actual_lags_sec = unique(actual_lags_sec);
end

end
