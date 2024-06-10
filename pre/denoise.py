


##########################################################################################################################################
# using deepcad to denoise 

# deepcad wants 3d data, and rather than reshaping the 4d array into 3d (denoising on all z slices at once), this script either
# operates on each z slice independently (if denoise_volume = 0), or all z slices (if denoise_volume = 1) . . . currently not set up to do anything in between 

# since noise varies with z, default is denoise_volume = 0, 
# but if individual z slices are being underfit (denoised output is blurry), 
# and increasing any or all of patch size, overlap, or train_dataset_size does not help with the underfitting, then you may need more data, 
# so consider fitting a z slices with denoise_volume = 1 . . . or you can adapt the code (should be simple) to fit some subset, e.g. every pair of z slices
 
# deepcad creates intermediate files that are saved in pth_denoising

# denoise_volume = 1 trains on all z slices listed in denoise_slice_index together, 
# denoise_volume = 0 trains on each z slice listed in denoise_slice_index separately
# denoise_slice_index lists which z slices to denoise
# if denoise_volume = 0, each z slice of 4d volumetric input movie is saved as a separate tif in a separate folder, each passed to deepcad, saved separately in a unique pth_trainset, 

#if denoise_volume = 1, each z slice is saved as a separate tif in the same folder, pth_trainset

# regardless of denoise_volume, denoised z slices are saved in separate tifs, 
# and outside this script the separate denoised z slices are reassmbled as single output file, which is placed in same folder as original tif 

# before denoising, deepcad and torch needs to be installed (see readme.md in this repo scopa)

# TRAIN MEANS LEARNING A MODEL THAT DESCRIBES AN INPUT MOVIE'S SIGNAL AND NOISE
# TEST MEANS PASSING A MOVIE THROUGH THAT MODEL TO DENOISE IT, THE OUTPUT FROM THE TESTING PHASE IS THE DENOISED MOVIE 
# INPUT TO TRAIN AND TEST DO NOT HAVE TO BE THE SAME MOVIE (BUT I ALWAYS MAKE THEM THE SAME MOVIE)

# it's possible to resume training if interrrupted by loading most recent .pth file, but currently this is inconvenient 
# because the deepcad code appends a timestamp to the .pth file's enclosing folder, so a new folder will be created when you resume
# it should still work, but you will have epochs spread across multiple folders
# however, the code below does not have this resuming training functionality yet, 
# so (WARNING) to ensure models don't get mixed, there is a line that removes any existing training folder before training (shutil.rmtree(pth_trainset_all[countz])



# # note train_datasets_size is APPROXIMATE number of 3d xyt patches to train the model on (so can exceed number of frames), is a little different from actual number patches because of how stride/gap in time is computed automatically
# # while test_datasize during training is number of frames to denoise during optional visualization/saving after each epoch (so I assign it variable name num_frames_of_each_tif_to_denoise_for_visualization_during_training)
# # while test_datasize during testing is number of frames to denoise using the model (so I assign it variable name num_frames_of_each_tif_to_denoise)
# # and select_img_num is number of frames in each tif file to include in training, counted from the beginning of each stack (tif) (this param is not used in testing, but test_datasize is analogous)

# # overlap factor applies to patch x and y, but not patch t
# # patch t spacing/overlap is based on how many xy patches there are in each frame, train_datasets_size, and patch_t, it is automatically calculated to evenly distribute the patches in time

# # deepcad's demo "best model" for int16 stack shape (6955,492,492) is train_datasets_size = 6000, n_epochs = 20, patch_x,y,t = 150, overlap_factor = 0.4 
# # here is their demo data:
# # fn_demo ='fish_localbrain' # select the demo file you want to train (e.g. 'ATP_3D', 'fish_localbrain', 'NP_3D', ...)
# # pth_demo, _ = download_demo(download_filename=fn_demo)
# # demodata = imread(pth_demo + '/fish_localbrain.tif')

# # the model should not converge (loss should not decrease across epochs) since the source and target are both original noisy images
# # so do not use the loss to guide you in tuning parameters. just inspect the results. 
# # in general the last epoch is the one to use, 
# # but if it looks just smoothed, it's underfit (so try more epochs or larger train_dataset_size), and if it looks too sharp/punctate, it's overfit (so try fewer epochs or smaller train_dataset_size)
# # epochs are continuous (not independent), so if training is interrupted, reload the last completed epoch on the .pth file and resume training (code is not yet written to do this, see above)

## patch overlap is not essential for denoising, it is just a way to augment the data, if you have enough data, your patches do not have to overlap, 
#this can happen automatically in patch_t, but i'm not sure if you can set patch_x or y to 0 or negative to prevent overlap 

# overlap in each dim xyt should be at least 90 to avoid stitching artifacts 
# overlap_t = patch_t - gap_t

#see matlab script scopa/util/find_denoising_params.m for how input params interact in the deepcad code 

##########################################################################################################################################


import torch

if torch.cuda.is_available():
    print('\033[1;31mGPU accessiable. Use GPU for computation.\033[0m')
    gpu_id = torch.cuda.current_device()
    total_memory = torch.cuda.get_device_properties(gpu_id).total_memory/1024/1024
    alloc_memory = torch.cuda.memory_allocated(0)/1024/1024
    print('GPU ID: ', gpu_id, '|', torch.cuda.get_device_name(), \
          '| Memory: {:.0f} MB'.format(total_memory))
    # print(nvidia-smi) #this will error 
    # print(nvcc --version) #not sure if this will error
    print('PyTorch version: ', torch.__version__)
else:
    print('\033[1;31mNo GPU support. Please enable GPUs for the notebook:\033[0m')
    print(' 1. Navigate to Edit Ã¢ÂÂ Notebook Settings')
    print(' 2. Select GPU from the Hardware Accelerator drop-down')

import os
import glob
import shutil
import numpy as np
import fnmatch
from natsort import natsorted
from helpers import stitch_denoised_slices, stitch_denoised_slices_carls_old_project

from deepcad.train_collection import training_class
from deepcad.test_collection import testing_class


def denoise(pth_denoising, fn_prefix, dims, volrate, denoise_slice_index, denoise_volume, num_epochs_denoise, carls_old_project, pth_tif_read, epoch_choose_denoise):


    ##########################   DEEPCAD DENOISING   ##########################
    
    print("\n\n\nENTERING DENOISE FUNCTION")

    patch_t_sec = 20 #20 seconds is just a guess 
    padinc = 5 #this is probably pointless and can probably be zero 

    stack_size_t = dims[0]
    stack_size_z = dims[1]
    stack_size_y = dims[2]
    stack_size_x = dims[3]
    default_patch_xy = 120
    train_datasets_size = 6000 #approximately how many 3d xyt patches to train on, which can be different from what actually gets used because of how gap/stride in t is computed; in case this number is set too high (will cause deepcad error), scopa code below lowers it to the highest acceptable value 
    overlap_factor = 0.8 # the overlap factor between two adjacent patches in x and y (t is more complicated see above)


    if carls_old_project: #if it's not my old grad school project 
        if denoise_volume:
            pretend_trial = '1' # pretend they all come from same trial
            dnfolder = fn_prefix.split('_')[0] + '_' + fn_prefix.split('_')[1] + '_' + pretend_trial + '_all' #for these non-volumetric grad recordings, if do_volume == 1, rename all trials "1", and each trial a different z slice
            numstacks_all_refers_to = len(glob.glob(pth_denoising + '/' + dnfolder + '/*tif')) #and 'all' means all stacks in dnfolder (which is really all trials)
        else: #if not denoise_volume, all is just one stack 
            numstacks_all_refers_to = 1
    else:
        numstacks_all_refers_to = stack_size_z # then 'all' is number of z slices 


    if denoise_slice_index == ['all'] or denoise_slice_index=='all': 
        zind_all_dn = np.arange(numstacks_all_refers_to)
        print("user chose denoise_slice_index 'all', which means " + str(numstacks_all_refers_to) + " slices (which are called 'stacks' in deepcad)")
    else:
        print("user set denoise_slice_index to: " + str(denoise_slice_index))
        zind_all_dn = denoise_slice_index
    
    if denoise_volume: 
        numstacks_trained_simultaneously = len(zind_all_dn)
    else: 
        numstacks_trained_simultaneously = 1

    print("denoising these slices: \n" + str(zind_all_dn))
    print("will save denoising intermediate results to: \n" + pth_denoising)
    print("filename prefix is: " + fn_prefix)
    print("input dimensions are: " + str(dims))
    print("denoise_volume is set to: " + str(denoise_volume))

    n_epochs = num_epochs_denoise  # number of training epochs (loss is continuous across patches and epochs - epochs and patches are not independent)
    epochs_choose = list(range(1,n_epochs+1)) #list, one-indexed like n_epochs, which training epochs (which states of the model) to use for testing (denoising), default here is to test (denoise) with model state after all epochs 

    patch_x = default_patch_xy if stack_size_x>default_patch_xy + padinc else int(stack_size_x - padinc) # 110 #int(np.ceil(Lx/4)) #extent of patch in x
    patch_y = default_patch_xy if stack_size_y>default_patch_xy + padinc else int(stack_size_y - padinc) #120 #110 #int(np.ceil(Ly/4)) #extent of patch in y
    patch_t = int(np.ceil(patch_t_sec*volrate)) #102 # 300 #extent of patch in t

    patch_t2 = patch_t*2 #use patch_t2 since alternating frames are sent to either end of the Unet, so you actually need double patch size in t)

    gap_x = np.floor(patch_x * (1 - overlap_factor)) 
    gap_y = np.floor(patch_y * (1 - overlap_factor)) 
    xnum = np.floor((stack_size_x - patch_x) / gap_x) + 1
    ynum = np.floor((stack_size_y - patch_y) / gap_y) + 1

    train_datasets_size_adjust = train_datasets_size+1
    gap_t = 0
    while gap_t==0:

        train_datasets_size_adjust = train_datasets_size_adjust - 1

        tnum = np.ceil(train_datasets_size_adjust / xnum / ynum / numstacks_trained_simultaneously)
        gap_t = np.floor((stack_size_t - patch_t2) / (tnum - 1)) #patch_t times 2 since input and target are interleaved and both patch_t length in t; THE FLOOR IN THIS LINE CAUSES THE NUMBER OF TRAINING PATCHES TO DIFFER FROM THE NUMBER REQUESTED IN TRAIN_DATASET_SIZE (ie integer shifts attempting to equal TRAIN_DATASET_SIZE, given patch number in x and y)

        numpatch_y = np.floor((stack_size_y - patch_y + gap_y) / gap_y)
        numpatch_x = np.floor((stack_size_x - patch_x + gap_x) / gap_x)
        if gap_t!=0:
            numpatch_t = np.floor((stack_size_t - patch_t2 + gap_t) / gap_t)
            num_true_patch_total = int(numpatch_y*numpatch_x*numpatch_t)
    
    train_datasets_size = train_datasets_size_adjust

    print("\nusing train_datasets_size: " + str(train_datasets_size) + "\nwhich actually means " + str(num_true_patch_total) + " patches in each of the " + str(numstacks_trained_simultaneously) + " z slices, for a total of " + str(num_true_patch_total*numstacks_trained_simultaneously) + " patches for the entire training set")


    select_img_num = 1e10 # number of frames to take from the beginning of each stack for training (make Lt or greater to use all frames)
    intensity_scale_factor = 1 # the factor for image intensity scaling
    num_frames_of_each_tif_to_denoise_for_visualization_during_training = patch_t + 10 #NEEDS TO BE AT LEAST PATCH_T TO PREVENT ERROR; for the optional inference visualization if save_test_images_per_epoch or visualize_images_per_epoch is True, and the code defaults to taking this number after the first 50 frames for display/save
    # num_frames_of_each_tif_to_denoise_for_visualization_during_training = 1000 if stack_size_t>1010 else int(stack_size_t) #NEEDS TO BE AT LEAST PATCH_T TO PREVENT ERROR; for the optional inference visualization if save_test_images_per_epoch or visualize_images_per_epoch is True, and the code defaults to taking this number after the first 50 frames for display/save
    GPU = '0'                   # the index of GPU you will use (e.g. '0', '0,1', '0,1,2')
    num_workers = 0             # if you use Windows system, set this to 0.
    save_test_images_per_epoch = True  # whether to save result images after each epoch
    num_frames_of_each_tif_to_denoise = 1e10 #this is number of frames of each tif to be tested (denoised); make this the length of the stack (or greater) to get the whole stack denoised

    denoise_dtype = "uint16" #dtype for denoising, and writing results, but regardless, stitch_denoised_slices will write to uint16


    if denoise_volume: #if training on all slices, put them all in one folder
        pth_trainset_all = ['']
        pth_testset_all = ['']
    else: #if training on subset of slices, put each subset in separate folder (but right now subset must be single slice, which can be looped over if slice index is 'all')
        pth_trainset_all = ['']*len(zind_all_dn)
        pth_testset_all = ['']*len(zind_all_dn)

    countz = -1
    for zii in zind_all_dn: #deepcad wants 3d data, so organize slices into separate tif files, and put in one folder (if denoise_volume=1, ie train on all slices) or separate folders (if denoise_volume=0, ie train on z subset)

        if denoise_volume:
            dnfolder_insert = 'all'
            countz = 0 #constant 0 because every slice goes to the same directory
        else:
            dnfolder_insert = str(zii)
            countz = countz + 1

        dnfolder = fn_prefix + '_' + dnfolder_insert
        tifname = fn_prefix + '_' + str(zii) + '*_.tif'

        pth_trainset_all[countz] = pth_denoising + '/' + dnfolder #dir containing all tif files for training
        pth_testset_all[countz] = pth_trainset_all[countz] + '/' + dnfolder + '_*' #dir containing all models (.pth files) for test

        oldfldrs = glob.glob(pth_testset_all[countz]) #delete folders from old runs until you have resume training functionality written
        if oldfldrs:
            for ofi in oldfldrs:
                if os.path.isdir(ofi):
                    shutil.rmtree(ofi)

        print(pth_trainset_all[countz] + '/' + tifname)
        pth_tif_pdn = glob.glob(pth_trainset_all[countz] + '/' + tifname)
        print(pth_tif_pdn)
        for ofi in pth_tif_pdn: #these should be the same for all files
            Lt = int(ofi.split('/')[-1].split('_')[-5])
            Ly = int(ofi.split('/')[-1].split('_')[-4])
            Lx = int(ofi.split('/')[-1].split('_')[-3])
            denoise_input_dtype = ofi.split('/')[-1].split('_')[-2]

        denoise_input_shape = (Lt, Ly, Lx)
        print(denoise_input_shape)
        print(denoise_input_dtype)
        if denoise_input_dtype!=denoise_dtype:
            raise Exception("dtype doens't match intended")
        if denoise_input_shape != (stack_size_t, stack_size_y, stack_size_x):
            raise Exception("dims changed")


    ########################### TRAIN ##########################

    for pth_trainset, pth_testset in zip(pth_trainset_all, pth_testset_all):

            print(pth_trainset)

            train_dict = {
                # dataset dependent parameters
                'patch_x': patch_x,                          # the width of 3D patches
                'patch_y': patch_y,                          # the height of 3D patches
                'patch_t': patch_t,                          # the time dimension (frames) of 3D patches
                'overlap_factor': overlap_factor,             # the factor for image intensity scaling
                'scale_factor': intensity_scale_factor,      # the factor for image intensity scaling
                'select_img_num': select_img_num, # number of images to take from the beginning of each stack (make larger than Lt use the full stack)
                'train_datasets_size': train_datasets_size,  # datasets size for training (how many 3D patches)
                'test_datasize': num_frames_of_each_tif_to_denoise_for_visualization_during_training,
                'datasets_path': pth_trainset,             # folder containing files for training
                'pth_dir': pth_trainset,                   # the path for pth file (saved models) and optional test images saved after each epoch if save_test_images_per_epoch=True

                # network related parameters
                'n_epochs': n_epochs,                          # the number of training epochs
                'lr': 0.00005,                                 # learning rate
                'b1': 0.5,                                     # Adam: beta1
                'b2': 0.9,                                   # Adam: beta2
                'fmap': 16,    # model complexity, 16 by default, deepcad author says it should not require adjustment
                'GPU': GPU,                                    # GPU index
                'num_workers': num_workers,                    # if you use Windows system, set this to 0.
                'visualize_images_per_epoch': False,                       # whether to show result images after each epoch
                'save_test_images_per_epoch': save_test_images_per_epoch,  # whether to save result images after each epoch
                'colab_display': True #if colab_display is true and save_test_images_per_epoch is false, it will error between training and testing
            }

            tc = training_class(train_dict)
            tc.run()


    ############################################# TEST (DENOISE) RECORDINGS WITH CHOSEN MODEL ##########################

            # deepcad defaults to denoising all tifs in datasets_path with all models (.pth files) in folder denoise_model
            # and will output denoised versions of those tifs and save in output_dir
            # but, to override default behavior, here i move all pth files except those listed in epochs_choose (which can still be all of them)

            pth_para = natsorted(glob.glob(pth_testset + '/' + '*.yaml'))[-1] #yaml file contains parameters used for training, to be loaded and reused for testing, since there is one yaml per folder, taking the last glob output takes the yaml in the most recent folder (the current run because of datetime in name)
            pth_pth_all = natsorted(glob.glob(pth_testset + '/' + '*.pth')) #paths to pth files (trained models, one for each epoch )

            pth_pth_keep_pattern = []
            for ec in epochs_choose:
                pth_pth_keep_pattern.append('E_' + "{:02d}".format(ec) + '_*.pth')

            print("using pth files with the following pattern: \n" + '%s' % '\n'.join(map(str, pth_pth_keep_pattern)) + "\n because epochs_choose is \n" + '%s' % ', '.join(map(str, epochs_choose)) )
            
            pthcheck_prev = ''
            for ppi,pth_pth in enumerate(pth_pth_all): #make sure there aren't multiple train folders before you move pth files below
                pth_fldr_pth = '/'.join(pth_pth.split('/')[:-1])
                if ppi>0 and pth_fldr_pth != pthcheck_prev:
                    print("WARNING, FOUND AT LEAST TWO TRAINING FOLDERS \n" + pthcheck_prev + "\n" + pth_fldr_pth)
                    raise Exception("multiple training folders are not allowed until resume training functionality exists")
                pthcheck_prev = pth_fldr_pth

            fldr_unused_pth = pth_fldr_pth + '/' + 'unused_pth_files/' #folder for the pth files you don't want to use for testing

            for pth_pth in pth_pth_all: #move all pth files besides the ones you want to test with
                fn_pth = pth_pth.split('/')[-1]
                if not any(fnmatch.fnmatch(fn_pth, pat+'*') for pat in pth_pth_keep_pattern):
                    if not os.path.exists(fldr_unused_pth):
                        os.mkdir(fldr_unused_pth)
                    print("moving the following pth file into unused_pth_files because it's not specified by epochs_choose: \n" + pth_pth)
                    shutil.move(pth_pth, fldr_unused_pth) #move all pth files besides the ones you want to test with

            fldr_pth = pth_fldr_pth.split('/')[-1] #folder with all the pth files


            with open(pth_para, "r") as stream: #read the params from training to apply to testing
                patch_t = train_dict['patch_t']
                patch_x = train_dict['patch_x']
                patch_y = train_dict['patch_y']
                fmap = train_dict['fmap']
                overlap_factor = train_dict['overlap_factor']

            test_dict = {
                # dataset dependent parameters
                'patch_x': patch_x,               # the width of 3D patches
                'patch_y': patch_y,               # the height of 3D patches
                'patch_t': patch_t,               # the time dimension (frames) of 3D patches
                'overlap_factor':overlap_factor,    # overlap factor
                'scale_factor': intensity_scale_factor, # the factor for image intensity scaling
                'test_datasize': num_frames_of_each_tif_to_denoise,     # the number of frames in each tif to be denoised/tested, measured from start
                'datasets_path': pth_trainset,     # folder containing all files to be tested
                'pth_dir': pth_trainset,                 # pth file root path
                'denoise_model' : fldr_pth,    # A folder containing all models (pth files) to be tested
                'output_dir' : pth_trainset,         # result file root path
                # network related parameters
                'fmap': fmap,                         # number of feature maps
                'GPU': GPU,                         # GPU index
                'num_workers': num_workers,         # if you use Windows system, set this to 0.
                'visualize_images_per_epoch': False, # whether to display inference performance after each epoch
                'save_test_images_per_epoch': save_test_images_per_epoch, # whether to save inference image after each epoch in pth path
                'colab_display': True #if colab_display is true and save_test_images_per_epoch is false, it will error between training and testing
            }

            tc = testing_class(test_dict)
            tc.run()

    # moved stitch to its own job because it can require more memory than the denoising, but only takes a minute
    # if carls_old_project: 
    #     stitch_denoised_slices_carls_old_project(pth_denoising, fn_prefix, pth_tif_read, md, denoise_volume, epoch_choose_denoise) 
    # else:
    #     stitch_denoised_slices(pth_denoising, fn_prefix, pth_tif_read, md, denoise_volume, epoch_choose_denoise) 

