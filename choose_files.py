import fnmatch
import os
import glob
import mat73
import numpy as np
from read_save_metadata import read_save_metadata
from tifffile.tifffile import imwrite
from natsort import natsorted


def choose_files(recdates, pth_allrec, fly, trial, recording_index, do_background_subtraction, 
                 use_background_subtracted, do_register):
    
    countz = -1 #so first one is zero, since recording_index is zero indexed 
    for recording_date in recdates:

        pth_fldrs_pattern = pth_allrec + recording_date + '-' + fly + '_*/'
        fn_pattern = recording_date + '-' + fly + '*_trial_00' + trial + '_*.tif'
        pth_fldrs = natsorted(glob.glob(pth_fldrs_pattern))
        old_mat_files = 0
        if not pth_fldrs:  #if no matches try another filename pattern (files from previous project)
            old_mat_files = 1
            pth_fldrs_pattern = pth_allrec + recording_date + '_' + fly + '_*/'
            fn_pattern = recording_date + '_' + fly + '_' + trial + '_stackraw_.mat'
            pth_fldrs = natsorted(glob.glob(pth_fldrs_pattern))

        for pth_fldr in pth_fldrs:

            print(pth_fldr)
            
            pth_allfiles = natsorted(os.listdir(pth_fldr))

            for f in pth_allfiles:

                if fnmatch.fnmatch(f, fn_pattern):
                    
                    countz = countz + 1

                    if recording_index == 'all' or (recording_index !='all' and countz==recording_index): #if 'all', do all files matching pattern, otherwise only file matching index

                        pth_datafile = pth_fldr + f
                        print(pth_datafile)

                        if old_mat_files:
                            fn_prefix = '_'.join(f.split('_')[:3])
                        else:
                            fn_prefix = f.split('_')[0].split('-')[0] + '_' + f.split('_')[0].split('-')[1]  + '_' + f.split('_')[-2][-1] #change hyphen to underscore
                        
                        pth_prefix = pth_fldr + fn_prefix
                        if do_background_subtraction or (use_background_subtracted and not do_register):
                            pth_tif_dn = pth_prefix + '_cmrg_bksb_dcdn_.tif'        
                            pth_tif_reg_tmp = pth_prefix + '_cmrg_bksb_tmp_.tif'
                            pth_tif_reg = pth_prefix + '_cmrg_bksb_.tif'
                        else:
                            pth_tif_dn = pth_prefix + '_cmrg_dcdn_.tif'         
                            pth_tif_reg_tmp = pth_prefix + '_cmrg_tmp_.tif'
                            pth_tif_reg = pth_prefix + '_cmrg_.tif'
                        
                        pth_md = pth_prefix + '_metadatanew_.mat'
                        pth_md_npy = pth_md[:-4] + '.npy'

                        if old_mat_files: #for my old project 

                            pth_datafile_new = pth_datafile[:-4] + '.tif'

                            if os.path.isfile(pth_md_npy) and os.path.isfile(pth_datafile_new): #
                                md = np.load(pth_md_npy, allow_pickle='TRUE').item() #if it exists, the md file will too 
                                pth_datafile = pth_datafile_new
                            else:
                                mat = mat73.loadmat(pth_datafile)
                                Y = mat['stackRaw_pmc'] # Y = mat['stackRaw_mc']
                                mnmv = np.min(Y)
                                Y = Y - mnmv #make movie nonnegative (not sure this is necessary)
                                print("MIN OF STACKRAW_PMC MAT FILE " + str(mnmv))
                                Y = np.transpose(Y, (2, 0, 1)) #put in order t y x (not t x y) #stackraw_mc may be flipped relative to stackraw pmc
                                pth_datafile = pth_datafile_new
                                imwrite(pth_datafile, Y.astype('uint16')) #write as t x y z (singleton z at end)
                                md = read_save_metadata(pth_datafile, pth_md, pth_md_npy, mat_file_shape = Y.shape)

                        else:
                            
                            fn_prefix = f.split('_')[0].split('-')[0] + '_' + f.split('_')[0].split('-')[1]  + '_' + f.split('_')[-2][-1] #change hyphen to underscore
                            if os.path.isfile(pth_md_npy):
                                md = np.load(pth_md_npy, allow_pickle='TRUE').item()
                            else:
                                md = read_save_metadata(pth_datafile, pth_md, pth_md_npy, mat_file_shape = None)

    return (pth_datafile, fn_prefix, pth_prefix, pth_tif_reg_tmp, pth_tif_reg, pth_tif_dn, md) 
