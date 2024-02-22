
#!/usr/bin/env python

import sys
import re
import os
import glob

dryrun = 1

print(sys.executable)
pth_env = sys.path

if (re.search("/Users/wienecke/", pth_env[0])):
  pth_allrec = '/Users/wienecke/scopa/post'
elif (re.search("/home/caw846/", pth_env[0])):
  pth_allrec = '/n/scratch3/users/c/caw846/stacks/'
elif (re.search("/home/users/wienecke/", pth_env[0])):
  pth_allrec = '/scratch/users/wienecke/stacks/'
elif (re.search('/content', pth_env[0])):
  pth_allrec = '/content/drive/MyDrive/stacks/'

pth_super = '/'.join(pth_allrec.split('/')[:-2])

# patold = ['cmnrg', 'cmnrgcaddn', 'cmnex']
# patnew = ['cmrg', 'cmrg_dcdn', 'cmex']

patold = ['']
patnew = ['']

for i,p in enumerate(patold):
    fnall = sorted(glob.glob(pth_allrec + '**/*_' + patold[i] + '_*'))
    fnall = sorted(glob.glob(pth_allrec + '**/' + patold[i] + '*'))

    for f in fnall:
        print(f)
        fnew = f.replace(patold[i], patnew[i]) 
        print(fnew)
        if not dryrun:
           os.rename(f, fnew)

