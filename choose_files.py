import fnmatch
import os
import glob
import mat73
import numpy as np
from read_save_metadata import read_save_metadata
from tifffile.tifffile import imwrite
from natsort import natsorted
import re

def choose_files(pth_allrec, recdates, fly, trial, folder_substrings, recording_index, do_background_subtraction, 
                 do_register, do_denoise, do_extract, do_cropping_session, do_stitching_session, 
                 use_background_subtracted, use_denoised, rename_raw_tif):
    
    pth_datafile_all = []
    pth_fldr_all = []
    fn_prefix_all = []
    pth_prefix_all = []
    pth_tif_reg_all = []
    pth_tif_dn_all = []
    md_all = []
    carls_old_project_all = []

    countz = -1 #so first one is zero, since recording_index is zero indexed 
    for recording_date in recdates:

        if do_register:
            fn_suffix = '_raw'
        if do_denoise or do_stitching_session or do_extract or do_cropping_session:
            fn_suffix = '_cmrg'
            if use_background_subtracted:
                fn_suffix = fn_suffix + '_bksb'
            if use_denoised and not do_denoise:
                fn_suffix = fn_suffix + '_dcdn'

        fn_pattern = recording_date + '_' + fly + '_' + trial + fn_suffix + '_.tif'
        pth_allfiles = natsorted(glob.glob(pth_allrec + '**/' + fn_pattern, recursive=True))
        flyg_filename_pattern = 0
        if not pth_allfiles and do_register:  #if no matches for 'raw' try original flyg output file pattern
            flyg_filename_pattern = 1
            if trial=='*':
                fn_pattern = recording_date + '-' + fly + '_*_trial_*_*.tif'
            else:
                fn_pattern = recording_date + '-' + fly + '_*_trial_' + '{:03d}'.format(int(trial)) + '_*.tif'  
            pth_allfiles = natsorted(glob.glob(pth_allrec + '**/' + fn_pattern, recursive=True))
            if not pth_allfiles:
                print("FOR JOB SUBMITTED, NO FILES MATCHING INPUT PATTERN")

        for pth_datafile in pth_allfiles:

            pth_fldr = ('/').join(pth_datafile.split('/')[:-1])
            f = pth_datafile.split('/')[-1]

            if rename_raw_tif and (re.search("caw846", pth_allrec) or re.search("wienecke", pth_allrec)):
                if re.search(recording_date + '-' + fly, pth_datafile) or re.search('stackraw', pth_datafile):
                    trialspec = str(int(pth_datafile.split('_')[-2]))
                    pth_datafile_rename = pth_fldr + '/' + recording_date + '_' + fly + '_' + trialspec + '_raw_.tif'
                    os.rename(pth_datafile, pth_datafile_rename)
                    pth_badmat = glob.glob(pth_datafile[:-4] + '.mat', recursive=True)
                    if pth_badmat:
                        os.remove(pth_badmat[0])
                    pth_datafile = pth_datafile_rename


            if not re.search("par26", pth_allrec) or (re.search("par26", pth_allrec) and (pth_fldr.split('_')[-1]=='dark' or pth_fldr.split('_')[-1]=='cl')): #folder filter for pablo
                
                countz = countz + 1

                if recording_index == 'all' or (recording_index !='all' and np.isin(countz, recording_index).any()): #if 'all', do all files matching pattern, otherwise only file matching index

                    print(pth_datafile)

                    if flyg_filename_pattern:                       
                        fn_prefix = f.split('_')[0].split('-')[0] + '_' + f.split('_')[0].split('-')[1]  + '_' + str(int(f.split('_')[-2][-1])) #change hyphen to underscore
                    else:
                        fn_prefix = '_'.join(f.split('_')[:3])

                    pth_prefix = pth_fldr + '/' + fn_prefix
                    if do_background_subtraction or (use_background_subtracted and not do_register):
                        pth_tif_reg = pth_prefix + '_cmrg_bksb_.tif'
                        pth_tif_dn = pth_prefix + '_cmrg_bksb_dcdn_.tif'        
                    else:
                        pth_tif_reg = pth_prefix + '_cmrg_.tif'
                        pth_tif_dn = pth_prefix + '_cmrg_dcdn_.tif'         
                    
                    pth_md_mat = pth_prefix + '_metadatanew_.mat'
                    pth_md_npy = pth_md_mat[:-4] + '.npy'
                    
                    if int(fn_prefix.split('_')[0])<20230101:
                        carls_old_project = 1
                    else:
                        carls_old_project = 0

                    if carls_old_project: #for my old project 


                        pth_datafile_new = pth_datafile[:-4] + '.tif'

                        if os.path.isfile(pth_md_npy) and os.path.isfile(pth_md_mat) and os.path.isfile(pth_datafile_new): #
                            md = np.load(pth_md_npy, allow_pickle='TRUE').item() 
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
                            md = read_save_metadata(pth_datafile, pth_md_mat, pth_md_npy, mat_file_shape = Y.shape)

                    else:
                        
                        if os.path.isfile(pth_md_npy) and os.path.isfile(pth_md_mat):
                            md = np.load(pth_md_npy, allow_pickle='TRUE').item()
                        else:
                            md = read_save_metadata(pth_datafile, pth_md_mat, pth_md_npy, mat_file_shape = None)
                        
                    pth_datafile_all.append(pth_datafile)
                    pth_fldr_all.append(pth_fldr)
                    fn_prefix_all.append(fn_prefix)
                    pth_prefix_all.append(pth_prefix)
                    pth_tif_reg_all.append(pth_tif_reg)
                    pth_tif_dn_all.append(pth_tif_dn)
                    md_all.append(md)
                    carls_old_project_all.append(carls_old_project)

    return (pth_datafile_all, pth_fldr_all, fn_prefix_all, pth_prefix_all, pth_tif_reg_all, pth_tif_dn_all, md_all, carls_old_project_all) 
