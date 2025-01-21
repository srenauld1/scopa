from ScanImageTiffReader import ScanImageTiffReader
from ast import literal_eval
import re
import os
import numpy as np
import json


def mdsisv(pth_readfile, pthmd, mat_file_shape = None):

    mdt = {}


    print("READING METADATA") #use ScanImageTiffReader to read metadata (strange ping because scanimage tif headers are not saved as json)
        
    if mat_file_shape is None: #mat_file_shape is None for scanimage data, is not None for Leica data (Carl's old project)

        meta = ScanImageTiffReader(pth_readfile).metadata() #tiffile might be able to read metadata
        
        mdt['channel_save'] = literal_eval(re.findall( 'channelSave = (.*)', meta)[0].replace(" ",",").replace(";",","))
        mdt['channel_active'] = literal_eval(re.findall( 'channelsActive = (.*)', meta)[0].replace(" ",",").replace(";",","))

        mdt['numslice'] = int(re.findall( 'actualNumSlices = (.*)', meta)[0])
        mdt['numslice_withflyback'] = int(re.findall( 'numFramesPerVolumeWithFlyback = (.*)', meta)[0])
        mdt['flyback'] = mdt['numslice_withflyback'] - mdt['numslice']

        if mdt['numslice']==1 and mdt['numslice_withflyback']==1:
            if re.findall( 'hStackManager.enable = (.*)', meta)[0]!='false': #if it's a single slice
                raise Exception("if numslice is 1, hStackManager.enable should be false")
            print("hStackManager.enable is false, treating stack as planar yxt")
            mdt['numvol'] = int(re.findall( 'framesPerSlice = (.*)', meta)[0])
        else:
            try:
                mdt['numvol'] = int(re.findall( 'actualNumVolumes = (.*)', meta)[0])
            except:
                print("USING OLD SCANIMAGE VERSION METADATA PATTERNS")
                mdt['numvol'] = int(re.findall( 'numVolumes = (.*)', meta)[0])
        


        mdt['xpix'] = int(re.findall( 'pixelsPerLine = (.*)', meta)[0])
        mdt['ypix'] = int(re.findall( 'linesPerFrame = (.*)', meta)[0])
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
        mdt['channel_offsets'] = literal_eval(re.findall( 'channelOffsets = (.*)', meta)[0].replace(" ",",").replace(";",","))
    
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
        mdt['channel_offsets'] = 0

                
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
            'channel_active': mdt['channel_active'],
            'channel_offsets': mdt['channel_offsets']}
        
    
    if not np.isin(md['channel_save'], md['channel_active']).any():
        print("channel_save is not a subset in channel_active")
        if len(md['channel_save'])>len(md['channel_active']):
            print("CHANNEL_SAVE HAS MORE CHANNELS THAN CHANNEL_ACTIVE; YOU MAY HAVE ACCIDENTALLY REDCORDED AN EMPTY CHANNEL; MAKING CHANNEL_SAVE EQUAL TO CHANNEL_ACTIVE, WHICH WILL DISREGARD THE PRESUMABLY EMPTY SAVED CHANNEL")
            md['channel_save'] = md['channel_active']


    with open(pthmd, 'w') as file: 
        file.write(json.dumps(md, sort_keys=True, indent=4))



def convert_md_file(pthmd, pthmd_old, pthmd_matold): #convert old metadatafile to new and delete old 

    md = np.load(pthmd_old, allow_pickle='TRUE').item()

    raise_channel_exception = 1
    if not 'channel_save' in md or not 'channel_active' in md:
        if raise_channel_exception:
            raise Exception("your metadata file is old and does not have channel information, rerun registration so channel information can be saved in the new metadata file, or if you're certain of the channel, just run the same again but with raise_channel_exception=0 above")
        else:
            md['channel_save'] = 1
            md['channel_active'] = 1

    with open(pthmd, 'w') as file: 
        file.write(json.dumps(md, sort_keys=True, indent=4))

    os.remove(pthmd_old)
    # if os.path.isfile(pthmd_matold): 
    #     os.remove(pthmd_matold)

