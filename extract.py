
#!/usr/bin/env python

import sys
import re
import cv2
import datetime
import fnmatch
import os
import glob
import logging
import os


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

from extract_models import extract_2d

# import bokeh.plotting as bpl
# bpl.output_notebook()

logging.basicConfig(format=
                          "%(relativeCreated)12d [%(filename)s:%(funcName)20s():%(lineno)s] [%(process)d] %(message)s",
                    # filename="/tmp/caiman.log",
                    #level=logging.INFO,
                    )

# export MKL_NUM_THREADS=1
# export OPENBLAS_NUM_THREADS=1

recordingIDs = ['20230624-2'] #date-fly, as it appears in the directory and raw file filename (with hyphen not underscore)
trial = '*' # '*' for any trial in folder
do_motion_correction = False
do_extraction = True
do_planar_extraction = False #WARNING, CAN ONLY DO 3D WITH AT LEAST LENGTH 3 IN EACH DIMENSION, OR REWRITE/ADAPT binary_closing IN CAIMAN'S THRESHOLD_COMPONENTS
region_extraction = 'gal'
do_plots = 0
anatomical_stack = False

env_path = sys.path

if (re.search("/Users/wienecke/", env_path[0])):
  pth_prefix = '/Users/wienecke/Documents/ambrose/leprechaunMat/'
elif (re.search("/home/caw846/", env_path[0])):
  pth_prefix = '/n/scratch3/users/c/caw846/'
elif (re.search("/home/users/wienecke/", env_path[0])):
  pth_prefix = '/scratch/users/wienecke/cx/'
elif (re.search('/content/CaImAn', env_path[0])):
  pth_prefix = '../drive/MyDrive/stacksfin/'

if len(sys.argv)==1:
    index = None #change here if you're running in visual studio debug mode (no arguments)
elif len(sys.argv)==2:
    index = int(sys.argv[1].split(':')[-1]) #for passing index as arg in command line, this won't error on local, even though there's no colon 
elif len(sys.argv)==3:
    index = int(sys.argv[1].split(':')[-1]) #for passing index as arg in command line, this won't error on local, even though there's no colon 
    region_extraction = sys.argv[2].split(':')[-1] #for passing index as arg in command line, this won't error on local, even though there's no colon 

print("STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY, STARTING EXTRACT.PY")
print(index)
print(region_extraction)

if anatomical_stack==True:
  dims_spacetime_original = [80, 164, 140, 256] 
  flyback = 51
  dims_spacetime_original_noflyback = [dims_spacetime_original[0], dims_spacetime_original[1]-flyback, dims_spacetime_original[2], dims_spacetime_original[3]] 

else:
  dims_spacetime_original = [3047, 20, 140, 256] #manual
  flyback = 5
  dims_spacetime_original_noflyback = [dims_spacetime_original[0], dims_spacetime_original[1]-flyback, dims_spacetime_original[2], dims_spacetime_original[3]] 

for recordingID in recordingIDs:
  
  tmpdate = datetime.datetime.now().strftime("%Y%m%dT%H%M%S") #create extraction ID, one for each recordingID

  pth_fldr_pattern = pth_prefix + recordingID + '_*/'

  if anatomical_stack:
    fn_pattern = recordingID + '_hires_.tif'
  else:
    fn_pattern = recordingID + '*_trial_00' + trial + '.tif'

  pth_fldr = glob.glob(pth_fldr_pattern)[0]

  for f in os.listdir(pth_fldr):
    if fnmatch.fnmatch(f,fn_pattern):
      pth_datafile = pth_fldr + f
      print(pth_datafile)
      pth_prefix_fnsave = pth_fldr + f.split('_')[0].split('-')[0] + '_' + f.split('_')[0].split('-')[1]

      if anatomical_stack:
        pth_tif_reg_tmp = [pth_prefix_fnsave + '_hires_caimanregtmp_.tif']
        pth_tif_reg = [pth_prefix_fnsave + '_hires_caimanreg_.tif']
      else:
        pth_tif_reg_tmp = [pth_prefix_fnsave + '_' + f.split('_')[-3] + '_' + f.split('_')[-2] + '_caimanregtmp_.tif']
        pth_tif_reg = [pth_prefix_fnsave + '_' + f.split('_')[-3] + '_' + f.split('_')[-2] + '_caimanreg_.tif']

      # if 'dview' in locals(): cm.stop_server(dview=dview)
      # cc, dview, n_processes = cm.cluster.setup_cluster(backend='ipyparallel', n_processes=None, single_thread=False)
      
      #extract_2d(index, pth_datafile, pth_prefix_fnsave, pth_tif_reg_tmp, pth_tif_reg, dims_spacetime_original, dims_spacetime_original_noflyback, flyback, anatomical_stack, do_motion_correction, do_extraction, do_planar_extraction, region_extraction, do_plots)


