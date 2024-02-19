function [resp_out, params_out, params_out_bad, idx_full] = cx_index_into_extraction_and_normalization(params_all, resp_in, exman, normman)

exparams_all = unique(params_all(:,1), 'stable');

countz = 0;
countz2 = 0;
params_out_bad = {};
for emi = 1:length(exman)

    exind_subset = find(~cellfun(@isempty, regexp(exparams_all, regexptranslate('wildcard', exman{emi}))));

    for emi2 = 1:length(exind_subset)

        ex_ind_out = exind_subset(emi2);
        exparams_out = exparams_all{ex_ind_out};
        normparams_given_ex = params_all(contains(params_all(:,1), exparams_out), 3);

        for nmi = 1:length(normman)

            normind_subset = find(~cellfun(@isempty, regexp(normparams_given_ex, regexptranslate('wildcard', normman{nmi}))));

            for nmi2 = 1:length(normind_subset)

                norm_ind_out = normind_subset(nmi2);
                norm_params_out = normparams_given_ex{norm_ind_out};

                resptmp = resp_in{ex_ind_out}.(norm_params_out);
                otherdims = repmat({':'},1,ndims(resptmp)-1);

                if ~isempty(resptmp)
                    countz = countz+1;
                    params_out{countz, 1} = exparams_out;
                    params_out{countz, 2} = ex_ind_out;
                    params_out{countz, 3} = norm_params_out;
                    params_out{countz, 4} = norm_ind_out;
                    resp_out(countz, :, :) = resptmp;
                    idx_full(countz) = find(contains(params_all(:,1), exparams_out) & contains(params_all(:,3), norm_params_out));

                else
                    countz2 = countz2+1;
                    params_out_bad{countz2, 1} = exparams_out;
                    params_out_bad{countz2, 2} = ex_ind_out;
                    params_out_bad{countz2, 3} = norm_params_out;
                    params_out_bad{countz2, 4} = norm_ind_out;
                end

                %offset_indedx = find(contains(params_all_gar(:,1), norm_manual{nmi}) & contains(params_all_gar(:,3), caiman_manual{cmi})):
            end
        end
    end
end