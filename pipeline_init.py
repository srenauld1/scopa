
#!/usr/bin/env python

##########################################################################################################################################

#SEE README.md FOR MORE DOCUMENTATION

##########################################################################################################################################

path_storage = '' #string, single element not in list, the full path (with final slash) to the long-term storage folder you want the data copied from after and copied to before and after analysis, ignored if not on cluster, compute folder with same name as final folder path_storage will be created (if on O2, this folder is directly under your scratch folder)
do_copyfiles = 0 #0 or 1 . . . 1 does nothing but copy the files matching pattern (e.g. from path_storage to compute folder), 0 allows everything else in the pipeline to occur . . . set to 0 if you do not have access to path_storage from where you're running this script
pars_filename = '' #string, single element not in list, skip if empty, name of input argument txt file, convenient for passing same arguments to multiple stages of pipeline 

recdates = ['*'] #list of strings, as it appears in the directory and raw file filename (with hyphen not underscore for now), '*' for any 
fly = ['*'] #list of strings, fly index_extraction_param_set, '*' for any, can be len 1 or len(recdates), if len 1 and len(recdates)>1, fly will be copied to match
trial = ['*'] #list of strings, trial index_extraction_param_set, '*' for any #
folder_substrings = ['*'] #list of strings, '*' for any, match recordings only in folders containing any substring in list  
recording_index = ['all'] #list, 'all' or list of string ints or ints, if 'all', loop over all recordings matching pattern in pth_allrec_compute, if not 'all', zero indexed (can be str or int) operate on recording whose index (in sorted list of all recordings in pth_allrec_compute) matches value in recording_index

file_matching_style = 'any' #string, single element not in list, 'any' or 'each', if any, will find all files matching any combo from above lists, if each, will match files using corresponding elements of above lists

do_register = 0 #caiman normCorre registration 
do_planar_registration = 1 #one z slice at a time, for 4d data, ignored if 3d data  
len_window_smooth_t = 0 #smoothing window length, uses 1d gaussian with std that is (by default) one-tenth len_window_smooth_t - 1 (since gaussian window radius is truncated at 5 std), (len_window_smooth_t = 0 skips smoothing)

do_background_subtraction = 0 #prior to registration, won't happen unless do_register = 1 
bg_patch_halfwidth = 3 #half width of patch over which mean is computed for background subtraction (patch is a line in x)

do_separate = 0 #write each z slice to separate tif prior to denoising, running this at some point is required for deepcad denoising to work on 4d data

do_denoise = 0 #deepcad denoising(from the more recent deepcadrt, although this is not real time), input must be motion_corrected 
denoise_volume = 1 #for denoise_volume = 1, denoise_slice_index must be 'all', and this will train on all z slices together . . . if denoise_volume = 0, denoise_slice_index must be 'all', or single index, and will trains on each z slice separately
denoise_slice_index = ['all'] #'all' or list of string ints or ints, either 'all' (all z slices) or selected integer strings . . . which z slices get denoised (not the same as which z slices are used to train model, although see above notes for denoise_volume) 
num_epochs_denoise = 5 #how many denoising epochs to run, by defult saves model after each epoch 

epoch_choose_denoise = num_epochs_denoise #which denoising epoch to grab and stitch into single tif and move into data folder  (must exist, ie must be one of epochs_choose in denoise.py)
use_denoised = 0 #use the deepcad denoised data, or just the caiman registered data, if 1,  

do_stitch = 0 #do nothing but stitch the denoised tifs into single tif and move from denoising into data folder (this is normally first part of extract function below, but this will skip the extraction part) . . . stitching is not part of denoise function because it is cpu intensive and causes jobs to pend forever if requesting sufficient CPU AND GPU

do_extract = 0 #caiman source extraction 
region_extraction = ['pb'] #list of strings specifying names for xy rectangular or xyz cuboid fov subregions that are passed separately to source extraction; interactive plots prompt user to define z range and draw xy rectangle; use ['fullfov'] to extract from entire FOV
do_planar_extraction = 1 #caiman source extraction for each plane independently (WARNING, 3D EXTRACTION REQUIRES AT LEAST 3 ELEMENTS IN EACH DIMENSION X Y and Z, OR you must REWRITE binary_closing IN CAIMAN'S THRESHOLD_COMPONENTS)
use_background_subtracted = 0 #use the registered data that had background subtracted before registration  
index_extraction_param_set = 'default' #one element, not in list, 'default' or string int or int, specifies the extraction param set (set is created in configs.py, which uses map2params.py to help create the param sets) 

do_cropping_session = 0 #skip everything but FOV selection for all entries in region_extraction, must have already run motion correction if use_denoised=False, or motion correction and denoising if use_denoised=True, convenient to do for many recordings at once so extraction can be run on a batch of recordings in pth_allrecs without interruption

do_plots = 0 #should be 0 if running job on O2, so not a command line argument because it errors unless running in an interactive mode, like in vscode, in register calls plot_gif, in extract calls caiman_plots_all, which shows extracted components' spatial masks and timeseries,  

# caiman note on starting cluster
# The default backend mode for parallel processing is through the multiprocessing package. 
# To make sure that this package is viewable from everywhere before starting the notebook 
# these commands need to be executed from the terminal (in Linux and Windows):
# export MKL_NUM_THREADS=1 
# export OPENBLAS_NUM_THREADS=1 
do_cluster = 0 #leave as 0 because cluster isn't working (except on google colab), and typical recordings (size 128 x 256 x 20 x 3000) don't take that long
cluster_backend = 'ipyparallel' #string, single element not in list, irrelevant if do_cluster=0


import sys
import os
import shutil 
from parse_args import parse_command_line
from paths_scopa import make_paths
from choose_files import choose_files
from pathlib import Path

if len(sys.argv)>1:
    
  [pars_filename, do_copyfiles, path_storage, index_extraction_param_set, region_extraction, do_background_subtraction, do_register, do_planar_registration, len_window_smooth_t, do_separate, do_denoise, denoise_volume, 
  denoise_slice_index, num_epochs_denoise, epoch_choose_denoise, do_stitch, do_cropping_session, do_extract, do_planar_extraction, use_denoised, use_background_subtracted, recdates, fly, trial, folder_substrings,
  recording_index, file_matching_style] = \
    parse_command_line(pars_filename = pars_filename, do_copyfiles = do_copyfiles, path_storage = path_storage, index_extraction_param_set = index_extraction_param_set, region_extraction = region_extraction, 
                      do_background_subtraction = do_background_subtraction, do_register = do_register, do_planar_registration = do_planar_registration, len_window_smooth_t = len_window_smooth_t, do_separate = do_separate, do_denoise = do_denoise, 
                      denoise_volume = denoise_volume, denoise_slice_index = denoise_slice_index, num_epochs_denoise = num_epochs_denoise, epoch_choose_denoise = epoch_choose_denoise, do_stitch = do_stitch, do_extract = do_extract, 
                      do_planar_extraction = do_planar_extraction, use_denoised = use_denoised, use_background_subtracted = use_background_subtracted, 
                      recdates = recdates, fly = fly, trial = trial, folder_substrings = folder_substrings, do_cropping_session = do_cropping_session, recording_index = recording_index, file_matching_style = file_matching_style)


[pth_allrec, pth_allrec_compute, pth_allrec_storage, pth_denoising, do_copyfiles] = make_paths(do_copyfiles, path_storage)


if do_stitch or do_cropping_session:
  print("forcing everything to zero since do_stitch or do_cropping_session is true")
  do_register = 0
  do_denoise = 0
  do_extract = 0
else:
  if do_denoise:
    print("forcing do_register and do_extract and do_cluster to zero because you're trying to denoise")
    do_register = 0
    do_extract = 0
    do_cluster = 0
    if denoise_volume==0 and len(denoise_slice_index)>1 and denoise_slice_index != ['all'] and denoise_slice_index!='all':
        raise Exception ("if denoise_volume==0, must either pass single denoise_slice_index (not multiple), or denoise_slice_index must be all. . . IS THIS STILL TRUE?")
    if denoise_volume==1 and denoise_slice_index != ['all'] and denoise_slice_index!='all':
        raise Exception ("if denoise volume == 1, denoise slice index must be 'all' (for now, although code can be adapted to accept z subset range) . . . IS THIS STILL TRUE?")
  elif do_register or do_extract:
    print("forcing do_denoise to zero because either do_register or do_extract is true")
    do_denoise = 0


if not do_copyfiles:

  import numpy as np
  import cv2
  import logging
  from helpers import separate_z_slices_for_denoising, separate_z_slices_for_denoising_carls_old_project, stitch_denoised_slices, stitch_denoised_slices_carls_old_project
 

  if do_register or do_extract or do_stitch or do_cropping_session:

    try:
        cv2.setNumThreads(0) #don't think this is necessary 
    except:
        pass

    try:
        if __IPYTHON__: #for debugging only. allows to reload classes when changed
            get_ipython().magic('load_ext autoreload')
            get_ipython().magic('autoreload 2')
    except NameError:
        pass

    try:
        shell = get_ipython().__class__.__name__
        print(shell)
    except NameError:
        print("in py file probably")      # Probably standard Python interpreter

    from register import register
    from extract import extract
    import logging
    logging.basicConfig(format=
                        "%(relativeCreated)12d [%(filename)s:%(funcName)20s():%(lineno)s]"\
                        "[%(process)d] %(message)s",
                        #filename="/n/scratch3/users/c/caw846/ctmp/caiman.log",
                        level=logging.WARNING,
                        )

  elif do_denoise:
      from denoise import denoise

[pth_tif_read_all, pth_fldr_all, fn_prefix_all, pth_prefix_all, pth_md_all, carls_old_project_all] = \
  choose_files(pth_allrec, recdates, fly, trial, folder_substrings, recording_index, file_matching_style, 
        do_register, do_separate, do_denoise, do_extract, do_cropping_session, do_stitch, 
        use_background_subtracted, use_denoised)


for ri, _ in enumerate(pth_tif_read_all):
    
    if do_copyfiles:
      
      pth_copydest = pth_allrec_compute + pth_fldr_all[ri].split('/')[-1]
      print("copying the following files: \n" + pth_tif_read_all[ri] + "\n" + pth_md_all[ri] + "\n from storage server into the following O2 directory: \n" + pth_copydest)
      Path(pth_copydest).mkdir(parents=True, exist_ok=True)
      shutil.copy(pth_tif_read_all[ri], pth_copydest)
      shutil.copy(pth_md_all[ri], pth_copydest)

    else:
      
      print("operating on the following file: \n" + pth_tif_read_all[ri] + "\n loading metadata first") 

      md = np.load(pth_md_all[ri], allow_pickle='TRUE').item()

      if do_register:
          register(pth_tif_read_all[ri], pth_prefix_all[ri], md, do_planar_registration, do_background_subtraction, 
                   bg_patch_halfwidth, len_window_smooth_t, cluster_backend, do_cluster, do_plots)

      if do_separate:
          if carls_old_project_all[ri]: 
            separate_z_slices_for_denoising_carls_old_project(pth_tif_read_all[ri], fn_prefix_all[ri], pth_denoising, md, denoise_volume)
          else:
            separate_z_slices_for_denoising(pth_tif_read_all[ri], fn_prefix_all[ri], pth_denoising, md, denoise_volume)

      if do_denoise:
          denoise(pth_denoising, fn_prefix_all[ri], md, denoise_slice_index, denoise_volume, num_epochs_denoise, carls_old_project_all[ri])

      if do_stitch: #and use_denoised
        force_stitch = 0 #stitch regardless of whether the file already exists (e.g. to use a different run or different epoch, warning this will overwrite existing stitched denoised tif)
        if not os.path.isfile(pth_tif_read_all[ri]) or force_stitch:
            if carls_old_project_all[ri]: 
                stitch_denoised_slices_carls_old_project(pth_denoising, fn_prefix_all[ri], pth_tif_read_all[ri], md, denoise_volume, epoch_choose_denoise) 
            else:
                stitch_denoised_slices(pth_denoising, fn_prefix_all[ri], pth_tif_read_all[ri], md, denoise_volume, epoch_choose_denoise) 


      if do_extract or do_cropping_session:

          extract(index_extraction_param_set, fn_prefix_all[ri], pth_prefix_all[ri], pth_tif_read_all[ri], pth_denoising, 
          md, denoise_volume, do_stitch, do_cropping_session, do_planar_extraction, use_denoised, epoch_choose_denoise,
          region_extraction, carls_old_project_all[ri], do_plots, cluster_backend, do_cluster)


print("EXITING pipeline_init.py") 

