
import numpy as np
import scipy.io as sio
import glob
import os
from tifffile.tifffile import imwrite, imread

import caiman as cm
import caiman.source_extraction.cnmf as cnmf
from configs import configs
from vis import caiman_plots_all
from helpers import stitch_denoised_slices, stitch_denoised_slices_carls_old_project, tracefunc
from crop_fov import crop_fov


def extract(index_extraction_param_set, fn_prefix, pth_prefix, pth_tif_reg, pth_tif_dn, pth_denoising, 
             md, denoise_volume, do_cropping_session, do_planar_extraction, use_denoised, 
             region_extraction, do_plots, cluster_backend, do_cluster):

    n_processes = 1 #set this in case you don't (or can't) setup cluster 
    dview = None #set this in case you don't (or can't) setup cluster

    ##########################   CAIMAN SOURCE EXTRACTION   ##########################

    if use_denoised or do_stitching_session:
        
        epoch_choose = 5 #which denoising epoch to stitch/use (must exist, ie must be one of epochs_choose in denoise.py)
        force_stitch = 0 #stitch regardless of whether the file already exists (e.g. to use a different run or different epoch, warning this will overwrite existing stitched denoised tif)

        if not os.path.isfile(pth_tif_dn) or force_stitch:
            if int(fn_prefix.split('_')[0])>20230101: #if it's not my old project 
                stitch_denoised_slices(pth_denoising, fn_prefix, pth_tif_dn, md['dims'], denoise_volume, epoch_choose) #stitch together denoised slices (tyx) into original size (tzyx)
            else:
                stitch_denoised_slices_carls_old_project(pth_denoising, fn_prefix, pth_tif_dn, md['dims'], denoise_volume, epoch_choose) #stitch together denoised slices (tyx) into original size (tzyx)

        pth_exin = pth_tif_dn
    
    else:
    
        pth_exin = pth_tif_reg

    Y = imread(pth_exin).astype('float32')
    Y = Y.reshape(md['dims'])
    Y = np.transpose(Y, (0, 3, 2, 1)) #put in order t x y z 
    print(Y.shape)

    for rx in region_extraction:
        
        print(pth_exin)
        print(rx)

        Ycrop, limits_str = crop_fov(Y, rx, pth_prefix, md['dims']) #define cuboid or rectangular fov for extraction (much faster if you don't need the full fov), careful your rectangle doesn't go off edge (croplim will have 0 in it, which creates empty array - need to fix this) 

        print(Ycrop.shape)


        if not do_cropping_session:
            
            pth_tif_ex = pth_exin[:-4] + rx + '_' + limits_str + '_cmex_tmp_.tif'
            imwrite(pth_tif_ex, Ycrop.squeeze()) #squeeze in case 3d . . . also must imwrite it to memmap it, and must memmap it to use patches in extraction
            basename_memap = pth_tif_ex.split('/')[-1][:-4]
            border_to_0 = 0 #if mc.border_nan == 'copy' else mc.border_to_0 
            fn_mmap_ex = cm.save_memmap([pth_tif_ex], base_name=basename_memap, order='C', border_to_0=border_to_0, dview=dview) # exclude borders
            os.remove(pth_tif_ex)
            Ycrop, dims_spatial_ex, dim_time_ex = cm.load_memmap(fn_mmap_ex) #if 3d mmap should be 3d, but Ycrop gets singleton 4th dim (z) added below so the code is more readable
            Ycrop = np.reshape(Ycrop.T, [dim_time_ex] + list(dims_spatial_ex), order='F') 
            
            if len(Ycrop.shape)==3: #if it's not volumetric
                Ycrop = Ycrop[...,np.newaxis] #add singleton 4th dim (z) so the code is more readable 
            
            print(Ycrop.shape)

            if index_extraction_param_set == 'default':
                index_extraction_param_set_new = ['default'] #make it iterable with brackets
            elif index_extraction_param_set<0: #if negative, initiate loop over extraction params here, range [0 - index_extraction_param_set]
                manual_start_ind = 0
                index_extraction_param_set_new = np.arange(manual_start_ind, -index_extraction_param_set)
            else: #if positive, just the one extraction param whose index matches index_extraction_param_set
                index_extraction_param_set_new = [index_extraction_param_set]
                            
            print("index_extraction_param_set NEW " + str(index_extraction_param_set_new))
            
            for ii in index_extraction_param_set_new:

                try: #try, since some param sets will error

                    if do_planar_extraction: #adjust images and some params for planar 
                        sliceindz = np.arange(Ycrop.shape[3])
                        dims_roimask_spatial = (dims_spatial_ex[0], dims_spatial_ex[1])
                    else:
                        sliceindz = [np.arange(Ycrop.shape[3])] #all slices in one list (not planar)
                        dims_roimask_spatial = (dims_spatial_ex[0], dims_spatial_ex[1], dims_spatial_ex[2])

                    countz = 0
                    for si in sliceindz: #for each slice (or all slices if do_planar_extraction = false)

                        cnm = None
                        cnm2 = None

                        # FOR SOME REASON CALLING configs OUTSIDE si LOOP CAUSES ALL LOOP ITERATIONS EXCEPT THE FIRST TO HAVE PROBLEMS (PRESUMABLY SOME CONFIG PARAM IS CHANGED ON EACH LOOP) FOR NOW PLACE IT INSIDE LOOP TO RESET ALL CONFIGS SO EACH SLICE GETS THE SAME - IT DOESN'T HURT ANYTHING, IT'S JUST SLIGHTLY INEFFICIENT 
                        opts_dict, indices_ex, fnadd = configs(index_extraction_param_set = ii, fnames = fn_mmap_ex, md = md, do_planar_extraction = do_planar_extraction, dims_spatial_ex = dims_spatial_ex) #param set for extraction
                        opts = cnmf.params.CNMFParams(params_dict=opts_dict)

                        if do_planar_extraction: #for planar extraction take on z slice at a time
                            print("PLANAR EXTRACTION FOR SLICE " + str(si))
                            images_sliced = Ycrop[:,:,:,si]
                        else: # for 3d extraction keep all z slices (for now, until implement z ranges)
                            print("3D EXTRACTION FOR ALL SLICES")
                            images_sliced = Ycrop #can't .copy() for some reason (but that's fine as long as you don't modify images_sliced)

                        if do_cluster:
                            if 'dview' in locals(): cm.stop_server(dview=dview)
                            cc, dview, n_processes = cm.cluster.setup_cluster(backend=cluster_backend, n_processes=None, single_thread=False)

                        cnm = cnmf.CNMF(n_processes, params=opts, dview=dview)
                        cnm = cnm.fit(images_sliced, indices = indices_ex)

                        cnm.estimates.evaluate_components(images_sliced, cnm.params, dview=dview)
                        print(('NUMGOOD ' + str(len(cnm.estimates.idx_components)) + ' NUMBAD ' + str(len(cnm.estimates.idx_components_bad))))
                        
                        cnm.estimates.select_components(use_object=True, save_discarded_components=False)

                        if do_cluster:
                            if 'dview' in locals(): cm.stop_server(dview=dview)
                            cc, dview, n_processes = cm.cluster.setup_cluster(backend=cluster_backend, n_processes=None, single_thread=False)
        
                
                        cnm2 = cnm.refit(images_sliced)

                        cnm2.estimates.evaluate_components(images_sliced, cnm2.params, dview=dview)
                        print(('REFIT: NUMGOOD ' + str(len(cnm2.estimates.idx_components)) + ' NUMBAD ' + str(len(cnm2.estimates.idx_components_bad))))
                        
                        cnm2.estimates.detrend_df_f(detrend_only=False, flag_auto=True, use_residuals=False) #use_residuals=False to not include residuals in traces for dff computation (default)
                        dff_residfalse = cnm2.estimates.F_dff 
                        cnm2.estimates.detrend_df_f(detrend_only=False, flag_auto=True, use_residuals=True) #use_residuals=True to include residuals in traces for dff computation
                        dff_residtrue = cnm2.estimates.F_dff 
                        cnm2.estimates.select_components(use_object=True, save_discarded_components=False)


                        if do_plots and cnm2.estimates.A.shape[-1]:
                            pth_results = pth_tif_ex[:-8] + fnadd + 'OUT_FIT1.mov'
                            caiman_plots_all(cnm, opts, images_sliced, dims_spatial_ex, do_planar_extraction, pth_results)

                        if do_plots and cnm2.estimates.A.shape[-1]:
                            pth_results2 = pth_tif_ex[:-8] + fnadd + 'OUT_FIT2.mov'
                            caiman_plots_all(cnm2, opts, images_sliced, dims_spatial_ex, do_planar_extraction, pth_results2)
                        
                
                        if countz==0: #do this zero padding so multiple extractions can be put into one array/saved, remove trailing zeros in matlab 

                            numroi_stack_pad = cnm2.estimates.A.shape[-1]
                            dims_roimask_stack = ( dims_roimask_spatial + (numroi_stack_pad, ) )
                            dims_roimask_b_stack = ( dims_roimask_spatial + (cnm2.estimates.b.shape[-1], ) )
                            dims_timeseries_stack = ( numroi_stack_pad, cnm2.estimates.C.shape[1] )

                            stack_masks = np.zeros(dims_roimask_stack + (len(sliceindz), ) )
                            stack_masks_b = np.zeros(dims_roimask_b_stack + (len(sliceindz), ) )
                            stack_c = np.zeros(dims_timeseries_stack + (len(sliceindz), ) )
                            #stack_yra = np.zeros(dims_timeseries_stack + (len(sliceindz), ) )
                            stack_s = np.zeros(dims_timeseries_stack + (len(sliceindz), ) )
                            stack_df = np.zeros(dims_timeseries_stack + (len(sliceindz), ) )
                            stack_dfr = np.zeros(dims_timeseries_stack + (len(sliceindz), ) )
                            stack_snr = np.zeros((dims_timeseries_stack[0], ) + (len(sliceindz), ) )
                            stack_rval = np.zeros((dims_timeseries_stack[0], ) + (len(sliceindz), ) )
                            #stack_idx = np.zeros((dims_timeseries_stack[0], ) + (len(sliceindz), ) )
                            #stack_idx_bad = np.zeros((dims_timeseries_stack[0], ) + (len(sliceindz), ) )

                        numroi_slice = cnm2.estimates.A.shape[-1]
                        numroi_b_slice = cnm2.estimates.b.shape[-1]
                        dims_mask_slice = (dims_roimask_spatial + (numroi_slice, ) )
                        dims_mask_b_slice = (dims_roimask_spatial + (numroi_b_slice, ) )
                        
                        stack_masks[..., :numroi_slice, countz] = np.reshape(cnm2.estimates.A.toarray(), dims_mask_slice, order='F') 
                        stack_masks_b[..., :numroi_b_slice, countz] = np.reshape(cnm2.estimates.b, dims_mask_b_slice, order='F') 
                        stack_c[:numroi_slice,:,countz] = cnm2.estimates.C 
                        #stack_yra[:numroi_slice,:,countz] = cnm2.estimates.YrA 
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
                    #mdict['YrA'] = stack_yra.astype('float32')
                    mdict['S'] = stack_s.astype('float32')
                    mdict['dff'] = stack_df.astype('float32')
                    mdict['dffr'] = stack_dfr.astype('float32')
                    mdict['rsnr'] = stack_snr.astype('float32')
                    mdict['rcor'] = stack_rval.astype('float32')
                    #mdict['idx'] = stack_idx
                    #mdict['idxbad'] = stack_idx_bad
                    
                    if np.any(stack_masks):
                        pth_mat_ex = pth_tif_ex[:-8] + fnadd + '_rois_.mat'

                    else:
                        mdict = {}
                        print("norois")
                        pth_mat_ex = pth_tif_ex[:-8] + fnadd + '_rois_NOROIS_.mat'

                except Exception as error:
                    
                    mdict = {}
                    pth_mat_ex = pth_tif_ex[:-8] + fnadd + '_rois_FAILURE_.mat'
                    print("An exception occurred:", type(error).__name__, "-", error) 

                
                sio.savemat(pth_mat_ex, mdict)

                if dview is not None: cm.stop_server(dview=dview)
