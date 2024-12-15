import numpy as np

def separate_channels_when_two(stack, md, discard_channel, chan_primary):
    
    dims = md['dims']
    rmdr = np.prod(stack.shape)/np.prod(dims)

    if rmdr%1==0:
        rmdr = int(rmdr)
    else:
        dims = [md['dims'][0], md['dims'][1]+md['flyback'], md['dims'][2], md['dims'][3]]
        rmdr = np.prod(stack.shape)/np.prod(dims)
        if rmdr%1==0:
            rmdr = int(rmdr)
        else:
            raise Exception("number of stack elements must be multiple of np.prod(dims), or np.prod(dims) with flyback")

    use_two_channels = 0
    stack_secondary = None
    chan_secondary = None
    chanstr_primary = '' 
    chanstr_secondary = ''

    if rmdr==2: #if there's just one channel, or an earlier job discarded one channel, rmdr will be 1 here

        stack = stack.reshape(dims[0], dims[1], rmdr, dims[2], dims[3])

        if not isinstance(md['channel_save'], int) and len(md['channel_save'])==2: #if two channels were saved

                if discard_channel is not None:
                    chan_primary = np.setxor1d([1,2], discard_channel)
                    # chanstr_primary = '_chn' + str(chan_primary) #if you set chanstr_primary to nonempty when discard_channel is not none, later the index will be wrong since the output stack has only one channel  (only if it's channel 2, right?)
                    stack = stack[:,:,chan_primary[0]-1,:,:].squeeze()
                    print("STACK HAS 2 CHANNELS, BUT discard_channel IS SET TO " + str(discard_channel) + ", SO DISCARDING CHANNEL " + str(discard_channel) + " AND KEEPING CHANNEL " + str(chan_primary[0]))
                else:
                    use_two_channels = 1
                    chan_secondary = np.setxor1d([1,2], chan_primary)[0]
                    chanstr_primary = '_chn' + str(chan_primary)
                    chanstr_secondary = '_chn' + str(chan_secondary)
                    stack_secondary = stack[:, :, chan_secondary-1, :, :].squeeze()
                    stack = stack[:, :, chan_primary-1, :, :].squeeze()
                    print("STACK HAS 2 CHANNELS, WITH chan_primary SET TO " + str(chan_primary) )
        
        else: #if channel_save has one channel, but rmdr is 2, you may have saved two channels with only one active; in read_save_metadata, this was detected and corrected when writing md['channel_save'], and here the extra saved channel will be removed from the stack
            
            if isinstance(md['channel_save'], list):
                stack = stack[:, :, int(md['channel_save'][0])-1, :, :].squeeze()
            elif isinstance(md['channel_save'], int):
                stack = stack[:, :, md['channel_save'][0]-1, :, :].squeeze()
            print("CHANNEL_SAVE HAS MORE CHANNELS THAN CHANNEL_ACTIVE; YOU MAY HAVE ACCIDENTALLY REDCORDED AN EMPTY CHANNEL; CHANNEL_SAVE WAS SET TO EQUAL TO CHANNEL_ACTIVE IN read_save_metadata.py; NOW SELECTING ONLY THE ACTIVE CHANNEL FROM THE STACK")

    #output chan_primary (which is also an input) in case it gets updated if there are two channels and discard_channel is not None
        
    return stack, stack_secondary, use_two_channels, chan_primary, chan_secondary, chanstr_primary, chanstr_secondary
    