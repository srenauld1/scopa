import numpy as np
import matplotlib.pyplot as plt

def im_montage(images, vmin=None, vmax=None):

    # if you don't pass in vmin and vmax each subfigure will be normalized to its own min/max

    numim = images.shape[-1]
    
    Nc = 3
    Nr = int(np.ceil(numim/Nc))
    fig, ax = plt.subplots(Nr, Nc)
    for i in range(numim):
        indies = np.unravel_index(i, (Nr,Nc))
        ax[indies[0],indies[1]].imshow(images[:,:,i].T, vmin=vmin, vmax=vmax)
        ax[indies[0],indies[1]].axis('off')
    
    # print("create zlimits and assign value")
    # input("Press Enter to continue...")
    #plt.close('all')
