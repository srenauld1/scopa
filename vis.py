
import numpy as np
import time
import caiman as cm

import matplotlib
from matplotlib import colors
import matplotlib.pyplot as plt
import matplotlib.animation as animation

from skimage.util import montage
    
from caiman.summary_images import local_correlations_movie_offline


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


def plot_gif(data, indy):
    
    matplotlib.use("Agg")

    def update_im(num, data, img):
        img.set_data(data[num,:,:])
        return img,

    Writer = animation.writers['ffmpeg']
    writer = Writer(fps=15, metadata=dict(artist='Me'), bitrate=100)

    fig1 = plt.figure()
    img = plt.imshow(data[0,:,:])

    plt.title('test')
    fram = np.arange(1,data.shape[0])
    line_ani = animation.FuncAnimation(fig1, update_im, fram, fargs=(data, img), interval=50, blit=True)
    filename_gif = '/Users/wienecke/Documents/ambrose/testnew' + str(indy) + '.gif'
    line_ani.save(filename_gif, writer=writer)


def caiman_plots_all(cnm, opts, images_sliced, dims_spatial, do_planar_extraction, pth_results):

    if do_planar_extraction:
        #Cn_o = compute_correlations(pth_mmap_reg[0], dims_spatial)
        Cn = cm.local_correlations(images_sliced.transpose(1,2,0))
        print(Cn.shape)
        Cn[np.isnan(Cn)] = 0
        print('you may need to change the data rate to generate nb_view_components: use jupyter notebook --NotebookApp.iopub_data_rate_limit=1.0e10 before opening jupyter notebook')                
        cnm.estimates.plot_contours(img=Cn) #img=None for mean projection
        cnm.estimates.view_components(img=Cn)
        cnm.estimates.play_movie(images_sliced, q_min=1, q_max=99.75, gain_res=2, magnification=2, 
                                 include_bck=False, frame_range=slice(0,100,1), bpx=False, thr=1, 
                                 save_movie=True, movie_name=pth_results, display=True, opencv_codec='H264',
                                 use_color=False, gain_color=4, gain_bck=0.2)
        
        # A2 = np.reshape(cnm.estimates.A.toarray(), dims_spatial + (-1,), order='F')
        # A2 = A2.reshape( A2.shape[:-2] + (np.prod(A2.shape[2:]), ) )
        # A2 = A2.transpose([2, 0, 1])
        # Nc = A2.shape[0]
        # grid_shape = (np.ceil(np.sqrt(Nc/2)).astype(int), np.ceil(np.sqrt(Nc*2)).astype(int))
        # plt.figure(figsize=np.array(grid_shape[::-1])*1.5)
        # plt.imshow(montage(A2, rescale_intensity=True, grid_shape=grid_shape, padding_width=5))
        # plt.axis('off')

    else:
        cnm.estimates.nb_view_components_3d(image_type='mean', dims_spatial=dims_spatial, axis=2)
        #cnm2.estimates.nb_view_components_3d(image_type='corr', dims_spatial=dims_spatial, Yr=Yr, denoised_color='red', max_projection=True);

    #denoised_movie = cm.movie(cnm2.estimates.A.dot(cnm2.estimates.C) + \
    #            cnm2.estimates.b.dot(cnm2.estimates.f)).reshape(dims_spatial + (-1,), order='F').transpose([3, 0, 1, 2]) #%% reconstruct denoised movie 

"""
arguments for cnm.estimates.play_movie

Displays a movie with three panels (original data (left panel),
        reconstructed data (middle panel), residual (right panel))


            imgs: np.array (possibly memory mapped, t,x,y[,z])
                Imaging data

            q_max: float (values in [0, 100], default: 99.75)
                percentile for maximum plotting value

            q_min: float (values in [0, 100], default: 1)
                percentile for minimum plotting value

            gain_res: float (1)
                amplification factor for residual movie

            magnification: float (1)
                magnification factor for whole movie

            include_bck: bool (True)
                flag for including background in original and reconstructed movie

            frame_range: range or slice or list (default: slice(None))
                display only a subset of frames

            bpx: int (default: 0)
                number of pixels to exclude on each border

            thr: float (values in [0, 1[) (default: 0)
                threshold value for contours, no contours if thr=0

            save_movie: bool (default: False)
                flag to save an avi file of the movie

            movie_name: str (default: 'results_movie.avi')
                name of saved file

            display: bool (default: True)
                flag for playing the movie (to stop the movie press 'q')

            opencv_codec: str (default: 'H264')
                FourCC video codec for saving movie. Check http://www.fourcc.org/codecs.php

            use_color: bool (default: False)
                flag for making a color movie. If True a random color will be assigned
                for each of the components

            gain_color: float (default: 4)
                amplify colors in the movie to make them brighter

            gain_bck: float (default: 0.2)
                dampen background in the movie to expose components (applicable
                only when color is used.)
"""

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



