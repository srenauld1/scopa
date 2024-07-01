    
import cv2
import numpy as np
import matplotlib.pyplot as plt
from vis import plot_gif
import scipy.io as sio

def downsample_fictrac_video_xyc(pth_ftvid, pth_prefix, makeplots):

    #downsample in xy, also convert RGB to grayscale, save as uint8 mat file; does not downsample in time (that occurs in matlab, depending on analysis)

    print("entering downsample_fictrac_video")

    ftv_dsfac_x = 0.25 #downsample factor in x (linear interp)
    ftv_dsfac_y = 0.25 #downsample factor in y (linear interp)

    ftvcap = cv2.VideoCapture(pth_ftvid[0])
    
    if ftvcap.isOpened():
        ftvlen = int(ftvcap.get(cv2.CAP_PROP_FRAME_COUNT)) #int will take floor
        ftvw  = ftvcap.get(cv2.CAP_PROP_FRAME_WIDTH)
        ftvw_ds = int(ftvw*ftv_dsfac_x) #int will take floor
        ftvh = ftvcap.get(cv2.CAP_PROP_FRAME_HEIGHT)
        ftvh_ds = int(ftvh*ftv_dsfac_y) #int will take floor
    else:
        print("could not read fictrac video, skipping conversion")
    
    ftvds = np.zeros((ftvlen+1, ftvh_ds, ftvw_ds), dtype='uint8') #ftvlen+1 since CAP_PROP_FRAME_COUNT is one-indexed
    ret = True
    frcnt = 0
    while True:
        ret, ftvfr = ftvcap.read()
        if ret:
            grfr = cv2.cvtColor(ftvfr, cv2.COLOR_RGB2GRAY)
            grfr = cv2.resize(grfr, (0,0), fx=ftv_dsfac_x, fy=ftv_dsfac_y) 
            ftvds[frcnt,:,:] = grfr
            frcnt = frcnt+1
        else:
            print("fictrac video has been downsampled and converted to grayscale")
            break


    pth_ftvid_ds = pth_prefix + '_FTV_DS_.mat'
    sio.savemat(pth_ftvid_ds, {'ftvds':ftvds}) #save for matlab part of pipeline 

    print("saved downsample, grayscale fictrac video to this mat file: \n" + pth_ftvid_ds)

    if makeplots:
        pth_ftvid_gif = pth_ftvid_ds[:-4] + '.gif'
        numframes_gif = 200 #for equidistant frames across entire video
        plot_gif(ftvds, pth_ftvid_gif, indst = slice(0, ftvds.shape[0], int(ftvlen/numframes_gif)), indimord = 'yx') 