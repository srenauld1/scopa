
import re
import os
import sys


def pathfun(do_copyfiles):

    print(sys.executable)
    env_path = sys.path


    pth_allrec_storage = []
    if (re.search("/Users/wienecke/", env_path[0])): #IF YOU'RE ON YOUR OWN MACHINE
        pth_allrec_compute = '/Users/wienecke/Documents/ambrose/stacks/'
        pth_allrec_storage = '/Volumes/neurobio/wilsonlab/wienecke/stacks/'
    elif (re.search("/home/caw846/", env_path[0])): #IF YOU'RE ON O2 . . . 
        pth_allrec_compute = '/n/scratch3/users/c/caw846/stacks/'
        pth_allrec_storage = '/n/files/Neurobio/wilsonlab/wienecke/stacks/'
    elif (re.search("/home/par26/", env_path[0])): #IF YOU'RE ON O2 . . . 
        pth_allrec_compute = '/n/scratch3/users/p/par26/analysis/'
        pth_allrec_storage = '/n/files/Neurobio/wilsonlab/pablo/analysis/'
    elif (re.search("/home/users/wienecke/", env_path[0])): #IF YOURE ON THE STANFORD CLUSTER
        pth_allrec_compute = '/scratch/users/wienecke/stacks/'
    elif (re.search('/content', env_path[0])): #IF YOURE ON GOOGLE COLAB
        pth_allrec_compute = '/content/drive/MyDrive/stacks/'
        do_cluster = 1 #cluster worked on colab 

    pth_super = '/'.join(pth_allrec_compute.split('/')[:-2])
    pth_denoising = os.path.join(pth_super, 'denoising')
    if not os.path.exists(pth_denoising) and not do_copyfiles:
        os.mkdir(pth_denoising)

    if do_copyfiles=='in':
        pth_allrec = pth_allrec_storage
    else:
        pth_allrec = pth_allrec_compute

    return pth_allrec, pth_allrec_compute, pth_allrec_storage, pth_denoising, do_cluster
