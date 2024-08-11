import numpy as np
import glob
from natsort import natsorted
import os
import shutil
import fnmatch
from tifffile.tifffile import imread
from plot_gif import plot_gif
import matplotlib.pyplot as plt
from pathlib import Path

def denoising_score(pth_trainset_all, epoch_choose_denoise, pth_tif_read, dims_pre_denoise):


    #this function defines the best epoch as the epoch with the smallest standard deviation in the background (in theory, background is unlabaled brain) 
    #also plots gif num_gif_frames of each epoch in epoch_choose_denoise, each z slice, 
    #this function defines background as a set of numpix_bg pixels with the lowest time-averaged intensity, 
    #the background set is updated as slices are loaded
    #the denoising score derived from the background set is also updated as slices are loaded
    #doing it this way saves RAM because models can be trained on each slice, 
    #so rather than accumulating the entire stack for each epoch then, with all epoch's stacks in memory, computing score on each
    #this function updates the score as slices are loaded, without having to accumulate the entire stack for each epoch  

    #denoising score is the average of the standard deviation (through time) of all background pixels 
    #the epoch with the lowest denoising score is the best model (bestepoch) because s.d. is higher for overfit and underfit models 
    #outside this function bestepoch is used to create the denoised stack (suffix cmrg_dcdn_.tif) 

    #background could be computed more flexibly with thresholding; 
    #a triangle threshold would work for most of our data, since often our background is clearly distinguished from foreground
    #but in case it's not (e.g. various cells with various distinct intensity distributions), simple global thresholding could fail
    #so it seemed simpler to hard code a small number of pixels (default numpx_bg is 30)
    #if your stack does not have any background this method might not work
    #in any case, inspect the output gifs for each epoch to be sure  

    #this function concatenates (numpy.stack) rather than preallocates because the number of epochs and slices matching input criteria is not easily available (it could be determined though, but these stacked arrays are small, so it's fine)  
    #also, in case training stops prematurely (preemption or error) this will find the best epoch from whatever is available 
    #however, concatenating makes the code much uglier

    #choosing the best epoch during stitching (after all epochs have run), rather than early stopping during denoising (once the denoising score starts to rise after reaching a minimum), means you may run denoising for longer than necessary, 
    #but the requested O2 resources will be left unused with early stopping, which hurts your priority score, and the extra time denoising is order hours  

    #todo: maybe background should be per slice, not whole stack;
    #todo: background should be computed on un-denoised stack, not on each epoch of denoised stack (but probably doesn't actually matter); it would simplify the code below to compute background once (on cmrg_.tif) before looping through epochs/slices 

    print("\n\n\nFINDING BEST DENOISING EPOCH")
    
    numpix_bg = 300 #how many pixels to consider background (unlabeled brain)
    num_gif_frames = 50 #how many frames of each epoch, each z slice to plot in gif for comparison of epochs after best epoch is selected in denoising_score (gifs only plotted if code enters denoising_score, ie if len(epoch_choose_denoise)>1 )
    do_plot_gif = 1 #plot sample gifs of all epochs all slices, to visually inspect and be sure best epoch is chosen

    zcnt = [] #can be separate trainset for each z, so start the count up here 
    for pth_trainset in pth_trainset_all: #for all trained models (could be all z slices in one model or each z slice individually)
    
        fldr_chex = natsorted(glob.glob(os.path.join(pth_trainset, 'DataFolderIs_*')))
        for fcxi,fcx in enumerate(fldr_chex):
            if fcxi!=len(fldr_chex)-1:
                print("deleting this denoise test folder from old run")
                print(fcx)
                shutil.rmtree(fcx)
    
        ecnt = -1
        fldr_outtiff_all = natsorted(glob.glob(os.path.join(pth_trainset, 'DataFolderIs_*', 'E_*'))) #for all epochs that were used for denoising, organize tif files into single folder in 'denoised' folder
        for fldr_outtiff in fldr_outtiff_all:

            mtchs = [fnmatch.fnmatch(fldr_outtiff.split('/')[-1], 'E_' + "{:02d}".format(tmp) + '_Iter_*') for tmp in list(epoch_choose_denoise)]
            mtch = [i for i, x in enumerate(mtchs) if x]
            if len(mtch)>1:
                raise Exception("should be one epoch match for each training folder")
            elif len(mtch)==1: #if there is one match, operate on it 
                ecnt = ecnt+1

                pth_denoised_singles = natsorted(glob.glob(os.path.join(fldr_outtiff, '*output.tif'))) #or separate z could be here, if all z trained single model

                for f in pth_denoised_singles:
                    if len(zcnt)<ecnt+1:
                        zcnt.append(0)
                    else:
                        zcnt[ecnt] = zcnt[ecnt] + 1
                    sliceind = int(f.split('/')[-1].split('_')[3])
                    ytmp = imread(f)
                    if ytmp.dtype!='uint16':
                        print("warning, converting type from " + str(ytmp.dtype))
                        if np.min(ytmp)<0 or np.max(ytmp) > 65535:
                            raise Exception("denoising have operated on uint16 for this pipeline, or adjust it")
                        ytmp = ytmp.astype('uint16')

                    # if zcnt[ecnt]==4:
                    #     dnsc_override = np.mean(np.std(ytmp[:,50:60,100:115], axis=0))

                    if do_plot_gif:
                        pth_gif_fldr = '/'.join(pth_tif_read.split('/')[:-1]) + '/dcdn_gif_samp/'
                        pth_gif = pth_gif_fldr + pth_tif_read.split('/')[-1][:-4] + 'dcdn_z' + str(sliceind) + '_e' + str(epoch_choose_denoise[ecnt]) + '_samp_.gif'
                        if not os.path.exists(pth_gif_fldr):
                            Path(pth_gif_fldr).mkdir(parents=True, exist_ok=True)
                        plot_gif(ytmp, pth_gif, indst = slice(0, num_gif_frames, 1))  
                        plt.close('all')

                    mnt = np.mean(ytmp, axis=0)
                    srti = np.argsort(mnt, axis=None)
                    srti = srti[:numpix_bg] #numpix_bg pixels with smallest intensity     
                    srtiz = srti+mnt.size*zcnt[ecnt]    
                    srtv = mnt[np.unravel_index(srti, mnt.shape)]
                    ytmp = ytmp.reshape(ytmp.shape[0],-1)
                    ytmp = ytmp[:,srti]
                    if zcnt[ecnt]==0: #the first slice for its epoch
                        if ecnt==0:
                            runtot_inds = srtiz
                            runtot_val = srtv
                            ytmpnew = ytmp
                        else:
                            runtot_inds=np.column_stack((runtot_inds, srtiz))
                            runtot_val=np.column_stack((runtot_val, srtv))
                            ytmpnew=np.dstack((ytmpnew, ytmp))
                    else:
                        if ecnt==0:
                            valboth = np.concatenate((runtot_val, srtv), axis=0)
                        else:
                            valboth = np.concatenate((runtot_val[:,ecnt], srtv), axis=0)
                        srtindsboth = np.argsort(valboth, axis=None)
                        topinds = srtindsboth[:numpix_bg]
                        botinds = srtindsboth[-numpix_bg:]
                        indsin = topinds[topinds >= numpix_bg] - numpix_bg
                        indsout = botinds[botinds < numpix_bg]
                        if ecnt==0:
                            runtot_inds[indsout] = srtiz[indsin]
                            runtot_val[indsout] = srtv[indsin]
                            ytmpnew[:,indsout] = ytmp[:,indsin]
                        else:
                            runtot_inds[indsout,ecnt] = srtiz[indsin]
                            runtot_val[indsout,ecnt] = srtv[indsin]
                            ytmpnew[:,indsout,ecnt] = ytmp[:,indsin]
                    if ecnt==0:
                        dnsc = np.mean(np.std(ytmpnew, axis=0)) #denoising score, average std in unlabaled brain (underfit and overfit are higher than "optimal model")
                        print("\n\n\nAFTER LOADING THE FOLLOWING DENOISED SLICE: \n" + f + "\nWHICH IS DENOISED SLICE #" + str(zcnt[ecnt]) + " (STACK SLICE #" + str(sliceind) + "), THE UPDATED DENOISING SCORE IS: " + str(dnsc))
                    else:
                        dnsctmp = np.mean(np.std(ytmpnew[:,:,ecnt], axis=0))
                        if zcnt[ecnt]==0: 
                            dnsc = np.append(dnsc,dnsctmp)
                        else:
                            dnsc[ecnt] = dnsctmp
                        print("\n\n\nAFTER LOADING THE FOLLOWING DENOISED SLICE: \n" + f + "\nWHICH IS DENOISED SLICE #" + str(zcnt[ecnt]) + " (STACK SLICE #" + str(sliceind) + "), THE UPDATED DENOISING SCORE IS: " + str(dnsc[ecnt]))
                    

                    # if zcnt[ecnt]==dims_pre_denoise[1]-1:
                    #     print("\n\n\nOVERRIDING WITH SCORE: " + str(dnsc_override))
                    #     if ecnt==0:
                    #         dnsc = dnsc_override
                    #     else:
                    #         dnsc[ecnt] = dnsc_override

    # for ei in np.arange(runtot_inds.shape[1]): #make sure background inds don't vary too much across epochs (in future just derive background from stack before denoising, but for now make sure background is fairly stable across epochs, which it seems to be so far)
    #     tmpinds = np.unravel_index(runtot_inds[:,ei], (mnt.shape[:]+ (dims_pre_denoise[1],)))
    #     print("epoch " + str(ei) + " x inds")
    #     print(tmpinds[0])
    #     print("epoch " + str(ei) + " y inds")
    #     print(tmpinds[1])
    #     print("epoch " + str(ei) + " z inds")
    #     print(tmpinds[2])
            
    epoch_choose_denoise = list(epoch_choose_denoise)
    for ei, zi in enumerate(zcnt):
        if zi != dims_pre_denoise[1]-1:
            print("not all slices present in epoch " + str(epoch_choose_denoise[ei]) + ", removing it from consideration")
            dnsc[ei] = np.max(dnsc)+1 #make incomplete epoch denoising score bigger than max so it can't be chosen as best epoch

    bestepoch = epoch_choose_denoise[np.argmin(dnsc)]

    print("\n\n\nBEST EPOCH IS EPOCH #" + str(bestepoch) + " STITCHING ITS OUTPUT TIFS TOGETHER INTO DENOISED STACK")
    
    return bestepoch
