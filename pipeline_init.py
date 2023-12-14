
#!/usr/bin/env python

##########################################################################################################################################

#SEE README FILE FOR DOCUMENTATION 

##########################################################################################################################################

data_folder_path_on_storage_server = '/n/files/Neurobio/wilsonlab/wienecke/stacks/' #the full path (include closing slash) to the long-term storage folder you want the data copied from and to before and after analysis, ignored if not on cluster 
do_copyfiles = '' #LEAVE THIS BLANK FOR NOW IT DOESN'T WORK YET ignored on local machine, 'in' or 'out' does nothing but copy the files matching pattern (e.g. in from storage to compute server, out vice versa), empty string '' allows everything else in the pipeline to occur 

recdates = ['20231120'] #list of strings, as it appears in the directory and raw file filename (with hyphen not underscore for now), '*' for any 
fly = '*' #string, fly index_extraction_param_set, '*' for any 
trial = '*' #string, trial index_extraction_param_set, '*' for any #
recording_index = 'all' #'all' #if 'all', loop over all recordings matching pattern in pth_allrec_compute, if not 'all', zero indexed (can be str or int) specifying to operate on recording whose index (in sorted list of all recordings in pth_allrec_compute) matches value in recording_index

do_register = 1 #caiman normCorre registration 
do_planar_registration = 1 #one z slice at a time, for 4d data, ignored if 3d data  
len_window_smooth_t = 0 #smoothing window length, uses 1d gaussian with std that is (by default) one-tenth len_window_smooth_t - 1 (since gaussian window radius is truncated at 5 std), (len_window_smooth_t = 0 skips smoothing)

do_background_subtraction = 0 #prior to registration, won't happen unless do_register = 1 
bg_patch_halfwidth = 3 #half width of patch over which mean is computed for background subtraction (patch is a line in x)

do_denoise = 0 #deepcad denoising(from the more recent deepcadrt, although this is not real time), input must be motion_corrected 
denoise_volume = 1 #for denoise_volume = 1, denoise_slice_index must be 'all', and this will train on all z slices together . . . if denoise_volume = 0, denoise_slice_index must be 'all', or single index, and will trains on each z slice separately
denoise_slice_index = 'all' #either 'all' (all z slices) or a single number (a single z slice) . . . this is which z slices get denoised (not the same as which z slices are used to train model, although see above notes for denoise_volume) 

do_extract = 0 #caiman source extraction 
region_extraction = ['fullfov'] #list of strings specifying names for xy rectangular or xyz cuboid fov subregions that are passed separately to source extraction; interactive plots prompt user to define z range and draw xy rectangle; use ['fullfov'] to extract from entire FOV
do_planar_extraction = 1 #caiman source extraction for each plane independently (WARNING, 3D EXTRACTION REQUIRES AT LEAST 3 ELEMENTS IN EACH DIMENSION X Y and Z, OR you must REWRITE binary_closing IN CAIMAN'S THRESHOLD_COMPONENTS)
use_background_subtracted = 0 #use the registered data that had background subtracted before registration  
use_denoised = 0 #use the deepcad denoised data, or just the caiman registered data 
index_extraction_param_set = 'default' #specifies the extraction param set (set is created in configs.py, which uses map2params.py to help create the param sets) 

do_cropping_session = 0 #skip everything but FOV selection for all entries in region_extraction, must have already run motion correction if use_denoised=False, or motion correction and denoising if use_denoised=True, convenient to do for many recordings at once so extraction can be run on a batch of recordings in pth_allrecs without interruption

# caiman note on starting cluster
# The default backend mode for parallel processing is through the multiprocessing package. 
# To make sure that this package is viewable from everywhere before starting the notebook 
# these commands need to be executed from the terminal (in Linux and Windows):
# export MKL_NUM_THREADS=1 
# export OPENBLAS_NUM_THREADS=1 
do_cluster = 0 #leave as 0 because cluster isn't working (except on google colab), and typical recordings (size 128 x 256 x 20 x 3000) don't take that long
cluster_backend = 'ipyparallel' #irrelevant if do_cluster=0

do_plots = 0 #in register calls plot_gif, in extract calls caiman_plots_all, which shows extracted components' spatial masks and timeseries,  

import sys
from parse_command_line import parse_command_line
from paths import makepaths

if len(sys.argv)>1:
  [do_copyfiles, data_folder_path_on_storage_server, index_extraction_param_set, region_extraction, do_background_subtraction, do_register, do_planar_registration, len_window_smooth_t, do_denoise, denoise_volume, 
   denoise_slice_index, do_extract, do_planar_extraction, use_denoised, use_background_subtracted, recdates, fly, trial, 
   do_cropping_session, recording_index] = \
    parse_command_line(do_copyfiles = do_copyfiles, data_folder_path_on_storage_server = data_folder_path_on_storage_server, index_extraction_param_set = index_extraction_param_set, region_extraction = region_extraction, 
                       do_background_subtraction = do_background_subtraction, do_register = do_register, do_planar_registration = do_planar_registration, len_window_smooth_t = len_window_smooth_t, do_denoise = do_denoise, 
                       denoise_volume = denoise_volume, denoise_slice_index = denoise_slice_index, do_extract = do_extract, 
                       do_planar_extraction = do_planar_extraction, use_denoised = use_denoised, use_background_subtracted = use_background_subtracted, 
                       recdates = recdates, fly = fly, trial = trial, do_cropping_session = do_cropping_session, recording_index = recording_index)


[pth_allrec, pth_allrec_compute, pth_allrec_storage, pth_denoising, do_copyfiles] = \
  makepaths(do_copyfiles, data_folder_path_on_storage_server)


if do_cropping_session or do_copyfiles:
  print("forcing everything to zero for fov cropping session since do_cropping_session==1")
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
        raise Exception ("if denoise_volume==0, must either pass single denoise_slice_index (not multiple), or denoise_slice_index must be all")
    if denoise_volume==1 and denoise_slice_index != ['all'] and denoise_slice_index!='all':
        raise Exception ("if denoise volume == 1, denoise slice index must be 'all' (for now, although code can be adapted to accept z subset range)")
  elif do_register or do_extract:
    print("forcing do_denoise to zero because either do_register or do_extract is true")
    do_denoise = 0


import shutil 
from choose_files import choose_files

if not do_copyfiles:

  import cv2
  import logging

  if do_register or do_extract or do_cropping_session:

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

   
[pth_datafile_all, pth_fldr_all, fn_prefix_all, pth_prefix_all, pth_tif_reg_tmp_all, pth_tif_reg_tmp2_all, pth_tif_reg_all, pth_tif_dn_all, md_all] = \
  choose_files(recdates, pth_allrec, fly, trial, recording_index, do_background_subtraction, 
        use_background_subtracted, do_register)

for ri, _ in enumerate(pth_datafile_all):
    
    if do_copyfiles=='in':
      pth_copydest = pth_allrec_compute + pth_fldr_all[ri].split('/')[-1]
      shutil.copytree(pth_fldr_all[ri], pth_copydest) #move the whole folder from storage server to compute server, overwriting existing 

    elif do_copyfiles=='out':
      pth_copydest = pth_allrec_storage + pth_fldr_all[ri].split('/')[-1]
      shutil.copytree(pth_fldr_all[ri], pth_copydest) #move the whole folder from compute server to storage server, overwriting existing 
       
    else:
    
      if do_register:
          register(pth_datafile_all[ri], fn_prefix_all[ri], pth_prefix_all[ri], pth_tif_reg_tmp_all[ri], pth_tif_reg_tmp2_all[ri], 
              pth_tif_reg_all[ri], pth_denoising, md_all[ri], do_planar_registration, do_background_subtraction, bg_patch_halfwidth, len_window_smooth_t,
              denoise_volume, cluster_backend, do_cluster, do_plots)

      if do_denoise:
          denoise(pth_denoising, fn_prefix_all[ri], md_all[ri]['dims'], md_all[ri]['volrate'], denoise_slice_index, denoise_volume)

      if do_extract or do_cropping_session:
          extract(index_extraction_param_set, fn_prefix_all[ri], pth_prefix_all[ri], pth_tif_reg_all[ri], pth_tif_dn_all[ri], pth_denoising, 
          md_all[ri], denoise_volume, do_cropping_session, do_planar_extraction, use_denoised, 
          region_extraction, do_plots, cluster_backend, do_cluster)

