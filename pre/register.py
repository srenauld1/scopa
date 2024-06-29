
import numpy as np
import os
from tifffile.tifffile import imwrite, imread

import caiman as cm
import caiman.source_extraction.cnmf as cnmf
from configs import configs
from helpers import stitch_registered_z_slices, separate_z_slices_for_denoising, separate_z_slices_for_denoising_carls_old_project, tracefunc 
from registration_template import find_registration_template
from subtract_background import bgremover
from scipy.ndimage import gaussian_filter as smooth_movie
from vis import im_montage, plot_gif


def register(pth_tif_read, pth_prefix, pth_allrec, md, registration_template_group_id, register_in_2d, halfwidth_window_bgsub, len_window_smooth_t_mcp, fn_prefix, pth_denoising, denoise_volume, carls_old_project, cluster_backend, use_cluster, makeplots):
   

    ########################## LOAD STACK, PREPARE VARIABLES ##########################

    print("\n\n\nENTERING REGISTRATION SCRIPT")

    if use_cluster:
        if 'dview' in locals(): cm.stop_server(dview=dview)
        cc, dview, n_processes = cm.cluster.setup_cluster(backend=cluster_backend, n_processes=None, single_thread=False)
    else:
        n_processes = 1 #set this in case you don't (or can't) setup cluster 
        dview = None #set this in case you don't (or can't) setup cluster
        
    if halfwidth_window_bgsub:
        pth_tif_write = pth_prefix + '_bksb_cmrg_.tif'
    else:
        pth_tif_write = pth_prefix + '_cmrg_.tif'

    pth_tif_write_tmp = pth_tif_write[:-4] + 'tmp_.tif'

    Y = imread(pth_tif_read).astype('float32') ## (tz)yx, or if multiple channels, (tz)cyx 
    
    if not isinstance(md['channelSave'], int):
        if len(md['channelSave'])==2:
            print("stack has 2 channels, discarding the first as temporary hack")
            keepchannel = 0 #which channel to keep, 0 or 1
            Y = Y[:,keepchannel,:,:]
        else:
            raise Exception("there is a channels problem")
        
    Y = Y.reshape(md['dims'][0], md['dims'][1]+md['flyback'], md['dims'][2], md['dims'][3])
        
    if md['flyback']!=0:    
        Y = Y[:,:-md['flyback'],:,:] #crop md['flyback'] frames

    Y = np.transpose(Y, (0, 3, 2, 1)) #put in order t x y z 

    mnmv = np.min(Y).astype('float32')
    Y -= mnmv #make movie nonnegative (not sure this is necessary)
    print("MIN BEFORE MOTION CORRECTION " + str(mnmv))

    if makeplots:
        mxmv = np.max(Y)
        #im_montage(Ynew[10,:,:,:], vmin=mnmv, vmax=mxmv) #view montage to check registration
        filename_gif = pth_tif_read[:-4] + '.gif'
        plot_gif(Y, filename_gif, indsz = slice(0, 2, 1), indst = slice(0, 20, 1))  #view gif before registration, can pass xyzt indices, otherwise will do all indices for each 

 
    if Y.shape[3]>1:
        movie_is_4d = 1
    elif Y.shape[3]==1:
        movie_is_4d = 0

    if movie_is_4d: 
        zindall = np.arange(Y.shape[3])
    else:
        zindall = [0]
    
    Y = Y.astype('uint16')



    ########################## BACKGROUND SUBTRACTION (OPTIONAL) ##########################

    if halfwidth_window_bgsub:

        print("DOING LINE-BY-LINE BACKGROUND SUBTRACTION")
        Y = Y.astype('float32') #needs to be float because subtraction can cause negatives       

        for zind in zindall: #for every z slice 

            dimorder = 'txy' 
            pth_bgplots_save = pth_prefix + '_' + str(zind)
            br = bgremover(Y[:,:,:,zind], pth_bgplots_save, patchhalfwidth=halfwidth_window_bgsub, dimorder=dimorder)
            br.draw_patches()
            br.remove_bg()
            if 1: #makeplots:
                br.make_plots()
            Y[:,:,:,zind] = np.transpose(br.out, (0, 2, 1))
                
        mnmv = np.min(Y).astype('float32')
        Y -= mnmv #make movie nonnegative (not sure this is necessary)
        Y = Y.astype('uint16')
        print("MIN BEFORE MOTION CORRECTION AFTER BACKGROUND SUBTRACTION" + str(mnmv))
                        
   

    ########################## TEMPORAL SMOOTHING (OPTIONAL) ##########################

    if len_window_smooth_t_mcp: #if you smooth before registering (very noisy data), create another file for smoothed movie

        if register_in_2d: #for planar extraction write one presmoothed z at a time
            pth_tif_presmooth = ['']*len(zindall)
            for zind in zindall: #for every z slice 
                print("WRITING PRESMOOTHED SLICE " + str(zind))
                pth_tif_presmooth[zind] = pth_tif_write_tmp[:-4] + str(zind) + '_presmooth_.tif'
                imwrite(pth_tif_presmooth[zind], Y[:,:,:,zind].squeeze(), bigtiff=True, photometric='minisblack') 
        else: # 
            print("WRITING ALL PRESMOOTHED SLICES" )
            pth_tif_presmooth = [pth_tif_write_tmp[:-4] + 'all_presmooth_.tif']
            imwrite(pth_tif_presmooth[0], Y.squeeze(), bigtiff=True, photometric='minisblack') #write as t x y z (z might be singleton for non-volumetric data, so squeeze)
    
        print("TEMPORALLY SMOOTHING MOVIE BEFORE REGISTRATION")

        dimtmp_presmooth = Y.shape
        numsigma_smooth_prereg = 5.0
        sigma_smooth_prereg = (len_window_smooth_t_mcp - 1) / numsigma_smooth_prereg / 2
        Y = smooth_movie(Y.reshape(md['dims'][0], -1), sigma=sigma_smooth_prereg, mode='reflect', truncate=numsigma_smooth_prereg, axes=0)
        Y = Y.reshape(dimtmp_presmooth)
        # mnmv = np.min(Y).astype('float32')
        # Y -= mnmv #make movie nonnegative (not sure this is necessary)
        # Y = Y.astype('uint16')
        print("MIN AFTER SMOOTHING " + str(np.min(Y)))


    ########################## MAKE OR LOAD REGISTRATION TEMPLATE ##########################


    regtemplate = find_registration_template(Y, md, registration_template_group_id, pth_allrec, pth_prefix, register_in_2d, movie_is_4d, makeplots)
        

    ########################## REGISTRATION (CAIMAN NORMCORRE) ##########################

    min_mov = np.min(Y).astype('float32')

    if register_in_2d: 
        sliceindz = zindall
    else:
        sliceindz = [zindall] #all slices in one list (not planar)

    countz = 0
    for si in sliceindz: #for each slice (or all slices if extract_in_2d = false)

        mc = None

        if register_in_2d and movie_is_4d: #for planar extraction take on z slice at a time
            print("DOING PLANAR registration FOR SLICE " + str(si))
            images_sliced = Y[:,:,:,si]
        else: # for 3d extraction keep all z slices (for now, until implement z ranges)
            print("DOING PLANAR REGISTRATION FOR ONLY SLICE, OR 3D FOR ALL SLICES")
            images_sliced = Y #can't .copy() for some reason (but that's fine as long as you don't modify images_sliced)

        if register_in_2d and movie_is_4d and regtemplate is not None:
            regtemplate_oneloop = regtemplate[:,:,si]
        else:
            regtemplate_oneloop = regtemplate

            
        imwrite(pth_tif_write_tmp, images_sliced.squeeze(), bigtiff=True, photometric='minisblack') #write as t x y z (z might be singleton for non-volumetric data, so squeeze)
    
        # each_min_mov = 0 # don't think we want to make min mov the min for each z slice 
        # if each_min_mov:
        #     min_mov = np.min(images_sliced).astype('float32')
        
        # FOR SOME REASON CALLING configs OUTSIDE si LOOP CAUSES ALL LOOP ITERATIONS EXCEPT THE FIRST TO HAVE PROBLEMS (PRESUMABLY SOME CONFIG PARAM IS CHANGED ON EACH LOOP) FOR NOW PLACE IT INSIDE LOOP TO RESET ALL CONFIGS SO EACH SLICE GETS THE SAME - IT DOESN'T HURT ANYTHING, IT'S JUST SLIGHTLY INEFFICIENT 
        opts_dict, _, _ = configs(register_in_2d = register_in_2d, fnames = pth_tif_write_tmp, min_mov = min_mov, md = md) #configs for motion correction (will also define for extraction, but extraction params are in redefined later call to configs)
        opts = cnmf.params.CNMFParams(params_dict=opts_dict)

        #sys.setprofile(tracefunc)
        mc = cm.motion_correction.MotionCorrect([pth_tif_write_tmp], dview=dview, **opts.get_group('motion'))
        mc.motion_correct(save_movie=True, template = regtemplate_oneloop)
        input_for_save_memmap = mc.mmap_file #create this variable because it can be memmap file or ndarray
        if len_window_smooth_t_mcp: #apply shifts learned from smoothed movie to the raw movie (we don't want smoothed movie ultimately)
            input_for_save_memmap = mc.apply_shifts_movie(pth_tif_presmooth[countz], save_memmap=False, order='F') #for some reason cannot save_memmap
            input_for_save_memmap = [input_for_save_memmap] #so must pass nd array to save_memmap below
            os.remove(pth_tif_presmooth[countz])

        os.remove(pth_tif_write_tmp)

        border_to_0 = 0 if mc.border_nan == 'copy' else mc.border_to_0 
        basename_memap = pth_tif_write.split('/')[-1][:-4]
        pth_mmap_reg = cm.save_memmap(input_for_save_memmap, base_name=basename_memap, order='C', border_to_0=border_to_0, dview=dview) # save in order C (motion_correct above has to save in order F)
        Ynew, dims_spatial_rg, dim_time_rg = cm.load_memmap(pth_mmap_reg) 
        Ynew = np.reshape(Ynew.T, [dim_time_rg] + list(dims_spatial_rg), order='F') 

        os.remove(mc.mmap_file[0]) #remove the mmap file in F order 
        os.remove(pth_mmap_reg) #remove the mmap file in C order 
        
        if register_in_2d:# and movie_is_4d:
            pth_write_single = pth_tif_write[:-4] + str(si) + '_z_.tif'
            imwrite(pth_write_single, np.transpose(Ynew, (0, 2, 1)).reshape(dim_time_rg, dims_spatial_rg[1], dims_spatial_rg[0]), bigtiff=True, photometric='minisblack') #write the registered movie as tif (uint16) for use in matlab, and caiman extraction below
        else:
            for si2 in np.arange(Ynew.shape[3]): #write 3d registered, each slice, bc reading them back makes caiman output Ynew mutable, without doubling ram by simply copying Ynew (takes more storage but less ram, on O2 this is preferable), also writing one big float32 4d array takes forever on local, each slice does better 
                pth_write_single = pth_tif_write[:-4] + str(si2) + '_z_.tif'
                imwrite(pth_write_single, np.transpose(Ynew[:,:,:,si2], (0, 2, 1)).reshape(dim_time_rg, dims_spatial_rg[1], dims_spatial_rg[0]), bigtiff=True, photometric='minisblack') #write the registered movie as tif (uint16) for use in matlab, and caiman extraction below

        if (register_in_2d and si==sliceindz[-1]) or not register_in_2d: #on final slice, if register_in_2d, or if 3d register
            Ynew = None
            Ynew = stitch_registered_z_slices(pth_tif_write, md['dims']) #output is all slices, txyz

        countz = countz + 1

    Y = None

    if makeplots:
        mxmv = np.max(Ynew)
        #im_montage(Ynew[10,:,:,:], vmin=mnmv, vmax=mxmv) #view montage to check registration
        filename_gif = pth_tif_write[:-4] + '.gif'
        plot_gif(Ynew, filename_gif, indsz = slice(3, 4, 1), indst = slice(0, 20, 1))  #view gif to check registration, can pass xyzt indices, otherwise will do all indices for each 



    ########################## WRITE REGISTERED STACK ##########################

    mnmv = np.min(Ynew).astype('float32')
    Ynew -= mnmv #make nonnegative before converting to uint16
    if np.max(Ynew) > 65535:
        raise Exception("clipping will occur when converting to uint16")
    print("MIN AFTER REGISTRATION " + str(mnmv))
    Ynew = Ynew.astype('uint16')
    Ynew_shape = Ynew.shape
    print(Ynew_shape)
    if len(Ynew.shape)==3:# or Y.shape[3]==1: #transpose into tzyx, collapse t and z (if z exists) 
        Ynew = np.transpose(Ynew, (0, 2, 1)).reshape(Ynew_shape[0], Ynew_shape[2], Ynew_shape[1])
    else:
        Ynew = np.transpose(Ynew, (0, 3, 2, 1)).reshape(Ynew_shape[0] * Ynew_shape[3], Ynew_shape[2], Ynew_shape[1])
    imwrite(pth_tif_write, Ynew, bigtiff=True, photometric='minisblack') #write the registered movie as tif (uint16) for use in matlab, and caiman extraction below



    ########################## WRITE SEPARATE Z SLICES TO PREPARE FOR OPTIONAL DENOISING ##########################

    if carls_old_project: 
        separate_z_slices_for_denoising_carls_old_project(pth_tif_write, fn_prefix, pth_denoising, md, denoise_volume) 
    else:
        separate_z_slices_for_denoising(pth_tif_write, fn_prefix, pth_denoising, md, denoise_volume) 


