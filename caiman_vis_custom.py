from matplotlib import colors
import matplotlib.pyplot as plt
import numpy as np
import time
import caiman as cm

import matplotlib
import matplotlib.animation as animation

from matplotlib.animation import FuncAnimation, PillowWriter
from skimage.util import montage

def im_series(images):
    for i2 in np.arange(30):
        img = plt.imshow(images[0,:,:,4])
        for i in np.arange(30) + 1:
            img.set_data(images[i,:,:,4])
            plt.draw()

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
    filename_gif = '/Users/wienecke/Documents/ambrose/leprechaunMat/testnew' + str(indy) + '.gif'
    line_ani.save(filename_gif, writer=writer)


def caiman_plots_all(cnm, opts, images_sliced, dims_spatial, do_planar_extraction):

    if do_planar_extraction:
        #Cn_o = compute_correlations(pth_mmap_reg[0], dims_spatial)
        Cn = cm.local_correlations(images_sliced.transpose(1,2,0))
        print(Cn.shape)
        Cn[np.isnan(Cn)] = 0
        print('you may need to change the data rate to generate nb_view_components: use jupyter notebook --NotebookApp.iopub_data_rate_limit=1.0e10 before opening jupyter notebook')                
        cnm.estimates.plot_contours(img=Cn) #img=None for mean projection
        cnm.estimates.view_components(img=Cn)
        cnm.estimates.play_movie(images_sliced, q_max=99.9, gain_res=2, magnification=2, bpx=True, include_bck=False, save_movie=True)
        A2 = cnm.estimates.A.toarray().reshape(opts.data['dims'] + (-1,), order='F').transpose([2, 0, 1])
        Nc = A2.shape[0]
        grid_shape = (np.ceil(np.sqrt(Nc/2)).astype(int), np.ceil(np.sqrt(Nc*2)).astype(int))
        plt.figure(figsize=np.array(grid_shape[::-1])*1.5)
        plt.imshow(montage(A2, rescale_intensity=True, grid_shape=grid_shape))
        plt.axis('off')
    else:
        cnm.estimates.nb_view_components_3d(image_type='mean', dims_spatial=dims_spatial, axis=2)
        #cnm2.estimates.nb_view_components_3d(image_type='corr', dims_spatial=dims_spatial, Yr=Yr, denoised_color='red', max_projection=True);

    #denoised_movie = cm.movie(cnm2.estimates.A.dot(cnm2.estimates.C) + \
    #            cnm2.estimates.b.dot(cnm2.estimates.f)).reshape(dims_spatial + (-1,), order='F').transpose([3, 0, 1, 2]) #%% reconstruct denoised movie 



    





