%{

region (previously rg) are unique to recording
mmname are unique to recording 

optid 

optid for all files in stack
for each recording, single file holds all region (rg), as struct 
for each recording, single file holds all maskman (name), as struct 

extract: oex, search for existing roim matching opts, load if so (make if not)
a2p: 

name defines rg
name_subname_optind defines rgname (maskman is loaded using name_subname_chan)
maskman just has name_subname in filename, does not need channel in filename, but includes channel as 4th dim, and requested channel must exist 

we want to reuse maskman, index let's us reuse maskman, subname let's us reuse rg 

rgn = {'fb'}


run extract.py
    seed or mask, lookup maskmanual with name_subname 

pre: 
    background subtraction, scanphase correction, registration, denoising, scannoise removal  
    input: stack
    output: stack and parsed scanimage metadata 
    slow and large files, do not distribute opts

rois:
    roimake: roim and/or roif
    input: stack (pre output) and metadata
    output: roi masks and timeseries

post:
    extern/daq
    feature extraction (from stack and/or timeseries)
    modeling
    visualization

oset simplifies setting options (could be reproduced with csv or json)
pipeline_init does not have oset 

oset vectors are expanded (map2opt) to create each o.roi.rgname 
rgname is name_subname_index
name is arbitrary, name is associated with rg; subname means the same rg as name, but different rgname; index is opt set index  

all rgname are included in options_.txt
the most recent options_.txt is searched for options matches (or rgname matches)


user can pass in rgname and opts will populate, or pass in opts and rgname will populate, but not both
there is no reason to make separate map2opt for roim and roif, because user will not want to loop through each separately 
if user has duplicate rgname (say, some run in python, some from a2p), the most recent param file is used as lookup
set includes roim and roif opt, since roim seeds roif
python runs of extract will write opts as options_cmex, for lookup when user runs a2p
since roim options will be missing from python runs, they are considered to have default values, as if the user ran a2p and skipped roim (draw and ma)

roi routines 
'seed' means draw/ma seeds caiman extraction
'cluster' means draw/ma clusters caiman rois
    if cluster, draw/ma has nothing to do with extract.py, so rgname run in python will be indexed differently 
    so do we need two indices (fb_l_2_22), one lookup for options_cmex, and another for options 
    an a2p run creates all options, and checks if an options set exists in the most recent options_cmex_.txt, and populates rgnamecm, use rgnamecm to look up roi file(s) 

run a2p
    distribute opts, define all rgname, save o
    search for o.roif options in options_cmex
        exists: id rgnamecm and its files
            files don't exist; flag to run
        does not exist: flag to run, pass in o.roi options 

run extract.py
    distribute opts, define all rgnamecm, save ocm
    if seeded, check if roim file exists, if so, load and use, if not, draw roim for seed in python

if you want to independently automate mrois from multiple drawn regions, use different rgname
(they can be analzed together after extracting responses), or choose to draw discontiguous roi and that one can get passed to roimauto


for num_roim argument
if number is passed, method is automated
you can have zero morph rois, which means any functional rois will not get morph selection
you can have one morph roi, which will use edge detection to refine and functional rois will get that selection
you can have more than 1 morph roi, which will create automated rois, and those are bad for functional roi selection
if more than zero automated morph rois, option to use manually drawn roi
to help automation (loops over each drawn roi)
if string 'manual' is passed
rois are drawn, either on the mean image (what is drawn is projected through z), or on each z slice

regardless, 3d centroids of each morph roi are found (if zero, then whole fov centroid)


create morphological rois
using the mean-time and mean-z projection of the data,
manually create 2d mask (roimaskman)
that 2d mask is projected into a 3d mask (mask_roim_all_simple)
that is refined using chosen method (edge detection, global threshold, etc)
if creating multiple morphological rois, the 3d mask is refined using
a high-z-res version of the data, and the mask is mapped back to original resolution
find the morphological roi centroids (roicen) of the final 3d mask,
and all voxels that are nearest each centroid (roiwt)
if you draw multiple rois in roimaskman, a different mask_roim_all_simple will be
made for each, but the 3d refining code cannot accommodate
multiple drawn rois currently, so do not do this;
if you want multiple rois within the fov passed to this function,
call this function (roimake)
again with the same inputs, but draw a different single 2d roi,
and assign the outputs of this function a different name (outside this function)

roiwt can be single when it's weighted, boolean otherwise

%}