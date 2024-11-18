from scipy.ndimage import median_filter as mdflt
from scipy.ndimage import gaussian_filter as gflt
import numpy as np
from plot_gif import plot_gif


def stacksmooth(stack, smlenpx, volrate, numframe):
      
        print("SMOOTHING STACK")

        numsmsd = 4 #truncate gaussian filter after this many stds (default is 4 so using that to define input sigma)

        if len(smlenpx)!=3:
             raise Exception("smlenpx must have 3 elements, xyz")
        
        smsd = smlenpx.copy()
        axmd = []
        for k,tmp in enumerate(smsd):
            if tmp!=0:
                smsd[k] = (tmp-1)/numsmsd
                axmd.append(k+1)

        smlenpx = smlenpx[:len(stack.shape)]
        ax = tuple(np.arange(1,len(stack.shape)))

        stack = gflt(stack, sigma=smsd, mode='reflect', truncate=numsmsd, axes=ax)
        for ind,val in enumerate(smlenpx): #can't figure out how to call this with smlenpx for all axes in one line like gflt
            if val:
                axmd = ind+1
                stack = mdflt(stack, size=val, axes=axmd)

        # removed temporal smoothing below
        # sampper = 1/volrate
        # smlensamp = smlensec / sampper  
        # smsdt = (smlensamp - 1) / numsmsd
        # stack = gflt(stack, sigma=smsdt, mode='reflect', truncate=numsmsd, axes=0)
        # stack = mdflt(stack, size=smlensamp, axes=0)

        #plot_gif(stack, '/Users/wienecke/stacks/test.gif', indsz=slice(3,4,1), indst=slice(0,20,1))

        return stack
