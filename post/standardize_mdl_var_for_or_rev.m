function standmdlvar = standardize_mdl_var_for_or_rev(means, stds)

standmdlvar = @standardize_mdl_var_direction;

    function mdlvar = standardize_mdl_var_direction(mdlvar, direction)

        if strcmp(direction, 'forward')
            mdlvar = (mdlvar - means) ./ stds; %standardize (mean zero, variance one)
        elseif strcmp(direction, 'reverse')
            mdlvar = mdlvar.*stds + means; %reverse standardize
        else
            error("standardization direction input must be 'forward' or 'reverse'")
        end

    end

end

