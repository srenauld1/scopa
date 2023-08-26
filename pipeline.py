
import sys
import numpy as np
import scipy.io as sio
import scipy

import glob
import os
from tifffile.tifffile import imwrite, imread

import matplotlib.pyplot as plt

#from ScanImageTiffReader import ScanImageTiffReader
import json

import caiman as cm
import caiman.source_extraction.cnmf as cnmf
from caiman_configs import configs
from caiman_vis_custom import caiman_plots_all, compute_correlations
from helpers import crop_fov, tracefunc

def pipeline_full(index, pth_datafile, pth_prefix_fnsave, pth_tif_reg_tmp, pth_tif_reg, pth_tif_dn, fn_reduced, old_mat_files, 
                      datasets_path_processing, datasets_path_complete, dims_spacetime_original, dims_spacetime_original_noflyback, 
                      flyback, anatomical_stack, do_motion_correction, do_denoise, do_cropping_session, do_extraction, do_planar_extraction, region_extraction, do_plots, cluster_backend, server):

    print("in full")
    n_processes = 1
    dview = None

    ##########################   MOTION CORRECTION   ##########################

    if do_motion_correction:

        #Y = ScanImageTiffReader(pth_datafile).data() #dim order (t z) y x, int16 . . . cm.load(pth_datafile) is same dim order but float32 (and cannot read metadata) 
        #Ymeta = ScanImageTiffReader(pth_datafile).metadata() #dim order (t z) y x, int16 . . . cm.load(pth_datafile) is same dim order but float32 (and cannot read metadata) 
        # with ScanImageTiffReader(pth_datafile) as reader:
        #    Ymeta=json.loads(reader.metadata())        
        
        Y = cm.load(pth_datafile)
        
        # if Y.shape[0]/19 % 1 == 0:
        #     dims_spacetime_original[0] = Y.shape[0]/19
        #     dims_spacetime_original[1] = 19
        #     dims_spacetime_original_noflyback[0] = Y.shape[0]/19
        #     dims_spacetime_original_noflyback[1] = 19 - flyback
        # elif Y.shape[0]/14 % 1 == 0:
        #     dims_spacetime_original[0] = Y.shape[0]/14
        #     dims_spacetime_original[1] = 14
        #     dims_spacetime_original_noflyback[0] = Y.shape[0]/14
        #     dims_spacetime_original_noflyback[1] = 14 - flyback
            
        
        Y = Y.reshape(dims_spacetime_original[0], dims_spacetime_original[1], dims_spacetime_original[2], dims_spacetime_original[3])
            
        Y = Y[:,:-flyback,:,:] #crop flyback frames
        #Y[540:600,4,:,:].play(magnification=2) #play in order t z y x
        Y = np.transpose(Y, (0, 3, 2, 1)) #put in order t x y z 
        
        min_mov = int(np.min(Y))
        Y = Y - min_mov #make movie nonnegative (not sure this is necessary)
        print("MIN BEFORE MOTION CORRECTION " + str(min_mov))
        
        imwrite(pth_tif_reg_tmp[0], Y) #write as t x y z

        if server:
            try:
                if 'dview' in locals(): cm.stop_server(dview=dview)
                cc, dview, n_processes = cm.cluster.setup_cluster(backend=cluster_backend, n_processes=None, single_thread=False)
            except:
                if 'dview' in locals(): cm.stop_server(dview=dview)
                cc, dview, n_processes = cm.cluster.setup_cluster(backend=cluster_backend, n_processes=None, single_thread=False)
                    
        opts_dict, indices_ex, fnadd = configs(index = None, fnames = pth_tif_reg_tmp, min_mov = min_mov) #don't pass do_planar_extraction here because these configs are for mc
        opts = cnmf.params.CNMFParams(params_dict=opts_dict)
        #opts.change_params({'fnames': pth_tif_reg_tmp, 'min_mov': min_mov}) #i don't understand why i have to pass pth_tif_reg_tmp to motioncorrect and set in params object but i do 

        mc = cm.motion_correction.MotionCorrect(pth_tif_reg_tmp, dview=dview, **opts.get_group('motion'))
        #sys.setprofile(tracefunc)
        mc.motion_correct(save_movie=True)
        os.remove(pth_tif_reg_tmp[0])

        border_to_0 = 0 if mc.border_nan == 'copy' else mc.border_to_0 
        basename_memap = pth_tif_reg[0].split('/')[-1][:-4]
        pth_mmap_reg = cm.save_memmap(mc.mmap_file, base_name=basename_memap, order='C', border_to_0=border_to_0, dview=dview) # save in order C (motion_correct above has to save in order F)
        Y, dims_spatial, T = cm.load_memmap(pth_mmap_reg) #np.allclose(images, images2, rtol=1e-05, atol=1e-04, equal_nan=False)
        Y = np.reshape(Y.T, [T] + list(dims_spatial), order='F') 
        min_mov_after_reg = int(np.min(Y))
        Y = Y - min_mov_after_reg #make movie nonnegative (not sure this is necessary)
        print("MIN AFTER MOTION CORRECTION " + str(min_mov_after_reg))

        os.remove(mc.mmap_file[0]) #remove the mmap file in F order 
        os.remove(pth_mmap_reg) #remove the mmap file in C order 
        #write registered movied as uint16, below cm.load will convert to float32 automatically 
        # Y_write = np.transpose(Y.astype('uint16'), (0, 3, 2, 1)) #put back in original t z y x scanimage order
        # Y_write = np.transpose(Y_write.astype('uint16'), (0, 3, 2, 1)).reshape(T * dims_spatial[2], dims_spatial[1], dims_spatial[0])
        imwrite(pth_tif_reg[0], np.transpose(Y.astype('uint16'), (0, 3, 2, 1)).reshape(T * dims_spatial[2], dims_spatial[1], dims_spatial[0])) #write the registered movie as tif for use in matlab, and caiman extraction below

        
    
    if do_denoise:
        os.system("source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh; \
          conda run -n deepcadrt2 python3 ~/scopa/denoise_script.py" \
                  + " " + pth_tif_reg[0] + " " + pth_tif_dn[0] + " " + fn_reduced \
                    + " " + str(old_mat_files) + " " + str(dims_spacetime_original_noflyback[0]) \
                        + " " + str(dims_spacetime_original_noflyback[1]) + " " + str(dims_spacetime_original_noflyback[2]) \
                            + " " + str(dims_spacetime_original_noflyback[3]) + " " + datasets_path_processing \
                                + " " + datasets_path_complete)

    #denoise_single_recording(pth_tif_reg, pth_tif_dn, fn_reduced, old_mat_files, dims_spacetime_original_noflyback, datasets_path_processing, datasets_path_complete)
    print("past denoise")

    ##########################   EXTRACTION   ##########################

    if do_extraction or do_cropping_session:
        
        print("in extract")

        pth_choose_asshole = pth_tif_reg
        
        Y = cm.load(pth_choose_asshole)  
        Y = Y.reshape(dims_spacetime_original_noflyback)
        Y = np.transpose(Y, (0, 3, 2, 1)) #put in order t x y z 

        if do_cropping_session:
            region_extraction = ['pb', 'gar', 'gal', 'no']

        for rx in region_extraction:
            print(pth_tif_reg)
            print(rx)

            if region_extraction == '':
                limits_str = ''
            else:
                if do_cropping_session:
                    _, limits_str = crop_fov(Y, rx, pth_choose_asshole, dims_spacetime_original_noflyback)
                else:
                    Y, limits_str = crop_fov(Y, rx, pth_choose_asshole, dims_spacetime_original_noflyback)


        if not do_cropping_session:
            
            pth_tif_ex = [pth_choose_asshole[0][:-4] + limits_str + '_caimanex_.tif']
            imwrite(pth_tif_ex[0], Y) #must write it to memmap it, and must memmap it to use patches in extraction
            basename_memap = pth_tif_ex[0].split('/')[-1][:-4]
            border_to_0 = 0 #if mc.border_nan == 'copy' else mc.border_to_0 
            fn_mmap_ex = cm.save_memmap(pth_tif_ex, base_name=basename_memap, order='C', border_to_0=border_to_0, dview=dview) # exclude borders
            os.remove(pth_tif_ex[0])
            Y, dims_spatial, T = cm.load_memmap(fn_mmap_ex) #np.allclose(images, images2, rtol=1e-05, atol=1e-04, equal_nan=False)
            Y = np.reshape(Y.T, [T] + list(dims_spatial), order='F') 

            if index is None:
                index_new = [None] #make it iterable with brackets
            elif index<0: #negative index initiates loop here (instead of looping in bash script, which would redo all above code on each loop)
                manual_start_ind = 0
                index_new = np.arange(manual_start_ind, -index)
                #index_new = np.flip(abs(np.arange(index, -manual_start_ind+1))) #why did i do it this way?
                #index_new = np.flip(abs(np.arange(index, 1))) #why did i do it this way?
            else: #positive index will redo everything above for each index
                index_new = [index]
            
            print("INDEX NEW " + str(index_new))
            
            for ii in index_new:

                if 1: #since some param combos will error

                    opts_dict, indices_ex, fnadd = configs(index = ii, fnames = fn_mmap_ex, do_planar_extraction=do_planar_extraction, dims_spatial = dims_spatial)
                    opts = cnmf.params.CNMFParams(params_dict=opts_dict)
                    
                    # opts.change_params(opts_dict) #i don't understand why i have to pass pth_tif_reg_tmp to motioncorrect and set in params object but i do 
                    # opts.change_params({'fnames': fn_mmap_ex}) #i don't understand why i have to pass pth_tif_reg_tmp to motioncorrect and set in params object but i do 
                
                    if do_planar_extraction: #adjust images and some params for planar 
                        sliceindz = np.arange(Y.shape[-1])
                        if anatomical_stack==1: #srv==0 and len(sliceindz)>20: #force arbitrary z reduction while working with the anatomical stack 
                            sliceindz = np.arange(25, 27)
                        dims_mask_space = (dims_spatial[1], dims_spatial[0])
                    else:
                        sliceindz = [np.arange(Y.shape[-1])] #all slices (not planar)
                        dims_mask_space = (dims_spatial[0], dims_spatial[1], dims_spatial[2])

                    countz = 0
                    for si in sliceindz: #for each slice (or all slices if do_planar_extraction = false)

                        cnm = None
                        cnm2 = None

                        if do_planar_extraction:
                            print("PLANAR EXTRACTION FOR SLICE " + str(si))
                            images_sliced = Y[:,:,:,si]
                        else:
                            print("3D EXTRACTION FOR ALL SLICES")
                            images_sliced = Y #keep images for loop over ii


                        if server:
                            try:
                                if 'dview' in locals(): cm.stop_server(dview=dview)
                                cc, dview, n_processes = cm.cluster.setup_cluster(backend=cluster_backend, n_processes=None, single_thread=False)
                            except:
                                if 'dview' in locals(): cm.stop_server(dview=dview)
                                cc, dview, n_processes = cm.cluster.setup_cluster(backend=cluster_backend, n_processes=None, single_thread=False)
                        
                        cnm = cnmf.CNMF(n_processes, params=opts, dview=dview)
                        cnm = cnm.fit(images_sliced, indices = indices_ex)

                        cnm.estimates.evaluate_components(images_sliced, cnm.params, dview=dview)
                        print(('NUMGOOD ' + str(len(cnm.estimates.idx_components)) + ' NUMBAD ' + str(len(cnm.estimates.idx_components_bad))))
                        
                        cnm.estimates.select_components(use_object=True, save_discarded_components=False)

                        if server:
                            try:
                                if 'dview' in locals(): cm.stop_server(dview=dview)
                                cc, dview, n_processes = cm.cluster.setup_cluster(backend=cluster_backend, n_processes=None, single_thread=False)
                            except:
                                if 'dview' in locals(): cm.stop_server(dview=dview)
                                cc, dview, n_processes = cm.cluster.setup_cluster(backend=cluster_backend, n_processes=None, single_thread=False)
                        
                        cnm2 = cnm.refit(images_sliced)
                        cnm2.estimates.evaluate_components(images_sliced, cnm2.params, dview=dview)
                        print(('REFIT: NUMGOOD ' + str(len(cnm2.estimates.idx_components)) + ' NUMBAD ' + str(len(cnm2.estimates.idx_components_bad))))
                        
                        cnm2.estimates.detrend_df_f(detrend_only=False, flag_auto=True, use_residuals=False) #use_residuals to use nondeconvolved traceds for dff computation (if p=0 use_residuals should not matter right?)
                        dff_residfalse = cnm2.estimates.F_dff 
                        cnm2.estimates.detrend_df_f(detrend_only=False, flag_auto=True, use_residuals=True) #use_residuals to use nondeconvolved traceds for dff computation (if p=0 use_residuals should not matter right?)
                        dff_residtrue = cnm2.estimates.F_dff 
                        cnm2.estimates.select_components(use_object=True, save_discarded_components=False)

                        if do_plots:
                            caiman_plots_all(cnm2, opts, images_sliced, dims_spatial, do_planar_extraction)

                        if countz==0: #do this zero padding so multiple extractions can be put into one array/saved, remove trailing zeros in matlab 

                            padnum = 10
                            padnum_b = 3
                            numroi_stack_pad = cnm2.estimates.A.shape[-1] + padnum #extra since it can vary a little across fits (even above input k)
                            dims_mask_stack = ( dims_mask_space + (numroi_stack_pad, ) )
                            dims_mask_b_stack = ( dims_mask_space + (cnm2.estimates.b.shape[-1] + padnum_b, ) )
                            dims_timeseries_stack = ( numroi_stack_pad, cnm2.estimates.C.shape[1] )

                            stack_masks = np.zeros(dims_mask_stack + (len(sliceindz), ) )
                            stack_masks_b = np.zeros(dims_mask_b_stack + (len(sliceindz), ) )
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
                        stack_c[:numroi_slice,:,countz] = cnm2.estimates.C 
                        stack_yra[:numroi_slice,:,countz] = cnm2.estimates.YrA 
                        stack_s[:numroi_slice,:,countz] = cnm2.estimates.S 
                        stack_df[:numroi_slice,:,countz] = dff_residfalse
                        stack_dfr[:numroi_slice,:,countz] = dff_residtrue
                        stack_snr[:numroi_slice,countz] = cnm2.estimates.SNR_comp 
                        stack_rval[:numroi_slice,countz] = cnm2.estimates.r_values 
                        #stack_idx[:cnm2.estimates.idx_components.shape[0],countz] = cnm2.estimates.idx_components
                        #if cnm2.estimates.idx_components_bad.shape==(1,):
                        #    stack_idx_bad[:cnm2.estimates.idx_components_bad.shape[0],countz] = cnm2.estimates.idx_components_bad 

                        countz = countz + 1

                    log_files = glob.glob('*_LOG_*')
                    for log_file in log_files:
                        os.remove(log_file)

                    mdict = {}
                    mdict['roimasks'] = stack_masks.astype('float32')
                    mdict['roimasks_b'] = stack_masks_b.astype('float32')
                    mdict['C'] = stack_c.astype('float32')
                    mdict['YrA'] = stack_yra.astype('float32')
                    mdict['S'] = stack_s.astype('float32')
                    mdict['dff'] = stack_df.astype('float32')
                    mdict['dffr'] = stack_dfr.astype('float32')
                    mdict['snr'] = stack_snr.astype('float32')
                    mdict['rval'] = stack_rval.astype('float32')
                    #mdict['idx'] = stack_idx
                    #mdict['idxbad'] = stack_idx_bad
                    
                    if np.any(stack_masks):
                        pth_mat_ex = [pth_tif_ex[0][:-5] + fnadd + 'rois_.mat']
                    else:
                        mdict = {}
                        print("norois")
                        pth_mat_ex = [pth_tif_ex[0][:-5] + fnadd + 'rois_NOROIS_.mat']

                else:
                    
                    mdict = {}
                    pth_mat_ex = [pth_tif_ex[0][:-5] + fnadd + 'rois_FAILURE_.mat']

                
                sio.savemat(pth_mat_ex[0], mdict)

                if dview is not None: cm.stop_server(dview=dview)
