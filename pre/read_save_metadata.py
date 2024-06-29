


from ScanImageTiffReader import ScanImageTiffReader
from ast import literal_eval
import re
import scipy.io as sio
import numpy as np

def read_save_metadata(pth_datafile, pth_md, pth_md_mat, pth_hires, mat_file_shape = None):

    mdt = {}

    print("READING METADATA") #use ScanImageTiffReader to read metadata (strange parsing because scanimage tif headers are not saved as json)

    try:
        
        if mat_file_shape is None:

            if pth_hires:
                meta_hires = ScanImageTiffReader(pth_hires).metadata()
                mdt['numvol_hires'] = int(re.findall( 'actualNumVolumes = (.*)', meta_hires)[0])
                mdt['numslice_withflyback_hires'] = int(re.findall( 'numFramesPerVolumeWithFlyback = (.*)', meta_hires)[0])
                mdt['numslice_hires'] = int(re.findall( 'actualNumSlices = (.*)', meta_hires)[0])
                mdt['xpix_hires'] = int(re.findall( 'pixelsPerLine = (.*)', meta_hires)[0])
                mdt['ypix_hires'] = int(re.findall( 'linesPerFrame = (.*)', meta_hires)[0])
                mdt['flyback_hires'] = mdt['numslice_withflyback_hires'] - mdt['numslice_hires']
                mdt['dims_hires'] = [mdt['numvol_hires'], mdt['numslice_withflyback_hires'] - mdt['flyback_hires'], mdt['ypix_hires'], mdt['xpix_hires']]
                fovtmp = literal_eval(re.findall( 'imagingFovUm = (.*)', meta_hires)[0].replace(" ",",").replace(";",","))
                mdt['xfov_hires'] = abs(fovtmp[0]) + abs(fovtmp[2])
                mdt['yfov_hires'] = abs(fovtmp[1]) + abs(fovtmp[3])
                mdt['zwid_hires'] = float(re.findall( 'actualStackZStepSize = (.*)', meta_hires)[0])
                mdt['zstartpos_hires'] = literal_eval(re.findall( 'zsRelative = (.*)', meta_hires)[0].replace(";",","))
                mdt['zfov_hires'] = mdt['zstartpos_hires'][-1] + mdt['zwid_hires'] - mdt['zstartpos_hires'][0]
                mdt['framerate_hires'] = float(re.findall( 'scanFrameRate = (.*)', meta_hires)[0])
                mdt['volrate_hires'] = float(re.findall( 'scanVolumeRate = (.*)', meta_hires)[0])


            meta = ScanImageTiffReader(pth_datafile).metadata()    #tiffile might be able to read metadata
            
            mdt['channelSave'] = int(re.findall( 'channelSave = (.*)', meta)[0])
            mdt['channelsActive'] = int(re.findall( 'channelsActive = (.*)', meta)[0])
            print("\n\n\nchannelSave: \n" + str(mdt['channelSave']))
            print("\n\n\nchannelsActive: \n" + str(mdt['channelsActive']))
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
            if isinstance(mdt['zstartpos'], int):
                mdt['zfov'] = mdt['zwid']
            else:
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
        
        raise Exception("\n\n\n CANNOT READ METADATA")

                
    md = {  'numvol': mdt['numvol'],
            'numslice_withflyback': mdt['numslice_withflyback'],
            'numslice': mdt['numslice'],
            'xpix': mdt['xpix'],
            'ypix': mdt['ypix'],
            'flyback': mdt['flyback'],
            'xfov': mdt['xfov'],
            'yfov': mdt['yfov'],
            'zwid': mdt['zwid'],
            'zstartpos': mdt['zstartpos'],
            'zfov': mdt['zfov'],
            'framerate': mdt['framerate'],
            'volrate': mdt['volrate']}
    
    if pth_hires:
        md_hires = {'numvol': mdt['numvol_hires'],
                    'numslice_withflyback': mdt['numslice_withflyback_hires'],
                    'numslice': mdt['numslice_hires'],
                    'xpix': mdt['xpix_hires'],
                    'ypix': mdt['ypix_hires'],
                    'flyback': mdt['flyback_hires'],
                    'xfov': mdt['xfov_hires'],
                    'yfov': mdt['yfov_hires'],
                    'zwid': mdt['zwid_hires'],
                    'zstartpos': mdt['zstartpos_hires'],
                    'zfov': mdt['zfov_hires'],
                    'framerate': mdt['framerate_hires'],
                    'volrate': mdt['volrate_hires']}
        md['md_hires'] = md_hires
    
        

    sio.savemat(pth_md_mat, {'md': md}) #save for matlab part of pipeline 
    
    with open(pth_md, 'wb') as fnmd: #and save as npy file for rest of python pipeline
        np.save(fnmd, mdt)

