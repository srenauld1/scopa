function [roimask, mm] = roidraw(opt)

%{

draw rois on interactive stack figure
stack background can be changed with name-value input arguments, or during roidraw with user keypresses (figure callbacks)
each roi can br comprised of one or multiple subrois (polygons)

output arguments 
    roimask 
        logical array representing spatial location of each roi
        holds all rois, if user draws on multiple channels, roimask is cell (one cell element for each channel)
        same yxz size as input stack, 4th dimension represents roi index (2d input stack, yx, will have singleton 3rd dimension, z)
        all ones if user quits roidraw without drawing anything
    mm
        struct holding roimask, and associated information (chanstr, channel, rg, and maskname)  
        if multiple channels with rois, mm is nonscalar struct, one struct element for each stack channel
        mm is saved to mat file with suffix mm_.mat, by default in folder holding stack

callbacks 
    simple callbacks
        uparrow/downarrow: adjust stack contrast
        o: remove voxels from most recent polygon that overlap with any previous polygons
        backspace: delete last polygon
        r: advance to the next roi
        q: quit roi drawing
    sequence callbacks
        t for modifying displayed t
        z for modifying displayed z
        c for projecting most recent drawn polygon to specified z
        after initializing with t, z, or c, the following keys are valid
            digits (a sequence of digits without comma or colon are treated as digits of the same number)
            comma (,) to separate indices 
            colon (:) to indicate range 
            hyphen (-) followed by number means that number of equidistant indices
            slash (/) followed by indices will display the mean of those indices
                slash is not a valid key for c-sequence (doesn't make sense to copy onto a mean)
            return will finalize the sequence, if sequence is invalid, switch remains on but input is erased 
                return without any digits will operate on all shown indices 
        examples:
            t300:400,909return
                show stack t indices [300:400, 909]
            z/3,5,7return
                show mean of stack z 3,5,7
            t/-30return
                show mean of 30 equidistant stack t
            c-3return
                copy most recent drawn subroi (polygon) to 3 "equidistant" z from 1:maxz
            preturn
                copy most recent drawn subroi (polygon) onto all shown z
                

a roi drawn on mean z will be placed at the z indices that went into the mean 
a roi can be projected onto a z slice that isn't shown, it will not error, it just won't show it (unless you change what z are shown to include that z)
changes to t are just for display purposes (rois are not mapped to specific t indices in any way)

TODO: input ir to modify selected saved rois
TODO: different drawing tools (circle, rectangle, paintbrush)
TODO: modify already drawn roi
TODO: min:increment:max in cb_idx, rather than just min:max

%}


arguments
    opt.stack = [] %image stack for roi drawing background (can pass in stack or pthstack)
    opt.pthstack = [] %path to image stack for roi drawing background
    opt.rg = [] %region input argument 'stack' represents
    opt.maskname = 'none' %name given to roimask (roimask holds all rois drawn)
    opt.chanstr = 'all' % string giving instruction on how to use stack channels for drawing rois, can be '1', '2', 'all', '1cp', '2cp' ('1'and '2' draw on channels 1 and 2, repectively, 'all' will draw on all channels, one at a time, if multiple, '1cp' copies rois drawn on channel 1 onto 2, '2cp' copies rois drawn on channel 2 onto 1)
    opt.do_oneroi = 0 %automatically exit roi drawing figure after completing one roi
    opt.do_rg = 0 %flag for drawing rg (region), which is a cuboid (roishape forced rectangle, mm not saved); do_rg is true when roidraw is called from stackcrop
    opt.roishape = 'freehand'
    opt.roialpha = 0.33 %transparency for showing drawn rois over stack background
    opt.cmap = [] %colormap for showing drawn rois over stack background
    opt.maxnt = 400 %max number of frames (t) to display as background for roi drawing
    opt.remove_overlap = 0 %1 to remove overlapping pixels from all rois (so you don't have to press 'o' after every polygon, but equivalent to that); 0 will leave any overlapping voxels remaining after exiting drawing figure
    opt.cellout = 0 %1 will output roimask in cell, 0 will not (cellout=0 will error if user creates rois on more than 1 channel)
end
opt = glboropt(opt);
stack = opt.stack;
pthstack = opt.pthstack;
cellout = opt.cellout;
rg = opt.rg;
chanstr = opt.chanstr;
maskname = opt.maskname;
do_oneroi = opt.do_oneroi;
do_rg = opt.do_rg;
roishape = opt.roishape;
roialpha = opt.roialpha;
cmap = opt.cmap;
remove_overlap = opt.remove_overlap;
maxnt = opt.maxnt;

fontsz = 12; %in figure title
maxnumroi = 50; %just for preallocating
maxnumsubroi = 50; %just for preallocating; max number of discontiguous subrois per roi

clear cb_idx cb_roishape

callstack = dbstack('-completenames');
fcnm = [];
if numel(callstack) >= 2
    fcnm = callstack(2).file;
    [~, fcnm] = fileparts(fcnm);
end
if isequal(fcnm, 'stackcrop') && ~isequal(do_rg,1)
    error("do_rg must be true when calling roidraw from stackcrop")
end

if isempty(stack)
    if isempty(pthstack)
        error("if name-value argument stack is empty, name-value argument pthstack must be nonempty")
    end
    stack = stackld(odf('sld', unpack=1), pthstack);
end
nd = ndims(stack);
if nd<2 || nd>5
    error("stack input to roidraw must have 2-5 dimensions")
end

[ny, nx, nz, nt, nc] = size(stack);

if ~cellout && nc>1
    error("cellout must be true when there are multiple channels, since there is one cell (roimask) for each channel")
end

iz = indsmake([], indsall=nz); % z indices displayed in initial roi drawing figure (can be modified with callbacks)
it = indsmake([], indsall=nt); % t indices displayed in initial roi drawing figure (can be modified with callbacks)
if numel(it)>maxnt
    it = it(1:maxnt);
end

if isempty(cmap)
    cmap = brewermap(maxnumroi, 'Dark2');
end
if roialpha<=0
    error("roialpha must be positive")
end

if do_rg
    rgname = maskname; %for making rg when do_rg is true, rgname is the maskname and make maskname empty
    maskname = [];
    do_oneroi = 1; %automatically set this to 1 if do_rg
    roishape = 'rectangle'; %automatically set this to 1 if do_rg
else
    if isempty(rg)
        [~, rg] = stackcrop(stack, pthstack=pthstack); %if rg is empty, it's default, which is no crop, so no need to output stack, just output the default rg (full stack)
    end
    rgname = rg.rgname;
end

[chandraw, dochancp] = chanstrparse(chanstr, nc);

roimask = cell(nc,1); %needs to be cell in case 2-channel with different number rois

try

    if do_rg
        error("skip loading mm since do_rg is true")
    else
        id = idmake(pthstack);
        fnsuffix = ['_' rgname '_' maskname '_mm'];
        pthmm = [id.pthrec, fnsuffix, '_.mat'];
        mm = load(pthmm);
    end

    for ic = chandraw
        roimask{ic} = mm(ic).mask;
    end

    if any(~isfield(mm(1), {'mask', 'maskname', 'chanstr', 'channel', 'rg'})) || numel(mm)==2 && any(~isfield(mm(2), {'mask', 'maskname', 'chanstr', 'channel', 'rg'}))
        error("mm struct must contain fields 'mask', 'maskname', 'chanstr', 'channel', 'rg'; you may have loaded an old mm struct")
    end
    if ~isequal(mm(1).rg, rg) || numel(mm)==2 && ~isequal(mm(2).rg, rg)
        error("mm file exists but for at least one channel rg in mm file does not match current rg with same name; did you delete the rg you used to draw this mm?")
    end
    sdf = structfun(@(x) diff(x)+1, rg, 'UniformOutput', false);
    if ~isequal(size(mm(ic).mask, [1 2 3]), [sdf.y, sdf.x, sdf.z])
        error("rg size does not match saved roimask size, name-value argument rg must not match rg used to draw rois")
    end
    if ~isequal(mm(1).maskname, maskname) || ~isequal(mm(1).chanstr, chanstr) || ( numel(mm)==2 && ( ~isequal(mm(2).maskname, maskname) || ~isequal(mm(2).chanstr, chanstr) ) )
        error("mm file exists but maskname and/or chanstr do not match for at least one channel")
    end
    if all(mm(1).mask==1)
        fprintf("NOTE MANUAL ROI MASK IS ALL ONES FOR rgname: " + rgname + ", maskname: " + maskname + ", channel 1: " + newline + "YOU PROBABLY CHOSE TO SKIP DRAWING" + newline)
    end
    if numel(mm)==2 && all(mm(2).mask==1)
        fprintf("NOTE MANUAL ROI MASK IS ALL ONES FOR rgname: " + rgname + ", maskname: " + maskname + ", channel 2: " + newline + "YOU PROBABLY CHOSE TO SKIP DRAWING" + newline)
    end

catch ME

    clear mm %in case old mm was loaded and errored, remove this eventually once all the old mm have been deleted

    if isempty(stack)
        error("input stack is empty, and since mm file doens't exist, or is invalid, you cannot create mm; you got this message when you tried to load mm: " + ME.message + newline)
    end
    fprintf(newline + "" + ME.message + newline + "mm FILE WITH ROIS MATCHING INPUT OPTIONS NOT FOUND, OPENING ROI DRAWING FIGURE" + newline)

    for ic = chandraw %some fields are redundant across channels (ie rg and maskname are the same for both channels), but for symmetry, and simpler code downstream, they're written to both channels


        %%%% PLOT STACK WITH DEFAULT z AND t, INITIALIZE PLOTTING VARIABLES %%%%

        roimask{ic} = zeros( ny, nx, nz, maxnumsubroi, maxnumroi, 'logical'); %mask for all rois, 4th dimension holds different rois
        subroirgba = []; %empty to start, gets populated later

        ir = 1; %roi counter
        irsub = 1; %subroi index for current roi
        iz_allpxroi_idx = []; %z indices for all-pixel rois
        scalefac = 1; %stack intensity scale factor
        idxf = 0; % t frame counter, initialize to 0
        idxfprev = -1; %initialize with dummy value
        dmslash = [0,0,0,0,0]; %in stack plot background, whether to average each dimension (1) or not (0)
        drawflag = 0; %1 if draw tool is open (image ready for drawing rois)
        zoomflag = 0; %1 if "zoomed in" from a view with multiple z to a view with one z
        alloff = 1; %all callback "switches" are off to begin
        izcopyroi = []; %z indices to copy most recent subroi onto
        iznew = []; %z indices for view change
        itnew = []; %t indices for view change
        imselectkeys = {'shift_shift', 'control_control'}; %hold down control with image click to select entire image as roi, hold down shift with image click to select range (from nearest selected whole image, if any, otherwise same as control_control)
        cbflag = flagset({'backspace', 'c', 's', 't', 'z'}, [0,1], init=1, me=1); %set all callback flags false; struct cbflag holds mutually exclusive state switches that are set by user input while drawing figure is open, and persist until changed by user input

        [stacktmp, h, ndt] = stackshow([], [], [], stack, ir, irsub, iz, it, ic, rgname, maskname, nz, nt, nc, roishape, do_rg, do_oneroi, fontsz, dmslash, cmap, roialpha);
        ttli_drawins = ndt+1; %title line showing drawing instructions
        ttli_switches = ndt+2; %title line showing switch state;
        ttli_lastkey = ndt+3; %title line showing last key;
        ttli_remove = 2:ndt; %title line showing last key;
        ttl_sv = h.ttl.String(ttli_remove);
        h.ttl.String{ttli_switches} = 'ALL SWITCHES OFF';

        %%%% DRAWING LOOP %%%%

        while true
            while true

                currkey = ''; %reset callback key on every loop

                idxf = mod(idxf, size(stacktmp,4))+1; %increment idxf; same as mod((idxf+1)-1, size(stacktmp,4))+1
                if ~isequal(idxf, idxfprev) % if current t changed, show the change
                    for k = 1:numel(h.im.pl)
                        h.im.pl{k}.CData = stacktmp(:,:,k,idxf);
                    end
                    idxfprev = idxf;
                end

                % h.ttl.String{ttli_drawins} = ['CLICK IMAGE TO SELECT ALL PIXELS' ttl_tmp ', ESCAPE=CLOSE DRAW TOOL'];

                if ~drawflag
                    if isscalar(h.im.ol)
                        h.ttl.String{ttli_drawins} = 'CLICK IMAGE=OPEN DRAW TOOL';
                        if zoomflag
                            h.ttl.String{ttli_drawins} = [h.ttl.String{ttli_drawins} ', ESCAPE=LAST VIEW'];
                        end
                    else
                        h.ttl.String{ttli_drawins} = 'CLICK IMAGE=ZOOM';
                    end
                end

                for k = 1:numel(h.im.ol) %capture axis click to start roi draw on that axis (we loop over ol, which is image overlay, rather than image itself, because in stackplt dool is true (to allow roi overlays to be drawn in ol)
                    if ~isempty(h.im.ol{k}.UserData)
                        roi_on_mean_z = 0;
                        h.im.ol{k}.UserData = [];
                        if any(strcmp(h.fg.UserData, imselectkeys))
                            if strcmp(h.fg.UserData, 'shift_shift') && numel(iz_allpxroi_idx)>1
                                [~, nearestz] = min(abs(iz_allpxroi_idx - k));
                                if k<iz_allpxroi_idx(nearestz)
                                    tmprng = k:iz_allpxroi_idx(nearestz);
                                else
                                    tmprng = iz_allpxroi_idx(nearestz):k;
                                end
                                iz_allpxroi_idx = [iz_allpxroi_idx tmprng]; %append range, then take unique below
                            else
                                iz_allpxroi_idx = sort([iz_allpxroi_idx k]);
                            end
                            iz_allpxroi_idx = unique(iz_allpxroi_idx);
                            h.fg.UserData = [];
                            subroinew = ones(ny,nx,'logical');
                            if isscalar(h.im.ol) && numel(iz)>1
                                roi_on_mean_z = 1;
                            end
                            [h, roimask, subroirgba, h.ttl.String, irsub] = subroiadd(h, subroinew, roimask, ic, ir, irsub, cmap, roialpha, iz, roi_on_mean_z, h.ttl.String, iz_allpxroi_idx, []); % add drawn subroi and show as overlay
                        else
                            axfocus = 1; %this is always 1 now because we "zoom in" to the axes you click on
                            if ~drawflag %on first axes click, do below, on second, don't do below, but do drawing further below (but don't put that clause in here because we don't want to have to click for every subroi on same image)
                                if ~zoomflag
                                    iz_o = iz;  %save current iz to return to after drawing on the zoomed in axes (or if there's just one axes, this won't hurt either)
                                end
                                if isscalar(h.im.ol) %if there's only one axes, no need to zoom in then select to draw, just one click to draw
                                    drawflag = 1;
                                    if numel(iz)>1
                                        roi_on_mean_z = 1;
                                    end
                                else %if multiple axes on first click (drawflag==1), we just zoom into clicked axes; on second click, we begin drawing
                                    zoomflag = 1;
                                    iznew = k;
                                end
                            end
                        end
                    end
                end

                if ~isempty(h.fg.UserData) && ~any(strcmp(h.fg.UserData, imselectkeys)) %capture key press on figure callback;

                    currkey = h.fg.UserData;
                    h.fg.UserData = [];

                    if cbflag.backspace || ( alloff && strcmp(currkey, 'backspace') ) %delete selected rois

                        if ir==1 && irsub==1
                            h.ttl.String{ttli_lastkey} = 'NOTHING TO DELETE';
                        else
                            [cbflag, irdel, h.ttl.String{ttli_lastkey}] = cb_idx(currkey, ir, maxnumroi);
                            if ~isempty(irdel)
                                irdel = flip(irdel); %since roimask dim order is subroi then roi, but backspace sequence is roi then subroi
                                if any(roimask{ic}(:,:,:,irdel{:}), [1,2,3])
                                    roimask{ic}(:,:,:,irdel{:}) = 0;
                                    h.ttl.String{ttli_lastkey} = ['backspace, DELETED ROI ' mat2str(irdel{2}) ', SUBROI ' mat2str(irdel{1}) ' (IF NONEMPTY)'];
                                else
                                    h.ttl.String{ttli_lastkey} = ['ALREADY EMPTY IN SET ROI ' mat2str(irdel{2}) ', SUBROI ' mat2str(irdel{1})];
                                end
                            end
                        end

                    elseif cbflag.c || ( alloff && strcmp(currkey, 'c') ) %copy roi to other z (include the alloff to prevent a context key in one sequence from initializing a different sequence)
                        if irsub==1
                            h.ttl.String{ttli_lastkey} = 'CANNOT USE c SWITCH BECAUSE YOU HAVE NOT DRAWN ANY SUBROIS FOR THE CURRENT ROI';
                        else
                            h.ttl.String{ttli_switches} = 'c SWITCH ON, ENTER z INDICES TO COPY ROI';
                            [cbflag, izcopyroi, h.ttl.String{ttli_lastkey}] = cb_idx(currkey, nz);
                        end

                    elseif cbflag.s || ( alloff && strcmp(currkey, 's') )  %s sequence; change roi shape (include the alloff to prevent a context key in one sequence from initializing a different sequence)
                        h.ttl.String{ttli_switches} = 's SWITCH ON, CHANGE DRAW TOOL: c (circle), e (ellipse), f (freehand), p (polygon), r (rectangle)';
                        [cbflag, roishape_new, h.ttl.String{ttli_lastkey}] = cb_roishape(currkey);
                        if ~isempty(roishape_new)
                            roishape = roishape_new;
                            roishape_new = []; %not necessary since persistent variables in cb_roishape get cleared on exit, but for clarity let's leave this here 
                            if do_rg
                                h.ttl.String{ttli_lastkey} = cat(2, h.ttl.String{ttli_lastkey}, 'NOTE do rg IS TRUE SO rg WILL BE xyz BOUNDING BOX OF DRAWN ROI');
                            end
                            for k = 1:numel(h.ttl.String)
                                h.ttl.String{k} = regexprep(h.ttl.String{k}, 'SHAPE: "\w+"', ['SHAPE: ' roishape ',']);
                            end
                        end

                    elseif cbflag.t || ( alloff && strcmp(currkey, 't') )  %t sequence; change shown t (include the alloff to prevent a context key in one sequence from initializing a different sequence)
                        h.ttl.String{ttli_switches} = 't SWITCH ON, ENTER T INDICES';
                        [cbflag, itnew, h.ttl.String{ttli_lastkey}, dmslash] = cb_idx(currkey, nt, maxnt, dmslash);

                    elseif cbflag.z || ( alloff && strcmp(currkey, 'z') )  %z sequence; change shown z (include the alloff to prevent a context key in one sequence from initializing a different sequence)
                        h.ttl.String{ttli_switches} = 'z SWITCH ON, ENTER Z INDICES';
                        [cbflag, iznew, h.ttl.String{ttli_lastkey}, dmslash] = cb_idx(currkey, nz, [], dmslash);

                    elseif any(strcmp(currkey, {'downarrow', 'uparrow'})) %adjust image contrast (not roi rgba)
                        if strcmpi(currkey, 'uparrow')
                            tmpd = -0.1;
                        else
                            tmpd = 0.1;
                        end
                        scalefac = scalefac + tmpd;
                        for k = 1:numel(h.im.ax)
                            clim = h.im.ax{k}.CLim(2) + h.im.ax{k}.CLim(2)*tmpd;
                            if clim<h.im.ax{k}.CLim(1)
                                clim = h.im.ax{k}.CLim(1);
                            end
                            h.im.ax{k}.CLim(2) = clim;
                        end
                        h.ttl.String{ttli_lastkey} = [currkey ', RESCALED CONTRAST ' num2str(-1*round((scalefac - 1)*100)) ' %'];

                    elseif strcmp(currkey, 'escape') %return to previous view
                        drawflag = 0;
                        if zoomflag %~isequal(iz, iz_o)
                            iznew = iz_o;
                            zoomflag = 0;
                        end

                    elseif strcmp(currkey, 'o') %remove pixels in current roi that belong to any other rois
                        if ir<2 || ( ir==2 && irsub==1 )
                            h.ttl.String{ttli_lastkey} = 'NO OVERLAP TO REMOVE';
                        else
                            h.ttl.String{ttli_lastkey} = 'o, REMOVING ANY VOXELS FROM CURRENT SUBROI THAT OVERLAP WITH PREVIOUS ROIS';
                            [i1,i2,i3,i4,i5] = ind2sub(size(roimask{ic}), find(roimask{ic}, 1, 'last'));
                            overlaps = logical(sum(roimask{ic}(:,:,:,:,1:i5-1), [4,5])) + roimask{ic}(:,:,:,i4,i5) > 1; %mask of all previous rois plus mask of current subroi gives us overlaps (we don't care about other subrois in current roi, they won't affect result since they are grouped anyway)
                            roimask{ic}(:,:,:,i4,i5) = roimask{ic}(:,:,:,i4,i5).*~overlaps; %zero overlaps
                            [h, roimask, subroirgba, h.ttl.String] = subroiadd(h, [], roimask, ic, ir, irsub, cmap, roialpha, iz, roi_on_mean_z, h.ttl.String, axfocus, []); % here, we copy drawn subroi to z slices izroi (and axfocus is empty)
                        end

                    elseif strcmp(currkey, 'q') %quit
                        h.ttl.String{ttli_lastkey} = 'q, QUIT';
                        h.ttl.String = roiinc(h.ttl.String, ir);
                        break;

                    elseif strcmp(currkey, 'r') %increment roi
                        if do_oneroi
                            h.ttl.String{ttli_lastkey} = 'CANNOT ADVANCE TO NEXT ROI BECAUSE YOU ARE LIMITED TO ONE ROI';
                        else
                            h.ttl.String{ttli_lastkey} = 'r, ADVANCED TO NEXT ROI';
                            [h.ttl.String, ir, irsub, iz_allpxroi_idx] = roiinc(h.ttl.String, ir);
                        end

                    else
                        h.ttl.String{ttli_lastkey} = 'INVALID KEY';
                    end

                    alloff = all(~cellfun(@(x) isequal(x,1), struct2cell(cbflag))); %all switches off
                    if alloff
                        h.ttl.String{ttli_switches} = 'ALL SWITCHES OFF';
                    end

                end

                if ~isempty(izcopyroi) %izcopyroi only used for c-sequence (roi copy)
                    roi_on_mean_z_dummy = 0; %make roi_on_mean_z=0 because it must be false when copying rois (doesn't make sense to copy to a mean)
                    [h, roimask, subroirgba, h.ttl.String, irsub] = subroiadd(h, subroinew, roimask, ic, ir, irsub, cmap, roialpha, iz, roi_on_mean_z_dummy, h.ttl.String, [], izcopyroi); % here, we copy drawn subroi to z slices izroi (and axfocus is empty)
                    izcopyroi = [];
                elseif ~isempty(iznew) || ~isempty(itnew)
                    if ~isempty(iznew)
                        iz = iznew;
                    else
                        it = itnew;
                    end
                    iznew = [];
                    itnew = [];
                    [stacktmp, h] = stackshow(h, subroirgba, roimask, stack, ir, irsub, iz, it, ic, rgname, maskname, nz, nt, nc, roishape, do_rg, do_oneroi, fontsz, dmslash, cmap, roialpha);
                end

                if drawflag
                    h.ttl.String(ttli_remove) = [];
                    h.ttl.String{2} = 'CALLBACKS DISABLED WHEN DRAW TOOL OPEN';
                    ttl_tmp = '';
                    if roi_on_mean_z
                        ttl_tmp = ', WILL COPY TO Z COMPRISING MEAN IMAGE';
                    end
                    if do_rg
                        h.ttl.String{ttli_drawins} = ['DRAW "' roishape '" (XY CROSS-SECTION OF rg "' rgname '")' ttl_tmp ', ESCAPE=CLOSE DRAW TOOL'];
                    else
                        h.ttl.String{ttli_drawins} = ['DRAW "' roishape '"' ttl_tmp ', ESCAPE=CLOSE DRAW TOOL'];
                    end
                    switch roishape
                        case 'circle'
                            hr = drawcircle(h.im.ax{axfocus});
                        case 'ellipse'
                            hr = drawellipse(h.im.ax{axfocus});
                        case 'freehand'
                            hr = drawfreehand(h.im.ax{axfocus});
                        case 'polygon'
                            hr = drawpolygon(h.im.ax{axfocus});
                        case 'rectangle'
                            hr = drawrectangle(h.im.ax{axfocus});
                        otherwise
                            error("invalid roishape")
                    end
                    h.ttl.String{ttli_drawins} = 'MOUSE=ADJUST, ESCAPE=DELETE, RETURN=ACCEPT';
                    while true
                        if ~isempty(h.fg.UserData) %capture key press on figure callback
                            currkey2 = h.fg.UserData;
                            h.fg.UserData = [];
                            if strcmp(currkey2 , 'return')
                                break
                            elseif  strcmp(currkey2 , 'escape') %hr will be empty if you hit escape
                                if isempty(hr.Position)
                                    drawflag = 0;
                                else
                                    delete(hr)
                                    hr = [];
                                    pause(0.1) %without this pause the draw tool disappears after escape
                                    break
                                end
                                break
                            end
                        end
                        pause(0.05)
                    end
                    if ~isempty(hr) && ~isempty(hr.Position) %if it's not an empty roi, which can be created by mistake, or by pressing escape to close drawing tool
                        hr.InteractionsAllowed = 'none'; %disallow any more changes
                        hr.Visible = 'off'; %make border and waypoints invisible (face alpha created in subroiadd below)
                        subroinew = createMask(hr, h.im.pl{axfocus});
                        [h, roimask, subroirgba, h.ttl.String, irsub] = subroiadd(h, subroinew, roimask, ic, ir, irsub, cmap, roialpha, iz, roi_on_mean_z, h.ttl.String, axfocus, []); % add drawn subroi and show as overlay
                    end
                    if ~drawflag
                        h.ttl.String{ttli_drawins} = ''; %this is not strictly necessary, just so it's empty during the brief pause when zooming out
                        h.ttl.String(ttli_remove) = ttl_sv;
                    end
                end

                pause(0.05); %pause for callbacks and figure updates

            end
            break;
        end

        h.ttl.String = "CLOSING THIS FIGURE IN 2 SEC";
        pause(2)
        close(h.fg);

        %%%% ARRANGE MASK %%%%

        if any(roimask{ic}(:))

            roimask{ic} = logical(sum(roimask{ic}, 4)); %sum subroi dimension

            kp = any(reshape(roimask{ic}, [], size(roimask{ic}, 4))); %find nonempty rois, this works for 2d, 3d, 4d
            if ~all(kp)
                roimask{ic} = roimask{ic}(:,:,:,kp); %remove empty "rois", this works for 2d, 3d, 4d
            end

            if remove_overlap %remove voxels from rois that overlap with rois drawn earlier
                for k = flip(1:size(roimask{ic},4))  %go backwards through foreground rois to zero voxels that overlap with any rois drawn earlier
                    overlaps = sum(roimask{ic},4)>1; %compute the sum after each overlap removal, so we don't remove all rois contributing to overlap
                    roimask{ic}(:,:,:,k) = roimask{ic}(:,:,:,k).*~overlaps; %zero overlap by multiplying by inverse mask
                end
            end

            if ~islogical(roimask{ic})
                roimask{ic} = logical(roimask{ic}); %just to be sure
            end

        else

            roimask{ic} = ones(ny, nx, nz, 'logical'); %otherwise just ones

        end


        %%%% ASSEMBLE mm STRUCT %%%%

        mm(ic).mask = roimask{ic};
        mm(ic).maskname = maskname;
        mm(ic).chanstr = chanstr;
        mm(ic).channel = ic;
        mm(ic).rg = rg; %save the region (rg) the masks were drawn on, in case the region changes but its name stays the same

        if dochancp
            chanreceive = setdiff(1:nc, ic);
            fprintf("name-value argument 'chanstr' ends with 'cp', COPYING ANY DRAWN ROIS FROM CHANNEL " + num2str(ic) + " ONTO CHANNEL " + num2str(chanreceive) + newline);
            roimask{chanreceive} = roimask{ic};
            mm(chanreceive).mask = roimask{ic};
            mm(chanreceive).maskname = maskname;
            mm(chanreceive).chanstr = chanstr;
            mm(chanreceive).channel = chanreceive;
            mm(chanreceive).rg = rg; %save the region (rg) the masks were drawn on, in case the region changes but its name stays the same
        end

    end

    %%%% SAVE %%%%

    if ~do_rg
        if chandraw==1 && nc==2 %do this so that 2-channel data gets empty 2nd element if channel 2 has no rois, otherwise 2nd element wouldn't exist, which would mislead user into thinking it's single-channel data
            mm(2) = structfun(@(x) [], mm, 'UniformOutput', false);
        end
        save(pthmm, '-struct', 'mm', '-v7.3', '-mat') %save each channel's mask separately (could do it together instead, either way is fine right?)
    end

end

if ~cellout
    roimask = cell2mat(roimask);
end


end

function [stacktmp, h, ndt] = stackshow(h, subroirgba, roimask, stack, ir, irsub, iz, it, ic, rgname, maskname, nz, nt, nc, roishape, do_rg, do_oneroi, fontsz, dmslash, cmap, roialpha)

idxstr = repmat({':'}, 1, 5); %do it this way in case we are only modifying one dimension, indexing with all elements of unchanged dimensions is costly
if ~isequal(iz, 1:nz)
    idxstr{3} = iz;
end
if ~isequal(it, 1:nt)
    idxstr{4} = it;
end
if ~isequal(ic, 1:nc)
    idxstr{5} = ic;
end

if isequal(idxstr, {':', ':', ':', ':', ':'})
    stacktmp = stack; % don't create different stacktmp if it matches the original stack indices (although stacktmp does get created even if it matches current stacktmp, so we could put it catch for this)
else
    stacktmp = stack(idxstr{:});
end

if any(dmslash) %we display the mean of stack dimensions corresponding to nonzero elements in vector dmslash
    stacktmp = stacktype(mean(stacktmp, find(dmslash)), class(stacktmp));
end

changeaxes = 1; %only change the axes if number of z slices to show has changed
if ~isempty(h)
    if isequal(size(stacktmp,3), numel(h.im.ax))
        changeaxes = 0;
    end
end

if changeaxes
    ax = axarr(stacktmp, marginax=0.01, marginfg=[0, 0.2, 0.01, 0.01], stackjust='mid');
    if isempty(h)
        h = fg(fontsz=fontsz, szf=1);
    end
    h = axim(stacktmp, h=h, ax=ax, dool=1, doui=1, cmap=gray(256), ydir='reverse', axidx=1); % axidx = 1 so we don't accumulate axes in this figure handle
else
    for k = 1:numel(h.im.pl)
        h.im.pl{k}.CData = stacktmp(:,:,k); %here just first index in any additional dimensions
    end
end

if ~isempty(subroirgba) %when redrawing the stack, also redraw any existing rois, subroirgba saves them in correct locations, regardless of which parts of the stack are displayed
    if ismember(3, find(dmslash)) %if z dimension is averaged, we must average rgba (if it exists)
        [imrgb_meanz, imalpha_meanz] = roiolmake(roimask=squeeze(any(roimask{ic}(:,:,iz(:),:,:), [3,4])), col=cmap, alp=roialpha); %
        h.im.ol{1}.CData = squeeze(imrgb_meanz); %rgb image
        h.im.ol{1}.AlphaData = imalpha_meanz; %transparency image,
    else
        for k = 1:numel(h.im.ol)
            h.im.ol{k}.CData = squeeze(subroirgba(:,:,iz(k),1:3)); %rgb image for axes iz(k)
            h.im.ol{k}.AlphaData = subroirgba(:,:,iz(k),4); %transparency image for axes iz(k)
        end
    end
end

[h, ndt] = titlemake(h, ic, rgname, maskname, ir, irsub, iz, it, nz, nt, roishape, do_rg, do_oneroi, fontsz, dmslash);

end

function [chandraw, dochancp] = chanstrparse(chanstr, nc)

switch chanstr
    case '1'
        chandraw = 1;
        dochancp = 0;
    case '2'
        chandraw = 2;
        dochancp = 0;
    case 'all'
        chandraw = 1:nc;
        dochancp = 0;
    case '1cp'
        chandraw = 1;
        dochancp = 1;
        if nc==1
            error("chanstr 1cp is only valid for 2-channel recordings")
        end
    case '2cp'
        chandraw = 2;
        dochancp = 1;
        if nc==1
            error("chanstr 2cp is only valid for 2-channel recordings")
        end
    otherwise
        error("chanstr must be '1', '2', 'all', '1cp', or '2cp'")
end

end

function [h, ndt] = titlemake(h, ic, rgname, maskname, ir, irsub, iz, it, nz, nt, roishape, do_rg, do_oneroi, fontsz, dmslash)

if isequal(iz, 1:nz)
    title_z = ',   Z ALL';
else
    title_z = ',   Z SUBSET';
end
if isequal(dmslash(3),1)
    title_z = [title_z ' MEAN'];
end
if isequal(it, 1:nt)
    title_t = ',   T ALL';
else
    title_t = ',   T SUBSET';
end
if isequal(dmslash(4),1)
    title_t = [title_t ' MEAN'];
end

if do_rg
    ttltmp = {['DRAWING rg: "' rgname '"']; ['SHOWING STACK (NO rg),   CHANNEL: ' num2str(ic) title_z title_t]};
else
    ttltmp = {['DRAWING ROI #' num2str(ir) ', SUBROI #' num2str(irsub) ', FOR MASKNAME: "' maskname '", SHAPE: "' roishape '"']; ['SHOWING STACK rg: "' rgname '",   CHANNEL: ' num2str(ic) title_z title_t]};
end

h.ttl.String = ttltmp;

if do_oneroi
    ttltmp = { [...
        'q: QUIT,   ', ...
        ]};
else
    ttltmp = { [...
        'q: QUIT,   ', ...
        'r: NEXT ROI,   ', ...
        ]};
end
h.ttl.String = cat(1, h.ttl.String, ttltmp);

ttltmp = { [...
    'up/down: CONTRAST,   ', ...
    'o: REMOVE OVERLAP,   ', ...
    ]};
h.ttl.String{end} = cat(2, h.ttl.String{end}, ttltmp{1}); %cat this one along same line, so we don't have to repeat this in the if else above

ttltmp = { [...
    'backspoace: DELETE ROI   ', ...
    'c: COPY SUBROI TO z,   ', ...
    's: CHANGE SHAPE,   ', ...
    't: ADJUST t,   ', ...
    'z: ADJUST z,   ', ...
    ]};
h.ttl.String = cat(1, h.ttl.String, ttltmp);

ndt = numel(h.ttl.String); %number of lines in title initially
h.ttl.FontSize = fontsz;

end

function [ttl, ir, irsub, iz_allpxroi_idx] = roiinc(ttl, ir)

ir = ir + 1; %increment roi counter
irsub = 1; %reset subroi counter to 1
iz_allpxroi_idx = [];
for k = 1:numel(ttl)
    ttl{k} = regexprep(ttl{k}, ' ROI #\d+', [' ROI #' num2str(ir)]); %distinguish subroi from roi with space first
    ttl{k} = regexprep(ttl{k}, 'SUBROI #\d+', ['SUBROI #' num2str(irsub)]);
end

end


function [h, roimask, subroirgba, ttl, irsub] = subroiadd(h, subroinew, roimask, ic, ir, irsub, cmap, roialpha, iz, roi_on_mean_z, ttl, axfocus, izroi)


if isempty(axfocus)
    if roi_on_mean_z
        axfocus = 1;
    else
        axfocus = find(ismember(iz, izroi));
    end
elseif isempty(izroi)
    if roi_on_mean_z
        izroi = iz;
    else
        izroi = iz(axfocus);
    end
end

if ~isempty(subroinew)
    for k = 1:numel(izroi)
        roimask{ic}(:,:,izroi(k),irsub,ir) = subroinew; %add subroi or roi
        irsub = irsub+1; %increment subroi counter for current roi
    end

    [imrgb, imalpha] = roiolmake(roimask=squeeze(any(roimask{ic}, 4)), col=cmap, alp=roialpha); %
    subroirgba = cat(4, imrgb, imalpha); %add rgba, we use this elsewhere, so compute even if roi_on_mean_z

    if roi_on_mean_z
        [imrgb_meanz, imalpha_meanz] = roiolmake(roimask=squeeze(any(roimask{ic}(:,:,iz(:),:,:), [3,4])), col=cmap, alp=roialpha); %
        h.im.ol{1}.CData = squeeze(imrgb_meanz); %rgb image
        h.im.ol{1}.AlphaData = imalpha_meanz; %transparency image,
    else
        for k = 1:numel(axfocus)
            h.im.ol{axfocus(k)}.CData = squeeze(imrgb(:,:,iz(axfocus(k)),:)); %rgb image
            h.im.ol{axfocus(k)}.AlphaData = imalpha(:,:,iz(axfocus(k))); %transparency image,
        end
    end

    for k = 1:numel(ttl)
        ttl{k} = regexprep(ttl{k}, 'SUBROI #\d+', ['SUBROI #' num2str(irsub)]);
    end
end

end

