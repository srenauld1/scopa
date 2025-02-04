%%%%%%%%%%%%%% a2p %%%%%%%%%%%%%%

%{

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
    stackpr: load stacks; plot stacks for comparison
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
    odf: invoke default options, overwriting defaults with input
    tsget: choose timeseries from highly nested struct ts using string pattern matching (wildards allowed)
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