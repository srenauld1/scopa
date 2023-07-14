import numpy as np

def configs():

    only_init = False

    sly = slice(0, 51, 1)
    slx = slice(40, 181, 1) 
    slz = slice(0, 70, 1)
    indices_ex = [slx, sly, slz]
    #indices_ex = [slice(None), slice(None), slice(None)]

    p = 0                   # order of the autoregressive system - 0 from carl's code
    merge_thresh = 0.9
    gSig = [3, 3, 3]  # gSig = [3,3]            # radius (half-size) of average neurons (in pixels)
    nb = 2                  # temporal global background components - TUNE

    do_patches = False      # flag for processing in patches or not - turn on or off - Not used in Matlab
    if do_patches:          # PROCESS IN PATCHES AND THEN COMBINE
        rf = 60             # half size of each patch
        stride_cnmf = 40          # overlap between patches
        p_patch = p
        nb_patch = nb
        k = 3              # number of components in each patch
        indices_ex = [slice(None), slice(None), slice(None)]
    else:                   # PROCESS THE WHOLE FOV AT ONCE
        rf = None           # setting these parameters to None
        stride_cnmf = None       # will run CNMF on the whole FOV
        p_patch = p
        nb_patch = nb
        k = 40              # number of neurons expected (in the whole FOV) - 40 from Carl's Code, seems to be too many

    ###
    fr = 5.08 #0.6193  #9.8465 frame period so 1000 / (9.8465 *(113+51)) # approximate frame rate of data - CONFIRMED FPS
    decay_time = .4         # length of transient - CONFIRMED APPROPRIATE FOR OUR INDICATOR GCaMP6f
    dxy = [1.33155792277, 1.33155792277, 0.16666666666666666] #for .751 um pixels # pixels per micron 

    tsub = 1                # temporal downsampling
    ssub = 1               # spatial downsampling

    method_init = 'greedy_roi' #'graph_nmf' #'greedy_roi' #python Caiman defaults to greedy_roi, carl's code uses sparse_nmf, but sparse_nmf runs MUCH slower
    sigma_smooth_snmf = (0.5, 0.5, 0.5)
    perc_baseline_snmf = 50

    se = np.ones((3,)*len(gSig), dtype=np.uint8)  #se = np.ones((3,3,1), dtype=np.uint8)
    update_background_components = True   #use this??

    fudge_factor = 0.96        # (default is 0.96; Carl's value = 1) -- bias correction factor for discrete time constants
    ITER = 5                # (default is 2; Carl's value=5) -- block coordinate descent iterations
    bas_nonneg = False #True

    rolling_sum = True

    min_SNR = 0  #2    # accept components with that peak-SNR or higher (if above this, acept)
    SNR_lowest = 0         # minimum SNR for accepted components (if below this, reject)
    rval_thr = 0  # 0.85  # space correlation threshold (if above this, accept)
    rval_lowest = 0  # 0.6  # space correlation threshold (if above this, accept)
    use_cnn = False      # use the CNN classifier affects if 2 below params are used
    min_cnn_thr = 0 #0.99 # if cnn classifier predicts below this value, reject
    cnn_lowest = 0  #0.1  # neurons with cnn probability lower than this value are rejected

    strides_mc = (24, 24, 6)
    overlaps_mc = (12, 12, 3)
    max_shifts_mc = (4, 4, 2)
    max_deviation_rigid = 3
    pw_rigid = False
    is3D_mc = True
    indices_mc = (slice(None), slice(None), slice(None)) #if is3d is true for motion correction, will overwrite with nones and will lose indices_ex

    opts_dict = {'strides': strides_mc,    # start a new patch for pw-rigid motion correction every x pixels
                'overlaps': overlaps_mc,   # overlap between pathes (size of patch strides+overlaps)
                'max_shifts': max_shifts_mc,   # maximum allowed rigid shifts (in pixels)
                'max_deviation_rigid': max_deviation_rigid,  # maximum shifts deviation allowed for patch with respect to rigid shifts
                'pw_rigid': pw_rigid,         # flag for performing non-rigid motion correction
                'is3D': is3D_mc,
                'fr': fr,
                'p': p,
                'nb': nb,
                'merge_thr': merge_thresh,
                'rf': rf,
                'indices': indices_mc,  #for some reason indices_mc is causing error, maybe needs list for mc and tuple for extraction?
                'K': k, 
                'gSig': gSig,
                'stride': stride_cnmf,
                'method_init': method_init,
                'sigma_smooth_snmf': sigma_smooth_snmf,
                'perc_baseline_snmf': perc_baseline_snmf,
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
                'update_background_components': update_background_components}

    return opts_dict, indices_ex
