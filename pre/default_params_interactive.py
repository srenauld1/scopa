

##default params for interactive mode (e.g. when pipeline_init.py is called directly, not from cxp.sh)
##these params can be changed, since these are the values that will be used in interactive mode

folder_with_all_recordings_on_storage_and_compute_filesystems = 'stacks' #folder holding all recordings you want this pipeline to operate on, if you're using do_copyfiles, this will refer to a folder on storage server and o2, tree on storage will be mirrored on o2 
pth_storage_prefix = '/n/files/Neurobio/wilsonlab/wienecke/' #string, single element not in list, pth_storage_prefix+folder_with_all_recordings_on_storage_and_compute_filesystems is the path to the storage folder containing all recordings, data will be copied from here, into a folder on scratch with name (folder_with_all_recordings_on_storage_and_compute_filesystems) then analyzed, then copied back, ignored if do_copyfiles==0, 
do_copyfiles = 0 #0, 1, or 2 . . . 1 does nothing but copy the files matching pattern from pth_storage_prefix to compute folder, 2 is same but vice-versa, 0 allows everything else in the pipeline to occur . . . set to 0 if you do not have access to pth_storage_prefix from where you're running this script
fnind_fn_prefix = '' #string, the job id (before any underscore if arrayed) for the first job run by cxp.sh, will point to a file that saves filename indices to ensure files get the same index across all jobs run by cxp, make empty to skip 
pth_parsfile = '' #string, single element not in list, skip if empty, name of input argument txt file, convenient for passing same arguments to multiple stages of pipeline 
scopatmpdir = '' #string, keep empty

recdate = ['20230627'] #list of strings, as it appears in the directory and raw file filename (with hyphen not underscore for now), '*' for any 
fly = ['*'] #list of strings, fly index_extraction_param_set, '*' for any, can be len 1 or len(recdate), if len 1 and len(recdate)>1, fly will be copied to match
trial = ['*'] #list of strings, trial index_extraction_param_set, '*' for any #
folder_substring = ['*'] #list of strings, '*' for any, match recordings only in folders containing any substring in list  
recording_index = ['all'] #list, 'all' or list of string ints or ints, if 'all', loop over all recordings matching pattern in pth_compute, if not 'all', zero indexed (can be str or int) operate on recording whose index (in sorted list of all recordings in pth_compute) matches value in recording_index
file_matching_style = 'any' #string, single element not in list, 'any' or 'each', if any, will find all files matching any combo from above lists, if each, will match files using corresponding elements of above lists

do_register = 0 #caiman normCorre registration 
register_in_2d = 1 #one z slice at a time, for 4d data, ignored if 3d data  
len_window_bgsub = 0 #full width of patch over which mean is computed for background subtraction (patch is a line in x), applied before registration, won't happejn unless do_register==1, make zero to skip, 
len_window_smooth_t_mcp = 0 #smoothing window length, uses 1d gaussian with std that is (by default) one-tenth len_window_smooth_t_mcp - 1 (since gaussian window radius is truncated at 5 std), (len_window_smooth_t_mcp = 0 skips smoothing)

do_separate = 0 #write each z slice to separate tif prior to denoising, running this at some point is required for deepcad denoising to work on 4d data

do_denoise = 0 #deepcad denoising(from the more recent deepcadrt, although this is not real time), input must be motion_corrected 
denoise_volume = 1 #for denoise_volume = 1, denoise_slice_index must be 'all', and this will train on all z slices together . . . if denoise_volume = 0, denoise_slice_index must be 'all', or single index, and will trains on each z slice separately
denoise_slice_index = ['all'] #'all' or list of string ints or ints, either 'all' (all z slices) or selected integer strings . . . which z slices get denoised (not the same as which z slices are used to train model, although see above notes for denoise_volume) 
num_epochs_denoise = 5 #how many denoising epochs to run, by defult saves model after each epoch 

use_background_subtracted = 0 #use the registered data that had background subtracted before registration  
use_denoised = 1 #use the deepcad denoised data, or just the caiman registered data, if 1,  
epoch_choose_denoise = num_epochs_denoise #which denoising epoch to grab and stitch into single tif and move into data folder  (must exist, ie must be one of epochs_choose in denoise.py)

do_stitch = 0 #do nothing but stitch the denoised tifs into single tif and move from denoising into data folder (this is normally first part of extract function below, but this will skip the extraction part) . . . stitching is not part of denoise function because it is cpu intensive and causes jobs to pend forever if requesting sufficient CPU AND GPU

do_remove = 0 #remove scan noise (matlab script, but choose_files uses choose_files function below)
len_window_smooth_t_rsc = 30 #gaussian window length in matlab smoothdata for smoothing stack in time prior to removing scan noise (with line by line notch filter) in extremely noisy recordings

do_crop = 0 #skip everything but FOV selection for all entries in regionex, must have already run motion correction if use_denoised=False, or motion correction and denoising if use_denoised=True, convenient to do for many recordings at once so extraction can be run on a batch of recordings in pth_allrecs without interruption

do_extract = 1 #caiman source extraction 
extract_in_2d = 1 #caiman source extraction for each plane independently (WARNING, 3D EXTRACTION REQUIRES AT LEAST 3 ELEMENTS IN EACH DIMENSION X Y and Z, OR you must REWRITE binary_closing IN CAIMAN'S THRESHOLD_COMPONENTS)
regionex = ['pb'] #DO NOT USE UNDERSCORES, or any punctuation, . . . list of strings specifying names for xy rectangular or xyz cuboid fov subregions that are passed separately to source extraction; interactive plots prompt user to define z range and draw xy rectangle; use ['fullfov'] to extract from entire FOV
index_extraction_param_set = 'default' #one element, not in list, 'default' or string int or int, specifies the extraction param set (set is created in configs.py, which uses map2params.py to help create the param sets) 

do_analysis = 0 #matlab analysis, various functions in analyze_movie

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
