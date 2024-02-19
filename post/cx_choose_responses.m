
function resptmp = cx_choose_responses(resp, regionex, extraction_params, norm_params, extraction_method_supplemental, rescale_resp)

%for the extraction and norm params indexed at present outsiode this
%function for the present regionex, and for all other regionex it grabs the
%first extraction param and first available norm param from the order below
%and option to rescale everything
also averages left and right galll

rea = fieldnames(resp);
for reai = 1:length(rea)
    if strcmp(rea{reai}, regionex) %if it's the target region of bump quantification
        resptmp.(rea{reai}) = resp.(rea{reai}).(extraction_params).(norm_params);
    else %otherwise grab whatever is available in the other regions as sdupplemental data
        epa = fieldnames(resp.(rea{reai}));
        for epai = 1:length(epa)
            switch extraction_method_supplemental
                case 'functional'
                    try %try since the supplemental regions don't necessarily have the same EXTRACTION params as the target region
                        try %also have to try various NORMALIZATION params too, since weighting options can vary
                            normchoose = 'in_cmc_pc_f_cl_f_w_yes'; %in_cmc* only exists in functional extraction, try weighted first
                            resptmp.(rea{reai}) = resp.(rea{reai}).(epa{epai}).(normchoose);
                            break %if match found, break out of loop over extraction params epa
                        catch
                            try
                                normchoose = 'in_cmc_pc_f_cl_f_w_no'; %in_cmc* only exists in functional extraction, try nonweighted (one roi) next
                                resptmp.(rea{reai}) = resp.(rea{reai}).(epa{epai}).(normchoose);
                                break %if match found, break out of loop over extraction params epa
                            catch
                                try
                                    normchoose = 'in_cmc_pc_f_cl_f_w_null';%in_cmc* only exists in functional extraction, try f (no data) last
                                    resptmp.(rea{reai}) = resp.(rea{reai}).(epa{epai}).(normchoose); 
                                    if isnan(resptmp.(rea{reai})) %doing the same thing within if and elseif clause because if isnan | isempty for empty returns empty
                                        resptmp.(rea{reai}) = transpose(vec(nan(size(visang)))); %turn nan into a row vector matching response size (to prevent plotting error)
                                    elseif isempty(resptmp.(rea{reai}))
                                        resptmp.(rea{reai}) = transpose(vec(nan(size(visang)))); %turn nan into a row vector matching response size (to prevent plotting error)
                                    end
                                    break %if match found, break out of loop over extraction params epa
                                catch
                                end
                            end
                        end

                    catch
                    end
                case 'morphological'
                    try
                        normchoose = 'in_rawf_pc_f_cl_rsc_w_no';
                        resptmp.(rea{reai}) = resp.(rea{reai}).(epa{epai}).(normchoose); %in_rawf*w_no only exists in morph exrtraction (no weighting bc morph doens't have for single roi regions)
                        break
                    catch
                    end
            end

        end
    end
    if rescale_resp
        for di = 1:size(resptmp.(rea{reai}), 1)
            resptmp.(rea{reai})(di,:) = rescale(resptmp.(rea{reai})(di,:));
        end
    end
end


resptmp.resp_ga_mean = rescale(mean([resptmp.gal; resptmp.gar], 1)); %nanmean doesnt make sense here
resptmp.resp_no_mean = rescale(mean([resptmp.nol; resptmp.nor], 1)); %nanmean doesnt make sense here
