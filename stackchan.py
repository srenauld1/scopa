import numpy as np
from stackshape import stackshape
import json

def stackchan(stack, md, pthmd, chanrm, chan_primary):
    
    #determine which channels are present and separate the channels, also output channel info strings; this function is used in several parts of the python pipeline (registration, denoising, and roi extraction)

    tzcyx, numchan = stackshape(stack, md)

    use_two_channels = 0
    stack_secondary = None
    chan_secondary = None
    chanstr_primary = '' 
    chanstr_secondary = ''

    if numchan==2: #if there's just one channel, or an earlier job discarded one channel, numchan will be 1 here

        stack = stack.reshape(tzcyx)

        if isinstance(md['channel_save'], list) and len(md['channel_save'])==2: #if two channels were saved to the raw scanimage output

            if isinstance(md['channel_active'], list) and len(md['channel_active'])==2:
                
                if chanrm is not None: #keep chanstr_primary empty if discarding a channel because if you discard channel 2 and set chanstr_primary to chn1, later the channel index will be 2, but that's wrong because the output stack has only one channel 
                    chan_primary = np.setxor1d([1,2], chanrm)
                    stack = stack[:,:,chan_primary[0]-1,:,:].squeeze()
                    print("STACK HAS 2 CHANNELS, BUT chanrm IS SET TO " + str(chanrm) + ", SO DISCARDING CHANNEL " + str(chanrm) + " AND KEEPING CHANNEL " + str(chan_primary[0]))
                else:
                    use_two_channels = 1
                    chan_secondary = np.setxor1d([1,2], chan_primary)[0]
                    chanstr_primary = '_chn' + str(chan_primary)
                    chanstr_secondary = '_chn' + str(chan_secondary)
                    stack_secondary = stack[:, :, chan_secondary-1, :, :].squeeze()
                    stack = stack[:, :, chan_primary-1, :, :].squeeze()
                    print("STACK HAS 2 CHANNELS, WITH chan_primary SET TO " + str(chan_primary) )
        
            else: #if channelchannel_active has one channel, but cvhannel_save is 2, you may have saved two channels with only one active; in mdsisv, this was detected and corrected when writing md['channel_save'], and here the extra saved channel will be removed from the stack
                
                if not np.isin(md['channel_save'], md['channel_active']).any():
                    print("channel_save is not a subset of channel_active")
                    if len(md['channel_save'])>len(md['channel_active']):
                        print("CHANNEL_SAVE HAS MORE CHANNELS THAN CHANNEL_ACTIVE; YOU MAY HAVE ACCIDENTALLY REDCORDED AN EMPTY CHANNEL; MAKING CHANNEL_SAVE EQUAL TO CHANNEL_ACTIVE, WHICH WILL DISREGARD THE PRESUMABLY EMPTY SAVED CHANNEL")
                        md['channel_save'] = md['channel_active']
                        with open(pthmd, 'w') as file: 
                            file.write(json.dumps(md, sort_keys=True, indent=4))
                    else:
                        raise Exception("channel_save and channel_active are each scalar, but do not match; did you save the wrong channel?")

                if isinstance(md['channel_save'], list):
                    stack = stack[:, :, int(md['channel_save'][0])-1, :, :].squeeze()
                elif isinstance(md['channel_save'], int):
                    stack = stack[:, :, md['channel_save']-1, :, :].squeeze()
                
                print("CHANNEL_SAVE HAS MORE CHANNELS THAN CHANNEL_ACTIVE; YOU MAY HAVE ACCIDENTALLY REDCORDED AN EMPTY CHANNEL; CHANNEL_SAVE WAS SET TO EQUAL TO CHANNEL_ACTIVE IN mdsisv.py; NOW SELECTING ONLY THE ACTIVE CHANNEL FROM THE STACK")

    #output chan_primary (which is also an input) in case it gets updated if there are two channels and chanrm is not None
        
    return stack, stack_secondary, use_two_channels, chan_primary, chan_secondary, chanstr_primary, chanstr_secondary
    