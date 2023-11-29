


from ScanImageTiffReader import ScanImageTiffReader
from ast import literal_eval
import re
import scipy.io as sio
import numpy as np
from numpy.core.records import fromarrays


def read_save_metadata(pth_datafile, pth_md, pth_md_npy, mat_file_shape = None):

    mdt = {}

    try:
        
        if mat_file_shape is None:

            # use ScanImageTiffReader to read metadata (strange parsing because scanimage tif headers are not saved as json)
            meta = ScanImageTiffReader(pth_datafile).metadata()    #tiffile might be able to read metadata
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
            mdt['zwid'] = float(re.findall( 'actualStackZStepSize = (.*)', meta)[0])
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

    except:
        
        "WARNING: CANNOT READ METADATA, USING DEFAULTS"
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

