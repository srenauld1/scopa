import numpy as np

def stackshape(stack, md):

    # use stack and dict 'md' (from mdsisv.py) to find stack shape (order tzcyx), accounting for number of channels and whether flyback frames are present
    # hoped to compute numchan without reference to md['chan_save'], since it can be wrong, but 1-chan stack with flyback cannot be distinguished from 2-chan stack without flyback when flyback equals numslice, so just using channel_save to set numchan

    dims_onechan = md['dims']

    if isinstance(md['channel_save'], list):
        numchan = len(md['channel_save'][0])
    elif isinstance(md['channel_save'], int):
        numchan = 1

    rmdr = np.prod(stack.shape)/np.prod(dims_onechan)/numchan

    if rmdr!=1:
        dims_onechan = [md['dims'][0], md['dims'][1]+md['flyback'], md['dims'][2], md['dims'][3]]
        rmdr = np.prod(stack.shape)/np.prod(dims_onechan)/numchan
        if rmdr!=1:
            raise Exception("number of stack elements must equal numchan*np.prod(md['dims']), or numchan*np.prod(md['dims']) with flyback; this error can occur if this is an aborted stack, or if something is wrong with your metadata")

    tzcyx = dims_onechan[0], dims_onechan[1], numchan, dims_onechan[2], dims_onechan[3]

    return tzcyx, numchan
