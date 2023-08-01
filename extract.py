
#!/usr/bin/env python

import sys
import re
import cv2
import datetime
import fnmatch
import os
import glob
import logging
#import matplotlib.pyplot as plt
import numpy as np
import os
from tifffile.tifffile import imwrite
from ScanImageTiffReader import ScanImageTiffReader
import json
from caiman_draw_fov import select_fov
from caiman_vis_custom import im_montage
from ast import literal_eval

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

import caiman as cm
from extract_models import extract_2d

# import bokeh.plotting as bpl
# bpl.output_notebook()

logging.basicConfig(format=
                          "%(relativeCreated)12d [%(filename)s:%(funcName)20s():%(lineno)s] [%(process)d] %(message)s",
                    # filename="/tmp/caiman.log",
                    #level=logging.INFO,
                    )

recordingIDs = ['20230627-2']
do_motion_correction = True
do_extraction = False
do_planar_extraction = False 
do_refit = True
do_fov_crop = 'FULL'
do_plots = 0
anatomical_stack = True

env_path = sys.path

if (re.search("/Users/wienecke/", env_path[0])):
  data_fn_prefix = '/Users/wienecke/Documents/ambrose/leprechaunMat/'
if (re.search("/home/caw846/", env_path[0])):
  data_fn_prefix = '/n/scratch3/users/c/caw846/'
elif (re.search("/home/users/wienecke/", env_path[0])):
  data_fn_prefix = '/scratch/users/wienecke/cx/'


if len(sys.argv)==1:
    index = None #change here if you're running in visual studio debug mode (no arguments)
else:
    index = int(sys.argv[1].split(':')[-1]) #for passing index as arg in command line, this won't error on local, even though there's no colon 

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

  path_date_stack_tmp = data_fn_prefix + recordingID + '_*/'
  path_to_stacks = []

  if anatomical_stack:
    stack_filename_template = recordingID + '_hires_.tif'
  else:
    stack_filename_template = recordingID + '*_trial_*.tif'

  path_date_stack = glob.glob(path_date_stack_tmp)
  if len(path_date_stack)>1:
     raise ValueError('multiple data folders') 
  else:
     path_date_stack = path_date_stack[0]
     
  for f in os.listdir(path_date_stack):
    if fnmatch.fnmatch(f,stack_filename_template):
      tmp = path_date_stack + f
      path_to_stacks.append(tmp)

  for f in path_to_stacks:

    print(f)
    fn_prefix = path_date_stack + f.split('/')[-1].split('_')[0].split('-')[0] + '_' + f.split('/')[-1].split('_')[0].split('-')[1]

    Y = cm.load(f)
    #Y = ScanImageTiffReader(f).data() #dim order (t z) y x, int16 . . . cm.load(f) is same dim order but float32 (and cannot read metadata) 
    #Ymeta = ScanImageTiffReader(f).metadata() #dim order (t z) y x, int16 . . . cm.load(f) is same dim order but float32 (and cannot read metadata) 
    # with ScanImageTiffReader(f) as reader:
    #    Ymeta=json.loads(reader.metadata())        
    
    Y = Y.reshape(dims_spacetime_original[0], dims_spacetime_original[1], dims_spacetime_original[2], dims_spacetime_original[3])
    Y = Y[:,:-flyback,:,:] #crop flyback frames

    #Y[20,:,:,:].play(magnification=2) 

    #cc, dview, n_processes = cm.cluster.setup_cluster(backend='local', n_processes=None, single_thread=False)

    Y = np.transpose(Y, (0, 3, 2, 1)) #put in order t x y z 

    if do_fov_crop == 'FULL':
      
      slt = slice(0, dims_spacetime_original_noflyback[0], 1)
      slx = slice(0, dims_spacetime_original_noflyback[3], 1) 
      sly = slice(0, dims_spacetime_original_noflyback[2], 1)
      slz = slice(0, dims_spacetime_original_noflyback[1], 1)
      
      limits_str = do_fov_crop + '_' + str(1) + '_' + str(dims_spacetime_original_noflyback[0]) + '_' + str(1) + '_' + str(dims_spacetime_original_noflyback[3]) + '_' + str(1) + '_' + str(dims_spacetime_original_noflyback[2]) + '_' + str(1) + '_' + str(dims_spacetime_original_noflyback[1])
      indices_crop = []

    else:
     
      try:
        fname_crop_lim_tmp = fn_prefix + '_' + do_fov_crop + '_*_.npy' #find file matching fov subregion with some crop lim 
        fname_crop_lim = glob.glob(fname_crop_lim_tmp)
        if len(fname_crop_lim) > 1:
          raise Exception("too many crop files")
        with open(fname_crop_lim[0], 'rb') as fncrop:
            croplim = np.load(fncrop)
        limits_str = do_fov_crop + '_' + str(croplim[0]) + '_' + str(croplim[1]) + '_' + str(croplim[2]) + '_' + str(croplim[3]) + '_' + str(croplim[4]) + '_' + str(croplim[5]) + '_' + str(croplim[6]) + '_' + str(croplim[7])

      except:
        Ymt = np.mean(Y, axis = 0)
        im_montage(Ymt)
        print("what slices do you want to keep? consider keeping first as padding if cells abut z edges")
        zlimits = input ("Enter a number: ")
        zlimits = literal_eval(zlimits)
        Ymtz = np.mean(Ymt, axis = 2)
        ylimits, xlimits = select_fov(Ymtz)
        tlimits = (1, dims_spacetime_original_noflyback[0])
        croplim = np.asarray((tlimits + xlimits + ylimits + zlimits)).astype(int) #make them 1-indexed for matlab later 
        limits_str = do_fov_crop + '_' + str(croplim[0]) + '_' + str(croplim[1]) + '_' + str(croplim[2]) + '_' + str(croplim[3]) + '_' + str(croplim[4]) + '_' + str(croplim[5]) + '_' + str(croplim[6]) + '_' + str(croplim[7])
        fname_crop_lim = fn_prefix + '_' + limits_str + '_.npy'
        with open(fname_crop_lim, 'wb') as fncrop:
            np.save(fncrop, croplim)

        slt = slice(croplim[0]-1, croplim[1], 1) #croplim are 1-indexed, and the second/upper is not included  
        slx = slice(croplim[2]-1, croplim[3], 1) # slice(40, 181, 1) 
        sly = slice(croplim[4]-1, croplim[5], 1) #slice(6, 51, 1)
        slz = slice(croplim[6]-1, croplim[7], 1)  #slice(1, 9, 1) 
      indices_crop = [slt, slx, sly, slz]

    Y = Y[slt,slx,sly,slz]
    dims_spacetime_new = Y.shape

    min_mov = int(np.min(Y))
    Y = Y - min_mov #make minimum zero (not certain this is the place for this, or whether it should occur at all)
    print("MIN BEFORE MOTION CORRECTION")
    print(min_mov)

    #don't put 'caimanreg' in separate underscore to prevent being recognized above

    if anatomical_stack:
      fname_tmptif_reg = [fn_prefix + '_' + limits_str + '_TMPcaimanregTMP_hires_.tif']
      fname_tif_reg = [fn_prefix + '_' + limits_str + '_caimanreg_hires_.tif']
    else:
      fname_tmptif_reg = [fn_prefix + '_' + limits_str + '_TMPcaimanregTMP' + f.split('/')[-1].split('_')[-3]+ '_' + f.split('/')[-1].split('_')[-2] + '_' + f.split('/')[-1].split('_')[-1].split('.')[0] +'_.' + f.split('/')[-1].split('_')[-1].split('.')[1]]
      fname_tif_reg = [fn_prefix + '_' + limits_str + '_caimanreg' + f.split('/')[-1].split('_')[-3]+ '_' + f.split('/')[-1].split('_')[-2] + '_' + f.split('/')[-1].split('_')[-1].split('.')[0] +'_.' + f.split('/')[-1].split('_')[-1].split('.')[1]]
       
    imwrite(fname_tmptif_reg[0], Y) #write as t x y z
    
    donestr = extract_2d(index, fname_tmptif_reg, fname_tif_reg, tmpdate, min_mov, dims_spacetime_new, dims_spacetime_original_noflyback, anatomical_stack, do_motion_correction, do_extraction, do_planar_extraction, do_fov_crop, indices_crop, do_refit, do_plots)

    print(donestr)


