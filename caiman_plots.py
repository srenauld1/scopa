
import matplotlib.pyplot as plt
import numpy as np
import caiman as cm
from caiman.summary_images import local_correlations_movie_offline

def compute_correlations(fname, dims):
    
    dview = None 

    Y = cm.load(fname)
    Cn = cm.local_correlations(Y, swap_dim=False)
    d1, d2, d3 = dims
    x, y = (int(1.2 * (d1 + d3)), int(1.2 * (d2 + d3)))
    scale = 6/x
    fig = plt.figure(figsize=(scale*x, scale*y))
    axz = fig.add_axes([1-d1/x, 1-d2/y, d1/x, d2/y])
    plt.imshow(Cn.max(2).T, cmap='gray')
    plt.title('Max.proj. z')
    plt.xlabel('x')
    plt.ylabel('y')
    axy = fig.add_axes([0, 1-d2/y, d3/x, d2/y])
    plt.imshow(Cn.max(0), cmap='gray')
    plt.title('Max.proj. x')
    plt.xlabel('z')
    plt.ylabel('y')
    axx = fig.add_axes([1-d1/x, 0, d1/x, d3/y])
    plt.imshow(Cn.max(1).T, cmap='gray')
    plt.title('Max.proj. y')
    plt.xlabel('x')
    plt.ylabel('z');
    plt.show()

    # wind = int(np.round(T / 6))
    # windb = int(np.round(T / 12))
    # Cns = local_correlations_movie_offline(fname,
    #                         remove_baseline=True, swap_dim=False, 
    #                         window=wind, stride=wind, winSize_baseline=windb, #example values were 1000,1000,100
    #                         quantil_min_baseline=10, dview=dview)
    # print(Cns.shape)
    # Cn = Cns.max(axis=0)
    # print(Cn.shape)

    return Cn

