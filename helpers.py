
import numpy as np
import glob

from caiman_vis_custom import im_montage 
from ast import literal_eval

import matplotlib.pyplot as plt
from matplotlib.widgets  import RectangleSelector

from ScanImageTiffReader import ScanImageTiffReader
from ast import literal_eval
import re
import scipy.io as sio
from numpy.core.records import fromarrays



def select_fov(img):

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




def crop_fov(Y, fov_region, pth_img, dims):

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
        print("what z slices do you want to keep? Consider keeping first as padding if cells abut z edges")
        zlimits = literal_eval(input ("choose z limits (one-indexed) using format (firstframe,lastframe): "))
        Ymtz = np.mean(Ymt[:,:,zlimits[0]:zlimits[1]], axis = 2)
        ylimits, xlimits = select_fov(Ymtz)
        tlimits = (1, dims[0])
        croplim = np.asarray((tlimits + xlimits + ylimits + zlimits)).astype(int) 
        limits_str = fov_region + '_' + str(croplim[0]) + '_' + str(croplim[1]) + '_' + str(croplim[2]) + '_' + str(croplim[3]) + '_' + str(croplim[4]) + '_' + str(croplim[5]) + '_' + str(croplim[6]) + '_' + str(croplim[7])
        fn_crop_lim = pth_img[0][:-4] + fov_region + '_croplim_.npy'
        with open(fn_crop_lim, 'wb') as fncrop:
            np.save(fncrop, croplim)

    slt = slice(croplim[0]-1, croplim[1], 1) # convert to zero-indexing, but slice does not include second index so do not subtract one on the 2nd index 
    slx = slice(croplim[2]-1, croplim[3], 1) 
    sly = slice(croplim[4]-1, croplim[5], 1) 
    slz = slice(croplim[6]-1, croplim[7], 1) 
    indices_crop = [slt, slx, sly, slz]
    Y = Y[tuple(indices_crop)]

    return Y, limits_str


def read_save_metadata(pth_datafile, pth_md):

    # use ScanImageTiffReader to read metadata (strange parsing because scanimage tif headers are not saved as json)
    meta = ScanImageTiffReader(pth_datafile).metadata()   
    mdt = {}
    mdt['numvol'] = int(re.findall( 'actualNumVolumes = (.*)', meta)[0])
    mdt['numslice_withflyback'] = int(re.findall( 'numFramesPerVolumeWithFlyback = (.*)', meta)[0])
    mdt['numslice'] = int(re.findall( 'actualNumSlices = (.*)', meta)[0])
    mdt['xpix'] = int(re.findall( 'pixelsPerLine = (.*)', meta)[0])
    mdt['ypix'] = int(re.findall( 'linesPerFrame = (.*)', meta)[0])
    mdt['flyback'] = mdt['numslice_withflyback'] - mdt['numslice']
    mdt['dims'] = [mdt['numvol'], mdt['numslice_withflyback'] - mdt['flyback'], mdt['ypix'], mdt['xpix']]
    fovtmp = literal_eval(re.findall( 'imagingFovUm = (.*)', meta)[0].replace(" ",",").replace(";",","))
    mdt['xfov'] = abs(fovtmp[0]) + abs(fovtmp[2])
    mdt['yfov'] = abs(fovtmp[1]) + abs(fovtmp[3])
    mdt['zwid'] = int(re.findall( 'actualStackZStepSize = (.*)', meta)[0])
    mdt['zstartpos'] = literal_eval(re.findall( 'zsRelative = (.*)', meta)[0].replace(";",","))
    mdt['zfov'] = mdt['zstartpos'][-1] + mdt['zwid'] - mdt['zstartpos'][0]
    mdt['framerate'] = float(re.findall( 'scanFrameRate = (.*)', meta)[0])
    mdt['volrate'] = float(re.findall( 'scanVolumeRate = (.*)', meta)[0])

    md = fromarrays( [ mdt['numvol'], mdt['numslice_withflyback'], mdt['numslice'], mdt['xpix'], \
        mdt['ypix'], mdt['flyback'], mdt['xfov'], mdt['yfov'], \
        mdt['zwid'], mdt['zfov'], mdt['framerate'], mdt['volrate'] ], \
        names = ['numvol', 'numslice_withflyback', 'numslice', 'xpix', 'ypix', 'flyback', \
            'xfov', 'yfov', 'zwid', 'zfov', 'framerate', 'volrate' ] )

    sio.savemat(pth_md[0], {'md': md}) #save for matlab part of pipeline 
    
    return mdt

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