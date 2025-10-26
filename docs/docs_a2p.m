%%%%%%%%%%%%%% a2p %%%%%%%%%%%%%%

%{

each module returns a struct
each element of the struct represents an option set
each field represents a quantity extracted by the module
    for each field
        dimensions represent fundamental splits in the data (rather than created in analysis) - NO!
        and why not s.stack in two cells for each channel? should this follow rule?
        we know we want cell for disjoint split, then other dimensions, then time
        time dimension is last, if it exists
    preceding 
        example: 'roimake' outputs struct 'roi', with field 'ts', with size (roi,t)
    if data requires additional dimensions, and they match first dimension length, they are placed before the time dimension 
        example: s.stack with size (y,x,z,t)
    if additional dimensions do not necessarily match the first dimension in length, they are placed in nonscalar struct
        example: roi.ts(1) with size (roi,t) and roi.ts(2) with size (roi,t) store roi timeseries for channel 1 and 2, respectively

in modules, opt are id-contolled name-value arguments (ie module options), opt2 are name-value arguments that are not id-controlled; 
in functions that are not modules, opt is used for all name-value arguments 
in matlab, if user explicitly sets name-value argument to empty when calling a function, the default value in arguments block is not used; 
the arguments block default value is only used if user doesn't specify the name-value argument in the function call,  
for example, daqld(pthdaq=[]) does not set pthdaq to its arguments block default value, but daqld() does; 
so for many name-value arguments in scopa matlab code, where we don't want empty to be a valid value, arguments block often sets temporary default value to empty, then true default is set below arguments block; 
this way, for example, pthdaq will get default value with daqld() and daqld(pthdaq=[])

%{
stack suffixes:
    'o': original
    'r': motion corrected
    'd': denoised
    'b': background-subtracted
    's': scannoise-removed 
%}

scopagit syncs local with remote, gets called from structfile 
if you get error "Unable to fetch from the remote "origin" at . . . ", try usegit=0

module: high-level function called directly from a2p
    stackld (sld)
    daqld (daq)
    roimake (roi)
    bmpmake (bmp)
    mdlmake (mdl)
    
for each module
    varid: unique id assigned to a set of input variables; z0 when unknown 
    optid: unique id assigned to a set of input options
    output is saved to file with varid and optid in suffix 


for rotations using imwarp (called by stackwarp), rotation angle is defined to be positive for a rotation that is counterclockwise when viewed by an observer looking along the rotation axis towards the origin

glb is required in only a couple places within function vget
strucfile gets called by: oid, vget, stackcrop, and fset; can read and/or
write in all cases except fset (fset just reads); uses scopagit to ensure integration across filesystems 
warning: when reading struct from file, jsencode (called from structld) will insert an 'x' at the beginning of any fieldname that doesn't begin with a letter (an invalid fieldname); if a file was written with structsv, it will not contain invalid fieldnames because structsv only writes valid structs) 

ap2 (analysis 2-photon)
    scopa 'post' pipeline for analyzing data output from scopa 'pre' pipeline
    primarily for defining/processing rois, fitting models, and visualizing data (including interactively)
    can run on single recordings, or in loop on batch of recordings
    can run locally, or on O2
    many subroutines can be run on electrophysiological data too; full pipeline could be easily adapted to run on electrophysiological data 

overview: 
    load/process stack(s)
    load/process stimulus (daq)
    load/process fictrac video
    load metadata
    draw and/or automatically extract morphological rois
    load/process functional rois
    extract features from stack and/or timeseries 
    fit models
    explore data interactively 

variables: 
    o: struct; input options in various sub-structs; each substruct is (predominantly) used in one function below, although substruct fields are passed individually as arguments to make the function more portable
    ts: struct; timeseries (in various sub-structs) with temporal indices corresponding to ts.t (imaging frame timestamps)
    roidat: struct; roi info for morphological and functional rois
    md: struct; metadata
    pth: struct; paths
    stack: numeric array; imaging movie chosen for analysis; dimensions y, x, z, t, c (channel)
    iy, ix, iz, it, ic: index for each dimension of stack, y, x, z, t, c (channel)
    ir: roi index
    y, x, z, t, c: reserved for stack dimensions
    k, m, p, q, s, u, v, w: reserved for loop indices
    b: reserved for model parameters
    cmc, cmdff, cmdffr, cms, cma, cmb, cmsnr, cmval: caiman roi extraction output variables (loaded/processed in roifauto)


main processing functions:
    stackseries: load stacks; plot stacks for comparison
    daqld: load/process daq data
    roimake: make manual (drawn) and/or automated morphological rois
    roifauto: process functional rois extracted in pre pipeline with caiman
    bmpmake: compute bump in various ways
    popcmp: compute poulation features, currently only holds bmpmake; eventually will be general stack and timeseries feature extraction routine, to make extracted features available to mdlmake routine
    mdlmake: fit models to any available timeseries (derived from roi code, or feature extraction code, or direct experimental timeseries (e.g stimulus, fictrac timeseries, etc)

utility functions (and visualization functions):
    stackplt: plot stack(s) 
    pltx: pltx means plot experiment; versatile and interactive plotting function; can plot fictrac video, fictrac paths, scatterplots, brain images with rois 
    pthauto: create path (e.g. for saving figures)
    oset: set options
    ofill: invoke default options, overwriting defaults with input
    vget: choose timeseries from highly nested struct ts using string pattern matching (wildards allowed)
    axarr: arrange subplots, including automatically arranging frames of imaging stack to optimally fill available space while maintaining aspect ratio 


abbreviations
    stack: imaging volume; o: options, md: metadata, df: default, pars: parameters, ts: timeseries, vel: velocity, dv: derivative, fb: flyback, ftv: fictrac video, ft: fictrac, roim: morphological roi, roif: functional roi, ld: load, pth: path, plt: plot, px: pixel, resp: response/neural activity timeseries; stim: stimulus; depv: dependent variable; indv: independent variable; cnt: count (loop index); cm: caiman; proc: process; fn: filename and fieldname (need to disambiguate) 


variables are organized into structs, which are sometimes unpacked when entering functions, unless they are used infrequently, or they are large and are modified with indexing
pixel (abbr. px) can mean both pixel and voxel in scopa variable names (because pixel is so often used to mean voxel); occasionally the term voxel is used in comments 

options
    some formatting is lost because of jsonencode/jsondecode, and consider syntax changes in matlab/python; current defaults are easily dealt with; use 0/1 instead of true/false, don't use multidimensional text defaults, convert char to string when necessary (done automatically in scopa); but careful adding defaults

expansion
    for consistency, all text arrays are string, since cell is for expansion

python part is less complex, more for batches, more for pre
matlab part is more interactive, more complex options, more for post 
many parts can cross over 

%}