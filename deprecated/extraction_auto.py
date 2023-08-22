from caiman_configs import configs
import caiman as cm
import caiman.source_extraction.cnmf as cnmf
import numpy as np
import scipy.io as sio
import glob
import os

#function written to attempt to run part of pipeline automated on google colab (failed because of start_server issues)
def extract_auto(index, pth_tif_ex, do_planar_extraction, dims_spatial, opts, fn_mmap_ex, anatomical_stack, dview):

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

        try: #since some param combos will error
            
            opts_dict, indices_ex, fnadd = configs(index = ii, do_planar_extraction=do_planar_extraction, dims_spatial = dims_spatial)
            opts.change_params(opts_dict) #i don't understand why i have to pass pth_tif_reg_tmp to motioncorrect and set in params object but i do 
            opts.change_params({'fnames': fn_mmap_ex}) #i don't understand why i have to pass pth_tif_reg_tmp to motioncorrect and set in params object but i do 
        
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

                if 'dview' in locals(): cm.stop_server(dview=dview)
                cc, dview, n_processes = cm.cluster.setup_cluster(backend='ipyparallel', n_processes=None, single_thread=False)

                cnm = cnmf.CNMF(n_processes, params=opts, dview=dview)
                cnm = cnm.fit(images_sliced, indices = indices_ex)

                cnm.estimates.evaluate_components(images_sliced, cnm.params, dview=dview)
                print(('NUMGOOD ' + str(len(cnm.estimates.idx_components)) + ' NUMBAD ' + str(len(cnm.estimates.idx_components_bad))))
                
                cnm.estimates.select_components(use_object=True, save_discarded_components=False)
                
                if 'dview' in locals(): cm.stop_server(dview=dview)
                cc, dview, n_processes = cm.cluster.setup_cluster(backend='ipyparallel', n_processes=None, single_thread=False)
                
                cnm2 = cnm.refit(images_sliced)
                cnm2.estimates.evaluate_components(images_sliced, cnm2.params, dview=dview)
                print(('REFIT: NUMGOOD ' + str(len(cnm2.estimates.idx_components)) + ' NUMBAD ' + str(len(cnm2.estimates.idx_components_bad))))
                
                cnm2.estimates.detrend_df_f(detrend_only=False, flag_auto=True, use_residuals=False) #use_residuals to use nondeconvolved traceds for dff computation (if p=0 use_residuals should not matter right?)
                dff_residfalse = cnm2.estimates.F_dff 
                cnm2.estimates.detrend_df_f(detrend_only=False, flag_auto=True, use_residuals=True) #use_residuals to use nondeconvolved traceds for dff computation (if p=0 use_residuals should not matter right?)
                dff_residtrue = cnm2.estimates.F_dff 
                cnm2.estimates.select_components(use_object=True, save_discarded_components=False)

                # if do_plots:
                #     caiman_plots_all(cnm2, opts, images_sliced, dims_spatial, do_planar_extraction)

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
                    # stack_idx = np.zeros((dims_timeseries_stack[0], ) + (len(sliceindz), ) )
                    # stack_idx_bad = np.zeros((dims_timeseries_stack[0], ) + (len(sliceindz), ) )

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

        except:
            
            mdict = {}
            pth_mat_ex = [pth_tif_ex[0][:-5] + fnadd + 'rois_FAILURE_.mat']

        
        sio.savemat(pth_mat_ex[0], mdict)

        if dview is not None: cm.stop_server(dview=dview)
