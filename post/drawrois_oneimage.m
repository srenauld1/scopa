function [maskroi, flag_quit_one_roi, flag_quit_all_rois] = ...
    drawrois_oneimage(stack, regionex, title_prefix, ...
    flag_one_image, flag_single_roi_per_stack, flag_croplim)

fontsize = 15;

[pthenv, ~, ~] = fileparts(matlab.desktop.editor.getActiveFilename);
pthenv = [pthenv filesep];

if ~exist('flag_one_image', 'var')
    flag_one_image = 0; %convenience flag, will automatically proceeed after one roi is drawn (helps prevent mistake when grouping roi across images)
end
if ~exist('flag_single_roi_per_stack', 'var')
    flag_single_roi_per_stack = 0; %convenience flag, will automatically proceeed after one roi is drawn (helps prevent mistake when grouping roi across images)
end
if ~exist('flag_croplim', 'var')
    flag_croplim = 0; %convenience flag, will automatically proceeed after one roi is drawn (helps prevent mistake when grouping roi across images)
end
if ~exist('title_prefix', 'var')
    title_prefix = '';
end

stack_rsc = stack;
indnz = stack~=0;

hfg = figure( 'Units', 'Normalized', 'WindowState', 'fullscreen');
set(hfg, 'KeyPressFcn', @(src,evnt)roi_key_press_fcn(src,evnt,pthenv));

him = imshow(stack, 'InitialMagnification', 'fit');
axis image

title({title_prefix}, 'FontSize', fontsize);

if flag_one_image && ~flag_croplim
    tmptitle = {'THIS IS THE ONLY IMAGE IN THE STACK, OR THE MEAN Z IMAGE'};
    hfg.Children.Title.String = cat(1, hfg.Children.Title.String, tmptitle);
end

if flag_croplim
    tmptitle = {'YOU MUST DRAW A ROI ON THIS IMAGE'};
else
    tmptitle = {...
        'PRESS "q" TO QUIT DRAWING ROIS FOR THIS REGION'; ...
        'PRESS "r" TO QUIT THE CURRENT ROI (WILL SKIP ANY REMAINING IMAGES IN STACK)'; ...
        'PRESS "s" TO MOVE TO THE NEXT SLICE IN THE STACK (WILL QUIT THE CURRENT ROI IF THERE ARE NO MORE SLICES)'; ...
        %'PRESS "backspace" TO UNDO LAST POLYGON'; ...
        'PRESS "d" TO DRAW A ROI THAT IS DISCONTIGUOUS IN THIS IMAGE (ROI CAN BE CONTINUED ON OTHER SLICES, IF THEY EXIST)', ...
        };
end
hfg.Children.Title.String = cat(1, hfg.Children.Title.String, tmptitle);

tmptitle = {'PRESS "up / down arrow" TO RESCALE CONTRAST'};
hfg.Children.Title.String = cat(1, hfg.Children.Title.String, tmptitle);

numrows = size(stack,1);
numcols = size(stack,2);
bw_mask_ind = 1;
numrois_est = 200; % preallocate this many ROIs
maskroi = zeros( numrows, numcols, numrois_est);
maskroi_tmp = zeros( numrows, numcols, numrois_est);

cmap = distinguishable_colors(numrois_est);

delete([pthenv 'tmp_roi_flag_.bin']) %try delete first in case you errored in the middle of drawing last time
delete([pthenv 'tmp_scaleshift_.bin']) %try delete first in case you errored in the middle of drawing last time

if flag_one_image && ~flag_single_roi_per_stack
    flag_single_roi_per_image = 0;
else
    flag_single_roi_per_image = 1;
end
flag_do = 0;
flag_undo = 0;
flag_exit_this_figure = 0;
flag_quit_one_roi = 0;
flag_quit_all_rois = 0;
flag_roi_drawn = 0;
tmpFrame = [];
scalefac = 1;
flag_allow_rescale = 1;
flag_base_message = 1;
flag_xy_discontiguous = 0;
flag_prequit = 0;
tmp_ind = 1;
while true


    if flag_allow_rescale
        pause(0.01);
        fid = fopen([pthenv 'tmp_scaleshift_.bin'], 'r');
        if fid>=3
            scaleshift = fread(fid, '*int8');
            fclose('all');
            delete([pthenv 'tmp_scaleshift_.bin'])
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
        him.Parent.XLabel.String{1} = 'DRAW NOW . . . SINGLE CLICK TO PLACE VERTEX, DRAG VERTEX AFTER CLOSURE TO ADJUST, DOUBLE CLICK AFTER CLOSURE TO FINISH';
        if flag_croplim
            him.Parent.XLabel.String{3} = ['THE BOUNDING BOX OF THE ONE POLYGON YOU DRAW WILL COMPRISE THE XY LIMITS FOR REGION "' regionex '"'];
        else
            if flag_one_image
                if flag_single_roi_per_stack
                    him.Parent.XLabel.String{3} = ['THE UNION OF ALL POLYGONS YOU DRAW ON THIS IMAGE WILL COMPRISE THE ONE AND ONLY ROI FOR REGION "' regionex '"'];
                else
                    him.Parent.XLabel.String{3} = ['EACH POLYGON, AND EACH DISCONTIGUOUS UNION, WILL BE A DIFFERENT ROI, AND WILL COMPRISE ALL THE ROIS FOR FOR REGION "' regionex '"'];
                end
            else
                if flag_single_roi_per_stack
                    him.Parent.XLabel.String{3} = ['ALL POLYGONS IN THIS ONE CYCLE THROUGH THE STACK WILL COMPRISE THE ONE AND ONLY ROI FOR REGION "' regionex '"'];
                else
                    him.Parent.XLabel.String{3} = ['ALL POLYGONS IN THIS CYCLE THROUGH THE STACK WILL COMPRISE A SINGLE ROI FOR REGION "' regionex '" . . . REPEAT UNTIL YOU ARE DONE'];
                end
            end
        end
        hfg.Children.Title.String{end} = [];
        flag_do = 0;
        flag_allow_rescale = 0;
        flag_base_message = 1;
        tmpFrame = roipoly;
    end

    pause(0.01);
    fid = fopen([pthenv 'tmp_roi_flag_.bin'], 'r');
    if fid>=3
        tmpflag = fread(fid, '*uint8');
        fclose('all');
        delete([pthenv 'tmp_roi_flag_.bin'])
        flag_base_message = 0;
        if tmpflag==1 && ~flag_croplim %&& ~flag_one_image
            flag_exit_this_figure = 1;
            tmpone = 'PRESSED "s", SKIPPING THIS IMAGE';
            him.Parent.XLabel.String{1} = tmpone;

        elseif tmpflag==2 && ~flag_croplim
            flag_quit_one_roi = 1;
            tmpone = 'PRESSED "r", FINISHING THIS ROI';
            him.Parent.XLabel.String{1} = tmpone;

        elseif tmpflag==3 %&& ~flag_croplim
            flag_quit_all_rois = 1;
            tmpone = 'PRESSED "q", QUITTING ALL ROIS';
            him.Parent.XLabel.String{1} = tmpone;

        elseif tmpflag==4 && ~flag_prequit %pressed enter
            flag_do = 1;
            % if exist('himpre', 'var')
            %     him = himpre;
            %     himpre = [];
            % end

        elseif tmpflag==5 && bw_mask_ind>1
            % flag_undo = 1;
            % him.Parent.XLabel.String{2} = 'PRESSED "backspace", REMOVED LAST ROI';

        elseif tmpflag==6
            if flag_xy_discontiguous==0 && ~flag_croplim
                flag_xy_discontiguous = 1;
                him.Parent.XLabel.String{2} = 'ALLOWING DISCONTIGUOUS ROI, PRESS "e" TO EXIT DISCONTIGUOUS MODE';
                him.Parent.Title.String{end-1} = 'ALLOWING DISCONTIGUOUS ROI, PRESS "e" TO EXIT DISCONTIGUOUS MODE';
            end

        elseif tmpflag==7 && ~flag_croplim % pressed e
            if flag_xy_discontiguous==1
                flag_xy_discontiguous = 0;
                flag_roi_drawn = 1;
                maskroi(:, :, bw_mask_ind) = logical(sum(maskroi_tmp, 3));
                bw_mask_ind = bw_mask_ind + 1;
                maskroi_tmp(:) = 0;
                tmp_ind = 1;
                him.Parent.XLabel.String{2} = 'EXITED DISCONTIGUOUS MODE, RETURN WITH "d"';
                him.Parent.Title.String{end-1} = 'EXITED DISCONTIGUOUS MODE, RETURN WITH "d"';
            end

        end

    end

    pause(0.01);
    if flag_roi_drawn
        if flag_single_roi_per_image
            if strcmp(him.Parent.XLabel.String{1}, 'PRESS "enter" TO DRAW A POLYGON')
                xtmp{1} = 'PRESS "enter" TO DRAW A POLYGON';
                % him.Parent.XLabel.String{1} = 'YOU ARE LIMITED TO ONE POLYGON ON THIS IMAGE, PRESS "backspace" TO REDO IT, OR NAVIGATE WITH "q", "r" or "s"';
                tmpone = 'YOU HAVE DRAWN THE ONLY ROI OR SUBROI ALLOWED ON THIS IMAGE';
                him.Parent.XLabel.String{1} = tmpone;
            end
            xtmp{2} = him.Parent.XLabel.String{2};
            xtmp{3} = him.Parent.XLabel.String{2};
            him.Parent.XLabel.String{2} = '';
            him.Parent.XLabel.String{3} = '';
            flag_do = 0;
            % flag_prequit = 1;
            % flag_quit_all_rois = 1;
            flag_exit_this_figure = 1;
        else 
            him.Parent.XLabel.String{1} = 'PRESS "enter" TO DRAW A POLYGON';
        end
    end


    if flag_exit_this_figure || ...
            flag_quit_one_roi || ...
            flag_quit_all_rois
        him.Parent.Title.String = "QUITTING IN 3 SEC";
        him.Parent.XLabel.String{1} = tmpone;
        him.Parent.XLabel.String{2} = '';
        him.Parent.XLabel.String{3} = '';
        pause(3)
        break;
    end

    if ~isempty(tmpFrame)
        maskroi_tmp(:,:,tmp_ind) = tmpFrame;
        tmpFrame = [];
        him = alphamask( maskroi_tmp(:, :, tmp_ind ), cmap(bw_mask_ind, :), 0.33, him.Parent ); %this displays the roi/background overlay
        if flag_xy_discontiguous
            tmp_ind = tmp_ind+1;
        else
            flag_roi_drawn = 1;
            maskroi(:, :, bw_mask_ind) = maskroi_tmp(:,:,tmp_ind);
            bw_mask_ind = bw_mask_ind + 1;
        end
    end

    % if flag_undo
    %     flag_undo = 0;
    %     if flag_prequit
    %         him.Parent.XLabel.String{1} = xtmp{1};
    %         him.Parent.XLabel.String{2} = xtmp{2};
    %         him.Parent.XLabel.String{3} = xtmp{3};
    %         flag_prequit = 0;
    %     end
    %     bw_mask_ind = bw_mask_ind - 1;
    %     maskroi(:, :, bw_mask_ind) = zeros( [numrows, numcols] );
    %     tmpFrame = [];
    %     him = alphamask( maskroi_tmp(:, :, tmp_ind ), cmap(bw_mask_ind, :), 0.33, him.Parent ); %this displays the roi/background overlay
    % end

    if flag_base_message
        if flag_undo==0
            him.Parent.XLabel.String{1} = 'PRESS "enter" TO DRAW A POLYGON';
        end
    end

    him.Parent.XLabel.FontSize = 20;

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

    maskroi = logical(maskroi);

else

    maskroi = zeros( numrows, numcols);

end

close(hfg);


end


function roi_key_press_fcn(hfg, event, varargin)

pthenv = varargin{1};

eventkey = event.Key;
eventmod = event.Modifier;

if strcmpi(eventkey, 's')
    fid = fopen([pthenv 'tmp_roi_flag_.bin'], 'w');
    fwrite(fid, 1, 'uint8');
    fclose('all');

elseif strcmpi(eventkey, 'r')
    fid = fopen([pthenv 'tmp_roi_flag_.bin'], 'w');
    fwrite(fid, 2, 'uint8');
    fclose('all');

elseif strcmpi(eventkey, 'q')
    fid = fopen([pthenv 'tmp_roi_flag_.bin'], 'w');
    fwrite(fid, 3, 'uint8');
    fclose('all');

elseif strcmpi(eventkey, 'return')
    fid = fopen([pthenv 'tmp_roi_flag_.bin'], 'w');
    fwrite(fid, 4, 'uint8');
    fclose('all');

elseif strcmpi(eventkey, 'backspace')
    % error("undo not implemented yet")
    fid = fopen([pthenv 'tmp_roi_flag_.bin'], 'w');
    fwrite(fid, 5, 'uint8');
    fclose('all');

elseif strcmpi(eventkey, 'd')
    fid = fopen([pthenv 'tmp_roi_flag_.bin'], 'w');
    fwrite(fid, 6, 'uint8');
    fclose('all');

elseif strcmpi(eventkey, 'e')
    fid = fopen([pthenv 'tmp_roi_flag_.bin'], 'w');
    fwrite(fid, 7, 'uint8');
    fclose('all');

elseif strcmpi(eventkey, 'downarrow')
    scaleshift = -1;
    if strcmpi(eventmod, 'shift')
        scaleshift = -5;
    end
    fid = fopen([pthenv 'tmp_scaleshift_.bin'], 'w');
    fwrite(fid, scaleshift, 'int8')
    fclose('all');

elseif strcmpi(eventkey, 'uparrow')
    scaleshift = 1;
    if strcmpi(eventmod, 'shift')
        scaleshift = 5;
    end
    fid = fopen([pthenv 'tmp_scaleshift_.bin'], 'w');
    fwrite(fid, scaleshift, 'int8')
    fclose('all');

end


end