


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

do_volume = 1 #DENOISE ALL Z SLICES TOGETHER (BETTER IF YOU DON'T HAVE MANY FRAMES)

if pth_in.endswith( '.mat'):

    mat = mat73.loadmat(pth_in)
    Y = mat['stackRaw_mc']
    Y = np.moveaxis(Y, [0, 2], [2, 0]) #put in order t y x
    Y = Y[..., np.newaxis]

else:

    Y = imread(pth_in).astype('float32')
    Y = Y.reshape(dims)
    Y = np.transpose(Y, (0, 2, 3, 1)) #put in order t y x z (not t x y z)

    size_pre_denoise = Y.shape

    fn_existing_denoised_slices = natsorted(glob.glob(pth_denoised + '/' + fn_prefix + '*output.tif'))
    if 0:#fn_existing_denoised_slices:
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
    #manual_max_dataset_size = 6000
    #train_datasets_size = np.max([manual_max_dataset_size, int(np.ceil(Lt/4))])  # datasets size for training (how many 3D patches)
    train_datasets_size = int(np.ceil(Lt*.8))  # datasets size for training (how many 3D patches)
    train_datasets_size = 40000
    patch_x = int(np.ceil(Lx/4)) #
    patch_y = int(np.ceil(Ly/4)) #
    patch_t = 300  
    
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

    # tmpdate = datetime.datetime.now().strftime("%Y%m%dT%H%M%S")
    # sys.stdout = open(pth_denoising + '/' + dnfolder + '_' + tmpdate + '_stderrout.txt', 'w')
    # sys.stderr = sys.stdout

    pth_trainset_all[countz] = os.path.join(pth_denoising, dnfolder)
    pth_testset_all[countz] = os.path.join(pth_trainset_all[countz], dnfolder + '_*')
    if os.path.exists(pth_trainset_all[countz]):
        shutil.rmtree(pth_trainset_all[countz]) #just remove it because for some reason existing timestamped folders deepcad creates can cause error
    os.mkdir(pth_trainset_all[countz])
    pth_tif_pdn = os.path.join(pth_trainset_all[countz], tifname)
    print(pth_tif_pdn)
    imwrite(pth_tif_pdn, Ynew.astype('float32'), photometric='minisblack' ) #put the tif in the folder deepcad looks to for training data


for pth_trainset, pth_testset in zip(pth_trainset_all, pth_testset_all):
    
    print(pth_trainset)

    n_epochs = 10                # number of training epochs
    GPU = '0'                   # the index of GPU you will use (e.g. '0', '0,1', '0,1,2')
    overlap_factor = 0.4        # the overlap factor between two adjacent patches
    intensity_scale_factor = 1 # the factor for image intensity scaling
    num_workers = 0             # if you use Windows system, set this to 0.

    # Setup some parameters for result visualization during training period (optional)
    save_test_images_per_epoch = True  # whether to save result images after each epoch

    train_dict = {
        # dataset dependent parameters
        'patch_x': patch_x,                          # the width of 3D patches
        'patch_y': patch_y,                          # the height of 3D patches
        'patch_t': patch_t,                          # the time dimension (frames) of 3D patches
        'overlap_factor':overlap_factor,             # the factor for image intensity scaling
        'scale_factor': intensity_scale_factor,      # the factor for image intensity scaling
        'select_img_num': train_datasets_size,       # select the number of images used for training
        'train_datasets_size': train_datasets_size,  # datasets size for training (how many 3D patches)
        'datasets_path': pth_trainset,             # folder containing files for training
        'pth_dir': pth_trainset,                   # the path for pth file and result images

        # network related parameters
        'n_epochs': n_epochs,                          # the number of training epochs
        'lr': 0.00005,                                 # learning rate
        'b1': 0.5,                                     # Adam: beta1
        'b2': 0.9, #0.999                                   # Adam: beta2
        'fmap': 8,  # was 16 by default                # model complexity
        'GPU': GPU,                                    # GPU index
        'num_workers': num_workers,                    # if you use Windows system, set this to 0.
        'visualize_images_per_epoch': False,                       # whether to show result images after each epoch
        'save_test_images_per_epoch': save_test_images_per_epoch,  # whether to save result images after each epoch
        'colab_display': True
    }

    tc = training_class(train_dict)
    tc.run()

    test_datasize = Lt
    para_path_tmp = glob.glob(os.path.join(pth_testset, '*.yaml'))[0]
    denoise_model = para_path_tmp.split('/')[-2]
    para_path = glob.glob(os.path.join(pth_trainset, denoise_model, '*.yaml'))[0]

    import yaml

    with open(para_path, "r") as stream:
        #para_dict = yaml.safe_load(stream)
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
        'scale_factor': intensity_scale_factor,                  # the factor for image intensity scaling
        'test_datasize': test_datasize,     # the number of frames to be tested
        'datasets_path': pth_trainset,     # folder containing all files to be tested
        'pth_dir': pth_trainset,                 # pth file root path
        'denoise_model' : denoise_model,    # A folder containing all models to be tested
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


    outtiff_path = natsorted(glob.glob(os.path.join(pth_trainset, 'DataFolderIs_*', 'E_*', '*output.tif')))
    outtiff_path = outtiff_path[-1] #for now just take the last one 
    pth_destination = pth_denoised + '/' + outtiff_path.split('/')[-1]
    if os.path.isfile(pth_destination): #if completed file (for single z slice) exist from previous run, delete it (full denoised 4d recording is reassembled in pth_out)
        os.remove(pth_destination)
    shutil.copy(outtiff_path, pth_denoised)
    #shutil.rmtree(pth_trainset)


    if tc.colab_display and re.search('/content', env_path[0]):
        display_filename = tc.result_display
        print('\033[1;31mDisplaying denoised file of the last epoch-----> \033[0m')
        print(pth_destination)
        # normalize the image and display
        img = display_img(pth_destination,norm_min_percent=1, norm_max_percent=99)
        plt.imshow(img,cmap=plt.cm.gray,vmin=0,vmax=255)
        plt.axis('off')
        plt.show()

