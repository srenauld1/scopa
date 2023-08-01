from matplotlib import colors
import matplotlib.pyplot as plt
import numpy as np
import time


def im_montage(images):

    numim = images.shape[-1]
    
    Nc = 3
    Nr = int(np.ceil(numim/Nc))
    fig, ax = plt.subplots(Nr, Nc)
    for i in range(numim):
        indies = np.unravel_index(i, (Nr,Nc))
        ax[indies[0],indies[1]].imshow(images[:,:,i].T)
        ax[indies[0],indies[1]].axis('off')
    
    # print("create zlimits and assign value")
    # input("Press Enter to continue...")
    #plt.close('all')


