import os
import glob
import numpy as np
from read_save_metadata import read_save_metadata
from helpers import rename_files, mat2tif_carls_old_project, ordinal
from natsort import natsorted
import re
from itertools import product
import collections
from pathlib import Path
import ast


def choose_files(first_job, pth_allrec, recdate, fly, trial, folder_substring, recording_index, file_matching_style, pth_fldr_fnind, fnind_fn_prefix, 
                 do_register, do_denoise, do_stitch, use_background_subtracted, use_denoised, do_remove, do_crop, do_extract, do_analysis, 
                 folder_with_all_recordings_on_storage_and_compute_filesystems):

    
    pth_fnind = pth_fldr_fnind + fnind_fn_prefix + '_' + str(recording_index[0]) + '_.txt'
    
    if not first_job:
        with open(pth_fnind) as f1:
            print("\n\n\nSINCE THIS IS A JOB INITIATED BY CXP.SH, BUT NOT THE FIRST JOB, WILL READ FILENAME SPECIFIERS FOR PREVIOUSLY FOUND FILES FROM THIS FILE: \n" + pth_fnind)
            filepatspec_all = []
            for line in f1:
                filepatspec_all.append(ast.literal_eval(line))
    else:
        if file_matching_style=='any': #find all possible combinations 
            filepatspec_all = list(product(recdate, fly, trial, folder_substring)) 
        elif file_matching_style=='each': #else corresponding elements 
            maxspec = np.max((len(recdate), len(fly), len(trial), len(folder_substring)))
            if len(recdate)==1:
                recdate = recdate*maxspec
            if len(fly)==1:
                fly = fly*maxspec
            if len(trial)==1:
                trial = trial*maxspec
            if len(folder_substring)==1:
                folder_substring = folder_substring*maxspec
            if not(len(recdate) == len(fly) == len(trial) == len(folder_substring)):
                raise Exception("\n\n\n recdate, fly, trial, and folder_substring must all be same length or length 1 for file_matching_style 'each'")
            filepatspec_all = [(w, x, y, z) for w, x, y, z in zip(recdate, fly, trial, folder_substring)] 

    pth_allfiles = []
    for filepatspec in filepatspec_all: #loop over all file pattern combos 

        fn_suffix_scopa = '_raw' #find files matching scopa output pattern
        if do_denoise or do_stitch or do_extract or do_crop or do_remove or do_analysis:
            fn_suffix_scopa = '_cmrg'
            if use_background_subtracted:
                fn_suffix_scopa =  '_bksb' + fn_suffix_scopa
            if use_denoised and (do_extract or do_crop or do_remove or do_analysis):
                fn_suffix_scopa = fn_suffix_scopa + '_dcdn'
        fn_suffix_scopa = fn_suffix_scopa + '_.tif'
        fn_pattern_scopa = filepatspec[0] + '_' + filepatspec[1] + '_' + filepatspec[2] + fn_suffix_scopa
        pth_allfiles_scopa = glob.glob(pth_allrec + '**/*' + filepatspec[3] + '*/' + fn_pattern_scopa, recursive=True)
        pth_allfiles = pth_allfiles + pth_allfiles_scopa #combine, since both patterns are valid as input

        if do_register: #(ie if you're looking for the raw files, the first to enter the pipeline) find files matching flyg default output pattern, or carl's old project output pattern
            
            if filepatspec[2]=='*':
                fn_suffix_flyg = '_*_trial_*_*.tif'
            else:
                fn_suffix_flyg = '_*_trial_' + '{:03d}'.format(int(filepatspec[2])) + '_*.tif'  #this suffix actually includes a filepatspec for trial, oh well
            fn_pattern_flyg = filepatspec[0] + '-' + filepatspec[1] + fn_suffix_flyg
            # pth_allfiles_flyg = glob.glob(pth_allrec + '**/' + fn_pattern_flyg, recursive=True)
            pth_allfiles_flyg = glob.glob(pth_allrec + '**/*' + filepatspec[3] + '*/' + fn_pattern_flyg, recursive=True)
            pth_allfiles = pth_allfiles + pth_allfiles_flyg #combine, since both patterns are valid as input

            fn_suffix_carlold = 'stackraw_.*'
            fn_pattern_carlold = filepatspec[0] + '_' + filepatspec[1] + '_' + filepatspec[2] + '_' + fn_suffix_carlold 
            # pth_allfiles_carlold = glob.glob(pth_allrec + '**/' + fn_pattern_carlold, recursive=True)
            pth_allfiles_carlold = glob.glob(pth_allrec + '**/*' + filepatspec[3] + '*/' + fn_pattern_carlold, recursive=True)
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
        if not first_job or recording_index == ['all']:
            recindstr = "WILL OPERATE ON ALL OF THESE FILES"
        else:
            recindstr = []
            for ri in recording_index:
                recindstr.append(ordinal(int(ri)+1))
            recindstr = "BECAUSE OF VALUE(S) in recording_index, WILL OPERATE ON FILE(S) FROM THIS LIST WITH THE FOLLOWING INDICES (IF FILES EXIST AT THESE INDICES): \n" + '%s' % ', '.join(map(str, recording_index))

    print("\n\n\nAFTER SEARCHING RECURSIVELY FOR FILES WITHIN THE FOLLOWING DIRECTORY: \n" + pth_allrec + '\n' + \
          "MATCHING ANY OF THE FOLLOWING FILENAME SPECIFIER COMBOS (recdate, fly, trial, folder_substring, where * is wildcard): \n" + '%s' % '\n'.join(map(str, filepatspec_all)) + '\n' + \
            "AND HAVING ANY OF THE THE FOLLOWING SUFFIXES: \n" + '%s' % '\n'.join(map(str, fn_suffixes_all)) + '\n' + \
                search_result_string + '\n' + recindstr)



    pth_tif_read_all = []
    pth_fldr_all = []
    fn_prefix_all = []
    pth_prefix_all = []
    pth_md_all = []
    carls_old_project_all = []
    countz = 0
    for pth_datafile in pth_allfiles: #loop over all found files
            
        if not first_job or (first_job and ( recording_index == ['all'] or (recording_index !=['all'] and np.isin(countz, recording_index).any()) ) ): #if first_job . . .  if 'all', do all files matching pattern, otherwise only file matching recording_index, if not first_job, don't apply this selection

            print("\n\n\nPREPARING FILE: \n" + pth_datafile)

            pth_fldr = ('/').join(pth_datafile.split('/')[:-1]) + '/'
            fname = pth_datafile.split('/')[-1]

            if re.search('trial', fname):                       
                fn_prefix = fname.split('_')[0].split('-')[0] + '_' + fname.split('_')[0].split('-')[1]  + '_' + str(int(fname.split('_')[-2][-1])) #change hyphen to underscore
            else:
                fn_prefix = '_'.join(fname.split('_')[:3])

            pth_prefix = pth_fldr + fn_prefix
            pth_md = pth_prefix + '_metadatanew_.npy'
            pth_md_mat = pth_md[:-4] + '.mat'  
            
            pth_pattern_hires = pth_fldr + fn_prefix.split('_')[0] + '?' + fn_prefix.split('_')[1] + '_' + fn_prefix.split('_')[2] + '_hires_.tif'
            pth_hires = glob.glob(pth_pattern_hires)
            if not pth_hires:
                pth_pattern_hires = pth_fldr + fn_prefix.split('_')[0] + '?' + fn_prefix.split('_')[1] + '_hires_.tif'
                pth_hires = glob.glob(pth_pattern_hires)
            if pth_hires:
                pth_hires = pth_hires[0]

            if re.search("wilsonlab/wienecke", pth_allrec) or re.search("Users/wienecke/Documents", pth_allrec): #  if in carl's wilsonlab storage server folder, rename if filename has string 'trial' or 'stackraw' (overwrite flyg and carlold filename patterns with scopa filename patterns) 
                if re.search('trial', fname) or re.search('stackraw', fname) or pth_hires: #do this only on storage server so that it is the first thing to occur before moving, to avoid duplicate files with different names
                    [pth_datafile, fname, pth_hires] = rename_files(pth_datafile, fname, fn_prefix, pth_fldr, pth_hires)
            
            mat_file_shape = None
            if int(fn_prefix.split('_')[0])>20230101:
                carls_old_project = 0
            else:
                carls_old_project = 1
                if fname[-3:]=='mat':
                    mat_file_shape = mat2tif_carls_old_project(pth_datafile)


            if not os.path.isfile(pth_md) or not os.path.isfile(pth_md_mat): #if either npy or mat version is not present, remake both 
                read_save_metadata(pth_datafile, pth_md, pth_md_mat, pth_hires, mat_file_shape = mat_file_shape)
                

            pth_tif_read_all.append(pth_datafile)
            pth_fldr_all.append(pth_fldr)
            fn_prefix_all.append(fn_prefix)
            pth_prefix_all.append(pth_prefix)
            pth_md_all.append(pth_md)
            carls_old_project_all.append(carls_old_project)
            
        
        countz = countz + 1

    if first_job: #if first_job, write a file mathing recording specifiers to recording index, so subsequent jobs in the same run will follow this mapping
        with open(pth_fnind, 'w') as f2:
            
            print("\n\n\nSINCE THIS IS THE FIRST (OR ONLY) JOB IN THE PIPELINE, WILL WRITE FILENAME SPECIFIERS FOR FOUND FILES TO THIS FILE: \n" + pth_fnind)

            recdate_found = []
            fly_found = []
            trial_found = []
            folder_substring_found = []
            for ppa in pth_prefix_all:
                pp = Path(ppa).parts #split path
                recdate_found.append(pp[-1].split('_')[0])
                fly_found.append(pp[-1].split('_')[1])
                trial_found.append(pp[-1].split('_')[2])
                split_index = pp.index(folder_with_all_recordings_on_storage_and_compute_filesystems) + 1 
                folder_substring_found.append(os.path.join(*pp[split_index:-1]) ) #everything in path after 'stacks' but before filename
            lines = [(w, x, y, z) for w, x, y, z in zip(recdate_found, fly_found, trial_found, folder_substring_found)] 
            for line in lines:
                f2.write(f"{line}\n")
            f2.close()




    return (pth_tif_read_all, pth_fldr_all, fn_prefix_all, pth_prefix_all, pth_md_all, carls_old_project_all) 
