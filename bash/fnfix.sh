
#!/usr/bin/env python

import sys
import re
import os
import glob

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

patold = ['cmnrg', 'cmnrgcaddn', 'cmnex']
patnew = ['cmrg', 'cmrg_dcdn', 'cmex']

for i,p in enumerate(patold):
    fnall = sorted(glob.glob(pth_allrec + '*/*_' + patold[i] + '_*'))

    for f in fnall:
        print(f)
        fnew = f.replace(patold[i], patnew[i]) 
        print(fnew)
        os.rename(f, fnew)

