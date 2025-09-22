import os
import glob
import numpy as np
from mdsisv import mdsisv, convert_md_file
from helpers import rename_original_scanimage_files, mat2tif, ordinal
from natsort import natsorted
import re
from itertools import product
import collections
from pathlib import Path
import ast
from pathmake import pathscopaget


def filefind(first_noncopy_job, pth_allrec, recdate, fly, trial, substr, jobind, file_matching_style, pth_fldr_fnind, fnind_fn_prefix, 
                 do_copyfiles, do_register, do_denoise, dnraw, do_stitch, do_remove, do_crop_only, do_extract, do_a2p, use_background_subtracted, use_denoised, use_scannoise_removed, 
                 folder_with_all_recordings_on_storage_and_compute_filesystems):

    # chanopt = ['[_chn]*'] #return chn1 or chn2 or both, but not filenames where chn* string is absent

    ######### FORMAT FILE SPECIFIERS, BASED ON INPUT #########

    pth_fnind = pth_fldr_fnind + fnind_fn_prefix + '_' + str(jobind[0]) + '_.txt'
    
    if first_noncopy_job or do_copyfiles!=0:
        if file_matching_style=='any': #find all possible combinations 
            filepatspec_all = list(product(recdate, fly, trial, substr)) 
        elif file_matching_style=='each': #else corresponding elements 
            maxspec = np.max((len(recdate), len(fly), len(trial), len(substr)))
            if len(recdate)==1:
                recdate = recdate*maxspec
            if len(fly)==1:
                fly = fly*maxspec
            if len(trial)==1:
                trial = trial*maxspec
            if len(substr)==1:
                substr = substr*maxspec
            if not(len(recdate) == len(fly) == len(trial) == len(substr)):
                raise Exception("\n\n\n recdate, fly, trial, and substr must all be same length or length 1 for file_matching_style 'each'")
            filepatspec_all = [(w, x, y, z) for w, x, y, z in zip(recdate, fly, trial, substr)] 
    else:
        with open(pth_fnind) as f1:
            print("\n\n\nSINCE THIS IS A JOB INITIATED BY pl.sh, BUT NOT THE FIRST JOB, WILL READ FILENAME SPECIFIERS FOR PREVIOUSLY FOUND FILES FROM THIS FILE: \n" + pth_fnind)
            filepatspec_all = []
            for line in f1:
                filepatspec_all.append(ast.literal_eval(line))

    ######### FIND FILES (INPUT FILES FOR DIFFERENT PARTS OF PIPELINE) #########

    pth_allfiles = []
    for filepatspec in filepatspec_all: #loop over all file pattern combos 

        suffixchar_original = 'o'
        fn_suffix_scopa = '_' + suffixchar_original #find files matching scopa output pattern (do_register scopa suffix for input file is 'o' (output ir 'or'), below is flyg suffix for do_register)
        if do_denoise and not dnraw or do_stitch and not dnraw or do_extract or do_crop_only or do_remove or do_a2p:
            fn_suffix_scopa = fn_suffix_scopa + 'r' 
            if use_background_subtracted:
                fn_suffix_scopa = '_' + suffixchar_original + 'br'
            if use_denoised and (do_extract or do_crop_only or do_remove or do_a2p): #don't let this affect do_stitch since it must have 'd' if it's run
                fn_suffix_scopa = fn_suffix_scopa + 'd'
            if use_scannoise_removed and (do_extract or do_crop_only or do_a2p):
                fn_suffix_scopa = fn_suffix_scopa + 's'
        if use_scannoise_removed and do_extract:
            fn_suffix_scopa = fn_suffix_scopa + '_.mat'  #this is the only time only a mat is available when a tif is required (besides carls_old_project)
        else:
            fn_suffix_scopa = fn_suffix_scopa + '_.tif'
        fn_pattern_scopa = filepatspec[0] + '_' + filepatspec[1] + '_' + filepatspec[2] + fn_suffix_scopa #
        pth_allfiles_scopa = glob.glob(pth_allrec + '**/*' + filepatspec[3] + '*/**/' + fn_pattern_scopa, recursive=True)
        pth_allfiles = pth_allfiles + pth_allfiles_scopa #combine with empty (functionally pointless here, just for readability/symmetry with pattern below

        if do_register or do_denoise and dnraw: #(ie if you're looking for the raw files, the first to enter the pipeline) find files matching flyg default output pattern, or carl's old project output pattern 
            
            if filepatspec[2]=='*':
                fn_suffix_flyg = '_*_trial_*_*.tif'
            else:
                fn_suffix_flyg = '_*_trial_' + '{:03d}'.format(int(filepatspec[2])) + '_*.tif'  #this suffix actually includes a filepatspec for trial, oh well
            fn_pattern_flyg = filepatspec[0] + '-' + filepatspec[1] + fn_suffix_flyg
            pth_allfiles_flyg = glob.glob(pth_allrec + '**/*' + filepatspec[3] + '*/**/' + fn_pattern_flyg, recursive=True)
            pth_allfiles = pth_allfiles + pth_allfiles_flyg #combine, since multiple patterns are valid as input

            fn_suffix_carlold = 'stackraw_.*'
            fn_pattern_carlold = filepatspec[0] + '_' + filepatspec[1] + '_' + filepatspec[2] + '_' + fn_suffix_carlold 
            pth_allfiles_carlold = glob.glob(pth_allrec + '**/*' + filepatspec[3] + '*/**/' + fn_pattern_carlold, recursive=True)
            pth_allfiles = pth_allfiles + pth_allfiles_carlold #combine, since multiple patterns are valid as input

        if do_remove or do_a2p: #these jobs use mat files (or convert tif to mat) so check if mat exists too
            fn_suffix_scopa_mat = fn_suffix_scopa[:-5] + '_.mat'
            fn_pattern_scopa_mat = filepatspec[0] + '_' + filepatspec[1] + '_' + filepatspec[2] + fn_suffix_scopa_mat
            pth_allfiles_scopa_mat = glob.glob(pth_allrec + '**/*' + filepatspec[3] + '*/**/' + fn_pattern_scopa_mat, recursive=True)
            pth_allfiles = pth_allfiles + pth_allfiles_scopa_mat #combine, since multiple patterns are valid as input


    ######### ORGANIZE LIST OF FOUND FILES, REMOVE DUPLICATES #########

    pth_allfiles_singles = [item for item, count in collections.Counter(pth_allfiles).items() if count == 1] #files that appear in pth_allfiles once 
    pth_allfiles_singles_full = [item for item, count in collections.Counter([x[:-3] for x in pth_allfiles_singles]).items() if count == 1] #files that appear in pth_allfiles once, even ignoring extension
    tmptmp = [x[:-3] for x in pth_allfiles_singles]
    keepidx = [tmptmp.index(i) for i in pth_allfiles_singles_full if i in tmptmp] #find indices of extensionless singles in full filename list 
    pth_allfiles_singles_full = [pth_allfiles_singles[i] for i in keepidx] #this puts the extension back on
    pth_allfiles_multi_noext = [item for item, count in collections.Counter([x[:-3] for x in pth_allfiles_singles]).items() if count > 1] #files that appear more than once when ignoring extension
    if do_remove or do_a2p:
        pth_allfiles_mat_with_tif = [tmp + 'mat' for tmp in pth_allfiles_multi_noext] #choose mat not tif, if both available (force mat extension on those that appear with mat and tif extensions since do_remove and do_a2p want mat if available)  
        pth_allfiles_tif_with_mat = []
    else:
        pth_allfiles_tif_with_mat = [tmp + 'tif' for tmp in pth_allfiles_multi_noext] # choose tif not mat, if both available (force tif extension on those that appear with mat and tif extensions since everything but do_remove and do_a2p want tif if available)  
        pth_allfiles_mat_with_tif = []
    pth_allfiles_duplicates = [item for item, count in collections.Counter(pth_allfiles).items() if count > 1] #files that appear multiple times in pth_allfiles
    pth_allfiles = pth_allfiles_singles_full + pth_allfiles_tif_with_mat + pth_allfiles_mat_with_tif + pth_allfiles_duplicates #combine 
    pth_allfiles = natsorted(pth_allfiles) #DON'T FORGET TO SORT NATURALLY (NATURALLY)


    ######### REPORT RESULTS #########

    try:
        fn_suffix_scopa
    except:
        raise Exception("fn_suffix_scopa IS NOT DEFINED; jobind (jobind IN pl.sh) FOR THIS JOB MAY BE OUTSIDE THE RANGE OF AVAILABLE FILES, IN WHICH CASE THIS JOB, AND ALL DEPENDENT JOBS, WILL ERROR; THIS IS NOT A PROBLEM EXCEPT IT MEANS YOU'RE REQUESTING BUT NOT USING RESOURCES ON O2; MAKE SURE jobind ONLY LISTS INDICES FOR FILES THAT EXIST")

    if do_register or do_denoise and dnraw:
        fn_suffixes_all = [fn_suffix_scopa, fn_suffix_flyg, fn_suffix_carlold]
    else:
        if do_remove or do_a2p:
            fn_suffixes_all = [fn_suffix_scopa, fn_suffix_scopa_mat]
        else:
            fn_suffixes_all = [fn_suffix_scopa]

    if not pth_allfiles:
        search_result_string = "NO FILES WERE FOUND"
        recindstr = ''
    else:
        search_result_string = "THE FOLLOWING FILES WERE FOUND: \n" + '%s' % '\n'.join(map(str, pth_allfiles))
        if not first_noncopy_job or jobind == ['all']:
            recindstr = "WILL OPERATE ON ALL OF THESE FILES"
        else:
            recindstr = []
            for ri in jobind:
                recindstr.append(ordinal(int(ri)+1))
            recindstr = "BECAUSE OF VALUE(S) in jobind, WILL OPERATE ON FILE(S) FROM THIS LIST WITH THE FOLLOWING (ZERO-INDEXED) INDICES (IF FILES EXIST AT THESE INDICES): \n" + '%s' % ', '.join(map(str, jobind))

    print("\n\n\nAFTER SEARCHING RECURSIVELY FOR FILES WITHIN THE FOLLOWING DIRECTORY: \n" + pth_allrec + '\n' + \
          "MATCHING ANY OF THE FOLLOWING FILENAME SPECIFIER COMBOS (recdate, fly, trial, substr, where * is wildcard): \n" + '%s' % '\n'.join(map(str, filepatspec_all)) + '\n' + \
            "AND HAVING ANY OF THE THE FOLLOWING SUFFIXES: \n" + '%s' % '\n'.join(map(str, fn_suffixes_all)) + '\n' + \
                search_result_string + '\n' + recindstr)


    ######### LOOP OVER FOUND FILES #########

    pth_read_all = []
    pth_fldr_all = []
    fn_prefix_all = []
    pth_prefix_all = []
    pthmd_all = []
    pth_daq_all = []
    pth_ftvid_all = []
    pth_ftdat_all = []
    pth_opt_all = []
    carls_old_project_all = []
    k = 0
    for pth_readfile in pth_allfiles: #loop over all found files
            
        if not first_noncopy_job or (first_noncopy_job and ( jobind == ['all'] or (jobind !=['all'] and np.isin(k, jobind).any()) ) ): #if first_noncopy_job . . .  if 'all', do all files matching pattern, otherwise only file whose index is in jobind; but if not first_noncopy_job (always first_noncopy_job in interactive mode, but only on first run in batch mode), don't apply this selection because it's been written into the fnind file that the file specifiers are read from

            print("\n\n\nPREPARING FILE: \n" + pth_readfile)

            fldr = ('/').join(pth_readfile.split('/')[:-1]) + '/'
            fname = pth_readfile.split('/')[-1]

            if '__' in fname:
                print("\n\n\nWARNING FOUND FILE HAS DOUBLE UNDERSCORE(S), REPLACING WITH SINGLE UNDERSCORE(S)")
                fname = fname.replace('__', '_')

            if re.search('trial', fname):                       
                fn_prefix = fname.split('_')[0].split('-')[0] + '_' + fname.split('_')[0].split('-')[1]  + '_' + str(int(fname.split('_')[-2][-1])) #change hyphen to underscore
            else:
                fn_prefix = '_'.join(fname.split('_')[:3])
            fn_prefix_flyg = '-'.join(fn_prefix.split('_')[:2])

            pth_prefix = fldr + fn_prefix
            datestr_found = fn_prefix.split('_')[0]
            flystr_found = fn_prefix.split('_')[1]
            trialstr_found = fn_prefix.split('_')[2]

            ######### FIND SOME ADDITIONAL OPTIONAL FILES #########

            pthmd = pth_prefix + '_mdsi_.txt'

            # fn_pattern_md_flyg = fldr + fn_prefix_flyg + '_metadata_*_trial_' + trialstr_found.zfill(3) + '.mat'
            # pthmd_flyg = glob.glob(fn_pattern_md_flyg, recursive=True)
            # pthmd_flyg = pthmd_flyg[0] #flyg metadata file only exists if you register in flyg
            # if pthmd_flyg:
            #     pthmd_flyg = pthmd_flyg[0]

            fn_pattern_daq = fldr + fn_prefix_flyg + '_daqData_*_trial_' + trialstr_found.zfill(3) + '.mat'
            pth_daq = glob.glob(fn_pattern_daq, recursive=True)
            if pth_daq:
                pth_daq = pth_daq[0]

            pthscopa = pathscopaget()
            pth_opt_pattern = pthscopa + 'opt_*_*_*_.txt' # copy all opt files from server to O2 
            pth_opt = glob.glob(pth_opt_pattern)
                
            fn_pattern_ftvid = fldr + 'FicTracData/fictrac-raw-' + datestr_found + '*_trial_' + trialstr_found.zfill(3) + '.avi'
            pth_ftvid = glob.glob(fn_pattern_ftvid, recursive=True)
            if pth_ftvid:
                pth_ftvid = pth_ftvid[0]
            
            fn_pattern_ftdat = fldr + 'FicTracData/fictrac-' + datestr_found + '*_trial_' + trialstr_found.zfill(3) + '.dat'
            pth_ftdat = glob.glob(fn_pattern_ftdat, recursive=True)
            if pth_ftdat:
                pth_ftdat = pth_ftdat[0]
            
            ######### RENAME FLYG FILES IF YOU'RE CARL, AND LOAD CARL'S OLD MAT FILES AS TIF #########

            if re.search("wilsonlab/wienecke", pth_allrec) or re.search("Users/wienecke/Documents", pth_allrec): #  if in carl's wilsonlab storage server folder, rename if filename has string 'trial' or 'stackraw' (overwrite flyg and carlold filename patterns with scopa filename patterns) 
                if re.search('trial', fname): #do this only on storage server so that it is the first thing to occur before moving, to avoid duplicate files with different names
                    [pth_readfile, fname] = rename_original_scanimage_files(pth_readfile, fname, fn_prefix, fldr, suffixchar_original)
            
            mat_file_shape = None
            if int(datestr_found)>20230101:
                carls_old_project = 0
            else:
                carls_old_project = 1
            
            if fname[-3:]=='mat' and do_copyfiles==0 and not do_remove and not do_a2p:
                mat_file_shape = mat2tif(pth_readfile, carls_old_project)


            ######### READ & WRITE SCANIMAGE METADATA #########

            pthmd_old = pth_prefix + '_metadatanew_.npy'
            pthmd_matold = pthmd_old[:-4] + '.mat'  
            if not os.path.isfile(pthmd): #if scanimage metadata file (*mdsi_.txt) is not present, make it
                if do_register or do_denoise and dnraw: #if doing registration, or if the either of the old metadata files are present, make mdsi_.txt:
                    if do_copyfiles==0: #if do_register and not copying files, create metadata files
                        mdsisv(pth_readfile, pthmd, mat_file_shape = mat_file_shape)
                    elif do_copyfiles==1: #if do_copyfiles==1, ie copying into O2, during do_register, they won't exist yet and that's fine
                        pthmd = []
                    # elif do_copyfiles==2: #REMOVED THIS BECAUSE COPYFILES 2 CAN OPERATE ON RECORDINGS THAT DIDN'T GET REGISTERED, BUT MATCHED FILE SPECS (if recid doens't include them eg) #if copying out of O2 during do_register, metadata files should exist, raise exception if they don't 
                    #     raise Exception("mdsi_.txt is not found; can only be created from scanimage metadata in raw tif, so make sure you haven't moved those metadata files, or run do_register to create them")
                else:
                    if os.path.isfile(pthmd_old):
                        convert_md_file(pthmd, pthmd_old, pthmd_matold)
                    else:
                        raise Exception("mdsi_.txt is not found, and neither is old metadata file 'metadatanew.npy, and you're not running do_register; can only be created from scanimage metadata in raw tif (the tif file used in do_register), so make sure you haven't moved those metadata files, or run do_register to create them")
            if os.path.isfile(pthmd_old): 
                os.remove(pthmd_old)
            if os.path.isfile(pthmd_matold): 
                os.remove(pthmd_matold)
                            
            
            ######### PUT IN LISTS (THESE MAY NOT BE ALL FOUND FILES SINCE jobid MAY HAVE BEEN APPLIED #########

            pth_read_all.append(pth_readfile)
            pth_fldr_all.append(fldr)
            fn_prefix_all.append(fn_prefix)
            pth_prefix_all.append(pth_prefix)
            pthmd_all.append(pthmd)
            pth_daq_all.append(pth_daq)
            pth_ftvid_all.append(pth_ftvid)
            pth_ftdat_all.append(pth_ftdat)
            pth_opt_all.append(pth_opt)
            carls_old_project_all.append(carls_old_project)
            
        
        k = k + 1

    ######### IF FIRST JOB IN PIPELINE, WRITE FILE SPECIFIERS INTO FILE FOR LATER JOBS #########

    if first_noncopy_job: #if first_noncopy_job, write file(s) matching recording specifiers (and possible jobind selection) to recording index, so subsequent jobs in the same run will follow this mapping
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



    return (pth_read_all, pth_fldr_all, fn_prefix_all, pth_prefix_all, pthmd_all, pth_daq_all, pth_ftvid_all, pth_ftdat_all, pth_opt_all, carls_old_project_all) 
