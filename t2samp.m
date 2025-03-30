function samp = t2samp(t, tin)

samp = unique(interp1(t, 1:numel(t), tin, 'nearest'), 'stable');
samp = samp(~isnan(samp));

end
