
#!/usr/bin/env python

import sys

print(sys.executable)

import re
import cv2
import datetime
import fnmatch
import os
import glob
import logging
import os

import mat73

try:
    cv2.setNumThreads(0)
except:
    pass

try:
    if __IPYTHON__:
        # this is used for debugging purposes only. allows to reload classes
        # when changed
        get_ipython().magic('load_ext autoreload')
        get_ipython().magic('autoreload 2')
except NameError:
    pass

from pipeline import pipeline_full
from parse_command_line import parse_command_line

logging.basicConfig(format=
                          "%(relativeCreated)12d [%(filename)s:%(funcName)20s():%(lineno)s] [%(process)d] %(message)s",
                    # filename="/tmp/caiman.log",
                    #level=logging.INFO,
                    )

# export MKL_NUM_THREADS=1
# export OPENBLAS_NUM_THREADS=1


#@title choose files and initialize cnmf params object (entry point)

#OLD MAT FILES recdates ARE 6 DIGITS NOT 8 (YEAR IS 2 NOT 4)
#recdates = ['231028'] #date-fly, as it appears in the directory and raw file filename (with hyphen not underscore)

index = 0
recdates = ['*'] #list , as it appears in the directory and raw file filename (with hyphen not underscore)
fly = '*'
trial = '*' # '*' for any trial in folder
region_extraction = ['pb', 'gar', 'gal', 'no'] #list
do_motion_correction = False
do_denoise = False
do_extraction = True
do_planar_extraction = False #WARNING, CAN ONLY DO 3D WITH AT LEAST LENGTH 3 IN EACH DIMENSION, OR REWRITE/ADAPT binary_closing IN CAIMAN'S THRESHOLD_COMPONENTS
do_cropping_session = False
array_index = 2

do_plots = 0
anatomical_stack = False

env_path = sys.path
server = 1
cluster_backend = 'ipyparallel'
if (re.search("/Users/wienecke/", env_path[0])):
  server = 0
  pth_prefix = '/Users/wienecke/Documents/ambrose/stacks/'
  if do_denoise: #need gpu, don't have one locally 
     raise Exception("no local gpu, make do_denoise false")
elif (re.search("/home/caw846/", env_path[0])):
  server = 0

  pth_prefix = '/n/scratch3/users/c/caw846/stacks/'
  cluster_backend = 'SLURM'

elif (re.search("/home/users/wienecke/", env_path[0])):
  pth_prefix = '/scratch/users/wienecke/stacks/'
elif (re.search('/content', env_path[0])):
  pth_prefix = '/content/drive/MyDrive/stacks/'

working_dir = '/'.join(pth_prefix.split('/')[:-2])
datasets_path_processing = os.path.join(working_dir, 'denoising_in_progress')
if not os.path.exists(datasets_path_processing):
    os.mkdir(datasets_path_processing)
datasets_path_complete = os.path.join(working_dir, 'denoised')
if not os.path.exists(datasets_path_complete):
    os.mkdir(datasets_path_complete)

if (re.search('/content', env_path[0])): #not set up for arguments in colab
  index = None

print(sys.argv)

if len(sys.argv)>1:
   [index, region_extraction, do_motion_correction, 
   do_denoise, do_extraction, do_planar_extraction, 
   recdates,  fly, trial, do_cropping_session, 
   array_index] = parse_command_line(index = index, region_extraction = region_extraction, do_motion_correction = do_motion_correction, 
                       do_denoise = do_denoise, do_extraction = do_extraction, do_planar_extraction = do_planar_extraction, 
                       recdates = recdates, fly = fly, trial = trial, do_cropping_session = do_cropping_session, 
                       array_index = array_index)

print("STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY")
print(index)
print(region_extraction)
print(do_motion_correction)
print(do_denoise)
print(do_extraction)
print(do_planar_extraction)
print(recdates)
print(fly)
print(trial)
print(do_cropping_session)
print(array_index)

if anatomical_stack==True:
  dims_spacetime_original = [80, 164, 140, 256]
  flyback = 51
  dims_spacetime_original_noflyback = [dims_spacetime_original[0], dims_spacetime_original[1]-flyback, dims_spacetime_original[2], dims_spacetime_original[3]]

else:
  dims_spacetime_original = [3047, 20, 140, 256] #manual
  flyback = 5
  dims_spacetime_original_noflyback = [dims_spacetime_original[0], dims_spacetime_original[1]-flyback, dims_spacetime_original[2], dims_spacetime_original[3]]


countz = 0
for recording_date in recdates:

  tmpdate = datetime.datetime.now().strftime("%Y%m%dT%H%M%S") #create extraction ID, one for each recordingID

  if anatomical_stack:
    fn_pattern = recording_date + '_hires_.tif'
    pth_fldr = sorted(glob.glob(pth_fldr_pattern))
  else:
    old_mat_files = 0
    pth_fldr_pattern = pth_prefix + recording_date + '-' + fly + '_*/'
    fn_pattern = recording_date + '-' + fly + '*_trial_00' + trial + '_*.tif'
    pth_fldr = sorted(glob.glob(pth_fldr_pattern))
    if not pth_fldr:  #if no matches try another filename pattern
      old_mat_files = 1
      do_motion_correction = False
      pth_fldr_pattern = pth_prefix + recording_date + '_' + fly + '/'
      fn_pattern = recording_date + '_' + fly + '_' + trial + '_stackRaw_mc_.mat'
      pth_fldr = sorted(glob.glob(pth_fldr_pattern))

  for ff in pth_fldr:

    print(ff)
    
    sorteddirlist = sorted(os.listdir(ff))

    for f in sorteddirlist:

      if fnmatch.fnmatch(f,fn_pattern):

        countz = countz + 1
        if array_index==0 or (array_index!=0 and countz==array_index):
          
          pth_datafile = ff + f
          print(pth_datafile)

          metafile_pattern = ff + 'registration_00' + f.split('_')[-2][-1] + '/imagingData*.mat'
          pth_md = sorted(glob.glob(metafile_pattern))
          if pth_md:
            matty = mat73.loadmat(pth_md[0])
            numvol = int(matty['SI']['hStackManager']['actualNumVolumes'])
            numslice_withflyback = int(matty['SI']['hStackManager']['numFramesPerVolumeWithFlyback'])
            flyback = numslice_withflyback - int(matty['SI']['hStackManager']['numFramesPerVolume'])
            ypix = int(matty['SI']['hRoiManager']['linesPerFrame'])
            dims_spacetime_original[0] = numvol
            dims_spacetime_original[1] = numslice_withflyback
            dims_spacetime_original[2] = ypix
            dims_spacetime_original_noflyback[0] = numvol
            dims_spacetime_original_noflyback[1] =  numslice_withflyback - flyback
            dims_spacetime_original_noflyback[2] = ypix


          if old_mat_files:
            fn_reduced = f[:-5]
          else:
            fn_reduced = f.split('_')[0].split('-')[0] + '_' + f.split('_')[0].split('-')[1]  + '_' + f.split('_')[-2][-1] #change hyphen to underscore

          pth_prefix_fnsave = ff + fn_reduced
          if old_mat_files:
            pth_tif_reg_tmp = []
            pth_tif_reg = pth_datafile
            pth_tif_dn = pth_datafile[:-4] + 'dn_.tif'
          else:
            if anatomical_stack:
              pth_tif_reg_tmp = [pth_prefix_fnsave + '_hires_caimanregtmp_.tif']
              pth_tif_reg = [pth_prefix_fnsave + '_hires_caimanreg_.tif']
              pth_tif_dn = [pth_prefix_fnsave + 'hires_cmregcaddn_.tif']
            else:
              pth_tif_reg_tmp = [pth_prefix_fnsave + '_caimanregtmp_.tif']
              pth_tif_reg = [pth_prefix_fnsave + '_caimanreg_.tif']
              pth_tif_dn = [pth_prefix_fnsave + '_cmregcaddn_.tif']


          pipeline_full(index, pth_datafile, pth_prefix_fnsave, pth_tif_reg_tmp, pth_tif_reg, pth_tif_dn, fn_reduced, old_mat_files, 
                        datasets_path_processing, datasets_path_complete, dims_spacetime_original, dims_spacetime_original_noflyback, 
                        flyback, anatomical_stack, do_motion_correction, do_denoise, do_cropping_session, do_extraction, do_planar_extraction, region_extraction, do_plots, cluster_backend, server)


