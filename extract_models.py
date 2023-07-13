

import numpy as np
import scipy.io as sio
import glob
import os

import caiman as cm
import caiman.source_extraction.cnmf as cnmf
from caiman_plots import compute_correlations

def extract_2d(opts_dict, fname, do_motion_correction, planar_extraction, do_refit, indices_ex, fname_save, srv):

    n_processes = 1
    dview = None
    opts = cnmf.params.CNMFParams(params_dict=opts_dict)
    opts.change_params({'fnames': fname}) #i don't understand why i have to pass fname to motioncorrect and set in params object but i do 
    #cc, dview, n_processes = cm.cluster.setup_cluster(backend='ipyparallel', n_processes=None, single_thread=False)

    if do_motion_correction:
                
        mc = cm.motion_correction.MotionCorrect(fname, dview=dview, **opts.get_group('motion'))
        mc.motion_correct(save_movie=True)

        fname_ex = mc.mmap_file
    
    else:
       
        fname_ex = fname
        #fname_ex = ['/Users/wienecke/Documents/ambrose/leprechaunMat/20230627-2_D05_syt7f_018_syt7f/20230627_2_hires_caimanreg__rig__d1_256_d2_140_d3_113_order_F_frames_80.mmap']

        
    Yr, dims, T = cm.load_memmap(fname_ex[0]) #np.allclose(images, images2, rtol=1e-05, atol=1e-04, equal_nan=False)
    images = np.reshape(Yr.T, [T] + list(dims), order='F') 

    #Cn_o = compute_correlations(fname_ex[0], dims)

    if planar_extraction: #adjust images and some params for planar 
        
        sliceindz = np.arange(images.shape[-1])
        if srv==0 and len(sliceindz)>20: #forced reduce while i'm working with the anatomical stack 
            sliceindz = np.arange(25, 27)
        
        indices_ex = indices_ex[:-1] #change from 3d to 2d 

        dims_mask_space = (dims[0], dims[1])
        opts_dict_2d = {'dxy': opts.data['dxy'][:-1],
            'sigma_smooth_snmf' : opts.init['sigma_smooth_snmf'][:-1],
            'gSig' : opts.init['gSig'][:-1],
            'gSiz' : opts.init['gSiz'][:-1],
            'se' : np.ones((3,)*len(opts.init['gSig'][:-1]), dtype=np.uint8)} #change some params from 3d to 2d
        
        opts.change_params(opts_dict_2d)

    else:
        
        sliceindz = [np.arange(images.shape[-1])] #all slices (not planar)
        dims_mask_space = (dims[0], dims[1], dims[2])

    countz = 0
    for si in sliceindz: #for each slice (or all slices if planar_extraction = false)

        images_sliced = images[:,:,:,si]
        
        #if 'dview' in locals(): cm.stop_server(dview=dview)
        #cc, dview, n_processes = cm.cluster.setup_cluster(backend='ipyparallel', n_processes=None, single_thread=False)
        
        cnm = cnmf.CNMF(n_processes, params=opts, dview=dview)
        cnm = cnm.fit(images_sliced, indices = indices_ex)

        if planar_extraction:

            Cn = cm.local_correlations(images_sliced.transpose(1,2,0))
            print(Cn.shape)
            Cn[np.isnan(Cn)] = 0
            print('you may need to change the data rate to generate nb_view_components: use jupyter notebook --NotebookApp.iopub_data_rate_limit=1.0e10 before opening jupyter notebook')
            if srv==0:
                cnm.estimates.plot_contours(img=Cn)
                cnm.estimates.view_components(img=Cn, idx=cnm.estimates.idx_components)
                #cnm.estimates.view_components(img=None, idx=cnm.estimates.idx_components) #img=None for mean projection
        
        else:
            
            if srv==0:
                cnm.estimates.nb_view_components_3d(image_type='mean', dims=dims, axis=2)
                #cnm.estimates.nb_view_components_3d(image_type='corr', dims=dims, Yr=Yr, denoised_color='red', max_projection=True);

        cnm.estimates.evaluate_components(images_sliced, cnm.params, dview=dview)

        print(('Keeping ' + str(len(cnm.estimates.idx_components)) + ' and discarding  ' + str(len(cnm.estimates.idx_components_bad))))

        cnm.estimates.select_components(use_object=True)
        
        if do_refit:

            #if 'dview' in locals(): cm.stop_server(dview=dview)
            #cc, dview, n_processes = cm.cluster.setup_cluster(backend='ipyparallel', n_processes=None, single_thread=False)
            
            cnm2 = cnm.refit(images_sliced)

            cnm2.estimates.evaluate_components(images_sliced, cnm2.params, dview=dview)

            print(('REFIT: Keeping ' + str(len(cnm2.estimates.idx_components)) + ' and discarding  ' + str(len(cnm2.estimates.idx_components_bad))))

            test_c = cnm2.estimates.C
            test_yra = cnm2.estimates.YrA
            test_s = cnm2.estimates.S
            test_dff = cnm2.estimates.F_dff

            cnm2.estimates.detrend_df_f(detrend_only=False, flag_auto=True, use_residuals=True) #use_residuals to use nondeconvolved traceds for dff computation (if p=0 use_residuals should not matter right?)

            print(np.array_equal(test_c, cnm2.estimates.C))
            print(np.array_equal(test_yra, cnm2.estimates.YrA))
            print(np.array_equal(test_s, cnm2.estimates.S))
            print(np.array_equal(test_dff, cnm2.estimates.F_dff))

            cnm2.estimates.select_components(use_object=True)

        else:
            
            cnm2 = cnm
        
        if srv==0:
            if planar_extraction:
                cnm.estimates.view_components(img=Cn, idx=cnm.estimates.idx_components) #img=Cn for mean proj
            else:
                cnm.estimates.nb_view_components_3d(image_type='mean', dims=dims, axis=2)
                #cnm.estimates.nb_view_components_3d(image_type='corr', dims=dims, Yr=Yr, denoised_color='red', max_projection=True);

            cnm2.estimates.play_movie(images_sliced, q_max=99.9, gain_res=2, magnification=2, bpx=True, include_bck=False, save_movie=True)
            
            #denoised_movie = cm.movie(cnm2.estimates.A.dot(cnm2.estimates.C) + \
            #            cnm2.estimates.b.dot(cnm2.estimates.f)).reshape(dims + (-1,), order='F').transpose([3, 0, 1, 2]) #%% reconstruct denoised movie 
            
        if countz==0:
            
            dims_mask = (dims_mask_space + (cnm2.estimates.A.shape[-1], ) )
            dims_mask_b = (dims_mask_space + (cnm2.estimates.b.shape[-1], ) )
            dims_timeseries = cnm2.estimates.C.shape

            stack_masks = np.zeros(dims_mask + (len(sliceindz), ) )
            stack_masks_b = np.zeros(dims_mask_b + (len(sliceindz), ) )
            stack_cen = np.zeros(cnm2.estimates.center.shape + (len(sliceindz), ) )
            stack_c = np.zeros(dims_timeseries + (len(sliceindz), ) )
            stack_yra = np.zeros(dims_timeseries + (len(sliceindz), ) )
            stack_s = np.zeros(dims_timeseries + (len(sliceindz), ) )
            stack_df = np.zeros(dims_timeseries + (len(sliceindz), ) )
            stack_snr = np.zeros((dims_timeseries[0], ) + (len(sliceindz), ) )
            stack_rval = np.zeros((dims_timeseries[0], ) + (len(sliceindz), ) )

        stack_masks[...,countz] = np.reshape(cnm2.estimates.A.toarray(), dims_mask, order='F') #the roi stack, binary version below
        stack_masks_b[...,countz] = np.reshape(cnm2.estimates.b, dims_mask_b, order='F') #the roi stack, binary version below
        stack_cen[...,countz] = cnm2.estimates.center #the roi stack, binary version below
        stack_c[:,:,countz] = cnm2.estimates.C #the roi stack, binary version below
        stack_yra[:,:,countz] = cnm2.estimates.YrA #the roi stack, binary version below
        stack_s[:,:,countz] = cnm2.estimates.S #the roi stack, binary version below
        stack_df[:,:,countz] = cnm2.estimates.F_dff #the roi stack, binary version below
        stack_snr[:,countz] = cnm2.estimates.SNR_comp #the roi stack, binary version below
        stack_rval[:,countz] = cnm2.estimates.r_values #the roi stack, binary version below

        countz = countz + 1

    log_files = glob.glob('*_LOG_*')
    for log_file in log_files:
        os.remove(log_file)

    mdict = {}
    mdict['roimasks'] = stack_masks
    mdict['roimasks_b'] = stack_masks_b
    mdict['cen'] = stack_cen
    mdict['C'] = stack_c
    mdict['YrA'] = stack_yra
    mdict['S'] = stack_s
    mdict['dff'] = stack_df
    mdict['snr'] = stack_snr
    mdict['rval'] = stack_rval
    
    sio.savemat(fname_save,mdict)

    if dview is not None: cm.stop_server(dview=dview)

    return mdict