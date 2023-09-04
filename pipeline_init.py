
#!/usr/bin/env python


##########################################################################################################################################

# this is the first part of the analysis pipeline for volumetric (xyzt) 2p imaging with behavior and visual stimuli (might not be optimaized for single plane xyt analysis)
# this first part of the pipeline is in python (entry point pipeline_init.py), and it operates on the imaging data only (not on behavior or stimulus data) 
# the second part of the pipeline is in matlab (entry point is cx_analysis.m), and operates on the output of this first part (imaging data) and also behavior and stimulus data
# there aren't many plots associated with this first part (they are disabled since the idea is for this first part to run in the background on all recordings, to prepare the data for more interactive analysis in matlab)

# if recording_index = 0, pipeline_init.py cycles through all recordings in directory specified by pth_allrec, passing one trial at a time to pipeline in pipeline.py
# if recording_index is not 0, pipeline_init.py chooses only the recording matching value of recording_index (based on the sorted list of all reocrdings in pth_allrec)
# this is convenient because recording_index can be assigned SLURM_ARRAY_TASK_ID in a bash script (e.g. mcp.sbatch), 
# which will run the pipeline on multiple recordings in parallel as a job array on O2 
# for example, the line #SBATCH --array=[1-30] will run up to 30 jobs (or as many as recources allow) in parallel for recordings (date_fly_trial) with recording_index 1-30  

# pipeline.py includes these options: 
# --motion correction (with caiman NormCorre)
# --background subtraction line-by-line (to remove stimulus bleedthrough), 
# --denoising (using deepcad), 
# --source extraction (using caiman cNMF)
# ------extraction can operate on 4d xyzt data (planar_extraction = False), or 3d data xyt (planar_extraction = True), where extraction operates on each z plane of the 4d data independently
# ------extraction includes the option to operate on a rectangular subset of the full FOV ('region_extraction') 
# ------if multiple region_extraction are provided, the extraction part of the pipeline loops over these   
# ------the extraction part of the pipeline also includes the option to loop over all possible combinations of any subset of extraction parameters, defined in map2params.py
# ------to do this, set index_extraction_param_set to a negative value, and all param combinations up to that index are looped over 
# ------if index_extraction_param_set is positive, only that param set index is run (if 'None', onlt the default param set is run) 
# these subroutines can be run at separate times, or all in one sequence for example, motion correction for all files in a directory, then in another job, denoising for all those same files, then extraction
# the denoising requires motion corrected input tif, and the extraction requires either the motion correction output tif, or the denoising output tif (depending on whether use_denoised is true of false)
# background subtraction is built in to the denoising script denoise.py, and currently cannot be disabled (but would be simple to include the option)

# input to pipeline are the big tif files output by ScanImage (precision is int16, not uint16), dimensions are tzyx
# metadata is read from these same tif files 
# some output files of this pipeline are saved as uint16 (not int16), since the data is nonnegative after processing
# in all stages of the pipeline, int16 or uint16 data is converted to float32 when read in, then operated on

# the whole pipeline is automated except if region_extraction is not [''], in which case interactive plots prompt user to define a cuboid or rectangular subset of the FOV on which extraction is run 
# do_cropping_session = True will skip everything but this interactive FOV selection for all entries in region_extraction, 
# but must have already run motion correction if use_denoised=False, or motion correction and denoising if use_denoised=True, to provide input files for cropping 
# do_cropping_session = True is convenient to cycle through many recordings that have been motion corrected (and optionally denoised) 
# at once so then extraction can be run in a separate job on a batch of recordings in pth_allrecs without interruption 
# the matlab part of the pipeline operates on any/all region_extraction for any recording 
# if a rectangle or cuboid cannot well separate brain regions that you want separated in later analysis, the matlab part of the pipeline gives the option to further sebset/subdivide any region_extraction
# so, here, region extraction is meant to separately run extraction on regions requiring different extraction params, and/or to run the extraction faster (ie if all extraction_regions amount to less data than the full fov)  
# then, analysis of more precisely defined brain regions is done in the matlab part of the pipeline, where regions can be further split into arbitrary 2d, 3d, or 4d shapes

# since the denoising part of the pipeline requires very different resources on O2, there is a bash script for running the denoising part of the pipeline, and another bash script for running anything but denoising
# but both bash scripts call pipeline_init.py, since denoising script is built into the pipeline for convenience
# the pipeline should be run in a virtual environment with caiman installed
# the denoising script is called using os.system to change the virtual environment from caiman to deepcad, but after denoising it returns to caiman (installing deepcad in the caiman env failed for some reason)
# the user can run the entire pipeline in one automated job (if region extraction = [''], or if region_extraction FOVs have already been defined for all region_extraction values), 
# but if do_denoising = True, resources for that job should change when transitioning into and out of the denoising part of the pipeline
# but this repo currently does not have a bash script to dynamically change SLURM resources (ie string together the sbatch files mentioned below)

# the recommended workflow is:
# 1. run job array mcp.sbatch to motion correct recordings in parallel (automated)
# 2. run job array dnp.sbatch to denoise the same batch of recordings in parallel (automated) - depending on how many recordings in pth_allrec, may need to make recording_index = 0 to loop in sequence (not parallel) because of limited GPU resources 
# 3. using ineractive job on O2 (visual studio), run pipeline_init.py, looping over all values in region_extraction and all recordings in the same batch of recordings (by making input params match those in cxp.sbatch and dnp.sbatch), letting user define all sub-FOV (interactive)
# 4. using job array exp.sbatch, run extraction on all values in region_extraction for same batch of recordings, optionally using the motion-corrected and denoised or just motion-corrected data (automated)
# 5. use matlab pipeline for further analysis using the output of this python pipeline 

# these sbatch files are written to run on requeue-type partitions (using other people's resources), and will automatically requeue if preempted

# before running any of the sbatch files mentioned above, caiman needs to be installed (follow instructions on their github)
# after that you also need to run the following commands (to install an extra package in the caiman environment) 
# module load miniconda3/4.10.3
# source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
# conda activate caiman
# pip install scanimage-tiff-reader

# before running denoise.py (from within in dnp.sbatch or directly on command line), deepcad and torch need to be installed (instructions on their github)
# after that you also need to run the following commands (to install a couple extra packages in the deepcad environment) 
# module load miniconda3/4.10.3
# source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
# conda activate deepcadrt
# pip install mat73
# pip install matplotlib 

# carl wienecke 230902
##########################################################################################################################################

import sys
import re
import cv2
import datetime
import fnmatch
import os
import glob
import logging
import os
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


logging.basicConfig(format=
                    "%(relativeCreated)12d [%(filename)s:%(funcName)20s():%(lineno)s]"\
                    "[%(process)d] %(message)s",
                    #filename="/n/scratch3/users/c/caw846/ctmp/caiman.log",
                    level=logging.WARNING,
                    )


# export MKL_NUM_THREADS=1 #can't remember why i tried this, but i don't use it   
# export OPENBLAS_NUM_THREADS=1 #can't remember why i tried this, but i don't use it  


index_extraction_param_set = 0 #specifies the extraction param set (set is created in configs.py, which uses map2params.py to help create the param sets) 
recdates = ['20230627'] #list of strings, as it appears in the directory and raw file filename (with hyphen not underscore for now), '*' for any 
fly = '*' #string, fly index_extraction_param_set, '*' for any 
trial = '2' #string, trial index_extraction_param_set, '*' for any 
region_extraction = ['pb', 'gar', 'gal', 'no'] #list of strings specifying names for xy rectangular or xyz cuboid fov subregions that are passed separately to source extraction; interactive plots prompt user to define z range and draw xy rectangle; use [''] to extract from entire FOV
do_motion_correction = False #caiman normCorre 
do_denoise = False #deepcad (from the more recent deepcadrt, although this is not real time), input must be motion_corrected 
use_denoised = False #use the deepcad denoised data, or just the caiman registered data 
do_extraction = True #caiman source extraction 
do_planar_extraction = False #caiman source extraction for each plane independently (WARNING, 3D EXTRACTION REQUIRES AT LEAST 3 ELEMENTS IN EACH DIMENSION X Y and Z, OR you must REWRITE binary_closing IN CAIMAN'S THRESHOLD_COMPONENTS)
do_cropping_session = False #skip everything but FOV selection for all entries in region_extraction, must have already run motion correction if use_denoised=False, or motion correction and denoising if use_denoised=True, convenient to do for many recordings at once so extraction can be run on a batch of recordings in pth_allrecs without interruption
recording_index = 0 #if 0, loop over all recordings in pth_allrec, if not 0, operate on recording whose index (in sorted list of all recordings in pth_allrec) matches value in recording_index

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
  [index_extraction_param_set, region_extraction, do_motion_correction, 
  do_denoise, use_denoised, do_extraction, do_planar_extraction, 
  recdates,  fly, trial, do_cropping_session, 
  recording_index] = parse_command_line(index_extraction_param_set = index_extraction_param_set, 
                      region_extraction = region_extraction, do_motion_correction = do_motion_correction, 
                      do_denoise = do_denoise, use_denoised = use_denoised, do_extraction = do_extraction, do_planar_extraction = do_planar_extraction, 
                      recdates = recdates, fly = fly, trial = trial, do_cropping_session = do_cropping_session, 
                      recording_index = recording_index)


print("STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY")
print(index_extraction_param_set)
print(region_extraction)
print(do_motion_correction)
print(do_denoise)
print(do_extraction)
print(do_planar_extraction)
print(recdates)
print(fly)
print(trial)
print(do_cropping_session)
print(recording_index)

countz = 0
for recording_date in recdates:

  tmpdate = datetime.datetime.now().strftime("%Y%m%dT%H%M%S") 

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
        if recording_index==0 or (recording_index!=0 and countz==recording_index): #if 0, do all files, otherwise only file matching index
          
          pth_datafile = pth_fldr + f
          print(pth_datafile)

          if old_mat_files: #for my old project 
            fn_prefix = f[:-5]
            pth_tif_reg_tmp = []
            pth_tif_reg = pth_datafile
            pth_tif_dn = pth_datafile[:-4] + 'dn_.tif'
          else:
            fn_prefix = f.split('_')[0].split('-')[0] + '_' + f.split('_')[0].split('-')[1]  + '_' + f.split('_')[-2][-1] #change hyphen to underscore
            pth_allrec_fnsave = pth_fldr + fn_prefix
            pth_tif_reg_tmp = [pth_allrec_fnsave + '_caimanregtmp_.tif']
            pth_tif_reg = [pth_allrec_fnsave + '_caimanreg_.tif']
            pth_tif_dn = [pth_allrec_fnsave + '_cmregcaddn_.tif']
            pth_tif_dn = [pth_allrec_fnsave + '_cmregcaddn_.tif']
            pth_md = [pth_allrec_fnsave + '_metadatanew_.mat']
            md = read_save_metadata(pth_datafile, pth_md)

          pipeline(index_extraction_param_set, pth_datafile, pth_tif_reg_tmp, pth_tif_reg, pth_tif_dn, fn_prefix, 
                        pth_denoising, pth_denoised, md, do_motion_correction, do_denoise, use_denoised, 
                        do_cropping_session, do_extraction, do_planar_extraction, region_extraction, 
                        do_plots, cluster_backend, do_cluster)


