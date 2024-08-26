

##default params for interactive mode (e.g. when pipeline_init.py is called directly, not from cxp.sh)
##these params can be changed, since these are the values that will be used in interactive mode

folder_with_all_recordings_on_storage_and_compute_filesystems = 'stacks' #folder holding all recordings you want this pipeline to operate on, if you're using do_copyfiles, this will refer to a folder on storage server and o2, tree on storage will be mirrored on o2; it is a separate variable (rather than end of pth_storage_prefix) to emphasize that it is separated off and mirrored on O2 
pth_storage_prefix = '/n/files/Neurobio/wilsonlab/wienecke/' #string, single element not in list, pth_storage_prefix+folder_with_all_recordings_on_storage_and_compute_filesystems is the path to the storage folder containing all recordings, data will be copied from here, into a folder on scratch with name (folder_with_all_recordings_on_storage_and_compute_filesystems) then analyzed, then copied back, ignored if do_copyfiles==0, 
do_copyfiles = 0 #0, 1, or 2 . . . 1 does nothing but copy the files matching pattern from pth_storage_prefix to compute folder, 2 is same but vice-versa, 0 allows everything else in the pipeline to occur . . . set to 0 if you do not have access to pth_storage_prefix from where you're running this script
fnind_fn_prefix = '' #string, the job id (before any underscore if arrayed) for the first job run by cxp.sh, will point to a file that saves filename indices to ensure files get the same index across all jobs run by cxp, make empty to skip 
pth_parsfile = '' #string, single element not in list, skip if empty, name of input argument txt file, convenient for passing same arguments to multiple stages of pipeline 
scopatmpdir = '' #string, keep empty

recdate = ['20240601'] #list of strings, as it appears in the directory and raw file filename (with hyphen not underscore for now), '*' for any 
fly = ['3'] #list of strings, fly index_extraction_param_set, '*' for any, can be len 1 or len(recdate), if len 1 and len(recdate)>1, fly will be copied to match
trial = ['1'] #list of strings, trial index_extraction_param_set, '*' for any #
folder_substring = ['*'] #list of strings, '*' for any, match recordings only in folders containing any substring in list  
recording_index = ['all'] #list, 'all' or list of zero-indexed string ints or ints, if 'all', loop over all recordings matching pattern in pth_compute, if not 'all', zero indexed (can be str or int) operate on recording whose index (in sorted list of all recordings in pth_compute) matches value in recording_index
file_matching_style = 'any' #string, single element not in list, 'any' or 'each', if any, will find all files matching any combo from above lists, if each, will match files using corresponding elements of above lists

registration_template_group_id=('') #empty string to skip; list of strings, each formatted recdate_fly_trial_folderSubstring; for each string, use brackets to designate which single trial is used as template, while all trials matching string with chars inside brackets replaced with wildcard * are registered to that template; e.g.  '202406[01]_[1]_[1]_[60312]' will register all trials matching 202406*_*_*_* (if they are also matched to above file specifiers, recdate, fly, trial, folder_substring) to a template created from raw tif matching **/*312*/**/20240601_1_1*tif (or **/*312*/**/20240601_1_*trial_001*tif for flyg filename format); recordings requested above that do not match any REGISTRATION_TEMPLATE_GROUP_ID just get registered in the default way (without a template); strings cannot have overlapping matches (within brackets, or outside); template must match recording in xyz size; template is median of 5 frames, which are each mean of 10 frames, equidistant across entire stack; code will sleep (with messages) for up to 300 seconds while waiting for template to be created (in case being created in parallel job)  

do_register = 1 #caiman normCorre registration 
register_in_2d = 1 #one z slice at a time, for 4d data, ignored if 3d data  
halfwidth_window_bgsub = 0 #half width of patch over which mean is computed for background subtraction (patch is a line in x), applied before registration, won't happejn unless do_register==1, make zero to skip, 
len_window_smooth_t_mcp_sec = 0 #smoothing window length, uses 1d gaussian with std that is (by default) one-tenth len_window_smooth_t_mcp_sec - 1 (since gaussian window radius is truncated at 5 std), (len_window_smooth_t_mcp_sec = 0 skips smoothing)

do_denoise = 0 #deepcad denoising(from the more recent deepcadrt, although this is not real time), input must be motion_corrected 
denoise_volume = 1 #for denoise_volume = 1, denoise_slice_index must be 'all', and this will train on all z slices together . . . if denoise_volume = 0, denoise_slice_index must be 'all', or single index, and will trains on each z slice separately
denoise_slice_index = ['all'] #'all' or list of string ints or ints, either 'all' (all z slices) or selected integer strings . . . which z slices get denoised (not the same as which z slices are used to train model, although see above notes for denoise_volume) 
num_epochs_denoise = 10 #how many denoising epochs to run, by defult saves model after each epoch 

do_stitch = 0 

use_background_subtracted = 0 #1 to use the background-subtracted, registered stack (suffix *bksb_cmrg_.tif) for any job after registration, 0 to use the registered stack (without background subtraction, suffix *cmrg_.tif) for any job after registration 
use_denoised = 1  #1 to use the registered, denoised stack for any job after registration and/or denoising (suffix *cmrg_dcdn_.tif), 0 to use the registered stack (without denoising) for any job after registration and/or denoising (suffix *cmrg_.tif) 
epoch_choose_denoise = range(1,num_epochs_denoise+1) #one-indexed, which denoising epoch to grab and stitch into single tif and move into data folder  (must exist, ie must be one of epochs_choose in denoise.py); if single number, will use that epoch, if multiple, will choose best epoch automatically (see denoise_score.py)

do_remove = 0 #remove scan noise (matlab script, but choose_files uses choose_files function below)
len_window_smooth_t_rsc_sec = 0 #gaussian window length in matlab smoothdata for smoothing stack in time prior to removing scan noise (with line by line notch filter) in extremely noisy recordings

use_scannoise_removed = 0 #1 to use the stack (a mat file) with scan noise removed (suffix 'nosn_.mat', output from do_remove), for any job after do_remove, 0 to not use it; if it doesn't exist, won't error

do_crop = 0 #skip everything but FOV selection for all entries in regionex, must have already run motion correction if use_denoised=False, or motion correction and denoising if use_denoised=True, convenient to do for many recordings at once so extraction can be run on a batch of recordings in pth_allrecs without interruption

do_extract = 0 #caiman source extraction 
extract_in_2d = 1 #caiman source extraction for each plane independently (WARNING, 3D EXTRACTION REQUIRES AT LEAST 3 ELEMENTS IN EACH DIMENSION X Y and Z, OR you must REWRITE binary_closing IN CAIMAN'S THRESHOLD_COMPONENTS)
regionex = ['pnew'] #DO NOT USE UNDERSCORES, or any punctuation, . . . list of strings specifying names for xy rectangular or xyz cuboid fov subregions that are passed separately to source extraction; interactive plots prompt user to define z range and draw xy rectangle; use ['fullfov'] to extract from entire FOV
index_extraction_param_set = 'default' #one element, not in list, 'default' or string int or int, specifies the extraction param set (set is created in configs.py, which uses map2params.py to help create the param sets) 

do_analysis = 0 #matlab analysis 'post', various functions in a2p.m

# caiman note on starting cluster
# The default backend mode for parallel processing is through the multiprocessing package. 
# To make sure that this package is viewable from everywhere before starting the notebook 
# these commands need to be executed from the terminal (in Linux and Windows):
# export MKL_NUM_THREADS=1 
# export OPENBLAS_NUM_THREADS=1 
use_cluster = 0 #leave as 0 because cluster isn't working (except on google colab), and typical recordings (size 128 x 256 x 20 x 3000) don't take that long
cluster_backend = 'ipyparallel' #string, single element not in list, irrelevant if use_cluster=0

makeplots = 0 #should be 0 if running job on O2, so not a command line argument because it errors unless running in an interactive mode, like in vscode, in register calls plot_gif, in extract calls caiman_plots_all, which shows extracted components' spatial masks and timeseries,  

first_job = 1 #this should always be 1 if you're running pipeline_init.py directly/interactively, first_job is only used when pipeline_init.py is called from cxp.sh, as part of a larger pipeline 
