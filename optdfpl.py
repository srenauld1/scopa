

## SET OPTIONS FOR INTERACTIVE MODE (WHEN pl.py IS CALLED DIRECTLY, NOT FROM pl.sh)

## CHOOSE WHAT PARTS OF THE PIPELINE TO RUN (IN INTERACTIVE MODE, ONELY ONE do_* CAN BE TRUE AT A TIME, FOR NOW; THIS IS NOT THE CASE IN pl.sh) ## 

do_register = 1 #caiman normCorre registration 
do_denoise = 0 #deepcad denoising (from the more recent deepcadrt, although this is not real time), input must be motion_corrected 
do_stitch = 0 #stitch deepcad denoised slices into stack of original size and put in data folder (before stitch, denoised data is in temporary 'denoising' directory)
do_remove = 0 #remove scan noise (matlab script, but filefind uses filefind function below)
do_extract = 0 #caiman source extraction 
do_a2p = 0 #matlab 'postprocessing' analysis; various functions in a2p.m (stimulus processing, roi segmentation, model fitting, plotting)

do_copyfiles = 0 #copy to/from wilsonlab server to analysis folder; in general when running interactively (ie setting options here in this file) you will want this to be 0, to run analysis, but if you want to test copyfiles functionality (you must be on transfer partition to do so), you can set to 1 or 2; 0, 1, or 2 . . . 1 does nothing but copy the files matching pattern from pth_storage_prefix to compute folder, 2 is same but vice-versa, 0 allows everything else in the pipeline to occur . . . set to 0 if you do not have access to pth_storage_prefix from where you're running this script
jobind = ['all'] #list, 'all' or list of zero-indexed string ints or ints, if 'all', loop over all recordings matching pattern in pth_compute, if not 'all', zero indexed (can be str or int) operate on recording whose index (in sorted list of all recordings in pth_compute) matches value in jobind

## CHOOSE RECORDING OR RECORDINGS ## 

folder_with_all_recordings_on_storage_and_compute_filesystems = 'stacks' #folder holding all recordings you want this pipeline to operate on, if you're using do_copyfiles, this will refer to a folder on storage server and o2, tree on storage will be mirrored on o2; it is a separate variable (rather than end of pth_storage_prefix) to emphasize that it is separated off and mirrored on O2 
pth_storage_prefix = '/n/files/Neurobio/wilsonlab/wienecke/' #string, single element not in list, pth_storage_prefix+folder_with_all_recordings_on_storage_and_compute_filesystems is the path to the storage folder containing all recordings, data will be copied from here, into a folder on scratch with name (folder_with_all_recordings_on_storage_and_compute_filesystems) then analyzed, then copied back, ignored if do_copyfiles==0, 

recdate = ['20240907'] #list of strings, as it appears in the directory and raw file filename (with hyphen not underscore for now), '*' for any 
fly = ['*'] #list of strings, fly, '*' for any, can be len 1 or len(recdate), if len 1 and len(recdate)>1, fly will be copied to match
trial = ['*'] #list of strings, trial, '*' for any #
folder_substring = ['*'] #list of strings, '*' for any, match recordings only in folders containing any substring in list  
file_matching_style = 'any' #string, single element not in list, 'any' or 'each', if any, will find all files matching any combo from above lists, if each, will match files using corresponding elements of above lists

## SOME OPTIONS IN ROUGH ORDER OF APPEARANCE ## 

scopatmplt = 1 #1 to use scopa template
clip = [-1] #[-1, 0.99] #0 to skip clip; [-1] to set negatives to 0, or [lower upper] quantiles to clip, or [-1 upper], which will set negatives to 0, and clip upper quantile; unless your stack is very noisy, or you have miscalibrated pmt offset, negative values should be predominantly noise and can be removed (assuming you "autoread" pmt offset and "subtract offset" ); 
methodrg = ['second'] #first, second, both, 12, 21 (both doesn't work yet); 'first' to register the first (or only) saved channel and discard channel 2 if it exists; 'second' to register second channel only and discard first (will error if there is only one saved channel, even if it's channel 2); 'both' to register channels 1 and 2 independently ('both' does not work yet!); '12' to register channel 1, then register channel 2 with the same shifts as channel 1; '21' is same as '12' but reversed; if methodrg is '12' or '21' or 'both' and only one channel is present, methodrg is automatically changed to 'first' 
register_in_2d = 1 #one z slice at a time, for 4d data, ignored if 3d data  
bglenpx = 0 #must be even and nonzero, will run line-by-line background subtraction; 0 to skip background subtraction; full width of patch over which mean is computed for background subtraction (patch is a line in x); must be even; applied before registration, won't happen unless do_register==1, (helps remove stimulus bleedthrough, but don't use unless there's a lot of bleedthrough, and there is a clear background patch on each line; if that's the case, set this as large as possible to cover that background, and even)
max_shifts_prc = [10, 10, 10] #empty [] to skip; unit percentage of FOV in each dimension xyz (converted to pixels in optrg.py; rounds to nearest pixel); max possible shifts (in patch if piecewise, or whole fov if not); z ignored if register_in_2d=1; shifts are computed using a subregion of fov with outermost max_shifts removed (for template and image); this way, in case the fov drifts, the correlation (used to compute shifts) uses a constant region of image (as long as brain doesn't drift more than max_shifts); if your image drifts a lot, max_shifts has to be large, which means a small region of fov is getting correlated with template, which makes it harder to get correct shifts, especially if snr is low; so set this as small as possible to accommodate drift (the extent to which minimizing max_shifts matters depends on snr, assuming it is large enough to accommodate drift)
smlenpx_mcp = [0, 0, 0] #gaussian xyz smoothing window length (pixels) in register (registration shifts computed with smoothed data, but shifts applied to nonsmoothed data); 0 0 0 to skip
clipinterp = 1 #clip any values taken outside original range by interpolation during registration shifts, applied per frame; this happens by default in the original normcorre for matlab, but not in caiman version
registration_template_group_id = [''] #empty string to skip; list of strings, each formatted recdate_fly_trial_folderSubstring; for each string, use brackets to designate which single trial is used as template, while all trials matching string with chars inside brackets replaced with wildcard * are registered to that template; e.g.  '202406[01]_[1]_[1]_[60312]' will register all trials matching 202406*_*_*_* (if they are also matched to above file specifiers: recdate, fly, trial, folder_substring) to a template created from raw tif matching **/*312*/**/20240601_1_1*tif (or **/*312*/**/20240601_1_*trial_001*tif for flyg filename format); recordings requested above that do not match any REGISTRATION_TEMPLATE_GROUP_ID just get registered in the default way (without a user-specified template); strings cannot have overlapping matches (within brackets, or outside); template must match recording in xyz size; template is median of 5 frames, which are each mean of 10 frames, equidistant across entire stack; code will sleep (with messages) for up to 300 seconds while waiting for template to be created (in case being created while another waits to use it in parallel jobs on O2)  

chan_dn = 'all' #'all', '1', or '2'; refers to the index in the output stack from registration (suffix *cmrg_.tif), so if you discarded channel 1 in registration the output cmrg will have one channel, and if you want to denoise that one channel (which is channel 2), set chan_dn to 1 (not 2), or you can just set to 'all' and it will work always; also 2 will error if there was only one channel to begin with (ie no *chn2_cmrg*.tif exists)
denoise_volume = 1 #for denoise_volume = 1, denoise_slice_index must be 'all', and this will train on all z slices together . . . if denoise_volume = 0, denoise_slice_index must be 'all', or single index, and will trains on each z slice separately
denoise_slice_index = ['all'] #'all' or list of string ints or ints, either 'all' (all z slices) or selected integer strings . . . which z slices get denoised (not the same as which z slices are used to train model, although see above notes for denoise_volume) 
num_epochs_denoise = 10 #how many denoising epochs to run, by defult saves model after each epoch 
epoch_choose_denoise = range(1,num_epochs_denoise+1) #one-indexed, which denoising epoch to grab and stitch into single tif and move into data folder  (must exist, ie must be one of epochs_choose in denoise.py); if single number, will use that epoch, if multiple, will choose best epoch automatically (see denoise_score.py)

use_background_subtracted = 0 #1 to use the background-subtracted, registered stack (suffix *bksb_cmrg_.tif) for any job after registration, 0 to use the registered stack (without background subtraction, suffix *cmrg_.tif) for any job after registration 
use_denoised = 1  #1 to use the registered, denoised stack for any job after registration and/or denoising (suffix *cmrg_dcdn_.tif), 0 to use the registered stack (without denoising) for any job after registration and/or denoising (suffix *cmrg_.tif) 

stopband_rsc = [10,20]; #stopband frequency indices; set emperically for now; keep between 2 and half number of pixels in x dimension . . . hopefully scan noise bandwidth scales simply with imaging temporal frequency
smlensec_rsc = 0 #gaussian window length in matlab smoothdata for smoothing stack in time prior to removing scan noise (with line by line notch filter) in extremely noisy recordings
use_scannoise_removed = 0 #1 to use the stack (a mat file) with scan noise removed (suffix 'nosn_.mat', output from do_remove), for any job after do_remove, 0 to not use it; if it doesn't exist, won't error

do_crop_only = 0 #skip everything but FOV selection for all entries in regionex, must have already run motion correction if use_denoised=False, or motion correction and denoising if use_denoised=True, convenient to do for many recordings at once so extraction can be run on a batch of recordings without interruption

extract_in_2d = 1 #caiman source extraction for each plane independently (WARNING, 3D EXTRACTION REQUIRES AT LEAST 3 ELEMENTS IN EACH DIMENSION X Y and Z, OR you must REWRITE binary_closing IN CAIMAN'S THRESHOLD_COMPONENTS)
methodex = 'seed21py' #'1' (channel 1 only), '2' (channel 2 only), '12' (channel 1 and 2 independently), 'seed1mat' (channel 1 functional extraction seeded with morph rois created/saved in matlab), 'seed2mat' (same as seed1 but for channel 2), 'seed1py' (same but seeded with automated morph rois made in python), 'seed2py' (same as 'seed1py' but channel 2), 'seedeachpy' (channel 1 and 2 independently, with python-automated morph roi seed masks for each channel), 'seedeachmat' (same as seedeachpy, but using morph rois created/saved in matlab), 'seed21py' (python-automated morph roi seed mask in channel 2 seed functional extraction from channel 1), 'seed12py' (inverse of seed21py), 'seed21mat' (same as 'seed21py', but for morph rois created/saved in matlab), 'seed12mat' (inverse of 'seed21mat'); the seed*py methodex only work when extract_in_2d=True
regionex = ['pnew3'] #DO NOT USE UNDERSCORES, or any punctuation, . . . list of strings specifying names for xy rectangular or xyz cuboid fov subregions that are passed separately to source extraction; interactive plots prompt user to define z range and draw xy rectangle; use ['fullfov'] to extract from entire FOV
maskname = ['none']

## SOME OPTIONS APPLIED IN VARIOUS PARTS OF THE PIPELINE ## 

use_cluster = 0 #to speed up caiman code; registration is fast enough (less than an hour) for our normal recordings; consider using cluster if your recording is very long (>30000 frames, for example) or very high res (>512,512,20, for example); running O2 non-interactive jobs, use cluster_backend='multiprocessing' (automatically set in pl.py); i haven't gotten cluster_backend='ipyparallel' to work for that case, and haven't tried for other cases
cluster_backend = 'ipyparallel' #string, single element not in list, irrelevant if use_cluster=0; use 'multiprocessing' on O2, can run caiman code faster 

makeplots = 0 #should be 0 if running job on O2, so not a command line argument because it errors unless running in an interactive mode, like in vscode, in register calls plot_gif, in extract calls caiman_plots_all, which shows extracted components' spatial masks and timeseries,  
