function [roimaskout, mm] = roidraw(stack, pthstack, opt)

%put drawn mask for each channel in a different element of nonscalar struct since each channel can have different number rois (simpler than padding smaller to put into matrtix)

arguments
    stack %can also be stack mean t (see below, stack just gets averaged if 4th dim is greater than 1)
    pthstack
    opt.roimaskin = [] %sole purpose is to set whether roimaskout is in a cell (when roidraw is run from within roimake), or not (possible when roidraw is run on its own)
    opt.rg = []
    opt.maskname = 'none'
    opt.methodmm = 'all'
    opt.oneroi = 0
    opt.dmstack = []
    opt.flag_rg = 0
    opt.roialpha = 0.33
    opt.cmap = []
    opt.fontsize = 12
    opt.remove_overlap = [] %if empty, prompt will ask user if they want to remove overlapping pixels; otherwise 0 or 1 to skip or do
end
roimaskin = opt.roimaskin;
rg = opt.rg;
dmstack = opt.dmstack;
flag_oneroi = opt.oneroi;
methodmm = opt.methodmm;
maskname = opt.maskname;
flag_rg = opt.flag_rg;
roialpha = opt.roialpha;
cmap = opt.cmap;
fontsize = opt.fontsize;
remove_overlap = opt.remove_overlap;


if ndims(stack)>5
    error("stackmnt in roidraw cannot have more than 5 dimensions")
end

stack = stackperm(stack, dmstack);

numchan = size(stack,5);

if isempty(roimaskin)
    cellout = 0;
    roimaskin = cell(numchan,1); %needs to be cell in case 2-channel with different number rois
else
    cellout = 1;
    if ~iscell(roimaskin)
        error("roimaskin must be cell (or empty)")
    end
end
if isempty(rg)
    [~, rg] = stackcrop(stack, pthstack); %if rg is empty, it's default, which is no crop, so no need to output stack
end
rgname = rg.name;

id = idmake(pthstack);
fnsuffix = ['_' rgname '_' maskname '_mm'];
pthmm = [id.pthrec, fnsuffix, '_.mat'];

if size(stack,4)>1
    stackmnt = mean(stack,4);
else
    stackmnt = stack;
end

[chandraw, dochancp] = methodmmparse(methodmm, numchan);

roimaskout = roimaskin;

try

    mm = load(pthmm);
        
    for c = chandraw
        roimaskout{c} = mm(c).mask;
    end

    if any(~isfield(mm(1), {'mask', 'maskname', 'chan', 'methodmm', 'rg'})) || numel(mm)==2 && any(~isfield(mm(2), {'mask', 'maskname', 'chan', 'methodmm', 'rg'}))
        error("mm struct must contain fields 'mask', 'maskname', 'chan', 'methodmm', 'rg'; you may have loaded an old mm struct")
    end
    if ~isequal(mm(1).rg, rg) || numel(mm)==2 && ~isequal(mm(2).rg, rg)
        error("mm file exists but for at least one channel rg in mm file does not match current rg with same name; did you delete the rg you used to draw this mm?")
    end
    if ~isequal(mm(1).maskname, maskname) || ~isequal(mm(1).methodmm, methodmm) || ( numel(mm)==2 && ( ~isequal(mm(2).maskname, maskname) || ~isequal(mm(2).methodmm, methodmm) ) )
        error("mm file exists but maskname and/or methodmm do not match for at least one channel")
    end
    if all(mm(1).mask==1)
        fprintf("NOTE MANUAL ROI MASK IS ALL ONES FOR rgname: " + rgname + ", maskname: " + maskname + ", channel 1: " + newline + "YOU PROBABLY CHOSE TO SKIP DRAWING" + newline)
    end
    if numel(mm)==2 && all(mm(2).mask==1)
        fprintf("NOTE MANUAL ROI MASK IS ALL ONES FOR rgname: " + rgname + ", maskname: " + maskname + ", channel 2: " + newline + "YOU PROBABLY CHOSE TO SKIP DRAWING" + newline)
    end

catch ME

    clear mm %in case old mm was loaded and errored, remove this soon

    if isempty(stackmnt)
        error("input stack is empty, so if mm file doens't exist, you cannot create one; you got this message when you tried to load mm: " + ME.message + newline)
    end
    fprintf(newline + "" + ME.message + newline + "YOU WILL NOW BE PROMPTED TO DRAW ROIS" + newline)

    for c = chandraw %some fields are redundant across channels (ie rg and maskname are the same for both channels), but for symmetry, and simpler code downstream, they're written to both channels

        roimaskout{c} = roidraw_onechan(stackmnt(:,:,:,:,c), rgname, maskname, c, flag_oneroi, flag_rg, roialpha, cmap, fontsize, remove_overlap);
        mm(c).mask = roimaskout{c};
        mm(c).maskname = maskname;
        mm(c).methodmm = methodmm;
        mm(c).chan = c;
        mm(c).rg = rg; %save the region (rg) the masks were drawn on, in case the region changes but its name stays the same

        if dochancp
            chanreceive = setdiff([1 2], c);
            fprintf("dochancp (DERIVED FROM methodmm) IS TRUE; COPYING ANY DRAWN ROIS FROM CHANNEL " + num2str(c) + " ONTO CHANNEL " + num2str(chanreceive) + newline);
            if all(mm(c).mask==1, 'all') && ~all(mm(chanreceive).mask==1, 'all')
                fprintf("warning projecting a manual mask of all ones onto a manual mask that is not all ones" + newline);
            end
            mm(chanreceive).mask = mm(c).mask;
        end

    end
    
    if chandraw==1 && numchan==2 %do this so that 2-channel data gets empty 2nd element if channel 2 has no auto rois, otherwise 2nd element wouldn't exist, which would mislead user into thinking it's single-channel data
        mm(2) = structfun(@(x) [], mm, 'UniformOutput', false);
    end
    if ~exist('mm', 'var')
        mm = [];
    end
    save(pthmm, '-struct', 'mm', '-v7.3', '-mat') %save each channel's mask separately (could do it together instead, either way is fine right?)

end

if ~cellout
    roimaskout = cell2mat(roimaskout);
end



end


function roimask_all_roi_all_z = roidraw_onechan(stackmnt, rgname, maskname, c, flag_oneroi, flag_rg, roialpha, cmap, fontsize, remove_overlap)


title_prefix = ['RGNAME: "' rgname '", MASKNAME: "' maskname  '", channel: ' num2str(c)];


%% make mean zt (2d) version of input stackmnt

% stackmnt = stackclip(stackmnt, clip=[0,1]);

stackmnzt = stacktype(mean(stackmnt, 3), class(stackmnt));
% stackmnzt = stackclip(stackmnzt, clip=[0,1]);

szo = size(stackmnt, [1 2 3]);

%% show mean zt and decide if you still want to draw rois

h = stackplt(stackmnzt, dmplt='yx', stackjust='center', szf=1, dosave=0);
h.hfg.WindowStyle = 'Docked';
h.httl.String = ['rgname "' rgname '", mean z, mean t'];
figure(h.hfg)

if flag_oneroi
    prompt = sprintf("\n\n\nBecause you requested more than one automated roi, you will be limited to drawing a single roi " + newline + ...
        "this roi can be composed of one or more polygons drawn across one or more images in the stack, or drawn on the mean z projection " + newline + ...
        "Do you want to draw this one manual roi for rgname '" + rgname + "'?" + newline + "Type 1 for yes, type 0 for no:");
else
    prompt = sprintf("PRESS 1 TO DRAW ROIS FOR rgname '" + rgname + "', maskname '" + maskname + "', channel " + num2str(c) + "; PRESS 0 TO SKIP DRAWING: ");
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
        % prompt = sprintf("PRESS 1 TO DRAW ON A SINGLE FIGURE WITH ALL RGNAME SLICES (FASTER, LOWER RES), PRESS 0 TO DRAW ON EACH SLICE IN A SEPARATE FIGURE (SLOWER, BUT HIGHER RES): ");
        % flag_allz = input(prompt);
        flag_allz = 1; %hard coding 1 because it's always preferable in my opinion
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
    roimask_all_roi_all_z = zeros(size(stackdraw, 1), size(stackdraw, 2), size(stackdraw, 3), numroiest, 'logical');

    ir = 1;
    flag_quit_all_rois = 0; %quit flag will stop drawing rois altogether
    while ~flag_quit_all_rois

        roimask_tmp2 = zeros(size(stackdraw, 1), size(stackdraw, 2), size(stackdraw, 3), 'logical');
        szi = 1;
        while szi <= numfig_per_loop

            [roimask_tmp, flag_quit_one_roi, flag_quit_all_rois, ir] = ...
                roidraw_onefig(stackdraw, flag_oneim, flag_oneroi, flag_allz, flag_rg, draw_on_meanzt, ir, szi, title_prefix=title_prefix, roialpha=roialpha, cmap=cmap, fontsize=fontsize, remove_overlap=remove_overlap);

            if flag_oneim || flag_allz
                roimask_tmp2 = roimask_tmp;
            else
                roimask_tmp2(:,:,szi) = roimask_tmp;
            end

            if szi == numfig_per_loop || flag_quit_one_roi || flag_quit_all_rois

                if flag_oneim
                    for ir = 1:size(roimask_tmp, 3)
                        roimask_all_roi_all_z(:,:,:,ir) = roimask_tmp2(:,:,ir);
                    end
                else
                    if flag_allz
                        roimask_all_roi_all_z = roimask_tmp2;
                    else
                        roimask_all_roi_all_z(:,:,:,ir) = roimask_tmp2;
                    end
                    ir = ir + 1;
                end
                roimask_tmp2(:) = 0;

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
    roimask_all_roi_all_z = ones(szo(1), szo(2), 'logical'); %otherwise just ones

end

if ~any(roimask_all_roi_all_z(:))
    roimask_all_roi_all_z = ones(szo(1), szo(2), 'logical'); %otherwise just ones
end


%% remove empty rois and save

keepinds = find(any(reshape(roimask_all_roi_all_z, [], size(roimask_all_roi_all_z, 4))));%find nonempty rois, this works for 2d, 3d, 4d
roimask_all_roi_all_z = roimask_all_roi_all_z(:,:,:,keepinds); %remove empty "rois", this works for 2d, 3d, 4d

if draw_on_meanzt
    roimask_all_roi_all_z = repmat(roimask_all_roi_all_z, [1 1 szo(3) 1]); %this projects the 2d mask across all z
end


if all(roimask_all_roi_all_z(:)==1) && ndims(roimask_all_roi_all_z)==2 && numel(szo)>2
    roimask_all_roi_all_z = ones(szo(1), szo(2), szo(3), 'logical'); %insertiung this because i don't remember why the above creates 2d rather than 3d ones
end


if remove_overlap %remove overlapping pixels
    [rw,cl,zs]=ind2sub([size(roimask_all_roi_all_z, 1), size(roimask_all_roi_all_z, 2), size(roimask_all_roi_all_z, 3)], find(sum(roimask_all_roi_all_z, 4)>1));
    for cli = 1:length(cl)
        roimask_all_roi_all_z(rw(cli), cl(cli), zs(cli), :) = 0; %why do it this way?
    end
end




end



function [chandraw, dochancp] = methodmmparse(methodmm, numchan)


switch methodmm
    case '1'
        chandraw = 1;
        dochancp = 0;
    case '2'
        chandraw = 2;
        dochancp = 0;
    case 'all'
        chandraw = 1:numchan;
        dochancp = 0;
    case '1cp'
        chandraw = 1;
        dochancp = 1;
        if numchan==1
            error("methodmm 1cp is only valid for 2-channel recordings")
        end
    case '2cp'
        chandraw = 2;
        dochancp = 1;
        if numchan==1
            error("methodmm 2cp is only valid for 2-channel recordings")
        end
end

end



