
import re
import os
import sys
from pathlib import Path
import inspect


def pthmake(do_copyfiles, do_autoallocate, folder_with_all_recordings_on_storage_and_compute_filesystems, pth_storage_prefix, scopatmpdir):

    print("\n\n\nsys.executable returns: \n" + sys.executable)

    print("sys.path[0] returns: \n" + sys.path[0])

    pth_scopa = pthscopaget()

    if scopatmpdir:
        pth_scopatmpdir = scopatmpdir
        print("\n\n\nsetting pth_scopatmpdir to scopatmp in user's home dir: \n" + pth_scopatmpdir)
    else:
        pp = Path(sys.path[0]).parts #split path
        split_index = pp.index('scopa') + 1
        pth_scopatmpdir = os.path.join(*pp[:split_index-1], 'scopatmp') #join to make suffix
        if not os.path.exists(pth_scopatmpdir):
            Path(pth_scopatmpdir).mkdir(parents=True, exist_ok=True)
        print("\n\n\nsetting pth_scopatmpdir to: \n" + pth_scopatmpdir)

    in_colab = 'google.colab' in sys.modules
    if in_colab:
        raise Exception("in colab run the ipynb pipeline instead")
    else:
        hn = os.popen('hostname').read()
        if re.search('compute.*harvard', hn): #if you're on O2, make compute folder that matches scratch path pattern
            pth_compute_prefix = '/n/scratch/users/' + pth_scopatmpdir.split('/')[-2][0] + '/' + pth_scopatmpdir.split('/')[-2] + '/'
        else: #else assume you're not on a cluster with specific compute folders (like scratch)
            pth_compute_prefix = ('/').join(pth_scopatmpdir.split('/')[:-1]) + '/' 


    if folder_with_all_recordings_on_storage_and_compute_filesystems[-1] != '/': 
        folder_with_all_recordings_on_storage_and_compute_filesystems = folder_with_all_recordings_on_storage_and_compute_filesystems + '/'
    if pth_storage_prefix[-1] != '/': 
        pth_storage_prefix = pth_storage_prefix + '/'

    pth_compute = pth_compute_prefix + folder_with_all_recordings_on_storage_and_compute_filesystems 
    if not os.path.exists(pth_compute):
        Path(pth_compute).mkdir(parents=True, exist_ok=True)

    pth_storage = pth_storage_prefix + folder_with_all_recordings_on_storage_and_compute_filesystems 
    if not os.path.exists(pth_storage) and do_copyfiles:
        raise Exception("pth_storage: \n" + pth_storage + "does not exist")

    pth_denoising = pth_compute_prefix + 'denoising' + '/' 
    if not os.path.exists(pth_denoising):
        Path(pth_denoising).mkdir(parents=True, exist_ok=True)

    pth_fldr_fnind = pth_scopatmpdir + '/' + 'fnind' + '/' 
    if not os.path.exists(pth_fldr_fnind):
        Path(pth_fldr_fnind).mkdir(parents=True, exist_ok=True)

    if do_autoallocate==1: 
        if do_copyfiles==0: #do_autoallocate uses transfer partition to look into server and find size of original scanimage tif, but doesn't copy anything 
            pth_allrec = pth_storage
            pth_fldr_copydest_prefix = pth_compute
        else:
            raise Exception ("if do_autoallocate is 1, do_copyfiles must be 0")
    else:
        if do_copyfiles==0: #computing (not copying)
            pth_allrec = pth_compute
            pth_fldr_copydest_prefix = 'junkpath/' #this won't be used, making dummy name just in case 
        elif do_copyfiles==1: #copying into O2
            pth_allrec = pth_storage
            pth_fldr_copydest_prefix = pth_compute
        elif do_copyfiles==2: #copying out of O2
            pth_allrec = pth_compute
            pth_fldr_copydest_prefix = pth_storage

    pth_optdf = pth_scopa + 'optdf.txt'
    pth_optroi = pth_allrec + 'optroi.txt'
    
    print("\n\n\npth_storage is : \n" + pth_storage)
    print("pth_compute is : \n" + pth_compute)
    print("pth_allrec is : \n" + pth_allrec)
    print("pth_fldr_fnind is : \n" + pth_fldr_fnind)

    return pth_scopa, pth_allrec, pth_fldr_copydest_prefix, pth_denoising, pth_fldr_fnind, pth_optdf, pth_optroi



def pthscopaget():
    
    # Get the frame of the current function
    frame = inspect.currentframe()

    # Get the filename of the current function
    filename = inspect.getframeinfo(frame).filename

    # Get the directory of the current function
    pth_scopa = os.path.dirname(os.path.abspath(filename))

    pth_scopa = pth_scopa + '/'

    # pp = Path(currscriptdir).parts #split path
    # pp_splitind = pp.index('scopa') + 1
    # pth_scopa = os.path.join(*pp[:pp_splitind]) + '/'

    return pth_scopa
    