
import numpy as np
import glob
import re
from natsort import natsorted
import fnmatch
import os
from tifffile.tifffile import imwrite, imread
import shutil
from pathlib import Path
import mat73



def stitch_registered_z_slices(pth_tif_reg, dims, do_plots):

    print("\n\n\nstitching together separately registered z slices, and writing as one tif")

    pth_tif_all = natsorted(glob.glob(pth_tif_reg[:-4] + '*_z_.tif'))

    Y = np.zeros(dims) #t z y x 

    countz = 0
    for f in pth_tif_all:
        countz = countz + 1
        print(f)
        sliceind = int(f.split('_')[-3])
        Ynew = imread(f)
        print(Ynew.dtype)
        print(sliceind)
        print("some (or probably all) slice min should be nonzero at this stage, this slice min is:" + str(np.min(Ynew)))
        Y[:,sliceind,:,:] = Ynew # was Y[:,:,:,sliceind] = Ynew

    if countz != dims[1]:
        raise Exception("not all slices present")

    mnmv = np.min(Y)
    Y = Y - mnmv #make nonnegative before writing to uint16
    if np.max(Y) > 65535:
        raise Exception("clipping will occur when converting to uint16")
    print("MIN AFTER REGISTRATION " + str(mnmv))

    Y = Y.astype('uint16')

    print(Y.shape)

    Y = Y.reshape(dims[0] * dims[1], dims[2], dims[3]) #(tz)yx
    print(Y.shape)
    #imwrite(pth_tif_reg, Y.squeeze(), bigtiff=True, photometric='minisblack') #squeeze was just for non-volumetric (old project), does it change header, slowing read dramatically?
    imwrite(pth_tif_reg, Y, bigtiff=True, photometric='minisblack') #write the registered movie as tif for use in matlab, and caiman extraction below

    for f in pth_tif_all:
        os.remove(f)
    
    return Y 



def separate_z_slices_for_denoising(pth_tif_read, fn_prefix, pth_denoising, md, denoise_volume):

    # prepare files for denoising by writing each z slice to different tif and putting in separate folders if denoise_volume = 0 
    # if using denoise_volume = 1, saves all separate tifs into one folder 
    # we do this cpu-intensive part outside denoise.py, which is gpu-intensive, since requesting lots of gpu and cpu will delay job start

    print("\n\n\nseparating z slices, and writing as separate tifs, to prepare data for deepcad denoising")

    dims = md['dims']

    Y = imread(pth_tif_read)
    Y = Y.reshape(dims)
    Y = np.transpose(Y, (0, 2, 3, 1)) #put in order t y x z (not t x y z)
    if Y.dtype!='uint16':
        raise Exception("dtype should be uint16 (arbitrary choice for this pipeline)")
    zind_all_dn = np.arange(dims[1])

    for zii in zind_all_dn: #deepcad wants 3d data, so organize slices into separate tif files, and put in one folder (if denoise_volume=1, ie train on all slices) or separate folders (if denoise_volume=0, ie train on z subset)

        Ynew = Y[:,:,:,zii]
        Lt, Ly, Lx = Ynew.shape
        denoise_input_dtype = Ynew.dtype
        if Ynew.shape != (dims[0], dims[2], dims[3]):
            raise Exception("dims changed")

        if denoise_volume:
            dnfolder = fn_prefix + '_all'
        else:
            dnfolder = fn_prefix + '_' + str(zii)
        tifname = fn_prefix + '_' + str(zii) + '_' + str(Lt) + '_' + str(Ly)  + '_' + str(Lx) + '_' + str(denoise_input_dtype) + '_.tif'

        print(tifname)
        pth_trainset = pth_denoising + '/' + dnfolder #dir containing all tif files for training
        pth_tif_write = pth_trainset + '/' + tifname
        if os.path.exists(pth_trainset) and (zii==0 or denoise_volume==0): #if you're on the first zii (regardless of denoise_volume value), or for all zii if denoise_volume==0
            shutil.rmtree(pth_trainset) #REMOVE any existing training folder before training, to ensure models don't get mixed (until "resume training" functionality is written)
        if not os.path.exists(pth_trainset): #don't make this "else" connected to "if" above because you have to evaluate it
            os.mkdir(pth_trainset)
        imwrite(pth_tif_write, Ynew, bigtiff=True, photometric='minisblack' ) #put the tif in the folder deepcad looks to for training data



def separate_z_slices_for_denoising_carls_old_project(pth_tif_read, fn_prefix, pth_denoising, md, denoise_volume):

    # prepare files for denoising by writing each z slice to different tif and putting in separate folders if denoise_volume = 0 
    # if using denoise_volume = 1, saves all separate tifs into one folder 
    # we do this cpu-intensive part outside denoise.py, which is gpu-intensive, since requesting lots of gpu and cpu will delay job start

    print("\n\n\npreparing carl's old data for deepcad denoising, if you're not carl there is a problem")

    dims = md['dims']
    
    Y = imread(pth_tif_read)
    Y = Y.reshape(dims)
    Y = np.transpose(Y, (0, 2, 3, 1)) #put in order t y x z (not t x y z)
    if Y.dtype!='uint16':
        raise Exception("dtype should be uint16 (arbitrary choice for this pipeline)")
    zind_all_dn = np.arange(dims[1])

    for zii in zind_all_dn: #deepcad wants 3d data, so organize slices into separate tif files, and put in one folder (if denoise_volume=1, ie train on all slices) or separate folders (if denoise_volume=0, ie train on z subset)

        Ynew = Y[:,:,:,zii]
        Lt, Ly, Lx = Ynew.shape
        denoise_input_dtype = Ynew.dtype
        if Ynew.shape != (dims[0], dims[2], dims[3]):
            raise Exception("dims changed")

        if denoise_volume:
            pretend_z = str(int(fn_prefix.split('_')[2]) - 1) #make it zero indexed
            pretend_trial = '1' # pretend they all come from same trial
            dnfolder = fn_prefix.split('_')[0] + '_' + fn_prefix.split('_')[1] + '_' + pretend_trial + '_all' #for these non-volumetric grad recordings, if do_volume == 1, rename all trials "1", and each trial a different z slice
            tifname = fn_prefix.split('_')[0] + '_' + fn_prefix.split('_')[1] + '_' + pretend_trial + '_' + pretend_z + '_' + str(Lt) + '_' + str(Ly)  + '_' + str(Lx) + '_' + str(denoise_input_dtype) + '_.tif'
        else: #if not denoise_volume, just keep it the way it is (all trials have only z slice 0)
            actual_z = '0'
            dnfolder = fn_prefix + '_' + actual_z
            tifname = fn_prefix + '_' + actual_z + str(Lt) + '_' + str(Ly)  + '_' + str(Lx) + '_' + str(denoise_input_dtype) + '_.tif'

        print(tifname)
        pth_trainset = pth_denoising + '/' + dnfolder #dir containing all tif files for training
        pth_tif_write = pth_trainset + '/' + tifname
        
        # for old project cannot remove folder because it saves from separate runs of register        
        # if os.path.exists(pth_trainset) and (zii==0 or denoise_volume==0): #if you're on the first zii (regardless of denoise_volume value), or for all zii if denoise_volume==0
        #     shutil.rmtree(pth_trainset) #REMOVE any existing training folder before training, to ensure models don't get mixed (until "resume training" functionality is written)
        
        if not os.path.exists(pth_trainset): #don't make this "else" connected to "if" above because you have to evaluate it
            os.mkdir(pth_trainset)
        imwrite(pth_tif_write, Ynew, bigtiff=True, photometric='minisblack') #put the tif in the folder deepcad looks to for training data



def stitch_denoised_slices(pth_denoising, fn_prefix, pth_tif_read, md, denoise_volume, denoise_epoch_choose):

  #stitch together denoised slices (tyx) into original size (tzyx)

    pth_tif_write = pth_tif_read[:-4] + 'dcdn_.tif'
    
    if os.path.isfile(pth_tif_write):
    
        print("\n\n\nWARNING, SKIPPING do_stitch BECAUSE pth_tif_write ALREADY EXISTS - DELETE IT TO CREATE A NEW ONE")
    
    else:
  
        print("\n\n\nstitching together denoised tifs (each tif a single z slice), and writing as one tif")

        dims_pre_denoise = md['dims']
        if denoise_volume == 1:
            pth_trainset_all = natsorted(glob.glob(os.path.join(pth_denoising, fn_prefix + '_all/')))
        else:
            pth_trainset_all = natsorted(glob.glob(os.path.join(pth_denoising, fn_prefix + '_*/')))
            pth_trainset_all = list(set(pth_trainset_all) - set(natsorted(glob.glob(os.path.join(pth_denoising, fn_prefix + '_al*/'))))) #exclude the "all" folders when denoise_volume==1

        Y = np.zeros((dims_pre_denoise[0], dims_pre_denoise[2], dims_pre_denoise[3], dims_pre_denoise[1])) #t y x z

        countz = 0
        for pth_trainset in pth_trainset_all:
        
            fldr_chex = natsorted(glob.glob(os.path.join(pth_trainset, 'DataFolderIs_*')))
            for fcxi,fcx in enumerate(fldr_chex):
                if fcxi!=len(fldr_chex)-1:
                    print("deleting this denoise test folder from old run")
                    print(fcx)
                    shutil.rmtree(fcx)
        
            fldr_outtiff_all = natsorted(glob.glob(os.path.join(pth_trainset, 'DataFolderIs_*', 'E_*'))) #for all epochs that were used for denoising, organize tif files into single folder in 'denoised' folder
            for fldr_outtiff in fldr_outtiff_all:
            
                if fnmatch.fnmatch(fldr_outtiff.split('/')[-1], 'E_' + "{:02d}".format(denoise_epoch_choose) + '_Iter_*'):
                    pth_denoised_singles = natsorted(glob.glob(os.path.join(fldr_outtiff, '*output.tif')))

                    for fni,f in enumerate(pth_denoised_singles): #loop over each denoised z slice and reassemble into array matching shape of original 4d volume
                        countz = countz + 1
                        print(f)
                        sliceind = int(f.split('/')[-1].split('_')[3])
                        Ynew = imread(f)
                        if Ynew.dtype!='uint16':
                            print("warning, converting type from " + str(Ynew.dtype))
                            Ynew = Ynew.astype('uint16')
                            if np.min(Y)<0 or np.max(Y) > 65535:
                                raise Exception("denoising have operated on uint16 for this pipeline, or adjust it")
                        print(Ynew.dtype)
                        print(sliceind)
                        Y[:,:,:,sliceind] = Ynew

        if countz != dims_pre_denoise[1]:
            raise Exception("not all slices present")

        mnmv = np.min(Y)
        Y = Y - mnmv #make nonnegative before writing to uint16
        print("MIN AFTER DENOISING " + str(mnmv))
    
        Y = Y.astype('uint16')

        Y = np.transpose(Y, (0, 3, 1, 2)) #tzyx
        print(Y.shape)
        Y = Y.reshape(dims_pre_denoise[0] * dims_pre_denoise[1], dims_pre_denoise[2], dims_pre_denoise[3]) #(tz)yx
        print(Y.shape)
        #imwrite(pth_tif_write, Y.squeeze(), bigtiff=True, photometric='minisblack') #squeeze was just for non-volumetric (old project), does it change header, slowing read dramatically?
        imwrite(pth_tif_write, Y, bigtiff=True, photometric='minisblack') #write the registered movie as tif for use in matlab, and caiman extraction below



def stitch_denoised_slices_carls_old_project(pth_denoising, fn_prefix, pth_tif_read, md, denoise_volume, denoise_epoch_choose):

  #stitch together denoised slices (tyx) into original size (tzyx, with singleton z)

    pth_tif_write = pth_tif_read[:-4] + 'dcdn_.tif'
    
    if os.path.isfile(pth_tif_write):
    
        print("\n\n\nWARNING, SKIPPING do_stitch BECAUSE pth_tif_write ALREADY EXISTS - DELETE IT TO CREATE A NEW ONE")
    
    else:

        print("\n\n\nwriting denoised tifs for carls old project, if you're not carl there's a problem")

        dims_pre_denoise = md['dims']

        goal_trial = int(fn_prefix.split('_')[2])
        actual_z_size = 1

        if denoise_volume == 1:
            pretend_trial = '1' # pretend they all come from same trial
            dnfolder = fn_prefix.split('_')[0] + '_' + fn_prefix.split('_')[1] + '_' + pretend_trial + '_all/' #for these non-volumetric grad recordings, if do_volume == 1, rename all trials "1", and each trial a different z slice
            pth_trainset_all = natsorted(glob.glob(pth_denoising + '/' + dnfolder))

        else:

            pth_trainset_all = natsorted(glob.glob(os.path.join(pth_denoising, fn_prefix + '_*/')))
            fldr_exclude = fn_prefix.split('_')[0] + '_' + fn_prefix.split('_')[1] + '_' + pretend_trial + '_al*/' 
            pth_trainset_all = list(set(pth_trainset_all) - set(natsorted(glob.glob(fldr_exclude)))) #exclude the "all" folders when denoise_volume==1

        countz = 0
        for pth_trainset in pth_trainset_all:

            
            fldr_chex = natsorted(glob.glob(os.path.join(pth_trainset, 'DataFolderIs_*')))
            for fcxi,fcx in enumerate(fldr_chex):
                if fcxi!=len(fldr_chex)-1:
                    print("deleting this denoise test folder from old run")
                    print(fcx)
                    shutil.rmtree(fcx)


            fldr_outtiff_all = natsorted(glob.glob(os.path.join(pth_trainset, 'DataFolderIs_*', 'E_*'))) #for all epochs that were used for denoising, organize tif files into single folder in 'denoised' folder
            for fldr_outtiff in fldr_outtiff_all:
                if fnmatch.fnmatch(fldr_outtiff.split('/')[-1], 'E_' + "{:02d}".format(denoise_epoch_choose) + '_Iter_*'):
                    pth_denoised_singles = natsorted(glob.glob(os.path.join(fldr_outtiff, '*output.tif')))

                    Y = np.zeros((dims_pre_denoise[0], dims_pre_denoise[2], dims_pre_denoise[3], actual_z_size)) #t y x z
                    print(dims_pre_denoise[1])
                    for fni,f in enumerate(pth_denoised_singles): #loop over each denoised z slice and reassemble into array matching shape of original 4d volume
                        if denoise_volume == 1:
                            trial = int(f.split('/')[-1].split('_')[3]) + 1 #filename z position is actual trial if denoise_volume was==1, add one bc they were made zero index, but original trial is one indexed
                        else:
                            trial = int(f.split('/')[-1].split('_')[2]) #filename trial is in nortmal trial position

                        if trial == goal_trial:
                            countz = countz + 1
                            print(f)
                            sliceind = 0 #always zero for these non-volumetric old recordings 
                            Ynew = imread(f)
                            if Ynew.dtype!='uint16':
                                print("warning, converting type from " + str(Ynew.dtype))
                                Ynew = Ynew.astype('uint16')
                                if np.min(Y)<0 or np.max(Y) > 65535:
                                    raise Exception("denoising have operated on uint16 for this pipeline, or adjust it")
                            print(Ynew.dtype)
                            print(sliceind)
                            Y[:,:,:,sliceind] = Ynew

                            mnmv = np.min(Y)
                            Y = Y - mnmv #make nonnegative before writing to uint16
                            print("MIN AFTER DENOISING " + str(mnmv))
                                
                            Y = Y.astype('uint16')
                            
                            Y = np.transpose(Y, (0, 3, 1, 2)) #tzyx
                            print(Y.shape)
                            Y = Y.reshape(dims_pre_denoise[0] * actual_z_size, dims_pre_denoise[2], dims_pre_denoise[3]) #(tz)yx
                            print(Y.shape)
                            imwrite(pth_tif_write, Y.squeeze(), bigtiff=True, photometric='minisblack') #write the registered movie as tif for use in matlab, and caiman extraction below


                    if countz != dims_pre_denoise[1]:
                        raise Exception("more or less than one slice present")



def rename_files(pth_datafile, fname, fn_prefix, pth_fldr):

    fname_rename = fn_prefix + '_raw_.' + fname[-3:]
    pth_datafile_rename = pth_fldr + fname_rename
    print("RENAMING FILE \n" + pth_datafile + "\nTO \n" + pth_datafile_rename)
    os.rename(pth_datafile, pth_datafile_rename) 
    
    pth_badmat = glob.glob(pth_datafile[:-4] + '.mat', recursive=True) #remove any mat files from old filename pattern
    if pth_badmat and re.search('trial', fname):
        print("REMOVING THE FOLLOWING MAT FILE WITH OLD NAMING PATTERN \n" + pth_badmat[0])
        os.remove(pth_badmat[0])
    pth_datafile = pth_datafile_rename
    fname = fname_rename

    return (pth_datafile, fname)



def mat2tif_carls_old_project(pth_datafile):

    print("converting mat to tif for carls old project, if you're not carl there's a problem")
    
    if os.path.isfile(pth_datafile[:-4] + '.tif'):
        raise Exception("ERROR: YOU SHOULD ONLY BE IN THIS FUNCTION IF THERE IS NO TIF")
    mat = mat73.loadmat(pth_datafile)
    Y = mat['stackRaw_pmc'] # Y = mat['stackRaw_mc']
    mnmv = np.min(Y)
    Y = Y - mnmv #make movie nonnegative (not sure this is necessary)
    print("MIN OF STACKRAW_PMC MAT FILE " + str(mnmv))
    Y = np.transpose(Y, (2, 0, 1)) #put in order t y x (not t x y) #stackraw_mc may be flipped relative to stackraw pmc
    pth_datafile = pth_datafile[:-4] + '.tif'
    imwrite(pth_datafile, Y.astype('uint16'), bigtiff=True, photometric='minisblack') #write as t x y z (singleton z at end)
    mat_file_shape = Y.shape
    
    return mat_file_shape
            


def copy_files_scopa(do_copyfiles, do_separate, do_denoise, do_stitch, pth_tif_read, pth_md, pth_fldr_copydest_prefix, pth_fldr):


    fldr_name = os.path.basename(os.path.abspath(pth_fldr))
    pth_fldr_copydest = pth_fldr_copydest_prefix + fldr_name
    if pth_fldr_copydest[-1] == '/': 
        pth_fldr_copydest = pth_fldr_copydest[:-1]
    if pth_fldr[-1] != '/': 
        pth_fldr = pth_fldr + '/'

    if do_copyfiles==1: #copy from storage server to O2 (unless do_denoise or do_stitch, since they only use files in O2 denoising folder, whcih is not copied in or out of O2)
        
        if do_denoise or do_stitch:
            print("\n\n\nnot copying anything because do_denoise or do_stitch is true, and they use files in denoising folder")
        else:
            print("\n\n\ncopying the following files: \n" + pth_tif_read + "\n" + pth_md + "\nfrom storage server into the following O2 directory: \n" + pth_fldr_copydest)

            Path(pth_fldr_copydest).mkdir(parents=True, exist_ok=True)
            shutil.copy2(pth_tif_read, pth_fldr_copydest)
            shutil.copy2(pth_md, pth_fldr_copydest)

    elif do_copyfiles==2: #copy from O2 to storage server (unless do_separate, since new files are sent to O2 denoising folder, whcih is not copied in or out of O2)
        
        if do_separate:
            print("\n\n\nnot copying anything because do_separate is true, and files created by do_separate are in denoising folder")
        else:
            print("\n\n\ncopying anything new from the O2 folder: \n" + pth_fldr + "\ninto the storage server folder: \n" + pth_fldr_copydest)

            for pth_src_tmp in Path(pth_fldr).glob('**/*'):  #this will copy hidden files too
                pth_src = str(pth_src_tmp)
                if os.path.isfile(pth_src): #only files, no directories (will create parent dirs if necessary below)
                    pp = Path(pth_src).parts #split path
                    split_index = pp.index(fldr_name) + 1 #find index to split source and destination (in case it's within a subdir)
                    pth_dest_suffix = os.path.join(*pp[split_index:]) #join to make suffix
                    pth_dest = pth_fldr_copydest + '/' + pth_dest_suffix #append suffix to source path
                    os.makedirs(os.path.dirname(pth_dest), exist_ok=True) #in case it's within a subdir, create any missing parent dir, if they don't exist  
                    if (not os.path.exists(pth_dest)) or (os.path.exists(pth_dest) and abs(os.stat(pth_src).st_mtime - os.stat(pth_dest).st_mtime) > 1) :
                        try:
                            shutil.copy2(pth_src, pth_dest)
                        except shutil.SameFileError:
                            print("same file error error occurred while copying this file: \n" + pth_src + "\nto this path \n:" + pth_dest)
                        except PermissionError:
                            print("permission error occurred while copying this file: \n" + pth_src + "\nto this path \n:" + pth_dest)
                        except:
                            print("Unknown error occurred while copying this file: \n" + pth_src + "\nto this path \n:" + pth_dest)



def ordinal(n: int):
    if 11 <= (n % 100) <= 13:
        suffix = 'th'
    else:
        suffix = ['th', 'st', 'nd', 'rd', 'th'][min(n % 10, 4)]
    return str(n) + suffix



def tracefunc(frame, event, arg, indent=[0]): # can get line number with frame.f_lineno
  
  strmtch = '/Users/wienecke/mambaforge/envs/caiman/lib/python3.10/site-packages/caiman' 
  if event == "call":
      if strmtch in frame.f_code.co_filename:
        indent[0] += 2
        print("-" * indent[0] + "> call function", frame.f_code.co_filename)
        print("-" * indent[0] + "> call function", frame.f_code.co_name)
      
  elif event == "return":
      if strmtch in frame.f_code.co_filename:
        print("<" + "-" * indent[0], "exit function", frame.f_code.co_name)
        print("<" + "-" * indent[0], "exit function", frame.f_code.co_filename)
        indent[0] -= 2

  return tracefunc