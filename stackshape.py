import numpy as np

def stackshape(stack, md):

    #use stack and dict 'md' (from mdsisv.py) to find stack shape (order tzcyx), accounting for number of channels, and whether flyback frames are present

    dims_onechan = md['dims']
    rmdr = np.prod(stack.shape)/np.prod(dims_onechan)

    if rmdr%1==0:
        numchan = int(rmdr)
    else:
        dims_onechan = [md['dims'][0], md['dims'][1]+md['flyback'], md['dims'][2], md['dims'][3]]
        rmdr = np.prod(stack.shape)/np.prod(dims_onechan)
        if rmdr%1==0:
            numchan = int(rmdr)
        else:
            raise Exception("number of stack elements must be multiple of np.prod(md['dims']), or np.prod(md['dims']) with flyback")

    tzcyx = dims_onechan[0], dims_onechan[1], numchan, dims_onechan[2], dims_onechan[3]

    return tzcyx, numchan
