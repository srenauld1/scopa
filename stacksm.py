from scipy.ndimage import median_filter as mdflt
from scipy.ndimage import gaussian_filter as gflt
import numpy as np
from plot_gif import plot_gif


def stacksm(stack, smlenpx, volrate, numframe):
      
        print("SMOOTHING STACK")

        numsmsd = 5 #truncate gaussian filter after this many stds (default is 4 so using that to define input sigma)

        if len(smlenpx)!=3:
             raise Exception("smlenpx must have 3 elements, xyz")
        
        smlentmp = []
        smsd = []
        smax = []
        for k,tmp in enumerate(smlenpx):
            if tmp!=0:
                smlentmp.append(int(tmp))
                smsd.append((tmp-1)/numsmsd)
                smax.append(k+1)

        stack = gflt(stack, sigma=smsd, mode='reflect', truncate=numsmsd, axes=smax)
        stack = mdflt(stack, size=smlentmp, axes=smax)

        # removed temporal smoothing below; spatial seems better for registration
        # sper = 1/volrate
        # smlensamp = smlensec / sper  
        # smsdt = (smlensamp - 1) / numsmsd
        # stack = gflt(stack, sigma=smsdt, mode='reflect', truncate=numsmsd, axes=0)
        # stack = mdflt(stack, size=smlensamp, axes=0)

        #plot_gif(stack, '/Users/wienecke/stacks/presm.gif', indsz=slice(2,3,1), indst=slice(0,100,1))

        return stack
