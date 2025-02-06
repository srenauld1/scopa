function roiman_allchan = roidraw(stackmnt, opt)

arguments
    stackmnt
    opt.pthstack = []
    opt.regionex = 'none'
    opt.maskname = 'none'
    opt.chan = 1
    opt.oneroi = 0
    opt.dmstack = []
    opt.chancp = 1
    opt.flag_croplim = 0
    opt.roialpha = 0.33
    opt.cmap = []
    opt.fontsize = 12
    opt.remove_overlap = [] %if empty, prompt will ask user if they want to remove overlapping pixels; otherwise 0 or 1 to skip or do
end
pthstack = opt.pthstack;
regionex = opt.regionex;
dmstack = opt.dmstack;
flag_oneroi = opt.oneroi;
chan = opt.chan;
chancp = opt.chancp;
maskname = opt.maskname;
flag_croplim = opt.flag_croplim;
roialpha = opt.roialpha;
cmap = opt.cmap;
fontsize = opt.fontsize;
remove_overlap = opt.remove_overlap;

if ndims(stackmnt)>5
    error("stackmnt in roidraw cannot have more than 5 dimensions")
end

stackmnt = stackperm(stackmnt, dmstack);

numchan = size(stackmnt,5);

roiman_allchan = cell(numchan, 1);

for c = 1:numchan
    chan_combine = unique([chan chancp]); %combine in case you want to copy a previously drawn channel, and also want to currently draw another channel
    if ismember(c,chan_combine)
        fnsuffix = ['_' regionex '_' maskname '_chn' num2str(c) '_mm'];
        pth_maskman = insertBefore(pthstack, '_.mat', fnsuffix);
        try
            roiman = struct2cell(load(pth_maskman)); %make sure it's called roiman (in case using old mask)
            roiman = roiman{1};
            if all(roiman(:)==1)
                fprintf("MASK MANUAL IS ALL ONES FOR regionex: " + regionex + ", maskname: " + maskname + ", channel: " + num2str(c) + newline)
            end
        catch
            roiman = roidraw_onechan(stackmnt(:,:,:,:,c), regionex, maskname, c, flag_oneroi, flag_croplim, roialpha, cmap, fontsize, remove_overlap);
            save(pth_maskman, 'roiman', '-v7.3', '-mat')
        end
        roiman_allchan{c} = roiman;
    end
end
if ~isempty(chancp) && numchan==2
    chanreceive = setxor(chancp, [1,2]);
    fprintf("chancp is " + num2str(chancp) + "; COPYING ANY DRAWN ROIS FROM CHANNEL " + num2str(chancp) + " ONTO CHANNEL " + num2str(chanreceive) + newline);
    if all(roiman_allchan{chancp}==1, 'all') && ~all(roiman_allchan{chanreceive}==1, 'all')
        fprintf("warning projecting a manual mask of all ones onto a manual mask that is not all ones; you may not intend this" + newline);
    end
    roiman_allchan(chanreceive) = roiman_allchan(chancp);
end




end


function roimaskman_all_roi_all_z = roidraw_onechan(stackmnt, regionex, maskname, c, flag_oneroi, flag_croplim, roialpha, cmap, fontsize, remove_overlap)


regionex_reformat = strrep(regionex, '_', ' ');
title_prefix = ['REGIONEX: "' regionex_reformat '", MASKNAME: "' maskname  '", channel: ' num2str(c)];


%% make mean zt (2d) version of input stackmnt

% stackmnt = stackclip(stackmnt, clip=[0,1]);

stackmnzt = stacktype(mean(stackmnt, 3), class(stackmnt));
% stackmnzt = stackclip(stackmnzt, clip=[0,1]);

szo = size(stackmnt);

%% show mean zt and decide if you still want to draw rois

h = stackplt(stackmnzt, dmplt='yx', stackjust='center', szf=1);
h.hfg.WindowStyle = 'Docked';
h.httl.String = ['regionex "' regionex_reformat '", mean z, mean t'];
figure(h.hfg)

if flag_oneroi
    prompt = sprintf("WARNING, because you requested more than one automated roi, you will be limited to drawing a single roi " + newline + ...
        "this roi can be composed of one or more polygons drawn across one or more images in the stack, or drawn on the mean z projection " + newline + ...
        "Do you want to draw this one manual roi for regionex '" + regionex + "'? Type 1 for yes, type 0 for no:");
else
    prompt = sprintf("PRESS 1 TO DRAW ROIS FOR regionex '" + regionex + "', maskname '" + maskname + "', channel " + num2str(c) + "; PRESS 0 TO SKIP DRAWING: ");
end
commandwindow();
draw_manual = input(prompt);


%% roi drawing control loop

if draw_manual

    prompt = sprintf("PRESS 1 TO DRAW ON EACH SLICE, PRESS 0 TO DRAW ON THE MEAN Z PROJECTION (SHOWN): ");
    draw_on_meanzt = ~input(prompt);

    if draw_on_meanzt
        stackdraw = stackmnzt;
        flag_allz = 1;
    else
        stackdraw = stackmnt;
        prompt = sprintf("PRESS 1 TO DRAW ON A SINGLE FIGURE WITH ALL REGIONEX SLICES (FASTER, LOWER RES), PRESS 0 TO DRAW ON EACH SLICE IN A SEPARATE FIGURE (SLOWER, BUT HIGHER RES): ");
        flag_allz = input(prompt);
    end

    if isempty(remove_overlap)
        prompt = sprintf("PRESS 1 TO USE THE ROIS YOU WILL DRAW, PRESS 0 TO AUTOMATICALLY REMOVE ANY PIXELS IN OVERLAPPING ROIS: ");
        remove_overlap = input(prompt);
    end


    if ndims(stackdraw)==2 %if stack has no z dim, or if draw_on_meanzt
        flag_oneim = 1;
    else
        flag_oneim = 0;
    end

    if flag_allz
        numfig_per_loop = 1;
    else
        numfig_per_loop = size(stackdraw, 3);
    end

    numroiest = 200; %just to preallocate, a big number
    roimaskman_all_roi_all_z = zeros(size(stackdraw, 1), size(stackdraw, 2), size(stackdraw, 3), numroiest, 'logical');

    ir = 1;
    flag_quit_all_rois = 0; %quit flag will stop drawing rois altogether
    while ~flag_quit_all_rois

        roimaskman_tmp2 = zeros(size(stackdraw, 1), size(stackdraw, 2), size(stackdraw, 3), 'logical');
        szi = 1;
        while szi <= numfig_per_loop

            [roimaskman_tmp, flag_quit_one_roi, flag_quit_all_rois, ir] = ...
                roidraw_onefig(stackdraw, flag_oneim, flag_oneroi, flag_allz, flag_croplim, draw_on_meanzt, ir, szi, title_prefix=title_prefix, roialpha=roialpha, cmap=cmap, fontsize=fontsize, remove_overlap=remove_overlap);

            if flag_oneim || flag_allz
                roimaskman_tmp2 = roimaskman_tmp;
            else
                roimaskman_tmp2(:,:,szi) = roimaskman_tmp;
            end

            if szi == numfig_per_loop || flag_quit_one_roi || flag_quit_all_rois

                if flag_oneim
                    for ir = 1:size(roimaskman_tmp, 3)
                        roimaskman_all_roi_all_z(:,:,:,ir) = roimaskman_tmp2(:,:,ir);
                    end
                else
                    if flag_allz
                        roimaskman_all_roi_all_z = roimaskman_tmp2;
                    else
                        roimaskman_all_roi_all_z(:,:,:,ir) = roimaskman_tmp2;
                    end
                    ir = ir + 1;
                end
                roimaskman_tmp2(:) = 0;

                if flag_oneroi || flag_oneim %limited to one figure drawing session
                    flag_quit_all_rois = 1;
                end

                break;
            
            end

            szi = szi + 1;

        end
    end

else

    draw_on_meanzt = 0;
    roimaskman_all_roi_all_z = ones(szo(1), szo(2), 'logical'); %otherwise just ones

end

if ~any(roimaskman_all_roi_all_z(:))
    roimaskman_all_roi_all_z = ones(szo(1), szo(2), 'logical'); %otherwise just ones
end


%% remove empty rois and save

keepinds = find(any(reshape(roimaskman_all_roi_all_z, [], size(roimaskman_all_roi_all_z, 4))));%find nonempty rois, this works for 2d, 3d, 4d
roimaskman_all_roi_all_z = roimaskman_all_roi_all_z(:,:,:,keepinds); %remove empty "rois", this works for 2d, 3d, 4d

if draw_on_meanzt
    roimaskman_all_roi_all_z = repmat(roimaskman_all_roi_all_z, [1 1 szo(3) 1]); %this projects the 2d mask across all z
end


if all(roimaskman_all_roi_all_z(:)==1) && ndims(roimaskman_all_roi_all_z)==2 && numel(szo)>2
    roimaskman_all_roi_all_z = ones(szo(1), szo(2), szo(3), 'logical'); %insertiung this because i don't remember why the above creates 2d rather than 3d ones
end


if remove_overlap %remove overlapping pixels
    [rw,cl,zs]=ind2sub([size(roimaskman_all_roi_all_z, 1), size(roimaskman_all_roi_all_z, 2), size(roimaskman_all_roi_all_z, 3)], find(sum(roimaskman_all_roi_all_z, 4)>1));
    for cli = 1:length(cl)
        roimaskman_all_roi_all_z(rw(cli), cl(cli), zs(cli), :) = 0; %why do it this way?
    end
end


end



