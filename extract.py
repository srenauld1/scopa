
import numpy as np
import scipy.io as sio
import glob
import os
from tifffile.tifffile import imwrite, imread

import caiman as cm
import caiman.source_extraction.cnmf as cnmf
from oex import oex
from vis_cm import caiman_plots_all
from stackcrop import stackcrop
from stackchan import stackchan
from helpers import stack_reshape_transpose_clip_zero_type
import json



def extract(pth_prefix, pth_tif_read, pth_optdf, pth_optroi, md, pthmd, extract_in_2d, methodex, rgname, maskname, do_crop_only=0, makeplots=0, cluster_backend='ipyparallel', use_cluster=0, optall=0):

    ##########################   CAIMAN SOURCE EXTRACTION   ##########################

    print("\n\n\nENTERING extract.py")

    n_processes = 1 #set this in case you don't (or can't) setup cluster 
    dview = None #set this in case you don't (or can't) setup cluster

    if not optall: #if not running extract from matlab (if you are, you will pass in options dict optall)
        stack = imread(pth_tif_read)

    chanrm, chan_primary_when_two, morphinpy = parse_methodex(methodex)
    stack, stack_secondary, two_channel_ex, chan_primary, chan_secondary, chanstr_primary, chanstr_secondary = stackchan(stack, md, pthmd, chanrm, chan_primary_when_two)

    stack = stack_reshape_transpose_clip_zero_type(stack, md['dims'])
    print("STACK HAS SHAPE: \n" + str(stack.shape))
    if two_channel_ex:
        if extract_in_2d:
            stack_secondary = stack_reshape_transpose_clip_zero_type(stack_secondary, md['dims'])
            print("STACK SECONDARY HAS SHAPE: \n" + str(stack_secondary.shape))
        else:
            raise Exception("two-channel extraction is currently not written for 3d extraction")


    for rgn in rgname:
        
        print("STARTINNG ROI EXTRACTION FROM FILE: \n" + pth_tif_read)

        stackcrop_tmp, limits_str = stackcrop(stack, rgn, pth_prefix, md['dims']) #define cuboid or rectangular fov for extraction (much faster if you don't need the full fov), careful your rectangle doesn't go off edge (croplim will have 0 in it, which creates empty array - need to fix this) 
        chanstr_ex = chanstr_secondary
        if two_channel_ex:
            stackcrop_tmp_secondary, limits_str = stackcrop(stack_secondary, rgn, pth_prefix, md['dims']) #define cuboid or rectangular fov for extraction (much faster if you don't need the full fov), careful your rectangle doesn't go off edge (croplim will have 0 in it, which creates empty array - need to fix this) 
            chanstr_seed = chanstr_primary

        print("REGION EXTRACTION (rgname) IS NAMED: \n" + rgn + "\n AND HAS SHAPE: \n" + str(stackcrop_tmp.shape))

        if not do_crop_only: #skip everything else if you're doing a cropping session

            pth_write_prefix = pth_tif_read[:-4] + rgn + '_' + limits_str + chanstr_ex + '_cmex'
            pth_tif_write_tmp = pth_write_prefix + '_tmp_.tif'
            if two_channel_ex: #stackcrop_tmp_secondary becomes stackcrop_ex and stackcrop_tmp becomes stackcrop_seed
                stackcrop_ex, pth_mmap_ex, dims_spatial_ex, dim_time_ex = stack2memmap(stackcrop_tmp_secondary, pth_tif_write_tmp, dview)
                pth_tif_write_tmp_secondary = pth_tif_write_tmp.replace(chanstr_ex, chanstr_seed) #only used if two_channel_ex==1 (ie if there are two channels and chanrm=None)
                stackcrop_seed, pth_mmap_seed, _, _ = stack2memmap(stackcrop_tmp, pth_tif_write_tmp_secondary, dview)
                stackcrop_tmp_secondary = None
            else:
                stackcrop_ex, pth_mmap_ex, dims_spatial_ex, dim_time_ex = stack2memmap(stackcrop_tmp, pth_tif_write_tmp, dview)
            stackcrop_tmp = None
            

            if not optall:
                optall = oex(pth_mmap_ex, md, dims_spatial_ex, extract_in_2d, two_channel_ex, pth_optdf, pth_optroi, methodex, rgn, maskname)

            print("looping over " + str(len(optall)) + " unique options sets")
            
            for k, (optid, opt) in enumerate(optall.items()):

                if 1: #try, since some param sets will error

                    if extract_in_2d: #adjust images and some params for 2D EXTRACTION 
                        indz = np.arange(stackcrop_ex.shape[3])
                        dims_roimask_spatial = (dims_spatial_ex[0], dims_spatial_ex[1])
                    else:
                        indz = [np.arange(stackcrop_ex.shape[3])] #all slices in one list (not 2D)
                        dims_roimask_spatial = (dims_spatial_ex[0], dims_spatial_ex[1], dims_spatial_ex[2])

                    cma_all = []
                    cmb_all = []
                    cmc_all = []
                    cmyra_all = []
                    cms_all = []
                    cmdff_all = []
                    cmdffr_all = []
                    cmsnr_all = []
                    cmrval_all = []
                    numroi_slice_all = []
                    numroi_b_slice_all = []
                    numroi_max_slice_all = 0

                    cnt = 0
                    for iz in indz: #for each slice (or all slices if extract_in_2d = false)

                        cnm = None
                        cnm2 = None
                        Ain = None
                       
                        print("extracting rois with options set index " + str(k) + ", and optid " + str(optid))
                        
                        cnmfpars = cnmf.params.CNMFParams(params_dict=opt)

                        if extract_in_2d: #for 2D extraction take one z slice at a time
                            print("DOING 2D EXTRACTION FOR SLICE " + str(iz) + " OF RGNAME '" + rgn + "'" )
                            img = stackcrop_ex[:,:,:,iz]
                        else: # for 3d extraction keep all z slices (for now, until implement z ranges)
                            print("DOING 3D EXTRACTION FOR ALL SLICES IN RGNAME '" + rgn + "'" )
                            img = stackcrop_ex #can't .copy() for some reason (but that's fine as long as you don't modify img)

                        if two_channel_ex: 
                            if morphinpy: 
                                imseed = stackcrop_seed[:,:,:,iz].mean(0) #right now seed images are forced to be 2d so indexing by iz is fine; in future will need if 3d switch
                                Ain = cm.base.rois.extract_binary_masks_from_structural_channel(imseed, min_area_size=opt['morph_min_area_size'], min_hole_size=opt['morph_min_hole_size'], gSig=opt['morph_gSig'], expand_method=opt['morph_expand_method'])[0]
                                # crd = plot_contours(Ain.astype('float32'), mR)
                            else:
                                print("loading predefined seed mask")
                                Ain = load_seed_mask(optid)

                        if use_cluster:
                            if 'dview' in locals(): cm.stop_server(dview=dview)
                            cc, dview, n_processes = cm.cluster.setup_cluster(backend=cluster_backend, n_processes=None, single_thread=False)

                        cnm = cnmf.CNMF(n_processes, params=cnmfpars, dview=dview, Ain=Ain)
                        cnm = cnm.fit(img) #scopa doens't use optional input to fit, indices; instead uses rgname

                        cnm.estimates.evaluate_components(img, cnm.params, dview=dview)
                        print(('NUM GOOD ROIS ' + str(len(cnm.estimates.idx_components)) + ' NUM BAD ROIS ' + str(len(cnm.estimates.idx_components_bad))))
                        
                        cnm.estimates.select_components(use_object=True, save_discarded_components=False)

                        if use_cluster:
                            if 'dview' in locals(): cm.stop_server(dview=dview)
                            cc, dview, n_processes = cm.cluster.setup_cluster(backend=cluster_backend, n_processes=None, single_thread=False)
        
                        cnm2 = cnm.refit(img)

                        cnm2.estimates.evaluate_components(img, cnm2.params, dview=dview)
                        print(('AFTER REFIT: NUM GOOD ROIS ' + str(len(cnm2.estimates.idx_components)) + ' NUM BAD ROIS ' + str(len(cnm2.estimates.idx_components_bad))))

                        cnm2.estimates.select_components(use_object=True, save_discarded_components=False)
                        cnm2.estimates.detrend_df_f(detrend_only=False, flag_auto=True, use_residuals=False) #use_residuals=False to not include residuals in traces for dff computation (default)
                        dff_residfalse = cnm2.estimates.F_dff 
                        cnm2.estimates.detrend_df_f(detrend_only=False, flag_auto=True, use_residuals=True) #use_residuals=True to include residuals in traces for dff computation
                        dff_residtrue = cnm2.estimates.F_dff 

                        if makeplots and cnm2.estimates.A.shape[-1]:
                            pth_results = pth_write_prefix + fnadd + '_' + str(iz) + '_OUT_FIT1.mov'
                            caiman_plots_all(cnm, cnmfpars, img, dims_spatial_ex, extract_in_2d, pth_results)
                            pth_results2 = pth_write_prefix + fnadd + '_' + str(iz) + '_OUT_FIT2.mov'
                            caiman_plots_all(cnm2, cnmfpars, img, dims_spatial_ex, extract_in_2d, pth_results2)
                        

                        numroi_slice = cnm2.estimates.A.shape[-1]
                        numroi_b_slice = cnm2.estimates.b.shape[-1]
                        dims_mask_slice = (dims_roimask_spatial + (numroi_slice, ) )
                        dims_mask_b_slice = (dims_roimask_spatial + (numroi_b_slice, ) )
                        

                        cma_all.append( np.reshape(cnm2.estimates.A.toarray(), dims_mask_slice, order='F') )
                        cmb_all.append( np.reshape(cnm2.estimates.b, dims_mask_b_slice, order='F') )
                        cmc_all.append( cnm2.estimates.C )
                        cmyra_all.append( cnm2.estimates.YrA )
                        cms_all.append( cnm2.estimates.S )
                        cmdff_all.append( dff_residfalse )
                        cmdffr_all.append( dff_residtrue )
                        cmsnr_all.append( cnm2.estimates.SNR_comp )
                        cmrval_all.append( cnm2.estimates.r_values )
                        numroi_slice_all.append( numroi_slice )
                        numroi_b_slice_all.append( numroi_b_slice )

                        numroi_max_slice_all = np.max((numroi_max_slice_all, numroi_slice))

                        cnt = cnt + 1
                    
                    dims_roimask_stack = ( dims_roimask_spatial + (numroi_max_slice_all, ) )
                    dims_roimask_b_stack = ( dims_roimask_spatial + (cnm2.estimates.b.shape[-1], ) )
                    dims_timeseries_stack = ( numroi_max_slice_all, cnm2.estimates.C.shape[1] )

                    cma = np.zeros(dims_roimask_stack + (len(indz), ) )
                    cmb = np.zeros(dims_roimask_b_stack + (len(indz), ) )
                    cmc = np.zeros(dims_timeseries_stack + (len(indz), ) )
                    #cmyra = np.zeros(dims_timeseries_stack + (len(indz), ) )
                    cms = np.zeros(dims_timeseries_stack + (len(indz), ) )
                    cmdff = np.zeros(dims_timeseries_stack + (len(indz), ) )
                    cmdffr = np.zeros(dims_timeseries_stack + (len(indz), ) )
                    cmsnr = np.zeros((dims_timeseries_stack[0], ) + (len(indz), ) )
                    cmrval = np.zeros((dims_timeseries_stack[0], ) + (len(indz), ) )
                    #stack_idx = np.zeros((dims_timeseries_stack[0], ) + (len(indz), ) )
                    #stack_idx_bad = np.zeros((dims_timeseries_stack[0], ) + (len(indz), ) )
                    for cnt in np.arange(len(indz)):

                        numroi_slice = numroi_slice_all[cnt]
                        numroi_b_slice = numroi_b_slice_all[cnt]

                        cma[..., :numroi_slice, cnt] = cma_all[cnt]
                        cmb[..., :numroi_b_slice, cnt] = cmb_all[cnt]
                        cmc[:numroi_slice,:,cnt] = cmc_all[cnt]
                        #cmyra[:numroi_slice,:,cnt] = cmyra_all[cnt]
                        cms[:numroi_slice,:,cnt] = cms_all[cnt]
                        cmdff[:numroi_slice,:,cnt] = cmdff_all[cnt]
                        cmdffr[:numroi_slice,:,cnt] = cmdffr_all[cnt]
                        cmsnr[:numroi_slice,cnt] = cmsnr_all[cnt]
                        cmrval[:numroi_slice,cnt] = cmrval_all[cnt]
                        #stack_idx[:cnm2.estimates.idx_components.shape[0],cnt] = cnm2.estimates.idx_components
                        #if cnm2.estimates.idx_components_bad.shape==(1,):
                        #    stack_idx_bad[:cnm2.estimates.idx_components_bad.shape[0],cnt] = cnm2.estimates.idx_components_bad 

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
                        pth_mat_ex = pth_write_prefix + optid + '_rois_.mat'

                    else:
                        mdict = {}
                        print("norois")
                        pth_mat_ex = pth_write_prefix + optid + '_rois_NOROIS_.mat'

                # except Exception as error:
                    
                #     mdict = {}
                #     pth_mat_ex = pth_write_prefix + fnadd + '_rois_FAILURE_.mat'
                #     print("An exception occurred:", type(error).__name__, "-", error) 

                
                sio.savemat(pth_mat_ex, mdict)

                os.remove(pth_mmap_ex)
                if two_channel_ex:
                    os.remove(pth_mmap_seed)

                if dview is not None: cm.stop_server(dview=dview)





def parse_methodex(methodex):
    
    chan_primary_when_two = None #irrelevant unless methodex starts with 'seed'
    morphinpy = 0
    if methodex=='1':
        chanrm = 2 #just in case 
    elif methodex=='2':
        chanrm = 1 #just in case 
    else:
        chanrm = None
        if methodex=='12':
            raise Exception('12 not supported yet')
        elif methodex.startswith('seed'):
            if 'each' in methodex:
                raise Exception('seedeachpy and seedeachmat not supported yet')
            else:
                if '1' in methodex and not '2' in methodex: 
                    chanrm = 2 
                elif '2' in methodex and not '1' in methodex: 
                    chanrm = 1 
                elif '12' in methodex:
                    chan_primary_when_two = 1
                elif '21' in methodex:
                    chan_primary_when_two = 2
                else:
                    raise Exception('seed methodex must contain each, 1, 2, 12, or 21')
            if methodex.endswith('py'):
                morphinpy = 1
            elif methodex.endswith('mat'):
                morphinpy = 0
            else:
                raise Exception('methodex starting with seed must end in py or mat')
        else:
            raise Exception('methodex must be 1, 2, 12, or start with seed')

    return chanrm, chan_primary_when_two, morphinpy


def stack2memmap(stackcrop_ex, pth_tif_write_tmp, dview):
    imwrite(pth_tif_write_tmp, stackcrop_ex.squeeze(), bigtiff=True, photometric='minisblack') #squeeze in case 3d . . . also must imwrite it to memmap it, and must memmap it to use patches in extraction
    basename_memap = pth_tif_write_tmp.split('/')[-1][:-4]
    pth_mmap_ex = cm.save_memmap([pth_tif_write_tmp], base_name=basename_memap, order='C', dview=dview) # exclude borders
    os.remove(pth_tif_write_tmp)
    stackcrop_ex, dims_spatial_ex, dim_time_ex = cm.load_memmap(pth_mmap_ex) #if 3d mmap should be 3d, but stackcrop_ex gets singleton 4th dim (z) added below so the code is more readable
    stackcrop_ex = np.reshape(stackcrop_ex.T, [dim_time_ex] + list(dims_spatial_ex), order='F') 
    if stackcrop_ex.ndim==3: #if it's not volumetric
        stackcrop_ex = stackcrop_ex[...,np.newaxis] #add singleton 4th dim (z) to simplify code below
    print("AFTER MEMMAPPING (AND ADDITION OF SINGLETON 4TH DIM IF stackcrop_ex IS NOT VOLUMETRIC), REGION EXTRACTION (rgname) HAS SHAPE: \n" + str(stackcrop_ex.shape))
    return stackcrop_ex, pth_mmap_ex, dims_spatial_ex, dim_time_ex

