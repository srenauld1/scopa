function standmdlvar = mdl_nrmvar(normtype, means, stds, mins, maxes)

standmdlvar = @standardize_mdl_var_direction; 

    function mdlvar = standardize_mdl_var_direction(mdlvar, direction)

        if strcmp(direction, 'forward')
            if strcmp(normtype, 'zscore')
                mdlvar = (mdlvar - means) ./ stds; %standardize (mean zero, variance one)
            elseif strcmp(normtype, 'minmax')
                mdlvar = (mdlvar - mins) ./ (maxes - mins); %standardize (mean zero, variance one)
            elseif strcmp(normtype, 'minmaxcnt')
                mdlvar = 2*(mdlvar - mins) ./ (maxes - mins) - 1; %standardize (mean zero, variance one)
            end
        elseif strcmp(direction, 'reverse')
            if strcmp(normtype, 'zscore')
                mdlvar = mdlvar.*stds + means; %reverse standardize
            elseif strcmp(normtype, 'minmax')
                mdlvar = mdlvar.*(maxes-mins)/2 + mins;
            elseif strcmp(normtype, 'minmaxcnt')
                mdlvar = (mdlvar+1).*(maxes-mins)/2 + mins;
            end
        else
            error("normalization direction input must be 'forward' or 'reverse'")
        end

    end

end

