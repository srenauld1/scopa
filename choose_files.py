import fnmatch
import os
import glob
import mat73
import numpy as np
from read_save_metadata import read_save_metadata
from tifffile.tifffile import imwrite
from natsort import natsorted
import re
from itertools import product
import collections


def choose_files(pth_allrec, recdates, fly, trial, folder_substrings, recording_index, file_matching_style, 
                 do_register, do_denoise, do_extract, do_cropping_session, do_stitching_session, 
                 use_background_subtracted, use_denoised):
    

    if file_matching_style=='any': #find all possible combinations 
        filepatspec_all = list(product(recdates, fly, trial, folder_substrings)) 
    elif file_matching_style=='each': #else corresponding elements 
        maxspec = np.max((len(recdates), len(fly), len(trial), len(folder_substrings)))
        if len(recdates)==1:
            recdates = recdates*maxspec
        if len(fly)==1:
            fly = fly*maxspec
        if len(trial)==1:
            trial = trial*maxspec
        if len(folder_substrings)==1:
            folder_substrings = folder_substrings*maxspec
        if not(len(recdates) == len(fly) == len(trial) == len(folder_substrings)):
            raise Exception("recdate, fly, trial, and folder_substrings must all be same length or length 1 for file_matching_style 'each'")
        filepatspec_all = [(w, x, y, z) for w, x, y, z in zip(recdates, fly, trial, folder_substrings)] 

    pth_allrec
    filepatspec_all
    pth_allfiles = []
    for filepatspec in filepatspec_all: #loop over all file pattern combos 

        fn_suffix = '_raw' #find files matching scopa output pattern
        if do_denoise or do_stitching_session or do_extract or do_cropping_session:
            fn_suffix = '_cmrg'
            if use_background_subtracted:
                fn_suffix = fn_suffix + '_bksb'
            if use_denoised and not do_denoise:
                fn_suffix = fn_suffix + '_dcdn'
        fn_suffix = fn_suffix + '_.tif'
        fn_pattern = filepatspec[0] + '_' + filepatspec[1] + '_' + filepatspec[2] + fn_suffix
        pth_allfiles_scopa = glob.glob(pth_allrec + '**/*' + filepatspec[3] + '*/' + fn_pattern, recursive=True)
        pth_allfiles = pth_allfiles + pth_allfiles_scopa #combine, since both patterns are valid as input

        if do_register: #find files matching flyg default output pattern (if do_register), and carl's old project output pattern
            
            if filepatspec[2]=='*':
                fn_pattern = filepatspec[0] + '-' + filepatspec[1] + '_*_trial_*_*.tif'
            else:
                fn_pattern = filepatspec[0] + '-' + filepatspec[1] + '_*_trial_' + '{:03d}'.format(int(filepatspec[2])) + '_*.tif'  
            pth_allfiles_flygraw = glob.glob(pth_allrec + '**/' + fn_pattern, recursive=True)
            pth_allfiles = pth_allfiles + pth_allfiles_flygraw #combine, since both patterns are valid as input
            
            fn_pattern = filepatspec[0] + '_' + filepatspec[1] + '_' + filepatspec[2] + '_stackraw_.*'  #raw or stackraw
            pth_allfiles_carlold = glob.glob(pth_allrec + '**/' + fn_pattern, recursive=True)
            pth_allfiles = pth_allfiles + pth_allfiles_carlold #combine, since both patterns are valid as input

    pth_allfiles_singles = [item for item, count in collections.Counter(pth_allfiles).items() if count == 1] #files that appear once 
    pth_allfiles_singles_full = [item for item, count in collections.Counter([x[:-3] for x in pth_allfiles_singles]).items() if count == 1] #files that appear once, even ignoring extension
    tmptmp = [x[:-3] for x in pth_allfiles_singles]
    keepidx = [tmptmp.index(i) for i in pth_allfiles_singles_full if i in tmptmp] #find indices of extensionless singles in full filename list 
    pth_allfiles_singles_full = [pth_allfiles_singles[i] for i in keepidx] #this puts the extension back on
    pth_allfiles_multi_noext = [item for item, count in collections.Counter([x[:-3] for x in pth_allfiles_singles]).items() if count > 1] #files that appear more than once when ignoring extension
    pth_allfiles_tif_given_mat_too = [tmp + 'tif' for tmp in pth_allfiles_multi_noext] #force tif extension on those that appear with multiple extensions  
    pth_allfiles_dupes = [item for item, count in collections.Counter(pth_allfiles).items() if count > 1] #files that appear multiple times 
    pth_allfiles = pth_allfiles_singles_full + pth_allfiles_tif_given_mat_too + pth_allfiles_dupes #combine 
    pth_allfiles = natsorted(pth_allfiles) #DON'T FORGET TO SORT NATURALLY (NATURALLY)

    if not pth_allfiles:
        print("FOR JOB SUBMITTED, NO FILES MATCHING INPUT PATTERN")


    pth_tif_read_all = []
    pth_fldr_all = []
    fn_prefix_all = []
    pth_prefix_all = []
    md_all = []
    carls_old_project_all = []
    countz = 0
    for pth_datafile in pth_allfiles: #loop over all found files
        
        pth_fldr = ('/').join(pth_datafile.split('/')[:-1])
        fldrname = pth_fldr.split('/')[-1]
        fname = pth_datafile.split('/')[-1]

        if re.search('trial', fname):                       
            fn_prefix = fname.split('_')[0].split('-')[0] + '_' + fname.split('_')[0].split('-')[1]  + '_' + str(int(fname.split('_')[-2][-1])) #change hyphen to underscore
        else:
            fn_prefix = '_'.join(fname.split('_')[:3])

        if re.search("caw846", pth_allrec) or re.search("wienecke", pth_allrec): # on carl's scratch rename if filename has string 'trial' or 'stackraw' 
            if re.search('trial', fname) or re.search('stackraw', fname): 
                fname_rename = fn_prefix + '_raw_.' + fname[-3:]
                pth_datafile_rename = pth_fldr + '/' + fname_rename
                print("RENAMING" + pth_datafile)
                os.rename(pth_datafile, pth_datafile_rename)
                pth_badmat = glob.glob(pth_datafile[:-4] + '.mat', recursive=True)
                if pth_badmat and re.search('trial', fname):
                    print("REMOVING" + pth_badmat[0])
                    os.remove(pth_badmat[0])
                pth_datafile = pth_datafile_rename
                fname = fname_rename

            
        if recording_index == ['all'] or (recording_index !=['all'] and np.isin(countz, recording_index).any()): #if 'all', do all files matching pattern, otherwise only file matching index

            print(pth_datafile)

            pth_prefix = pth_fldr + '/' + fn_prefix      

            pth_md_mat = pth_prefix + '_metadatanew_.mat'
            pth_md_npy = pth_md_mat[:-4] + '.npy'
            
            if int(fn_prefix.split('_')[0])<20230101:
                carls_old_project = 1
            else:
                carls_old_project = 0

            mat_file_shape_in = None
            if carls_old_project and fname[-3:]=='mat':

                if os.path.isfile(pth_datafile[:-4] + '.tif'):
                    raise Exception("you should only be in mat clause if there is no tif")

                mat = mat73.loadmat(pth_datafile)
                Y = mat['stackRaw_pmc'] # Y = mat['stackRaw_mc']
                mnmv = np.min(Y)
                Y = Y - mnmv #make movie nonnegative (not sure this is necessary)
                print("MIN OF STACKRAW_PMC MAT FILE " + str(mnmv))
                Y = np.transpose(Y, (2, 0, 1)) #put in order t y x (not t x y) #stackraw_mc may be flipped relative to stackraw pmc
                pth_datafile = pth_datafile[:-4] + '.tif'
                imwrite(pth_datafile, Y.astype('uint16')) #write as t x y z (singleton z at end)
                mat_file_shape_in = Y.shape

            
            if os.path.isfile(pth_md_npy) and os.path.isfile(pth_md_mat):
                md = np.load(pth_md_npy, allow_pickle='TRUE').item()
            else:
                md = read_save_metadata(pth_datafile, pth_md_mat, pth_md_npy, mat_file_shape = mat_file_shape_in)
                
            pth_tif_read_all.append(pth_datafile)
            pth_fldr_all.append(pth_fldr)
            fn_prefix_all.append(fn_prefix)
            pth_prefix_all.append(pth_prefix)
            md_all.append(md)
            carls_old_project_all.append(carls_old_project)
            
        
        countz = countz + 1


    return (pth_tif_read_all, pth_fldr_all, fn_prefix_all, pth_prefix_all, md_all, carls_old_project_all) 
