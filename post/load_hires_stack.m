function [stack_hires_mnt, map_hires_lores] = load_hires_stack(pth_hires_prefix, pth_hires_mat_matreg, ...
    stack, md, use_caiman_on_hires, pth_roi_func_hires)


%% if using a high-z-res stack also, map low resolution z indices to to high resolution z indices

pth_hires_tif = [pth_hires_prefix '.tif'];

pixdist_z_lr = md.zwid;
pos_lr_cntrs = compute_z_centers(pixdist_z_lr, md.numslice );
pixdist_z_hr = md.md_hires.zwid;
pos_hr_cntrs = compute_z_centers(pixdist_z_hr, md.md_hires.sz_o(3) );

map_hires_lores = [];
for phri = 1:length(pos_hr_cntrs)
    mapindy = find(pos_hr_cntrs(phri)>pos_lr_cntrs-pixdist_z_lr/2 & pos_hr_cntrs(phri)<pos_lr_cntrs+pixdist_z_lr/2);
    if ~isempty(mapindy)
        map_hires_lores(phri) = mapindy;
    else
        map_hires_lores(phri) = nan; %for any hires slices out of lores range
    end
end

lores_z_out_of_bounds = find(pos_lr_cntrs+pixdist_z_lr/2>max(pos_hr_cntrs)+pixdist_z_hr/2); %lores slice indices whose end is beyond the last hires z end (but we only care about this for registering hires, not for using registered hires)
hires_z_out_of_bounds = find(map_hires_lores==lores_z_out_of_bounds); %remove all hires for the lores out of bounds to not have any partial correspondance slices
map_hires_lores(hires_z_out_of_bounds) = [];


%% try to load registered hires stack, or if it doesn't exist, register it to the lores stack (hires is registered to lores in matlab, not python)


try

    stack_hires_mnt = struct2cell(load(pth_hires_mat_matreg)); %load registered stack
    stack_hires_mnt = stack_hires_mnt{1};

catch

    try

        lores_z_for_hires_map = setxor(lores_z_out_of_bounds, 1:size(stack, 3)); %crop here so the hires registration is correct
        meanvol_lores = rescale(mean(stack(:,:,lores_z_for_hires_map,:),4)); %rescale makes it a double, good for hires registration

        doplots = 0;
        stack_hires_mnt = register_3d_hires_to_3d_lores(pth_hires_tif, ...
            pth_hires_mat_matreg, meanvol_lores, map_hires_lores, hires_z_out_of_bounds, doplots);

    catch

        "THERE IS NO HIRES STACK (OR THERE'S AN ERROR)"

    end

end

if ndims(stack_hires_mnt)~=3
    error(sprintf("ERROR, \nTHIS PIPELINE REQUIRES stack_hires_mnt TO BE 3D"))
end


%% load caiman rois extracted from hires (work in progress, low priority because it's likely uncommon use case)

if use_caiman_on_hires % load caiman rois extracted from hires if they exist

    error(sprintf("ERROR \n" + ...
        "IF YOU WANT TO USE CAIMAN ROI EXTRACTION ON THIS HIRES REGISTERED TIF, \n" + ...
        "YOU COULD INSERT A CALL TO pipeline_init.py HERE \n" + ...
        "BUT YOU HAVE TO ADAPT THE PYTHON CODE TO OPERATE ON FILES WITH STRING hires \n" + ...
        "AND YOU HAVE TO ADAPT register_3d_hires_to_lores TO OUTPUT THE REGISTERED FULL 4D HIRES, \n" + ...
        "RATHER THAN THE CURRENT OUTPUT, WHICH IS REGISTERED TEMPORAL AVERAGE stack_hires_mnt \n" + ...
        "CURRENTLY HIRES IS JUST USED FOR ANATOMY, SO TEMPORAL AVERAGE IS FINE, \n" + ...
        "THE CODE ISN'T WRITTEN FOR HIRES FUNCTIONAL ROI EXTRACTION \n" + ...
        "YOU CAN USE update_tif BELOW TO WRITE THIS 4D ARRAY TO TIF TO USE IN CAIMAN, \n" + ...
        "ALL OF THESE REQUIRED CHANGES WOULD BE SMALL, AND IS ON THE TODO LIST"))

    fntmp = rdir(pth_roi_func_hires);
    if ~isempty(fntmp)
        pth_roi_func_hires = fntmp.name;
        roimask_hires = struct2cell(load(pth_roi_func_hires));
        roimask_hires = roimask_hires{1};
        % roimasks_hires_all = sum(roimask_hires, 4);
        % roimasks_hires_all(roimasks_hires_all~=0) = 1;
        % stack_hires_mnt = stack_hires_mnt.*roimasks_hires_all;
    else
        disp("WRITING HI RES REGISTERED TIF FOR CAIMAN TO USE IN PYTHON")
        pth_hires_tif_matreg = [pth_hires_mat_matreg(1:end-4) '.tif'];
        stack_hires_reg = INSERT_SOME_FUNCTION_TO_REGISTER_THE_FULL_4D_VERSION;
        update_tif(stack_hires_reg, pth_hires_tif, pth_hires_tif_matreg)
        error("ERROR, HIRES CAIMAN ROI FILE DOESN'T EXIST, NEED TO RUN PYTHON EXTRACTION ON HI RES REGISTERED TIF")
    end
end

