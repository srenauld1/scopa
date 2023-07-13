

def cnmf_2d(path_to_stack, opts):
  
  import warnings
  warnings.simplefilter(action='ignore', category=FutureWarning)

  fnames = [path_to_stack]
  opts.set('data', {'fnames': fnames})

  #cluster handling
  if 'dview' in locals():
    cm.stop_server(dview=dview)
  dview = cm.cluster.start_server(ncpus=2) #Start a cluster with 2 CPU's (available in colab)


  #%% MEMORY MAPPING
  # memory map the file in order 'C'
  fname_new = cm.save_memmap(fnames, base_name='memmap_', order='C', dview=dview)
  print(fname_new)

  # now load the file
  Yr, dims, T = cm.load_memmap(fname_new)
  images = np.reshape(Yr.T, [T] + list(dims), order='F')
  print(type(images))
  print(images.shape)

      #load frames in python format (T x X x Y)

  #Initialize a new cnmf object and pass in our masks as the "Ain" param
  #"Ain" is A-in, meaning the A matrix holding the spatial footprints of the roi's
  print('initializing cnmf object')
  cnm_seeded = cnmf.CNMF(n_processes = 2, params=opts, dview=dview, Ain=mask_A)
  print('cnmf object initialized')
  print('starting seeded cnmf')
  cnm_seeded.fit(images)
  print('seeded cnmf completed')
  print('starting component evaluation')
  cnm_seeded.estimates.evaluate_components(images, opts, dview=dview)
  print('component evaluation completed')
  print('detrending and normalizing temporal traces')
  cnm_seeded.estimates.detrend_df_f(detrend_only=False, flag_auto=False, quantileMin = 28, frames_window = 500)
  print('detrending and normalizing complete')

  cm.stop_server(dview=dview)

  print(path_to_stack[:(len(path_to_stack)-4)].split('/')[4])

  #return the cnm object and a dictionary of results
  return cnm_seeded, {'stack_name': path_to_stack[:(len(path_to_stack)-4)].split('/')[4], #chops the movie identifier out of the filepath
                        'spatial': np.transpose(cnm_seeded.estimates.A.A, axes = (1,0)), #de-sparsified (.A) and transposed to put the axes in roi x pixel order
                        'temporal': cnm_seeded.estimates.F_dff}





# sly = slice(0, 51, 1)
# slx = slice(40, 181, 1) 
# slz = slice(0, 70, 1)
# indices = [slx, sly, slz]
# #indices = [slice(None), slice(None), slice(None)]

# p = 0                   # order of the autoregressive system - 0 from carl's code
# merge_thresh = 0.95
# gSig = [2,2,2]  # gSig = [3,3]            # radius (half-size) of average neurons (in pixels)
# nb = 5                  # temporal global background components - TUNE

# do_patches = False      # flag for processing in patches or not - turn on or off - Not used in Matlab
# if do_patches:          # PROCESS IN PATCHES AND THEN COMBINE
#     rf = 20             # half size of each patch
#     stride = 12          # overlap between patches
#     p_patch = p
#     nb_patch = nb
#     k = 7              # number of components in each patch
#     indices = [slice(None), slice(None), slice(None)]
# else:                   # PROCESS THE WHOLE FOV AT ONCE
#     rf = None           # setting these parameters to None
#     stride = None       # will run CNMF on the whole FOV
#     p_patch = p
#     nb_patch = nb
#     k = 400              # number of neurons expected (in the whole FOV) - 40 from Carl's Code, seems to be too many

# ###
# dims = [256, 140, 113]  #9.8465 frame period so 1000 / (9.8465 *(113+51)) # approximate frame rate of data - CONFIRMED FPS
# fr = 0.6193  #9.8465 frame period so 1000 / (9.8465 *(113+51)) # approximate frame rate of data - CONFIRMED FPS
# decay_time = .4         # length of transient - CONFIRMED APPROPRIATE FOR OUR INDICATOR GCaMP6f
# dxy = [1.33155792277, 1.33155792277, 1.33155792277] #for .751 um pixels # pixels per micron 

# tsub = 1                # temporal downsampling
# ssub = 1               # spatial downsampling

# method_init = 'greedy_roi' #'graph_nmf' #'greedy_roi' #python Caiman defaults to greedy_roi, carl's code uses sparse_nmf, but sparse_nmf runs MUCH slower
# sigma_smooth_snmf = (0.5, 0.5, 0.5)
# perc_baseline_snmf = 50

# se = np.ones((3,)*len(dims), dtype=np.uint8)  #se = np.ones((3,3,1), dtype=np.uint8)
# update_background_components = True   #use this??

# fudge_factor = 0.96        # (default is 0.96; Carl's value = 1) -- bias correction factor for discrete time constants
# ITER = 5                # (default is 2; Carl's value=5) -- block coordinate descent iterations
# bas_nonneg = False #True

# min_SNR = 0      # accept components with that peak-SNR or higher (if above this, acept)
# SNR_lowest = 0         # minimum SNR for accepted components (if below this, reject)
# rval_lowest = 0  # 0.6  # space correlation threshold (if above this, accept)
# rval_thr = 0  # 0.6  # space correlation threshold (if above this, accept)
# use_cnn = False      # use the CNN classifier affects if 2 below params are used
# min_cnn_thr = 0  # if cnn classifier predicts below this value, reject
# cnn_lowest = 0.1   # neurons with cnn probability lower than this value are rejected

# cnm = cnmf.CNMF(n_processes, dview=dview, gSig=gSig)


# cnm.params.set('data', {
#                    #'fnames': fname,
#                    'fr': fr,
#                    'decay_time': decay_time,
#                    'dxy': dxy, 
#                    'dims': dims,
#                             })

# cnm.params.set('data', {
#                    #'fnames': fname,
#                    'fr': fr,
#                    'decay_time': decay_time,
#                    'dxy': dxy, 
#                    'dims': dims,
#                             })

# cnm.params.set('patch', {
#                     'rf': rf,
#                     'stride': stride,
#                     'p_patch': p_patch,
#                     'nb_patch': nb_patch,
#                      #'n_processes': n_processes,
#                             })

# cnm.params.set('preprocess', {
#                     'p': p
#                             })

# cnm.params.set('init', {
#                     'K': k,     #little K here in 'init', big K if passed to CNMF class        # declared above in patch params
#                     #'gSig': gSig, #for some reason have to pass this to cnmf
#                     'tsub': tsub,
#                     'ssub': ssub,
#                     'gSig': gSig,
#                     'nb': nb, #decleared in temporal
#                     'method_init': method_init,
#                     'sigma_smooth_snmf': sigma_smooth_snmf,
#                     'perc_baseline_snmf': perc_baseline_snmf
#                             })

# cnm.params.set('spatial', {
#                     'nb': nb,  #can i make this diff from temporal? 
#                     'se': se, 
#                             })

# cnm.params.set('temporal', {
#                     'p': p,
#                     'fudge_factor': fudge_factor,
#                     'ITER': ITER,
#                     'nb': nb,  #can i make this diff from spatial? 
#                     'bas_nonneg': bas_nonneg,
#                             })

# cnm.params.set('merging', {
#                     'merge_thr': merge_thresh #if you're passing to subdict 'merging' keyword is merge_thr, if passing to CNMF params class it's merge_thresh
#                             })

# cnm.params.set('quality', {
#                     'min_SNR': min_SNR,
#                     'SNR_lowest': SNR_lowest,
#                     'rval_lowest': rval_lowest,
#                     'rval_thr': rval_thr,
#                     'use_cnn': use_cnn,
#                     'min_cnn_thr': min_cnn_thr,
#                     'cnn_lowest': cnn_lowest
#                             })



