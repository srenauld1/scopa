
import sys
import numpy as np
import scipy.io as sio
import scipy

import glob
import os
from tifffile.tifffile import imwrite, imread

import caiman as cm
import caiman.source_extraction.cnmf as cnmf
from configs import configs
from caiman_vis_custom import caiman_plots_all, compute_correlations
from helpers import crop_fov, tracefunc

def pipeline(index_extraction_param_set, pth_datafile, pth_tif_reg_tmp, pth_tif_reg, pth_tif_dn, fn_prefix, 
                      pth_denoising, pth_denoised, md, do_motion_correction, 
                      do_denoise, use_denoised, do_cropping_session, do_extraction, do_planar_extraction, 
                      region_extraction, do_plots, cluster_backend, do_cluster):

    n_processes = 1
    dview = None

    ##########################   CAIMAN NORMCORRE MOTION CORRECTION   ##########################

    if do_motion_correction and not do_cropping_session:
        
        Y = imread(pth_datafile).astype('float32') ##having trouble on O2 with caiman function cm.load so just using imread from tifffile.tifffile
        
        Y = Y.reshape(md['dims'][0], md['dims'][1]+md['flyback'], md['dims'][2], md['dims'][3])
            
        Y = Y[:,:-md['flyback'],:,:] #crop md['flyback'] frames
        #Y[540:600,4,:,:].play(magnification=2) #play in order t z y x
        Y = np.transpose(Y, (0, 3, 2, 1)) #put in order t x y z 
        
        min_mov = int(np.min(Y))
        Y = Y - min_mov #make movie nonnegative (not sure this is necessary)
        print("MIN BEFORE MOTION CORRECTION " + str(min_mov))
        
        imwrite(pth_tif_reg_tmp[0], Y) #write as t x y z

        if do_cluster:
            if 'dview' in locals(): cm.stop_server(dview=dview)
            cc, dview, n_processes = cm.cluster.setup_cluster(backend=cluster_backend, n_processes=None, single_thread=False)

        opts_dict, indices_ex, fnadd = configs(index_extraction_param_set = None, fnames = pth_tif_reg_tmp, min_mov = min_mov, md = md) #configs for motion correction (will also define for extraction, but extraction params are in redefined later call to configs)
        opts = cnmf.params.CNMFParams(params_dict=opts_dict)

        #sys.setprofile(tracefunc)
        mc = cm.motion_correction.MotionCorrect(pth_tif_reg_tmp, dview=dview, **opts.get_group('motion'))
        mc.motion_correct(save_movie=True)
        os.remove(pth_tif_reg_tmp[0])

        border_to_0 = 0 if mc.border_nan == 'copy' else mc.border_to_0 
        basename_memap = pth_tif_reg[0].split('/')[-1][:-4]
        pth_mmap_reg = cm.save_memmap(mc.mmap_file, base_name=basename_memap, order='C', border_to_0=border_to_0, dview=dview) # save in order C (motion_correct above has to save in order F)
        Y, dims_spatial, dim_time = cm.load_memmap(pth_mmap_reg) 
        Y = np.reshape(Y.T, [dim_time] + list(dims_spatial), order='F') 
        
        min_mov_after_reg = int(np.min(Y))
        Y = Y - min_mov_after_reg #make movie nonnegative for extraction (not sure this is necessary)
        print("MIN AFTER MOTION CORRECTION " + str(min_mov_after_reg))

        os.remove(mc.mmap_file[0]) #remove the mmap file in F order 
        os.remove(pth_mmap_reg) #remove the mmap file in C order 
        
        imwrite(pth_tif_reg[0], np.transpose(Y.astype('uint16'), (0, 3, 2, 1)).reshape(dim_time * dims_spatial[2], dims_spatial[1], dims_spatial[0])) #write the registered movie as tif (uint16) for use in matlab, and caiman extraction below


    ##########################   BACKGROUND SUBTRACTION AND DEEPCAD DENOISING   ##########################

    if do_denoise and not do_cropping_session:
        os.system("source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh; \
          conda run -n deepcadrt ~/.conda/envs/deepcadrt/bin/python3 ~/scopa/denoise.py" \
            + " --pth_in " + pth_tif_reg[0] \
            + " --pth_out " + pth_tif_dn[0] \
            + " --pth_denoising " + pth_denoising \
            + " --pth_denoised " + pth_denoised \
            + " --fn_prefix " + fn_prefix \
            + " --dims " + ' '.join(map(str,  md['dims'])))
        

    ##########################   CAIMAN SOURCE EXTRACTION   ##########################

    if do_extraction or do_cropping_session:

        if use_denoised: 
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

            if rx == '':
                limits_str = ''
                Ycrop = Y.copy()
            else:
                Ycrop, limits_str = crop_fov(Y, rx, pth_exin, md['dims']) #define cuboid or rectangular fov for extraction (much faster if you don't need the full fov) 

            print(Ycrop.shape)

            if not do_cropping_session:
                
                pth_tif_ex = [pth_exin[0][:-4] + limits_str + '_caimanex_.tif']
                imwrite(pth_tif_ex[0], Ycrop) #must imwrite it to memmap it, and must memmap it to use patches in extraction
                basename_memap = pth_tif_ex[0].split('/')[-1][:-4]
                border_to_0 = 0 #if mc.border_nan == 'copy' else mc.border_to_0 
                fn_mmap_ex = cm.save_memmap(pth_tif_ex, base_name=basename_memap, order='C', border_to_0=border_to_0, dview=dview) # exclude borders
                os.remove(pth_tif_ex[0])
                Ycrop, dims_spatial, dim_time = cm.load_memmap(fn_mmap_ex)
                Ycrop = np.reshape(Ycrop.T, [dim_time] + list(dims_spatial), order='F') 
                print(Ycrop.shape)

                if index_extraction_param_set is None:
                    index_extraction_param_set_new = [None] #make it iterable with brackets
                elif index_extraction_param_set<0: #if negative, initiate loop over extraction params here, range [0 - index_extraction_param_set]
                    manual_start_ind = 0
                    index_extraction_param_set_new = np.arange(manual_start_ind, -index_extraction_param_set)
                else: #if positive, just the one extraction param whose index matches index_extraction_param_set
                    index_extraction_param_set_new = [index_extraction_param_set]
                                
                print("index_extraction_param_set NEW " + str(index_extraction_param_set_new))
                
                for ii in index_extraction_param_set_new:

                    try: #since some param sets will error

                        opts_dict, indices_ex, fnadd = configs(index_extraction_param_set = ii, fnames = fn_mmap_ex, md = md, do_planar_extraction = do_planar_extraction, dims_spatial = dims_spatial) #param set for extraction
                        opts = cnmf.params.CNMFParams(params_dict=opts_dict)

                        if do_planar_extraction: #adjust images and some params for planar 
                            sliceindz = np.arange(Ycrop.shape[-1])
                            dims_roimask_spatial = (dims_spatial[0], dims_spatial[1])
                        else:
                            sliceindz = [np.arange(Ycrop.shape[-1])] #all slices (not planar)
                            dims_roimask_spatial = (dims_spatial[0], dims_spatial[1], dims_spatial[2])

                        countz = 0
                        for si in sliceindz: #for each slice (or all slices if do_planar_extraction = false)

                            cnm = None
                            cnm2 = None

                            if do_planar_extraction:
                                print("PLANAR EXTRACTION FOR SLICE " + str(si))
                                images_sliced = Ycrop[:,:,:,si]
                            else:
                                print("3D EXTRACTION FOR ALL SLICES")
                                images_sliced = Ycrop #can't .copy() for some reason, for 3d extraction keep all images for loop over ii

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

                            if do_plots:
                                caiman_plots_all(cnm2, opts, images_sliced, dims_spatial, do_planar_extraction)

                            if countz==0: #do this zero padding so multiple extractions can be put into one array/saved, remove trailing zeros in matlab 

                                padnum = 10
                                padnum_b = 3
                                numroi_stack_pad = cnm2.estimates.A.shape[-1] + padnum #extra since it can vary a little across fits (even above input k)
                                dims_roimask_stack = ( dims_roimask_spatial + (numroi_stack_pad, ) )
                                dims_roimask_b_stack = ( dims_roimask_spatial + (cnm2.estimates.b.shape[-1] + padnum_b, ) )
                                dims_timeseries_stack = ( numroi_stack_pad, cnm2.estimates.C.shape[1] )

                                stack_masks = np.zeros(dims_roimask_stack + (len(sliceindz), ) )
                                stack_masks_b = np.zeros(dims_roimask_b_stack + (len(sliceindz), ) )
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
                            dims_mask_slice = (dims_roimask_spatial + (numroi_slice, ) )
                            dims_mask_b_slice = (dims_roimask_spatial + (numroi_b_slice, ) )
                            
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

                    except:
                        
                        mdict = {}
                        pth_mat_ex = [pth_tif_ex[0][:-5] + fnadd + 'rois_FAILURE_.mat']

                    
                    sio.savemat(pth_mat_ex[0], mdict)

                    if dview is not None: cm.stop_server(dview=dview)
