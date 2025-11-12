
import numpy as np
import glob
import re
import os
from tifffile.tifffile import imwrite, imread
import mat73



def stack_reshape_transpose_clip_zero_type(stack, dims, clip=0):

    stack = stack.reshape(dims[0], dims[1], dims[2], dims[3])
    stack = np.transpose(stack, (0, 3, 2, 1)) #put in order t x y z 
    
    if isinstance(clip, int):
        clip = [clip]
    if any(el for el in clip):
        if clip==[-1]: #if you use autoread offset and subtract offset in scanimage, and your stack is not extremely noisy, negatives should be mostly noise and can be removed
            stack[stack<0] = 0
        elif len(clip)==2:
            if clip[0]==-1:
                minnew = 0
            else:
                minnew = np.quantile(stack, clip[0]) #index minnew into chan in case you want to see these values for each channel
            maxnew = np.quantile(stack, clip[1]) #index maxnew into chan in case you want to see these values for each channel
            idx = stack<minnew
            stack[idx] = minnew
            idx = stack>maxnew
            stack[idx] = maxnew
        else:
            raise Exception("to apply clipping, clip must be 2 element list or [-1], or to skip clipping, clip should be [0] or []")

    mnmv = np.min(stack)
    stack -= mnmv #make movie nonnegative then convert to uint16 (not sure this matters for caiman, but useful further ahead)
    stack = stack.astype('uint16')
    print("MIN BEFORE MOTION CORRECTION " + str(mnmv))
    
    return stack


def rename_original_scanimage_files(pth_readfile, fname, fn_prefix, fldr, suffixchar_raw):


    if re.search('trial', fname) or re.search('stackraw', fname):
        fname_rename = fn_prefix + '_' + suffixchar_raw + '_.' + fname[-3:]
        pth_readfile_rename = fldr + fname_rename
        print("RENAMING FILE \n" + pth_readfile + "\nTO \n" + pth_readfile_rename)
        os.rename(pth_readfile, pth_readfile_rename) 
        
        pth_badmat = glob.glob(pth_readfile[:-4] + '.mat') #remove any mat files from old filename pattern
        if pth_badmat and re.search('trial', fname):
            print("REMOVING THE FOLLOWING MAT FILE WITH OLD NAMING PATTERN \n" + pth_badmat[0])
            os.remove(pth_badmat[0])
        
        pth_readfile = pth_readfile_rename
        fname = fname_rename

    return (pth_readfile, fname)


def mat2tif(pth_readfile, carls_old_project):

    print("converting mat to tif for carls old project, if you're not carl there's a problem")
    
    pth_tif_write = pth_readfile[:-4] + '.tif'

    if os.path.isfile(pth_readfile[:-4] + '.tif'):
        raise Exception("ERROR: YOU SHOULD ONLY BE IN THIS FUNCTION IF THERE IS NO TIF")
    mat = mat73.loadmat(pth_readfile)
    
    if carls_old_project:
        stack = mat['stackRaw_pmc'] # stack = mat['stackRaw_mc']
    else:
        stack = mat['stack'] 

    stack = stack.astype('float32')
    mnmv = np.min(stack).astype('float32')
    stack -= mnmv #make movie nonnegative (not sure this is necessary)
    print("MIN OF MAT FILE " + str(mnmv))
    if np.max(stack) > 65535:
        raise Exception("clipping will occur when converting to uint16")
    stack = stack.astype('uint16')
    Yshape = stack.shape
    print(Yshape)
    
    if len(Yshape)==3:# or stack.shape[3]==1: #transpose into tzyx, collapse t and z (if z exists) 
        if carls_old_project:
            stack = np.transpose(stack, (2, 0, 1)) # from yxt to tzyx . . . for carls_old_project, stackraw_mc may be flipped relative to stackraw pmc, so may be xyt, which would need np.transpose(stack, (2, 1, 0))
        else:
            stack = np.transpose(stack, (2, 0, 1)) #from yxt to tzyx
    else:
        stack = np.transpose(stack, (3, 2, 0, 1)).reshape(Yshape[3] * Yshape[2], Yshape[0], Yshape[1]) #from yxzt to tzyx 
    
    imwrite(pth_tif_write, stack, bigtiff=True, photometric='minisblack') #write the registered movie as tif (uint16) for use in matlab, and caiman extraction below
    stack_shape_mat = stack.shape
    
    return stack_shape_mat
            

def ordinal(n: int):
    if 11 <= (n % 100) <= 13:
        suffix = 'th'
    else:
        suffix = ['th', 'st', 'nd', 'ord', 'th'][min(n % 10, 4)]
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