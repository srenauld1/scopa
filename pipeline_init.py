
#!/usr/bin/env python

##########################################################################################################################################

#SEE README FILE FOR DOCUMENTATION 

##########################################################################################################################################

import sys
import re
import cv2
import datetime
import fnmatch
import os
import glob
import logging
from parse_command_line import parse_command_line
import mat73
import numpy as np
from pipeline import pipeline
from helpers import read_save_metadata
from tifffile.tifffile import imwrite
from natsort import natsorted


print(sys.executable)
env_path = sys.path

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

logging.basicConfig(format=
                    "%(relativeCreated)12d [%(filename)s:%(funcName)20s():%(lineno)s]"\
                    "[%(process)d] %(message)s",
                    #filename="/n/scratch3/users/c/caw846/ctmp/caiman.log",
                    level=logging.WARNING,
                    )


# caiman note on starting cluster
# The default backend mode for parallel processing is through the multiprocessing package. 
# To make sure that this package is viewable from everywhere before starting the notebook these commands need to be executed from the terminal (in Linux and Windows):
# export MKL_NUM_THREADS=1 #can't remember why i tried this, but i don't use it   
# export OPENBLAS_NUM_THREADS=1 #can't remember why i tried this, but i don't use it  


index_extraction_param_set = 'default' #specifies the extraction param set (set is created in configs.py, which uses map2params.py to help create the param sets) 
recdates = ['20230627'] #list of strings, as it appears in the directory and raw file filename (with hyphen not underscore for now), '*' for any 
fly = '*' #string, fly index_extraction_param_set, '*' for any 
trial = '*' #string, trial index_extraction_param_set, '*' for any 
region_extraction = ['pb', 'gar', 'gal', 'no'] #list of strings specifying names for xy rectangular or xyz cuboid fov subregions that are passed separately to source extraction; interactive plots prompt user to define z range and draw xy rectangle; use ['fullfov'] to extract from entire FOV
do_motion_correction = 0 #caiman normCorre 
do_background_subtraction = 0 #won't happen unless do_motion_correction = True 
do_denoise = 0 #deepcad (from the more recent deepcadrt, although this is not real time), input must be motion_corrected 
denoise_volume = 0 #denoise_volume = 1 trains on all z slices listed in denoise_slice_index together, denoise_volume = 0 trains on each z slice listed in denoise_slice_index separately
denoise_slice_index = 'all' #which z slices to denoise
do_extraction = 0 #caiman source extraction 
do_planar_extraction = 0 #caiman source extraction for each plane independently (WARNING, 3D EXTRACTION REQUIRES AT LEAST 3 ELEMENTS IN EACH DIMENSION X Y and Z, OR you must REWRITE binary_closing IN CAIMAN'S THRESHOLD_COMPONENTS)
use_background_subtracted = 0 #won't happen unless do_motion_correction = True 
use_denoised = 0 #use the deepcad denoised data, or just the caiman registered data 
do_cropping_session = 0 #skip everything but FOV selection for all entries in region_extraction, must have already run motion correction if use_denoised=False, or motion correction and denoising if use_denoised=True, convenient to do for many recordings at once so extraction can be run on a batch of recordings in pth_allrecs without interruption
recording_index = 'all' #if 'all', loop over all recordings matching pattern in pth_allrec, if not 'all', zero indexed (can be str or int) specifying to operate on recording whose index (in sorted list of all recordings in pth_allrec) matches value in recording_index

bg_patch_halfwidth = 3 #half width of patch over which mean is computed for background subtraction (patch is a line in x)
do_plots = 0 #plots were for old version of this pipeline, and I haven't verified that plots run without error, so I leave this 0
do_cluster = 0 #leave as 0 because cluster isn't working (except on colab), and typical recordings (size 128 x 256 x 20 x 3000) don't take that long
cluster_backend = 'ipyparallel' #irrelevant if do_cluster=0

if (re.search("/Users/wienecke/", env_path[0])):
  pth_allrec = '/Users/wienecke/Documents/ambrose/stacks/'
  if do_denoise: #need gpu, don't have one locally 
     raise Exception("no gpu, make do_denoise false")
elif (re.search("/home/caw846/", env_path[0])):
  pth_allrec = '/n/scratch3/users/c/caw846/stacks/'
  cluster_backend = 'SLURM' #this failed on O2, and so did cluster_backend = 'ipyparallel' 
elif (re.search("/home/users/wienecke/", env_path[0])):
  pth_allrec = '/scratch/users/wienecke/stacks/'
elif (re.search('/content', env_path[0])):
  pth_allrec = '/content/drive/MyDrive/stacks/'
  do_cluster = 1 #cluster worked on colab 
  index_extraction_param_set = 'default' #not set up for arguments in colab 

pth_super = '/'.join(pth_allrec.split('/')[:-2])
pth_denoising = os.path.join(pth_super, 'denoising')
if not os.path.exists(pth_denoising):
    os.mkdir(pth_denoising)


if len(sys.argv)>1:
  [index_extraction_param_set, region_extraction, do_background_subtraction, do_motion_correction, 
  do_denoise, denoise_volume, denoise_slice_index, do_extraction, do_planar_extraction, use_denoised, use_background_subtracted,
  recdates, fly, trial, do_cropping_session, 
  recording_index] = parse_command_line(index_extraction_param_set = index_extraction_param_set, 
                      region_extraction = region_extraction, do_background_subtraction = do_background_subtraction, do_motion_correction = do_motion_correction, 
                      do_denoise = do_denoise, denoise_volume = denoise_volume, denoise_slice_index = denoise_slice_index, do_extraction = do_extraction, do_planar_extraction = do_planar_extraction, 
                      use_denoised = use_denoised, use_background_subtracted = use_background_subtracted, recdates = recdates, fly = fly, trial = trial, do_cropping_session = do_cropping_session, 
                      recording_index = recording_index)


print("STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY")
print(index_extraction_param_set)
print(region_extraction)
print(do_motion_correction)
print(do_denoise)
print(denoise_volume)
print(denoise_slice_index)
print(do_extraction)
print(do_planar_extraction)
print(recdates)
print(fly)
print(trial)
print(do_cropping_session)
print(recording_index)

countz = -1 #so first one is zero, since recording_index is zero indexed 
for recording_date in recdates:

  pth_fldrs_pattern = pth_allrec + recording_date + '-' + fly + '_*/'
  fn_pattern = recording_date + '-' + fly + '*_trial_00' + trial + '_*.tif'
  pth_fldrs = natsorted(glob.glob(pth_fldrs_pattern))
  old_mat_files = 0
  if not pth_fldrs:  #if no matches try another filename pattern (files from previous project)
    old_mat_files = 1
    pth_fldrs_pattern = pth_allrec + recording_date + '_' + fly + '_*/'
    fn_pattern = recording_date + '_' + fly + '_' + trial + '_stackraw_.mat'
    pth_fldrs = natsorted(glob.glob(pth_fldrs_pattern))

  for pth_fldr in pth_fldrs:

    print(pth_fldr)
    
    pth_allfiles = natsorted(os.listdir(pth_fldr))

    for f in pth_allfiles:

      if fnmatch.fnmatch(f, fn_pattern):
        
        countz = countz + 1

        if recording_index == 'all' or (recording_index !='all' and countz==recording_index): #if 'all', do all files matching pattern, otherwise only file matching index
          
          # tmpdate = datetime.datetime.now().strftime("%Y%m%dT%H%M%S") 
          # sys.stdout = open(pth_fldr + '/' + tmpdate + '.txt', 'w')
          # sys.stderr = sys.stdout

          pth_datafile = pth_fldr + f
          print(pth_datafile)

          if old_mat_files:
            fn_prefix = '_'.join(f.split('_')[:3])
          else:
            fn_prefix = f.split('_')[0].split('-')[0] + '_' + f.split('_')[0].split('-')[1]  + '_' + f.split('_')[-2][-1] #change hyphen to underscore
          
          pth_prefix = pth_fldr + fn_prefix
          if do_background_subtraction or (use_background_subtracted and not do_motion_correction):
            pth_tif_dn = pth_prefix + '_cmrg_bksb_dcdn_.tif'        
            pth_tif_reg_tmp = pth_prefix + '_cmrg_bksb_tmp_.tif'
            pth_tif_reg = pth_prefix + '_cmrg_bksb_.tif'
          else:
            pth_tif_dn = pth_prefix + '_cmrg_dcdn_.tif'         
            pth_tif_reg_tmp = pth_prefix + '_cmrg_tmp_.tif'
            pth_tif_reg = pth_prefix + '_cmrg_.tif'
          
          pth_md = pth_prefix + '_metadatanew_.mat'
          pth_md_npy = pth_md[:-4] + '.npy'

          if old_mat_files: #for my old project 

            pth_datafile_new = pth_datafile[:-4] + '.tif'

            if os.path.isfile(pth_md_npy) and os.path.isfile(pth_datafile_new): #
              md = np.load(pth_md_npy, allow_pickle='TRUE').item() #if it exists, the md file will too 
              pth_datafile = pth_datafile_new
            else:
              mat = mat73.loadmat(pth_datafile)
              Y = mat['stackRaw_pmc'] # Y = mat['stackRaw_mc']
              mnmv = np.min(Y)
              Y = Y - mnmv #make movie nonnegative (not sure this is necessary)
              print("MIN OF STACKRAW_PMC MAT FILE " + str(mnmv))
              Y = np.transpose(Y, (2, 0, 1)) #put in order t y x (not t x y) #stackraw_mc may be flipped relative to stackraw pmc
              pth_datafile = pth_datafile_new
              imwrite(pth_datafile, Y.astype('uint16')) #write as t x y z (singleton z at end)
              md = read_save_metadata(pth_datafile, pth_md, pth_md_npy, mat_file_shape = Y.shape)

          else:
            
            fn_prefix = f.split('_')[0].split('-')[0] + '_' + f.split('_')[0].split('-')[1]  + '_' + f.split('_')[-2][-1] #change hyphen to underscore
            if os.path.isfile(pth_md_npy):
               md = np.load(pth_md_npy, allow_pickle='TRUE').item()
            else:
               md = read_save_metadata(pth_datafile, pth_md, pth_md_npy, mat_file_shape = None)


          pipeline(index_extraction_param_set, pth_datafile, fn_prefix, pth_prefix, pth_tif_reg_tmp, pth_tif_reg, pth_tif_dn, 
                        pth_denoising, md, do_background_subtraction, bg_patch_halfwidth, do_motion_correction, 
                        do_denoise, denoise_volume, denoise_slice_index, do_cropping_session, do_extraction, do_planar_extraction, 
                        use_background_subtracted, use_denoised, region_extraction, do_plots, cluster_backend, do_cluster)


