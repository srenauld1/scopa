function var = mdl_nrmvar(var, direction, normtype, means, stds, mins, maxes)


if strcmp(direction, 'forward')
    if strcmp(normtype, 'zscore')
        var = (var - means) ./ stds; %standardize (mean zero, variance one)
    elseif strcmp(normtype, 'minmax')
        var = (var - mins) ./ (maxes - mins); %standardize (mean zero, variance one)
    elseif strcmp(normtype, 'minmaxcnt')
        var = 2*(var - mins) ./ (maxes - mins) - 1; %standardize (mean zero, variance one)
    end
elseif strcmp(direction, 'reverse')
    if strcmp(normtype, 'zscore')
        var = var.*stds + means; %reverse standardize
    elseif strcmp(normtype, 'minmax')
        var = var.*(maxes-mins)/2 + mins;
    elseif strcmp(normtype, 'minmaxcnt')
        var = (var+1).*(maxes-mins)/2 + mins;
    end
else
    error("normalization direction input must be 'forward' or 'reverse'")
end

end
