import numpy as np

def flybackrm(stack, dims, flyback):
    
    dims_onechan = [dims[0], dims[1], dims[2], dims[3]]
    rmdr = np.prod(stack.shape)/np.prod(dims_onechan)
    if rmdr!=1:
        dims_onechan = [dims[0], dims[1]+flyback, dims[2], dims[3]]
        rmdr = np.prod(stack.shape)/np.prod(dims_onechan)
        if rmdr!=1:
            raise Exception("number of stack elements must equal numchan*np.prod(dims) for one channel, or numchan*np.prod(dims) for one channel with flyback; this error can occur if this is an aborted stack, or if something is wrong with your metadata")
        else:
            if flyback==0:
                raise Exception("inferred flyback, but it is 0 in metadata")  
            stack = stack.reshape(dims[0], dims[1]+flyback, dims[2], dims[3])
            stack = stack[:,:-flyback,:,:] #crop flyback frames
            stack = stack.reshape(dims[0]*dims[1], dims[2], dims[3])
    
    return stack
