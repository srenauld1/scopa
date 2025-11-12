

%{

remove rskey allowed to be nonscalar in dq make now that dqwmakew diistribuytes 

make global resampliung option so stack and daq can be arbitrarily resampled together (currently only can subset each, and arbitrarily sample daq)
make trialData perisstent so we don't repeatedly reload
consistently save in wrapper or not? rgmake saves to s, but nothing else does
make a runtype that checks wrapper defaults match module defaults (increase all runtype by 1 and make this runtype 1, but only call from odf with no other inputs)
something better for save flag than mnum
remove justld from rgmake??
remove cell approach in roinorm and roits, since roimask is no longer ever cell
rename opt mos in all modules??

make save matfile function taking in fields 

how do we deal with multiple output structs in s but only wanting one for this or that?
how do we deal with saving in wrapper functions, or rather, outside them, if looping over "each" option sets?

need '*' analog for child mos like cm
make varidcheck (like optidcvheck)
make input mos permit nonscalar (bmp(2)) but still allow bmp also, which means all indices
make one roi limmit when dorg in roidraw??
commebnted out metadata check in vsget, fix that
remove ii from stackind
probably should make no norm nrmstr = 'f' everywhere, and not allow empty?? but right now reverted to empty in most places in a rush
add classes to validation functions like mustBeBinary, etc with 'cellok' or something like that
need to add input validation for tg 

voltlim, balldia, voltminhd, should all probably not be in opt

get voltlim from metadata
and maybe voltminhd

consider putting more fields in s (things that get used repeatedly, especially when they can cost big time/ram, like stack min, stack max, and stackmnt), but then need to be sure to update these values in rgmake if crop
put any argument dependent option changing before odf=1 so arguments get changed before oid gets called in ofill 

vecdv need to generalize vecdv for nd, and change to vecdv, and make time units optional (something like dvlensec and slopelensamp

deal with nonscalar dq output within dqmake (when rsidx are multiple) while multiple optid also make dq nonscalar (outside dqmake)
consider renaming roi child mos 
    rmm
    rma
    rfa
    rnm
    rqc
(also their outputs??)

put fmfmake into stimftmake (stim feature make)
consider putting stimftmake into dqmake , as child module, and having derivatives/velocities handled by that child module 
consider putting bmpmake into stackftmake (stack feature make) something like that
so at the high level, dqmake becomes load all stim stuff (ie not neural data)
and bmpmake gets put into stack feature extrator, extracting all features from neural data (except rois, or rois also??)
rename ts vec in many cases (like vecrs --> vecrs)
consider renaming input 'opt' 'mos' in modules  
argument validation functions applied in odf, or somewhere in oset before oid

write function to delete opt set from opt file and renumber everything? or allow nonsequential nm in structfile??
need to use better system than the glb('maketime*') checks
probably get rid of glb pthstack or deal with when name value conflicts in better way than error
make function vg check to check vg formatting, put it in ofill 

FIX: EMPTY [], '', {}, WILL INVOKE DEFAULT (ALTHOUGH EMPTY STRING ARRAY [""] WILL NOT INVOKE DEFAULT STRING ARRAY)
FIX: NONFUNCTIONAL (PLOTTING) OPTIONS ARE CURRENTLY ALL IN SEPARATE OBIN, SO OID EASILY DEALS WITH THEM, BUT CAN THIS ALWAYS BE THE CASE? what about redundant obins that get removed in ored, they aren't returned, is that a problem? should options leaving oset always have same fields?? 
FIX: ORED NEEDS TO REMOVE NONFUNCTIONAL OBIN AT ANY NESTING 
when constructing o, you can only append obin or option listed in odf;
options can be structs themselves, but defaults for all fields have to be defined oin odf
the only time a struct can appear within an option is struct vg, which has special handling in ofill


disallow copybins unless user runs them through oid, since they should be temporary bins on way to id??
should cb_key convert key+modifier to intended key? for example semicolon+shift convert to colon, in cb_key rather than where it gets used?
graphics objects are placed in struct, it let's me name them (advantage is mostly just shorter names), but loses some of the heirarchical structure, which can be confusing, and most importantly, deleting the struct does not affect the graphics object, you have to run delete(object) for example, rather than rmfield(s, object), and this is confusing
flip (rotate) all stacks for berg1, then make it an option in pl.sh
change all dos to char vector, with hyphen separating what has been done and what is requested, like or-d for do denoise after do register has been done - but what about stitch, or a2p?
make dnraw use registered
get rid of pth local and o2 by putting stacks inside scopa and gitignore it
need to catch duplicate fieldnames in structfile, in case edited file directly, jsonencode will insewrt underscore and we dopn't want that
consider what to do when glb and name value are empty, invoke default or sometimes error?
roi.dat channels are roi.dat(chan) but they contain mm which is mm(chan) so you might have roi.dat(chan2).mm(chan1) right???
run pl.sh multiple times at once
my only eval calls are in ofill, fix those
make sure all options have unique names (should not require enclosing field to be unique)
flag_single_roi_per_stack does not force contiguity right? should we even have this?
deal with stackplt looking dim
deal with stackplt not working to show rois for non volumetric stack 
eventually make rg and mm have check that stack input has not changed, with stack's optid from s
make all pthscopa calls glb?
fix all eval calls, eg in structunflat
fix order of module inputs, should opt be first, or just first name-value argument?
remove calls to combos since it relies on a toolbox
distribution in vget?? can vg fields be distributed when cells? or is the group field doing that but with less flexibility?
give mn an ored so that if no do for a module, that obin is empty in  options struct, or just hard code that
optid not getting assigned for mdl from within bmp
save opt with each module's save
make vget have option to retrieve the index of all found timeseries, so you don't output all of them and then index that, but instead output only the desired combo index 
use dbstack to prevent some functions from running unless a2p is on stack (like vget maybe; in general because of reliance on glb)
should empty optid be part of each struct in defaults? or only added after oid, as it does now?
change names for vget group
vget defaults are never filled in on purpose, but is that right?
make dqmake ftv have a dotfv, just like roimake
consider making default nested opts rather than using otree; for example, d.roi.cm = [], etc
optid for stackseries, since it affects the rois
no roeason to make dq a table in dqmake then convert to struct, just m,ake struct from start
in vget there are multiple files with matched optid and domain, you may have created them from different versions of the same stack (or, od, etc); need to make this fixible; for now just rename one
do i need maketime protection for rg??
in odf define timeseries fields available to bmp (like mu, rho, amp, etc), the way you did with dq, do this for all main modules 
vget is limited to one obin within vg at a time but shouldn't be, what if you want a dq and roi variable as indv
make sure optids refer to same file, that the opt file mapping opt to id has not been changed 
nonfunctional obin in ored/odist etc need to be able to be nested and returned to right spot
set up default roimake, where opt can be empty) - mean of fov
need to make nan for cue in dark now that epoch is loaded on dq
now if multiple recind are running in pl.sh, and one errors, the whole sequence will stop (i think only at the do copyfiles part though, so maybe if docopyfiles is 0 the recind without error will continue??) is this good or bad?
should roiname none be reserved for skipping drawing?
right now opts thsat get written to opt file are only functional, and if entire obin are non-functional (ignored) they are written as empty struct which is {} in txt file; is this best? should all ignored options get written as empty or nan or something like that? that seems like a lot of clutter
ofill argument unpack should unpack to the specified nest if obin is nested, currently it just unnpacks the highest level, or if that might cause issue somewhere, make an unpack nest option
TEMPORARY HACK FOR CROPPING NEW RUNBG dq (WHEN dq RUNS IN BACKGROUND, TO CAPTURE START AND END OF EVERYTHING) output data is less accurate than frameClock, since volume (or frame?) seems to complete after outputData ends, but i think frameClock is missing any final flyback frames
should ftv downsampling occur in ftvalign in matlab? why do it in pythno during register?? oh it's because matlab on mac can't read it??
dq needs toindex, like doballscale etc, to convert binary to index, right now it happens by default in daqpr for any binary variable, but what if you want it to remain binary?? it should also occur outside daqpr, like the other to* variables, but this one before daqpr
make substr have convenient start finish markers, rather than having to use ^ and $ where the option is specified
make chan sum to draw on sum of channels
make channel consistently 5th dim index or pmt index; right now in python code it's pmt index and in matlab it's mostly stack 5th dim index
make sure fictrac has not flatlined, epoch might be as expected despite fictrac flatline
write function to delete a variable in txt (not allow manual) that will also delete all associated files
\n\nSTITCH IS INDEPENDENT FOR 2 CHANNELS, FIX THAT? OR IS THAT FINE??
apply vecdv to dq directly, not output of vecrs
make vsmooth for all variables rather than stacksm and vecsm
MAKE TIME ALWAYS 2ND DIM
FIX DIFFERENT roi OPTS FOR EACH RGNAME, OR MAYBE TRANSFER MANY PARAMS TO OPTS IN THEIR FUNCTIONS
CAN STACK REMAIN INT16?? zero in uint16 is nice though
MAKE ALL INDICES CONSISTENTLY REPRESENT START, CENTER, OR END . . . dq starts at 0, so maybe do start indexed, but singleton 0 indexed samples don't tell you width; but currently default dq downsampling makes time represent center, since it takeds average
make hemisphere option (eg option to analyze left or right or both)
fix hsv spec for internal periodic components (vonmises in fnet gets periodic hue spec)
need to make mdl_parse_mdlname_string run with other inputs ignored during param setting to check the syntax (so you don't find out later, halfway through the pipeline
allow recursive mdl
constrain amplitude of all intermediate functions
time in all functions
IS THERE RECORD OF ORIGINAL Z IN ROI??????
IS THERE RECORD OF ORIGINAL Z IN ROI??????
IS THERE RECORD OF ORIGINAL Z IN ROI??????
IS THERE RECORD OF ORIGINAL Z IN ROI??????
IS THERE RECORD OF ORIGINAL Z IN ROI??????
IS THERE RECORD OF ORIGINAL Z IN ROI??????
IS THERE RECORD OF ORIGINAL Z IN ROI??????
fix hard coded, field-dependent nesting in vnm
FOR NORMAL AND CIRCULAR VARIABLES, CONSIDER A SWITCH FROM MEAN TO INTERP NEAREST WHEN THERE ARE MANY FLYBACK FRAMES, OR WHEN VOLRTE IS LOW, SINCE INCLUDING THOSE IS IN MEAN IS MISLEADING (IF THEY ARE INCLUDED WITH usefbf=1)" + newline)
empty in oset invokles defaults becausde it's the same as not existing, do we want that?

%}