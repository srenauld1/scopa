
import numpy as np
import glob
import re
import os
from tifffile.tifffile import imwrite, imread
import mat73
from denoising_score import denoising_score



def rename_files(pth_readfile, fname, fn_prefix, pth_fldr, pth_hires):

    if re.search('trial', fname) or re.search('stackraw', fname):
        fname_rename = fn_prefix + '_raw_.' + fname[-3:]
        pth_readfile_rename = pth_fldr + fname_rename
        print("RENAMING FILE \n" + pth_readfile + "\nTO \n" + pth_readfile_rename)
        os.rename(pth_readfile, pth_readfile_rename) 
        
        pth_badmat = glob.glob(pth_readfile[:-4] + '.mat') #remove any mat files from old filename pattern
        if pth_badmat and re.search('trial', fname):
            print("REMOVING THE FOLLOWING MAT FILE WITH OLD NAMING PATTERN \n" + pth_badmat[0])
            os.remove(pth_badmat[0])
        
        pth_readfile = pth_readfile_rename
        fname = fname_rename
    

    if pth_hires:
        fn_hires = os.path.basename(pth_hires)
        if re.search(fn_prefix.split('_')[0] + '-' + fn_prefix.split('_')[1], fn_hires):
            fn_hires_rename = fn_hires.replace('-', '_')
            pth_hires_rename = pth_fldr + fn_hires_rename
            print("RENAMING FILE \n" + pth_hires + "\nTO \n" + pth_hires_rename)
            os.rename(pth_hires, pth_hires_rename) 
        
            pth_hires = pth_hires_rename

        pth_badmat = glob.glob(pth_hires[:-4] + '.mat') #remove any mat files from old filename pattern
        if pth_badmat:
            print("REMOVING THE FOLLOWING MAT FILE WITH OLD NAMING PATTERN \n" + pth_badmat[0])
            os.remove(pth_badmat[0])
        
    
        

    return (pth_readfile, fname, pth_hires)


def mat2tif_scopa(pth_readfile, carls_old_project):

    print("converting mat to tif for carls old project, if you're not carl there's a problem")
    
    pth_tif_write = pth_readfile[:-4] + '.tif'

    if os.path.isfile(pth_readfile[:-4] + '.tif'):
        raise Exception("ERROR: YOU SHOULD ONLY BE IN THIS FUNCTION IF THERE IS NO TIF")
    mat = mat73.loadmat(pth_readfile)
    
    if carls_old_project:
        Y = mat['stackRaw_pmc'] # Y = mat['stackRaw_mc']
    else:
        Y = mat['stack'] 

    Y = Y.astype('float32')
    mnmv = np.min(Y).astype('float32')
    Y -= mnmv #make movie nonnegative (not sure this is necessary)
    print("MIN OF MAT FILE " + str(mnmv))
    if np.max(Y) > 65535:
        raise Exception("clipping will occur when converting to uint16")
    Y = Y.astype('uint16')
    Yshape = Y.shape
    print(Yshape)
    
    if len(Yshape)==3:# or Y.shape[3]==1: #transpose into tzyx, collapse t and z (if z exists) 
        if carls_old_project:
            Y = np.transpose(Y, (2, 0, 1)) # from yxt to tzyx . . . for carls_old_project, stackraw_mc may be flipped relative to stackraw pmc, so may be xyt, which would need np.transpose(Y, (2, 1, 0))
        else:
            Y = np.transpose(Y, (2, 0, 1)) #from yxt to tzyx
    else:
        Y = np.transpose(Y, (3, 2, 0, 1)).reshape(Yshape[3] * Yshape[2], Yshape[0], Yshape[1]) #from yxzt to tzyx 
    
    imwrite(pth_tif_write, Y, bigtiff=True, photometric='minisblack') #write the registered movie as tif (uint16) for use in matlab, and caiman extraction below
    mat_file_shape = Y.shape
    
    return mat_file_shape
            

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