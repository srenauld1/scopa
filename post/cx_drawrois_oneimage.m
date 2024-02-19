function [maskroi, flag_quit_one_roi, flag_quit_all_rois] = cx_drawrois_oneimage(stack, title_prefix, flag_xy_discontiguous, flag_single_roi_per_figure)

fontsize = 15;

if ~exist('flag_xy_discontiguous', 'var')
    flag_xy_discontiguous = 0; %1 to draw discontiguous rois on single image (all separate rois on one image will be considered one roi for that image)
end

if ~exist('flag_single_roi_per_figure', 'var')
    flag_single_roi_per_figure = 0; %convenience flag, will automatically proceeed after one roi is drawn (helps prevent mistake when grouping roi across images)
end

if ~exist('title_prefix', 'var')
    title_prefix = '';
end

if flag_xy_discontiguous
    flag_single_roi_per_figure = 0; %but when flag_xy_discontiguous==0, flag_single_roi_per_figure can be 0 or 1
end

stack_rsc = stack;
indnz = stack~=0;

hfg = figure( 'Units', 'Normalized', 'WindowState', 'fullscreen') ;
set(hfg, 'KeyPressFcn', @roi_key_press_fcn);
him = imshow(stack, 'InitialMagnification', 'fit');
axis image

title({title_prefix; ...
    %'PRESS "backspace" TO UNDO LAST POLYGON'; ...
    'PRESS "s" TO MOVE TO THE NEXT IMAGE IN THE STACK (IF IT EXISTS)'; ...
    'PRESS "r" TO QUIT DRAWING THE CURRENT ROI (FOR ALL REMAINING IMAGES IN STACK)'; ...
    'PRESS "q" TO QUIT DRAWING ROIS ALTOGETHER FOR THIS REGION'; ...
    'PRESS "d" TO ALLOW A DISCONTIGUOUS ROI'; ...
    'PRESS "up / down arrow" TO RESCALE CONTRAST'}, ...
    'FontSize', fontsize)

numrows = size(stack,1);
numcols = size(stack,2);
bw_mask_ind = 1;
numrois_est = 200; % preallocate this many ROIs
bw_mask = zeros( [numrows, numcols] );
bw_label = zeros( [numrows, numcols] );
maskroi = zeros( numrows, numcols, numrois_est );

cmap = distinguishable_colors(numrois_est);

delete('tmp_roi_flag_.bin') %try delete first in case you errored in the middle of drawing last time
delete('tmp_scaleshift_.bin') %try delete first in case you errored in the middle of drawing last time

flag_do = 0;
flag_undo = 0;
flag_skip_this_figure = 0;
flag_quit_one_roi = 0;
flag_quit_all_rois = 0;
flag_roi_drawn = 0;
tmpFrame = [];
scalefac = 1;
flag_allow_rescale = 1;
flag_base_message = 1;
while true


    if flag_allow_rescale
        pause(0.01);
        fid = fopen('tmp_scaleshift_.bin', 'r');
        if fid>=3
            scaleshift = fread(fid, '*int8');
            delete('tmp_scaleshift_.bin')
            fclose(fid);
            scalefac = scalefac + single(scaleshift)/10;
            if scalefac<0
                scalefac = 0;
            end
            stack_rsc(indnz) = rescale(stack(indnz), 0, scalefac);
            him.CData = stack_rsc;
            him.Parent.XLabel.String{3} = ['RESCALED ORIGINAL CONTRAST BY ' num2str(round((scalefac - 1)*100)) ' PERCENT'];
        end
    end

    if flag_do
        him.Parent.XLabel.String{1} = 'DRAW NOW; SINGLE CLICK = PLACE VERTEX, DOUBLE CLICK AFTER CLOSURE = FINISH, ADJUST = DRAG VERTEX';
        if flag_xy_discontiguous
            him.Parent.XLabel.String{3} = 'ALL POLYGONS IN THIS IMAGE (AND OTHER IMAGES IN THE STACK) WILL COMPRISE ONE ROI';
        else
            if flag_single_roi_per_figure
                him.Parent.XLabel.String{3} = 'THIS POLYGON AND ANY OTHER POLYGONS IN THE STACK WILL COMPRISE ONE ROI';
            else
                him.Parent.XLabel.String{3} = 'EACH POLYGON IN THIS IMAGE (AND OTHER IMAGES IN THE STACK), IS A SEPARATE ROIS';
            end
        end
        flag_do = 0;
        flag_allow_rescale = 0;
        flag_base_message = 1;
        tmpFrame = roipoly;
    end

    pause(0.01);
    fid = fopen('tmp_roi_flag_.bin', 'r');
    if fid>=3
        tmpflag = fread(fid, '*uint8');
        delete('tmp_roi_flag_.bin')
        fclose(fid);
        flag_base_message = 0;
        if tmpflag==1
            flag_skip_this_figure = 1;
            him.Parent.XLabel.String{1} = 'PRESSED "s", SKIPPING THIS IMAGE';

        elseif tmpflag==2
            flag_quit_one_roi = 1;
            him.Parent.XLabel.String{1} = 'PRESSED "r", FINISHING THIS ROI';

        elseif tmpflag==3
            flag_quit_all_rois = 1;
            him.Parent.XLabel.String{1} = 'PRESSED "q", QUITTING ALL ROIS';

        elseif tmpflag==4 %pressed enter
            flag_do = 1;

        elseif tmpflag==5
            flag_undo = 1;
            him.Parent.XLabel.String{2} = 'PRESSED "backspace", REMOVED LAST ROI';

        elseif tmpflag==6
            if flag_xy_discontiguous==0
                flag_xy_discontiguous = 1;
                flag_single_roi_per_figure = 0;
                him.Parent.XLabel.String{2} = 'ALLOWING DISCONTIGUOUS ROI';
            end

        end

    end

    pause(0.01);
    if flag_skip_this_figure || ...
            flag_quit_one_roi || ...
            flag_quit_all_rois || ...
            (flag_roi_drawn & flag_single_roi_per_figure)
        him.Parent.Title.String = "QUITTING IN 3 SEC";
        if strcmp(him.Parent.XLabel.String{1}, 'PRESS "enter" TO DRAW A POLYGON')
            him.Parent.XLabel.String{1} = '';
        end
        him.Parent.XLabel.String{2} = '';
        him.Parent.XLabel.String{3} = '';
        pause(3)
        break;
    end

    if ~isempty(tmpFrame)
        flag_roi_drawn = 1;
        bw_mask = max( bw_mask, tmpFrame );
        bw_label = max( bw_label, bw_mask_ind * tmpFrame );
        maskroi(:, :, bw_mask_ind) = tmpFrame;
        tmpFrame = [];
        if flag_xy_discontiguous
            him = alphamask( maskroi(:, :, bw_mask_ind ), cmap(1, :), 0.33, him.Parent ); %this displays the roi/background overlay
        else
            him = alphamask( maskroi(:, :, bw_mask_ind ), cmap(bw_mask_ind, :), 0.33, him.Parent ); %this displays the roi/background overlay
        end
        bw_mask_ind = bw_mask_ind + 1;
    end

    if flag_undo
        flag_undo = 0;
        bw_mask_ind = bw_mask_ind - 1;
        bw_mask = zeros( [numrows, numcols] );
        bw_label(bw_label==max(bw_label(:))) = 0;
        maskroi(:, :, bw_mask_ind) = zeros( [numrows, numcols] );
        tmpFrame = [];
        if flag_xy_discontiguous
            him = alphamask( maskroi(:, :, bw_mask_ind ), cmap(1, :), 0.33, him.Parent ); %this displays the roi/background overlay
        else
            him = alphamask( maskroi(:, :, bw_mask_ind ), cmap(bw_mask_ind, :), 0.33, him.Parent ); %this displays the roi/background overlay
        end
    end

    if flag_base_message
        if flag_undo==0
            him.Parent.XLabel.String{1} = 'PRESS "enter" TO DRAW A POLYGON';
        end
    end

    him.Parent.XLabel.FontSize = 25;

end




if any(maskroi(:))


    maskroi = maskroi(:, :, [1 : bw_mask_ind - 1]);

    %remove overlapping pixels
    [rw,cl]=ind2sub([size(maskroi, 1) size(maskroi, 2)], find(sum(maskroi, 3)>1));
    for cli = 1:length(cl)
        maskroi(rw(cli), cl(cli), :) = 0; %do it this way
    end

    %remove rois with zero pixels
    ma = zeros(1, size(maskroi,3));
    for bi = 1:size(maskroi,3)
        ma(bi)=sum(vec(maskroi(:,:,bi)));
    end
    maskroi(:,:,[find(~ma)]) = [];

    if flag_xy_discontiguous
        maskroi = sum(maskroi, 3);
    end


    maskroi = logical(maskroi);

else

    maskroi = zeros( numrows, numcols);

end

close(hfg);


end


function roi_key_press_fcn(hfg, event)

eventkey = event.Key;
eventmod = event.Modifier;

if strcmpi(eventkey, 's')
    fid = fopen('tmp_roi_flag_.bin', 'w');
    fwrite(fid, 1, 'uint8');
    fclose(fid);

elseif strcmpi(eventkey, 'r')
    fid = fopen('tmp_roi_flag_.bin', 'w');
    fwrite(fid, 2, 'uint8');
    fclose(fid);

elseif strcmpi(eventkey, 'q')
    fid = fopen('tmp_roi_flag_.bin', 'w');
    fwrite(fid, 3, 'uint8');
    fclose(fid);

elseif strcmpi(eventkey, 'return')
    fid = fopen('tmp_roi_flag_.bin', 'w');
    fwrite(fid, 4, 'uint8');
    fclose(fid);

elseif strcmpi(eventkey, 'backspace')
    error("undo not implemented yet")
    fid = fopen('tmp_roi_flag_.bin', 'w');
    fwrite(fid, 5, 'uint8');
    fclose(fid);

elseif strcmpi(eventkey, 'd')
    fid = fopen('tmp_roi_flag_.bin', 'w');
    fwrite(fid, 6, 'uint8');
    fclose(fid);

elseif strcmpi(eventkey, 'downarrow')
    scaleshift = -1;
    if strcmpi(eventmod, 'shift')
        scaleshift = -5;
    end
    fid = fopen('tmp_scaleshift_.bin', 'w');
    fwrite(fid, scaleshift, 'int8')
    fclose(fid);

elseif strcmpi(eventkey, 'uparrow')
    scaleshift = 1;
    if strcmpi(eventmod, 'shift')
        scaleshift = 5;
    end
    fid = fopen('tmp_scaleshift_.bin', 'w');
    fwrite(fid, scaleshift, 'int8')
    fclose(fid);

end


end