
import re
import os
import sys


def makepaths(do_copyfiles, path_storage):

    print("sys.executable returns: \n" + sys.executable)
    
    env_path = sys.path[0]

    print("sys.path[0] returns: \n" + env_path)

    in_colab = 'google.colab' in sys.modules
    if in_colab:
        raise Exception("in colab run the ipynb pipeline instead")
    else:
        hn = os.popen('hostname').read()
        if re.search('compute.*harvard', hn): #if you're on O2, make compute folder that matches scratch path pattern
            pth_super_compute = '/n/scratch3/users/' + env_path.split('/')[-2][0] + '/' + env_path.split('/')[-2] + '/'
        else: #else assume you're not on a cluster with specific compute folders (like scratch)
            pth_super_compute = ('/').join(env_path.split('/')[:-1]) + '/' 


    superfolder_name_compute = path_storage.split('/')[-1] #for compute, mirror the last folder on path_storage
    pth_allrec_compute = pth_super_compute + superfolder_name_compute + '/' 
    if not os.path.exists(pth_allrec_compute):
        os.mkdir(pth_allrec_compute)

    pth_denoising = pth_super_compute + 'denoising/' 
    if not os.path.exists(pth_denoising):
        os.mkdir(pth_denoising)

    if do_copyfiles:
        pth_allrec = path_storage
    else:
        pth_allrec = pth_allrec_compute
    
    print("path_storage is : \n" + path_storage)
    print("pth_allrec_compute is : \n" + pth_allrec_compute)

    return pth_allrec, pth_allrec_compute, path_storage, pth_denoising, do_copyfiles
