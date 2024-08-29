import numpy as np

def separate_channels_when_two(stack, md, discard_channel, chan_primary_when_two):
    
    two_channel_reg = 0
    stack_secondary = None
    chan_secondary = None
    chanstr_primary = '' 
    chanstr_secondary = ''
    if 'channel_save' in md: #older runs of do_register will not have this field in md, if you want it, delete metadatanew and rerun
        if not isinstance(md['channel_save'], int):
            if len(md['channel_save'])==2:
                if discard_channel is not None:
                    keepchan = np.setxor1d([1,2], discard_channel)
                    # chanstr_primary = '_chn' + str(keepchan) #channel id is saved in metadata, we only want chn* infix if two_channel_reg
                    stack = stack[:,keepchan[0]-1,:,:].squeeze()
                    print("STACK HAS 2 CHANNELS, BUT discard_channel IS SET TO " + str(discard_channel) + ", SO DISCARDING CHANNEL " + str(discard_channel) + " AND KEEPING CHANNEL " + str(keepchan))
                else:
                    two_channel_reg = 1
                    chan_secondary = np.setxor1d([1,2], chan_primary_when_two)
                    chan_secondary = chan_secondary[0]
                    chanstr_primary = '_chn' + str(chan_primary_when_two)
                    chanstr_secondary = '_chn' + str(chan_secondary)
                    if np.ndim(stack)==3: #hack for not having dims include channels for now
                        stack = stack.reshape(md['dims'][0], md['dims'][1], 2, md['dims'][2], md['dims'][3])
                        stack_secondary = stack[:,:,chan_secondary-1,:,:].squeeze()
                        stack = stack[:,:,chan_primary_when_two-1,:,:].squeeze()                    
                    elif np.ndim(stack)==4:
                        stack_secondary = stack[:,chan_secondary-1,:,:].squeeze()
                        stack = stack[:,chan_primary_when_two-1,:,:].squeeze()
                    print("STACK HAS 2 CHANNELS, WILL REGISTER CHANNEL " + str(chan_primary_when_two) + ", THEN WILL REGISTER CHANNEL " + str(chan_secondary) + " USING SHIFTS FROM CHANNEL " + str(chan_primary_when_two) )
            else:
                raise Exception("is channel 2 the only channel?")
        
    
    return stack, stack_secondary, two_channel_reg, chan_secondary, chanstr_primary, chanstr_secondary
    