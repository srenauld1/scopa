import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation


def plot_gif(data, filename_gif, indsx = None, indsy = None, indsz = None, indst = None, indimord = 'xy'):

    # by default (indimord = 'xy'), input movie "data" is assumed to be txyz if 4d, or txy if 3d
    # if indimord='yx', data is assumed to be tyxz if 4d, or tyx if 3d

    if indst==None:
        indst = slice(0, data.shape[0], 1) 
    if indsx==None:
        indsx = slice(0, data.shape[1], 1) # convert to zero-indexing, but slice does not include second index so do not subtract one on the 2nd index 
    if indsy==None:
        indsy = slice(0, data.shape[2], 1) 
    if len(data.shape)==4:
        if indsz==None:
            indsz = slice(0, data.shape[3], 1) 

    if len(data.shape)==4:
        data = data[indst,indsx,indsy,indsz]
        if indimord == 'xy':
            data = np.transpose(data, (0, 3, 2, 1)) #put in order (tz) y x
        elif indimord == 'yx':
            data = np.transpose(data, (0, 3, 1, 2)) #put in order (tz) y x
        data = data.reshape(data.shape[0]*data.shape[1], data.shape[2], data.shape[3])
    else:
        data = data[indst,indsx,indsy]
        if indimord == 'xy':
            data = np.transpose(data, (0, 2, 1)) #put in order (tz) y x


    data = data - np.min(data)

    mnmv = np.min(data)
    mxmv = np.max(data)

    #matplotlib.use("Agg")

    def update_im(num, data, img):
        img.set_data(data[num,:,:])
        return img,

    Writer = animation.writers['ffmpeg']
    writer = Writer(fps=15, metadata=dict(artist='Me'), bitrate=100)

    fig1 = plt.figure()
    img = plt.imshow(data[0,:,:], vmin=mnmv, vmax=mxmv)

    plt.title('test')
    fram = np.arange(1,data.shape[0])
    line_ani = animation.FuncAnimation(fig1, update_im, fram, fargs=(data, img), interval=50, blit=True)
    line_ani.save(filename_gif, writer=writer)
