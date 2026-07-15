from ScanImageTiffReader import ScanImageTiffReader
from ast import literal_eval
import re
import os
import numpy as np
import json


def mdsild(pth_readfile, pthmd, stack_shape_nonnative = None):

    mdt = {}


    print("READING METADATA") #use ScanImageTiffReader to read metadata (strange ping because scanimage tif headers are not saved as json)
        
    if stack_shape_nonnative is None: #stack_shape_nonnative is None for scanimage stacks, is not None for non-scanimage stacks (can't parse metadata)

        meta = ScanImageTiffReader(pth_readfile).metadata() #tiffile might be able to read metadata
        
        mdt['channel_save'] = literal_eval(re.findall( 'channelSave = (.*)', meta)[0].replace(" ",",").replace(";",","))
        mdt['channel_active'] = literal_eval(re.findall( 'channelsActive = (.*)', meta)[0].replace(" ",",").replace(";",","))

        mdt['numslice'] = int(re.findall( 'actualNumSlices = (.*)', meta)[0])
        mdt['numslice_withflyback'] = int(re.findall( 'numFramesPerVolumeWithFlyback = (.*)', meta)[0])
        if mdt['numslice'] < 1: #actualNumSlices can be 0 in some scanimage acquisitions (eg aborted, or certain fastZ configs); fall back to the configured hStackManager.numSlices so numslice/flyback/dims are not left at 0
            numslice_cfg = int(re.findall( 'hStackManager.numSlices = (.*)', meta)[0])
            print("actualNumSlices is " + str(mdt['numslice']) + " (invalid); falling back to hStackManager.numSlices = " + str(numslice_cfg))
            mdt['numslice'] = numslice_cfg
        mdt['flyback'] = mdt['numslice_withflyback'] - mdt['numslice']

        if mdt['numslice']==1 and mdt['numslice_withflyback']==1 and re.findall( 'hStackManager.enable = (.*)', meta)[0]=='false': #if it's a single slice
            print("treating stack as planar yxt because numslice=1, numslice_withflyback=1, and hStackManager.enable is false")
            mdt['numvol'] = int(re.findall( 'framesPerSlice = (.*)', meta)[0])
        else:
            try:
                mdt['numvol'] = int(re.findall( 'actualNumVolumes = (.*)', meta)[0])
            except:
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

        mdt['dims'] = [stack_shape_nonnative[0], 1, stack_shape_nonnative[1], stack_shape_nonnative[2]] #z size (2nd dim) is hard coded as 1 because old project is not volumetric 
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
        mdt['numvol'] = stack_shape_nonnative[0]
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

