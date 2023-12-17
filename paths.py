
import re
import os
import sys


def makepaths(do_copyfiles, superfolder_name_compute, superfolder_name_storage):

    print(sys.executable)
    env_path = sys.path[0]


    in_colab = 'google.colab' in sys.modules
    if in_colab:
        raise Exception("in colab run the ipynb pipeline instead")
    else:
        hn = os.popen('hostname').read()
        if re.search('compute.*harvard', hn): #if you're on O2
            pth_super_compute = '/n/scratch3/users/' + env_path.split('/')[-2][0] + '/' + env_path.split('/')[-2] + '/'
            pth_allrec_storage = superfolder_name_storage
        else: #else assume you're not on a cluster 
            pth_super_compute = ('/').join(env_path.split('/')[:-1]) + '/' 
            pth_allrec_storage = '' #no need to move data elsewhere on local machine
            # if do_copyfiles:
            #     print("FORCING do_copyfiles to zero because you're not on the cluster")
            #     do_copyfiles = 0

    pth_allrec_compute = pth_super_compute + superfolder_name_compute + '/' #data folder in scopa is ignored (see .gitignore file with ls -a)
    if not os.path.exists(pth_allrec_compute):
        os.mkdir(pth_allrec_compute)
        
    # if not os.path.exists(pth_allrec_storage):
    #     os.mkdir(pth_allrec_storage)

    pth_denoising = pth_super_compute + 'denoising/' #data folder in scopa is ignored (see .gitignore file with ls -a)
    if not os.path.exists(pth_denoising):
        os.mkdir(pth_denoising)

    if do_copyfiles=='in':
        pth_allrec = pth_allrec_storage
    else:
        pth_allrec = pth_allrec_compute

    return pth_allrec, pth_allrec_compute, pth_allrec_storage, pth_denoising, do_copyfiles
