
import numpy as np
import os
from tifffile.tifffile import imwrite, imread

import caiman as cm
import caiman.source_extraction.cnmf as cnmf
from configs import configs
from helpers import separate_z_slices_before_denoising, tracefunc 
from subtract_background import bgremover

def register(pth_datafile, fn_prefix, pth_prefix, pth_tif_reg_tmp, pth_tif_reg, pth_denoising, md, 
             do_background_subtraction, bg_patch_halfwidth, denoise_volume, cluster_backend, do_cluster):

    if do_cluster:
        if 'dview' in locals(): cm.stop_server(dview=dview)
        cc, dview, n_processes = cm.cluster.setup_cluster(backend=cluster_backend, n_processes=None, single_thread=False)
    else:
        n_processes = 1 #set this in case you don't (or can't) setup cluster 
        dview = None #set this in case you don't (or can't) setup cluster
        

    ##########################   BACKGROUND SUBTRACTION AND CAIMAN NORMCORRE MOTION CORRECTION   ##########################

    Y = imread(pth_datafile).astype('float32') ##having trouble on O2 with caiman function cm.load so just using imread from tifffile.tifffile
    
    Y = Y.reshape(md['dims'][0], md['dims'][1]+md['flyback'], md['dims'][2], md['dims'][3])
        
    if md['flyback']!=0:    
        Y = Y[:,:-md['flyback'],:,:] #crop md['flyback'] frames

    #Y[540:600,4,:,:].play(magnification=2) #play in order t z y x
    Y = np.transpose(Y, (0, 3, 2, 1)) #put in order t x y z 
    
    mnmv = np.min(Y)
    Y = Y - mnmv #make movie nonnegative (not sure this is necessary)
    print("MIN BEFORE MOTION CORRECTION " + str(mnmv))
    
    if do_background_subtraction:
                    
        if Y.shape[3]==1: #if it's not volumetric
            zindall = [0]
        else:
            zindall = np.arange(Y.shape[3])

        for zind in zindall: #for every z slice 

            dimorder = 'txy' 
            pth_bgplot_save = pth_prefix + '_' + str(zind)
            br = bgremover(Y[:,:,:,zind], pth_bgplot_save, half_wid=bg_patch_halfwidth, dimorder=dimorder)
            br.draw_patches()
            br.remove_bg()
            br.make_plots()
            Y[:,:,:,zind] = np.transpose(br.out, (0, 2, 1))
                
        mnmv = np.min(Y)
        Y = Y - mnmv #make movie nonnegative (not sure this is necessary)
        print("MIN BEFORE MOTION CORRECTION AFTER BG SUB" + str(mnmv))
                        
    imwrite(pth_tif_reg_tmp, Y.squeeze()) #write as t x y z (z might be singleton for non-volumetric data, so squeeze)

    min_mov = np.min(Y)
    opts_dict, indices_ex, fnadd = configs(index_extraction_param_set = 'default', fnames = pth_tif_reg_tmp, min_mov = min_mov, md = md) #configs for motion correction (will also define for extraction, but extraction params are in redefined later call to configs)
    opts = cnmf.params.CNMFParams(params_dict=opts_dict)

    #sys.setprofile(tracefunc)
    mc = cm.motion_correction.MotionCorrect([pth_tif_reg_tmp], dview=dview, **opts.get_group('motion'))
    mc.motion_correct(save_movie=True)
    os.remove(pth_tif_reg_tmp)

    border_to_0 = 0 if mc.border_nan == 'copy' else mc.border_to_0 
    basename_memap = pth_tif_reg.split('/')[-1][:-4]
    pth_mmap_reg = cm.save_memmap(mc.mmap_file, base_name=basename_memap, order='C', border_to_0=border_to_0, dview=dview) # save in order C (motion_correct above has to save in order F)
    Y, dims_spatial_rg, dim_time_rg = cm.load_memmap(pth_mmap_reg) 
    Y = np.reshape(Y.T, [dim_time_rg] + list(dims_spatial_rg), order='F') 
    
    mnmv = np.min(Y)
    Y = Y - mnmv #make nonnegative before writing to uint16
    print("MIN AFTER MOTION CORRECTION " + str(mnmv))

    os.remove(mc.mmap_file[0]) #remove the mmap file in F order 
    os.remove(pth_mmap_reg) #remove the mmap file in C order 
    
    if md['dims'][1]==1:
        imwrite(pth_tif_reg, np.transpose(Y.astype('uint16'), (0, 2, 1)).reshape(dim_time_rg, dims_spatial_rg[1], dims_spatial_rg[0])) #write the registered movie as tif (uint16) for use in matlab, and caiman extraction below
    else:
        imwrite(pth_tif_reg, np.transpose(Y.astype('uint16'), (0, 3, 2, 1)).reshape(dim_time_rg * dims_spatial_rg[2], dims_spatial_rg[1], dims_spatial_rg[0])) #write the registered movie as tif (uint16) for use in matlab, and caiman extraction below


    # FINAL PART OF MOTION CORECTION SECTION  is to prepare files for denoising 
    # by writing each z slice to separate tif and put them in separate folders 
    # (since default in denoise.py is denoise_volume = 0 )
    # if using denoise_volume = 1, just move all separate tifs into one folder (might build this if clause) 
    # (do this cpu-intensive part outside denoise.py, which is gpu-intensive, and called with different O2 resources)
    separate_z_slices_before_denoising(pth_tif_reg, fn_prefix, pth_denoising, md['dims'], denoise_volume)
