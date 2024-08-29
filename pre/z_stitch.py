


import numpy as np
import glob
import re
from natsort import natsorted
import fnmatch
import os
from tifffile.tifffile import imwrite, imread
import shutil
from denoising_score import denoising_score


def stitch_registered_slices(pth_tif_reg, dims):

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

    stack = np.transpose(stack, (0,3,2,1)) #transpose to txyz, to match caiman output

    for f in pth_tif_all:
        os.remove(f)
    
    return stack 



def stitch_denoised_slices(pth_denoising, fn_prefix, pth_tif_read, md, denoise_volume, epoch_choose_denoise):

    #stitch together denoised slices (tyx) into original size (tzyx)

    pth_tif_write = pth_tif_read[:-4] + 'dcdn_.tif'
    
    if os.path.isfile(pth_tif_write):
        print("\n\n\nWARNING, STITCHED DENOISED STACK ALREADY EXISTS - OVERWRITING IT NOW")
  
    dims_pre_denoise = md['dims']
    if denoise_volume == 1:
        pth_trainset_all = natsorted(glob.glob(os.path.join(pth_denoising, fn_prefix + '_all/')))
    else:
        pth_trainset_all = natsorted(glob.glob(os.path.join(pth_denoising, fn_prefix + '_*/')))
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
    stack = stack.reshape(dims_pre_denoise[0] * dims_pre_denoise[1], dims_pre_denoise[2], dims_pre_denoise[3]) #(tz)yx
    print(stack.shape)
    #imwrite(pth_tif_write, stack.squeeze(), bigtiff=True, photometric='minisblack') #squeeze was just for non-volumetric (old project), does it change header, slowing read dramatically?
    imwrite(pth_tif_write, stack, bigtiff=True, photometric='minisblack') #write the registered movie as tif for use in matlab, and caiman extraction below



def stitch_denoised_slices_carls_old_project(pth_denoising, fn_prefix, pth_tif_read, md, denoise_volume, epoch_choose_denoise):

  #stitch together denoised slices (tyx) into original size (tzyx, with singleton z)

    pth_tif_write = pth_tif_read[:-4] + 'dcdn_.tif'
    
    if os.path.isfile(pth_tif_write):
    
        print("\n\n\nWARNING, SKIPPING stitch BECAUSE pth_tif_write ALREADY EXISTS - DELETE IT TO CREATE A NEW ONE")
    
    else:

        print("\n\n\nwriting denoised tifs for carls old project, if you're not carl there's a problem")

        dims_pre_denoise = md['dims']

        goal_trial = int(fn_prefix.split('_')[2])
        actual_z_size = 1

        if denoise_volume == 1:
            pretend_trial = '1' # pretend they all come from same trial
            dnfolder = fn_prefix.split('_')[0] + '_' + fn_prefix.split('_')[1] + '_' + pretend_trial + '_all/' #for these non-volumetric grad recordings, if do_volume == 1, rename all trials "1", and each trial a different z slice
            pth_trainset_all = natsorted(glob.glob(pth_denoising + '/' + dnfolder))

        else:

            pth_trainset_all = natsorted(glob.glob(os.path.join(pth_denoising, fn_prefix + '_*/')))
            fldr_exclude = fn_prefix.split('_')[0] + '_' + fn_prefix.split('_')[1] + '_' + pretend_trial + '_al*/' 
            pth_trainset_all = list(set(pth_trainset_all) - set(natsorted(glob.glob(fldr_exclude)))) #exclude the "all" folders when denoise_volume==1

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
                if fnmatch.fnmatch(fldr_outtiff.split('/')[-1], 'E_' + "{:02d}".format(epoch_choose_denoise) + '_Iter_*'):
                    pth_denoised_singles = natsorted(glob.glob(os.path.join(fldr_outtiff, '*output.tif')))

                    stack = np.zeros((dims_pre_denoise[0], dims_pre_denoise[2], dims_pre_denoise[3], actual_z_size), dtype='float32') #t y x z
                    print(dims_pre_denoise[1])
                    for fni,f in enumerate(pth_denoised_singles): #loop over each denoised z slice and reassemble into array matching shape of original 4d volume
                        if denoise_volume == 1:
                            trial = int(f.split('/')[-1].split('_')[3]) + 1 #filename z position is actual trial if denoise_volume was==1, add one bc they were made zero index, but original trial is one indexed
                        else:
                            trial = int(f.split('/')[-1].split('_')[2]) #filename trial is in nortmal trial position

                        if trial == goal_trial:
                            countz = countz + 1
                            print(f)
                            sliceind = 0 #always zero for these non-volumetric old recordings 
                            stacknew = imread(f)
                            if stacknew.dtype!='uint16':
                                print("warning, converting type from " + str(stacknew.dtype))
                                if np.min(stacknew)<0 or np.max(stacknew) > 65535:
                                    raise Exception("denoising have operated on uint16 for this pipeline, or adjust it")
                                stacknew = stacknew.astype('uint16')
                            print(stacknew.dtype)
                            print(sliceind)
                            stack[:,:,:,sliceind] = stacknew

                            mnmv = np.min(stack).astype('float32')
                            stack -= mnmv #make nonnegative before writing to uint16
                            print("MIN AFTER DENOISING " + str(mnmv))
                                
                            stack = stack.astype('uint16')
                            
                            stack = np.transpose(stack, (0, 3, 1, 2)) #tzyx
                            print(stack.shape)
                            stack = stack.reshape(dims_pre_denoise[0] * actual_z_size, dims_pre_denoise[2], dims_pre_denoise[3]) #(tz)yx
                            print(stack.shape)
                            imwrite(pth_tif_write, stack.squeeze(), bigtiff=True, photometric='minisblack') #write the registered movie as tif for use in matlab, and caiman extraction below


                    if countz != dims_pre_denoise[1]:
                        raise Exception("more or less than one slice present")

