
function resp = extract_roi_responses(respin, mask_roi_vec, ...
    pth_save_prefix, normopts, dtmni, resp)


%if resp is passed as input, this function's output resp is appended to it
if ~exist('resp', 'var')
    resp = [];
end

if isequal(unique(mask_roi_vec), [0 1]) | isequal(unique(mask_roi_vec), [0 1]') | unique(mask_roi_vec)==1
    weightingstr = 'no';
elseif unique(mask_roi_vec)==0
    error("no pixel indices for any rois present")
else
    weightingstr = 'yes';
end

if ~isstruct(respin) %if input is plain raw image f
    raw_image_input = 1;
    respintmp.rawf = reshape(respin, [], size(respin, ndims(respin))); %reshape
    respin = respintmp;
    clear respintmp
else
    raw_image_input = 0;
end

fnin = fieldnames(respin);
countz = 0;

for fnini = 1:length(fnin)

    resp1.f = respin.(fnin{fnini}); %assign the no-normalization default

    resp1 = normalize_response(resp1.f, normopts.precluster, dtmni);

    fn1 = fieldnames(resp1);

    for fn1i = 1:length(fn1)

        countz = countz+1;

        im2d = resp1.(fn1{fn1i});

        if ndims(im2d)~=2
            error("should always be 2d (space by time), raw image is reshaped above, and caiman rois are also 2d space by time")
        end

        goodinds = any(im2d, 2) & ~any(isnan(im2d), 2); %so they don't affect the mean, get rid of bad rois here (all zeros or any nans); do before clustering so extraction & normalization param mapping is unaffected, for raw pixels this should do nothing
        if raw_image_input & numel(find(goodinds)) ~= size(im2d, 1)
            error
        end

        im2d = im2d (goodinds, :);
        roiinds_new = mask_roi_vec(:, goodinds);

        if ~isempty(im2d) %some normalizations will be empty (like dff when F0 is too low, divides by zero)
            resp2.f = roiinds_new * im2d ./ sum(roiinds_new,2); %default no normalization, this is the summed fluorescence in each group, normalized by total intensity
        else
            resp2.f = nan;
        end

        resp2 = normalize_response(resp2.f, normopts.postcluster, dtmni);

        fn2 = fieldnames(resp2);

        for fni2 = 1:length(fn2)
            fieldname_tmp = ['in_' fnin{fnini} '_pc_' fn1{fn1i} '_cl_'  fn2{fni2} '_w_' weightingstr];
            resp.(fieldname_tmp) = resp2.(fn2{fni2});
        end

    end
end

%assign the no-normalization/no-clustering fields for functional rois (just plain caiman output)
%(morph rois get clustered at least, since otherwise they're just single pixels)
%note these can have different size than the fields that were clustered
%pc gets f, cl and w get null since there is no clustering for this field 
if ~raw_image_input
    for fnini = 1:length(fnin)
        fieldname_tmp = ['in_' fnin{fnini} '_pc_f_cl_null_w_null'];
        resp.(fieldname_tmp) = respin.(fnin{fnini});
    end
end


if normopts.doplots
    
    numroi = size(cluster_f,1);
    indzy = 1:size(cluster_f,2);
    figure;
    colord = distinguishable_colors(numroi);

    countz = 0;
    for mi = 1 : 1 : size(cluster_f, 1)
        countz = countz+1;
        xinds = [1:length(indzy)]+length(indzy)*(countz-1);
        sp1 = subplot(3,1,1);
        hold(sp1, 'on')
        plot(xinds, cluster_f(mi,indzy), 'color', colord(countz,:));
        title("raw")
        sp2 = subplot(3,1,2);
        hold(sp2, 'on')
        plot(xinds, cluster_dff(mi,indzy), 'color', colord(countz,:));
        title("dff")
        sp3 = subplot(3,1,3);
        hold(sp3, 'on')
        plot(xinds, cluster_955(mi,indzy), 'color', colord(countz,:));
        title("percentile normalized")
        %pause(0.5);
    end

    saveas( gcf, [pth_save_prefix(1:end-4) '_normcompresp_.png'])


    prctcheck = 99;
    pfn = prctile(cluster_f, prctcheck, 2);
    pdfn = prctile(cluster_dff, prctcheck, 2);
    pzfn = prctile(cluster_955, prctcheck, 2);

    figure;
    subplot(3,1,1)
    scatter(1:length(pfn), pfn)
    title("raw")

    subplot(3,1,2)
    scatter(1:length(pdfn), pdfn)
    title("dff")

    subplot(3,1,3)
    scatter(1:length(pzfn), pzfn)
    title("percentile normalized")

    saveas( gcf, [pth_save_prefix(1:end-4) '_normcompprct_.png'])


    if length(pfn)>1

        pfn = rescale(pfn);
        pdfn = rescale(pdfn);
        pzfn = rescale(pzfn);

        figure;
        subplot(3,1,1)
        plot(pfn)
        title(std(pfn))
        subplot(3,1,2)
        plot(pdfn)
        title(std(pdfn))
        subplot(3,1,3)
        plot(pzfn)
        title(std(pzfn))

        saveas( gcf, [pth_save_prefix(1:end-4) '_normcompprctnorm_.png'])

    end


    figure;
    for ci = 1:size(roi_dff, 1)

        subplot(3,1,1)
        hist(vec(roi_box(ci,:)), 100);
        xlim([0 0.5])

        subplot(3,1,2)
        hist(vec(roi_nn(ci,:)-1), 100);
        xlim([0 0.5])

        subplot(3,1,3)
        indiest = 1:200;
        yyaxis left
        plot(roi_box(ci,indiest))
        yyaxis right
        plot(roi_nn(ci,indiest))
        pause(.2)

    end

end

end