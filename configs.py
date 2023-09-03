

import numpy as np
from map2params import map2params

##########################################################################################################################################

# configs for caiman motion correction and source extraction
# this is not comprehensive, but should be the most likely params to require tuning 
# below is more comprehensive for extraction than motion correction 

##########################################################################################################################################

def configs(index_extraction_param_set = None, fnames = None, min_mov = 0, do_planar_extraction = None, dims_spatial = (1,1,1)):
    

    #motion correction configs 
    strides_mc = (24, 24, 6)
    overlaps_mc = (12, 12, 3)
    max_shifts_mc = (4, 4, 2)
    max_deviation_rigid = 3
    pw_rigid = False
    is3D_mc = True
    nonneg_movie = True
    min_mov = min_mov
    shifts_opencv = True 
    indices_mc = (slice(None), slice(None), slice(None)) #if is3d is true for motion correction, will overwrite with nones and will lose indices_ex

    do_slices = False #my crop_fov is meant to replace this, so should always be false 
    if do_slices:
        sly = slice(6, 51, 1)
        slx = slice(40, 181, 1) 
        slz = slice(1, 9, 1) 
        indices_ex = [slx, sly, slz]
    else:
        indices_ex = [slice(None), slice(None), slice(None)]
        
    
    only_init = False #only use the initialization run for extraction 

    p = 0                   # order of the autoregressive system - 0 for nonspiking, 1 for instanteous rise but not decay, 2 for non-ionstantaneous rise and decay 
    merge_thresh = 0.9
    gSig = [2, 2, 1] #forces to be odd so gsiz min is 3 (ie gsig 0.5 is same as 1)  # gSig = [3,3]            # radius (half-size) of average neurons (in pixels)
    nb = 1 #num background components 

    fr = 5.08 #0.6193  #9.8465 frame period so 1000 / (9.8465 *(113+51)) # approximate frame rate of data - CONFIRMED FPS
    decay_time = .4         # length of transient - CONFIRMED APPROPRIATE FOR OUR INDICATOR GCaMP6f
    dxy = [1.33155792277, 1.33155792277, 0.16666666666666666] #for .751 um pixels # pixels per micron 

    tsub = 1                # temporal downsampling
    ssub = 1               # spatial downsampling
    p_ssub = 1 #patch downsampling in space 
    p_tsub = 1 #patch downsampling in time
    
    thr_method = 'nrg' #or 'max'
    maxthr = 0.1 #for  thr_method = 'max' keep pixels above this threshold
    nrgthr = 0.9999 #for  thr_method = 'nrg' keep pixels whose sorted cumsum contributes this much of total energy 
    extract_cc = True #true will throw away isolated pixels of some kind 
    
    method_init = 'graph_nmf' #'greedy_roi' #'graph_nmf' #sparse_NMF apparently has problems?? 'greedy_roi' python Caiman defaults to greedy_roi, looks for globular sources  

    max_iter_snmf = 1000
    perc_baseline_snmf = 20
    alpha_snmf = 100 #default 1000 #for method_init sparseNMF    
    #sigma_smooth_snmf = gSig #(2, 2, 0.5) #default 0.5 0.5 0.5

    lambda_gnmf = 1 #for method_init graphNMF
    SC_kernel = 'heat' #NOT TUNABLE NOW       # kernel for graph affinity matrix
    SC_sigma = 1              # std for SC kernel
    SC_thr = 0                 # threshold for affinity matrix
    SC_normalize = True        # standardize entries prior to computing affinity matrix
    SC_use_NN = False          # sparsify affinity matrix by using only nearest neighbors
    SC_nnn = 20                # number of nearest neighbors to use if SC_use_NN = True


    low_rank_background = True #true makes bankground nb, false makes it update with hals
    update_background_components = True   #use this??

    fudge_factor = 0.96        # (default is 0.96; old value = 1) -- bias correction factor for discrete time constants
    ITER = 5                # (default is 2; old value=5) -- block coordinate descent iterations
    bas_nonneg = False #True

    rolling_sum = True

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

    stride_to_rf_ratio = 0.65

    if index_extraction_param_set is not None: #create param set whose index matches value in index_extraction_param_set
        map_index_2_params = map2params()
        index_extraction_param_set = int(index_extraction_param_set)
        print('reading parameters from the index_extraction_param_set file')
        merge_thresh, m2p_gsig, nb, SC_sigma, lambda_gnmf, perc_baseline_snmf, max_iter_snmf = map_index_2_params.map_index(index_extraction_param_set)
        gSig = [m2p_gsig, m2p_gsig, 1]  #gSiz (made from gsig) will be 2 for 0.5 or 1, so don't bother with 0.5

    if dims_spatial[0]<50 and dims_spatial[1]<50 and dims_spatial[2]<50: #dont bother with patches if FOV is small enough (but this should be adjusted for dirtier drivers)
        do_patches = False
    else:
        do_patches = True

    #determine k in automated way based on gSig, roi_decimation_fac, and stride_to_rf_ratio, while also satisfying caiman patch size recommendations
    roi_decimation_fac = 0.4 
    if do_patches: # PROCESS IN PATCHES AND THEN COMBINE, patches are useful if activity stats vary over fov (e.g. extracting same neurons from regions with varying SNR, patch runs will adapt to local stats)
        rf = int(np.ceil((np.max(gSig)*2+1) / stride_to_rf_ratio)) + 1
        stride_cnmf = int(np.round(rf * stride_to_rf_ratio))         # overlap between patches
        p_patch = p
        nb_patch = nb
        if do_planar_extraction==True:
            k = int(np.round( (rf*2*rf*2) / ((gSig[0]*2+1)*(gSig[1]*2+1))*roi_decimation_fac))  # number of components in each patch, rf and gsig are both half sizes
            #k = int(np.round(rf*rf / (gSig[0]*gSig[1])))
        else:
            if rf*2<dims_spatial[-1]:
                rfz = rf*2
            else:
                rfz = dims_spatial[-1]
            k = int(np.round( (rf*2*rf*2*rfz) / ((gSig[0]*2+1)*(gSig[1]*2+1)*(gSig[2]*2+1))*roi_decimation_fac))  # number of components in each patch, rf and gsig are both half sizes
        indices_ex = [slice(None), slice(None), slice(None)]
    else:                   # PROCESS THE WHOLE FOV AT ONCE
        rf = None # will run CNMF on the whole FOV
        stride_cnmf = None       # will run CNMF on the whole FOV
        p_patch = p
        nb_patch = nb
        k = int(np.round( np.prod(dims_spatial) / ((gSig[0]*2+1)*(gSig[1]*2+1)*(gSig[2]*2+1))*roi_decimation_fac))  # number of components in each patch, rf and gsig are both half sizes

    dimstr = "3dex_"
    if do_planar_extraction==True:        
        dimstr = '2dex_'
        indices_ex = indices_ex[:-1] #change from 3d to 2d 
        dxy = dxy[:-1] #change from 3d to 2d 
        gSig = gSig[:-1] #change from 3d to 2d 
    
    gSiz = [int(np.round(2*gstmp + 1)) for gstmp in gSig] #put here at end to register any gSig change
    se = np.ones((3,)*len(gSig), dtype=np.uint8)  #put here at end to register any gSig change #se = np.ones((3,3,1), dtype=np.uint8)
    #medw = (3,)*len(gSig)

    sigma_smooth_snmf = [0.5] #append this filter sigma for time to beginning (when it is applied time is in 1st dim?)
    sigma_smooth_snmf.extend(gSig)
    if do_planar_extraction==False:
        sigma_smooth_snmf[-1] = 0.5 #sigma_smooth_snmf can actually use values<1, if 3d extraction, make small for coarse z samples

    fnadd = '_' + str(gSig[0]) + '_' + str(nb) + '_' + str(merge_thresh) + '_' + str(k) + \
        '_' + str(rf) + '_' + str(SC_sigma) + '_' + str(lambda_gnmf) + '_' + str(perc_baseline_snmf) \
            + '_' + str(max_iter_snmf) + '_' + method_init.split('_')[0] + '_' + dimstr

    if do_planar_extraction is None: #it's none during motion correction, when we don't care about these params, rather than true/false
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
                'sigma_smooth_snmf': sigma_smooth_snmf,
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
