


##########################################################################################################################################
# this script operates on individual input files 
# using deepcad to denoise 

# typically I call this script from pipeline.py, but it can be run on its own from the command line  

# deepcad wants 3d data, and rather than reshaping the 4d array into 3d (denoising on all z slices at once), this script
# operates on each z slice independently, since noise varies with z 

# deepcad creates intermediate files that are saved in pth_denoising
# each z slice of 4d volumetric input movie is passed to deepcad, saved separately in pth_denoised, 
# outside this script, the separate denoised z slices are reassmbled as single output file pth_out, which is placed in same folder as input file pth_in 


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
pth_out = '/Users/wienecke/Documents/ambrose/stacks/20230624-2_D05_syt7f_018_syt7f/20230624_2_1_cmrg_dcdn_.tif' #output file
pth_denoising = '/Users/wienecke/Documents/ambrose/denoising' #path for intermediate files created by deepcad
pth_denoised = '/Users/wienecke/Documents/ambrose/denoised' #path for finished (denoised) 3d files, prior to reassembling 
fn_prefix = '20230624_2_1' #filename prefix (date_fly_trial)
dims = [3047, 15, 140, 256] # input motion dimensions (and output movie dimensions)
denoise_slice_index = [0]

[pth_in, pth_out, pth_denoising, pth_denoised, fn_prefix, dims, denoise_slice_index] = parse_command_line_denoise(pth_in = pth_in, pth_out = pth_out, 
                    pth_denoising = pth_denoising, pth_denoised = pth_denoised, 
                    fn_prefix = fn_prefix, dims = dims, denoise_slice_index = denoise_slice_index)

print(pth_in)
print(pth_out)
print(pth_denoising)
print(pth_denoised)
print(fn_prefix)
print(dims)
print(denoise_slice_index)

env_path = sys.path

denoise_slice_index = 'all' #override input set to 'all' for now
do_volume = 1 #DENOISE ALL Z SLICES TOGETHER (BETTER IF YOU DON'T HAVE MANY FRAMES)

Y = imread(pth_in).astype('float32')
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

pth_trainset_all = ['']*len(zind_all_dn)
pth_testset_all = ['']*len(zind_all_dn)
countz = -1
for zii in zind_all_dn: #organize slices into separate tifs, in one folder (train on all slices) or separate (train on z subset)

    Ynew = Y[:,:,:,zii]
    Lt, Ly, Lx = Ynew.shape #don't need to index these they should be the same
    if countz>-1 and prev_shape != Ynew.shape:
      raise Exception("dims changed")
    prev_shape = Ynew.shape
    print(Lt)
    print(Ly)
    print(Lx)

    if do_volume:
      dnfolder_insert = 'all'
      countz = 0
      pth_trainset_all = ['']
      pth_testset_all = ['']
    else:
      dnfolder_insert = str(zii)
      countz = countz + 1

    dnfolder = fn_prefix + '_' + dnfolder_insert
    tifname = fn_prefix + '_' + str(zii) + '_.tif'

    pth_trainset_all[countz] = os.path.join(pth_denoising, dnfolder)
    if (zii==0 and os.path.exists(pth_trainset_all[countz])) or (do_volume==0 and os.path.exists(pth_trainset_all[countz])):
      shutil.rmtree(pth_trainset_all[countz]) #just remove it because for some reason existing timestamped folders deepcad creates can cause error
    if not os.path.exists(pth_trainset_all[countz]):
      os.mkdir(pth_trainset_all[countz])
    pth_testset_all[countz] = os.path.join(pth_trainset_all[countz], dnfolder + '_*')
    pth_tif_pdn = os.path.join(pth_trainset_all[countz], tifname)
    print(pth_tif_pdn)
    imwrite(pth_tif_pdn, Ynew.astype('float32'), photometric='minisblack' ) #put the tif in the folder deepcad looks to for training data





########################## TRAIN ########################## 

# train_datasets_size is how many 3d xyt patches to train on
# overlap factor applies to patch x and y, but not patch t
# patch t spacing is based on how many xy patches there are in each frame, and train_datasets_size
# the maximum possible train_datasets_size for a given xy patch number (ie how to obtain patch_t spacing of 1 frame)
# is roughly the number of frames in each stack minus double the patch_t size (double since the algorithm takes interleaved frames as input/output) 
# times number of stacks, times the number of xy patches in each frame 
# for example, for a 4d recording whose tzyx shape is (3047,15,140,256)
# if there are 36 xy patches per frame (determined by patch_x and patch_y and overlap factor), and patch_t is 300
# the maximum train_datasets_size is (3047 - (300*2)) * 15 * 36 (which will give patch_t spacing of 1 frame)
# of course this is not optimal,
# above this number causes errors because it calls for t patch spacing of zero 
# deepcad's demo "best model" for int16 stack shape (6955,492,492) is train_datasets_size = 6000, n_epochs = 20, patch_x,y,t = 150, overlap_factor = 0.4 
# here is their demo data:
# fn_demo ='fish_localbrain' # select the demo file you want to train (e.g. 'ATP_3D', 'fish_localbrain', 'NP_3D', ...)
# pth_demo, _ = download_demo(download_filename=fn_demo)
# demodata = imread(pth_demo + '/fish_localbrain.tif')



for pth_trainset, pth_testset in zip(pth_trainset_all, pth_testset_all):

      print(pth_trainset)

      n_epochs = 20                # number of training epochs (loss is cumulative across all patches and epochs)
      train_datasets_size = 40000 #how many 3d xyt patches to train on
      select_img_num = 1e10 # number of images to take from the beginning of each stack (make larger than Lt use the full stack)
      patch_x = int(np.ceil(Lx/4)) #extent of patch in x
      patch_y = int(np.ceil(Ly/4)) #extent of patch in y
      overlap_factor = 0.4        # the overlap factor between two adjacent patches
      patch_t = 300 #extent of patch in t
      intensity_scale_factor = 1 # the factor for image intensity scaling
      test_datasize = 400 #for the optional inference visualization if save_test_images_per_epoch or visualize_images_per_epoch is True, and the code defaults to taking this number after the first 50 frames for display/save  
      GPU = '0'                   # the index of GPU you will use (e.g. '0', '0,1', '0,1,2')
      num_workers = 0             # if you use Windows system, set this to 0.
      save_test_images_per_epoch = True  # whether to save result images after each epoch

      train_dict = {
          # dataset dependent parameters
          'patch_x': patch_x,                          # the width of 3D patches
          'patch_y': patch_y,                          # the height of 3D patches
          'patch_t': patch_t,                          # the time dimension (frames) of 3D patches
          'overlap_factor':overlap_factor,             # the factor for image intensity scaling
          'scale_factor': intensity_scale_factor,      # the factor for image intensity scaling
          'select_img_num': select_img_num, # number of images to take from the beginning of each stack (make larger than Lt use the full stack)
          'train_datasets_size': train_datasets_size,  # datasets size for training (how many 3D patches)
          'test_datasize': test_datasize,    
          'datasets_path': pth_trainset,             # folder containing files for training
          'pth_dir': pth_trainset,                   # the path for pth file and result images

          # network related parameters
          'n_epochs': n_epochs,                          # the number of training epochs
          'lr': 0.00005,                                 # learning rate
          'b1': 0.5,                                     # Adam: beta1
          'b2': 0.9, #0.999                                   # Adam: beta2
          'fmap': 16,  # was 16 by default                # model complexity
          'GPU': GPU,                                    # GPU index
          'num_workers': num_workers,                    # if you use Windows system, set this to 0.
          'visualize_images_per_epoch': False,                       # whether to show result images after each epoch
          'save_test_images_per_epoch': save_test_images_per_epoch,  # whether to save result images after each epoch
          'colab_display': True
      }

      tc = training_class(train_dict)
      tc.run()


      ########################## TEST ########################## 

      #this will default to denoising all stacks with all models saved after each epoch (so 100 denoised stacks w suffix output.tif for 10 stacks 10 models)

        
      test_datasize = Lt #for "testing" phase, make this the length of the stack to get the whole stack denoised 
      folder_models = glob.glob(os.path.join(pth_testset, '*.yaml'))[0].split('/')[-2] #folder with all the trained models (one for each epoch)
      pth_para = glob.glob(os.path.join(pth_trainset, folder_models, '*.yaml'))[0] #path to the para file with handful of hyperparams set above for training

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
          'test_datasize': test_datasize,     # the number of frames to be tested
          'datasets_path': pth_trainset,     # folder containing all files to be tested
          'pth_dir': pth_trainset,                 # pth file root path
          'denoise_model' : folder_models,    # A folder containing all models to be tested
          'output_dir' : pth_trainset,         # result file root path
          # network related parameters
          'fmap': fmap,                         # number of feature maps
          'GPU': GPU,                         # GPU index
          'num_workers': num_workers,         # if you use Windows system, set this to 0.
          'visualize_images_per_epoch': False, # whether to display inference performance after each epoch
          'save_test_images_per_epoch': save_test_images_per_epoch, # whether to save inference image after each epoch in pth path
          'colab_display': True
      }

      tc = testing_class(test_dict)
      tc.run()


        ########################## CHOOSE DENOISING MODEL OUTPUT AND MOVE ########################## 

      epoch_choose = n_epochs #just choosing the last one for now (not optimal necessarily, will fix this soon)
      
      outtiff_fldr = natsorted(glob.glob(os.path.join(pth_trainset, 'DataFolderIs_*', 'E_*')))[epoch_choose-1]
      pth_outtiff_all = natsorted(glob.glob(os.path.join(outtiff_fldr, '*output.tif')))

      for pth_outtiff in pth_outtiff_all:

          pth_destination = pth_denoised + '/' + pth_outtiff.split('/')[-1]
          print(pth_destination)
          if os.path.isfile(pth_destination): #if completed file (for single z slice) exist from previous run, delete it (full denoised 4d recording is reassembled in pth_out)
              os.remove(pth_destination)
          shutil.copy(pth_outtiff, pth_denoised)
          #shutil.rmtree(pth_trainset)



