import numpy as np
import glob
from natsort import natsorted
import os
import shutil
import fnmatch
from tifffile.tifffile import imread


def denoising_score(pth_trainset_all, denoise_epoch_choose):

    numpix_bg = 50

    zcnt = [] #can be separate trainset for each z, so start the count up here 
    for pth_trainset in pth_trainset_all: #for all trained models (could be all z slices or each individually)
    
        fldr_chex = natsorted(glob.glob(os.path.join(pth_trainset, 'DataFolderIs_*')))
        for fcxi,fcx in enumerate(fldr_chex):
            if fcxi!=len(fldr_chex)-1:
                print("deleting this denoise test folder from old run")
                print(fcx)
                shutil.rmtree(fcx)
    
        ecnt = 0
        fldr_outtiff_all = natsorted(glob.glob(os.path.join(pth_trainset, 'DataFolderIs_*', 'E_*'))) #for all epochs that were used for denoising, organize tif files into single folder in 'denoised' folder
        for fldr_outtiff in fldr_outtiff_all:

            mtchs = [fnmatch.fnmatch(fldr_outtiff.split('/')[-1], 'E_' + "{:02d}".format(tmp) + '_Iter_*') for tmp in list(denoise_epoch_choose)]
            mtch = [i for i, x in enumerate(mtchs) if x]
            if len(mtch)>1:
                raise Exception("should be one epoch match for each training folder")
            elif len(mtch)==1: #if there is one match, operate on it 
                ecnt = ecnt+1

                pth_denoised_singles = natsorted(glob.glob(os.path.join(fldr_outtiff, '*output.tif'))) #or separate z could be here, if all z trained single model

                for fni,f in enumerate(pth_denoised_singles):
                    if len(zcnt)<ecnt:
                        zcnt.append(0)
                    else:
                        zcnt[ecnt-1] = zcnt[ecnt-1] + 1
                    print(f)
                    sliceind = int(f.split('/')[-1].split('_')[3])
                    Ynew = imread(f)
                    if Ynew.dtype!='uint16':
                        print("warning, converting type from " + str(Ynew.dtype))
                        if np.min(Ynew)<0 or np.max(Ynew) > 65535:
                            raise Exception("denoising have operated on uint16 for this pipeline, or adjust it")
                        Ynew = Ynew.astype('uint16')

                    mnt = np.mean(Ynew, axis=0)
                    srti = np.argsort(mnt, axis=None)
                    srti = srti[:numpix_bg] #numpix_bg pixels with smallest intensity         
                    srtv = mnt[np.unravel_index(srti, mnt.shape)]
                    Ynew = Ynew.reshape(Ynew.shape[0],-1)
                    Ynew = Ynew[:,srti]
                    if zcnt[ecnt]==0: #the first slice for its epoch
                        if ecnt==0:
                            runtot_val = srtv
                            ytmpnew = Ynew
                        else:
                            runtot_val=np.stack((runtot_val, srtv), axis=0)
                            ytmpnew=np.stack((ytmpnew, Ynew), axis=0)
                    else:
                        valboth = np.concatenate((runtot_val, srtv), axis=0)
                        srtindsboth = np.argsort(valboth, axis=None)
                        topinds = srtindsboth[:numpix_bg]
                        botinds = srtindsboth[-numpix_bg:]
                        indsin = topinds[topinds >= numpix_bg] - numpix_bg
                        indsout = botinds[botinds < numpix_bg]
                        runtot_val[ecnt,indsout] = srtv[indsin]
                        ytmpnew[ecnt,:,indsout] = Ynew[:,indsin]
                        dnsctmp = np.mean(np.std(ytmpnew[ecnt,:,:], axis=0))
                    if ecnt==0:
                        dnsc = dnsctmp #denoising score, average std in unlabaled brain (underfit and overfit are higher than "optimal model")
                    else:
                        dnsc = np.stack((dnsc, dnsctmp), axis=0)


    bestepoch = denoise_epoch_choose[np.argmin(dnsc)]
    
    return bestepoch
