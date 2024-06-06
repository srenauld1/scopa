
import numpy as np
import os
from tifffile.tifffile import imwrite, imread

import caiman as cm
import caiman.source_extraction.cnmf as cnmf
from configs import configs
from helpers import stitch_registered_z_slices, separate_z_slices_for_denoising, separate_z_slices_for_denoising_carls_old_project, tracefunc 
from subtract_background import bgremover
from scipy.ndimage import gaussian_filter as smooth_movie
from vis import im_montage, plot_gif


def make_registration_template(pth_tif_read, pth_prefix, md, register_in_2d, halfwidth_window_bgsub, len_window_smooth_t_mcp, fn_prefix, pth_denoising, denoise_volume, carls_old_project, cluster_backend, use_cluster, makeplots):
   

    if use_cluster:
        if 'dview' in locals(): cm.stop_server(dview=dview)
        cc, dview, n_processes = cm.cluster.setup_cluster(backend=cluster_backend, n_processes=None, single_thread=False)
    else:
        n_processes = 1 #set this in case you don't (or can't) setup cluster 
        dview = None #set this in case you don't (or can't) setup cluster
        
    pth_tif_write = pth_prefix + '_rgtemplate_.tif'

    pth_tif_write_tmp = pth_tif_write[:-4] + 'tmp_.tif'

    Y = imread(pth_tif_read).astype('float32') ##having trouble on O2 with caiman function cm.load so just using imread from tifffile.tifffile
    
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

        imwrite(pth_tif_write_tmp, images_sliced.squeeze(), bigtiff=True, photometric='minisblack') #write as t x y z (z might be singleton for non-volumetric data, so squeeze)
    
        # each_min_mov = 0 # don't think we want to make min mov the min for each z slice 
        # if each_min_mov:
        #     min_mov = np.min(images_sliced).astype('float32')
        
        # FOR SOME REASON CALLING configs OUTSIDE si LOOP CAUSES ALL LOOP ITERATIONS EXCEPT THE FIRST TO HAVE PROBLEMS (PRESUMABLY SOME CONFIG PARAM IS CHANGED ON EACH LOOP) FOR NOW PLACE IT INSIDE LOOP TO RESET ALL CONFIGS SO EACH SLICE GETS THE SAME - IT DOESN'T HURT ANYTHING, IT'S JUST SLIGHTLY INEFFICIENT 
        opts_dict, indices_ex, fnadd = configs(register_in_2d = register_in_2d, index_extraction_param_set = 'default', fnames = pth_tif_write_tmp, min_mov = min_mov, md = md) #configs for motion correction (will also define for extraction, but extraction params are in redefined later call to configs)
        opts = cnmf.params.CNMFParams(params_dict=opts_dict)

        #sys.setprofile(tracefunc)
        mc = cm.motion_correction.MotionCorrect([pth_tif_write_tmp], dview=dview, **opts.get_group('motion'))
        mc.motion_correct(save_movie=True)
        input_for_save_memmap = mc.mmap_file #create this variable because it can be memmap file or ndarray

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

#     dims, T = cm.base.movies.get_file_size(fname, var_name_hdf5=var_name_hdf5)
#     Ts = np.arange(T)[subidx].shape[0]
    
#     use_different_number_frames_in_2d_and_3d_templates = 0 #WILSONLAB, CFRW, 240218, 0 TO MAKE 2D AND 3D HAVE SAME TEMPLATE NUM FRAMES (SET TO 1 FOR ORIGINAL)
#     if use_different_number_frames_in_2d_and_3d_templates:
#         step = Ts // 10 if is3D else Ts // 50 #this was the original line
#     else:
#         goal_frames_in_template = 50
#         step = Ts // goal_frames_in_template 
    
#     corrected_slicer = slice(subidx.start, subidx.stop, step + 1)
#     m = cm.load(fname, var_name_hdf5=var_name_hdf5, subindices=corrected_slicer)

#     if len(m.shape) < 3:
#         m = cm.load(fname, var_name_hdf5=var_name_hdf5)
#         m = m[corrected_slicer]
#         logging.warning("Your original file was saved as a single page " +
#                         "file. Consider saving it in multiple smaller files" +
#                         "with size smaller than 4GB (if it is a .tif file)")

#     if is3D:
#         m = m[:, indices[0], indices[1], indices[2]]
#     else:
#         m = m[:, indices[0], indices[1]]

#     if template is None:
#         if gSig_filt is not None:
#             m = cm.movie(
#                 np.array([high_pass_filter_space(m_, gSig_filt) for m_ in m]))
#         if is3D:     
#             # TODO - motion_correct_3d needs to be implemented in movies.py
#             template = caiman.motion_correction.bin_median_3d(m) # motion_correct_3d has not been implemented yet - instead initialize to just median image
# #            template = caiman.motion_correction.bin_median_3d(
# #                    m.motion_correct_3d(max_shifts[2], max_shifts[1], max_shifts[0], template=None)[0])
#         else:
#             if not m.flags['WRITEABLE']:
#                 m = m.copy()
#             register_template = 0 #WILSONLAB, CFRW, 240218, SWITCH OFF TEMPLATE REGISTER, IT CAN MAKE A BAD TEMPLATE FOR A NOISY MOVIE 
#             if register_template:
#                 template = caiman.motion_correction.bin_median(
#                         m.motion_correct(max_shifts[1], max_shifts[0], template=None)[0])
#             else:
#                 template = caiman.motion_correction.bin_median(m)
