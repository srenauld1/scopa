
import re
import os
import sys
from pathlib import Path


def make_paths(do_copyfiles, pth_storage):

    print("\n\n\nsys.executable returns: \n" + sys.executable)
    
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


    superfolder_name_compute = pth_storage.split('/')[-2] #for compute, mirror the last folder on pth_storage (which is -2 since pth_storage ends with slash)
    pth_compute = pth_super_compute + superfolder_name_compute + '/' 
    if not os.path.exists(pth_compute):
        Path(pth_compute).mkdir(parents=True, exist_ok=True)

    pth_denoising = pth_super_compute + 'denoising/' 
    if not os.path.exists(pth_denoising):
        Path(pth_denoising).mkdir(parents=True, exist_ok=True)

    elif do_copyfiles==0: #computing (not copying)
        pth_allrec = pth_compute
        pth_copydest_prefix = pth_storage
    if do_copyfiles==1: #copying into O2
        pth_allrec = pth_storage
        pth_copydest_prefix = pth_compute
    elif do_copyfiles==2: #copying out of O2
        pth_allrec = pth_compute
        pth_copydest_prefix = pth_storage
    
    print("\n\n\npth_storage is : \n" + pth_storage)
    print("pth_compute is : \n" + pth_compute)
    print("pth_allrec is : \n" + pth_allrec)

    return pth_allrec, pth_copydest_prefix, pth_denoising
