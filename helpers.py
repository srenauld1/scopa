
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

from natsort import natsorted
import fnmatch
import os
from tifffile.tifffile import imwrite, imread
import shutil


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
                im_montage(Ymt)
                print("what z slices do you want to keep? Consider keeping first as padding if cells abut z edges \
                    WARNING, 3D EXTRACTION REQUIRES AT LEAST 3 ELEMENTS IN EACH DIMENSION X Y and Z, \
                    OR you must REWRITE/ADAPT binary_closing IN CAIMAN'S THRESHOLD_COMPONENTS")
                zlimits = literal_eval(input ("choose z limits (one-indexed) using format (firstframe,lastframe): "))
                Ymtz = np.mean(Ymt[:,:,zlimits[0]-1:zlimits[1]-1], axis = 2)
            ylimits, xlimits = select_fov(Ymtz)
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


def read_save_metadata(pth_datafile, pth_md, pth_md_npy, mat_file_shape = None):

    mdt = {}

    if mat_file_shape is None:

        # use ScanImageTiffReader to read metadata (strange parsing because scanimage tif headers are not saved as json)
        meta = ScanImageTiffReader(pth_datafile).metadata()   
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
    
    else:

        mdt['dims'] = [mat_file_shape[0], 1, mat_file_shape[1], mat_file_shape[2]] #z size (2nd dim) is 1 because old project is not volumetric 
        mdt['framerate'] = 20
        mdt['volrate'] = 20
        mdt['xpix'] = 256
        mdt['xfov'] = 74
        mdt['ypix'] = 128
        mdt['yfov'] = 37
        mdt['numslice'] = 1
        mdt['numslice_withflyback'] = 1
        mdt['numvol'] = mat_file_shape[0]
        mdt['zfov'] = 1  #set to 1 to avoid division by zero later, even though it's not really 1
        mdt['flyback'] = 0
        mdt['zwid'] = 0
        mdt['zstartpos'] = 0


    md = fromarrays( [ mdt['numvol'], mdt['numslice_withflyback'], mdt['numslice'], mdt['xpix'], \
        mdt['ypix'], mdt['flyback'], mdt['xfov'], mdt['yfov'], \
        mdt['zwid'], mdt['zfov'], mdt['framerate'], mdt['volrate'] ], \
        names = ['numvol', 'numslice_withflyback', 'numslice', 'xpix', 'ypix', 'flyback', \
            'xfov', 'yfov', 'zwid', 'zfov', 'framerate', 'volrate' ] )

    sio.savemat(pth_md, {'md': md}) #save for matlab part of pipeline 
    
    with open(pth_md_npy, 'wb') as fnmd: #and save as npy file for rest of python pipeline
        np.save(fnmd, mdt)

    return mdt


def separate_z_slices_before_denoising(pth_input, fn_prefix, pth_denoising, dims, denoise_volume): 

    Y = imread(pth_input)
    Y = Y.reshape(md['dims'])
    Y = np.transpose(Y, (0, 2, 3, 1)) #put in order t y x z (not t x y z)
    if Y.dtype!='uint16':
        raise Exception("dtype should be uint16 (arbitrary choice for this pipeline)")
    zind_all_dn = np.arange(md['dims'][1])

    for zii in zind_all_dn: #deepcad wants 3d data, so organize slices into separate tif files, and put in one folder (if denoise_volume=1, ie train on all slices) or separate folders (if denoise_volume=0, ie train on z subset)

        Ynew = Y[:,:,:,zii]
        if Ynew.shape != (md['dims'][0], md['dims'][2], md['dims'][3]):
            raise Exception("dims changed")
        if denoise_volume:
            dnfolder_insert = 'all'
        else:
            dnfolder_insert = str(zii)
        dnfolder = fn_prefix + '_' + dnfolder_insert
        tifname = fn_prefix + '_' + str(zii) + '_.tif'
        pth_trainset = pth_denoising + '/' + dnfolder #dir containing all tif files for training
        pth_tif_pdn = pth_trainset + '/' + tifname
        if os.path.exists(pth_trainset) and (zii==0 or denoise_volume==0): #if you're on the first zii (regardless of denoise_volume value), or for all zii if denoise_volume==0 
            shutil.rmtree(pth_trainset) #REMOVE any existing training folder before training, to ensure models don't get mixed (until "resume training" functionality is written) 
        if not os.path.exists(pth_trainset): #don't make this "else" connected to "if" above because you have to evaluate it  
            os.mkdir(pth_trainset)
        imwrite(pth_tif_pdn, Ynew, photometric = 'minisblack' ) #put the tif in the folder deepcad looks to for training data



def stitch_denoised_slices(pth_denoising, fn_prefix, pth_out, dims_pre_denoise, denoise_volume, epoch_choose):
    
    # stitch together separate z slices (separate tifs) output by denoising, choose which denoising epoch to use, 
    # and whether it was a denoising run that operated on all slices at once, or a slice ssubset (denoise_volume = 1 or 0, respectively) 

    if denoise_volume == 1:
        pth_trainset_all = natsorted(glob.glob(os.path.join(pth_denoising, fn_prefix + '_all/')))
    else:
        pth_trainset_all = natsorted(glob.glob(os.path.join(pth_denoising, fn_prefix + '_*/')))
        pth_trainset_all = list(set(pth_trainset_all) - set(natsorted(glob.glob(os.path.join(pth_denoising, fn_prefix + '_al*/'))))) #exclude the "all" folders when denoise_volume==1

    countz = 0
    for pth_trainset in pth_trainset_all:
        countz = countz + 1
        fldr_outtiff_all = natsorted(glob.glob(os.path.join(pth_trainset, 'DataFolderIs_*', 'E_*'))) #for all epochs that were used for denoising, organize tif files into single folder in 'denoised' folder  
        for fldr_outtiff in fldr_outtiff_all:
            if fnmatch.fnmatch(fldr_outtiff.split('/')[-1], 'E_' + "{:02d}".format(epoch_choose) + '_Iter_*'):
                pth_denoised_singles = natsorted(glob.glob(os.path.join(fldr_outtiff, '*output.tif')))

                Y = np.zeros((dims_pre_denoise[0], dims_pre_denoise[2], dims_pre_denoise[3], dims_pre_denoise[1])) #t y x z
                for fni,f in enumerate(pth_denoised_singles): #loop over each denoised z slice and reassemble into array matching shape of original 4d volume
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

                if fni != dims_pre_denoise[1]-1:
                    raise Exception("not all slices present")

                mnmv = np.min(Y)
                Y = Y - mnmv #make nonnegative before writing to uint16
                print("MIN AFTER DENOISING " + str(mnmv))
                Y = Y.astype('uint16')
                Y = np.transpose(Y, (0, 3, 1, 2)) #tzyx
                print(Y.shape)
                Y = Y.reshape(dims_pre_denoise[0] * dims_pre_denoise[1], dims_pre_denoise[2], dims_pre_denoise[3]) #(tz)yx
                print(Y.shape)
                imwrite(pth_out, Y.squeeze()) #write the registered movie as tif for use in matlab, and caiman extraction below





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