
import numpy as np
import glob

from caiman_vis_custom import im_montage 
from ast import literal_eval

import matplotlib
import matplotlib.pyplot as plt
from matplotlib.widgets  import RectangleSelector
from matplotlib.animation import FuncAnimation, PillowWriter


def select_fov(img):

    fig, ax = plt.subplots()

    ax.imshow(img.T)

    def line_select_callback(eclick, erelease):
        x1, y1 = eclick.xdata, eclick.ydata
        x2, y2 = erelease.xdata, erelease.ydata

        rect = plt.Rectangle( (min(x1,x2),min(y1,y2)), np.abs(x1-x2), np.abs(y1-y2) )
        ax.add_patch(rect)

    # rs = RectangleSelector(ax, line_select_callback,
    #                        drawtype='box', useblit=False, button=[1], 
    #                        minspanx=5, minspany=5, spancoords='pixels', 
    #                        interactive=True)
    props = dict(facecolor='blue', alpha=0.2)
    rs = RectangleSelector(ax, line_select_callback, interactive=True, 
                            props=props, drag_from_anywhere=True,
                            use_data_coordinates=True)


    input("Press Enter to continue...")
    plt.show 
    ylimits = tuple(np.round((rs.corners[1][0], rs.corners[1][-1])))
    xlimits = tuple(np.round((rs.corners[0][0], rs.corners[0][2])))

    return ylimits, xlimits




def crop_fov(Y, fov_region, pth_img, dims_spacetime_original_noflyback):

    try:
        
        fn_croplim_pattern = pth_img[0][:-4] + fov_region + '_croplim_.npy' #find file matching fov subregion with some crop lim 
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
        fn_crop_lim = pth_img[0][:-4] + fov_region + '_croplim_.npy'
        with open(fn_crop_lim, 'wb') as fncrop:
            np.save(fncrop, croplim)

    slt = slice(croplim[0]-1, croplim[1], 1) #croplim are 1-indexed, and the second/upper is not included  
    slx = slice(croplim[2]-1, croplim[3], 1) # slice(40, 181, 1) 
    sly = slice(croplim[4]-1, croplim[5], 1) #slice(6, 51, 1)
    slz = slice(croplim[6]-1, croplim[7], 1)  #slice(1, 9, 1) 
    indices_crop = [slt, slx, sly, slz]
    Y = Y[tuple(indices_crop)]

    return Y, limits_str



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