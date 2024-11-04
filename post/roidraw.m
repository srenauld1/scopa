function roimaskman_allchan = roidraw(stack, pth_roim, regionex, opt)

chandraw = opt.chandraw;
chancp = opt.chancp;
maskname = opt.maskname;

numchan = size(stack,5);

roimaskman_allchan = repmat({ones(size(stack,1), size(stack,2), size(stack,3), 'logical')}, [numchan, 1]);

for c = 1:numchan
    if ismember(c,chandraw)
        fninsert = ['_' maskname '_chn' num2str(c) '_roiman_'];
        pth_maskman = insertBefore(pth_roim, '.mat', fninsert);
        try
            roiman = struct2cell(load(pth_maskman));
            roiman = roiman{1};
            if all(roiman(:)==1)
                fprintf("WARNING, MASK MANUAL CHANNEL" + num2str(c) + " IS ALL ONES FOR REGION: " + regionex + newline)
            end
        catch
            flag_limit_one_manual_roi = 0;
            if numroiauto>1
                flag_limit_one_manual_roi = 1;
            end
            roiman = roidraw_onechan(stack(:,:,:,:,c), regionex, flag_limit_one_manual_roi);
            save(pth_maskman, 'roiman', '-v7.3', '-mat')
        end
        roimaskman_allchan{c} = roiman;
    end
end
if ~isempty(chancp) && numchan==2
    chanreceive = setxor(chancp, [1,2]);
    fprintf("chancp is " + num2str(chancp) + "; COPYING ANY DRAWN ROIS FROM CHANNEL " + num2str(chancp) + " ONTO CHANNEL " + num2str(chanreceive) + newline);
    if all(roimaskman_allchan{chancp}==1, 'all') && ~all(roimaskman_allchan{chanreceive}==1, 'all')
        fprintf("warning projecting a manual mask of all ones onto a manual mask that is not all ones; you may not intend this" + newline);
    end
    roimaskman_allchan(chanreceive) = roimaskman_allchan(chancp);
end


end


function roimaskman_all_roi_all_z = roidraw_onechan(stack, regionex, pth_tmpfiles, flag_limit_one_manual_roi)


if ndims(stack)~=4
    error("stack in roidraw must be 4-dimensional (yxzt); use singleton z if not volumetric")
end

regionex_reformat = strrep(regionex, '_', ' ');

%% make mean zt (2d), and mean t (3d) versions of input stack

stack = stackmn(stack, numdim_out); %take mean of trailing dims until stack is 2d
stack_mnzt = stackclip(stack, clip=[0 100], rescale=1, skipzero=1);

stackmnt = zeros(size(stack, 1), size(stack, 2), size(stack, 3), 'single');
for szi = 1:size(stack, 3)
    stackmnt(:,:,szi) = stackclip(stack(:,:,szi,:), numdim_out, clip_prctile, scalefac, ignore_zeros, filename_gif);
end

%% show mean zt and decide if you still want to draw rois

envname = getenv('HOSTNAME');
if ~isempty(regexp( envname, 'compute-', 'once' ))
    hfg = figure( 'Units', 'Normalized', 'WindowState', 'fullscreen');  %fullscreen makes it docked on O2 matlab proxy app
else
    hfg = figure( 'Units', 'Normalized', 'Windowstyle', 'docked');
end


imshow(stack_mnzt, 'InitialMagnification','fit')
axis image
title(['region "' regionex_reformat '", mean z, mean t']);
figure(hfg)
if flag_limit_one_manual_roi
    prompt = ['WARNING, because you requested more than one automated roi \n' ...
        'you will be limited to drawing a single roi \n', ...
        'this roi can be composed of one or more polygons drawn across one or more images in the stack, or drawn on the mean z projection \n', ...
        'do you want to draw this one manual roi for region "' regionex '"? \n', ...
        'type 1 for yes, type 0 for no: '];
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
        stackroidraw = stackmnt;
    end

    if ndims(stackroidraw)==2
        flag_one_image = 1;
    else
        flag_one_image = 0;
    end

    numrois_estimated = 200; %just to preallocate, choose a big number you won't draw
    roimaskman_all_roi_all_z = zeros(size(stackroidraw, 1), size(stackroidraw, 2), size(stackroidraw, 3), numrois_estimated, 'logical');

    roicount = 1;
    flag_quit_all_rois = 0; %quit flag will stop drawing rois altogether
    while ~flag_quit_all_rois

        roimaskman_tmp2 = zeros(size(stackroidraw, 1), size(stackroidraw, 2), size(stackroidraw, 3), 'logical');
        szi = 1;
        while szi <= size(stackroidraw, 3)

            if flag_limit_one_manual_roi
                title_prefix = ['THIS IS REGION "' regionex_reformat '", MEAN T, ' titleaddendum(flag_one_image, draw_on_meanzt, szi), ' . . . NOW DRAW ROI #1 (THE ONLY ALLOWED ROI) ON THIS IMAGE'];
            else
                if flag_one_image
                    title_prefix = ['THIS IS REGION "' regionex_reformat '", MEAN T, ' titleaddendum(flag_one_image, draw_on_meanzt, szi), ' . . . NOW DRAW ALL ROIS ON THIS IMAGE '];
                else
                    title_prefix = ['THIS IS REGION "' regionex_reformat '", MEAN T, ' titleaddendum(flag_one_image, draw_on_meanzt, szi), ' . . . NOW DRAW ALL OR PART OF ROI #' num2str(roicount) ' ON THIS IMAGE'];
                end
            end

            [roimaskman_tmp, flag_quit_one_roi, flag_quit_all_rois] = ...
                drawrois_oneimage(stackroidraw(:,:,szi), pth_tmpfiles, regionex_reformat, title_prefix, flag_one_image, flag_limit_one_manual_roi);

            if flag_one_image
                roimaskman_tmp2 = roimaskman_tmp;
            else
                roimaskman_tmp2(:,:,szi) = roimaskman_tmp;
            end

            if szi == size(stackroidraw, 3) || flag_quit_one_roi || flag_quit_all_rois

                if flag_one_image
                    for roicount = 1:size(roimaskman_tmp, 3)
                        roimaskman_all_roi_all_z(:,:,:,roicount) = roimaskman_tmp2(:,:,roicount);
                    end
                else
                    roimaskman_all_roi_all_z(:,:,:,roicount) = roimaskman_tmp2;
                    roicount = roicount + 1;
                end
                roimaskman_tmp2(:) = 0;

                if flag_limit_one_manual_roi || flag_one_image %limited to one roi
                    flag_quit_all_rois = 1;
                end

                break;
            end

            szi = szi + 1;

        end
    end

else

    draw_on_meanzt = 0;
    roimaskman_all_roi_all_z = ones(size(stack,1), size(stack,2), 'logical'); %otherwise just ones

end

if ~any(roimaskman_all_roi_all_z(:))
    roimaskman_all_roi_all_z = ones(size(stack,1), size(stack,2), 'logical'); %otherwise just ones
end


%% remove empty rois and save

keepinds = find(any(reshape(roimaskman_all_roi_all_z, [], size(roimaskman_all_roi_all_z, 4))));%find nonempty rois, this works for 2d, 3d, 4d
roimaskman_all_roi_all_z = roimaskman_all_roi_all_z(:,:,:,keepinds); %remove empty "rois", this works for 2d, 3d, 4d

if draw_on_meanzt
    roimaskman_all_roi_all_z = repmat(roimaskman_all_roi_all_z, [1 1 size(stack, 3) 1]); %this projects the 2d mask across all z
end


if all(roimaskman_all_roi_all_z(:)==1) && ndims(roimaskman_all_roi_all_z)==2 && ndims(stack)>2
    roimaskman_all_roi_all_z = ones(size(stack,1), size(stack,2), size(stack,3), 'logical'); %insertiung this because i don't remember why the above creates 2d rather than 3d ones
end

roimaskman = roimaskman_all_roi_all_z;


end


function strout = titleaddendum(flag_one_image, draw_on_meanzt, szi)

if draw_on_meanzt
    strout = 'MEAN Z';
else
    strout = ['Z SLICE ' num2str(szi)];
    if flag_one_image
        strout = ['Z SLICE ' num2str(szi) '(THE ONLY SLICE IN THE STACK)'];
    end
end

end


