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
    
    pth_datafile_all = []
    fn_prefix_all = []
    pth_prefix_all = []
    pth_tif_reg_tmp_all = []
    pth_tif_reg_tmp2_all = []
    pth_tif_reg_all = []
    pth_tif_dn_all = []
    md_all = []

    countz = -1 #so first one is zero, since recording_index is zero indexed 
    for recording_date in recdates:

        if trial=='*':
            fn_pattern = recording_date + '-' + fly + '_*_trial_*_*.tif'
        else:
            fn_pattern = recording_date + '-' + fly + '_*_trial_' + '{:03d}'.format(int(trial)) + '_*.tif'

        pth_allfiles = natsorted(glob.glob(pth_allrec + '/**/' + fn_pattern, recursive=True))

        for pth_datafile in pth_allfiles:

            pth_fldr = ('/').join(pth_datafile.split('/')[:-1])
            f = pth_datafile.split('/')[-1]

            if 1: #FILTER FOR PABLO pth_fldr.split('_')[-1]=='dark' or pth_fldr.split('_')[-1]=='cl':
                
                countz = countz + 1

                if recording_index == 'all' or (recording_index !='all' and countz==recording_index): #if 'all', do all files matching pattern, otherwise only file matching index

                    print(pth_datafile)

                    fn_prefix = f.split('_')[0].split('-')[0] + '_' + f.split('_')[0].split('-')[1]  + '_' + str(int(f.split('_')[-2][-1])) #change hyphen to underscore
                    
                    pth_prefix = pth_fldr + '/' + fn_prefix
                    if do_background_subtraction or (use_background_subtracted and not do_register):
                        pth_tif_dn = pth_prefix + '_cmrg_bksb_dcdn_.tif'        
                        pth_tif_reg_tmp = pth_prefix + '_cmrg_bksb_tmp_.tif'
                        pth_tif_reg_tmp2 = pth_prefix + '_cmrg_bksb_tmp2_.tif'
                        pth_tif_reg = pth_prefix + '_cmrg_bksb_.tif'
                    else:
                        pth_tif_dn = pth_prefix + '_cmrg_dcdn_.tif'         
                        pth_tif_reg_tmp = pth_prefix + '_cmrg_tmp_.tif'
                        pth_tif_reg_tmp2 = pth_prefix + '_cmrg_tmp2_.tif'
                        pth_tif_reg = pth_prefix + '_cmrg_.tif'
                    
                    pth_md = pth_prefix + '_metadatanew_.mat'
                    pth_md_npy = pth_md[:-4] + '.npy'
                    
                    if os.path.isfile(pth_md_npy):
                        md = np.load(pth_md_npy, allow_pickle='TRUE').item()
                    else:
                        md = read_save_metadata(pth_datafile, pth_md, pth_md_npy, mat_file_shape = None)
                    
                    pth_datafile_all.append(pth_datafile)
                    fn_prefix_all.append(fn_prefix)
                    pth_prefix_all.append(pth_prefix)
                    pth_tif_reg_tmp_all.append(pth_tif_reg_tmp)
                    pth_tif_reg_tmp2_all.append(pth_tif_reg_tmp2)
                    pth_tif_reg_all.append(pth_tif_reg)
                    pth_tif_dn_all.append(pth_tif_dn)
                    md_all.append(md)

    return (pth_datafile_all, fn_prefix_all, pth_prefix_all, pth_tif_reg_tmp_all, 
            pth_tif_reg_tmp2_all, pth_tif_reg_all, pth_tif_dn_all, md_all) 
