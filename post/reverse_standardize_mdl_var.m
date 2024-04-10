function revstandvar = reverse_standardize_mdl_var(stds, means)

revstandvar = @reverse_standardize_mdl_var_sub;

    function mdlvar = reverse_standardize_mdl_var_sub(mdlvar)

        mdlvar = mdlvar.*stds + means; %rescale to original

    end

end

