function inp = insert_nan_for_polar_wrap(inp, spacing, dim, diffthresh)

%replace diffs (across 'spacing' samples) greater than diffthresh with nan in timeseries (to make plot easier to read)

arguments 
    inp
    spacing = 1
    dim = 1
    diffthresh = pi;
end

if ~isvector(inp)
    if isempty(dim)
        error("must specify dim is inp is not vector")
    end
end

filt = [zeros(1,spacing-1), 1, zeros(1,spacing-1), -1]; %find diffs across larger num samples since sometimes it takes more than 2 samples to go from max to min (-pi to pi)
for j = 1:size(inp, dim)

    C = repmat({':'},1,ndims(inp));
    C{dim} = j; 
    tmp = inp(C{:});

    dfsg = conv(tmp, filt, 'full');
    dfsg = dfsg((length(filt) - 1)+1:end-(length(filt) - (1 + (spacing-1))));
    if dim==1
        dfsg2 = cat(2, zeros(1, (spacing-1)+1), dfsg);
    elseif dim==2
        dfsg2 = cat(1, zeros(1, (spacing-1)+1, 1), dfsg);
    end

    excludeinds = abs(dfsg2)>diffthresh;
    tmp(excludeinds) = nan;
    inp(C{:}) = tmp;


end

end