


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

import sys
import re
import os
import glob
import shutil

import numpy as np
from skimage import io
from tifffile.tifffile import imwrite, imread

import scipy.io
import matplotlib
import matplotlib.pyplot as plt
import matplotlib as mpl

from deepcad.train_collection import training_class
from deepcad.test_collection import testing_class
from deepcad.movie_display import display, display_img
from deepcad.utils import get_first_filename

import random
from tqdm import tqdm
from scipy import signal
import datetime

env_path = sys.path
if (re.search("/Users/wienecke/", env_path[0])):
    if len(sys.argv)==1:
        pth_tif_reg = ['/Users/wienecke/Documents/ambrose/stacks/20230624-2_D05_syt7f_018_syt7f/20230624_2_1_caimanreg_.tif']
elif (re.search("/home/caw846/", env_path[0])):
    import mat73

def denoise_single_recording(pth_tif_reg, pth_tif_dn, fn_reduced, old_mat_files, dims_spacetime_original_noflyback, datasets_path_processing, datasets_path_complete):

    print("in denoise single")

    # dims_spacetime_original = [3047, 20, 140, 256] #manual
    # flyback = 5
    # dims_spacetime_original_noflyback = [dims_spacetime_original[0], dims_spacetime_original[1]-flyback, dims_spacetime_original[2], dims_spacetime_original[3]]

    # pth_prefix = '/'.join(pth_tif_reg[0].split('/')[:-1])
    # working_dir = '/'.join(pth_prefix.split('/')[:-2])
    # datasets_path_processing = os.path.join(working_dir, 'denoising_in_progress')
    # if not os.path.exists(datasets_path_processing):
    #     os.mkdir(datasets_path_processing)
    # datasets_path_complete = os.path.join(working_dir, 'denoised')
    # if not os.path.exists(datasets_path_complete):
    #     os.mkdir(datasets_path_complete)

    # fn_reduced = '_'.join(pth_tif_reg[0].split('/')[-1].split('_')[:3])
    # pth_tif_dn = '_'.join(pth_tif_reg[0].split('_')[:-2]) + '_cmregcaddn_.tif'

    # if pth_tif_reg[0].endswith( '.mat'):
    #     old_mat_files = 1
    # elif pth_tif_reg[0].endswith( '.tif'):
    #     old_mat_files = 0


    class BgRemover:


        def __init__(self, img_path, half_wid=12):
            self.uppath = '/'.join(img_path.split('/')[:-1])
            self.path = img_path
            self.half_wid = half_wid
            self.img = io.imread(img_path).astype('float32')
            self.make_savedir()

        def make_savedir(self):
            working_dir = os.path.dirname(self.uppath)
            saving_dir = os.path.join(working_dir, 'bg_remove')
            if not os.path.exists(saving_dir):
                os.mkdir(saving_dir)
            self.saving_dir = saving_dir
            self.file_head = self.path.split('.')[0].split('/')[-1]

        def draw_bg(self):
            half_wid = self.half_wid
            wid = 2*half_wid
            kernel = np.ones(wid)/wid
            template = np.mean(self.img, axis=0)
            bg_ind = []
            for line in template:
                tmp = np.convolve(line, kernel, 'valid')
                bg_center = np.argmin(tmp) + half_wid
                bg_ind.append([bg_center-half_wid, bg_center+half_wid])
            self.bg_ind = bg_ind

        def show_bg(self):
            bg_ind = self.bg_ind
            show_bg = np.mean(self.img, axis=0)
            mv = np.max(show_bg)
            for i in range(show_bg.shape[0]):
                show_bg[i, bg_ind[i][0]:bg_ind[i][1]] = mv
            plt.imshow(show_bg)
            plt.savefig(os.path.join(self.saving_dir, self.file_head+'_bg_patch.png'))
            plt.close()

        def remove_bg(self, offset=0):
            bg_ind = self.bg_ind
            out = self.img.copy()
            for ind in range(out.shape[1]):
                patch = self.img[:, ind, :]
                bg_patch = self.img[:, ind, bg_ind[ind][0]:bg_ind[ind][1]]
                bg = bg_patch.mean(axis=-1)
                patch = patch-bg[None].T
                out[:, ind, :] = patch
            out = out + offset # compensate so that most of the pixels are above 0 (no need)
            self.out = out

        def show_spectrum(self, fs=354):
            half_wid = self.half_wid
            y_len, x_len = self.out.shape[1:3]
            test_y = random.randint(0, y_len-1)
            test_x = random.randint(0, x_len-2*half_wid-1) + half_wid

            test_patch = self.img[:, test_y, test_x-half_wid:test_x+half_wid]
            test = test_patch.mean(-1)
            test = test/test.mean()

            f, Pxx_den = signal.periodogram(test, fs)
            plt.semilogy(f, Pxx_den)
            plt.ylim([1e-7, 1])
            plt.savefig(os.path.join(self.saving_dir, self.file_head + '_spectrum_withBG.png'))
            plt.close()

            test_patch = self.out[:, test_y, test_x-half_wid:test_x+half_wid]
            test = test_patch.mean(-1)
            test = test/test.mean()

            f, Pxx_den = signal.periodogram(test, fs)
            plt.semilogy(f, Pxx_den)
            plt.ylim([1e-7, 1])
            plt.savefig(os.path.join(self.saving_dir, self.file_head + '_spectrum_withoutBG.png'))
            plt.close()

        def save_out(self):
            save_name = os.path.join(self.path[:-4] + '.tif')
            io.imsave(save_name, self.out.astype('float'))




    if old_mat_files:

        mat = mat73.loadmat(pth_tif_reg)
        Y = mat['stackRaw_mc']
        Y = np.moveaxis(Y, [0, 2], [2, 0]) #put in order t y x
        Y = Y[..., np.newaxis]

    else:

        Y = imread(pth_tif_reg).astype('float32')  
        Y = Y.reshape(dims_spacetime_original_noflyback)
        Y = np.transpose(Y, (0, 2, 3, 1)) #put in order t y x z (not t x y z)

        size_pre_denoise = Y.shape

        zind_all_dn = np.arange(Y.shape[-1])

    for zii in zind_all_dn: #for each z slice

        Ynew = Y[:,:,:,zii]
        print("denoising slice" + str(zii))
        print(Y.shape)
        print(Ynew.shape)

        dnfolder = fn_reduced + '_' + str(zii)
        tifname = dnfolder + '_.tif'
        tiffolder_path = os.path.join(datasets_path_processing, dnfolder)
        testfolder_path = os.path.join(tiffolder_path, dnfolder + '_*')
        if not os.path.exists(tiffolder_path):
            os.mkdir(tiffolder_path)
        pth_tif_pdn = os.path.join(tiffolder_path, tifname)
        print(pth_tif_pdn)
        imwrite(pth_tif_pdn, Ynew.astype('float'), photometric='minisblack')


        #remove background line by line
        br = BgRemover(pth_tif_pdn, half_wid=12)
        br.draw_bg()
        br.show_bg()
        br.remove_bg()
        br.show_spectrum(fs=180)
        br.save_out()


        stack = io.imread(pth_tif_pdn)
        Lt, Ly, Lx = stack.shape
        print(Lt)
        print(Ly)
        print(Lx)

        n_epochs = 2                # number of training epochs
        GPU = '0'                   # the index of GPU you will use (e.g. '0', '0,1', '0,1,2')
        manual_max_dataset_size = 4000
        train_datasets_size = np.max([manual_max_dataset_size, int(np.ceil(Lt/4))])  # datasets size for training (how many 3D patches)
        patch_x = int(np.ceil(Lx/4)) # was /4   # the width, height, and length of 3D patches (use isotropic patch size by default)
        patch_y = int(np.ceil(Ly/4)) # was /4
        patch_t = 300                #100
        overlap_factor = 0.4        # the overlap factor between two adjacent patches
        num_workers = 0             # if you use Windows system, set this to 0.

        # Setup some parameters for result visualization during training period (optional)
        save_test_images_per_epoch = True  # whether to save result images after each epoch

        train_dict = {
            # dataset dependent parameters
            'patch_x': patch_x,                          # the width of 3D patches
            'patch_y': patch_y,                          # the height of 3D patches
            'patch_t': patch_t,                          # the time dimension (frames) of 3D patches
            'overlap_factor':overlap_factor,             # the factor for image intensity scaling
            'scale_factor': 1,                           # the factor for image intensity scaling
            'select_img_num': train_datasets_size,       # select the number of images used for training (use 2000 frames in colab)
            'train_datasets_size': train_datasets_size,  # datasets size for training (how many 3D patches)
            'datasets_path': tiffolder_path,             # folder containing files for training
            'pth_dir': tiffolder_path,                   # the path for pth file and result images

            # network related parameters
            'n_epochs': n_epochs,                          # the number of training epochs
            'lr': 0.00005,                                 # learning rate
            'b1': 0.5,                                     # Adam: beta1
            'b2': 0.999,                                   # Adam: beta2
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
        para_path_tmp = glob.glob(os.path.join(testfolder_path, '*.yaml'))[0]
        denoise_model = para_path_tmp.split('/')[-2] #datetime.datetime.now().strftime("%Y%m%dT%H%M%S") #'stackraw2_202210240402'
        para_path = glob.glob(os.path.join(tiffolder_path, denoise_model, '*.yaml'))[0]

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
            'scale_factor': 1,                  # the factor for image intensity scaling
            'test_datasize': test_datasize,     # the number of frames to be tested
            'datasets_path': tiffolder_path,     # folder containing all files to be tested
            'pth_dir': tiffolder_path,                 # pth file root path
            'denoise_model' : denoise_model,    # A folder containing all models to be tested
            'output_dir' : tiffolder_path,         # result file root path
            # network related parameters
            'fmap': fmap,                         # number of feature maps
            'GPU': GPU,                         # GPU index
            'num_workers': num_workers,         # if you use Windows system, set this to 0.
            'visualize_images_per_epoch': False,# whether to display inference performance after each epoch
            'save_test_images_per_epoch': True, # whether to save inference image after each epoch in pth path
            'colab_display': True
        }

        tc = testing_class(test_dict)
        tc.run()

        if tc.colab_display:
            display_filename = tc.result_display
            print('\033[1;31mDisplaying denoised file of the last epoch-----> \033[0m')
            print(display_filename)
            # normalize the image and display
            img = display_img(display_filename,norm_min_percent=1, norm_max_percent=99)
            plt.imshow(img,cmap=plt.cm.gray,vmin=0,vmax=255)
            plt.axis('off')
            plt.show()

        outtiff_path = glob.glob(os.path.join(tiffolder_path, 'DataFolderIs_*', 'E_02_*', '*output.tif'))[0]
        shutil.move(outtiff_path, datasets_path_complete)
        shutil.rmtree(tiffolder_path)
        shutil.rmtree('/'.join(tiffolder_path.split('/')[:-1]) + '/bg_remove')



    Y = np.zeros(size_pre_denoise)
    pth_denoised_singles = glob.glob(datasets_path_complete + '/' + fn_reduced + '*')
    countz = 0
    for f in pth_denoised_singles: #for each z slice
        print(countz)
        Ynew = imread(f)
        print(Ynew.dtype)
        Y[:,:,:,countz] = Ynew
        countz+=1

    min_mov_after_dn = int(np.min(Y))
    Y = Y - min_mov_after_dn #make movie nonnegative (not sure this is necessary)
    print("MIN AFTER MOTION CORRECTION " + str(min_mov_after_dn))
    Y = Y.astype('uint16')
    Y = np.transpose(Y, (0, 3, 1, 2))
    Y = Y.reshape(size_pre_denoise[0] * size_pre_denoise[3], size_pre_denoise[1], size_pre_denoise[2])
    imwrite(pth_tif_dn[0], Y) #write the registered movie as tif for use in matlab, and caiman extraction below