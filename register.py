
import numpy as np
import os
from tifffile.tifffile import imwrite, imread

import caiman as cm
import caiman.source_extraction.cnmf as cnmf
from configs import configs
from helpers import stitch_registered_z_slices, separate_z_slices_before_denoising, separate_z_slices_before_denoising_carls_old_project, tracefunc 
from subtract_background import bgremover
from scipy.ndimage import gaussian_filter as smooth_movie
from vis import im_montage, plot_gif

def register(pth_datafile, fn_prefix, pth_prefix, pth_tif_reg, pth_denoising, md, 
             do_planar_registration, do_background_subtraction, bg_patch_halfwidth, len_window_smooth_t, 
             denoise_volume, carls_old_project, cluster_backend, do_cluster, do_plots):

    if do_cluster:
        if 'dview' in locals(): cm.stop_server(dview=dview)
        cc, dview, n_processes = cm.cluster.setup_cluster(backend=cluster_backend, n_processes=None, single_thread=False)
    else:
        n_processes = 1 #set this in case you don't (or can't) setup cluster 
        dview = None #set this in case you don't (or can't) setup cluster
        

    pth_tif_reg_tmp = pth_tif_reg[:-4] + 'tmp_.tif'

    ##########################   BACKGROUND SUBTRACTION AND CAIMAN NORMCORRE MOTION CORRECTION   ##########################

    Y = imread(pth_datafile).astype('float32') ##having trouble on O2 with caiman function cm.load so just using imread from tifffile.tifffile
    
    Y = Y.reshape(md['dims'][0], md['dims'][1]+md['flyback'], md['dims'][2], md['dims'][3])
        
    if md['flyback']!=0:    
        Y = Y[:,:-md['flyback'],:,:] #crop md['flyback'] frames

    Y = np.transpose(Y, (0, 3, 2, 1)) #put in order t x y z 
    
    mnmv = np.min(Y)
    Y = Y - mnmv #make movie nonnegative (not sure this is necessary)
    print("MIN BEFORE MOTION CORRECTION " + str(mnmv))
    
    if Y.shape[3]>1:
        movie_is_4d = 1
    elif Y.shape[3]==1:
        movie_is_4d = 0

    if movie_is_4d: 
        zindall = np.arange(Y.shape[3])
    else:
        zindall = [0]
    
    Y = Y.astype('uint16')


    if do_background_subtraction:
                    
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
        Y = Y.astype('uint16')
        print("MIN BEFORE MOTION CORRECTION AFTER BG SUB" + str(mnmv))
                        
   
    if len_window_smooth_t: #if you smooth before registering (very noisy data), create another file for smoothed movie

        if do_planar_registration: #for planar extraction write one presmoothed z at a time
            pth_tif_psm = ['']*len(zindall)
            for zind in zindall: #for every z slice 
                print("WRITING PRESMOOTHED SLICE " + str(zind))
                pth_tif_psm[zind] = pth_tif_reg_tmp[:-4] + str(zind) + '_presmooth_.tif'
                imwrite(pth_tif_psm[zind], Y[:,:,:,zind].squeeze()) 
        else: # 
            print("WRITING ALL PRESMOOTHED SLICES" )
            pth_tif_psm = [pth_tif_reg_tmp[:-4] + 'all_presmooth_.tif']
            imwrite(pth_tif_psm[0], Y.squeeze()) #write as t x y z (z might be singleton for non-volumetric data, so squeeze)
    
        print("SMOOTHING DATA IN TIME BEFORE REGISTRATION")

        dimtmp_presmooth = Y.shape
        numsigma_smooth_prereg = 5.0
        sigma_smooth_prereg = (len_window_smooth_t - 1) / numsigma_smooth_prereg / 2
        Y = smooth_movie(Y.reshape(md['dims'][0], -1), sigma=sigma_smooth_prereg, mode='reflect', truncate=numsigma_smooth_prereg, axes=0)
        Y = Y.reshape(dimtmp_presmooth)
        mnmv = np.min(Y)
        Y = Y - mnmv #make movie nonnegative (not sure this is necessary)
        Y = Y.astype('uint16')
        print("MIN AFTER SMOOTHING " + str(mnmv))

    
    min_mov = np.min(Y)

    if do_planar_registration: 
        sliceindz = zindall
    else:
        sliceindz = [zindall] #all slices in one list (not planar)

    countz = 0
    for si in sliceindz: #for each slice (or all slices if do_planar_extraction = false)

        mc = None

        if do_planar_registration and movie_is_4d: #for planar extraction take on z slice at a time
            print("PLANAR registration FOR SLICE " + str(si))
            images_sliced = Y[:,:,:,si]
        else: # for 3d extraction keep all z slices (for now, until implement z ranges)
            print("3D registration FOR ALL SLICES")
            images_sliced = Y #can't .copy() for some reason (but that's fine as long as you don't modify images_sliced)

        imwrite(pth_tif_reg_tmp, images_sliced.squeeze()) #write as t x y z (z might be singleton for non-volumetric data, so squeeze)
    
        # each_min_mov = 0 # don't think we want to make min mov the min for each z slice 
        # if each_min_mov:
        #     min_mov = np.min(images_sliced)
        
        # FOR SOME REASON CALLING configs OUTSIDE si LOOP CAUSES ALL LOOP ITERATIONS EXCEPT THE FIRST TO HAVE PROBLEMS (PRESUMABLY SOME CONFIG PARAM IS CHANGED ON EACH LOOP) FOR NOW PLACE IT INSIDE LOOP TO RESET ALL CONFIGS SO EACH SLICE GETS THE SAME - IT DOESN'T HURT ANYTHING, IT'S JUST SLIGHTLY INEFFICIENT 
        opts_dict, indices_ex, fnadd = configs(do_planar_registration = do_planar_registration, index_extraction_param_set = 'default', fnames = pth_tif_reg_tmp, min_mov = min_mov, md = md) #configs for motion correction (will also define for extraction, but extraction params are in redefined later call to configs)
        opts = cnmf.params.CNMFParams(params_dict=opts_dict)

        #sys.setprofile(tracefunc)
        mc = cm.motion_correction.MotionCorrect([pth_tif_reg_tmp], dview=dview, **opts.get_group('motion'))
        mc.motion_correct(save_movie=True)
        input_for_save_memmap = mc.mmap_file #create this variable because it can be memmap file or ndarray
        if len_window_smooth_t: #apply shifts learned from smoothed movie to the raw movie (we don't want smoothed movie ultimately)
            input_for_save_memmap = mc.apply_shifts_movie(pth_tif_psm[countz], save_memmap=False, order='F') #for some reason cannot save_memmap
            input_for_save_memmap = [input_for_save_memmap] #so must pass nd array to save_memmap below
            os.remove(pth_tif_psm[countz])

        os.remove(pth_tif_reg_tmp)

        border_to_0 = 0 if mc.border_nan == 'copy' else mc.border_to_0 
        basename_memap = pth_tif_reg.split('/')[-1][:-4]
        pth_mmap_reg = cm.save_memmap(input_for_save_memmap, base_name=basename_memap, order='C', border_to_0=border_to_0, dview=dview) # save in order C (motion_correct above has to save in order F)
        Ynew, dims_spatial_rg, dim_time_rg = cm.load_memmap(pth_mmap_reg) 
        Ynew = np.reshape(Ynew.T, [dim_time_rg] + list(dims_spatial_rg), order='F') 


        os.remove(mc.mmap_file[0]) #remove the mmap file in F order 
        os.remove(pth_mmap_reg) #remove the mmap file in C order 
        
        if do_planar_registration and movie_is_4d:
            pth_write = pth_tif_reg[:-4] + str(si) + '_z_.tif'
        else:
            pth_write = pth_tif_reg
            mnmv = np.min(Ynew)
            Ynew = Ynew - mnmv #make nonnegative before writing to uint16
            print("MIN AFTER MOTION CORRECTION " + str(mnmv))
            if do_plots:
                mxmv = np.max(Y)
                #im_montage(Ynew[10,:,:,:], vmin=mnmv, vmax=mxmv) #view montage to check registration
                plot_gif(Ynew, indst = slice(0, 20, 1))  #view gif to check registration, can pass xyzt indices, otherwise will do all indices for each 

        if len(Ynew.shape)==3:# or Y.shape[3]==1:
            imwrite(pth_write, np.transpose(Ynew.astype('uint16'), (0, 2, 1)).reshape(dim_time_rg, dims_spatial_rg[1], dims_spatial_rg[0])) #write the registered movie as tif (uint16) for use in matlab, and caiman extraction below
        else:
            imwrite(pth_write, np.transpose(Ynew.astype('uint16'), (0, 3, 2, 1)).reshape(dim_time_rg * dims_spatial_rg[2], dims_spatial_rg[1], dims_spatial_rg[0])) #write the registered movie as tif (uint16) for use in matlab, and caiman extraction below

        countz = countz + 1

    Y = None

    if do_planar_registration and movie_is_4d:
        stitch_registered_z_slices(pth_tif_reg, md['dims'], do_plots)

    # FINAL PART OF MOTION CORECTION SECTION  is to prepare files for denoising 
    # by writing each z slice to separate tif and put them in separate folders 
    # (since default in denoise.py is denoise_volume = 0 )
    # if using denoise_volume = 1, just move all separate tifs into one folder (might build this if clause) 
    # (do this cpu-intensive part outside denoise.py, which is gpu-intensive, and called with different O2 resources)
    if carls_old_project: #if it's not my old project 
        separate_z_slices_before_denoising_carls_old_project(pth_tif_reg, fn_prefix, pth_denoising, md['dims'], denoise_volume)
    else:
        separate_z_slices_before_denoising(pth_tif_reg, fn_prefix, pth_denoising, md['dims'], denoise_volume)
