
import numpy as np
import glob

from caiman_draw_fov import select_fov
from caiman_vis_custom import im_montage 
from ast import literal_eval

def crop_fov(Y, fov_region, pth_tif_reg, dims_spacetime_original_noflyback):

    try:
        
        fn_croplim_pattern = pth_tif_reg[0][:-4] + fov_region + '_*_.npy' #find file matching fov subregion with some crop lim 
        fn_croplim = glob.glob(fn_croplim_pattern)
        if len(fn_croplim) > 1:
            raise Exception("too many crop files")
        with open(fn_croplim[0], 'rb') as fnc:
            croplim = np.load(fnc)
        limits_str = fov_region + '_' + str(croplim[0]) + '_' + str(croplim[1]) + '_' + str(croplim[2]) + '_' + str(croplim[3]) + '_' + str(croplim[4]) + '_' + str(croplim[5]) + '_' + str(croplim[6]) + '_' + str(croplim[7])

    except:
        
        Ymt = np.mean(Y, axis = 0)
        im_montage(Ymt)
        print("what z slices do you want to keep? consider keeping first as padding if cells abut z edges")
        zlimits = literal_eval(input ("choose z limits, format (firstframe,lastframe) one-indexed: "))
        Ymtz = np.mean(Ymt[:,:,zlimits[0]:zlimits[1]], axis = 2)
        ylimits, xlimits = select_fov(Ymtz)
        tlimits = (1, dims_spacetime_original_noflyback[0])
        croplim = np.asarray((tlimits + xlimits + ylimits + zlimits)).astype(int) #make them 1-indexed for matlab later 
        limits_str = fov_region + '_' + str(croplim[0]) + '_' + str(croplim[1]) + '_' + str(croplim[2]) + '_' + str(croplim[3]) + '_' + str(croplim[4]) + '_' + str(croplim[5]) + '_' + str(croplim[6]) + '_' + str(croplim[7])
        fn_crop_lim = pth_tif_reg[0][:-4] + limits_str + '_.npy'
        with open(fn_crop_lim, 'wb') as fncrop:
            np.save(fncrop, croplim)

    slt = slice(croplim[0]-1, croplim[1], 1) #croplim are 1-indexed, and the second/upper is not included  
    slx = slice(croplim[2]-1, croplim[3], 1) # slice(40, 181, 1) 
    sly = slice(croplim[4]-1, croplim[5], 1) #slice(6, 51, 1)
    slz = slice(croplim[6]-1, croplim[7], 1)  #slice(1, 9, 1) 
    indices_crop = [slt, slx, sly, slz]
    Y = Y[tuple(indices_crop)]

    return Y, limits_str