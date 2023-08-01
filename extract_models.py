
import sys
import numpy as np
import scipy.io as sio
import scipy

import glob
import os
from tifffile.tifffile import imwrite
import matplotlib.pyplot as plt


import caiman as cm
import caiman.source_extraction.cnmf as cnmf
from caiman_plots import compute_correlations
from tracefunctioncfrw import tracefunc
from caiman_configs import configs

from skimage.util import montage

def extract_2d(index, fname_tmptif_reg, fname_tif_reg, tmpdate, min_mov, dims_spacetime_new, dims_spacetime_original_noflyback, anatomical_stack, do_motion_correction, do_extraction, do_planar_extraction, do_fov_crop, indices_crop, do_refit, do_plots):

    
    ##########################   MOTION CORRECTION   ##########################

    
    opts_dict, indices_ex, fnadd = configs(index = None) #don't pass do_planar_extraction here because these configs are for mc
    n_processes = 1
    dview = None
    opts = cnmf.params.CNMFParams(params_dict=opts_dict)
    opts.change_params({'fnames': fname_tmptif_reg, 'min_mov': min_mov}) #i don't understand why i have to pass fname_tmptif_reg to motioncorrect and set in params object but i do 
    #cc, dview, n_processes = cm.cluster.setup_cluster(backend='ipyparallel', n_processes=None, single_thread=False)

    if do_motion_correction:
                
        mc = cm.motion_correction.MotionCorrect(fname_tmptif_reg, dview=dview, **opts.get_group('motion'))
        #sys.setprofile(tracefunc)
        mc.motion_correct(save_movie=False)
        border_to_0 = 0 if mc.border_nan == 'copy' else mc.border_to_0 
        basename_memap = fname_tmptif_reg[0].split('/')[-1][:-5]
        #fname_mmap_tot = cm.paths.memmap_frames_filename(basename_memap, dims_spacetime_new[1:], dims_spacetime_new[0], 'C')
        fname_mmap_reg = cm.save_memmap(fname_tmptif_reg, base_name=basename_memap, order='C', border_to_0=border_to_0, dview=dview) # exclude borders
    
    else:
       
        #fname_mmap_reg = '/Users/wienecke/Documents/ambrose/leprechaunMat/20230627-2_D05_syt7f_018_syt7f/20230627_2_3047_15_140_256_TMPcaimanregTMPtrial_002_00001_d1_256_d2_140_d3_15_order_C_frames_3047.mmap'
        fname_mmap_reg = '/Users/wienecke/Documents/ambrose/leprechaunMat/20230627-2_D05_syt7f_018_syt7f/20230627_2_PB_1_3047_44_176_6_40_2_9_TMPcaimanregTMPtrial_002_00001_d1_133_d2_35_d3_8_order_C_frames_3047.mmap'

    Yr, dims_spatial, T = cm.load_memmap(fname_mmap_reg) #np.allclose(images, images2, rtol=1e-05, atol=1e-04, equal_nan=False)
    images = np.reshape(Yr.T, [T] + list(dims_spatial), order='F') 
    print("MIN AFTER MOTION CORRECTION")
    print(np.min(images))
    Yr = None

    os.remove(fname_tmptif_reg[0])
    opts.change_params({'fnames': fname_mmap_reg}) #just to prevent error, even though this fname is not used for fit extract

    if not os.path.isfile(fname_tif_reg[0]): #save registered file for matlab 
        images_write = np.transpose(images.astype('uint16'), (0, 3, 2, 1)) #put back in original t z y x scanimage order 
        images_write = images_write.reshape(T * dims_spatial[2], dims_spatial[1], dims_spatial[0])
        
        # if do_fov_crop: #embed back in full FOV
        #     FOV = np.zeros(dims_spacetime_original_noflyback)
        #     FOV[tuple(indices_crop)] = images_write
        
        imwrite(fname_tif_reg[0], images_write) 
        images_write = None

    #Cn_o = compute_correlations(fname_mmap_reg[0], dims_spatial)
    
    
    ##########################   EXTRACTION   ##########################


    # if do_fov_crop:
    #     sly = slice(6, 51, 1)
    #     slx = slice(40, 181, 1) 
    #     slz = slice(1, 9, 1) 
    # else:
    #     sly = slice(0, dims_original[1], 1)
    #     slx = slice(0, dims_original[0], 1) 
    #     slz = slice(0, dims_original[2], 1)
    # indices_crop = [slx, sly, slz]


    # if do_planar_extraction==False: # and images_sliced.shape[-1]==dims_original[2]
    #     #dims_spatial = (dims_original[0], dims_original[1], dims_original[2]-1) #subtract one for the hack below 
    #     dims_spatial = dims_original

    if do_extraction:

        if index is None:
            index_new = [None] #make it iterable with brackets
        elif index<0: #negative index initiates loop here (instead of looping in bash script, which would redo all above code on each loop)
            #manual_start_ind = 54
            index_new = np.flip(abs(np.arange(index, 1)))
            #index_new = np.flip(abs(np.arange(index, -manual_start_ind+1)))
        else: #positive index will redo everything above for each index
            index_new = [index]
        
        print("INDEX NEW " + str(index_new))
        
        for ii in index_new:
            
            #if ii is not None:
            opts_dict, indices_ex, fnadd = configs(index = ii, do_planar_extraction=do_planar_extraction, dims_spatial = dims_spatial)
            opts.change_params(opts_dict) #i don't understand why i have to pass fname_tmptif_reg to motioncorrect and set in params object but i do 
            
            fname_mat_rois = [fname_tif_reg[0][:(len(fname_tif_reg)-5)] + tmpdate + '_caiman' + fnadd + 'rois_.mat']

            if do_planar_extraction: #adjust images and some params for planar 
                sliceindz = np.arange(images.shape[-1])
                if anatomical_stack==1: #srv==0 and len(sliceindz)>20: #force arbitrary z reduction while working with the anatomical stack 
                    sliceindz = np.arange(25, 27)
                #indices_ex = indices_ex[:-1] #previously had to do this here and not in configs??
                dims_mask_space = (dims_spatial[1], dims_spatial[0])
            else:
                sliceindz = [np.arange(images.shape[-1])] #all slices (not planar)
                dims_mask_space = (dims_spatial[0], dims_spatial[1], dims_spatial[2])

            countz = 0
            for si in sliceindz: #for each slice (or all slices if do_planar_extraction = false)

                cnm = None
                cnm2 = None

                if do_planar_extraction:
                    print("PLANAR EXTRACTION FOR SLICE " + str(si))
                    images_sliced = images[:,:,:,si]

                else:
                    print("3D EXTRACTION FOR ALL SLICES")
                    images_sliced = images #keep images for loop over ii

                #dims_extraction = images_sliced.shape[1:]
                #opts_dict_dims = {'dims_spatial': dims_extraction} 
                #opts.change_params(opts_dict_dims)

                #if 'dview' in locals(): cm.stop_server(dview=dview)
                #cc, dview, n_processes = cm.cluster.setup_cluster(backend='ipyparallel', n_processes=None, single_thread=False)

                cnm = cnmf.CNMF(n_processes, params=opts, dview=dview)
                cnm = cnm.fit(images_sliced, indices = indices_ex)

                if do_planar_extraction:

                    if do_plots==1:
                        Cn = cm.local_correlations(images_sliced.transpose(1,2,0))
                        print(Cn.shape)
                        Cn[np.isnan(Cn)] = 0
                        print('you may need to change the data rate to generate nb_view_components: use jupyter notebook --NotebookApp.iopub_data_rate_limit=1.0e10 before opening jupyter notebook')                
                        cnm.estimates.plot_contours(img=Cn)
                        cnm.estimates.view_components(img=Cn)
                        #cnm.estimates.view_components(img=None, idx=cnm.estimates.idx_components) #img=None for mean projection
                
                else:
                    
                    if do_plots==1:
                        cnm.estimates.nb_view_components_3d(image_type='mean', dims_spatial=dims_spatial, axis=2)
                        #cnm.estimates.nb_view_components_3d(image_type='corr', dims_spatial=dims_spatial, Yr=Yr, denoised_color='red', max_projection=True);

            
                cnm.estimates.evaluate_components(images_sliced, cnm.params, dview=dview)
                print(('NUMGOOD ' + str(len(cnm.estimates.idx_components)) + ' NUMBAD ' + str(len(cnm.estimates.idx_components_bad))))
                #cnm.estimates.select_components(use_object=True, save_discarded_components=True)
                
                if do_refit:

                    #if 'dview' in locals(): cm.stop_server(dview=dview)
                    #cc, dview, n_processes = cm.cluster.setup_cluster(backend='ipyparallel', n_processes=None, single_thread=False)
                    
                    cnm2 = cnm.refit(images_sliced)
                    cnm2.estimates.evaluate_components(images_sliced, cnm2.params, dview=dview)
                    print(('REFIT: NUMGOOD ' + str(len(cnm2.estimates.idx_components)) + ' NUMBAD ' + str(len(cnm2.estimates.idx_components_bad))))
                    cnm2.estimates.detrend_df_f(detrend_only=False, flag_auto=True, use_residuals=False) #use_residuals to use nondeconvolved traceds for dff computation (if p=0 use_residuals should not matter right?)
                    dff_residfalse = cnm2.estimates.F_dff 
                    cnm2.estimates.detrend_df_f(detrend_only=False, flag_auto=True, use_residuals=True) #use_residuals to use nondeconvolved traceds for dff computation (if p=0 use_residuals should not matter right?)
                    dff_residtrue = cnm2.estimates.F_dff 
                    #cnm2.estimates.select_components(use_object=True, save_discarded_components=True)

                else:
                    
                    cnm2 = cnm
                
                if do_plots==1:
                    if do_planar_extraction:
                        cnm2.estimates.view_components(img=Cn) #img=Cn for mean proj
                    else:
                        cnm2.estimates.nb_view_components_3d(image_type='mean', dims_spatial=dims_spatial, axis=2)
                        #cnm2.estimates.nb_view_components_3d(image_type='corr', dims_spatial=dims_spatial, Yr=Yr, denoised_color='red', max_projection=True);
                    
                    if do_planar_extraction:
                        #this fails for my 3d hack 
                        cnm2.estimates.play_movie(images_sliced, q_max=99.9, gain_res=2, magnification=2, bpx=True, include_bck=False, save_movie=True)
                        A2 = cnm2.estimates.A.toarray().reshape(opts.data['dims'] + (-1,), order='F').transpose([2, 0, 1])
                        Nc = A2.shape[0]
                        grid_shape = (np.ceil(np.sqrt(Nc/2)).astype(int), np.ceil(np.sqrt(Nc*2)).astype(int))
                        plt.figure(figsize=np.array(grid_shape[::-1])*1.5)
                        plt.imshow(montage(A2, rescale_intensity=True, grid_shape=grid_shape))
                        plt.axis('off')
                
                #denoised_movie = cm.movie(cnm2.estimates.A.dot(cnm2.estimates.C) + \
                #            cnm2.estimates.b.dot(cnm2.estimates.f)).reshape(dims_spatial + (-1,), order='F').transpose([3, 0, 1, 2]) #%% reconstruct denoised movie 
                
                # if do_fov_crop: #embed back in full FOV
                #     FOV = np.zeros(dims_spacetime_original_noflyback, order='C')
                #     FOV[tuple(indices_crop)] = 1
                #     FOV = FOV.flatten(order='F')
                #     ind_nz = np.where(FOV>0)[0].tolist()
                #     cnm2.estimates.A = cnm2.estimates.A.tocsc()
                #     A_data = cnm2.estimates.A.data
                #     A_ind = np.array(ind_nz)[cnm2.estimates.A.indices]
                #     A_ptr = cnm2.estimates.A.indptr
                #     A_FOV = scipy.sparse.csc_matrix((A_data, A_ind, A_ptr), shape=(FOV.shape[0], cnm2.estimates.A.shape[-1]))
                #     b_FOV = np.zeros((FOV.shape[0], cnm2.estimates.b.shape[-1]))
                #     b_FOV[ind_nz] = cnm2.estimates.b
                #     cnm2.estimates.A = A_FOV
                #     cnm2.estimates.b = b_FOV

                if countz==0: #do this zero padding so multiple extractions can be put into one array/saved, remove trailing zeros in matlab 

                    padnum = 10
                    padnum_b = 3
                    #numroi_stack_pad = cnm2.estimates.center.shape[0] + padnum #extra since it can vary a little across fits (even above input k)
                    numroi_stack_pad = cnm2.estimates.A.shape[-1] + padnum #extra since it can vary a little across fits (even above input k)
                    dims_mask_stack = ( dims_mask_space + (numroi_stack_pad, ) )
                    dims_mask_b_stack = ( dims_mask_space + (cnm2.estimates.b.shape[-1] + padnum_b, ) )
                    #dims_cen_stack = ( (numroi_stack_pad,) + (cnm2.estimates.center.shape[-1], ) ) #cen.shape[0] seems to be k regardless of actual num rois?
                    #dims_cen_stack = ( cnm2.estimates.center.shape ) #cen.shape[0] seems to be k regardless of actual num rois?
                    dims_timeseries_stack = ( numroi_stack_pad, cnm2.estimates.C.shape[1] )

                    stack_masks = np.zeros(dims_mask_stack + (len(sliceindz), ) )
                    stack_masks_b = np.zeros(dims_mask_b_stack + (len(sliceindz), ) )
                    #stack_cen = np.zeros(dims_cen_stack + (len(sliceindz), ) )
                    stack_c = np.zeros(dims_timeseries_stack + (len(sliceindz), ) )
                    stack_yra = np.zeros(dims_timeseries_stack + (len(sliceindz), ) )
                    stack_s = np.zeros(dims_timeseries_stack + (len(sliceindz), ) )
                    stack_df = np.zeros(dims_timeseries_stack + (len(sliceindz), ) )
                    stack_dfr = np.zeros(dims_timeseries_stack + (len(sliceindz), ) )
                    stack_snr = np.zeros((dims_timeseries_stack[0], ) + (len(sliceindz), ) )
                    stack_rval = np.zeros((dims_timeseries_stack[0], ) + (len(sliceindz), ) )
                    stack_idx = np.zeros((dims_timeseries_stack[0], ) + (len(sliceindz), ) )
                    stack_idx_bad = np.zeros((dims_timeseries_stack[0], ) + (len(sliceindz), ) )

                numroi_slice = cnm2.estimates.A.shape[-1]
                numroi_b_slice = cnm2.estimates.b.shape[-1]
                dims_mask_slice = (dims_mask_space + (numroi_slice, ) )
                dims_mask_b_slice = (dims_mask_space + (numroi_b_slice, ) )
                
                stack_masks[..., :numroi_slice, countz] = np.reshape(cnm2.estimates.A.toarray(), dims_mask_slice, order='F') 
                stack_masks_b[..., :numroi_b_slice, countz] = np.reshape(cnm2.estimates.b, dims_mask_b_slice, order='F') 
                #stack_cen[:cnm2.estimates.center.shape[0],:,countz] = cnm2.estimates.center 
                stack_c[:numroi_slice,:,countz] = cnm2.estimates.C 
                stack_yra[:numroi_slice,:,countz] = cnm2.estimates.YrA 
                stack_s[:numroi_slice,:,countz] = cnm2.estimates.S 
                stack_df[:numroi_slice,:,countz] = dff_residfalse
                stack_dfr[:numroi_slice,:,countz] = dff_residtrue
                stack_snr[:numroi_slice,countz] = cnm2.estimates.SNR_comp 
                stack_rval[:numroi_slice,countz] = cnm2.estimates.r_values 
                stack_idx[:cnm2.estimates.idx_components.shape[0],countz] = cnm2.estimates.idx_components
                if cnm2.estimates.idx_components_bad.shape==(1,):
                    stack_idx_bad[:cnm2.estimates.idx_components_bad.shape[0],countz] = cnm2.estimates.idx_components_bad 

                countz = countz + 1

            log_files = glob.glob('*_LOG_*')
            for log_file in log_files:
                os.remove(log_file)

            mdict = {}
            mdict['roimasks'] = stack_masks
            mdict['roimasks_b'] = stack_masks_b
            #mdict['cen'] = stack_cen
            mdict['C'] = stack_c
            mdict['YrA'] = stack_yra
            mdict['S'] = stack_s
            mdict['dff'] = stack_df
            mdict['dffr'] = stack_dfr
            mdict['snr'] = stack_snr
            mdict['rval'] = stack_rval
            mdict['idx'] = stack_idx
            mdict['idxbad'] = stack_idx_bad
            
            sio.savemat(fname_mat_rois[0],mdict)

            if dview is not None: cm.stop_server(dview=dview)

    donestr = "DONE"
    return donestr