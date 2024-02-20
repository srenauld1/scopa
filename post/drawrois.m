function maskmanual_all_roi_all_z = drawrois(stack, regionex, pth_maskmanual, flag_limit_one_manual_roi)


if ndims(stack)~=4
    error(sprintf("ERROR, \nTHIS PIPELINE REQUIRES stack TO BE 4D, EVEN IF SOME DIM (e.g., 3rd dim z) ARE SINGLETON"))
end

%% make mean zt (2d), and mean t versions of input stack (3d)

clip_prctile = [0 100]; %[0 100] does not change contrast
scalefac = 1;
ignore_zeros = 1; %don't include zeros in percentile for contrast adjustment
numdim_out = 2; %number of dimensions of output image
filename_gif = []; %filename to save image, empty to skip

stack_mnzt = process_stack_for_roi_selection(stack, numdim_out, clip_prctile, scalefac, ignore_zeros, filename_gif);

stack_mnt = zeros(size(stack, 1), size(stack, 2), size(stack, 3), 'single');
for szi = 1:size(stack, 3)
    stack_mnt(:,:,szi) = process_stack_for_roi_selection(stack(:,:,szi,:), numdim_out, clip_prctile, scalefac, ignore_zeros, filename_gif);
end

%% show mean zt and decide if you still want to draw rois

hfg = figure( 'Units', 'Normalized', 'Windowstyle', 'docked') ;
imshow(stack_mnzt, 'InitialMagnification','fit')
axis image
title(['region "' regionex '", mean z, mean t']);
figure(hfg)
if flag_limit_one_manual_roi
    prompt = ['WARNING, you will be limited to drawing a single roi because you requested more than one automated roi \n' ...
        'do you want to draw this one manual roi for region "' regionex '"? type 1 for yes, type 0 for no: '];
else
    prompt = ['do you want to draw manual roi(s) for region "' regionex '"? type 1 for yes, type 0 for no: '];
end
commandwindow();
draw_manual = input(sprintf(prompt));

%% roi drawing control loop

if draw_manual

    prompt = ['do you want to draw roi(s) on the mean z projection (rather than on individual z slices)? type 1 for yes, type 0 for no: '];
    draw_on_meanzt = input(prompt);

    if draw_on_meanzt
        stackroidraw = stack_mnzt;
    else
        stackroidraw = stack_mnt;
    end

    prompt = ['do you want to draw any rois that are discontiguous in xy? type 1 for yes, type 0 for no: '];
    flag_xy_discontiguous = input(prompt);

    flag_single_roi_per_figure = 0; %can draw multiple rois per image
    if ~flag_xy_discontiguous% && ~draw_on_meanzt
        flag_single_roi_per_figure = 1; %can only draw one roi per image (to group each roi across z)
    end
    numrois_estimated = 200; %just to preallocate, choose a big number you won't draw
    maskmanual_all_roi_all_z = zeros(size(stackroidraw, 1), size(stackroidraw, 2), size(stackroidraw, 3), numrois_estimated, 'logical');

    roicount = 1;
    flag_quit_all_rois = 0; %quit flag will stop drawing rois altogether
    while ~flag_quit_all_rois

        maskmanual_one_roi_all_z = zeros(size(stackroidraw, 1), size(stackroidraw, 2), size(stackroidraw, 3), 'logical');
        szi = 1;
        while szi <= size(stackroidraw, 3)

            title_prefix = ['REGION "' regionex '", ROI ' num2str(roicount) ', MEAN t, ' titleaddendum(draw_on_meanzt, szi)];
            [maskmanual_one_roi_one_z, flag_quit_one_roi, flag_quit_all_rois] = drawrois_oneimage(stackroidraw(:,:,szi), title_prefix, flag_xy_discontiguous, flag_single_roi_per_figure);
            maskmanual_one_roi_all_z(:,:,szi) = maskmanual_one_roi_one_z;

            if szi == size(stackroidraw, 3) || flag_quit_one_roi || flag_quit_all_rois
                prompt = "do you want to proceed, or redo the last roi draw/button press? type 1 to proceed, type 0 to redo: ";
                figure; drawnow; close; commandwindow();
                flag_proceed = input(prompt);
                if flag_proceed
                    maskmanual_all_roi_all_z(:,:,:,roicount) = maskmanual_one_roi_all_z;
                    maskmanual_one_roi_all_z(:) = 0;
                    roicount = roicount + 1;
                    if flag_limit_one_manual_roi  %limited to one roi
                        flag_quit_all_rois = 1;
                    end
                else
                    flag_quit_all_rois = 0; %make sure this is zero if you want to redo last decision (in case last decision was pressing "q")
                end
                break;
            end

            szi = szi + 1;

        end
    end

else

    maskmanual_all_roi_all_z = ones(size(stack,1), size(stack,2), 'logical'); %otherwise just ones

end

if ~any(maskmanual_all_roi_all_z(:))
    maskmanual_all_roi_all_z = ones(size(stack,1), size(stack,2), 'logical'); %otherwise just ones
end


%% remove empty rois and save

keepinds = find(any(reshape(maskmanual_all_roi_all_z, [], size(maskmanual_all_roi_all_z, 4))));%this works for 2d, 3d, 4d
maskmanual_all_roi_all_z = maskmanual_all_roi_all_z(:,:,:,keepinds); %this works for 2d, 3d, 4d

if draw_on_meanzt
    maskmanual_all_roi_all_z = repmat(maskmanual_all_roi_all_z, [1 1 size(stack, 3) 1]); %this projects the 2d mask across all z
end

maskmanual = maskmanual_all_roi_all_z;
save(pth_maskmanual, 'maskmanual', '-v7.3', '-mat')

end


function strout = titleaddendum(draw_on_meanzt, szi)

if draw_on_meanzt
    strout = 'mean z';
else
    strout = ['z slice ' num2str(szi)];
end

end


