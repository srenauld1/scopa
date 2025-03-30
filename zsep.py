import numpy as np
import os
from tifffile.tifffile import imwrite, imread
import shutil
from stackchan import stackchan
from check_aborted_stack import check_aborted_stack
from flybackrm import flybackrm



def zsep_todn(pth_tif_read, fn_prefix, pth_denoising, md, pthmd, denoise_volume, chan_dn, dnraw):

    # prepare files for denoising by writing each z slice to different tif and putting in separate folders if denoise_volume = 0 
    # if using denoise_volume = 1, saves all separate tifs into one folder 
    # we do this cpu-intensive part outside denoise.py, which is gpu-intensive, since requesting lots of gpu and cpu will delay job start

    print("\n\n\nseparating z slices, and writing as separate tifs, to prepare data for deepcad denoising")
        
    stack = imread(pth_tif_read)
    
    chanrm = None #WARNING! in this function, chanrm should always be None so tmp files for input to denoising have chn* infix if it's a 2-channel recording, even if you want to only denoise one channel (in case you want to do the other later)
    if chanrm is not None:
        raise Exception("WARNING! in this function (zsep_todn), chanrm should always be None so tmp files for input to denoising have chn* infix if it's a 2-channel recording, even if you want to only denoise one channel (in case you want to do the other later)")
    if chan_dn == ['all'] or chan_dn=='all': #ignored if it's not a 2-channel recording according to metadata md
        chan_primary = 1 #can be any number from existing channels if chan_dn is 'all'; just sets which is denoised first
    else:
        chan_primary = chan_dn 

    if md['dims'][1]>1:
        stackisvol = 1
    else:
        stackisvol = 0

    md = check_aborted_stack(md, pthmd, stack, stackisvol) #fine to run this whether dnraw is true or false, it costs nothing
    
    stack, stack_secondary, two_channel_dn, chan_primary, chan_secondary, chanstr_primary, chanstr_secondary = stackchan(stack, md, pthmd, chanrm, chan_primary)

    stack = flybackrm(stack, md['dims'], md['flyback'])
    zsep_onechan(stack, md['dims'], denoise_volume, pth_denoising, fn_prefix, chanstr_primary)
    if stack_secondary is not None:
        stack = None
        stack = flybackrm(stack, md['dims'], md['flyback'])
        zsep_onechan(stack_secondary, md['dims'], denoise_volume, pth_denoising, fn_prefix, chanstr_secondary)

    return chanstr_primary, chanstr_secondary



def zsep_onechan(stack, dims, denoise_volume, pth_denoising, fn_prefix, chan_str_infix):
    
    stack = stack.reshape(dims)
    stack = np.transpose(stack, (0, 2, 3, 1)) #put in order t y x z (not t x y z)
    if stack.dtype!='uint16':
        raise Exception("dtype should be uint16 (arbitrary choice for this pipeline)")
    zind_all_dn = np.arange(dims[1])

    for zii in zind_all_dn: #deepcad wants 3d data, so organize slices into separate tif files, and put in one folder (if denoise_volume=1, ie train on all slices) or separate folders (if denoise_volume=0, ie train on z subset)

        stacknew = stack[:,:,:,zii]
        Lt, Ly, Lx = stacknew.shape
        denoise_input_dtype = stacknew.dtype
        if stacknew.shape != (dims[0], dims[2], dims[3]):
            raise Exception("dims changed")

        if denoise_volume:
            dnfolder = fn_prefix + chan_str_infix + '_all'
        else:
            dnfolder = fn_prefix + chan_str_infix + '_' + str(zii)
        tifname = fn_prefix + '_' + str(zii) + '_' + str(Lt) + '_' + str(Ly)  + '_' + str(Lx) + '_' + str(denoise_input_dtype) + '_.tif'

        print(tifname)
        pth_trainset = pth_denoising + dnfolder + '/' #dir containing all tif files for training
        pth_tif_write = pth_trainset + tifname
        if os.path.exists(pth_trainset) and (zii==0 or denoise_volume==0): #if you're on the first zii (regardless of denoise_volume value), or for all zii if denoise_volume==0
            shutil.rmtree(pth_trainset) #REMOVE any existing training folder before training, to ensure models don't get mixed (until "resume training" functionality is written)
        if not os.path.exists(pth_trainset): #don't make this "else" connected to "if" above because you have to evaluate it
            os.mkdir(pth_trainset)
        imwrite(pth_tif_write, stacknew, bigtiff=True, photometric='minisblack') #put the tif in the folder deepcad looks to for training data
