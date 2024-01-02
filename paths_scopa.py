
import re
import os
import sys
from pathlib import Path


def make_paths(do_copyfiles, folder_with_all_recordings_on_storage_and_compute_filesystems, pth_storage_prefix):

    print("\n\n\nsys.executable returns: \n" + sys.executable)
    
    env_path = sys.path[0]

    print("sys.path[0] returns: \n" + env_path)

    in_colab = 'google.colab' in sys.modules
    if in_colab:
        raise Exception("in colab run the ipynb pipeline instead")
    else:
        hn = os.popen('hostname').read()
        if re.search('compute.*harvard', hn): #if you're on O2, make compute folder that matches scratch path pattern
            pth_compute_prefix = '/n/scratch3/users/' + env_path.split('/')[-2][0] + '/' + env_path.split('/')[-2] + '/'
        else: #else assume you're not on a cluster with specific compute folders (like scratch)
            pth_compute_prefix = ('/').join(env_path.split('/')[:-1]) + '/' 


    if folder_with_all_recordings_on_storage_and_compute_filesystems[-1] != '/': 
        folder_with_all_recordings_on_storage_and_compute_filesystems = folder_with_all_recordings_on_storage_and_compute_filesystems + '/'

    pth_compute = pth_compute_prefix + folder_with_all_recordings_on_storage_and_compute_filesystems 
    if not os.path.exists(pth_compute):
        Path(pth_compute).mkdir(parents=True, exist_ok=True)

    pth_storage = pth_storage_prefix + folder_with_all_recordings_on_storage_and_compute_filesystems 
    if not os.path.exists(pth_storage) and do_copyfiles:
        raise Exception("pth_storage: \n" + pth_storage + "does not exist")

    pth_denoising = pth_compute_prefix + 'denoising' + '/' 
    if not os.path.exists(pth_denoising):
        Path(pth_denoising).mkdir(parents=True, exist_ok=True)

    elif do_copyfiles==0: #computing (not copying)
        pth_allrec = pth_compute
        pth_fldr_copydest_prefix = 'junkpath/' #this won't be used, making dummy name just in case 
    if do_copyfiles==1: #copying into O2
        pth_allrec = pth_storage
        pth_fldr_copydest_prefix = pth_compute
    elif do_copyfiles==2: #copying out of O2
        pth_allrec = pth_compute
        pth_fldr_copydest_prefix = pth_storage
    
    print("\n\n\npth_storage is : \n" + pth_storage)
    print("pth_compute is : \n" + pth_compute)
    print("pth_allrec is : \n" + pth_allrec)

    return pth_allrec, pth_fldr_copydest_prefix, pth_denoising
