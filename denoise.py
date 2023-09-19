


##########################################################################################################################################
# this script operates on individual input files 
# using deepcad to denoise 

# typically I call this script from pipeline.py, but it can be run on its own from the command line  

# deepcad wants 3d data, and rather than reshaping the 4d array into 3d (denoising on all z slices at once), this script
# operates on each z slice independently, since noise varies with z 

# deepcad creates intermediate files that are saved in pth_denoising
# each z slice of 4d volumetric input movie is passed to deepcad, saved separately in pth_denoised, 
# outside this script, the separate denoised z slices are reassmbled as single output file, which is placed in same folder as input file pth_in 


# before running denoise.py (in dnp.sbatch or directly on command line), deepcad and torch needs to be installed (instructions on their github)
# after that you also need to run the following commands (to install a couple extra packages in the deepcad environment) 
# module load miniconda3/4.10.3
# source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
# conda activate deepcadrt
# pip install mat73
# pip install matplotlib 
##########################################################################################################################################

import torch

if torch.cuda.is_available():
    print('\033[1;31mGPU accessiable. Use GPU for computation.\033[0m')
    gpu_id = torch.cuda.current_device()
    total_memory = torch.cuda.get_device_properties(gpu_id).total_memory/1024/1024
    alloc_memory = torch.cuda.memory_allocated(0)/1024/1024
    print('GPU ID: ', gpu_id, '|', torch.cuda.get_device_name(), \
          '| Memory: {:.0f} MB'.format(total_memory))
    #nvcc--version
    print('PyTorch version: ', torch.__version__)
else:
    print('\033[1;31mNo GPU support. Please enable GPUs for the notebook:\033[0m')
    print(' 1. Navigate to Edit → Notebook Settings')
    print(' 2. Select GPU from the Hardware Accelerator drop-down')

import os
import glob
import shutil
import numpy as np
import sys
import datetime
import re

from tifffile.tifffile import imwrite, imread

import matplotlib.pyplot as plt

from natsort import natsorted

from deepcad.train_collection import training_class
from deepcad.test_collection import testing_class
# from deepcad.movie_display import display, display_img
# from deepcad.utils import get_first_filename

import mat73

from parse_command_line import parse_command_line_denoise


# some default values
pth_in = '/Users/wienecke/Documents/ambrose/stacks/20230624-2_D05_syt7f_018_syt7f/20230624_2_1_cmrg_.tif' #file the be denoised 
pth_denoising = '/Users/wienecke/Documents/ambrose/denoising' #path for intermediate files created by deepcad
pth_denoised = '/Users/wienecke/Documents/ambrose/denoised' #path for finished (denoised) 3d files, prior to reassembling 
fn_prefix = '20230624_2_1' #filename prefix (date_fly_trial)
dims = [3047, 15, 140, 256] # input motion dimensions (and output movie dimensions)
denoise_slice_index = [0]

[pth_in, pth_denoising, pth_denoised, fn_prefix, dims, denoise_slice_index] = parse_command_line_denoise(pth_in = pth_in,
                    pth_denoising = pth_denoising, pth_denoised = pth_denoised, 
                    fn_prefix = fn_prefix, dims = dims, denoise_slice_index = denoise_slice_index)

print(pth_in)
print(pth_denoising)
print(pth_denoised)
print(fn_prefix)
print(dims)
print(denoise_slice_index)

env_path = sys.path

# #@title denoise

# TRAIN MEANS LEARNING A MODEL THAT DESCRIBES AN INPUT MOVIE'S SIGNAL AND NOISE
# TEST MEANS PASSING A MOVIE THROUGH THAT MODEL TO DENOISE IT, THE OUTPUT FROM THE TESTING PHASE IS THE DENOISED MOVIE 
# INPUT TO TRAIN AND TEST DO NOT HAVE TO BE THE SAME MOVIE (BUT I ALWAYS MAKE THEM THE SAME MOVIE)

denoise_slice_index = 'all' #'all' or list of integers
do_volume = 0
denoise_dtype = "uint16" #dtype for denoising, and writing results, but regardless, stitch_denoised_slices will write to uint16  


Y = imread(pth_in).astype(denoise_dtype)
Y = Y.reshape(dims)
Y = np.transpose(Y, (0, 2, 3, 1)) #put in order t y x z (not t x y z)

size_pre_denoise = Y.shape

fn_existing_denoised_slices = natsorted(glob.glob(pth_denoised + '/' + fn_prefix + '*output.tif'))
if 0:#skip this for now until we know more, was previously this: if fn_existing_denoised_slices:
    largest_denoised_slice_index = int(fn_existing_denoised_slices[-1].split('/')[-1].split('_')[3])
    print(denoise_slice_index)
    print("updating denoise slice index bc largest existing is " + str(largest_denoised_slice_index))
    if denoise_slice_index=='all':
        zind_all_dn = np.arange(largest_denoised_slice_index + 1, Y.shape[-1])
    else:
        zind_all_dn = [x + largest_denoised_slice_index for x in denoise_slice_index]
    print(zind_all_dn)
else:
    if denoise_slice_index == 'all':
        zind_all_dn = np.arange(size_pre_denoise[-1])
    else:
        zind_all_dn = denoise_slice_index


print(pth_in)
print(zind_all_dn)

if do_volume: #if training on all slices, put them all in one folder 
    pth_trainset_all = ['']
    pth_testset_all = ['']
else: #if training on subset of slices, put each subset in separate folder 
    pth_trainset_all = ['']*len(zind_all_dn)
    pth_testset_all = ['']*len(zind_all_dn)


tmpdate = datetime.datetime.now().strftime("%Y%m%dT%H%M%S") 
countz = -1
for zii in zind_all_dn: #deepcad wants 3d data, so organize slices into separate tif files, and put in one folder (if do_volume=1, ie train on all slices) or separate folders (if do_volume=0, ie train on z subset)

    Ynew = Y[:,:,:,zii]
    Lt, Ly, Lx = Ynew.shape #don't need to index these they should be the same for all stacks
    if countz>-1 and prev_shape != Ynew.shape:
      raise Exception("dims changed")
    prev_shape = Ynew.shape

    if do_volume:
      dnfolder_insert = 'all'
      countz = 0 #constant 0 because every slice goes to the same directory
    else:
      dnfolder_insert = str(zii)
      countz = countz + 1

    dnfolder = fn_prefix + '_' + dnfolder_insert # + '_' + tmpdate
    tifname = fn_prefix + '_' + str(zii) + '_.tif'

    pth_trainset_all[countz] = pth_denoising + '/' + dnfolder #dir containing all tif files for training
    pth_testset_all[countz] = pth_trainset_all[countz] + '/' + dnfolder + '_*' #dir containing all models (.pth files) for test 
    pth_tif_pdn = pth_trainset_all[countz] + '/' + tifname

    if os.path.exists(pth_trainset_all[countz]):
      if zii==0 or do_volume==0: #remove existing folder if you're on the first zii (regardless of do_volume value), or for all zii if do_volume==0 
        shutil.rmtree(pth_trainset_all[countz]) 
    if not os.path.exists(pth_trainset_all[countz]): #don't make this "else" connected to "if" above because you have to evaluate it  
      os.mkdir(pth_trainset_all[countz])
    
    print(pth_tif_pdn)
    imwrite(pth_tif_pdn, Ynew.astype(denoise_dtype), photometric='minisblack' ) #put the tif in the folder deepcad looks to for training data



# ########################## TRAIN ########################## 

# # train_datasets_size is how many 3d xyt patches to train on
# # overlap factor applies to patch x and y, but not patch t
# # patch t spacing is based on how many xy patches there are in each frame, train_datasets_size, and patch_t
# # the maximum possible train_datasets_size for a given xy patch number (ie how to obtain patch_t spacing of 1 frame, which is totally un)
# # is roughly the number of frames in each stack minus double the patch_t size (double since the algorithm takes interleaved frames as input/output) 
# # times number of stacks, times the number of xy patches in each frame 
# # for example, for a 4d recording whose tzyx shape is (3047,15,140,256)
# # if there are 36 xy patches per frame (determined by patch_x and patch_y and overlap factor), and patch_t is 300
# # the maximum train_datasets_size is (3047 - (300*2)) * 15 * 36 (which will give patch_t spacing of 1 frame)
# # of course this is not optimal,
# # above this number causes errors because it calls for t patch spacing of zero 
# # deepcad's demo "best model" for int16 stack shape (6955,492,492) is train_datasets_size = 6000, n_epochs = 20, patch_x,y,t = 150, overlap_factor = 0.4 
# # here is their demo data:
# # fn_demo ='fish_localbrain' # select the demo file you want to train (e.g. 'ATP_3D', 'fish_localbrain', 'NP_3D', ...)
# # pth_demo, _ = download_demo(download_filename=fn_demo)
# # demodata = imread(pth_demo + '/fish_localbrain.tif')

# # the model should not converge (loss should not decrease across epochs) since the source and target are both original noisy images
# # so do not use the loss to guide you in tuning parameters. just inspect the results. 
# # in general the last epoch is the one to use, and if it looks just smoothed, it's underfit (so try more epochs or larger train_dataset_size), and if it looks too sharp/punctate, it's overfit (so try fewer epochs or smaller train_dataset_size)
# # epochs are continuous (not independent), so if training is interrupted, reload the last completed epoch on the .pth file and resume training (deepcad code is not written to do this, requires modification)

# # note train_datasets_size is number of 3d patches to train the model (so can exceed number of frames), and also is slightly different from what actually gets used 
# # while test_datasize during training is number of frames to denoise during optional visualization/saving after each epoch (so I assign it variable name num_frames_to_denoise_for_visualization_during_training)
# # while test_datasize during testing is number of frames to denoise using the model (so I assign it variable name num_frames_to_denoise_during_final_test)
# # and select_img_num is number of frames in each tif file to include in training, counted from the beginning of each stack (tif) (this param is not used in testing, but test_datasize is analogous)

for pth_trainset, pth_testset in zip(pth_trainset_all, pth_testset_all):

      print(pth_trainset)

      n_epochs = 10  # number of training epochs (loss is continuous across patches and epochs - epochs and patches are not independent)
      epoch_choose = n_epochs #which training epoch (which state of the model) to use for testing (denoising), for now just choosing the last epoch (in general this is best, but always inspect for overfit/underfit)
      train_datasets_size = 6000 #how many 3d xyt patches to train on, which is slightly different from what actually gets used 
      select_img_num = 1e10 # number of images to take from the beginning of each stack (make larger than Lt use the full stack)
      patch_x = 110 #int(np.ceil(Lx/4)) #extent of patch in x
      patch_y = 110 #int(np.ceil(Ly/4)) #extent of patch in y
      overlap_factor = 0.9        # the overlap factor between two adjacent patches
      patch_t = 300 #extent of patch in t
      intensity_scale_factor = 1 # the factor for image intensity scaling
      num_frames_to_denoise_for_visualization_during_training = 400 #for the optional inference visualization if save_test_images_per_epoch or visualize_images_per_epoch is True, and the code defaults to taking this number after the first 50 frames for display/save  
      num_frames_to_denoise_during_final_test = Lt #this is number of frames of each tif to be tested (denoised); just make this the length of the stack (or greater) to get the whole stack denoised 
      GPU = '0'                   # the index of GPU you will use (e.g. '0', '0,1', '0,1,2')
      num_workers = 0             # if you use Windows system, set this to 0.
      save_test_images_per_epoch = True  # whether to save result images after each epoch

      train_dict = {
          # dataset dependent parameters
          'patch_x': patch_x,                          # the width of 3D patches
          'patch_y': patch_y,                          # the height of 3D patches
          'patch_t': patch_t,                          # the time dimension (frames) of 3D patches
          'overlap_factor': overlap_factor,             # the factor for image intensity scaling
          'scale_factor': intensity_scale_factor,      # the factor for image intensity scaling
          'select_img_num': select_img_num, # number of images to take from the beginning of each stack (make larger than Lt use the full stack)
          'train_datasets_size': train_datasets_size,  # datasets size for training (how many 3D patches)
          'test_datasize': num_frames_to_denoise_for_visualization_during_training,    
          'datasets_path': pth_trainset,             # folder containing files for training
          'pth_dir': pth_trainset,                   # the path for pth file (saved models) and optional test images saved after each epoch if save_test_images_per_epoch=True

          # network related parameters
          'n_epochs': n_epochs,                          # the number of training epochs
          'lr': 0.00005,                                 # learning rate
          'b1': 0.5,                                     # Adam: beta1
          'b2': 0.9, #0.999                                   # Adam: beta2
          'fmap': 16,  # model complexity, 16 by default, deepcad author says it should not require adjustment 
          'GPU': GPU,                                    # GPU index
          'num_workers': num_workers,                    # if you use Windows system, set this to 0.
          'visualize_images_per_epoch': False,                       # whether to show result images after each epoch
          'save_test_images_per_epoch': save_test_images_per_epoch,  # whether to save result images after each epoch
          'colab_display': True #if colab_display is true and save_test_images_per_epoch is false, it will error between training and testing
      }

      tc = training_class(train_dict)
      tc.run()


############################################# TEST (DENOISE) RECORDINGS WITH CHOSEN MODEL ########################## 

      # this will default to denoising all tifs in datasets_path with all models (.pth files) in folder denoise_model
      # and will output denoised versions of those tifs and save in output_dir

      # but, to override default behavior, here i move all pth files except the chosen one to avoid testing on all pth files 
      pth_para = natsorted(glob.glob(pth_testset + '/' + '*.yaml'))[-1] #path to yaml file (parameters used for training, to be loaded and reused for testing . . . take most recent (the current run because of datetime in name)
      pth_pth = natsorted(glob.glob(pth_testset + '/' + '*.pth')) #path to yaml file (parameters used for training, to be loaded and reused for testing . . . take most recent (the current run because of datetime in name)
      pth_fldr_pth = '/'.join(pth_pth[0].split('/')[:-1]) #folder with all the trained models (.pth files, one for each epoch), and (optionally) test tifs for each epoch
      fldr_pth = pth_fldr_pth.split('/')[-1] #folder with all the trained models (.pth files, one for each epoch), and (optionally) test tifs for each epoch
      pth_pth_keep_pattern = 'E_' + "{:02d}".format(epoch_choose) + '_*.pth'

      for ppi in pth_pth: #move all pth files besides the one you want to test with 
        fn_pth = ppi.split('/')[-1]
        if not fnmatch.fnmatch(fn_pth, pth_pth_keep_pattern):
          fldr_extra_pth = pth_fldr_pth + '/' + 'unused_pth_files/'
          if not os.path.exists(fldr_extra_pth):
            os.mkdir(fldr_extra_pth)
          shutil.move(ppi, fldr_extra_pth)


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
          'test_datasize': num_frames_to_denoise_during_final_test,     # the number of frames in each tif to be denoised/tested, measured from start
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

################################## COPY DENOISING MODEL OUTPUT TO DIFFERENT DIRECTORY ########################## 
      
      fldr_outtiff = natsorted(glob.glob(os.path.join(pth_trainset, 'DataFolderIs_*', 'E_*')))[0] 
      pth_outtiff_all = natsorted(glob.glob(os.path.join(fldr_outtiff, '*output.tif')))

      fldr_destination = pth_denoised + '/' +  fn_prefix 
      if not os.path.exists(fldr_destination): #don't make this "else" connected to "if" above because you have to evaluate it  
        os.mkdir(fldr_destination)

      for pth_outtiff in pth_outtiff_all: #copy all output tiffs (3d data) to a new folder, later to be reassembled into a 4d volume in stitch_denoised_slices

          pth_destination = fldr_destination + '/' + pth_outtiff.split('/')[-1]
          print(pth_destination)
          if os.path.isfile(pth_destination): #if completed file (for single z slice) exist from previous run, delete it
              os.remove(pth_destination)
          shutil.copy(pth_outtiff, fldr_destination + '/')
          #shutil.rmtree(pth_trainset)






