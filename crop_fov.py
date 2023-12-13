

import numpy as np
import glob
from vis import im_montage 
import matplotlib.pyplot as plt
from matplotlib.widgets  import RectangleSelector
from ast import literal_eval



def select_fov_xy(img):

    fig, ax = plt.subplots()

    ax.imshow(img.T)

    def line_select_callback(eclick, erelease):
        x1, y1 = eclick.xdata, eclick.ydata
        x2, y2 = erelease.xdata, erelease.ydata

        rect = plt.Rectangle( (min(x1,x2),min(y1,y2)), np.abs(x1-x2), np.abs(y1-y2) )
        ax.add_patch(rect)

    props = dict(facecolor='blue', alpha=0.2)
    rs = RectangleSelector(ax, line_select_callback, interactive=True, 
                            props=props, drag_from_anywhere=True,
                            use_data_coordinates=True)


    input("Press Enter to continue...")
    plt.show 
    ylimits = tuple(np.round((rs.corners[1][0], rs.corners[1][-1])))
    xlimits = tuple(np.round((rs.corners[0][0], rs.corners[0][2])))

    return ylimits, xlimits




def crop_fov(Y, region_extraction, pth_prefix, dims):
    
    #using interactive plots, choose z slices (user input based on plot 1) and define/draw xy rectangle (user draw on plot 2) to create cuboid fov to keep for extraction 
    
    try:
        
        fn_croplim_pattern = pth_prefix + '_' + region_extraction + '*_croplim_.npy' #find file matching fov subregion with some crop lim 
        fn_croplim = glob.glob(fn_croplim_pattern)
        if len(fn_croplim) > 1:
            raise Exception("too many crop files")
        with open(fn_croplim[0], 'rb') as fnc:
            croplim = np.load(fnc)
        limits_str = str(croplim[0]) + '_' + str(croplim[1]) + '_' + str(croplim[2]) + '_' + str(croplim[3]) + '_' + str(croplim[4]) + '_' + str(croplim[5]) + '_' + str(croplim[6]) + '_' + str(croplim[7])

    except:
        
        if region_extraction == 'fullfov':
       
            croplim = np.asarray((1, dims[0], 1, dims[3], 1, dims[2], 1, dims[1])).astype(int) 
            limits_str = '1_' + str(dims[0]) + '_1_' + str(dims[3]) + '_1_' + str(dims[2]) + '_1_' + str(dims[1])
       
        else:
       
            Ymt = np.mean(Y, axis = 0)
            if Ymt.shape[-1]==1: #only do z slice selection if the movie is volumetric 4d
                zlimits = (1,1)
                Ymtz = np.mean(Ymt, axis = 2)
            else:
                im_montage(Ymt) #pass whole Ymt min and max as vmin and vmax if you don't want each slice normalized
                print("what z slices do you want to keep? note: each slice normalized to boost contrast for this plot \
                      Consider keeping first as padding if cells abut z edges \
                      WARNING, 3D EXTRACTION REQUIRES AT LEAST 3 ELEMENTS IN EACH DIMENSION X Y and Z, \
                      OR you must REWRITE/ADAPT binary_closing IN CAIMAN'S THRESHOLD_COMPONENTS")
                zlimits = literal_eval(input ("choose z limits (one-indexed) using format (firstframe,lastframe): "))
                Ymtz = np.mean(Ymt[:,:,zlimits[0]-1:zlimits[1]-1], axis = 2)
            ylimits, xlimits = select_fov_xy(Ymtz)
            tlimits = (1, dims[0])
            croplim = np.asarray((tlimits + xlimits + ylimits + zlimits)).astype(int) 
            
        limits_str = str(croplim[0]) + '_' + str(croplim[1]) + '_' + str(croplim[2]) + '_' + str(croplim[3]) + '_' + str(croplim[4]) + '_' + str(croplim[5]) + '_' + str(croplim[6]) + '_' + str(croplim[7])
        fn_crop_lim = pth_prefix + '_' + region_extraction + '_' + limits_str + '_croplim_.npy'
        with open(fn_crop_lim, 'wb') as fncrop:
            np.save(fncrop, croplim)

    slt = slice(croplim[0]-1, croplim[1], 1) # convert to zero-indexing, but slice does not include second index so do not subtract one on the 2nd index 
    slx = slice(croplim[2]-1, croplim[3], 1) 
    sly = slice(croplim[4]-1, croplim[5], 1) 
    slz = slice(croplim[6]-1, croplim[7], 1) 
    indices_crop = [slt, slx, sly, slz]
    Y = Y[tuple(indices_crop)]

    return Y, limits_str
