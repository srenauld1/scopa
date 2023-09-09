
#!/usr/bin/env python

import sys
import re
import os
import glob
import numpy as np

print(sys.executable)
env_path = sys.path

if (re.search("/Users/wienecke/", env_path[0])):
  pth_allrec = '/Users/wienecke/Documents/ambrose/stacks/'
elif (re.search("/home/caw846/", env_path[0])):
  pth_allrec = '/n/scratch3/users/c/caw846/stacks/'
elif (re.search("/home/users/wienecke/", env_path[0])):
  pth_allrec = '/scratch/users/wienecke/stacks/'
elif (re.search('/content', env_path[0])):
  pth_allrec = '/content/drive/MyDrive/stacks/'

pth_super = '/'.join(pth_allrec.split('/')[:-2])

patold = 'croplim_.npy'

fnall = sorted(glob.glob(pth_allrec + '*/*_cmnrg_*_' + patold))

for f in fnall:
    print(f)
    with open(f, 'rb') as fnc:
        croplim = np.load(fnc)
    limits_str = str(croplim[0]) + '_' + str(croplim[1]) + '_' + str(croplim[2]) + '_' + str(croplim[3]) + '_' + str(croplim[4]) + '_' + str(croplim[5]) + '_' + str(croplim[6]) + '_' + str(croplim[7])
    fnew = '_'.join(f.split('_')[:-4]) + '_' + f.split('_')[-3] + '_' + limits_str + '_' + patold 
    with open(fnew, 'wb') as fncrop:
        np.save(fncrop, croplim)
    
    os.remove(f)
    

fnall = sorted(glob.glob(pth_allrec + '*/*_cmnrgcaddn_*_' + patold))

for f in fnall:
    print(f)

    os.remove(f)
    

