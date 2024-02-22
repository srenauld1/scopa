
function [resp, alpha] = map_rois_to_head_direction(stack, resp, visang, ...
    pixinds_roi, mapind2ind, stimepochinds_i, dt_i_mean, fitopt, ...
    halfcent, fn_prefix, numcluster_for_bump_domain_resample, doplots)

%resp = nonlinearly_transform_response(resp)

stimfit = visang;
fitopt.hsv_background = 'rois';
fitopt.modeltype = 'vonmises';
fitopt.sort_method = 'unbiased';
fitopt.epochinds = {[4]};
fitopt.length_model_seconds = 0;
fitopt.doplots = 1;

[~, ~, cueang_pref] = fitresp(stack, stimfit, resp, ...
    pixinds_roi, mapind2ind, stimepochinds_i, ...
    dt_i_mean, fn_prefix, fitopt);

cueang_pref = cueang_pref{1}(:)';


%% resample functional alpha

if numcluster_for_bump_domain_resample

    ["resampling original numrois " num2str(size(resp, 1))]

    resample_smoothfac = 1;

    % if size(resp,1)<numroi_func*2
    %     "TOO FEW ROIS FOR RESAMPLING COMPASS"
    %     error
    % end

    %%%should change this to sampling 4*pi rather than right/left
    rois_left = 1:size(resp, 1)/2;
    rois_right = size(resp, 1)/2+1:size(resp, 1);

    [dfc_left, alpha_left] = resample_compass(resp(rois_left,:), cueang_pref(rois_left), halfcent, resample_smoothfac, doplots);
    [dfc_right, alpha_right] = resample_compass(resp(rois_right,:), cueang_pref(rois_right), halfcent, resample_smoothfac, doplots);

    resp = cat(1, dfc_left, dfc_right);
    alpha = [alpha_left alpha_right];

else

    alpha = cueang_pref;

end


if doplots

    figure;
    subplot(3,1,1)
    plot(cueang_pref)
    ylim([-4 4])
    subplot(3,1,2)
    plot(mod(cueang_pref, 2*pi))
    ylim([0 8])
    subplot(3,1,3)
    uwtmp = unwrap(mod(cueang_pref, 2*pi));
    uwtmp = uwtmp - uwtmp(1);
    plot(uwtmp)
    ylim([0 16])
    saveas( gcf, [fn_prefix '_PREFHD_.png'])

end


