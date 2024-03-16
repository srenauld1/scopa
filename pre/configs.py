

import numpy as np
from map2params import map2params, map2params_t5

##########################################################################################################################################

# configs for caiman motion correction and source extraction
# this is not comprehensive, but should be the most likely params to require tuning 
# below is more comprehensive for extraction than motion correction 

##########################################################################################################################################

def configs(register_in_2d = True, index_extraction_param_set = 'default', fnames = None, min_mov = 0,
            md = None, extract_in_2d = None, dims_spatial_ex = 0):

    #md['dims'] is dims of original fov, dims_spatial_ex is dims of extraction fov (which may be cropped, so not necessarily the same as md['dims']

   
    ### motion correction configs ###

    pw_rigid = False #rigid or non, for tiny fly brains i'm guessing nonrigid is not necessary and invites artifact, so i always leave false, but i've not noticed a difference in tests with my data yet 
    nonneg_movie = True #true because i make it nonnegative before registration
    min_mov = min_mov

    niter_rig = 1 #default 1, number registration iterations (regardles of pw_rigid, or is3d)
    max_deviation_rigid = 3 #only relevant if pw_rigid==True, this is max amount patches can deviate from whole fov rigid shifts 
    shifts_opencv = False #automatically false if is3D_mc==true, or if pw_rigid = True . . . so true only works for rigid 2d registration . . . true uses intercubic interp (faster but smoother), false uses fourier
    upsample_factor_grid = 4 #default 4, use for merging patches if pw_rigid==True


    if md['dims'][1]==1 or register_in_2d:
        is3D_mc = False #if not 3d, register each slice . . . 
        indices_mc = (slice(None), slice(None)) #if is3d is true for motion correction, will overwrite with nones and will lose indices_ex
        strides_mc = (24, 24) #ignored if pw_rigid==False, otherwise this is piecewise patch stride 
        overlaps_mc = (12, 12) #ignored if pw_rigid==False, otherwise this is piecewise patch overlap
        max_shifts_mc = (8, 8) #max allowed shifts (in patch if piecewise, or whole fov if not) 
    else:
        is3D_mc = True
        indices_mc = (slice(None), slice(None), slice(None)) #if is3d is true for motion correction, will overwrite with nones and will lose indices_ex
        strides_mc = (24, 24, 6) #ignored if pw_rigid==False, otherwise this is piecewise patch stride 
        overlaps_mc = (12, 12, 3)#ignored if pw_rigid==False, otherwise this is piecewise patch overlap
        max_shifts_mc = (8, 8, 2)#max allowed shifts (in patch if piecewise, or whole fov if not) 


    ### roi extraction params ###

    do_slices = False #my crop_fov is meant to replace this, so should always be false
    if do_slices:
        sly = slice(6, 51, 1)
        slx = slice(40, 181, 1)
        slz = slice(1, 9, 1)
        indices_ex = [slx, sly, slz]
    else:
        indices_ex = [slice(None), slice(None), slice(None)]


    p = 1 # order of the autoregressive system - 0 for nonspiking, 1 for instanteous rise but not decay, 2 for non-ionstantaneous rise and decay
    merge_thresh = 0.85
    gSig_z = 1 # gSig in z dimension (ignored if extract_in_2d==True), anything below 1 will have same effect as 1, consider that our z are often much larger than xy when you set this, so if neurons are restricted to single z planes, make this 1
    gSig = [2, 2, gSig_z] #forced to be odd so gsiz min is 3 (ie gsig 0.5 is same as 1)  # gSig = [3,3]            # radius (half-size) of average neurons (in pixels)
    nb = 1 #num background components

    fr = md['volrate'] #0.6193  #9.8465 frame period so 1000 / (9.8465 *(113+51)) # approximate frame rate of data - CONFIRMED FPS
    decay_time = .4  # only for deconvolution, length of transient - CONFIRMED APPROPRIATE FOR OUR INDICATOR GCaMP6f
    dxy = [md['xpix']/md['xfov'], md['ypix']/md['yfov'], md['numslice']/md['zfov']] #pixels per micron

    tsub = 1  # temporal downsampling
    ssub = 1  # spatial downsampling
    p_ssub = 1 #patch downsampling in space
    p_tsub = 1 #patch downsampling in time

    only_init = False #only use the initialization for extraction (no alternating least squares for spatial and temporal refinement)
    method_init = 'graph_nmf' #'greedy_roi' #'graph_nmf' #sparse_nmf 'greedy_roi' python Caiman defaults to greedy_roi, looks for globular sources 

    #params for method_init sparse_nmf or graph_nmf
    max_iter_snmf = 1000 #for method_init sparse_nmf or graph_nmf
    perc_baseline_snmf = 20 #for method_init sparse_nmf or graph_nmf

    sigma_smooth_snmf_z = 0.5 #for method_init sparse_nmf or graph_nmf #can be less than 1 and have effect, unlike gsig, make small if z are larger than neuron extent in z
    sigma_smooth_snmf_t = 0.5 #for method_init sparse_nmf or graph_nmf #smoothing in time before sparsenmf init
    sigma_smooth_snmf = [sigma_smooth_snmf_t, gSig[0], gSig[1], sigma_smooth_snmf_z] #for method_init sparse_nmf or graph_nmf #smoothing std prior to initialization in sparse_nmf method, default 0.5 0.5 0.5

    alpha_snmf = 0.5 #ONLY FOR method_init sparse_nmf . . . sparsity penalty, default 0.5

    lambda_gnmf = 1 #ONLY FOR method_init graph_nmf . . .  sparsity for method_init graphNMF
    SC_kernel = 'heat' #ONLY FOR method_init graph_nmf . . . #NOT TUNABLE NOW       # kernel for graph affinity matrix
    SC_sigma = 1 #ONLY FOR method_init graph_nmf . . .              # std for SC kernel
    SC_thr = 0   #ONLY FOR method_init graph_nmf . . .               # threshold for affinity matrix
    SC_normalize = True  #ONLY FOR method_init graph_nmf . . .       # standardize entries prior to computing affinity matrix
    SC_use_NN = False  #ONLY FOR method_init graph_nmf . . .         # sparsify affinity matrix by using only nearest neighbors
    SC_nnn = 20      #ONLY FOR method_init graph_nmf . . .           # number of nearest neighbors to use if SC_use_NN = True


    low_rank_background = True #True #true makes bankground nb, false makes it update with hals, if true with patches, each patch keeps its background, if false, each patch bg approximated withg global background
    update_background_components = True

    fudge_factor = 0.96        # (default is 0.96; old value = 1) -- bias correction factor for discrete time constants
    ITER = 2                # (default is 2; old value=5) -- block coordinate descent iterations
    bas_nonneg = False #appears to not matter unless you're deconvolving (p is 1 or 2, not 0)

    rolling_sum = True #think (?) only relevant for init method greedy_roi

    #during refinement, in update_spatial, the following params are used in function threshold_components
    thr_method = 'nrg' #or 'max'
    maxthr = 0.1 #for  thr_method = 'max' keep pixels above this threshold
    nrgthr = 0.9999 #for  thr_method = 'nrg' keep pixels whose sorted cumsum contributes this much of total energy
    extract_cc = True #true will throw away isolated pixels of some kind (cc means connected components)

    #Each parameter has a low threshold (rval_lowest (default -1), SNR_lowest (default 0.5), cnn_lowest (default 0.1))
    # and high threshold (rval_thr (default 0.8), min_SNR (default 2.5), min_cnn_thr (default 0.9)).
    # A component has to exceed ALL low thresholds as well as ONE high threshold to be accepted.
    # can turn off CNN part withy use_CNN = false
    # these values will result in no roi filtering
    SNR_lowest = 0#0.5#0  #0.5 default       # minimum SNR for accepted components
    min_SNR = 0#0  #2.5 default    # accept components with that peak-SNR or higher
    rval_lowest = -1  # -1 default 0.6  # space correlation threshold
    rval_thr = 0#0  # 0.8 default  # space correlation threshold
    use_cnn = False      # True default # use the CNN classifier affects if 2 below params are used
    cnn_lowest = 0  #0.1 default  # neurons with cnn probability lower than this value are rejected
    min_cnn_thr = 0 #0.9 default # if cnn classifier predicts below this value, reject

    # stride_to_rf_ratio (along with gSig) is for automatic calculation of rf, stride, and k,
    # recommend stride_to_rf_ratio in approxoimate range 0.3 - 0.8 (must be 0 < stride_to_rf_ratio <=1)
    # smaller stride_to_rf_ratio means larger patch with smaller patch overlap (caiman mistakenly calls patch overlap "stride", when true stride is distance between patches)
    # caiman docs say patch diameter should be 3-4 times neuron diameter and patch stride should be at least neuron diameter
    # neuron diameter is approximately gsiz, and gsiz is gsig*2+1 for each element of gsig (each dimension xy if 2d extraction, or xyz if 3d extraction)
    # calculation below is just based on the largest dim of neuron (max(gsiz)), to be conservative
    # if gsig is very different across dims you may consider a different automated calculation of rf and stride and k
    # patch diameter = ceil(neuron_dia/stride_to_rf_ratio)+1)*2
    # patch stride = ceil(ceil(neuron_dia/stride_to_rf_ratio)+1)*stride_to_rf_ratio)+1
    # therefore . . .  
    #   when stride_to_rf_ratio = 0.3, patch is ~7 times larger than neuron diameter, max(gsiz), and stride is 50% larger
    #   when stride_to_rf_ratio = 0.8, patch is ~3 times larger than neuron diameter, max(gsiz), and stride is still 50% larger
    
    stride_to_rf_ratio = 0.3  #keep in approxoimate range 0.3 - 0.8
    use_patch_size_threshold = 50 #skip patch extraction if all dims are smaller than this 

    if index_extraction_param_set != 'default': #create param set whose index matches value in index_extraction_param_set
        if md['dims'][1]==1:
            print("USING ALTERNATE MAP2PARAMS FOR CARLS OLD PROJECT")
            map_index_2_params = map2params_t5()
        else:
            map_index_2_params = map2params()

        print('indexing into param set')
        merge_thresh, m2p_gsig_xy, nb, SC_sigma, lambda_gnmf, perc_baseline_snmf, max_iter_snmf = \
            map_index_2_params.map_index(int(index_extraction_param_set))
        gSig = [m2p_gsig_xy, m2p_gsig_xy, gSig_z]  

    if np.all(np.array(dims_spatial_ex)<use_patch_size_threshold): #dont bother with patches if FOV is small enough (but this should be adjusted for dirtier drivers)
        do_patches = False
    else:
        do_patches = True

    gSiz = [int(np.round(2*gstmp + 1)) for gstmp in gSig] #put here at end to register any gSig change

    #determine k in automated way based on gSig, roi_decimation_fac, and stride_to_rf_ratio, while also satisfying caiman patch size recommendations
    roi_decimation_fac = 0.4  #1 is "space filling", caiman demo does not use this variable, but effectively their demo sets it at 0.33)
    if do_patches: # PROCESS IN PATCHES AND THEN COMBINE, patches are useful if activity stats vary over fov (e.g. extracting same neurons from regions with varying SNR, patch runs will adapt to local stats)

        if extract_in_2d==True:
            maxgsiz = np.max(gSiz[0:2])
        else:
            maxgsiz = np.max(gSiz)

        rf = int(np.ceil((maxgsiz) / stride_to_rf_ratio)) + 1
        patchFW = rf*2 #patch full width, since rf is half
        stride_cnmf = int(np.ceil(rf * stride_to_rf_ratio)) + 1

        p_patch = p
        nb_patch = nb
        if extract_in_2d==True:
            k = int(np.round( (patchFW*patchFW) / np.prod(gSiz[0:2])*roi_decimation_fac))  # number of components in each patch
        else:
            if patchFW<dims_spatial_ex[2]:
                rfz = patchFW
            else:
                rfz = dims_spatial_ex[2]
            k = int(np.round( (patchFW*patchFW*rfz) / np.prod(gSiz)*roi_decimation_fac))  # number of components in each patch
        indices_ex = [slice(None), slice(None), slice(None)]
    else: # PROCESS THE WHOLE FOV AT ONCE
        rf = None # setting rf to none will run CNMF on the whole FOV
        stride_cnmf = None       
        p_patch = p
        nb_patch = nb
        k = int(np.round( np.prod(dims_spatial_ex) / np.prod(gSiz)*roi_decimation_fac))  # number of components in whole fov (the "whole fov patch")

    
    if extract_in_2d==True:
        dimstr = '2dex'
        indices_ex = indices_ex[:-1] #change from 3d to 2d
        dxy = dxy[:-1] #change from 3d to 2d
        gSig = gSig[:-1] #change from 3d to 2d
        gSiz = gSiz[:-1] #change from 3d to 2d
        sigma_smooth_snmf = sigma_smooth_snmf[:-1] #change from 3d to 2d
    else:
        dimstr = "3dex"

    se = np.ones((3,)*len(gSig), dtype=np.uint8)  #put here at end to register any gSig change #se = np.ones((3,3,1), dtype=np.uint8)
    #medw = (3,)*len(gSig)
    
    fnadd = str(gSig[0]) + '_' + str(nb) + '_' + str(merge_thresh) \
        + '_' + str(rf) + '_' + str(SC_sigma) + '_' + str(lambda_gnmf) + '_' + str(perc_baseline_snmf) \
        + '_' + str(max_iter_snmf) + '_' + str(ITER) \
        + '_' + str(k) + '_' + method_init.split('_')[0] + '_' + dimstr

    if extract_in_2d is None: #it's none during motion correction, when we don't care about these params, rather than true/false
        print("motion correction params configured")
    else:
        print("index_extraction_param_set is " + str(index_extraction_param_set) + " with filename string " + fnadd)

    opts_dict = {'strides': strides_mc,    # start a new patch for pw-rigid motion correction every x pixels
                'overlaps': overlaps_mc,   # overlap between pathes (size of patch strides+overlaps)
                'max_shifts': max_shifts_mc,   # maximum allowed rigid shifts (in pixels)
                'max_deviation_rigid': max_deviation_rigid,  # maximum shifts deviation allowed for patch with respect to rigid shifts
                'pw_rigid': pw_rigid,         # flag for performing non-rigid motion correction
                'is3D': is3D_mc,
                'nonneg_movie':nonneg_movie,
                'min_mov': min_mov,
                'shifts_opencv':shifts_opencv,
                'niter_rig':niter_rig,
                'upsample_factor_grid':upsample_factor_grid,
                'fr': fr,
                'p': p,
                'nb': nb,
                'merge_thr': merge_thresh,
                'rf': rf,
                'indices': indices_mc,  #for some reason indices_mc is causing error, maybe needs list for mc and tuple for extraction?
                'K': k,
                'gSig': gSig,
                'gSiz': gSiz,
                'stride': stride_cnmf,
                'method_init': method_init,
                'perc_baseline_snmf': perc_baseline_snmf,
                'max_iter_snmf': max_iter_snmf,
                'sigma_smooth_snmf': sigma_smooth_snmf,
                'SC_kernel': SC_kernel, #NOT TUNABLE NOW       # kernel for graph affinity matrix
                'SC_sigma': SC_sigma,            # std for SC kernel
                'SC_thr': SC_thr,                 # threshold for affinity matrix
                'SC_normalize': SC_normalize,        # standardize entries prior to computing affinity matrix
                'SC_use_NN': SC_use_NN,          # sparsify affinity matrix by using only nearest neighbors
                'SC_nnn': SC_nnn,                # number of nearest neighbors to use if SC_use_NN = True
                'lambda_gnmf': lambda_gnmf, #for method_init graphNMF
                'alpha_snmf': alpha_snmf, #for method_init sparseNMF
                #'dims': dims,
                'dxy': dxy,
                'decay_time': decay_time,
                'bas_nonneg': bas_nonneg,
                'p_patch': p_patch,
                'nb_patch': nb_patch,
                'se': se,
                'rolling_sum': rolling_sum,
                'only_init': only_init,
                'ssub': ssub,
                'tsub': tsub,
                'p_ssub': p_ssub,
                'p_tsub': p_tsub,
                'SNR_lowest': SNR_lowest,
                'min_SNR': min_SNR,
                'rval_thr': rval_thr,
                'rval_lowest': rval_lowest,
                'use_cnn': use_cnn,
                'min_cnn_thr': min_cnn_thr,
                'cnn_lowest': cnn_lowest,
                'ITER': ITER,
                'fudge_factor': fudge_factor,
                'cnn_lowest': cnn_lowest,
                'update_background_components': update_background_components,
                'low_rank_background' : low_rank_background,
                'thr_method': thr_method,
                'maxthr': maxthr,
                'nrgthr': nrgthr,
                'fnames': fnames,
                #'medw': medw,
                'extract_cc': extract_cc}


    # # for reference here are the initialization defs for 3 methods, sparse_nmf apparently "has problems" according to gitter

    # # greedyROI(Y, nr=30, gSig=[5, 5], gSiz=[11, 11], nIter=5, kernel=None, nb=1,
    #           rolling_sum=False, rolling_length=100, seed_method='auto')

    # for graphnmf all these are tunable in cnmf params except remove_baseline, truncate, tol, and SC_kernel whose defaults are below
    # note SC_kernel appears to be tunable because it's in params but it is not, heat is default
    # # graphNMF(Y_ds, nr, max_iter_snmf=500, lambda_gnmf=1,
    #          sigma_smooth=(.5, .5, .5), remove_baseline=True,
    #          perc_baseline=20, nb=1, truncate=2, tol=1e-3, SC_kernel='heat',
    #          SC_normalize=True, SC_thr=0, SC_sigma=1, SC_use_NN=False,
    #          SC_nnn=20

    # for sparsenmf all these are tunable in cnmf params except remove_baseline and truncate, whose defaults are below
    # # sparseNMF(Y_ds, nr, max_iter_snmf=500, alpha=10e2, sigma_smooth=(.5, .5, .5),
    #           remove_baseline=True, perc_baseline=20, nb=1, truncate=2)


    return opts_dict, indices_ex, fnadd


