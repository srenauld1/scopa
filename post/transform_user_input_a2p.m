function ui = transform_user_input_a2p(ui)

% some params are set in user-input-friendly format and need to be transformed into format that simplifies the downstream code

if ~iscell(ui.mn.pthstacks)
    ui.mn.pthstacks = {ui.mn.pthstacks};
end

for k = 1:numel(ui.mn.regionex_all)

    regionex = ui.mn.regionex_all{k};

    if ~isfield(ui.mroi.auto.num_mroi_auto, regionex)
        num_mroi_auto_tmp.(regionex) = 0;
    else
        num_mroi_auto_tmp.(regionex) =  ui.mroi.auto.num_mroi_auto.(regionex);
    end
    if any(strcmp(ui.mroi.use_drawn_rois, regionex))
        use_drawn_rois_tmp.(regionex) = 1;
    else
        use_drawn_rois_tmp.(regionex) = 0;
    end
    if any(strcmp(ui.mroi.auto.use_hires, regionex))
        use_hires_tmp.(regionex) = 1;
    else
        use_hires_tmp.(regionex) = 0;
    end
    if ~isfield(ui.pf.bump.numcluster_for_bump_domain_resample, regionex)
        numcluster_for_bump_domain_resample_tmp.(regionex) = 0;
    else
        numcluster_for_bump_domain_resample_tmp.(regionex) = ui.pf.bump.numcluster_for_bump_domain_resample.(regionex);    
    end

end

ui.mroi.auto.num_mroi_auto = num_mroi_auto_tmp;
ui.mroi.use_drawn_rois = use_drawn_rois_tmp;
ui.mroi.auto.use_hires = use_hires_tmp;
ui.pf.bump.numcluster_for_bump_domain_resample = numcluster_for_bump_domain_resample_tmp;

end