import numpy as np
import glob
from natsort import natsorted
import os
import shutil
import fnmatch
from tifffile.tifffile import imread
from plot_gif import plot_gif


def denoising_score(pth_trainset_all, epoch_choose_denoise, numpix_bg, num_gif_frames, pth_gif_prefix):


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

    #todo: maybe background should be per slice, not whole stack; and probably background should be computed on un-denoised stack, not on each epoch of denoised stack (but probably doesn't matter)

    print("\n\n\nFINDING BEST DENOISING EPOCH")


    zcnt = [] #can be separate trainset for each z, so start the count up here 
    for pth_trainset in pth_trainset_all: #for all trained models (could be all z slices or each individually)
    
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

                    pth_gif = pth_gif_prefix + 'dcdn_z' + str(sliceind) + '_e' + str(epoch_choose_denoise[ecnt]) + '_samp_.gif'
                    plot_gif(ytmp, pth_gif, indst = slice(0, num_gif_frames, 1))  

                    mnt = np.mean(ytmp, axis=0)
                    srti = np.argsort(mnt, axis=None)
                    srti = srti[:numpix_bg] #numpix_bg pixels with smallest intensity         
                    srtv = mnt[np.unravel_index(srti, mnt.shape)]
                    ytmp = ytmp.reshape(ytmp.shape[0],-1)
                    ytmp = ytmp[:,srti]
                    if zcnt[ecnt]==0: #the first slice for its epoch
                        if ecnt==0:
                            runtot_val = srtv
                            ytmpnew = ytmp
                        else:
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
                            runtot_val[indsout] = srtv[indsin]
                            ytmpnew[:,indsout] = ytmp[:,indsin]
                        else:
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
                    
                    # if zcnt[ecnt]!=0:
                    #     print(indsin) #print inds that are going into cumulative record


    bestepoch = epoch_choose_denoise[np.argmin(dnsc)]

    print("\n\n\nBEST EPOCH IS EPOCH #" + str(bestepoch) + " STITCHING ITS OUTPUT TIFS TOGETHER INTO DENOISED STACK")
    
    return bestepoch
