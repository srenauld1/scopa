

import numpy as np
import json
import glob
from im_montage import im_montage 
import matplotlib.pyplot as plt
from matplotlib.widgets  import RectangleSelector
from ast import literal_eval
from pthmakepy import getpathscopa


def stackcrop(stack, rgname, pth_prefix, dims):
    
    #using interactive plots, choose z slices (user input based on plot 1) and define/draw xy rectangle (user draw on plot 2) to create cuboid fov to keep for extraction 
    pth_scopa = getpathscopa()
    with open('/Users/wienecke/scopa/userdat.txt', 'r') as file:
        userdat = json.loads(file.read())
    pthsv = pth_scopa + 'opt_rg_' + userdat['scopausername'] + '_.txt'

    recid = pth_prefix.split('/')[-1]

    try:

        with open(pthrg[0], 'r') as file:
            rgall = json.loads(file.read())

        for key in rgall:
            if key==rgname:
                rg = rgall[key]
                break

    except:
        
        if rgname == 'none':
       
            rg = np.asarray((1, dims[0], 1, dims[3], 1, dims[2], 1, dims[1])).astype(int) 
       
        else:
       
            stackmnt = np.mean(stack, axis = 0)
            if stackmnt.shape[-1]==1: #only do z slice selection if the movie is volumetric 4d
                zlimits = (1,1)
                stackmntz = np.mean(stackmnt, axis = 2)
            else:
                im_montage(stackmnt) #pass whole stackmnt min and max as vmin and vmax if you don't want each slice normalized
                print("WHAT Z SLICES DO YOU WANT TO KEEP FOR RGNAME '" + rgname + "' \n" + \
                    "EACH SLICE NORMALIZED TO RAISE CONTRAST FOR THIS PLOT \n" \
                    "WARNING, EXTRACTION REQUIRES AT LEAST 3 ELEMENTS IN EACH DIMENSION, \n" \
                    "SO CHOOSE AT LEAST 3 Z SLICES FOR 3D EXTRACTION (IF extract_in_2d==0) \n" \
                    "OR YOU MUST REWRITE/ADAPT binary_closing IN CAIMAN'S THRESHOLD_COMPONENTS")

                zlimits = literal_eval(input ("CHOOSE Z LIMITS (ONE-INDEXED) FOR RGNAME '" + rgname + "' AS TUPLE, i.e. USING FORMAT (FIRSTFRAME,LASTFRAME): "))
                stackmntz = np.mean(stackmnt[:,:,zlimits[0]-1:zlimits[1]], axis = 2)
            ylimits, xlimits = draw_rect_xy(stackmntz)
            tlimits = (1, dims[0])
            rg = np.asarray((tlimits + xlimits + ylimits + zlimits)).astype(int) 
            
    limits_str = str(rg[0]) + '_' + str(rg[1]) + '_' + str(rg[2]) + '_' + str(rg[3]) + '_' + str(rg[4]) + '_' + str(rg[5]) + '_' + str(rg[6]) + '_' + str(rg[7])
    pthrg = pth_prefix + '_' + rgname + '_' + limits_str + '_croplim_.txt'

    rgt = {}
    rgt['y'] = ylimits
    rgt['x'] = xlimits
    rgt['z'] = zlimits
    rgt['t'] = tlimits
    rgt['c'] = (1,1)
    rgt['name'] = rgname
    rgt['id'] = [0]

    rgw = {  'y': rgt['y'],
            'x': rgt['x'],
            'z': rgt['z'],
            't': rgt['t'],
            'c': rgt['c'],
            'name': rgt['name'],
            'id': rgt['id']}


    with open('/Users/wienecke/scopa/opt_rg_cw_a_.txt', 'r') as file:
        rgall = json.loads(file.read())
    for key in rgall:
        if rgall[key]==rgw:
            raise Exception("rg exists already with a different name")

    rgall[rgnamenew] = rgw
    with open(pthrg, 'w') as file: 
        file.write(json.dumps(rgw, sort_keys=True, indent=4, separators=(',', ':'))) #if this file already existed/was loaded above, this will just save it again, if file didn't exist, this will create it

    slt = slice(rg[0]-1, rg[1], 1) # convert to zero-indexing, but slice does not include second index so do not subtract one on the 2nd index 
    slx = slice(rg[2]-1, rg[3], 1) 
    sly = slice(rg[4]-1, rg[5], 1) 
    slz = slice(rg[6]-1, rg[7], 1) 
    indices_crop = [slt, slx, sly, slz]
    stack = stack[tuple(indices_crop)]

    return stack, limits_str



def draw_rect_xy(img):

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


