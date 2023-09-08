
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

from pipeline import pipeline
from helpers import read_save_metadata

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


# export MKL_NUM_THREADS=1 #can't remember why i tried this, but i don't use it   
# export OPENBLAS_NUM_THREADS=1 #can't remember why i tried this, but i don't use it  


index_extraction_param_set = 0 #specifies the extraction param set (set is created in configs.py, which uses map2params.py to help create the param sets) 
recdates = ['*'] #list of strings, as it appears in the directory and raw file filename (with hyphen not underscore for now), '*' for any 
fly = '2' #string, fly index_extraction_param_set, '*' for any 
trial = '2' #string, trial index_extraction_param_set, '*' for any 
region_extraction = ['pb', 'gar', 'gal', 'no'] #list of strings specifying names for xy rectangular or xyz cuboid fov subregions that are passed separately to source extraction; interactive plots prompt user to define z range and draw xy rectangle; use [''] to extract from entire FOV
do_background_subtraction = False
do_motion_correction = False #caiman normCorre 
do_denoise = False #deepcad (from the more recent deepcadrt, although this is not real time), input must be motion_corrected 
denoise_slice_index = [0] #deepcad (from the more recent deepcadrt, although this is not real time), input must be motion_corrected 
use_denoised = False #use the deepcad denoised data, or just the caiman registered data 
do_extraction = False #caiman source extraction 
do_planar_extraction = False #caiman source extraction for each plane independently (WARNING, 3D EXTRACTION REQUIRES AT LEAST 3 ELEMENTS IN EACH DIMENSION X Y and Z, OR you must REWRITE binary_closing IN CAIMAN'S THRESHOLD_COMPONENTS)
do_cropping_session = False #skip everything but FOV selection for all entries in region_extraction, must have already run motion correction if use_denoised=False, or motion correction and denoising if use_denoised=True, convenient to do for many recordings at once so extraction can be run on a batch of recordings in pth_allrecs without interruption
recording_index = None #if None, loop over all recordings in pth_allrec, if not 0, operate on recording whose index (in sorted list of all recordings in pth_allrec) matches value in recording_index

bg_patch_halfwidth = 8 #half width of patch over which mean is computed for background subtraction (patch is a line in x)
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
  index_extraction_param_set = None #not set up for arguments in colab 

pth_super = '/'.join(pth_allrec.split('/')[:-2])
pth_denoising = os.path.join(pth_super, 'denoising')
if not os.path.exists(pth_denoising):
    os.mkdir(pth_denoising)
pth_denoised = os.path.join(pth_super, 'denoised')
if not os.path.exists(pth_denoised):
    os.mkdir(pth_denoised)


if len(sys.argv)>1:
  [index_extraction_param_set, region_extraction, do_background_subtraction, do_motion_correction, 
  do_denoise, denoise_slice_index, use_denoised, do_extraction, do_planar_extraction, 
  recdates,  fly, trial, do_cropping_session, 
  recording_index] = parse_command_line(index_extraction_param_set = index_extraction_param_set, 
                      region_extraction = region_extraction, do_background_subtraction = do_background_subtraction, do_motion_correction = do_motion_correction, 
                      do_denoise = do_denoise, denoise_slice_index = denoise_slice_index, use_denoised = use_denoised, do_extraction = do_extraction, do_planar_extraction = do_planar_extraction, 
                      recdates = recdates, fly = fly, trial = trial, do_cropping_session = do_cropping_session, 
                      recording_index = recording_index)


print("STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY")
print(index_extraction_param_set)
print(region_extraction)
print(do_motion_correction)
print(do_denoise)
print(denoise_slice_index)
print(do_extraction)
print(do_planar_extraction)
print(recdates)
print(fly)
print(trial)
print(do_cropping_session)
print(recording_index)



countz = 0
for recording_date in recdates:

  pth_fldrs_pattern = pth_allrec + recording_date + '-' + fly + '_*/'
  fn_pattern = recording_date + '-' + fly + '*_trial_00' + trial + '_*.tif'
  pth_fldrs = sorted(glob.glob(pth_fldrs_pattern))
  old_mat_files = 0
  if not pth_fldrs:  #if no matches try another filename pattern (files from previous project)
    old_mat_files = 1
    pth_fldrs_pattern = pth_allrec + recording_date + '_' + fly + '/'
    fn_pattern = recording_date + '_' + fly + '_' + trial + '_stackRaw_mc_.mat'
    pth_fldrs = sorted(glob.glob(pth_fldrs_pattern))

  for pth_fldr in pth_fldrs:

    print(pth_fldr)
    
    pth_allfiles = sorted(os.listdir(pth_fldr))

    for f in pth_allfiles:

      if fnmatch.fnmatch(f, fn_pattern):

        countz = countz + 1
        if recording_index == 0 or (recording_index !=0 and countz==recording_index): #if 0, do all files, otherwise only file matching index
          

          tmpdate = datetime.datetime.now().strftime("%Y%m%dT%H%M%S") 
          sys.stdout = open(pth_fldr + '/' + tmpdate + '.txt', 'w')
          sys.stderr = sys.stdout

          pth_datafile = pth_fldr + f
          print(pth_datafile)

          if old_mat_files: #for my old project 
            fn_prefix = f[:-5]
            pth_allrec_fnsave = pth_fldr + fn_prefix
            pth_tif_reg_tmp = []
            pth_tif_reg = pth_datafile
            pth_tif_dn = pth_datafile[:-4] + 'dn_.tif'
          else:
            fn_prefix = f.split('_')[0].split('-')[0] + '_' + f.split('_')[0].split('-')[1]  + '_' + f.split('_')[-2][-1] #change hyphen to underscore
            pth_allrec_fnsave = pth_fldr + fn_prefix
            pth_tif_reg_tmp = [pth_allrec_fnsave + '_cmnrgtmp_.tif']
            pth_tif_reg = [pth_allrec_fnsave + '_cmnrg_.tif']
            pth_tif_dn = [pth_allrec_fnsave + '_cmnrgcaddn_.tif']
            pth_md = [pth_allrec_fnsave + '_metadatanew_.mat']
            md = read_save_metadata(pth_datafile, pth_md)

          pipeline(index_extraction_param_set, pth_datafile, fn_prefix, pth_allrec_fnsave, pth_tif_reg_tmp, pth_tif_reg, pth_tif_dn, 
                        pth_denoising, pth_denoised, md, do_background_subtraction, bg_patch_halfwidth, do_motion_correction, do_denoise, denoise_slice_index, 
                        use_denoised, do_cropping_session, do_extraction, do_planar_extraction, region_extraction, 
                        do_plots, cluster_backend, do_cluster)


