

import numpy as np
from map2params import map2params

def optex(index_extraction_param_set = 'default', fnames = None, md = None, extract_in_2d = None, dims_spatial_ex = 0, two_channel_ex = 0):

    # THE MOST IMPORTANT OPTIONS ARE UNDER HEADINGS "GENERAL" AND "INITIALIZATION"
    # consider further adjustments if you cannot get good results with any adjustment in those sections

    # below are many of the options for caiman source extraction with cnmf
    # these are chosen as the most likely to require tuning
    # the options in map2params are the most likely to require tuning
    # md['dims'] is dims of original fov, dims_spatial_ex is dims of extraction fov (which may be cropped, so not necessarily the same as md['dims'])
    # opts_dict has params that are passed to cnmf.params.CNMFParams to create the caiman params object 
    # opts_dict_morph has params that are not passed to cnmf.params.CNMFParams to create the caiman params object, but which may still be used in caiman functions


    ############ GENERAL (USED IN FUNCTION CNMF, OR IN MULTIPLE FUNCTIONS WITHIN CNMF) ############

    gSig = [2, 2, 1] # approximate xyz radius (half-size), in pixels, of average neurons; z ignored if extract_in_2d; later, forced to be odd when creating gsiz, so min gsiz is 3; any number 0-1 has same effect as 1; also, consider that our z are often much larger than xy when you set this, so if neurons are restricted to single z planes, make this 1 (since gsig unit is pixels)      
    method_init = 'graph_nmf' #'greedy_roi' #'graph_nmf' #sparse_nmf 'greedy_roi' python Caiman defaults to greedy_roi, looks for globular sources 
    nb = 1 #nb is used everywhere; num background components
    update_background_components = False #spatial; update background components during spatial phase
    low_rank_background = True #spatial, and patch; and  #true makes bankground nb, false makes it update with hals, if true with patches, each patch keeps its background, if false, each patch bg approximated with global background
    merge_thresh = 0.85 #threshold for merging components (merge_components in merging.py)
    normalize_init = True # init; variance norm by pixel over time befroe initialization;  prob should always be true except for 1p data; patches take care of this to some extent but why not just do it always;

    only_init = False #only use the initialization for extraction (no updating of spatial and or temporal components, ie no alternating least squares for spatial and temporal refinement)
    if two_channel_ex:
        only_init = False

    roidensity = 0.4  #used to derive k (approximate number of neurons to find), given other options, gSig, and patch or fov size; keep above 0 and less than or equal to 1; 1 is "space filling" (as many neurons as possible given patch or fov size, reoslution, and gsiz); caiman demo does not use this variable, but effectively their demo sets it at 0.33)
    p = 1 #for deconvolution model if 1 or 2, or skipping deconvolution if 0 (skip deconvolution if neuron is nonspiking); order of the autoregressive system - 0 for nonspiking, 1 for instanteous rise but not decay, 2 for non-ionstantaneous rise and decay


    ############ INITIALIZATION ############

    #the set of initialization options that get used depends on how you set method_init above

    # for method_init sparse_nmf and graph_nmf
    sigma_smooth_snmf_z = 0.5 #can be less than 1 and have effect, unlike gsig, make small if z are larger than neuron extent in z
    sigma_smooth_snmf_t = 0.5 #smoothing in time before sparsenmf init
    sigma_smooth_snmf = [sigma_smooth_snmf_t, gSig[0], gSig[1], sigma_smooth_snmf_z] #smoothing std prior to initialization in sparse_nmf method, default 0.5 0.5 0.5
    perc_baseline_snmf = 20 # default 20
    max_iter_snmf = 500  #default 200 sparsenmf, 500 graphnmf

    # for method_init sparse_nmf only
    alpha_snmf = 0.5 #default 0.5 sparsity penalty, 

    # for method_init graph_nmf only
    lambda_gnmf = 1 #default 1; sparsity penalty for method_init graphNMF
    SC_sigma = 1 # default 1; std for SC kernel
    SC_thr = 0    # default 0; threshold for affinity matrix
    SC_normalize = True  # default True; standardize entries prior to computing affinity matrix
    SC_use_NN = False  # default False; sparsify affinity matrix by using only nearest neighbors
    SC_nnn = 20   # default 20; number of nearest neighbors to use if SC_use_NN = True

    # for method_init greedy_roi only   
    rolling_sum = False #default false Using rolling sum for initialization (RollingGreedyROI), instead of total sum
    rolling_length = 100 #default 100


    ############ UPDATE TEMPORAL AND DECONVOLUTION ############

    #p belongs in this section, but because it is so important, it was moved above under section "general" 
    p_patch = p #patch p should match p; why would it ever not?
    ITER = 3                # (default is 2; old value=5) -- block coordinate descent iterations
    bas_nonneg = False #clip negatives in deconvolution (not the same as clipping negatives in stack); appears to not matter unless you're deconvolving (p is 1 or 2, not 0)
    fudge_factor = 0.96        # (default is 0.96; old value = 1) -- bias correction factor for discrete time constants


    ############ UPDATE SPATIAL (esp. threshold_components ############

    #during refinement, in update_spatial, the following params are used in function threshold_components
    thr_method = 'nrg' #or 'max'
    maxthr = 0.1 #for  thr_method = 'max' keep pixels above this threshold
    nrgthr = 0.9999 #for  thr_method = 'nrg' keep pixels whose sorted cumsum contributes this much of total energy
    extract_cc = True #true will throw away isolated pixels of some kind (cc means connected components)
    se = np.ones((3,)*len(gSig), dtype=np.uint8)  #structuring element; put here at end to register any gSig change #se = np.ones((3,3,1), dtype=np.uint8)
    medw = (3,)*len(gSig)


    ############ PATCHES ############

    #low_rank_background also has meaning for patches in run_CNMF_patches, see notes for low_rank_background above
    nb_patch = nb #should patch nb match nb? doens't seem like it has to
    patchfac = 4 #how many times larger largest dim of patch is than lagest dim of neuron diameter (ie largest dim of gsiz, since neuron diameter is approximately gsiz); 0 to skip patches, or make it large to do one patch on the full fov (saqme as 0); caiman recommends 3-4 (if not 0);automatically skipped if two_channel_ex (seeded extraction); if fov is smaller than patch, it's just one patch; patches are useful if activity stats vary over fov (e.g. extracting same neurons from regions with varying SNR, patch runs will adapt to local stats)
    stridefac = 2 #how many times larger largest dim of stride is than lagest dim of neuron diameter (ie largest dim of gsiz, since neuron diameter is approximately gsiz); 0 to skip patches; caiman recommends at least 1 (at least neuron dia) (if not 0);automatically skipped if two_channel_ex (seeded extraction); if fov is smaller than patch, it's just one patch; patches are useful if activity stats vary over fov (e.g. extracting same neurons from regions with varying SNR, patch runs will adapt to local stats)
    

    ############ QUALITY EVALUATION ############

    # Each parameter has a low threshold (rval_lowest (default -1), SNR_lowest (default 0.5), cnn_lowest (default 0.1))
    # and high threshold (rval_thr (default 0.8), min_SNR (default 2.5), min_cnn_thr (default 0.9)).
    # A component has to exceed ALL low thresholds as well as ONE high threshold to be accepted.
    # can turn off CNN part withy use_CNN = false
    # these values will result in no roi filtering
    decay_time = .2  # i can only find this used in components evaluation (and onacid), approximate length of indicator tau off
    SNR_lowest = 0 #0.5#0  #0.5 default       # minimum SNR for accepted components
    min_SNR = 0 #0  #2.5 default    # accept components with that peak-SNR or higher
    rval_lowest = -1  # -1 default 0.6  # space correlation threshold
    rval_thr = 0 #0  # 0.8 default  # space correlation threshold
    use_cnn = False # True default # use the CNN classifier affects if 2 below params are used
    cnn_lowest = 0  #0.1 default  # neurons with cnn probability lower than this value are rejected
    min_cnn_thr = 0 #0.9 default # if cnn classifier predicts below this value, reject

    
    ############ MORPHOLOGICAL SEGEMENTATION OPTIONS (FOR STRUCTURAL CHANNEL, USED TO SEED FUNCTIONAL CHANNEL) ############

    morph_se = se #structuring element; only used for cm.base.rois.extract_binary_masks_from_structural_channel, which is only used in two_channel_ex when automated structural rois seed the other channel
    morph_areamin = 2 #min area (in pixels); only used for cm.base.rois.extract_binary_masks_from_structural_channel, which is only used in two_channel_ex when automated structural rois seed the other channel
    morph_holemin = 0 #holes with smaller area (in pixels) will be filled in; only used for cm.base.rois.extract_binary_masks_from_structural_channel, which is only used in two_channel_ex when automated structural rois seed the other channel
    morph_expandmthd = 'closing' #closing or dilation; only used for cm.base.rois.extract_binary_masks_from_structural_channel, which is only used in two_channel_ex when automated structural rois seed the other channel
    morph_gsig = int(np.mean(gSig)) #must be odd and greater than 1; only used for cm.base.rois.extract_binary_masks_from_structural_channel, which is only used in two_channel_ex when automated structural rois seed the other channel
    if morph_gsig<3:
        morph_gsig = 3
    if not morph_gsig%2==1:
        morph_gsig = morph_gsig+1


    ############ DOWNSAMPLING ############

    tsub = 1  # temporal downsampling
    ssub = 1  # spatial downsampling
    p_ssub = 1 #patch downsampling in space
    p_tsub = 1 #patch downsampling in time


    ############ DERIVE k, gSiz, AND PATCH PARAMS rf and stride  ############
    

    gSiz = [int(np.round(2*gstmp + 1)) for gstmp in gSig] #half-size of bounding box for each neuron; this is what caiman does to compute gsiz from gsig, just putting it here for transparency
    if not two_channel_ex: #patches turned off when seeding functional rois with automatically segmented structural channel rois; PROCESS IN PATCHES AND THEN COMBINE, patches are useful if activity stats vary over fov (e.g. extracting same neurons from regions with varying SNR, patch runs will adapt to local stats)

        if extract_in_2d==True:
            maxgsiz = np.max(gSiz[0:2])
        else:
            maxgsiz = np.max(gSiz)

        rf = int(np.ceil((maxgsiz) * patchfac))
        patchFW = rf*2 #patch full width, since rf is half
        stride_patch = int(np.ceil((maxgsiz) * stridefac))

        skippatch = 0
        if extract_in_2d==True:
            k = int(np.round( (patchFW*patchFW) / np.prod(gSiz[0:2])*roidensity))  # number of components in each patch
            if patchFW>=dims_spatial_ex[0] and patchFW>=dims_spatial_ex[1]:
                skippatch = 1
        else:
            if patchFW<dims_spatial_ex[2]:
                rfz = patchFW
            else:
                rfz = dims_spatial_ex[2]
            if patchFW>=dims_spatial_ex[0] and patchFW>=dims_spatial_ex[1] and rfz>=dims_spatial_ex[2]:
                skippatch = 1
            k = int(np.round( (patchFW*patchFW*rfz) / np.prod(gSiz)*roidensity))  # number of components in each patch
        
        if skippatch: #reset if it turns out the patch is same size as fov or bigger
            rf = None # setting rf to none will run CNMF on the whole FOV
            stride_patch = None       
            k = int(np.round( np.prod(dims_spatial_ex) / np.prod(gSiz)*roidensity))  # number of components in whole fov (the "whole fov patch")
    
    else: # PROCESS THE WHOLE FOV AT ONCE (no patches)
        rf = None # setting rf to none will run CNMF on the whole FOV
        stride_patch = None       
        k = int(np.round( np.prod(dims_spatial_ex) / np.prod(gSiz)*roidensity))  # number of components in whole fov (the "whole fov patch")

    if method_init=='corr_pnr':
        k = None #override k above if using corr_pnr (if in cnmfe mode, ie 1p mode)


    ############ DERIVED DATA PARAMS ############

    fr = md['volrate'] #0.6193  #9.8465 frame period so 1000 / (9.8465 *(113+51)) # approximate frame rate of data - CONFIRMED FPS
    if md['zfov']==0: #md['zfov']==0 when stack is xyt (not volumetric xyzt); below, the third element (hard coded 0.0) will be removed
        dxy = [md['xpix']/md['xfov'], md['ypix']/md['yfov'], 0.0 ] #pixels per micron
    else:
        dxy = [md['xpix']/md['xfov'], md['ypix']/md['yfov'], md['numslice']/md['zfov']] #pixels per micron

    
    ############ INDICES TO SUBSET STACK (DON'T USE IN SCOPA) ############
    
    indices_ex = [slice(None), slice(None), slice(None)] # xyz indices to subset FOV; but scopa's regionex (id to crop_fov) is meant to replace this, so this ca remain none

    ############ CORRECT FOR 2D ############

    if extract_in_2d==True: #change a few options from 3d to 2d (remove 3rd element)
        indices_ex = indices_ex[:-1] 
        dxy = dxy[:-1] 
        gSig = gSig[:-1] 
        gSiz = gSiz[:-1] 
        se = se[:,:,0]
        medw = medw[:-1] 
        sigma_smooth_snmf = sigma_smooth_snmf[:-1]
        morph_se = morph_se[:,:,0]

    ############ CHECK OPTIONS ############

    if patchfac<3 or stridefac<1.5:
        raise Exception("patchfac should be at least 3, and stridefac should be at least 1.5, according to caiman recommendations")
    if False in [tmp==slice(None) for tmp in indices_ex]:
        raise Exception("all indices_ex must be None in scopa because regionex replaces this functionality (basically)")
    
    if method_init=='corr_pnr': #for 1p data, according to caiman . . . so does this mean lots of background activity?? 
        raise Exception("method_init 'corr_pnr' is for 1p data (data with busy background, aka high rank background); if you want to use it anyway, see required options changes below")
            #these changes are required for method_init=='corr_pnr':
                # nb = 0 ##nb is used everywhere; num background components
                # only_init = True #only use the initialization for extraction (no alternating least squares for spatial and temporal refinement)
                # low_rank_background = None ##spatial, and patch; #true makes bankground nb, false makes it update with hals, if true with patches, each patch keeps its background, if false, each patch bg approximated with global background
                # center_psf = True  #initialization; True indicates centering the filtering kernel for background removal. This is useful for data with large background fluctuations.
                # normalize_init = False #init; variance norm by pixel over time befroe initialization; prob should always be true except for 1p data; patches take care of this to some extent but why not just do it always; 

    ############ ASSEMBLE OPTIONS DICTIONARIES ############

    opts_dict = {
                'fr': fr,
                'p': p,
                'nb': nb,
                'merge_thr': merge_thresh,
                'rf': rf,
                'K': k,
                'gSig': gSig,
                'gSiz': gSiz,
                'stride': stride_patch,
                'method_init': method_init,
                'perc_baseline_snmf': perc_baseline_snmf,
                'max_iter_snmf': max_iter_snmf,
                'sigma_smooth_snmf': sigma_smooth_snmf,
                'SC_sigma': SC_sigma,            # std for SC kernel
                'SC_thr': SC_thr,                 # threshold for affinity matrix
                'SC_normalize': SC_normalize,        # standardize entries prior to computing affinity matrix
                'SC_use_NN': SC_use_NN,          # sparsify affinity matrix by using only nearest neighbors
                'SC_nnn': SC_nnn,                # number of nearest neighbors to use if SC_use_NN = True
                'lambda_gnmf': lambda_gnmf, #for method_init graphNMF
                'alpha_snmf': alpha_snmf, #for method_init sparseNMF
                'dxy': dxy,
                'decay_time': decay_time,
                'bas_nonneg': bas_nonneg,
                'p_patch': p_patch,
                'nb_patch': nb_patch,
                'se': se,
                'rolling_sum': rolling_sum,
                'rolling_length': rolling_length,
                'only_init': only_init,
                'normalize_init': normalize_init,
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
                'update_background_components': update_background_components,
                'low_rank_background' : low_rank_background,
                'thr_method': thr_method,
                'maxthr': maxthr,
                'nrgthr': nrgthr,
                'medw': medw,
                'extract_cc': extract_cc,
                'fnames': fnames
                } 

    opts_dict_morph = {
                'morph_se': morph_se, 
                'morph_areamin': morph_areamin, 
                'morph_holemin': morph_holemin, 
                'morph_gsig': morph_gsig, 
                'morph_expandmthd': morph_expandmthd 
                }


    ############ NOTES ON INITIALIZATION METHODS ############

    # for reference here are the initialization defs for 3 methods, 
    # sparse_nmf "has problems" according to gitter, although it's worked for carl

    # greedyROI(stack, nr=30, gSig=[5, 5], gSiz=[11, 11], nIter=5, kernel=None, nb=1,
    #           rolling_sum=False, rolling_length=100, seed_method='auto')

    # for graphnmf all these are tunable in cnmf params except remove_baseline, truncate, tol, and SC_kernel whose defaults are below
    # note SC_kernel appears to be tunable because it's in params but it is not, heat is default
    # # graphNMF(Y_ds, nr, max_iter_snmf=500, lambda_gnmf=1,
    #          sigma_smooth=(.5, .5, .5), remove_baseline=True,
    #          perc_baseline=20, nb=1, truncate=2, tol=1e-3, SC_kernel='heat',
    #          SC_normalize=True, SC_thr=0, SC_sigma=1, SC_use_NN=False,
    #          SC_nnn=20

    # for sparsenmf all these are tunable in cnmf params except remove_baseline and truncate, whose defaults are below
    # # sparseNMF(Y_ds, nr, max_iter_snmf=200, alpha=0.5, sigma_smooth=(.5, .5, .5),
    #          remove_baseline=True, perc_baseline=20, nb=1, truncate=2):


    return opts_dict, opts_dict_morph, indices_ex


