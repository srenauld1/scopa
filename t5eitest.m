ful = [-1 1];
permtmp = combinator(2,11,'p','r');
permtmp = ful(permtmp);

gofsave = Inf;
for kjk = 1:size(permtmp,1)

    permtmp2 = permtmp(kjk,:);
    permtmp2 = repmat(permtmp2, [25 1]);
    permtmp2 = permtmp2(:)';
    indv = indv.*permtmp2;

    for ri = 1:num_dim_depvp %(ri=1:num_dim_depvp, optpp) %ri = 1:num_dim_depvp
        if depv_good_inds(ri)
            depv = double(depv_all(:, ri));
            depv_val = double(depv_all_val(:, ri));

            [ ft(ri,:), pred(:,ri), gof(ri), gof_val(ri) ] = ...
                mdl_fit(indv, depv, ri, histinc, ...
                mdlname, valnum, indv_val, depv_val, sampinds_indvdepv_train, ...
                sampinds_indvdepv_val, num_samp_total, supp, op, ...
                depvmin(ri), depvmax(ri), pthvalsv);

            mdlplt(op.mdl, supp, depv_all(:,ri), pred(:,ri), ft(ri,:), indv, opt.nrmd)
        end
    end

    if partest
        tocBytes(gcp)
        toc
    end

    if gof(ri)<gofsave
        gofsave = gof(ri);
        kjk_save = kjk;
    end
end