function [roimask, mm] = roidraw(s, opt)

%{

CHANNELS
    currently, roidraw operates on one channel at a time, but should have option to change channel as callback just like the other dimensions

dorg
    if dorg=1, you are using roidraw to draw an rg (region)
    by default, dorg=1 when roidraw is called from stackcrop (the function that makes rg)
    an rg must be rectangular or cuboidal, so default roishape when dorg=1 is 'rectangle' (but it can be changed with s-switch 
    when dorg=1, you are limited to 1 roi (can have multiple subrois), 
    rg will be the bounding box of whatever roi you draw 

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
        struct holding roimask, and associated information (chanstr, channel, rg, and roiname)  
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
    min:increment:max in cb_array, rather than just min:max
    show multiple channels and ic callback for changing channel 
    make it more convenient to adjust spacing in titles

WARNING 
    there is currently not a way of ensuring input arguments 'stack' and 'rg' match (rg is a cropped version of a stack); 
    for example, you could make an 'rg' and pass it into this function as argument 'stack', but pass a different rg into this function as argument 'rg'
    the code does make sure the rg size matches the input 'stack' size, but if you pass in mismatched stack and rg of the same sizes, this mistake will not be caught
    an improvement might make stack a struct throughout a2p (rather than an ordinary numeric array) with the image stack as one field, and the rg data as another field, but i haven't done this
    nevertheless, the code still tries to match stack and rg in the saved roi data because we do need to know what images rois were drawn on

%}


arguments (Input)

    s %struct output from function stackld (contains stack, md, pthstack, rg, and other fields)
    
    opt.roiname {mustBeTextScalar} = '' %name given to output roimask (and by extension, saved struct mm, whichg holds roimask); this is the name of the set of rois you are drawing in this call to roidraw; if empty, default name is 'none'
    opt.chanstr {mustBeTextScalar, mustBeNonempty} = 'all' % string giving instruction on how to use stack channels for drawing rois, can be '1', '2', 'all', '1cp', '2cp' ('1'and '2' draw on channels 1 and 2, repectively, 'all' will draw on all channels, one at a time, if multiple, '1cp' copies rois drawn on channel 1 onto 2, '2cp' copies rois drawn on channel 2 onto 1)
    opt.roishape {mustBeTextScalar, mustBeNonempty} = 'freehand' %name of draw tool, can be changed with figure callback; circle, ellipse, freehand, polygon, rectangle, voxel (voxel is single click on image to make single-voxel roi)
    opt.roialpha (1,1) double {mustBePositive, mustBeLessThanOrEqual(opt.roialpha,1)} = 0.33 %transparency for showing drawn rois over stack background
    opt.cmap (:,3) double = [] %colormap for showing drawn rois over stack background; empty will use a default colormap
    opt.rmolap (1,1) {mustBeMember(opt.rmolap,[0,1])} = 0 %1 to remove overlapping pixels from all rois (so you don't have to press 'o' after every subroi is drawn, but equivalent to that callback applied after every subroi is drawn); 0 will leave any overlapping voxels remaining after exiting drawing figure
    opt.cellout (1,1) {mustBeMember(opt.cellout,[0,1])} = 0 %1 will output roimask in cell, 0 will not (cellout=0 will error if user creates rois on more than 1 channel)
    opt.nosave (1,1) {mustBeMember(opt.nosave,[0,1])} = 0 %1 to skip saving drawn rois, 0 to save drawn rois
    opt.nodraw (1,1) {mustBeMember(opt.nodraw,[0,1])} = 0 %1 to error and exit if loading roi file fails, 0 to draw if loading fails
    opt.dorg (1,1) {mustBeMember(opt.dorg,[0,1])} = 0 %flag for drawing rg (region), which is a rectangle or cuboid (when dorg=1, default roishape is rectangle, and mm is neither loaded nor saved); dorg is true when roidraw is called from stackcrop
    opt.rgname {mustBeTextScalar} = '' %name of rg you are drawing when dorg=1, keep empty unless dorg=1
    opt.pausetime (1,1) double {mustBePositive} = 0.01 %seconds, pause to allow drawing/callbacks to run smoothly; if callbacks frequently aren't caught, try increasing; pausetime=0.1 worked well on 2021 Apple M1 Pro 16 GB

end

roiname = opt.roiname;
chanstr = opt.chanstr;
roishape = opt.roishape;
roialpha = opt.roialpha;
cmap = opt.cmap;
rmolap = opt.rmolap;
cellout = opt.cellout;
nosave = opt.nosave;
nodraw = opt.nodraw;
dorg = opt.dorg;
rgname = opt.rgname;
pausetime = opt.pausetime;

nmdm = glbfile('dmstackdf');

fontsz = 10; %in figure title
maxnumroi = 50; %just for preallocating
maxnumsubroi = 50; %just for preallocating; max number of discontiguous subrois per roi
mmnamedf = 'none'; %default roiname if empty

keydict_roishape = {  ... %callback keydict for using s-switch (via function 'cb_array') to change roishape, all other switches use default keydict, which is defined in cb_array (see that example for formatting)
    {'s', 's', 'init'}, ...
    {'return', 'return', 'finish'}, ...
    {'escape', 'escape', 'exit'}, ...
    {'c', 'circle', 'circle'}, ...
    {'e', 'ellipse', 'ellipse'}, ...
    {'f', 'freestyle', 'freestyle'}, ...
    {'p', 'polygon', 'polygon'}, ...
    {'r', 'rectangle', 'rectangle'}, ...
    {'v', 'voxel', 'single-voxel'}, ...
    };

keydict_slash = {  ... %callback keydict for using s-switch (via function 'cb_array') to change roishape, all other switches use default keydict, which is defined in cb_array (see that example for formatting)
    {'slash', 'slash', 'init'}, ...
    {'return', 'return', 'finish'}, ...
    {'escape', 'escape', 'exit'}, ...
    {',', ',', 'element delim'}, ...
    {'z', 'z', 'z mean'}, ...
    {'t', 't', 't mean'}, ...
    };

clear cb_array

stackid = insertBefore(idmake(s.pth, 'stackid'), '_', '\'); %to print underscores properly

callstack = dbstack('-completenames');
if numel(callstack) >= 2
    fcnm = callstack(2).file;
    [~, fcnm] = fileparts(fcnm);
    if isequal(fcnm, 'stackcrop') && ~dorg
        error("dorg must be true when calling roidraw from stackcrop")
    end
end

nd = ndims(s.stack);
if nd<2 || nd>5
    error("s.stack input to roidraw must have 2-5 dimensions")
end
if numel(nmdm)~=5 || numel(unique(nmdm))~=numel(nmdm)
    error("nmdm must have 5 elements, none repeated")
end

[ny, nx, nz, nt, nc] = size(s.stack);
superset.y = 1:ny;
superset.x = 1:nx;
superset.z = 1:nz;
superset.t = 1:nt;
superset.c = 1:nc;

stackmnz = stacktype(mean(s.stack, strfind(nmdm, 'z')), class(s.stack));
stackmnt = stacktype(mean(s.stack, strfind(nmdm, 't')), class(s.stack));
stackmnzt = stacktype(mean(stackmnt, strfind(nmdm, 'z')), class(s.stack));

if ~cellout && nc>1
    error("cellout must be true when there are multiple channels, since there is one cell (roimask) for each channel")
end

iz = vecsub([], superset=superset.z); % z indices displayed in initial roi drawing figure (can be modified with callbacks)
it = vecsub([], superset=superset.t); % t indices displayed in initial roi drawing figure (can be modified with callbacks)

if isempty(cmap)
    cmap = brewermap(maxnumroi, 'Dark2');
end

if dorg
    if ~isempty(roiname)
        error("when dorg=1, name-value argument roiname must be empty")
    end
    roishape = 'rectangle'; %automatically set this to 1 if dorg
    nosave = 1;
end

[chandraw, dochancp] = chanstrparse(chanstr, nc);

roimask = cell(nc,1); %needs to be cell in case 2-channel with different number rois

try

    if dorg
        error("use this error to skip loading mm since dorg is true and we are not making mm, we are making rg")
    else
        if isempty(roiname)
            roiname = mmnamedf;
        end
        fnsuffix = ['_' rgname '_' roiname '_mm'];
        pthmm = [idmake(s.pth, 'pthrec'), fnsuffix, '_.mat'];
        load(pthmm, 'mm');
    end

    for ic = 1:numel(mm)
        roimask{ic} = mm(ic).mask;
    end

    if any(~isfield(mm(1), {'mask', 'roiname', 'chanstr', 'channel', 'rg'})) || numel(mm)==2 && any(~isfield(mm(2), {'mask', 'roiname', 'chanstr', 'channel', 'rg'}))
        error("mm struct must contain fields 'mask', 'roiname', 'chanstr', 'channel', 'rg'; you may have loaded an old mm struct")
    end
    if ~isequal(mm(1).rg, rg) || numel(mm)==2 && ~isequal(mm(2).rg, rg)
        error("mm file exists but for at least one channel rg in mm file does not match current rg with same name; did you delete the rg you used to draw this mm?")
    end
    sdf = structfun(@(x) diff(x)+1, rg, 'UniformOutput', false);
    if ~isequal(size(mm(ic).mask, [1 2 3]), [sdf.y, sdf.x, sdf.z])
        error("rg size does not match saved roimask size, name-value argument rg must not match rg used to draw rois")
    end
    if ~isequal(mm(1).roiname, roiname) || ~isequal(mm(1).chanstr, chanstr) || ( numel(mm)==2 && ( ~isequal(mm(2).roiname, roiname) || ~isequal(mm(2).chanstr, chanstr) ) )
        error("mm file exists but roiname and/or chanstr do not match for at least one channel")
    end

catch ME

    clear mm %in case old mm was loaded and errored, remove this eventually once all the old mm have been deleted

    if nodraw
        error("nodraw is true, and loading failed; you got this message when you tried to load mm: " + ME.message + newline)
    end
    fprintf(newline + "" + ME.message + newline + "mm FILE WITH ROIS MATCHING INPUT OPTIONS NOT FOUND, OPENING ROI DRAWING FIGURE" + newline)

    for ic = chandraw %some fields are redundant across channels (ie rg and roiname are the same for both channels), but for symmetry, and simpler code downstream, they're written to both channels

        stackmin = double(min(s.stack(:,:,:,:,ic), [], 'all'));
        stackmax = double(max(s.stack(:,:,:,:,ic), [], 'all'));

        %%%% INITIALIZE PLOT LOOP VARIABLES, AND PLOT STACK %%%%

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
        idxt = 0; % t frame counter, initialize to 0
        it_tmp_prev = -1; %it displayed in previous loop, initialize with dummy value
        dmmean = [0,0,0,0,0]; %whether to average each stack dimension (1) or not (0)
        dmmean_tmp = []; %change to dmmean, init with empty
        drawflag = 0; %1 if draw tool is open (image ready for drawing rois)
        zoomflag = 0; %1 if "zoomed in" from a view with multiple z to a view with one z
        editflag = 0; %1 if editing roi drawn previously
        roishape_o = []; %tmp roishape used when changing roishape with s switch
        switches_off = 1; %all callback "switches" are off to begin
        ttl_removed = 0; %flag for when variable title lines are changed
        izcopyroi = []; %z indices to copy most recent subroi onto
        iznew = []; %z indices for view change
        itnew = []; %t indices for view change
        tpauseflag = 0;
        tshift = 1;
        imselected_withkey = 0;
        imselectkeys = {'shift', 'control'}; %hold down control with image click to select entire image as roi, hold down shift with image click to select range (from nearest selected whole image, if any, otherwise same as control)
        cbflag = flagset({'backspace', 'c', 'e', 's', 'slash', 't', 'z'}, [0,1], init=1, me=1); %set all callback flags false; struct cbflag holds mutually exclusive state switches that are set by user input while drawing figure is open, and persist until changed by user input

        [stacktmp, h] = stackshow([], [], [], s, stackmnz, stackmnt, stackmnzt, stackmin, stackmax, ir, irsub, iz, it, ic, stackid, rgname, roiname, nz, nt, roishape, dorg, fontsz, dmmean, nmdm, cmap, roialpha, imselectkeys);

        ttli = struct('drawing', 1, 'showing', 2, 'buttons', 3, 'switches', 4, 'howto', 5, 'action', 6);
        ttli.sv = [ttli.buttons, ttli.switches, ttli.howto]; %title line indices that get removed/restored when draw tool is opened/closed
        ttl_sv = h.ttl.String(ttli.sv);
        ttl_prefixes = regexp(h.ttl.String, '[\w\s]*:\s*', 'match', 'once');
        ttl_switches = [];
        ttl_validkeys = [];

        %%%% DRAWING LOOP %%%%

        while true

            drawnow %update figure in case executing callback

            currkey = h.fg.UserData;

            imselectkey_being_pressed = 0;
            if ~isempty(currkey)
                if ~ismember(currkey, imselectkeys) %clear if not imselectkey (this includes imselectkey with "released" prefix) . . .
                    h.fg.UserData = [];
                    if imselected_withkey
                        currkey = []; %to prevent "released shift" or "released control" from appearing in title as an invalid entry when it was released after whole-im roi selection (not very important)
                        imselected_withkey = 0;
                    end
                else
                    if startsWith(currkey, 'released') %or if imselectkey, wait to clear until release registered because for imselectkeys we want to know if they're being held down
                        h.fg.UserData = [];
                    else
                        imselectkey_being_pressed = 1;
                    end
                end
            end

            imselected = 0;
            for k = 1:numel(h.im.ol) %capture axis click to start roi draw on that axis, or axis click with imselectkeys for whole image rois (we loop over ol, which is image overlay, rather than im (stack image), because in axim dool is true (to allow roi overlays to be drawn in ol)
                if ~isempty(h.im.ol{k}.UserData)
                    h.im.ol{k}.UserData = [];
                    imselected = k;
                    if imselectkey_being_pressed
                        imselected_withkey = 1;
                    else
                        imselected_withkey = 0;
                    end
                    break
                end
            end

            idxt = mod((idxt+tshift)-1, numel(it))+1; %increment t;
            it_tmp = it(idxt);
            if size(stacktmp,strfind(nmdm, 't'))>1 && ~isequal(it_tmp, it_tmp_prev) % if shown stack is not t-mean, and if current t changed, show the change
                if size(stacktmp,strfind(nmdm, 'z'))>1 %if shown stack is not z-mean, update each axis with iz, and t change
                    for k = 1:numel(h.im.pl)
                        h.im.pl{k}.CData = stacktmp(:,:,iz(k),it_tmp,ic); %indexing into channel dimension is not too slow when there is also indexing of preceding dimensions, especially the big one (t)
                    end
                else %if shown stack is z-mean, update single axis with t change
                    h.im.pl{1}.CData = stacktmp(:,:,:,it_tmp,ic); %indexing into channel dimension is not too slow when there is also indexing of preceding dimensions, especially the big one (t)
                end
                h.ttl.String{2} = regexprep(h.ttl.String{2}, '(t:.*\[).*(\])', ['$1' num2str(it_tmp) '$2']);
                it_tmp_prev = it_tmp;
            end
            if tpauseflag
                tshift = 0;
            end


            if imselected
                roi_on_mean_z = 0;
                numax = numel(h.im.ol);
                if imselectkey_being_pressed
                    [iz_allpxroi_idx_new, iz_allpxroi_idx, roi_on_mean_z, subroinew, roiinfotmp] = wholeimroi(currkey, imselected, iz_allpxroi_idx, roi_on_mean_z, iz, numax, ny, nx);
                    [h, roimask, hr, subroirgba, h.ttl.String, irsub] = subroiadd(h, subroinew, hr, roiinfotmp, roimask, ic, ir, irsub, cmap, roialpha, iz, roi_on_mean_z, h.ttl.String, [], iz_allpxroi_idx_new); % add drawn subroi and show as overlay
                else
                    axfocus = 1; %this is always 1 now because we "zoom in" to the axes you click on
                    if ~drawflag %on first axes click, do below, on second, don't do below, but do drawing further below (but don't put that clause in here because we don't want to have to click for every subroi on same image)
                        if ~zoomflag
                            iz_o = iz;  %save current iz to return to after drawing on the zoomed in axes (or if there's just one axes, this won't hurt either)
                        end
                        if numax==1 %if there's only one axes, no need to zoom in then select to draw, just one click to draw
                            drawflag = 1;
                            if numel(iz)>1
                                roi_on_mean_z = 1;
                            end
                            [h.ttl.String, ttl_sv] = titlechange('drawstart', h.ttl.String, ttl_sv, ttli, ttl_prefixes, h.im.ol, zoomflag, editflag, iredit, roishape, dorg, roi_on_mean_z);
                        else %if multiple axes, on first click zoomflag=1 and we "zoom into" clicked axes; on second click drawflag=1 and we begin drawing
                            zoomflag = 1;
                            iznew = iz(imselected);
                        end
                    end
                end
            end


            if ~isempty(currkey) && ~imselectkey_being_pressed

                if cbflag.backspace || ( switches_off && strcmp(currkey, 'backspace') ) %delete selected rois

                    if ir==1 && irsub==1
                        ttl_action = 'NO ROIS TO DELETE';
                    else
                        [irdel, cbflag, ttl_action, ttl_validkeys] = cb_array(currkey, superset=1:maxnumroi); %veclen 2 because each vec is [roi,subroi]
                        ttl_switches = 'backspace-SWITCH ON, ENTER ROI INDICES TO DELETE (SEE DOCS FOR FORMAT)';
                        if ~isempty(irdel)
                            [hr, roimask, ttl_action, success] = roidel(irdel, hr, roimask, ic);
                            if success
                                [h, roimask, hr, subroirgba, h.ttl.String] = subroiadd(h, [], [], [], roimask, ic, ir, irsub, cmap, roialpha, iz, roi_on_mean_z, h.ttl.String, [], iz); % here, we copy drawn subroi to z slices izroi (and axfocus is empty)
                            end
                        end
                    end

                elseif cbflag.c || ( switches_off && strcmp(currkey, 'c') ) %copy roi to other z (include the switches_off to prevent a context key in one sequence from initializing a different sequence)
                    if irsub==1
                        ttl_action = 'CANNOT USE c-SWITCH BECAUSE YOU HAVE NOT DRAWN ANY SUBROIS FOR THE CURRENT ROI';
                    else
                        [izcopyroi, cbflag, ttl_action, ttl_validkeys] = cb_array(currkey, superset=1:nz, numvec=1, dounique=1);
                        ttl_switches = 'c-SWITCH ON, ENTER z INDICES TO COPY ROI TO';
                    end

                elseif cbflag.e || ( switches_off && strcmp(currkey, 'e') ) %copy roi to other z (include the switches_off to prevent a context key in one sequence from initializing a different sequence)
                    if ir==1 && irsub==1
                        ttl_action = 'NO ROIS TO EDIT';
                    else
                        [iredit, cbflag, ttl_action, ttl_validkeys] = cb_array(currkey, superset=1:maxnumroi, numvec=1, veclen=2); %veclen 2 because each vec is [roi,subroi]
                        ttl_switches = 'e-SWITCH ON, ENTER SUBROI TO EDIT IN FORMAT roi,subroi';
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
                                h.ttl.String = regexprep(h.ttl.String, 'ROISHAPE: "\w+"', ['ROISHAPE: "' roishape '"']);
                                [h.ttl.String, ttl_sv] = titlechange('drawstart', h.ttl.String, ttl_sv, ttli, ttl_prefixes, h.im.ol, zoomflag, editflag, iredit, roishape, dorg, roi_on_mean_z);
                            else
                                ttl_action = ['CANNOT EDIT ROI,SUBROI ' mat2str([iredit(2),iredit(1)]) ' BECAUSE IT IS EMPTY'];
                            end
                        end
                    end

                elseif cbflag.s || ( switches_off && strcmp(currkey, 's') )  %s sequence; change roi shape (include the switches_off to prevent a context key in one sequence from initializing a different sequence)
                    ttl_switches = 's-SWITCH ON, CHANGE ROISHAPE (DRAW TOOL)';
                    [roishape_new, cbflag, ttl_action, ttl_validkeys] = cb_array(currkey, keydict=keydict_roishape, numvec=1); 
                    if ~isempty(roishape_new)
                        roishape = roishape_new;
                        if dorg
                            ttl_action = cat(2, ttl_action, 'NOTE dorg IS TRUE SO rg WILL BE xyz BOUNDING BOX OF DRAWN ROI (UNION OF ALL SUBROIS)');
                        end
                        h.ttl.String = regexprep(h.ttl.String, 'ROISHAPE: "\w+"', ['ROISHAPE: "' roishape '"']);
                    end

                elseif cbflag.slash || ( switches_off && strcmp(currkey, 'slash') )  %slash-sequence; show average of dimension selected in slash-sequence (yxztc) (include the switches_off to prevent a context key in one sequence from initializing a different sequence)
                    ttl_switches = 'slash-SWITCH ON, SELECT STACK DIMENSION TO AVERAGE';
                    [dmmean_tmp, cbflag, ttl_action, ttl_validkeys] = cb_array(currkey, keydict=keydict_slash, numvec=1, superset=nmdm, dounique=1); %don't dounique in case user wants to see repeated frames
                    if ~isempty(dmmean_tmp)
                        for k = 1:numel(dmmean_tmp)
                            dmmean(strfind(nmdm, dmmean_tmp(k))) = 1;
                        end
                    end

                elseif cbflag.t || ( switches_off && strcmp(currkey, 't') )  %t sequence; change shown t (include the switches_off to prevent a context key in one sequence from initializing a different sequence)
                    ttl_switches = 't-SWITCH ON, ENTER t INDICES TO DISPLAY';
                    [itnew, cbflag, ttl_action, ttl_validkeys] = cb_array(currkey, superset=superset.t, numvec=1); %don't dounique in case user wants to see repeated frames

                elseif cbflag.z || ( switches_off && strcmp(currkey, 'z') )  %z sequence; change shown z (include the switches_off to prevent a context key in one sequence from initializing a different sequence)
                    ttl_switches = 'z-SWITCH ON, ENTER z INDICES TO DISPLAY';
                    [iznew, cbflag, ttl_action, ttl_validkeys] = cb_array(currkey, superset=1:nz, numvec=1, dounique=1); %dounique for z indices because having repeated z makes roi accounting complicated, and it's probably pointless anyway (but repeated t might be useful)

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
                    ttl_action = [currkey ', RESCALED CONTRAST ' num2str(-1*round((scalefac - 1)*100)) ' %'];

                elseif strcmp(currkey, 'escape') %return to previous view
                    if zoomflag
                        ttl_action = [currkey ', ZOOMED OUT'];
                        [drawflag, iznew, zoomflag, editflag, roishape, roishape_o, ir, irsub] = escapefun(zoomflag, editflag, iz_o, roishape_o, ir_o, irsub_o, roishape, ir, irsub);
                    else
                        ttl_action = [currkey ' HAS NO EFFECT BECAUSE YOU ARE NOT ZOOMED IN, AND DRAW TOOL IS NOT OPEN'];
                    end

                elseif any(strcmp(currkey, {'leftarrow', 'rightarrow', 'shift+leftarrow', 'shift+rightarrow'})) % t backward or forward
                    if tpauseflag
                        if startsWith(currkey, 'shift+')
                            currkey = erase(currkey, 'shift+');
                            modkey = 'shift';
                        else
                            modkey = [];
                        end
                        if strcmpi(currkey, 'leftarrow')
                            ttl_action = [currkey ', t BACKWARD'];
                            tshift = -1;
                        else
                            ttl_action = [currkey ', t FORWARD'];
                            tshift = 1;
                        end
                        if strcmp(modkey, 'shift')
                            ttl_action = cat(2, ttl_action, ' 10 elements');
                            tshift = tshift*10;
                        end
                    else
                        ttl_action = [currkey ', INVALID, YOU MUST FIRST PAUSE t WITH SPACE'];
                    end


                elseif strcmp(currkey, 'o') %remove pixels in current roi that belong to any other rois
                    if ir<2 || ( ir==2 && irsub==1 )
                        ttl_action = 'NO OVERLAP TO REMOVE';
                    else
                        ttl_action = 'o, REMOVING ANY VOXELS FROM CURRENT SUBROI THAT OVERLAP WITH PREVIOUS ROIS';
                        [~,~,~,i4,i5] = ind2sub(size(roimask{ic}), find(roimask{ic}, 1, 'last'));
                        overlaps = logical(sum(roimask{ic}(:,:,:,:,1:i5-1), [4,5])) + roimask{ic}(:,:,:,i4,i5) > 1; %mask of all previous rois plus mask of current subroi gives us overlaps (we don't care about other subrois in current roi, they won't affect result since they are grouped anyway)
                        roimask{ic}(:,:,:,i4,i5) = roimask{ic}(:,:,:,i4,i5).*~overlaps; %zero overlaps
                        [h, roimask, hr, subroirgba, h.ttl.String] = subroiadd(h, [], [], [], roimask, ic, ir, irsub, cmap, roialpha, iz, roi_on_mean_z, h.ttl.String, axfocus, []); % here, we copy drawn subroi to z slices izroi (and axfocus is empty)
                    end

                elseif strcmp(currkey, 'q') %quit
                    ttl_action = 'q, QUIT';
                    h.ttl.String = roiinc(h.ttl.String, ir);
                    break;

                elseif strcmp(currkey, 'r') %increment roi (if at least one subroi exists for current roi)
                    if dorg
                        ttl_action = 'CANNOT ADVANCE TO NEXT ROI BECAUSE dorg=1 (YOU ARE LIMITED TO ONE ROI, BUT IT CAN HAVE MULTIPLE SUBROIS)';
                    else
                        if irsub==1
                            ttl_action = ['CANNOT ADVANCE TO NEXT ROI BECAUSE YOU HAVE NOT DRAWN A SUBROI FOR ROI ' num2str(ir)];
                        else
                            ttl_action = 'r, ADVANCED TO NEXT ROI';
                            [h.ttl.String, ir, irsub, iz_allpxroi_idx] = roiinc(h.ttl.String, ir);
                        end
                    end

                elseif strcmp(currkey, 'space') %pause t, until leftarrow or rightarrow
                    if tpauseflag
                        ttl_action = 'spacebar, UNPAUSED t';
                        tpauseflag = 0; %unpause t
                        tshift = 1;
                    else
                        ttl_action = 'spacebar, PAUSED t (leftarrow: t BACKWARD, rightarrow: t FORWARD)';
                        tpauseflag = 1; %pause t
                        tshift = 0;
                    end

                elseif any(strcmp(currkey, {'shift+z', 'shift+control+z'})) %quit
                    if ~isscalar(h.im.ol)
                        ttl_action = [currkey ', YOU MUST ZOOM IN TO ONE Z PLANE TO SCROLL Z'];
                    elseif isequal(nz, 1)
                        ttl_action = [currkey ', STACK HAS ONLY ONE Z PLANE, SO YOU CANNOT SCROLL Z'];
                    else
                        if strcmp(currkey, 'shift+control+z')
                            ttl_action = 'shift+control+z, DECREASING Z';
                            zshift = -1;
                        else
                            ttl_action = 'shift+z, INCREASING Z';
                            zshift = 1;
                        end
                        iznew = mod(iz+zshift-1, nz)+1;
                    end

                else
                    ttl_action = [currkey ', INVALID'];
                end

                switches_off = all(~cellfun(@(x) isequal(x,1), struct2cell(cbflag))); % check whether all switches off
                if switches_off && ttl_removed
                    h.ttl.String(ttli.sv) = ttl_sv;
                    ttl_removed = 0;
                    ttl_switches = [];
                    ttl_validkeys = [];
                end

                if ~isempty(ttl_switches)
                    h.ttl.String(ttli.sv) = cell(1, numel(ttli.sv));
                    h.ttl.String{ttli.sv(2)} = ttl_switches;
                    h.ttl.String{ttli.sv(3)} = ttl_validkeys;
                    ttl_removed = 1;
                end

                h.ttl.String{ttli.action} = regexprep(h.ttl.String{ttli.action}, ['(' ttl_prefixes{ttli.action} ').*'], ['$1' ttl_action]);

            end


            if ~isempty(iznew) || ~isempty(itnew) || ~isempty(dmmean_tmp) %redraw if z or t was changed, or averaged
                if ~isempty(iznew)
                    iz = iznew;
                    dmmean(strfind(nmdm, 'z')) = 0;
                elseif ~isempty(itnew)
                    it = itnew;
                    dmmean(strfind(nmdm, 't')) = 0;
                end
                [stacktmp, h] = stackshow(h, subroirgba, roimask, s, stackmnz, stackmnt, stackmnzt, stackmin, stackmax, ir, irsub, iz, it, ic, stackid, rgname, roiname, nz, nt, roishape, dorg, fontsz, dmmean, nmdm, cmap, roialpha, imselectkeys);
                roi_on_mean_z_dummy = 0; %irrelevant here
                [h.ttl.String, ttl_sv] = titlechange('newz', h.ttl.String, ttl_sv, ttli, ttl_prefixes, h.im.ol, zoomflag, editflag, iredit, roishape, dorg, roi_on_mean_z_dummy);
                iznew = [];
                itnew = [];
                dmmean_tmp = [];
            elseif ~isempty(izcopyroi) %izcopyroi only used for c-switch (roi copy)
                roi_on_mean_z_dummy = 0; %make roi_on_mean_z=0 because it must be false when copying rois (doesn't make sense to copy to a mean)
                [h, roimask, hr, subroirgba, h.ttl.String, irsub] = subroiadd(h, subroinew, hr, roiinfotmp, roimask, ic, ir, irsub, cmap, roialpha, iz, roi_on_mean_z_dummy, h.ttl.String, [], izcopyroi); % here, we copy drawn subroi to z slices izroi (and axfocus is empty)
                izcopyroi = [];
            end


            if drawflag
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
                ttl_howto_suffix = 'mouse: ADJUST,   backspace: DELETE,   return: ACCEPT';
                h.ttl.String{ttli.howto} = regexprep(h.ttl.String{ttli.howto}, ['(' ttl_prefixes{ttli.howto} ').*'], ['$1' ttl_howto_suffix]);
                drawnow
                while true
                    if ~isempty(h.fg.UserData) %capture key press on figure callback
                        currkey = h.fg.UserData;
                        h.fg.UserData = [];
                        if strcmp(currkey , 'return')
                            ttl_action = 'return, ACCEPTED DRAWN ROI, DRAW TOOL STILL OPEN';
                            break
                        elseif strcmp(currkey , 'escape')
                            if isempty(hrtmp.Position) % hrtmp.Position will be empty if you hit escape before drawing anything
                                ttl_action = 'escape, CLOSED DRAW TOOL';
                                drawflag = 0;
                                hrtmp = [];
                                break
                            end
                        elseif strcmp(currkey , 'backspace')
                            if ~isempty(hrtmp.Position) %  if you drew something but want to delete it before hitting enter
                                if editflag %if you're editing, and you hit escape (ie delete the recovered subroi), you have to delete it from roimask too
                                    [hr, roimask, ttl_action, success] = roidel({iredit}, hr, roimask, ic); %put iredit in cell for roidel
                                    if success
                                        [h, roimask, hr, subroirgba, h.ttl.String] = subroiadd(h, [], [], [], roimask, ic, ir, irsub, cmap, roialpha, iz, roi_on_mean_z, h.ttl.String, [], iz); % here, we copy drawn subroi to z slices izroi (and axfocus is empty)
                                    else
                                        error("you should not arrive here")
                                    end
                                else
                                    ttl_action = 'backspace, DELETED ROI BEFORE FINISHING, DRAW TOOL STILL OPEN';
                                end
                                delete(hrtmp)
                                pause(pausetime) %without this pause the draw tool disappears after escape
                            end
                            hrtmp = [];
                            break
                        else
                            ttl_action = [currkey ', INVALID'];
                        end
                        h.ttl.String{ttli.action} = regexprep(h.ttl.String{ttli.action}, ['(' ttl_prefixes{ttli.action} ').*'], ['$1' ttl_action]);
                    end
                    pause(pausetime)
                end
                if strcmp(currkey , 'escape')
                    [h.ttl.String, ttl_sv] = titlechange('drawstop', h.ttl.String, ttl_sv, ttli, ttl_prefixes, h.im.ol, zoomflag, editflag, iredit, roishape, dorg, roi_on_mean_z);
                else
                    [h.ttl.String, ttl_sv] = titlechange('drawstart', h.ttl.String, ttl_sv, ttli, ttl_prefixes, h.im.ol, zoomflag, editflag, iredit, roishape, dorg, roi_on_mean_z);
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
            end

        end

        h.ttl.String = "CLOSING FIGURE IN 1 SECOND";
        pause(1)
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

            if rmolap %remove voxels from rois that overlap with rois drawn earlier
                for k = flip(1:size(roimask{ic},4))  %go backward through foreground rois to zero voxels that overlap with any rois drawn earlier
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
        mm(ic).roiname = roiname;
        mm(ic).chanstr = chanstr;
        mm(ic).channel = ic;
        mm(ic).rg = rg; %save the region (rg) the masks were drawn on, in case the region changes but its name stays the same

        if dochancp
            chanreceive = setdiff(1:nc, ic);
            fprintf("name-value argument 'chanstr' ends with 'cp', COPYING ANY DRAWN ROIS FROM CHANNEL " + num2str(ic) + " ONTO CHANNEL " + num2str(chanreceive) + newline);
            roimask{chanreceive} = roimask{ic};
            mm(chanreceive).mask = roimask{ic};
            mm(chanreceive).roiname = roiname;
            mm(chanreceive).chanstr = chanstr;
            mm(chanreceive).channel = chanreceive;
            mm(chanreceive).rg = rg; %save the region (rg) the masks were drawn on, in case the region changes but its name stays the same
        end

    end

    %%%% SAVE %%%%

    if ~nosave
        if isequal(chandraw, 1) && isequal(nc, 2) %do this so that 2-channel data gets empty 2nd element if channel 2 has no rois, otherwise 2nd element wouldn't exist, which would mislead user into thinking it's single-channel data
            mm(2) = structfun(@(x) [], mm, 'UniformOutput', false);
        end
        save(pthmm, 'mm', '-v7.3', '-mat') %save each channel's mask separately (could do it together instead, either way is fine right?)
        % save(pthmm, '-struct', 'mm', '-v7.3', '-mat') %save each channel's mask separately (could do it together instead, either way is fine right?)
    end

end

if ~cellout
    roimask = cell2mat(roimask);
end


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


function [stacktmp, h] = stackshow(h, subroirgba, roimask, s, stackmnz, stackmnt, stackmnzt, stackmin, stackmax, ir, irsub, iz, it, ic, stackid, rgname, roiname, nz, nt, roishape, dorg, fontsz, dmmean, nmdm, cmap, roialpha, imselectkeys)

%output stacktmp is for updating t-display, it is not necessarily what is shown in the figure (eg if z is subset)

if any(dmmean) %we display the mean of stack dimensions corresponding to nonzero elements in vector dmmean
    if isequal(find(dmmean),strfind(nmdm, 'z')) && isequal(iz, 1:nz)
        stacktmp = stackmnz;
    elseif isequal(find(dmmean),strfind(nmdm, 't')) && isequal(it, 1:nt)
        stacktmp = stackmnt;
    elseif isequal(find(dmmean),find(ismember(nmdm, 'zt'))) && isequal(iz, 1:nz) && isequal(it, 1:nt) %find(ismember()) for multiple char
        stacktmp = stackmnzt;
    else
        idxstr = repmat({':'}, 1, 5); %do it this way in case we are only indexing with averaged dimensions, indexing with all elements of unchanged dimensions is slow
        if ismember(strfind(nmdm, 'z'), find(dmmean)) && ~isequal(iz, 1:nz)
            idxstr{strfind(nmdm, 'z')} = iz;
        end
        if ismember(strfind(nmdm, 't'), find(dmmean)) && ~isequal(it, 1:nt)
            idxstr{strfind(nmdm, 't')} = it;
        end
        if ismember(strfind(nmdm, 'z'), find(dmmean)) && ismember(strfind(nmdm, 't'), find(dmmean)) && ~isequal(iz, 1:nz) && isequal(it, 1:nt)
            stacktmp = stacktype(mean(stackmnt(idxstr{:}), find(dmmean)), class(s.stack));
        else
            stacktmp = stacktype(mean(s.stack(idxstr{:}), find(dmmean)), class(s.stack));
        end
    end
    if ismember(strfind(nmdm, 'z'), find(dmmean))
        stack_oneframe = stacktmp(:,:,:,1,ic); %if we averaged z, don't index with iz; we take one frame because we don't need t for axarr or axim, and this will save time indexing into iz; make sure you get the right channel 
    else
        stack_oneframe = stacktmp(:,:,iz,1,ic); %if we didn't average z, index with izwe take one frame because we don't need t for axarr or axim, and this will save time indexing into iz; make sure you get the right channel 
    end
else
    stacktmp = s.stack;
    stack_oneframe = s.stack(:,:,iz,1,ic); %we take one frame because we don't need t for axarr or axim, and this will save time indexing into iz;make sure you get the right channel 
end


changeaxes = 0; %only change the axes if number of z slices to show has changed
if isempty(h) || ( ~dmmean(strfind(nmdm, 'z')) && ~isequal(numel(iz), numel(h.im.ax)) ) || ( dmmean(strfind(nmdm, 'z')) && ~isscalar(h.im.ax) )
    changeaxes = 1;
end

if changeaxes
    ax = axarr(stack_oneframe, marginax=0.01, marginfg=[0, 0.2, 0.01, 0.01], stackjust='mid');
    if isempty(h)
        h = fg(fontsz=fontsz, szf=1, alignh='left', cbshort=1, releasekeys=imselectkeys);
    end
    h = axim(stack_oneframe, h=h, ax=ax, dool=1, doui=1, cmap=gray(256), immin=stackmin, immax=stackmax, ydir='reverse', axidx=1); % axidx = 1 so we don't accumulate axes in this figure handle
else
    for k = 1:numel(h.im.pl)
        h.im.pl{k}.CData = stack_oneframe(:,:,k);
    end
end

if ~isempty(subroirgba) %when redrawing the stack, also redraw any existing rois, subroirgba saves them in correct locations, regardless of which parts of the stack are displayed
    if dmmean(strfind(nmdm, 'z')) %if z dimension is averaged, we must average rgba (if it exists)
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

h.ttl = titlemake(h.ttl, ic, stackid, rgname, roiname, ir, irsub, iz, it, roishape, dorg, dmmean, nmdm);

end


function ttl = titlemake(ttl, ic, stackid, rgname, roiname, ir, irsub, iz, it, roishape, dorg, dmmean, nmdm)

num_title_lines = 6;

prefix_z = 'z: ';
title_z = num2lab(iz, maxn=6, prefix=prefix_z);
if dmmean(strfind(nmdm, 'z'))
    title_z = insertAfter(title_z, prefix_z, ' MEAN OF ');
end
prefix_t = 't: ';
title_t = num2lab(it, maxn=6, prefix=prefix_t);
if dmmean(strfind(nmdm, 't'))
    title_t = insertAfter(title_t, prefix_t, ' MEAN OF ');
end

if isempty(ttl.String) %when first making the figure/title

    ttl.String = repelem({''}, num_title_lines);

    if dorg
        title_roiset = ['RGNAME: "' rgname '"'];
    else
        title_roiset = ['roiname: "' roiname '"'];
    end
    ttl.String(1) = { ['DRAWING:       ' title_roiset ',   ROI ' num2str(ir) ',   SUBROI ' num2str(irsub) ',   ROISHAPE: "' roishape '"'] };

    ttl.String(2) = { ['SHOWING:       STACKID: ' stackid  ',  RGNAME: "' rgname '",   CHANNEL: ' num2str(ic) ',   ' title_z ',   ' title_t] };

    ttl.String(3) = { [...
        'BUTTONS:       ', ...
        'r: NEXT ROI,  ', ...
        'space/left/right: (UN)PAUSE/SCROLL t,  ', ...
        'shift+(cntrl+)z : SCROLL z,  ', ...
        'up/down: CONTRAST,  ', ...
        'o: RM OVERLAP,  ', ...
        'q: QUIT', ...
        ]};

    ttl.String(4) = { [...
        'SWITCHES:      ', ... %4 SPACES HERE TO ALIGN EVERYTHING
        'backspace: DELETE ROIS,  ', ...
        'c: COPY SUBROI TO z,  ', ...
        'e: EDIT SUBROI,  ', ...
        's: CHANGE ROISHAPE,  ', ...
        't: CHANGE t,  ', ...
        'z: CHANGE z,  ', ...
        'slash: AVERAGE DIMS', ...
        ]};

    ttl.String(5) = {'TO MAKE ROI: CLICK IM: ZOOM,   cntrl+CLICK IM: WHOLE-IM SUBROI,   shift+CLICK IM: WHOLE-IM SUBROI RANGE'};
    ttl.String(6) = {'LAST ACTION: '};

else %when updating the title (only have to update title_z and title_t in 2nd line in titlemake)

    ttl.String(2) = { ['SHOWING:       rgname: "' rgname '",   CHANNEL: ' num2str(ic) ',   ' title_z ',   ' title_t] };

end

end

function [ttl, ir, irsub, iz_allpxroi_idx] = roiinc(ttl, ir)

ir = ir + 1; %increment roi counter
irsub = 1; %reset subroi counter to 1
iz_allpxroi_idx = [];
ttl = regexprep(ttl, ' ROI \d+', [' ROI ' num2str(ir)]); %distinguish subroi from roi with space first
ttl = regexprep(ttl, 'SUBROI \d+', ['SUBROI ' num2str(irsub)]);

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
    ttl = regexprep(ttl, 'SUBROI \d+', ['SUBROI ' num2str(irsub)]);
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
        ttl = 'INVALID, IRDEL SHOULD BE CELL VECTOR OR ORDINARY VECTOR';
        return
    end
end
if any(~ismember([irdel{:}], 1:50))
    ttl = 'INVALID, IRDEL SHOULD BE CELL VECTOR OR ORDINARY VECTOR';
end
if any(~cell2mat(cellfun(@(x) isequal(numel(x),2), irdel, 'UniformOutput', false))) %if format is not roi,subroi;roi,subroi
    if numel(irdel)~=2 % . . . then format is empty;empty, or rois;empty, or empty;subrois length must be 2
        ttl = 'INVALID, ROI INDICES FOR DELETION MUST BE IN FORMAT ROI,SUBROI;ROI,SUBROI..., OR ROIS;EMPTY, OR EMPTY;SUBROIS';
        return
    end
    allsubrois = isequal(sort(irdel{2}), 1:size(roimask{ic},4));  %all rois for each subroi listed
    allrois = isequal(sort(irdel{1}), 1:size(roimask{ic},5));  %all subrois for each roi listed
    if allrois && allsubrois %all subrois for each roi listed
        roimask{ic}(:) = 0;
        hr = {};
        ttl = 'DELETED ALL ROIS (backspace-SWITCH OUTPUT EMPTY)';
    elseif allsubrois %all subrois for each roi listed
        for k = 1:numel(irdel{1})
            roimask{ic}(:,:,:,:,irdel{1}(k)) = 0;
            hr{irdel{1}(k)} = [];
        end
        if numel(irdel{1})<6
            tmpprint = sprintf('%d,', irdel{1}); %to remove trailing comma
            ttl = ['DELETED ALL SUBROIS FROM ROI(S) [' tmpprint(1:end-1) '], (backspace-SWITCH OUTPUT NONEMPTY;EMPTY)'];
        else
            ttl = ['DELETED ALL SUBROIS FROM ' num2str(numel(irdel{1})) ' ROIS, (backspace-SWITCH OUTPUT NONEMPTY;EMPTY)'];
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
            ttl = ['DELETED SUBROI(S) [' tmpprint(1:end-1) '] FROM ALL ROIS (backspace-SWITCH OUTPUT EMPTY;NONEMPTY)'];
        else
            ttl = ['DELETED ' num2str(numel(irdel{2})) ' SUBROIS FROM ALL ROIS (backspace-SWITCH OUTPUT EMPTY;NONEMPTY)'];
        end
    else
        ttl = 'INVALID FORMAT FOR backspace-SWITCH';
        return
    end
else
    for k = 1:numel(irdel)
        roimask{ic}(:,:,:,irdel{k}(2),irdel{k}(1)) = 0; %subroi comes before roi in roimask
        hr{irdel{k}(1),irdel{k}(2)} = [];
    end
    if numel(irdel)<6
        tmpprint = sprintf('[%d,%d],', irdel{:}); %to remove trailing comma
        ttl = ['DELETED [ROI,SUBROI] ' tmpprint(1:end-1) ' (backspace-SWITCH OUTPUT NONEMPTY;NONEMPTY)'];
    else
        ttl = ['DELETED ' num2str(numel(irdel)) ' SUBROIS FROM ALL ROIS (backspace-SWITCH OUTPUT NONEMPTY;NONEMPTY)'];
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


function [iz_allpxroi_idx_new, iz_allpxroi_idx, roi_on_mean_z, subroinew, roiinfotmp] = wholeimroi(currkey, imselected, iz_allpxroi_idx, roi_on_mean_z, iz, numax, ny, nx)

if strcmp(currkey, 'shift') && numel(iz_allpxroi_idx)>0
    [~, nearestz] = min(abs(iz_allpxroi_idx - iz(imselected)));
    if iz(imselected)<iz_allpxroi_idx(nearestz)
        iz_allpxroi_idx_new = iz(imselected):iz_allpxroi_idx(nearestz); %append range, then take unique below
    else
        iz_allpxroi_idx_new = iz_allpxroi_idx(nearestz)+1:iz(imselected); %append range, then take unique below
    end
else
    iz_allpxroi_idx_new = iz(imselected);
end
iz_allpxroi_idx = unique(sort([iz_allpxroi_idx iz_allpxroi_idx_new]));
if numax==1 && numel(iz)>1
    roi_on_mean_z = 1;
    iz_allpxroi_idx_new = iz; %overwrite above (single z) if it's a mean z image
end
subroinew = ones(ny,nx,'logical'); %yx
roiinfotmp = {'rectangle', [0,0,nx,ny]};%xy not yx

end

function [ttl, ttl_sv] = titlechange(status, ttl, ttl_sv, ttli, ttl_prefixes, axol, zoomflag, editflag, iredit, roishape, dorg, roi_on_mean_z)

if strcmp(status, 'newz')
    if isscalar(axol)
        ttl{ttli.howto} = regexprep(ttl{ttli.howto}, 'CLICK IM: ZOOM,', 'CLICK IM: OPEN DRAW TOOL,');
        ttl{ttli.howto} = erase(ttl{ttli.howto}, ',   shift+CLICK IM: WHOLE-IM SUBROI RANGE');
        if zoomflag
            ttl{ttli.buttons} = insertAfter(ttl{ttli.buttons}, ttl_prefixes{ttli.buttons}, 'escape: ZOOM OUT,  ');
        end
    else
        ttl{ttli.howto} = regexprep(ttl{ttli.howto}, 'CLICK IM: OPEN DRAW TOOL,', 'CLICK IM: ZOOM,');
        ttl{ttli.buttons} = erase(ttl{ttli.buttons}, 'escape: ZOOM OUT,  ');
    end
    ttl_sv = ttl(ttli.sv);
elseif strcmp(status, 'drawstart')
    ttl{ttli.buttons} = regexprep(ttl{ttli.buttons}, ['(' ttl_prefixes{ttli.buttons} ').*'], ['$1' 'DISABLED WHEN DRAWING']);
    if editflag
        ttl{ttli.switches} = ['e-SWITCH ON, NOW EDITING ROI ' num2str(iredit(1)) ' SUBROI ' num2str(iredit(1))];
    else
        ttl{ttli.switches} = regexprep(ttl{ttli.switches}, ['(' ttl_prefixes{ttli.switches} ').*'], ['$1' 'DISABLED WHEN DRAWING']);
    end
    ttl_howto_suffix = ['DRAW "' roishape '",   escape: CLOSE DRAW TOOL'];
    if dorg
        ttl_howto_suffix = insertBefore(ttl_howto_suffix, ',   escape:', ' (XY CROSS-SECTION OF rg');
    end
    if roi_on_mean_z
        ttl_howto_suffix = insertBefore(ttl_howto_suffix, ',   escape:', ',   WILL COPY TO Z COMPRISING MEAN IMAGE');
    end
    ttl{ttli.howto} = regexprep(ttl{ttli.howto}, ['(' ttl_prefixes{ttli.howto} ').*'], ['$1' ttl_howto_suffix]);
elseif strcmp(status, 'drawstop')
    ttl(ttli.sv) = ttl_sv;
end

end