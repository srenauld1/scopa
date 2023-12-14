
import numpy as np
import glob
from natsort import natsorted
import fnmatch
import os
from tifffile.tifffile import imwrite, imread
import shutil
from vis import im_montage, plot_gif


def stitch_registered_z_slices(pth_tif_reg, dims, do_plots):


  pth_tif_all = natsorted(glob.glob(pth_tif_reg[:-4] + '*_z_.tif'))

  Y = np.zeros(dims) #t z y x 

  countz = 0
  for f in pth_tif_all:
      countz = countz + 1
      print(f)
      sliceind = int(f.split('_')[-2])
      Ynew = imread(f)
      if Ynew.dtype!='uint16':
          print("warning, converting type from " + str(Ynew.dtype))
          Ynew = Ynew.astype('uint16')
          if np.min(Y)<0 or np.max(Y) > 65535:
            raise Exception("reg have operated on uint16 for this pipeline, or adjust it")
      print(Ynew.dtype)
      print(sliceind)
      print("each slice min should not be zero, this slice min is:" + str(np.min(Ynew)))
      Y[:,sliceind,:,:] = Ynew # was Y[:,:,:,sliceind] = Ynew

  if countz != dims[1]:
      raise Exception("not all slices present")

  mnmv = np.min(Y)
  Y = Y - mnmv #make nonnegative before writing to uint16
  print("MIN AFTER REGISTRATION " + str(mnmv))
  
  if Y.dtype!='uint16': #was  Y = Y.astype('uint16')
      raise Exception("not uint16")
  
  print(Y.shape)
  
  if do_plots:
      mxmv = np.max(Y)
      #im_montage(Ynew[10,:,:,:], vmin=mnmv, vmax=mxmv) #view montage to check registration
      plot_gif(Y, indst = slice(0, 20, 1))  #view gif to check registration, can pass xyzt indices, otherwise will do all indices for each 


  Y = Y.reshape(dims[0] * dims[1], dims[2], dims[3]) #(tz)yx
  print(Y.shape)
  #imwrite(pth_out, Y.squeeze()) #squeeze was just for non-volumetric (old project), does it change header, slowing read dramatically?
  imwrite(pth_tif_reg, Y) #write the registered movie as tif for use in matlab, and caiman extraction below

  for f in pth_tif_all:
     os.remove(f)


def separate_z_slices_before_denoising(pth_input, fn_prefix, pth_denoising, dims, denoise_volume):

    Y = imread(pth_input)
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
        pth_tif_pdn = pth_trainset + '/' + tifname
        if os.path.exists(pth_trainset) and (zii==0 or denoise_volume==0): #if you're on the first zii (regardless of denoise_volume value), or for all zii if denoise_volume==0
            shutil.rmtree(pth_trainset) #REMOVE any existing training folder before training, to ensure models don't get mixed (until "resume training" functionality is written)
        if not os.path.exists(pth_trainset): #don't make this "else" connected to "if" above because you have to evaluate it
            os.mkdir(pth_trainset)
        imwrite(pth_tif_pdn, Ynew, photometric = 'minisblack' ) #put the tif in the folder deepcad looks to for training data


def separate_z_slices_before_denoising_carls_old_project(pth_input, fn_prefix, pth_denoising, dims, denoise_volume):

    Y = imread(pth_input)
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
        pth_tif_pdn = pth_trainset + '/' + tifname
        
        # for old project cannot remove folder because it saves from separate runs of register        
        # if os.path.exists(pth_trainset) and (zii==0 or denoise_volume==0): #if you're on the first zii (regardless of denoise_volume value), or for all zii if denoise_volume==0
        #     shutil.rmtree(pth_trainset) #REMOVE any existing training folder before training, to ensure models don't get mixed (until "resume training" functionality is written)
        
        if not os.path.exists(pth_trainset): #don't make this "else" connected to "if" above because you have to evaluate it
            os.mkdir(pth_trainset)
        imwrite(pth_tif_pdn, Ynew, photometric = 'minisblack' ) #put the tif in the folder deepcad looks to for training data


def stitch_denoised_slices(pth_denoising, fn_prefix, pth_out, dims_pre_denoise, denoise_volume, epoch_choose):

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
      
      if fnmatch.fnmatch(fldr_outtiff.split('/')[-1], 'E_' + "{:02d}".format(epoch_choose) + '_Iter_*'):
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
  
  if Y.dtype!='uint16': #was  Y = Y.astype('uint16')
    raise Exception("not uint16")
  
  Y = np.transpose(Y, (0, 3, 1, 2)) #tzyx
  print(Y.shape)
  Y = Y.reshape(dims_pre_denoise[0] * dims_pre_denoise[1], dims_pre_denoise[2], dims_pre_denoise[3]) #(tz)yx
  print(Y.shape)
  #imwrite(pth_out, Y.squeeze()) #squeeze was just for non-volumetric (old project), does it change header, slowing read dramatically?
  imwrite(pth_out, Y) #write the registered movie as tif for use in matlab, and caiman extraction below


def stitch_denoised_slices_carls_old_project(pth_denoising, fn_prefix, pth_out, dims_pre_denoise, denoise_volume, epoch_choose):

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
      if fnmatch.fnmatch(fldr_outtiff.split('/')[-1], 'E_' + "{:02d}".format(epoch_choose) + '_Iter_*'):
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
                 
                if Y.dtype!='uint16': #was  Y = Y.astype('uint16')
                  raise Exception("not uint16")
              
                Y = np.transpose(Y, (0, 3, 1, 2)) #tzyx
                print(Y.shape)
                Y = Y.reshape(dims_pre_denoise[0] * actual_z_size, dims_pre_denoise[2], dims_pre_denoise[3]) #(tz)yx
                print(Y.shape)
                imwrite(pth_out, Y.squeeze()) #write the registered movie as tif for use in matlab, and caiman extraction below


        if countz != dims_pre_denoise[1]:
            raise Exception("more or less than one slice present")


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