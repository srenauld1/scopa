function [roimask, mm] = roidraw(opt)

%{

do_rg
    if do_rg=1, you are using roidraw to draw an rg (region)
    by default, do_rg=1 when roidraw is called from stackcrop (the function that makes rg)
    an rg must be rectangular or cuboidal, so default roishape when do_rg=1 is 'rectangle' (but it can be changed with s-switch 
    when do_rg=1, you are limited to 1 roi (can have multiple subrois), 
    rg will be the bounding box of whatever roi you draw 

USEGIT
    if you want rg under git version control, usegit=1, otherwise usegit=0 (note if you've set glb('usegit'), usegit must match glb('usegit'), if not, just change glb('usegit') 
    if usegit=1 and internet connection fails, you will get git error, in this case you can draw rois if you make usegit=0, but note rg will have a different optid than if usegit=1 

OVERVIEW
    draw rois on interactive stack figure
    each roi can be composed of one or more subrois  
    stack background can be changed with name-value input arguments, or during roidraw with user keypresses (figure callbacks)
    figure title guides user through interactions 

INPUT ARGUMENTS 
    see docs in arguments block

OUTPUT ARGUMENTS 
    roimask 
        logical array representing spatial location of each roi
        holds all rois, if user draws on multiple channels, roimask is cell (one cell element for each channel)
        same yxz size as input stack, 4th dimension represents roi index (2d input stack, yx, will have singleton 3rd dimension, z)
        all ones if user quits roidraw without drawing anything
    mm
        struct holding roimask, and associated information (chanstr, channel, rg, and mmname)  
        if multiple channels with rois, mm is nonscalar struct, one struct element for each stack channel
        mm is saved to mat file with suffix mm_.mat, by default in folder holding stack

DRAWING ROIS
    if there are multiple z planes, click an image once to zoom in, 
    once zoomed in (or if there is only one image to begin with), click that one image to open draw tool (cursor will become fluer shape), 
    then draw according to the rules of the roishape you currently have active (reported in figure title next to 'ROISHAPE:'), 
    then adjust if you want, 
    then press return to accept or backspace to delete

WHOLE-IMAGE ROIS
    you can create subrois that occupy all pixels in a single image (z slice) by pressing shift or control while clicking on that image (it creates a rectangular subroi)
    control+click creates a single whole-image roi
    shift+click creates multiple whole-image rois, from the clicked image to the nearest whole-image roi (if none, then shift+click just creates one whole-image roi where you clicked)
    like any other roi, you can copy whole-image rois with 'c' switch, and edit with 'e' switch, etc  

ROISHAPE
    default is freestyle, but you can change roishape with 's' switch (see 'callbacks' section below)
    use roishape 'v' ('voxel') to make single-pixel rois (by clicking the voxel); for all other roishapes in roidraw, single-click will create an empty roi

ROI INDEXING 
    roi indices are incremented by user (press 'r'); can only advance to next roi if at least one subroi has been created for current roi 
    subroi indices are automatically incremented if user creates a nonempty subroi (empty doesn't count)
    while running roidraw, if the user deletes a roi or subroi, zeros take its place, so the indexing is not adjusted (eg after deleting roi 3, roi 4 remains roi 4); 
    however, upon exiting roidraw, and in any saved roi info, empty rois are removed and roi indexing is adjusted  

CALLBACKS 
    
    simple callbacks (ie single input character has meaning)

        'escape': return to previous view, if applicable (if zoomed in to draw or edit roi)
        'uparrow' & 'downarrow': change stack contrast, 'uparrow' increases (downarrow decreases) by 10% of current intensity range (not original range)
        'space' & 'leftarrow' & 'rightarrow': 'space' pause/unpause t, 'leftarrow' t backward 1 element, 'rightarrow' t forward 1 element; hold 'shift' with leftarrow or rightarrow to step 10 elements instead of 1
        'o': remove voxels from most recent subroi that overlap with any previous subrois
        'r': advance to next roi index
        'q': quit roidraw
    
    switches (ie sequence of input characters has meaning)
        
        NOTE: for all switches, the switch is turned off in one of three ways: 
            (1) a successful exit (pressing 'return' to finalize a valid output for that switch)
            (2) by pressing 'escape'
            (3) an unsuccessful exit (pressing 'return' to attempt to finalize an invalid output for that switch
        NOTE: invalid individual keys when the switch is on are just ignored, they do not turn the switch off)
        NOTE: for all switches, a sequence of digits is interpreted as a single number (separate numbers with commas or semicolon, depending on context)
        NOTE: in examples, valid symbols are represented with their names (comma, semicolon, colon, hyphen, slash)
        NOTE: in examples, arrows separate single user-input characters
        NOTE: if you make a mistake, you can press the switch init key to restart switch 
        
        valid switch keys
            valid keys for switches where user makes numeric vector(s), specifically, switches 'backspace', 'c', 'e', 't', or 'z' (just not switch 's'):
                    init key (one of the following, depending on switch): 'backspace', 'c', 'e', 't', or 'z': these turn on switch 
                    digits (a sequence of digits without comma or colon are treated as digits of the same number)
                    comma (,): to separate digits 
                    colon (:): to create numeric range (ie min:max, but two-colon format is currently not valid, ie min:increment:max does not work)
                    hyphen (-): followed by number means that number of equidistant indices
                    return: will finalize the sequence, if sequence is invalid, switch is turned off 
                        return without entering any digits will operate on all available indices
                    escape: to exit switch without any effect
                    semicolon(;): to separate vectors 
                        NOTE: semicolon is only valid for backspace-switch, where you can list multiple rois to delete                
                    slash (/): means the numeric vector the user creates in the switch will be averaged
                        NOTE: slash is only valid for t-switch and z-switch (eg to display the mean of selected z or t)
            valid keys for s-switch (s-switch is different/simpler because user inputs alphabetic char only, ie user does not make numeric vector(s)
                    's' (switch on), 
                    roishape keys ('c'=circle, 'e'=ellipse, 'f'=freestyle, 'p'=polygon, 'r'=rectangle, 'v'=voxel), 
                    'return' (finalize), 
                    'escape' (switch off)
        
        switches description
            'backspace' delete drawn roi
                format:
                    roi,subroi;roi,subroi;...roi,subroi; (list of roi(s),subroi(s)
                    rois;empty (all subrois of listed rois)
                    empty;subrois (all subrois of listed subrois)
                    empty;empty (all rois)
                    empty (all rois)
                example: 
                    backspace-->2-->comma-->3-->semicolon-->3-->comma-->1-->0-->return (delete roi 2, subroi 3 and roi 3, subroi 10)
                    backspace-->2-->colon-->3-->semicolon-->3-->comma-->1-->0-->return (delete roi 2, subroi 3 and roi 3, subroi 10)
                    backspace-->return (delete all rois)
            'c' copy most recent drawn subroi to specified z
                format: 
                    ir,irsub (ir=roi index, irsub=subroi index)
                example: 
                    e-->2-->comma-->3-->return (edit roi 2, subroi 3)
                notes:
                    each z plane a subroi is copied to counts as a separate subroi (since subroi are 2 dimensional, ie xy)
                    a roi can be copied onto a z slice that isn't shown, it just won't show it unless you change what z are shown to include that z
            'e' edit drawn roi 
                format: 
                    ir,irsub (ir=roi index, irsub=subroi index)
                example: 
                    e-->2-->comma-->3-->return (edit roi 2, subroi 3)
                notes:
                    once you've selected roi,subroi for editing, the view will "zoom in" to the z with that subroi, and it will be editable; exit edit mode with 'return' (accept subroi) or 'backspace' (delete subroi)
                    after exiting edit mode, the view, and roi.subroi index, automatically returns to state before edit mode 
            's' change roi shape
                roishapes ('shorthand'=fullname): 
                     'c'=circle, 'e'=ellipse, 'f'=freestyle, 'p'=polygon, 'r'=rectangle, 'v'=voxel
                example:
                      s-->c-->return (change roishape to circle)
                notes:
                    default roishape is freestyle
            't' change displayed t
                example:
                    t-->2-->colon-->4-->0-->return (show t 2:40)
                    t-->hyphen-->2-->0-->return (show 20 equispaced t indices across all t)
                    t-->slash-->1-->comma-->3-->comma-->5-->return (show mean of t 1,3,5)
                notes:
                    changes to t are just for display purposes (rois are not mapped to specific t indices in any way)
                    by default, only maxnt t indices can be shown; you can adjust this with name-value argument maxnt; if you request more than maxnt, your numeric vector will be truncated to have maxnt elements 
    
            'z' change displayed z
                example:
                    z-->2-->colon-->4-->return (show z 2:4)
                    z->return (show all z)
                notes:
                    a roi drawn on mean z will be placed at the z indices that went into the mean, and each z index will count as a separate subroi


TODO 
    arrows to move around in z when zoomed in 
    make whole im rois have hr struct too
    input option 'edit' to modify saved rois (save hr with structfile so there is only one file for all rois) 
    renumber rois when deleted??
    warp stack callback ('w') 
    show timeseries 
    use copy switch in edit mode
    labels on figure title that include colon, [], etc
    min:increment:max in cb_idx, rather than just min:max

%}


arguments (Input)
    opt.stack = [] %image stack for roi drawing background (can pass in stack or pthstack)
    opt.pthstack = [] %path to image stack for roi drawing background
    opt.rg = [] %region input argument 'stack' represents
    opt.mmname = 'none' %name given to roimask (roimask holds all rois drawn)
    opt.chanstr = 'all' % string giving instruction on how to use stack channels for drawing rois, can be '1', '2', 'all', '1cp', '2cp' ('1'and '2' draw on channels 1 and 2, repectively, 'all' will draw on all channels, one at a time, if multiple, '1cp' copies rois drawn on channel 1 onto 2, '2cp' copies rois drawn on channel 2 onto 1)
    opt.do_rg = 0 %flag for drawing rg (region), which is a cuboid (roishape forced rectangle, mm not saved); do_rg is true when roidraw is called from stackcrop
    opt.roishape = 'freehand'
    opt.roialpha = 0.33 %transparency for showing drawn rois over stack background
    opt.cmap = [] %colormap for showing drawn rois over stack background
    opt.maxnt = 400 %max number of frames (t) to display as background for roi drawing
    opt.remove_overlap = 0 %1 to remove overlapping pixels from all rois (so you don't have to press 'o' after every polygon, but equivalent to that); 0 will leave any overlapping voxels remaining after exiting drawing figure
    opt.cellout = 0 %1 will output roimask in cell, 0 will not (cellout=0 will error if user creates rois on more than 1 channel)
    opt.usegit = []
    opt.justload = 0 %if 0, error and exit if loading fails, if 1, draw if loading fails
end
opt = glboropt(opt);
stack = opt.stack;
pthstack = opt.pthstack;
rg = opt.rg;
mmname = opt.mmname;
chanstr = opt.chanstr;
do_rg = opt.do_rg;
roishape = opt.roishape;
roialpha = opt.roialpha;
cmap = opt.cmap;
maxnt = opt.maxnt;
remove_overlap = opt.remove_overlap;
cellout = opt.cellout;
usegit = opt.usegit;
justload = opt.justload;

fontsz = 10; %in figure title
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

if isempty(stack) && ~justload
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

iz = idxmake([], superset=nz); % z indices displayed in initial roi drawing figure (can be modified with callbacks)
it = idxmake([], superset=nt); % t indices displayed in initial roi drawing figure (can be modified with callbacks)
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
    rgname = mmname; %for making rg when do_rg is true, rgname is the mmname and make mmname empty
    mmname = [];
    roishape = 'rectangle'; %automatically set this to 1 if do_rg
else
    if isempty(rg)
        [~, rg] = stackcrop(stack, pthstack=pthstack, usegit=usegit); %if rg is empty, it's default, which is no crop, so no need to output stack, just output the default rg (full stack)
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
        fnsuffix = ['_' rgname '_' mmname '_mm'];
        pthmm = [id.pthrec, fnsuffix, '_.mat'];
        mm = load(pthmm);
    end

    for ic = chandraw
        roimask{ic} = mm(ic).mask;
    end

    if any(~isfield(mm(1), {'mask', 'mmname', 'chanstr', 'channel', 'rg'})) || numel(mm)==2 && any(~isfield(mm(2), {'mask', 'mmname', 'chanstr', 'channel', 'rg'}))
        error("mm struct must contain fields 'mask', 'mmname', 'chanstr', 'channel', 'rg'; you may have loaded an old mm struct")
    end
    if ~isequal(mm(1).rg, rg) || numel(mm)==2 && ~isequal(mm(2).rg, rg)
        error("mm file exists but for at least one channel rg in mm file does not match current rg with same name; did you delete the rg you used to draw this mm?")
    end
    sdf = structfun(@(x) diff(x)+1, rg, 'UniformOutput', false);
    if ~isequal(size(mm(ic).mask, [1 2 3]), [sdf.y, sdf.x, sdf.z])
        error("rg size does not match saved roimask size, name-value argument rg must not match rg used to draw rois")
    end
    if ~isequal(mm(1).mmname, mmname) || ~isequal(mm(1).chanstr, chanstr) || ( numel(mm)==2 && ( ~isequal(mm(2).mmname, mmname) || ~isequal(mm(2).chanstr, chanstr) ) )
        error("mm file exists but mmname and/or chanstr do not match for at least one channel")
    end
    if all(mm(1).mask==1)
        fprintf("NOTE MANUAL ROI MASK IS ALL ONES FOR rgname: " + rgname + ", mmname: " + mmname + ", channel 1: " + newline + "YOU PROBABLY CHOSE TO SKIP DRAWING" + newline)
    end
    if numel(mm)==2 && all(mm(2).mask==1)
        fprintf("NOTE MANUAL ROI MASK IS ALL ONES FOR rgname: " + rgname + ", mmname: " + mmname + ", channel 2: " + newline + "YOU PROBABLY CHOSE TO SKIP DRAWING" + newline)
    end

catch ME

    clear mm %in case old mm was loaded and errored, remove this eventually once all the old mm have been deleted

    if justload
        error("justload is true, and loading failed; you got this message when you tried to load mm: " + ME.message + newline)
    end
    fprintf(newline + "" + ME.message + newline + "mm FILE WITH ROIS MATCHING INPUT OPTIONS NOT FOUND, OPENING ROI DRAWING FIGURE" + newline)

    for ic = chandraw %some fields are redundant across channels (ie rg and mmname are the same for both channels), but for symmetry, and simpler code downstream, they're written to both channels


        %%%% PLOT STACK WITH DEFAULT z AND t, INITIALIZE PLOTTING VARIABLES %%%%

        roimask{ic} = zeros( ny, nx, nz, maxnumsubroi, maxnumroi, 'logical'); %mask for all rois, 4th dimension holds different rois
        subroirgba = []; %empty to start, gets populated later
        hr = {};

        ir = 1; %roi counter
        irsub = 1; %subroi index for current roi
        iredit = []; %index of one subroi to edit (ie roi,subroi)
        ir_o = [];
        irsub_o = [];
        iz_allpxroi_idx = []; %z indices for all-pixel rois
        iz_o = [];
        scalefac = 1; %stack intensity scale factor
        idxf = 0; % t frame counter, initialize to 0
        idxfprev = -1; %initialize with dummy value
        dmmean = [0,0,0,0,0]; %in stack plot background, whether to average each dimension (1) or not (0)
        drawflag = 0; %1 if draw tool is open (image ready for drawing rois)
        zoomflag = 0; %1 if "zoomed in" from a view with multiple z to a view with one z
        editflag = 0;
        roishape_o = [];
        alloff = 1; %all callback "switches" are off to begin
        newview = 1;
        izcopyroi = []; %z indices to copy most recent subroi onto
        iznew = []; %z indices for view change
        itnew = []; %t indices for view change
        tpauseflag = 0;
        tshift = 1;
        imselectkeys = {'shift_shift', 'control_control'}; %hold down control with image click to select entire image as roi, hold down shift with image click to select range (from nearest selected whole image, if any, otherwise same as control_control)
        cbflag = flagset({'backspace', 'c', 'e', 's', 't', 'z'}, [0,1], init=1, me=1); %set all callback flags false; struct cbflag holds mutually exclusive state switches that are set by user input while drawing figure is open, and persist until changed by user input

        [stacktmp, h, ndt] = stackshow([], [], [], stack, ir, irsub, iz, it, ic, rgname, mmname, nz, nt, nc, roishape, do_rg, fontsz, dmmean, cmap, roialpha);
        ttli_drawins = ndt+1; %title line showing drawing instructions
        ttli_switches = ndt+2; %title line showing switch state;
        ttli_lastkey = ndt+3; %title line showing last key;
        ttli_remove = 3:ndt; %title line showing last key;
        ttl_sv = h.ttl.String(ttli_remove);

        %%%% DRAWING LOOP %%%%

        while true

            currkey = ''; %reset callback key on every loop

            idxf = mod((idxf+tshift)-1, size(stacktmp,4))+1; %increment idxf;
            if ~isequal(idxf, idxfprev) % if current t changed, show the change
                for k = 1:numel(h.im.pl)
                    h.im.pl{k}.CData = stacktmp(:,:,k,idxf);
                end
                idxfprev = idxf;
                h.ttl.String{2} = regexprep(h.ttl.String{2}, 't: \d*', ['t: ' num2str(it(idxf))]);
            end
            if tpauseflag
                tshift = 0;
            end

            for k = 1:numel(h.im.ol) %capture axis click to start roi draw on that axis (we loop over ol, which is image overlay, rather than image itself, because in stackplt dool is true (to allow roi overlays to be drawn in ol)
                if ~isempty(h.im.ol{k}.UserData)
                    roi_on_mean_z = 0;
                    h.im.ol{k}.UserData = [];
                    if any(strcmp(h.fg.UserData, imselectkeys))
                        if strcmp(h.fg.UserData, 'shift_shift') && numel(iz_allpxroi_idx)>0
                            [~, nearestz] = min(abs(iz_allpxroi_idx - iz(k)));
                            if iz(k)<iz_allpxroi_idx(nearestz)
                                iz_allpxroi_idx_new = iz(k):iz_allpxroi_idx(nearestz); %append range, then take unique below
                            else
                                iz_allpxroi_idx_new = iz_allpxroi_idx(nearestz)+1:iz(k); %append range, then take unique below
                            end
                        else
                            iz_allpxroi_idx_new = iz(k);
                        end
                        iz_allpxroi_idx = unique(sort([iz_allpxroi_idx iz_allpxroi_idx_new]));
                        h.fg.UserData = [];
                        subroinew = ones(ny,nx,'logical');
                        if isscalar(h.im.ol) && numel(iz)>1
                            roi_on_mean_z = 1;
                        end
                        roiinfotmp = {'rectangle', hrtmp.Position};
                        [h, roimask, hr, subroirgba, h.ttl.String, irsub] = subroiadd(h, subroinew, hr, roiinfotmp, roimask, ic, ir, irsub, cmap, roialpha, iz, roi_on_mean_z, h.ttl.String, [], iz_allpxroi_idx_new); % add drawn subroi and show as overlay
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
                            else %if multiple axes, on first click zoomflag=1 and we "zoom into" clicked axes; on second click drawflag=1 and we begin drawing
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
                        h.ttl.String{ttli_lastkey} = 'NO ROIS TO DELETE';
                    else
                        h.ttl.String{ttli_switches} = 'backspace SWITCH ON, ENTER ROI INDICES TO DELETE (SEE roidraw.m DOCS FOR FORMAT)';
                        [cbflag, irdel, h.ttl.String{ttli_lastkey}] = cb_idx(currkey, superset=1:maxnumroi, veclenmax=maxnumroi); %veclen 2 because each vec is [roi,subroi]
                        if ~isempty(irdel)
                            [hr, roimask, h.ttl.String{ttli_lastkey}, success] = roidel(irdel, hr, roimask, ic);
                            if success
                                [h, roimask, hr, subroirgba, h.ttl.String] = subroiadd(h, [], [], [], roimask, ic, ir, irsub, cmap, roialpha, iz, roi_on_mean_z, h.ttl.String, [], iz); % here, we copy drawn subroi to z slices izroi (and axfocus is empty)
                            end
                        end
                    end

                elseif cbflag.c || ( alloff && strcmp(currkey, 'c') ) %copy roi to other z (include the alloff to prevent a context key in one sequence from initializing a different sequence)
                    if irsub==1
                        h.ttl.String{ttli_lastkey} = 'CANNOT USE c SWITCH BECAUSE YOU HAVE NOT DRAWN ANY SUBROIS FOR THE CURRENT ROI';
                    else
                        h.ttl.String{ttli_switches} = 'c SWITCH ON, ENTER z INDICES TO COPY ROI';
                        [cbflag, izcopyroi, h.ttl.String{ttli_lastkey}] = cb_idx(currkey, superset=1:nz, numvec=1, dounique=1);
                    end

                elseif cbflag.e || ( alloff && strcmp(currkey, 'e') ) %copy roi to other z (include the alloff to prevent a context key in one sequence from initializing a different sequence)
                    if ir==1 && irsub==1
                        h.ttl.String{ttli_lastkey} = 'NO ROIS TO EDIT';
                    else
                        h.ttl.String{ttli_switches} = 'e SWITCH ON, ENTER SUBROI TO EDIT IN FORMAT roi,subroi';
                        [cbflag, iredit, h.ttl.String{ttli_lastkey}] = cb_idx(currkey, superset=1:maxnumroi, numvec=1, veclenmax=2); %veclen 2 because each vec is [roi,subroi]
                        if ~isempty(iredit)
                            sumz = sum(roimask{ic}(:,:,:,iredit(2),iredit(1)), [1,2]); %subroi comes before roi in roimask
                            if any(sumz(:))
                                drawflag = 1;
                                editflag = 1;
                                axfocus = 1; %this is always 1 now because we "zoom in" to the axes you click on
                                iz_o = iz;  %save current iz to return to after drawing on the zoomed in axes (or if there's just one axes, this won't hurt either)
                                ir_o = ir;
                                irsub_o = irsub;
                                roishape_o = roishape;
                                iznew = unique(find(sumz));
                                ir = iredit(1);
                                irsub = iredit(2);
                                roishape = hr{iredit(1),iredit(2)}{1};
                                if numel(iznew)>1
                                    roi_on_mean_z = 1;
                                end
                                for k = 1:numel(h.ttl.String)
                                    h.ttl.String{k} = regexprep(h.ttl.String{k}, 'ROISHAPE: "\w+"', ['ROISHAPE: "' roishape '"']);
                                end
                            else
                                h.ttl.String{ttli_lastkey} = ['CANNOT EDIT ROI,SUBROI ' mat2str([iredit(2),iredit(1)]) ' BECAUSE IT IS EMPTY'];
                            end
                        end
                    end

                elseif cbflag.s || ( alloff && strcmp(currkey, 's') )  %s sequence; change roi shape (include the alloff to prevent a context key in one sequence from initializing a different sequence)
                    h.ttl.String{ttli_switches} = 's SWITCH ON, CHANGE DRAW TOOL: c (circle), e (ellipse), f (freehand), p (polygon), r (rectangle), v (voxel)';
                    [cbflag, roishape_new, h.ttl.String{ttli_lastkey}] = cb_roishape(currkey);
                    if ~isempty(roishape_new)
                        roishape = roishape_new;
                        roishape_new = []; %not necessary since persistent variables in cb_roishape get cleared on exit, but for clarity let's leave this here
                        if do_rg
                            h.ttl.String{ttli_lastkey} = cat(2, h.ttl.String{ttli_lastkey}, 'NOTE do rg IS TRUE SO rg WILL BE xyz BOUNDING BOX OF DRAWN ROI');
                        end
                        for k = 1:numel(h.ttl.String)
                            h.ttl.String{k} = regexprep(h.ttl.String{k}, 'ROISHAPE: "\w+"', ['ROISHAPE: "' roishape '"']);
                        end
                    end

                elseif cbflag.t || ( alloff && strcmp(currkey, 't') )  %t sequence; change shown t (include the alloff to prevent a context key in one sequence from initializing a different sequence)
                    h.ttl.String{ttli_switches} = 't SWITCH ON, ENTER T INDICES';
                    [cbflag, itnew, h.ttl.String{ttli_lastkey}, dm, domean] = cb_idx(currkey, superset=1:nt, numvec=1, veclenmax=maxnt); %don't dounique in case user wants to see repeated frames
                    if ~isempty(itnew) %only nonempty when exiting cb_idx successfully
                        dmmean(dm) = domean;
                    end

                elseif cbflag.z || ( alloff && strcmp(currkey, 'z') )  %z sequence; change shown z (include the alloff to prevent a context key in one sequence from initializing a different sequence)
                    h.ttl.String{ttli_switches} = 'z SWITCH ON, ENTER Z INDICES';
                    [cbflag, iznew, h.ttl.String{ttli_lastkey}, dm, domean] = cb_idx(currkey, superset=1:nz, numvec=1, dounique=1); %dounique for z indices because having repeated z makes roi accounting complicated, and it's probably pointless anyway (but repeated t might be useful)
                    if ~isempty(iznew)  %only nonempty when exiting cb_idx successfully
                        dmmean(dm) = domean;
                    end

                elseif any(strcmp(currkey, {'downarrow', 'uparrow'})) %adjust image contrast (not roi rgba)
                    if strcmpi(currkey, 'uparrow')
                        cshift = -0.1;
                    else
                        cshift = 0.1;
                    end
                    scalefac = scalefac + cshift;
                    for k = 1:numel(h.im.ax)
                        clim = h.im.ax{k}.CLim(2) + h.im.ax{k}.CLim(2)*cshift;
                        if clim<h.im.ax{k}.CLim(1)
                            clim = h.im.ax{k}.CLim(1);
                        end
                        h.im.ax{k}.CLim(2) = clim;
                    end
                    h.ttl.String{ttli_lastkey} = [currkey ', RESCALED CONTRAST ' num2str(-1*round((scalefac - 1)*100)) ' %'];

                elseif strcmp(currkey, 'escape') %return to previous view
                    [drawflag, iznew, zoomflag, editflag, roishape, roishape_o, ir, irsub] = escapefun(zoomflag, editflag, iz_o, roishape_o, ir_o, irsub_o, roishape, ir, irsub);

                elseif any(strcmp(currkey, {'leftarrow', 'rightarrow', 'leftarrow_shift', 'rightarrow_shift'})) %shift t backward or forward
                    if tpauseflag
                        if endsWith(currkey, '_shift')
                            currkey = erase(currkey, '_shift');
                            modkey = 'shift';
                        else
                            modkey = [];
                        end
                        if strcmpi(currkey, 'leftarrow')
                            tshift = -1;
                            h.ttl.String{ttli_lastkey} = [currkey ', t BACKWARD'];
                        else
                            tshift = 1;
                            h.ttl.String{ttli_lastkey} = [currkey ', t FORWARD'];
                        end
                        if strcmp(modkey, 'shift')
                            tshift = tshift*10;
                            h.ttl.String{ttli_lastkey} = cat(2, h.ttl.String{ttli_lastkey}, ' 10 elements');
                        end
                    end


                elseif strcmp(currkey, 'o') %remove pixels in current roi that belong to any other rois
                    if ir<2 || ( ir==2 && irsub==1 )
                        h.ttl.String{ttli_lastkey} = 'NO OVERLAP TO REMOVE';
                    else
                        h.ttl.String{ttli_lastkey} = 'o, REMOVING ANY VOXELS FROM CURRENT SUBROI THAT OVERLAP WITH PREVIOUS ROIS';
                        [~,~,~,i4,i5] = ind2sub(size(roimask{ic}), find(roimask{ic}, 1, 'last'));
                        overlaps = logical(sum(roimask{ic}(:,:,:,:,1:i5-1), [4,5])) + roimask{ic}(:,:,:,i4,i5) > 1; %mask of all previous rois plus mask of current subroi gives us overlaps (we don't care about other subrois in current roi, they won't affect result since they are grouped anyway)
                        roimask{ic}(:,:,:,i4,i5) = roimask{ic}(:,:,:,i4,i5).*~overlaps; %zero overlaps
                        [h, roimask, hr, subroirgba, h.ttl.String] = subroiadd(h, [], [], [], roimask, ic, ir, irsub, cmap, roialpha, iz, roi_on_mean_z, h.ttl.String, axfocus, []); % here, we copy drawn subroi to z slices izroi (and axfocus is empty)
                    end

                elseif strcmp(currkey, 'q') %quit
                    h.ttl.String{ttli_lastkey} = 'q, QUIT';
                    h.ttl.String = roiinc(h.ttl.String, ir);
                    break;

                elseif strcmp(currkey, 'r') %increment roi (if at least one subroi exists for current roi)
                    if do_rg
                        h.ttl.String{ttli_lastkey} = 'CANNOT ADVANCE TO NEXT ROI BECAUSE do_rg=1 (YOU ARE LIMITED TO ONE ROI, BUT IT CAN HAVE MULTIPLE SUBROIS)';
                    else
                        if irsub==1
                            h.ttl.String{ttli_lastkey} = ['CANNOT ADVANCE TO NEXT ROI BECAUSE YOU HAVE NOT DRAWN A SUBROI FOR ROI ' num2str(ir)];
                        else
                            h.ttl.String{ttli_lastkey} = 'r, ADVANCED TO NEXT ROI';
                            [h.ttl.String, ir, irsub, iz_allpxroi_idx] = roiinc(h.ttl.String, ir);
                        end
                    end

                elseif strcmp(currkey, 'space') %pause t, until leftarrow or rightarrow
                    if tpauseflag
                        tpauseflag = 0; %unpause t
                        tshift = 1;
                        h.ttl.String{ttli_lastkey} = 'spacebar, UNPAUSED t';
                    else
                        tpauseflag = 1; %pause t
                        tshift = 0;
                        h.ttl.String{ttli_lastkey} = 'spacebar, PAUSED t (leftarrow=BACKWARDS,rightarrow=FORWARDS)';
                    end

                elseif any(strcmp(currkey, {'z_shift', 'z_shift_control', 'z_control_shift'})) %quit
                    if ~isscalar(h.im.ol) 
                        h.ttl.String{ttli_lastkey} = 'YOU MUST ZOOM IN TO ONE Z PLANE TO SCROLL Z WITH shift z OR shift control z';
                    elseif isequal(nz, 1)
                        h.ttl.String{ttli_lastkey} = 'STACK HAS ONLY ONE Z PLANE, SO YOU CANNOT SCROLL Z WITH shift z OR shift control z';
                    else
                        if any(strcmp(currkey, {'z_shift_control', 'z_control_shift'}))
                            h.ttl.String{ttli_lastkey} = 'shift & control & z, DECREASING Z';
                            zshift = -1;
                        else
                            h.ttl.String{ttli_lastkey} = 'shift & z, INCREASING Z';
                            zshift = 1;
                        end
                        iznew = mod(iz+zshift-1, nz)+1;
                    end

                else
                    h.ttl.String{ttli_lastkey} = 'INVALID KEY';
                end

                alloff = all(~cellfun(@(x) isequal(x,1), struct2cell(cbflag))); % check whether all switches off
                if alloff
                    h.ttl.String{ttli_switches} = 'ALL SWITCHES OFF';
                end

            end

            if ~isempty(iznew) || ~isempty(itnew)
                if ~isempty(iznew)
                    iz = iznew;
                else
                    it = itnew;
                end
                iznew = [];
                itnew = [];
                [stacktmp, h] = stackshow(h, subroirgba, roimask, stack, ir, irsub, iz, it, ic, rgname, mmname, nz, nt, nc, roishape, do_rg, fontsz, dmmean, cmap, roialpha);
                newview = 1;
            elseif ~isempty(izcopyroi) %izcopyroi only used for c-switch (roi copy)
                roi_on_mean_z_dummy = 0; %make roi_on_mean_z=0 because it must be false when copying rois (doesn't make sense to copy to a mean)
                [h, roimask, hr, subroirgba, h.ttl.String, irsub] = subroiadd(h, subroinew, hr, roiinfotmp, roimask, ic, ir, irsub, cmap, roialpha, iz, roi_on_mean_z_dummy, h.ttl.String, [], izcopyroi); % here, we copy drawn subroi to z slices izroi (and axfocus is empty)
                izcopyroi = [];
            end

            if drawflag
                h.ttl.String(ttli_remove) = cell(1,numel(ttli_remove));
                h.ttl.String{ttli_remove(1)} = 'CALLBACKS DISABLED WHEN DRAW TOOL OPEN';
                if editflag
                    h.ttl.String{ttli_switches} = ['e SWITCH ON, EDITING ROI ' num2str(iredit(1)) ' SUBROI ' num2str(iredit(1))];
                else
                    h.ttl.String{ttli_switches} = 'ALL SWITCHES OFF';
                end
                ttl_tmp = '';
                if roi_on_mean_z
                    ttl_tmp = ', WILL COPY TO Z COMPRISING MEAN IMAGE';
                end
                if do_rg
                    h.ttl.String{ttli_drawins} = ['DRAW "' roishape '" (XY CROSS-SECTION OF rg "' rgname '")' ttl_tmp ', ESCAPE=CLOSE DRAW TOOL'];
                else
                    h.ttl.String{ttli_drawins} = ['DRAW "' roishape '"' ttl_tmp ', ESCAPE=CLOSE DRAW TOOL'];
                end

                switch roishape %ordered by use probability
                    case 'freehand'
                        if editflag
                            hrtmp = drawfreehand(h.im.ax{axfocus}, Position=hr{iredit(1),iredit(2)}{2});
                        else
                            hrtmp = drawfreehand(h.im.ax{axfocus});
                        end
                    case 'polygon'
                        if editflag
                            hrtmp = drawpolygon(h.im.ax{axfocus}, Position=hr{iredit(1),iredit(2)}{2});
                        else
                            hrtmp = drawpolygon(h.im.ax{axfocus});
                        end
                    case 'rectangle'
                        if editflag
                            hrtmp = drawrectangle(h.im.ax{axfocus}, Position=hr{iredit(1),iredit(2)}{2});
                        else
                            hrtmp = drawrectangle(h.im.ax{axfocus});
                        end
                    case 'ellipse'
                        if editflag
                            hrtmp = drawellipse(h.im.ax{axfocus}, Center=hr{iredit(1),iredit(2)}{2}, SemiAxes=hr{iredit(1),iredit(2)}{3}, RotationAngle=hr{iredit(1),iredit(2)}{4});
                        else
                            hrtmp = drawellipse(h.im.ax{axfocus});
                        end
                    case 'circle'
                        if editflag
                            hrtmp = drawcircle(h.im.ax{axfocus}, Center=hr{iredit(1),iredit(2)}{2}, Radius=hr{iredit(1),iredit(2)}{3});
                        else
                            hrtmp = drawcircle(h.im.ax{axfocus});
                        end
                    case 'voxel'
                        if editflag
                            hrtmp = drawfreehand(h.im.ax{axfocus}, Position=hr{iredit(1),iredit(2)}{2}); %use freehand as dummy tool for "voxel" tool, since single click produces empty roi for all above draw tools, and we want to follow those rules
                        else
                            hrtmp = drawfreehand(h.im.ax{axfocus});
                        end
                    otherwise
                        error("invalid roishape")
                end
                h.ttl.String{ttli_drawins} = 'MOUSE=ADJUST, BACKSPACE=DELETE, RETURN=ACCEPT';
                while true
                    if ~isempty(h.fg.UserData) %capture key press on figure callback
                        currkey2 = h.fg.UserData;
                        h.fg.UserData = [];
                        if strcmp(currkey2 , 'return')
                            break
                        elseif strcmp(currkey2 , 'escape')
                            if isempty(hrtmp.Position) % hrtmp.Position will be empty if you hit escape before drawing anything
                                drawflag = 0;
                                hrtmp = [];
                                break
                            end
                        elseif strcmp(currkey2 , 'backspace')
                            if ~isempty(hrtmp.Position) %  if you drew something but want to delete it before hitting enter
                                if editflag %if you're editing, and you hit escape (ie delete the recovered subroi), you have to delete it from roimask too
                                    [hr, roimask, h.ttl.String{ttli_lastkey}, success] = roidel({iredit}, hr, roimask, ic); %put iredit in cell for roidel
                                    if success
                                        [h, roimask, hr, subroirgba, h.ttl.String] = subroiadd(h, [], [], [], roimask, ic, ir, irsub, cmap, roialpha, iz, roi_on_mean_z, h.ttl.String, [], iz); % here, we copy drawn subroi to z slices izroi (and axfocus is empty)
                                    else
                                        error("you should not arrive here")
                                    end
                                end
                                delete(hrtmp)
                                pause(0.1) %without this pause the draw tool disappears after escape
                            end
                            hrtmp = [];
                            break
                        end
                    end
                    pause(0.05)
                end
                if ~isempty(hrtmp)  %skip if it's an empty roi, or you pressed escape
                    if strcmp(roishape, 'voxel')
                        subroinew = createMask_voxel(hrtmp, ny, nx);
                    else
                        subroinew = createMask(hrtmp, h.im.pl{axfocus});
                    end
                    if any(subroinew, 'all') %this catches 'single-click' empty rois (except roishape 'voxel' which allows single-click rois)
                        if strcmp(roishape, 'circle')
                            roiinfotmp = {roishape, hrtmp.Center, hrtmp.Radius};
                        elseif strcmp(roishape, 'ellipse')
                            roiinfotmp = {roishape, hrtmp.Center, hrtmp.SemiAxes, hrtmp.RotationAngle};
                        else
                            roiinfotmp = {roishape, hrtmp.Position};
                        end
                        [h, roimask, hr, subroirgba, h.ttl.String, irsub] = subroiadd(h, subroinew, hr, roiinfotmp, roimask, ic, ir, irsub, cmap, roialpha, iz, roi_on_mean_z, h.ttl.String, axfocus, []); % add drawn subroi and show as overlay
                    end
                    delete(hrtmp)
                    hrtmp = [];
                end
                if editflag %force escape edit mode after editing previously drawm roi, to simplify control flow
                    [drawflag, iznew, zoomflag, editflag, roishape, roishape_o, ir, irsub] = escapefun(zoomflag, editflag, iz_o, roishape_o, ir_o, irsub_o, roishape, ir, irsub);
                end
                if ~drawflag %when exiting this drawflag clause, change title
                    h.ttl.String{ttli_drawins} = ''; %this is not strictly necessary, just so it's empty during the brief pause when zooming out
                    h.ttl.String(ttli_remove) = ttl_sv;
                end
            else %if not drawflag, just display some different titles (when newview, so we don't do it repeatedly)
                if newview
                    if isscalar(h.im.ol)
                        h.ttl.String{ttli_drawins} = 'CLICK IMAGE=OPEN DRAW TOOL';
                        if zoomflag
                            h.ttl.String{ttli_drawins} = [h.ttl.String{ttli_drawins} ', ESCAPE=LAST VIEW'];
                        end
                    else
                        h.ttl.String{ttli_drawins} = 'CLICK IMAGE=ZOOM';
                    end
                    h.ttl.String{ttli_drawins} = [h.ttl.String{ttli_drawins} ', CNTRL+CLICK IMAGE=WHOLE-IMAGE SUBROI, SHIFT+CLICK IMAGE=WHOLE-IMAGE SUBROI RANGE'];
                    newview = 0;
                end
            end

            pause(0.05); %pause for callbacks and figure updates

        end

        h.ttl.String = "CLOSING FIGURE IN 2 SECONDS";
        pause(2)
        close(h.fg);

        %%%% ARRANGE MASK %%%%

        if any(roimask{ic}(:))

            roimask{ic} = squeeze(logical(sum(roimask{ic}, 4))); %sum subroi dimension

            if ndims(roimask{ic})==3 %if singleton z, roimask will become 3d after above squeeze, so insert singleton z
                roimask{ic} = reshape(roimask{ic}, size(roimask{ic},1),  size(roimask{ic},2),  1,  size(roimask{ic},3));
            end
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
        mm(ic).mmname = mmname;
        mm(ic).chanstr = chanstr;
        mm(ic).channel = ic;
        mm(ic).rg = rg; %save the region (rg) the masks were drawn on, in case the region changes but its name stays the same

        if dochancp
            chanreceive = setdiff(1:nc, ic);
            fprintf("name-value argument 'chanstr' ends with 'cp', COPYING ANY DRAWN ROIS FROM CHANNEL " + num2str(ic) + " ONTO CHANNEL " + num2str(chanreceive) + newline);
            roimask{chanreceive} = roimask{ic};
            mm(chanreceive).mask = roimask{ic};
            mm(chanreceive).mmname = mmname;
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

function [stacktmp, h, ndt] = stackshow(h, subroirgba, roimask, stack, ir, irsub, iz, it, ic, rgname, mmname, nz, nt, nc, roishape, do_rg, fontsz, dmmean, cmap, roialpha)

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

if any(dmmean) %we display the mean of stack dimensions corresponding to nonzero elements in vector dmmean
    stacktmp = stacktype(mean(stacktmp, find(dmmean)), class(stacktmp));
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
        h = fg(fontsz=fontsz, szf=1, alignh='left');
    end
    h = axim(stacktmp, h=h, ax=ax, dool=1, doui=1, cmap=gray(256), ydir='reverse', axidx=1); % axidx = 1 so we don't accumulate axes in this figure handle
else
    for k = 1:numel(h.im.pl)
        h.im.pl{k}.CData = stacktmp(:,:,k); %here just first index in any additional dimensions
    end
end

if ~isempty(subroirgba) %when redrawing the stack, also redraw any existing rois, subroirgba saves them in correct locations, regardless of which parts of the stack are displayed
    if ismember(3, find(dmmean)) %if z dimension is averaged, we must average rgba (if it exists)
        [imrgb_meanz, imalpha_meanz] = roiolmake(roimask=squeeze(any(roimask{ic}(:,:,iz(:),:,:), [3,4])), rgb=cmap, a=roialpha); %
        h.im.ol{1}.CData = squeeze(imrgb_meanz); %rgb image
        h.im.ol{1}.AlphaData = imalpha_meanz; %transparency image,
    else
        for k = 1:numel(h.im.ol)
            h.im.ol{k}.CData = squeeze(subroirgba(:,:,iz(k),1:3)); %rgb image for axes iz(k)
            h.im.ol{k}.AlphaData = subroirgba(:,:,iz(k),4); %transparency image for axes iz(k)
        end
    end
end

[h, ndt] = titlemake(h, ic, rgname, mmname, ir, irsub, iz, it, nz, nt, roishape, do_rg, fontsz, dmmean);

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

function [h, ndt] = titlemake(h, ic, rgname, mmname, ir, irsub, iz, it, nz, nt, roishape, do_rg, fontsz, dmmean)

max_num_iz_to_print = 10;
if isequal(iz, 1:nz)
    title_z = [',   Z: [' num2str(iz(1)) ':' num2str(iz(end)) ']'];
else
    if numel(iz)<=max_num_iz_to_print
        title_z = [',   Z: ' mat2str(iz)];
    else
        tmpprint = sprintf('%d,', iz(1:3));
        tmpprint2 = sprintf('%d,', iz(end-2:end));
        title_z = [',   Z: [' tmpprint(1:end-1) '...' tmpprint2(1:end-1) ']'];
    end
end
if isequal(dmmean(3),1)
    title_z = [title_z ' MEAN'];
end

title_t = ',   t: 1'; % 1 is dummy value that gets replaced on each drawing loop
if isequal(dmmean(4),1)
    if isequal(it, 1:nt)
        title_t = ',   t: ALL MEAN';
    else
        title_t = ',   t: SUBSET MEAN';
    end
end

if do_rg
    ttltmp = {
        ['DRAWING: rg: "' rgname '",   ROI ' num2str(ir) ',   SUBROI ' num2str(irsub) '",   ROISHAPE: "' roishape '"'];
        ['SHOWING: STACK (NO rg),   CHANNEL: ' num2str(ic) title_z title_t]
        };
else
    ttltmp = {
        ['DRAWING:   ROI ' num2str(ir) ',   SUBROI ' num2str(irsub) ',   IN MMNAME: "' mmname '",   ROISHAPE: "' roishape '"'];
        ['SHOWING:   STACK rg: "' rgname '",   CHANNEL: ' num2str(ic) title_z title_t]
        };
end

h.ttl.String = ttltmp;

ttltmp = { [...
    'BUTTONS:   ', ...
    'escape: LAST VIEW,   ', ...
    'r: NEXT ROI,   ', ...
    'space/left/right: t (UN)PAUSE/BACK/FORWARD,   ', ...
    'shift (control) z : z up (down),   ', ...
    'up/down: CONTRAST,   ', ...
    'o: REMOVE OVERLAP,   ', ...
    'q: QUIT,   ', ...
    ]};
h.ttl.String = cat(1, h.ttl.String, ttltmp);

ttltmp = { [...
    'SWITCHES:   ', ...
    'backspace: DELETE ROI(S)   ', ...
    'c: COPY CURRENT SUBROI TO z,   ', ...
    'e: EDIT SUBROI,   ', ...
    's: CHANGE ROISHAPE,   ', ...
    't: CHANGE t,   ', ...
    'z: CHANGE z,   ', ...
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
    ttl{k} = regexprep(ttl{k}, ' ROI \d+', [' ROI ' num2str(ir)]); %distinguish subroi from roi with space first
    ttl{k} = regexprep(ttl{k}, 'SUBROI \d+', ['SUBROI ' num2str(irsub)]);
end

end


function [h, roimask, hr, subroirgba, ttl, irsub] = subroiadd(h, subroinew, hr, roiinfotmp, roimask, ic, ir, irsub, cmap, roialpha, iz, roi_on_mean_z, ttl, axfocus, izroi)

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
        hr{ir,irsub} = roiinfotmp; %save what we need in case we want to edit roi later
        irsub = irsub+1; %increment subroi counter for current roi
    end
    for k = 1:numel(ttl)
        ttl{k} = regexprep(ttl{k}, 'SUBROI \d+', ['SUBROI ' num2str(irsub)]);
    end
end

[imrgb, imalpha] = roiolmake(roimask=squeeze(any(roimask{ic}, 4)), rgb=cmap, a=roialpha); %
subroirgba = cat(4, imrgb, imalpha); %add rgba, we use this elsewhere, so compute even if roi_on_mean_z

if roi_on_mean_z
    [imrgb_meanz, imalpha_meanz] = roiolmake(roimask=squeeze(any(roimask{ic}(:,:,iz(:),:,:), [3,4])), rgb=cmap, a=roialpha); %
    h.im.ol{1}.CData = squeeze(imrgb_meanz); %rgb image
    h.im.ol{1}.AlphaData = imalpha_meanz; %transparency image,
else
    for k = 1:numel(axfocus)
        h.im.ol{axfocus(k)}.CData = squeeze(imrgb(:,:,iz(axfocus(k)),:)); %rgb image
        h.im.ol{axfocus(k)}.AlphaData = imalpha(:,:,iz(axfocus(k))); %transparency image,
    end
end

end


function [hr, roimask, ttl, success] = roidel(irdel, hr, roimask, ic)

success = 0;
if ~iscell(irdel)
    if isvector(irdel)
        irdeltmp = cell(1,2);
        irdeltmp{1} = irdel;
        irdeltmp{2} = 1:size(roimask{ic},4);
        irdel = irdeltmp;
    else
        ttl = 'IRDEL SHOULD BE CELL VECTOR OR ORDINARY VECTOR';
        return
    end
end
if any(~cell2mat(cellfun(@(x) isequal(numel(x),2), irdel, 'UniformOutput', false))) %if format is not roi,subroi;roi,subroi
    if numel(irdel)~=2 % . . . then format is empty;empty, or rois;empty, or empty;subrois length must be 2
        ttl = 'ROI INDICES FOR DELETION MUST BE IN FORMAT ROI,SUBROI;ROI,SUBROI..., OR ROIS;EMPTY, OR EMPTY;SUBROIS';
        return
    end
    allsubrois = isequal(sort(irdel{2}), 1:size(roimask{ic},4));  %all rois for each subroi listed
    allrois = isequal(sort(irdel{1}), 1:size(roimask{ic},5));  %all subrois for each roi listed
    if allrois && allsubrois %all subrois for each roi listed
        roimask{ic}(:) = 0;
        hr = {};
        ttl = 'DELETED ALL ROIS (backspace SWITCH OUTPUT EMPTY)';
    elseif allsubrois %all subrois for each roi listed
        for k = 1:numel(irdel{1})
            roimask{ic}(:,:,:,:,irdel{1}(k)) = 0;
            hr{irdel{1}(k)} = [];
        end
        if numel(irdel{1})<6
            tmpprint = sprintf('%d,', irdel{1}); %to remove trailing comma
            ttl = ['DELETED ALL SUBROIS FROM ROI(S) [' tmpprint(1:end-1) '], (backspace SWITCH OUTPUT NONEMPTY;EMPTY)'];
        else
            ttl = ['DELETED ALL SUBROIS FROM ' num2str(numel(irdel{1})) ' ROIS, (backspace SWITCH OUTPUT NONEMPTY;EMPTY)'];
        end
    elseif allrois
        for k = 1:numel(irdel{2})
            roimask{ic}(:,:,:,irdel{2}(k),:) = 0;
            for q = 1:size(roimask{ic},5) %have to loop for this one
                hr{q,irdel{2}(k)} = [];
            end
        end
        if numel(irdel{2})<6
            tmpprint = sprintf('%d,', irdel{2}); %to remove trailing comma
            ttl = ['DELETED SUBROI(S) [' tmpprint(1:end-1) '] FROM ALL ROIS (backspace SWITCH OUTPUT EMPTY;NONEMPTY)'];
        else
            ttl = ['DELETED ' num2str(numel(irdel{2})) ' SUBROIS FROM ALL ROIS (backspace SWITCH OUTPUT EMPTY;NONEMPTY)'];
        end
    else
        ttl = 'INVALID FORMAT FOR backspace SWITCH';
        return
    end
else
    for k = 1:numel(irdel)
        roimask{ic}(:,:,:,irdel{k}(2),irdel{k}(1)) = 0; %subroi comes before roi in roimask
        hr{irdel{k}(1),irdel{k}(2)} = [];
    end
    if numel(irdel)<6
        tmpprint = sprintf('[%d,%d],', irdel{:}); %to remove trailing comma
        ttl = ['DELETED [ROI,SUBROI] ' tmpprint(1:end-1) ' (backspace SWITCH OUTPUT NONEMPTY;NONEMPTY)'];
    else
        ttl = ['DELETED ' num2str(numel(irdel)) ' SUBROIS FROM ALL ROIS (backspace SWITCH OUTPUT NONEMPTY;NONEMPTY)'];
    end
end
success = 1;

end

function subroinew = createMask_voxel(hrtmp, ny, nx)

hrtmp.Position = round(hrtmp.Position);
if hrtmp.Position(1)>nx %position is xy, not yx
    hrtmp.Position(1)=nx;
end
if hrtmp.Position(2)>ny %position is xy, not yx
    hrtmp.Position(2)=ny;
end
hrtmp.Position(hrtmp.Position<1) = 1;
subroinew = zeros( ny, nx, 'logical');
subroinew(hrtmp.Position(2), hrtmp.Position(1)) = 1;

end

function [drawflag, iznew, zoomflag, editflag, roishape, roishape_o, ir, irsub] = escapefun(zoomflag, editflag, iz_o, roishape_o, ir_o, irsub_o, roishape, ir, irsub)

drawflag = 0;
iznew = [];
if zoomflag || editflag
    iznew = iz_o;
    if zoomflag
        zoomflag = 0;
    elseif editflag
        editflag = 0;
        roishape = roishape_o;
        roishape_o = [];
        ir = ir_o;
        irsub = irsub_o;
    end
end

end