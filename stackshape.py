import numpy as np
import json


def stackshape(stack, md, pthmd, force_match=0):

    # use stack and dict 'md' (from mdsild.py) to find stack shape (order tzcyx), accounting for number of channels and whether flyback frames are present
    # hoped to compute numchan without reference to md['chan_save'], since it can be wrong, but 1-chan stack with flyback cannot be distinguished from 2-chan stack without flyback when flyback equals numslice, so just using channel_save to set numchan
    # force_match=1 will force metadata to match first dimension of stack shape if possible by changing numvol, and will rewrite metadata file; if force_match=0 (default), an exception will be raised if stack shape does not match metadata

    dims_onechan = md['dims']

    if isinstance(md['channel_save'], list):
        numchan = len(md['channel_save']) # why was it this?? len(md['channel_save'][0])
    elif isinstance(md['channel_save'], int):
        numchan = 1

    rmdr = np.prod(stack.shape)/np.prod(dims_onechan)/numchan
    hasfb = 0

    if rmdr!=1:
        dims_onechan = [md['dims'][0], md['dims'][1]+md['flyback'], md['dims'][2], md['dims'][3]]
        hasfb = 1
        rmdr = np.prod(stack.shape)/np.prod(dims_onechan)/numchan
        if rmdr!=1:
            if force_match:
                numvoltmp = stack.shape[0]/(md['dims'][1]+md['flyback'])
                if numvoltmp % 1 == 0:
                    md['numvol'] = int(numvoltmp)
                    md['dims'][0] = md['numvol']
                    with open(pthmd, 'w') as file: 
                        file.write(json.dumps(md, sort_keys=True, indent=4))
                else:
                    raise Exception("number of stack elements must equal numchan*np.prod(md['dims']), or numchan*np.prod(md['dims']) with flyback; this error can occur if this is an aborted stack, or if something is wrong with your metadata")
            else:
                raise Exception("number of stack elements must equal numchan*np.prod(md['dims']), or numchan*np.prod(md['dims']) with flyback; this error can occur if this is an aborted stack, or if something is wrong with your metadata")

    tzcyx = dims_onechan[0], dims_onechan[1], numchan, dims_onechan[2], dims_onechan[3]

    return tzcyx, numchan, hasfb, md
