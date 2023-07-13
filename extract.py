
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
from caiman_configs import configs

# import bokeh.plotting as bpl
# bpl.output_notebook()

logging.basicConfig(format=
                          "%(relativeCreated)12d [%(filename)s:%(funcName)20s():%(lineno)s] [%(process)d] %(message)s",
                    # filename="/tmp/caiman.log",
                    #level=logging.INFO,
                    )


env_path = sys.path
if (re.search("/Users/wienecke/", env_path[0])):
   data_path_prefix = '/Users/wienecke/Documents/ambrose/leprechaunMat/'
   anatomical_stack = True
   dimin = [80, 164, 140, 256] 
   flyback = 51
   srv = 0
elif (re.search("/home/caw846/", env_path[0])):  
   data_path_prefix = '/n/scratch3/users/c/caw846/'
   anatomical_stack = False
   dimin = [3047, 20, 140, 256] 
   flyback = 5
   srv = 1


planar_extraction = True 
do_motion_correction = True
do_refit = True

recordingIDs = ['20230624-2', '20230627-2']

opts_dict, indices_ex = configs()

for recordingID in recordingIDs:
  
  tmpdate = datetime.datetime.now().strftime("%Y%m%dT%H%M%S") #create extraction ID, one for each recordingID

  path_date_stack_tmp = data_path_prefix + recordingID + '_*/'
  path_to_stacks = []

  if anatomical_stack:
    stack_filename_template = recordingID.split('-')[0] + '_' + recordingID.split('-')[1] + '_hires_.tif'
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
    Y = cm.load(f) #scan image tif files are loaded (and presumably saved) as t z y x
    Y = Y.reshape(dimin[0], dimin[1], dimin[2], dimin[3])
    Y = Y[:,:-flyback,:,:] #crop flyback frames

    Y[20,:,:,:].play(magnification=2) 

    #cc, dview, n_processes = cm.cluster.setup_cluster(backend='local', n_processes=None, single_thread=False)

    Y = np.transpose(Y, (0, 3, 2, 1)) #put in order t x y z 

    Y = Y - np.min(Y) #make minimum zero (not certain this is the place for this, or whether it should occur at all)

    fname = [f[:(len(f)-4)] + 'caimanreg_.tif']
    fname_save = fname[0][:(len(f)-4)] + tmpdate + '_caimanrois_.mat'

    imwrite(fname[0], Y) #write as t x y z
    dims = Y.shape[1:]
    
    fug = extract_2d(opts_dict, fname, do_motion_correction, planar_extraction, do_refit, indices_ex, fname_save, srv)



