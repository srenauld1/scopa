
import numpy as np
import scipy.io as sio
import glob
import os
from tifffile.tifffile import imwrite, imread

import caiman as cm
import caiman.source_extraction.cnmf as cnmf
from configs import configs
from vis import caiman_plots_all
from crop_fov import crop_fov


def extract(index_extraction_param_set, pth_prefix, pth_tif_read, md, do_crop, extract_in_2d, regionex, makeplots, cluster_backend, use_cluster):

    ##########################   CAIMAN SOURCE EXTRACTION   ##########################

    print("\n\n\nENTERING EXTRACT FUNCTION")

    n_processes = 1 #set this in case you don't (or can't) setup cluster 
    dview = None #set this in case you don't (or can't) setup cluster

    Y = imread(pth_tif_read).astype('float32')
    Y = Y.reshape(md['dims'])
    Y = np.transpose(Y, (0, 3, 2, 1)) #put in order t x y z 
    print(Y.shape)

    for rx in regionex:
        
        print("ROI EXTRACTION FROM FILE: \n" + pth_tif_read)

        Ycrop, limits_str = crop_fov(Y, rx, pth_prefix, md['dims']) #define cuboid or rectangular fov for extraction (much faster if you don't need the full fov), careful your rectangle doesn't go off edge (croplim will have 0 in it, which creates empty array - need to fix this) 

        print("REGION EXTRACTION IS NAMED: \n" + rx + "\n AND HAS SHAPE: \n" + str(Ycrop.shape))

        if not do_crop: #skip everything else if you're doing a cropping session
            
            pth_tif_write_tmp = pth_tif_read[:-4] + rx + '_' + limits_str + '_cmex_tmp_.tif'
            imwrite(pth_tif_write_tmp, Ycrop.squeeze(), bigtiff=True, photometric='minisblack') #squeeze in case 3d . . . also must imwrite it to memmap it, and must memmap it to use patches in extraction
            basename_memap = pth_tif_write_tmp.split('/')[-1][:-4]
            border_to_0 = 0 #if mc.border_nan == 'copy' else mc.border_to_0 
            fn_mmap_ex = cm.save_memmap([pth_tif_write_tmp], base_name=basename_memap, order='C', border_to_0=border_to_0, dview=dview) # exclude borders
            os.remove(pth_tif_write_tmp)
            Ycrop, dims_spatial_ex, dim_time_ex = cm.load_memmap(fn_mmap_ex) #if 3d mmap should be 3d, but Ycrop gets singleton 4th dim (z) added below so the code is more readable
            Ycrop = np.reshape(Ycrop.T, [dim_time_ex] + list(dims_spatial_ex), order='F') 
            
            if len(Ycrop.shape)==3: #if it's not volumetric
                Ycrop = Ycrop[...,np.newaxis] #add singleton 4th dim (z) so the code is simpler later
            
            print("AFTER MEMMAPPING (AND ADDITION OF SINGLETON 4TH DIM IF ORIGINALLY 3D), REGION EXTRACTION HAS SHAPE: \n" + str(Ycrop.shape))

            if index_extraction_param_set == 'default':
                index_extraction_param_set_new = ['default'] #make it iterable with brackets
            elif index_extraction_param_set<0: #if negative, initiate loop over extraction params here, range [0 - index_extraction_param_set]
                manual_start_ind = 0
                index_extraction_param_set_new = np.arange(manual_start_ind, -index_extraction_param_set)
            else: #if positive, just the one extraction param whose index matches index_extraction_param_set
                index_extraction_param_set_new = [index_extraction_param_set]
                            
            print("looping over the following index_extraction_param_set values, to index into extraction param sets " + str(index_extraction_param_set_new))
            
            for ii in index_extraction_param_set_new:

                try: #try, since some param sets will error

                    if extract_in_2d: #adjust images and some params for planar 
                        sliceindz = np.arange(Ycrop.shape[3])
                        dims_roimask_spatial = (dims_spatial_ex[0], dims_spatial_ex[1])
                    else:
                        sliceindz = [np.arange(Ycrop.shape[3])] #all slices in one list (not planar)
                        dims_roimask_spatial = (dims_spatial_ex[0], dims_spatial_ex[1], dims_spatial_ex[2])

                    countz = 0
                    for si in sliceindz: #for each slice (or all slices if extract_in_2d = false)

                        cnm = None
                        cnm2 = None

                        # FOR SOME REASON CALLING configs OUTSIDE si LOOP CAUSES ALL LOOP ITERATIONS EXCEPT THE FIRST TO HAVE PROBLEMS (PRESUMABLY SOME CONFIG PARAM IS CHANGED ON EACH LOOP) FOR NOW PLACE IT INSIDE LOOP TO RESET ALL CONFIGS SO EACH SLICE GETS THE SAME - IT DOESN'T HURT ANYTHING, IT'S JUST SLIGHTLY INEFFICIENT 
                        opts_dict, indices_ex, fnadd = configs(index_extraction_param_set = ii, fnames = fn_mmap_ex, md = md, extract_in_2d = extract_in_2d, dims_spatial_ex = dims_spatial_ex) #param set for extraction
                        opts = cnmf.params.CNMFParams(params_dict=opts_dict)

                        if extract_in_2d: #for planar extraction take on z slice at a time
                            print("DOING PLANAR EXTRACTION FOR SLICE " + str(si) + " OF REGIONEX '" + rx + "'" )
                            images_sliced = Ycrop[:,:,:,si]
                        else: # for 3d extraction keep all z slices (for now, until implement z ranges)
                            print("DOING 3D EXTRACTION FOR ALL SLICES IN REGIONEX '" + rx + "'" )
                            images_sliced = Ycrop #can't .copy() for some reason (but that's fine as long as you don't modify images_sliced)

                        if use_cluster:
                            if 'dview' in locals(): cm.stop_server(dview=dview)
                            cc, dview, n_processes = cm.cluster.setup_cluster(backend=cluster_backend, n_processes=None, single_thread=False)

                        cnm = cnmf.CNMF(n_processes, params=opts, dview=dview)
                        cnm = cnm.fit(images_sliced, indices = indices_ex)
                        max_possible_num_roi = cnm.estimates.A.shape[-1]

                        cnm.estimates.evaluate_components(images_sliced, cnm.params, dview=dview)
                        print(('NUM GOOD ROIS ' + str(len(cnm.estimates.idx_components)) + ' NUM BAD ROIS ' + str(len(cnm.estimates.idx_components_bad))))
                        
                        cnm.estimates.select_components(use_object=True, save_discarded_components=False)

                        if use_cluster:
                            if 'dview' in locals(): cm.stop_server(dview=dview)
                            cc, dview, n_processes = cm.cluster.setup_cluster(backend=cluster_backend, n_processes=None, single_thread=False)
        
                        #cnm2 = cnm.refit(images_sliced)
                        cnm2 = cnm

                        cnm2.estimates.evaluate_components(images_sliced, cnm2.params, dview=dview)
                        print(('AFTER REFIT: NUM GOOD ROIS ' + str(len(cnm2.estimates.idx_components)) + ' NUM BAD ROIS ' + str(len(cnm2.estimates.idx_components_bad))))

                        cnm2.estimates.select_components(use_object=True, save_discarded_components=False)
                        cnm2.estimates.detrend_df_f(detrend_only=False, flag_auto=True, use_residuals=False) #use_residuals=False to not include residuals in traces for dff computation (default)
                        dff_residfalse = cnm2.estimates.F_dff 
                        cnm2.estimates.detrend_df_f(detrend_only=False, flag_auto=True, use_residuals=True) #use_residuals=True to include residuals in traces for dff computation
                        dff_residtrue = cnm2.estimates.F_dff 


                        if makeplots and cnm2.estimates.A.shape[-1]:
                            pth_results = pth_tif_write_tmp[:-8] + fnadd + '_' + str(si) + '_OUT_FIT1.mov'
                            caiman_plots_all(cnm, opts, images_sliced, dims_spatial_ex, extract_in_2d, pth_results)

                        # if makeplots and cnm2.estimates.A.shape[-1]:
                        #     pth_results2 = pth_tif_write_tmp[:-8] + fnadd + '_' + str(si) + '_OUT_FIT2.mov'
                        #     caiman_plots_all(cnm2, opts, images_sliced, dims_spatial_ex, extract_in_2d, pth_results2)
                        
                
                        if countz==0: #do this zero padding so multiple extractions can be put into one array/saved, remove trailing zeros in matlab 

                            dims_roimask_stack = ( dims_roimask_spatial + (max_possible_num_roi, ) )
                            dims_roimask_b_stack = ( dims_roimask_spatial + (cnm2.estimates.b.shape[-1], ) )
                            dims_timeseries_stack = ( max_possible_num_roi, cnm2.estimates.C.shape[1] )

                            cma = np.zeros(dims_roimask_stack + (len(sliceindz), ) )
                            cmb = np.zeros(dims_roimask_b_stack + (len(sliceindz), ) )
                            cmc = np.zeros(dims_timeseries_stack + (len(sliceindz), ) )
                            #cmyra = np.zeros(dims_timeseries_stack + (len(sliceindz), ) )
                            cms = np.zeros(dims_timeseries_stack + (len(sliceindz), ) )
                            cmdff = np.zeros(dims_timeseries_stack + (len(sliceindz), ) )
                            cmdffr = np.zeros(dims_timeseries_stack + (len(sliceindz), ) )
                            cmsnr = np.zeros((dims_timeseries_stack[0], ) + (len(sliceindz), ) )
                            cmrval = np.zeros((dims_timeseries_stack[0], ) + (len(sliceindz), ) )
                            #stack_idx = np.zeros((dims_timeseries_stack[0], ) + (len(sliceindz), ) )
                            #stack_idx_bad = np.zeros((dims_timeseries_stack[0], ) + (len(sliceindz), ) )

                        numroi_slice = cnm2.estimates.A.shape[-1]
                        numroi_b_slice = cnm2.estimates.b.shape[-1]
                        dims_mask_slice = (dims_roimask_spatial + (numroi_slice, ) )
                        dims_mask_b_slice = (dims_roimask_spatial + (numroi_b_slice, ) )
                        
                        cma[..., :numroi_slice, countz] = np.reshape(cnm2.estimates.A.toarray(), dims_mask_slice, order='F') 
                        cmb[..., :numroi_b_slice, countz] = np.reshape(cnm2.estimates.b, dims_mask_b_slice, order='F') 
                        cmc[:numroi_slice,:,countz] = cnm2.estimates.C 
                        #cmyra[:numroi_slice,:,countz] = cnm2.estimates.YrA 
                        cms[:numroi_slice,:,countz] = cnm2.estimates.S 
                        cmdff[:numroi_slice,:,countz] = dff_residfalse
                        cmdffr[:numroi_slice,:,countz] = dff_residtrue
                        cmsnr[:numroi_slice,countz] = cnm2.estimates.SNR_comp 
                        cmrval[:numroi_slice,countz] = cnm2.estimates.r_values 
                        #stack_idx[:cnm2.estimates.idx_components.shape[0],countz] = cnm2.estimates.idx_components
                        #if cnm2.estimates.idx_components_bad.shape==(1,):
                        #    stack_idx_bad[:cnm2.estimates.idx_components_bad.shape[0],countz] = cnm2.estimates.idx_components_bad 

                        countz = countz + 1

                    log_files = glob.glob('*_LOG_*')
                    for log_file in log_files:
                        os.remove(log_file)

                    mdict = {}
                    mdict['cma'] = cma.astype('float32')
                    mdict['cmb'] = cmb.astype('float32')
                    mdict['cmc'] = cmc.astype('float32')
                    #mdict['YrA'] = cmyra.astype('float32')
                    mdict['cms'] = cms.astype('float32')
                    mdict['cmdff'] = cmdff.astype('float32')
                    mdict['cmdffr'] = cmdffr.astype('float32')
                    mdict['cmsnr'] = cmsnr.astype('float32')
                    mdict['cmrval'] = cmrval.astype('float32')
                    #mdict['idx'] = stack_idx
                    #mdict['idxbad'] = stack_idx_bad
                    
                    if np.any(cma):
                        pth_mat_ex = pth_tif_write_tmp[:-8] + fnadd + '_rois_.mat'

                    else:
                        mdict = {}
                        print("norois")
                        pth_mat_ex = pth_tif_write_tmp[:-8] + fnadd + '_rois_NOROIS_.mat'

                except Exception as error:
                    
                    mdict = {}
                    pth_mat_ex = pth_tif_write_tmp[:-8] + fnadd + '_rois_FAILURE_.mat'
                    print("An exception occurred:", type(error).__name__, "-", error) 

                
                sio.savemat(pth_mat_ex, mdict)

                if dview is not None: cm.stop_server(dview=dview)
