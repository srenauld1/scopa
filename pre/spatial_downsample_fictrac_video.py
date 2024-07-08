    
import cv2
import numpy as np
import matplotlib.pyplot as plt
from vis import plot_gif
import scipy.io as sio

def spatial_downsample_fictrac_video(pth_ftvid, pth_prefix, makeplots):

    #downsample in xy, also convert RGB to grayscale, save as uint8 mat file; does not downsample in time (that occurs in matlab, depending on analysis)

    print("\n\n\nENTERING spatial_downsample_fictrac_video")

    hack_vid_length = 1
    ftv_dsfac_x = 0.25 #downsample factor in x (linear interp)
    ftv_dsfac_y = 0.25 #downsample factor in y (linear interp)

    ftvcap = cv2.VideoCapture(pth_ftvid)
    
    if ftvcap.isOpened():
        if hack_vid_length:  #preallocation hack because CAP_PROP_FRAME_COUNT is not always accurate and I don't want to figure out how to deal with variable codec or whatever is the cause 
            max_num_min = 60 #assume nobody makes a fictrac video longer than 60 min 
            approximate_ft_rate = 60 #hz
            ftvlen = int(max_num_min*60*approximate_ft_rate)
            print("hacking fictrac video length, if your video is longer than 60 min at ~60 Hz, preallocate larger array")
        else:
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
            break

        
    ftvds = ftvds[:frcnt,:,:] #in case hack_vid_length, crop to last written frame
    print("fictrac video has been downsampled and converted to grayscale; new size is: \n" + str(ftvds.shape))

    pth_ftvid_ds = pth_prefix + '_FTV_DS_.mat'
    sio.savemat(pth_ftvid_ds, {'ftvds':ftvds}) #save for matlab part of pipeline 

    print("saved downsampled, grayscale fictrac video to this mat file: \n" + pth_ftvid_ds)

    if makeplots:
        pth_ftvid_gif = pth_ftvid_ds[:-4] + '.gif'
        numframes_gif = 200 #for equidistant frames across entire video
        gifstep = int(ftvds.shape[0]/numframes_gif)
        if gifstep==0:
            gifstep = 1
        plot_gif(ftvds, pth_ftvid_gif, indst = slice(0, ftvds.shape[0], gifstep), indimord = 'yx') 