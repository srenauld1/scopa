function [depvp, gof_val] = fitmdl_validation(num_rois, ft, indv_val, depvp_train, inds, depv_allrois_val, depv_good_inds, mdl, supp)

depvp = zeros(numel(inds.sampinds_depvpre), numel(depv_good_inds), 'single');
gof_val = zeros(1,numel(depv_good_inds));
for ri = 1:num_rois
    if depv_good_inds(ri)
        depvp(inds.sampinds_indvdepv_val, ri) = mdl(ft(ri,:), indv_val, supp)'; %compute validation depvp
        gof_val(ri) = mse(double(depv_allrois_val(:,ri)), depvp(inds.sampinds_indvdepv_val, ri));
        depvp(inds.sampinds_indvdepv_train, ri) = depvp_train(:,ri); %combine val and train depvp
    end
end