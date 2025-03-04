function [stackmnthr, hrlr] = hiresld(recid, pth, stack, md, opts_hires)


%% if using a high-z-res stack also, map low resolution z indices to to high resolution z indices

pth_hires_tif = [pth.hires_prefix '.tif'];

pixdist_z_lr = md.widyxz(3);
pos_lr_cntrs = slicemid(pixdist_z_lr, md.numslice );
pixdist_z_hr = md.md_hires.widyxz(3);
pos_hr_cntrs = slicemid(pixdist_z_hr, md.md_hires.sz(3) );

hrlr = [];
for phri = 1:length(pos_hr_cntrs)
    mapindy = find(pos_hr_cntrs(phri)>pos_lr_cntrs-pixdist_z_lr/2 & pos_hr_cntrs(phri)<pos_lr_cntrs+pixdist_z_lr/2);
    if ~isempty(mapindy)
        hrlr(phri) = mapindy;
    else
        hrlr(phri) = nan; %for any hires slices out of lores range
    end
end

lores_z_out_of_bounds = find(pos_lr_cntrs+pixdist_z_lr/2>max(pos_hr_cntrs)+pixdist_z_hr/2); %lores slice indices whose end is beyond the last hires z end (but we only care about this for registering hires, not for using registered hires)
hires_z_out_of_bounds = find(hrlr==lores_z_out_of_bounds); %remove all hires for the lores out of bounds to not have any partial correspondance slices
hrlr(hires_z_out_of_bounds) = [];


%% try to load registered hires stack, or if it doesn't exist, register it to the lores stack (hires is registered to lores in matlab, not python)


try
 
    stackmnthr = struct2cell(load(pth.hires_mat_matreg)); %load registered stack, if it exists
    stackmnthr = stackmnthr{1};

catch

    try

        error("warning, you are attempting to use deprecated hires registration code; register hires in caiman instead")

        lores_z_for_hires_map = setxor(lores_z_out_of_bounds, 1:size(stack, 3)); %crop here so the hires registration is correct
        stack_lores_mnt = rescale(mean(stack(:,:,lores_z_for_hires_map,:),4)); %rescale makes it a double, good for hires registration, may not be quite the same as stackmnt in a2p since lores_z_for_hires_map is applied here (using only z that match hires and lores)

        pth2.pthstackdir = pth.stackdir;
        pth2.stack_analysis = [pth.hires_prefix '.mat'];
        pth2.stacks_prefix = {pth.hires_prefix};

        stack_hires = stackseries(md.md_hires.sz, md.md_hires.numslice_withflyback, pth2, opts_hires.ld, recid);

        stack_hires(:,:,hires_z_out_of_bounds,:) = [];
        stackmnthr = rescale(mean(stack_hires, 4));

        stackmnthr = hiresrg(stackmnthr, ...
            pth.hires_mat_matreg, stack_lores_mnt, hrlr, opts_hires);

    catch

        "THERE IS NO HIRES STACK (OR THERE'S AN ERROR)"

    end

end


%% load caiman rois extracted from hires (work in progress, low priority because it's likely uncommon use case)

if opts_hires.use_caiman_on_hires % load caiman rois extracted from hires if they exist

    error(sprintf("ERROR \n" + ...
        "IF YOU WANT TO USE CAIMAN ROI EXTRACTION ON THIS HIRES REGISTERED TIF, \n" + ...
        "YOU COULD INSERT A CALL TO pl.py HERE \n" + ...
        "BUT YOU HAVE TO ADAPT THE PYTHON CODE TO OPERATE ON FILES WITH STRING hires \n" + ...
        "AND YOU HAVE TO ADAPT hiresrg TO OUTPUT THE REGISTERED FULL 4D HIRES, \n" + ...
        "RATHER THAN THE CURRENT OUTPUT, WHICH IS REGISTERED TEMPORAL AVERAGE stackmnthr \n" + ...
        "CURRENTLY HIRES IS JUST USED FOR ANATOMY, SO TEMPORAL AVERAGE IS FINE, \n" + ...
        "THE CODE ISN'T WRITTEN FOR HIRES FUNCTIONAL ROI EXTRACTION \n" + ...
        "YOU CAN USE update_tif BELOW TO WRITE THIS 4D ARRAY TO TIF TO USE IN CAIMAN, \n" + ...
        "ALL OF THESE REQUIRED CHANGES WOULD BE SMALL, AND IS ON THE TODO LIST"))

    fntmp = rdir(pth.roif_hires);
    if ~isempty(fntmp)
        pth.roif_hires = fntmp.name;
        roimask_hires = struct2cell(load(pth.roif_hires));
        roimask_hires = roimask_hires{1};
    else
        disp("WRITING HI RES REGISTERED TIF FOR CAIMAN EXTRACTION")
        pth_hires_tif_matreg = [pth.hires_mat_matreg(1:end-4) '.tif'];
        stack_hires_reg = INSERT_SOME_FUNCTION_TO_REGISTER_THE_FULL_4D_HIRES;
        update_tif(stack_hires_reg, pth_hires_tif, pth_hires_tif_matreg) %WRITE THE REGISTERED hires 
        roimask_hires = INSERT_SOME_FUNCTION_THAT_CALLS_CAIMAN_ON_HIRES;
        error("ERROR, HIRES CAIMAN ROI FILE DOESN'T EXIST, NEED TO RUN PYTHON EXTRACTION ON HI RES REGISTERED TIF")
    end

    %mask hires by caiman-extracted hires rois
    roimasks_hires_all = sum(roimask_hires, 4);
    roimasks_hires_all(roimasks_hires_all~=0) = 1;
    stackmnthr = stackmnthr.*roimasks_hires_all;

end


if ndims(stackmnthr)~=3
    error(sprintf("ERROR, \nTHIS PIPELINE REQUIRES stackmnthr TO BE 3D"))
end

