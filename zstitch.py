


import numpy as np
import glob
import re
from natsort import natsorted
import fnmatch
import os
from tifffile.tifffile import imwrite, imread
import shutil
from denoising_score import denoising_score
import json



def stitchrg(pth_tif_reg, dims):

    print("\n\n\nstitching together separately registered z slices, and writing as one tif")

    pth_tif_all = natsorted(glob.glob(pth_tif_reg[:-4] + '*_z_.tif'))

    stack = np.zeros(dims, dtype='float32') #t z y x 

    countz = 0
    for f in pth_tif_all:
        countz = countz + 1
        print(f)
        sliceind = int(f.split('_')[-3])
        stacknew = imread(f)
        print(stacknew.dtype)
        print(sliceind)
        print("some (or probably all) slice min should be nonzero at this stage, this slice min is:" + str(np.min(stacknew)))
        stack[:,sliceind,:,:] = stacknew # was stack[:,:,:,sliceind] = stacknew

    if countz != dims[1]:
        raise Exception("incorrect number of registered files present")

    for f in pth_tif_all:
        os.remove(f)
        
    stack = np.transpose(stack, (0,3,2,1)) #transpose to txyz, to match caiman output

    mnmv = np.min(stack).astype('float32')
    stack -= mnmv #make nonnegative before converting to uint16
    if np.max(stack) > 65535:
        raise Exception("clipping will occur when converting to uint16")
    print("MIN AFTER REGISTRATION " + str(mnmv))
    stack = stack.astype('uint16')
    
    return stack 


def stitchdn(pth_denoising, fn_prefix, pth_tif_read, md, denoise_volume, epoch_choose_denoise, pthmd):

    #stitch together denoised slices (tyx) into original size (tzyx)

    print("\n\n\nENTERING FUNCTION stitchdn")

    pth_tif_write = pth_tif_read[:-4] + 'd_.tif' #forcing this suffix since stitch is specificaly for denoising (rather than letting it have use_denoised determine)
    
    if os.path.isfile(pth_tif_write):
        print("\n\n\nWARNING, STITCHED DENOISED STACK ALREADY EXISTS - OVERWRITING IT NOW")
  
    dims_pre_denoise = md['dims']

    #channel infixes will only exist for denoised 2-channel recordings, even if only one channel was denoised
    chn1_infix_exists = 0
    chn2_infix_exists = 0
    if 'channel_save' in md: #older runs of do_register will not have this field in md, if you want it, delete mdsi and rerun
        if not isinstance(md['channel_save'], int):
            if len(md['channel_save'])==2:
                if len(glob.glob(os.path.join(pth_denoising, fn_prefix + '_chn1_*/')))!=0:
                    chn1_infix_exists = 1
                if len(glob.glob(os.path.join(pth_denoising, fn_prefix + '_chn2_*/')))!=0:
                    chn2_infix_exists = 1
                

    all_dn_folders = glob.glob(os.path.join(pth_denoising, fn_prefix + '_*/'))
    onechan_dn_folders = [fntmp for fntmp in all_dn_folders if ( re.search(r'\d+/$', fntmp) or re.search(r'all/$', fntmp) ) and not re.search('chn1', fntmp) and not re.search('chn2', fntmp)]
    if len(onechan_dn_folders)!=0 and (chn1_infix_exists or chn2_infix_exists):
        raise Exception("WARNING, THERE ARE DENOISING FOLDERS FOR THIS RECORDING WITH AND WITHOUT CHANNEL INFIXES; THIS MEANS THIS RECORDING IS 2-CHANNEL, AND AT SOME POINT YOU RAN DENOISING ON A STACK (FOR EXAMPLE THE REGISTERED STACK) THAT HAD A CHANNEL DISCARDED, AND ALSO AT SOME POINT RAN DENOISING ON BOTH CHANNELS; THE CODE DOESN'T KNOW WHICH YOU ARE TRYING TO DO RIGHT NOW; DELETE THE DENOISING FOLDER(S) YOU DON'T NEED; THIS IS A HACK SOLUTION THAT NEEDS TO BE FIXED")

    chanrm = None
    if chn1_infix_exists and chn2_infix_exists:
        stack_dtype = 'uint16' #float within stitchdn_onechan, but 2 channels are put together as uint16
        stack_allchan = np.zeros((dims_pre_denoise[0], dims_pre_denoise[1], 2, dims_pre_denoise[2], dims_pre_denoise[3]), dtype=stack_dtype)
        chan_str_insert = '_chn1'
        stack_allchan[:,:,0,:,:] = stitchdn_onechan(pth_denoising, fn_prefix, pth_tif_read, dims_pre_denoise, denoise_volume, epoch_choose_denoise, chan_str_insert)
        chan_str_insert = '_chn2'
        stack_allchan[:,:,1,:,:] = stitchdn_onechan(pth_denoising, fn_prefix, pth_tif_read, dims_pre_denoise, denoise_volume, epoch_choose_denoise, chan_str_insert)
    elif chn1_infix_exists and not chn2_infix_exists:
        chanrm = 2
        chan_str_insert = '_chn1'
        print("\n\n\nSTITCHING CHANNEL 1 BECAUSE chn1 infix exists in the denoising folder but not chn2 infix; you must have denoised only channel 1 of a 2-channel stack (raw or registered)")
        stack_allchan = stitchdn_onechan(pth_denoising, fn_prefix, pth_tif_read, dims_pre_denoise, denoise_volume, epoch_choose_denoise, chan_str_insert)
    elif not chn1_infix_exists and chn2_infix_exists:
        chanrm = 1
        chan_str_insert = '_chn2'
        print("\n\n\nSTITCHING CHANNEL 2 BECAUSE chn2 infix exists in the denoising folder but not chn1 infix; you must have denoised only channel 2 of a 2-channel stack (raw or registered)")
        stack_allchan = stitchdn_onechan(pth_denoising, fn_prefix, pth_tif_read, dims_pre_denoise, denoise_volume, epoch_choose_denoise, chan_str_insert)
    elif not chn1_infix_exists and not chn2_infix_exists:
        print("\n\n\nSTITCHING A SINGLE CHANNEL BECAUSE THERE ARE NO DENOISING FOLDERS WITH CHANNEL INFIXES (chn1 or chn2); EITHER THE RECORDING HAS ONLY ONE CHANNEL, OR YOU DISCARDED A CHANNEL IN THE STACK YOU DENOISED (FOR EXAMPLE, THE REGISTERED STACK)")
        chan_str_insert = ''
        stack_allchan = stitchdn_onechan(pth_denoising, fn_prefix, pth_tif_read, dims_pre_denoise, denoise_volume, epoch_choose_denoise, chan_str_insert)


    if len(stack_allchan.shape)==4:
        stack_allchan = stack_allchan.reshape(dims_pre_denoise[0] * dims_pre_denoise[1], dims_pre_denoise[2], dims_pre_denoise[3]) #(tz)yx
    elif len(stack_allchan.shape)==5:
        stack_allchan = stack_allchan.reshape(dims_pre_denoise[0] * dims_pre_denoise[1] * 2, dims_pre_denoise[2], dims_pre_denoise[3]) #(tzc)yx

    print(stack_allchan.shape)
    imwrite(pth_tif_write, stack_allchan, bigtiff=True, photometric='minisblack') #write the registered movie as tif for use in matlab, and caiman extraction below

    pthhd, pthtl = os.path.split(pth_tif_write)
    suffix = pthtl.replace(fn_prefix, '')
    suffix = suffix.replace('_.tif', '')

    print("now that the stack has been written, updating metadata to include chanrm")
    md['chanrm' + suffix] = chanrm
    with open(pthmd, 'w') as file: 
        file.write(json.dumps(md, sort_keys=True, indent=4))


def stitchdn_onechan(pth_denoising, fn_prefix, pth_tif_read, dims_pre_denoise, denoise_volume, epoch_choose_denoise, chan_str_insert):

    if denoise_volume == 1:
        pth_trainset_all = natsorted(glob.glob(os.path.join(pth_denoising, fn_prefix + chan_str_insert + '_all/')))
    else:
        pth_trainset_all = natsorted(glob.glob(os.path.join(pth_denoising, fn_prefix + chan_str_insert + '_*/')))
        pth_trainset_all = list(set(pth_trainset_all) - set(natsorted(glob.glob(os.path.join(pth_denoising, fn_prefix + '_al*/'))))) #exclude the "all" folders when denoise_volume==1

    stack = np.zeros((dims_pre_denoise[0], dims_pre_denoise[2], dims_pre_denoise[3], dims_pre_denoise[1]), dtype='float32') #t y x z

    if np.isscalar(epoch_choose_denoise) or len(epoch_choose_denoise)==1:
        print("\n\n\nuser passed only one epoch_choose_denoise, which is epoch #" + str(epoch_choose_denoise) + ", so using that to stitch together denoising stack")
        if len(epoch_choose_denoise)==1:
            bestepoch = epoch_choose_denoise[0]
        else:
            bestepoch = epoch_choose_denoise
    else:
        bestepoch = denoising_score(pth_trainset_all, epoch_choose_denoise, pth_tif_read, dims_pre_denoise)


    print("\n\n\nstitching together denoised tifs (each tif a single z slice), and writing as one tif")

    countz = 0
    for pth_trainset in pth_trainset_all:
    
        fldr_chex = natsorted(glob.glob(os.path.join(pth_trainset, 'DataFolderIs_*')))
        for fcxi,fcx in enumerate(fldr_chex):
            if fcxi!=len(fldr_chex)-1:
                print("deleting this denoise test folder from old run")
                print(fcx)
                shutil.rmtree(fcx)
    
        fldr_outtiff_all = natsorted(glob.glob(os.path.join(pth_trainset, 'DataFolderIs_*', 'E_*'))) #for all epochs that were used for denoising, organize tif files into single folder in 'denoised' folder
        for fldr_outtiff in fldr_outtiff_all:
        
            if fnmatch.fnmatch(fldr_outtiff.split('/')[-1], 'E_' + "{:02d}".format(bestepoch) + '_Iter_*'):
                pth_denoised_singles = natsorted(glob.glob(os.path.join(fldr_outtiff, '*output.tif')))

                for fni,f in enumerate(pth_denoised_singles): #loop over each denoised z slice and reassemble into array matching shape of original 4d volume
                    countz = countz + 1
                    print(f)
                    sliceind = int(f.split('/')[-1].split('_')[3])
                    stacknew = imread(f)
                    if stacknew.dtype!='uint16':
                        print("warning, converting type from " + str(stacknew.dtype))
                        if np.min(stacknew)<0 or np.max(stacknew) > 65535:
                            raise Exception("denoising have operated on uint16 for this pipeline, or adjust it")
                        stacknew = stacknew.astype('uint16')
                    print(stacknew.dtype)
                    print(sliceind)
                    stack[:,:,:,sliceind] = stacknew

    if countz != dims_pre_denoise[1]:
        raise Exception("not all slices present")

    mnmv = np.min(stack).astype('float32')
    stack -= mnmv #make nonnegative before writing to uint16
    print("MIN AFTER DENOISING " + str(mnmv))

    stack = stack.astype('uint16')

    stack = np.transpose(stack, (0, 3, 1, 2)) #tzyx
    print(stack.shape)

    return stack
