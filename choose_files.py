import os
import glob
import numpy as np
from read_save_metadata import read_save_metadata
from helpers import rename_files, mat2tif_carls_old_project, ordinal
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

    pth_allfiles = []
    for filepatspec in filepatspec_all: #loop over all file pattern combos 

        fn_suffix_scopa = '_raw' #find files matching scopa output pattern
        if do_denoise or do_stitching_session or do_extract or do_cropping_session:
            fn_suffix_scopa = '_cmrg'
            if use_background_subtracted:
                fn_suffix_scopa = fn_suffix_scopa + '_bksb'
            if use_denoised and not do_denoise:
                fn_suffix_scopa = fn_suffix_scopa + '_dcdn'
        fn_suffix_scopa = fn_suffix_scopa + '_.tif'
        fn_pattern_scopa = filepatspec[0] + '_' + filepatspec[1] + '_' + filepatspec[2] + fn_suffix_scopa
        pth_allfiles_scopa = glob.glob(pth_allrec + '**/*' + filepatspec[3] + '*/' + fn_pattern_scopa, recursive=True)
        pth_allfiles = pth_allfiles + pth_allfiles_scopa #combine, since both patterns are valid as input

        if do_register: #if do_register==1 (ie if you're looking for the raw files, the first to enter the pipeline) find files matching flyg default output pattern, or carl's old project output pattern
            
            fn_suffix_flyg = '*.tif'
            if filepatspec[2]=='*':
                fn_pattern_flyg = filepatspec[0] + '-' + filepatspec[1] + '_*_trial_*_' + fn_suffix_flyg
            else:
                fn_pattern_flyg = filepatspec[0] + '-' + filepatspec[1] + '_*_trial_' + '{:03d}'.format(int(filepatspec[2])) + '_' + fn_suffix_flyg  
            pth_allfiles_flygraw = glob.glob(pth_allrec + '**/' + fn_pattern_flyg, recursive=True)
            pth_allfiles = pth_allfiles + pth_allfiles_flygraw #combine, since both patterns are valid as input

            fn_suffix_carlold = 'stackraw_.*'
            fn_pattern_carlold = filepatspec[0] + '_' + filepatspec[1] + '_' + filepatspec[2] + '_' + fn_suffix_carlold 
            pth_allfiles_carlold = glob.glob(pth_allrec + '**/' + fn_pattern_carlold, recursive=True)
            pth_allfiles = pth_allfiles + pth_allfiles_carlold #combine, since both patterns are valid as input

    pth_allfiles_singles = [item for item, count in collections.Counter(pth_allfiles).items() if count == 1] #files that appear once 
    pth_allfiles_singles_full = [item for item, count in collections.Counter([x[:-3] for x in pth_allfiles_singles]).items() if count == 1] #files that appear once, even ignoring extension
    tmptmp = [x[:-3] for x in pth_allfiles_singles]
    keepidx = [tmptmp.index(i) for i in pth_allfiles_singles_full if i in tmptmp] #find indices of extensionless singles in full filename list 
    pth_allfiles_singles_full = [pth_allfiles_singles[i] for i in keepidx] #this puts the extension back on
    pth_allfiles_multi_noext = [item for item, count in collections.Counter([x[:-3] for x in pth_allfiles_singles]).items() if count > 1] #files that appear more than once when ignoring extension
    pth_allfiles_tif_with_mat = [tmp + 'tif' for tmp in pth_allfiles_multi_noext] #force tif extension on those that appear with multiple extensions  
    pth_allfiles_duplicates = [item for item, count in collections.Counter(pth_allfiles).items() if count > 1] #files that appear multiple times 
    pth_allfiles = pth_allfiles_singles_full + pth_allfiles_tif_with_mat + pth_allfiles_duplicates #combine 
    pth_allfiles = natsorted(pth_allfiles) #DON'T FORGET TO SORT NATURALLY (NATURALLY)

    if do_register:
        fn_suffixes_all = [fn_suffix_scopa, fn_suffix_flyg, fn_suffix_carlold]
    else:
        fn_suffixes_all = [fn_suffix_scopa]

    if not pth_allfiles:
        search_result_string = "NO FILES WERE FOUND"
        recindstr = ''
    else:
        search_result_string = "THE FOLLOWING FILES WERE FOUND: \n" + '%s' % '\n'.join(map(str, pth_allfiles))
        if recording_index == ['all']:
            recindstr = "WILL OPERATE ON ALL OF THESE FILES"
        else:
            recindstr = []
            for ri in recording_index:
                recindstr.append(ordinal(ri+1))
            recindstr = "BECAUSE OF VALUE(S) in recording_index, WILL OPERATE ON FILE(S) FROM THIS LIST WITH INDICES: \n" + '%s' % ', '.join(map(str, recording_index))

    print("AFTER SEARCHING RECURSIVELY FOR FILES WITHIN THE FOLLOWING DIRECTORY: \n" + pth_allrec + '\n' + \
          "MATCHING ANY OF THE FOLLOWING FILENAME SPECIFIER COMBOS (recdates, fly, trial, folder_substrings, where * is wildcard): \n" + '%s' % '\n'.join(map(str, filepatspec_all)) + '\n' + \
            "AND HAVING ANY OF THE THE FOLLOWING SUFFIXES: \n" + '%s' % '\n'.join(map(str, fn_suffixes_all)) + '\n' + \
                search_result_string + '\n' + recindstr)



    pth_tif_read_all = []
    pth_fldr_all = []
    fn_prefix_all = []
    pth_prefix_all = []
    md_all = []
    carls_old_project_all = []
    countz = 0
    for pth_datafile in pth_allfiles: #loop over all found files
        
        pth_fldr = ('/').join(pth_datafile.split('/')[:-1])
        fname = pth_datafile.split('/')[-1]

        if re.search('trial', fname):                       
            fn_prefix = fname.split('_')[0].split('-')[0] + '_' + fname.split('_')[0].split('-')[1]  + '_' + str(int(fname.split('_')[-2][-1])) #change hyphen to underscore
        else:
            fn_prefix = '_'.join(fname.split('_')[:3])
            
        if recording_index == ['all'] or (recording_index !=['all'] and np.isin(countz, recording_index).any()): #if 'all', do all files matching pattern, otherwise only file matching index

            print("PREPARING FILE: \n" + pth_datafile)

            if re.search("caw846", pth_allrec) or re.search("wienecke", pth_allrec): #  if on on carl's scratch, rename if filename has string 'trial' or 'stackraw' (overwrite flyg and carlold filename patterns with scopa filename patterns) 
                if re.search('trial', fname) or re.search('stackraw', fname):
                    [pth_datafile, fname] = rename_files(pth_datafile, fname, fn_prefix, pth_fldr)

            pth_prefix = pth_fldr + '/' + fn_prefix      

            pth_md_mat = pth_prefix + '_metadatanew_.mat'
            pth_md_npy = pth_md_mat[:-4] + '.npy'
            
            mat_file_shape = None
            if int(fn_prefix.split('_')[0])>20230101:
                carls_old_project = 0
            else:
                carls_old_project = 1
                if fname[-3:]=='mat':
                    mat_file_shape = mat2tif_carls_old_project(pth_datafile)
                    
            
            if os.path.isfile(pth_md_npy) and os.path.isfile(pth_md_mat):
                md = np.load(pth_md_npy, allow_pickle='TRUE').item()
            else:
                md = read_save_metadata(pth_datafile, pth_md_mat, pth_md_npy, mat_file_shape = mat_file_shape)
                
            pth_tif_read_all.append(pth_datafile)
            pth_fldr_all.append(pth_fldr)
            fn_prefix_all.append(fn_prefix)
            pth_prefix_all.append(pth_prefix)
            md_all.append(md)
            carls_old_project_all.append(carls_old_project)
            
        
        countz = countz + 1


    return (pth_tif_read_all, pth_fldr_all, fn_prefix_all, pth_prefix_all, md_all, carls_old_project_all) 
