from ScanImageTiffReader import ScanImageTiffReader
from ast import literal_eval
import re
import os
import numpy as np
import json


def read_save_metadata(pth_readfile, pth_md, pth_hires, mat_file_shape = None):

    mdt = {}

    print("READING METADATA") #use ScanImageTiffReader to read metadata (strange ping because scanimage tif headers are not saved as json)

    try:
        
        if mat_file_shape is None: #mat_file_shape is None for scanimage data, is not None for Leica data (Carl's old project)

            if pth_hires:
                meta_hires = ScanImageTiffReader(pth_hires).metadata()
                mdt['channel_save'] = literal_eval(re.findall( 'channelSave = (.*)', meta_hires)[0].replace(" ",",").replace(";",","))
                mdt['channel_active'] = literal_eval(re.findall( 'channelsActive = (.*)', meta_hires)[0].replace(" ",",").replace(";",","))
                mdt['numvol'] = int(re.findall( 'actualNumVolumes = (.*)', meta_hires)[0])
                mdt['numslice_withflyback'] = int(re.findall( 'numFramesPerVolumeWithFlyback = (.*)', meta_hires)[0])
                mdt['numslice'] = int(re.findall( 'actualNumSlices = (.*)', meta_hires)[0])
                mdt['xpix'] = int(re.findall( 'pixelsPerLine = (.*)', meta_hires)[0])
                mdt['ypix'] = int(re.findall( 'linesPerFrame = (.*)', meta_hires)[0])
                mdt['flyback'] = mdt['numslice_withflyback'] - mdt['numslice']
                mdt['dims'] = [mdt['numvol'], mdt['numslice_withflyback'] - mdt['flyback'], mdt['ypix'], mdt['xpix']]
                fovtmp = literal_eval(re.findall( 'imagingFovUm = (.*)', meta_hires)[0].replace(" ",",").replace(";",","))
                mdt['xfov'] = abs(fovtmp[0]) + abs(fovtmp[2])
                mdt['yfov'] = abs(fovtmp[1]) + abs(fovtmp[3])
                mdt['zwid'] = float(re.findall( 'actualStackZStepSize = (.*)', meta_hires)[0])
                mdt['zstartpos'] = literal_eval(re.findall( 'zsRelative = (.*)', meta_hires)[0].replace(";",","))
                mdt['zfov'] = mdt['zstartpos'][-1] + mdt['zwid'] - mdt['zstartpos'][0]
                mdt['framerate'] = float(re.findall( 'scanFrameRate = (.*)', meta_hires)[0])
                mdt['volrate'] = float(re.findall( 'scanVolumeRate = (.*)', meta_hires)[0])


            meta = ScanImageTiffReader(pth_readfile).metadata()    #tiffile might be able to read metadata
            
            mdt['channel_save'] = literal_eval(re.findall( 'channelSave = (.*)', meta)[0].replace(" ",",").replace(";",","))
            mdt['channel_active'] = literal_eval(re.findall( 'channelsActive = (.*)', meta)[0].replace(" ",",").replace(";",","))
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
            if re.findall( 'actualStackZStepSize = (.*)', meta)[0]=='[]':
                mdt['zwid'] = 0.0
            else:
                mdt['zwid'] = float(re.findall( 'actualStackZStepSize = (.*)', meta)[0])
            mdt['zstartpos'] = literal_eval(re.findall( 'zsRelative = (.*)', meta)[0].replace(";",","))
            if isinstance(mdt['zstartpos'], int):
                mdt['zfov'] = mdt['zwid']
            else:
                mdt['zfov'] = mdt['zstartpos'][-1] + mdt['zwid'] - mdt['zstartpos'][0]
            mdt['framerate'] = float(re.findall( 'scanFrameRate = (.*)', meta)[0])
            mdt['volrate'] = float(re.findall( 'scanVolumeRate = (.*)', meta)[0])
        
        else: #for raw imaging files that are not saved by scanimage (eg carl's old project with Leica data)

            mdt['dims'] = [mat_file_shape[0], 1, mat_file_shape[1], mat_file_shape[2]] #z size (2nd dim) is hard coded as 1 because old project is not volumetric 
            mdt['channel_save'] = 1
            mdt['channel_active'] = 1
            mdt['framerate'] = 20
            mdt['volrate'] = 20
            mdt['xpix'] = 256
            mdt['xfov'] = 74
            mdt['ypix'] = 128
            mdt['yfov'] = 37
            mdt['numslice'] = 1
            mdt['numslice_withflyback'] = 1
            mdt['numvol'] = mat_file_shape[0]
            mdt['zfov'] = 0 
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
            'dims': mdt['dims'],
            'xfov': mdt['xfov'],
            'yfov': mdt['yfov'],
            'zwid': mdt['zwid'],
            'zstartpos': mdt['zstartpos'],
            'zfov': mdt['zfov'],
            'framerate': mdt['framerate'],
            'volrate': mdt['volrate'], 
            'channel_save': mdt['channel_save'],
            'channel_active': mdt['channel_active']}
    
    if pth_hires:
        md_hires = {'numvol': mdt['numvol'],
                    'numslice_withflyback': mdt['numslice_withflyback'],
                    'numslice': mdt['numslice'],
                    'xpix': mdt['xpix'],
                    'ypix': mdt['ypix'],
                    'flyback': mdt['flyback'],
                    'dims': mdt['dims'],
                    'xfov': mdt['xfov'],
                    'yfov': mdt['yfov'],
                    'zwid': mdt['zwid'],
                    'zstartpos': mdt['zstartpos'],
                    'zfov': mdt['zfov'],
                    'framerate': mdt['framerate'],
                    'volrate': mdt['volrate'], 
                    'channel_save': mdt['channel_save'],
                    'channel_active': mdt['channel_active']}
        md['md_hires'] = md_hires
    
    
    if not np.isin(md['channel_save'], md['channel_active']).any():
        print("channel_save is not a subset in channel_active")
        if len(md['channel_save'])>len(md['channel_active']):
            print("CHANNEL_SAVE HAS MORE CHANNELS THAN CHANNEL_ACTIVE; YOU MAY HAVE ACCIDENTALLY REDCORDED AN EMPTY CHANNEL; MAKING CHANNEL_SAVE EQUAL TO CHANNEL_ACTIVE, WHICH WILL DISREGARD THE PRESUMABLY EMPTY SAVED CHANNEL")
            md['channel_save'] = md['channel_active']


    with open(pth_md, 'w') as file: 
        file.write(json.dumps(md, sort_keys=True, indent=4))



def convert_md_file(pth_md, pth_md_old, pth_md_mat_old): #convert old metadatafile to new and delete old 

    md = np.load(pth_md_old, allow_pickle='TRUE').item()

    if not 'channel_save' in md or not 'channel_active' in md:
        # md['channel_save'] = 1
        # md['channel_active'] = 1
        raise Exception("your metadata file is old and does not have channel information, rerun registration so channel information can be saved in the new metadata file")

    with open(pth_md, 'w') as file: 
        file.write(json.dumps(md))

    os.remove(pth_md_old)
    # if os.path.isfile(pth_md_mat_old): 
    #     os.remove(pth_md_mat_old)

