# THE MOST IMPORTANT OPTIONS ARE IN map2opt.py (WHICH ARE ALL UNDER HEADINGS "GENERAL" AND "INITIALIZATION" BELOW)
# consider further adjustments if you cannot get good results with any adjustment in those sections

# below are most of the options for caiman source extraction with cnmf
# these are chosen as the most likely to require tuning

# of the options below, only patchfac, stridefac, deconvolution_in_each_patch, and roidensity are not caiman options (patchfac and stridefac are proportional to / used to derive caiman options rf and strides, while roidensity is used to derive caiman option K, and deconvolution_in_each_patch is used to derive p_patch)

# set scopa defaults above section heading "END SETTING SCOPA CAIMAN EXTRACTION DEFAULTS"

# set options sweeps in map2opt
# map2opt (called below) let's the user specify lists for any options in optex; those lists get distributed into all possible combinations of the options in map2opt

# md['dims'] is dims of original fov, dims_spatial_ex is dims of extraction fov (which may be cropped, so not necessarily the same as md['dims'])
# opttmp (in section ASSEMBLE OPTIONS DICTIONARY) has all options set here in topex; most are passed to cnmf.params.CNMFParams to create the caiman params object for use in cnmf.fit; some are used in a couple other caiman functions (noted in comments)

# downsampling options tsub, ssub, p_ssub, p_tsub have been omitted because extraction is never that slow at our typical resolutions (5-60 min per recording, just run on o2 if it's slow)

# input argument fnames is used to memmap a scopa regionex within caiman; fnames is automatically derived outside this function and just put in the options dict in here

# INDICES TO SUBSET STACK (optional input to cnmf.fit) ARE OMITTED IN SCOPA
# DOWNSAMPLING OPTIONS ARE OMITTED IN SCOPA 

############ GENERAL (USED IN MAIN EXTRACTION FUNCTION fit, in cnmf.py, OR IN MULTIPLE FUNCTIONS CALLED FROM fit) ############

gSig = [2, 2, 0.5] # approximate xyz half-size, in pixels, of average neurons; z ignored if extract_in_2d; later, forced to be odd when creating gsiz, so min gsiz is 3; any number 0-1 has same effect as 1, but since gSig is used to derive sigma_smooth_snmf, which is not clipped to 1, go ahead and use the real value; also, consider that our z are often much larger than xy when you set this, so if neurons are restricted to single z planes, make this 1 (since gsig unit is pixels)      
nb = 2 #nb is used everywhere; default 1; num background components
low_rank_background = 1 #spatial, and patch; #default true; and  #true makes bankground nb, false makes it update with hals, if true with patches, each patch keeps its background, if false, each patch bg approximated with global background
update_background_components = 1 #spatial; #default true; update background components during spatial phase
merge_thr = 0.85 #merge_components; default 0.85; threshold for merging components
only_init = 1 #default false; only use the initialization for extraction (no updating of spatial and or temporal components, ie no alternating least squares for spatial and temporal refinement)
normalize_init = 1 # init; default true; variance norm by pixel over time befroe initialization;  prob should always be true except for 1p data; patches take care of this to some extent but why not just do it always;
roidensity = 0.4  ##not a caiman option; used to derive K (approximate number of neurons to find), given other options, gSig, and patch or fov size; keep above 0 and less than or equal to 1; 1 is "space filling" (as many neurons as possible given patch or fov size, reoslution, and gsiz); caiman demo does not use this variable, but effectively their demo sets it at 0.33)
p = 1 #for deconvolution model if 1 or 2, or skipping deconvolution if 0 (skip deconvolution if neuron is nonspiking); order of the autoregressive system - 0 for nonspiking, 1 for instanteous rise but not decay (low sample rate), 2 for non-ionstantaneous rise and decay (higher sample rate)


############ INITIALIZATION (USED IN initialization.py) ############

#the set of initialization options that get used depends on how you set method_init

method_init = 'graph_nmf' #'greedy_roi' #'graph_nmf' #sparse_nmf; default greedy_roi; greedy_roi looks for globular sources; carl usually does not use greedy_roi  

# for method_init sparse_nmf and graph_nmf
sigma_smooth_snmf = [0.5, gSig[0], gSig[1], gSig[2]] # default 0.5 0.5 0.5 0.5; txyz std of gaussian smoothing filter applied just before initialization with method_init sparse_nmf or graph_nmf; similar to gSig for method_init greedy_roi, but unlike gSig, values 0-1 and evens do have an effect; consider z width, relative to xy width, when setting this 
perc_baseline_snmf = 20 # default 20
max_iter_snmf = 500  #default 200 sparsenmf, 500 graphnmf

# for method_init sparse_nmf only
alpha_snmf = 0.5 #default 0.5; sparsity penalty for sparse_nmf, different than sparsity penalty in graph_nmf, so keeping it separate 

# for method_init graph_nmf only
lambda_gnmf = 1 #default 1; sparsity penalty for method_init graphNMF; different than sparsity penalty in sparse_nmf, so keeping it separate 
SC_sigma = 1 # default 1; std for SC kernel
SC_thr = 0    # default 0; threshold for affinity matrix
SC_normalize = 1  # default True; standardize entries prior to computing affinity matrix
SC_use_NN = 0  # default False; sparsify affinity matrix by using only nearest neighbors
SC_nnn = 20   # default 20; number of nearest neighbors to use if SC_use_NN = True

# for method_init greedy_roi only   
rolling_sum = 0 #default false Using rolling sum for initialization (RollingGreedyROI), instead of total sum
rolling_length = 100 #default 100


############ UPDATE TEMPORAL COMPONENTS AND DECONVOLUTION (USED IN temporal.py AND deconvolution.py) ############

#p belongs in this section, but because it is so important, it was moved above under section "general" 
ITER = 3                # (default is 2; old value=5) -- block coordinate descent iterations
bas_nonneg = 0 #clip negatives in deconvolution (not the same as clipping negatives in stack); appears to not matter unless you're deconvolving (p is 1 or 2, not 0)
fudge_factor = 0.96        # (default is 0.96; old value = 1) -- bias correction factor for discrete time constants


############ UPDATE SPATIAL COMPONENTS (USED IN spatial.py, specifically in function threshold_components) ############

#during refinement, in update_spatial, the following params are used in function threshold_components
thr_method = 'nrg' #or 'max'
maxthr = 0.1 #for  thr_method = 'max' keep pixels above this threshold
nrgthr = 0.9999 #for  thr_method = 'nrg' keep pixels whose sorted cumsum contributes this much of total energy
extract_cc = 1 #true will throw away isolated pixels of some kind (cc means connected components)


############ PATCHES (USED IN cnmf.py AND map_reduce.py) ############

#low_rank_background also has meaning for patches in run_CNMF_patches, see notes for low_rank_background above
patchfac = 4 #not a caiman option; how many times larger largest dim of patch is than lagest dim of neuron diameter (ie largest dim of gsiz, since neuron diameter is approximately gsiz); 0 to skip patches, or make it large to do one patch on the full fov (saqme as 0); caiman recommends 3-4 (if not 0);automatically skipped if two_channel_ex (seeded extraction); if fov is smaller than patch, it's just one patch; patches are useful if activity stats vary over fov (e.g. extracting same neurons from regions with varying SNR, patch runs will adapt to local stats)
stridefac = 2 #not a caiman option; how many times larger largest dim of stride is than lagest dim of neuron diameter (ie largest dim of gsiz, since neuron diameter is approximately gsiz); 0 to skip patches; caiman recommends at least 1 (at least neuron dia) (if not 0);automatically skipped if two_channel_ex (seeded extraction); if fov is smaller than patch, it's just one patch; patches are useful if activity stats vary over fov (e.g. extracting same neurons from regions with varying SNR, patch runs will adapt to local stats)
nb_patch = nb #default matches nb; num background components per patch 
deconvolution_in_each_patch = 0 #not a caiman param but used to derive p_patch; this will only have effect if p is nonzero above


############ QUALITY EVALUATION (USED IN evaluate_components) ############

# Each parameter has a low threshold (rval_lowest (default -1), SNR_lowest (default 0.5), cnn_lowest (default 0.1)) and high threshold (rval_thr (default 0.8), min_SNR (default 2.5), min_cnn_thr (default 0.9)).
# in evaluate_components (called outside cnmf.fit), a component has to exceed ALL low thresholds as well as ONE high threshold to be accepted.
# can turn off CNN part withy use_CNN = false;
# these values below were set by carl as scopa defaults result in no roi filtering
SNR_lowest = 0 #0.5#0  #0.5 default  # minimum SNR for accepted components
min_SNR = 0 #0  #2.5 default    # accept components with that peak-SNR or higher
rval_lowest = -1  # -1 default 0.6  # space correlation threshold
rval_thr = 0 #0  # 0.8 default  # space correlation threshold
use_cnn = 0 # True default # use the CNN classifier affects if 2 below params are used
cnn_lowest = 0  #0.1 default  # neurons with cnn probability lower than this value are rejected
min_cnn_thr = 0 #0.9 default # if cnn classifier predicts below this value, reject
decay_time = .2  # i can only find this used in components evaluation (and onacid), approximate length of indicator tau off

############ MORPHOLOGICAL SEGEMENTATION OPTIONS (USED IN extract_binary_masks_from_structural_channel, TO EXTRACT MORPHOLOGICAL ROIS THAT SEED FUNCTIONAL CHANNEL EXTRACTION) ############

#morph_gsig is derived from gsig by default
morph_min_area_size = 2 #min area (in pixels); only used for cm.base.rois.extract_binary_masks_from_structural_channel, which is only used in two_channel_ex when automated structural rois seed the other channel
morph_min_hole_size = 0 #holes with smaller area (in pixels) will be filled in; only used for cm.base.rois.extract_binary_masks_from_structural_channel, which is only used in two_channel_ex when automated structural rois seed the other channel
morph_expand_method = 'closing' #closing or dilation; only used for cm.base.rois.extract_binary_masks_from_structural_channel, which is only used in two_channel_ex when automated structural rois seed the other channel


############ DERIVE A FEW OPTIONS FROM OTHERS ABOVE ############

gSiz = [int(np.round(2*gstmp + 1)) for gstmp in gSig] #half-size of bounding box for each neuron; this is what caiman does to compute gsiz from gsig, just putting it here for transparency
if extract_in_2d:
    gsiz_use = gSiz[0:2]
else:
    gsiz_use = gSiz
if two_channel_ex: #patches turned off (process whole fov at once) when seeding functional rois with automatically segmented structural channel rois; PROCESS IN PATCHES AND THEN COMBINE, patches are useful if activity stats vary over fov (e.g. extracting same neurons from regions with varying SNR, patch runs will adapt to local stats)
    rf = None # setting rf to none will run CNMF on the whole FOV
    stride = None       
    total_vox_ex = np.prod(dims_spatial_ex)
else:
    maxgsiz = np.max(gsiz_use)
    rf = int(np.ceil((maxgsiz) * patchfac))
    patchFW = rf*2 #patch full width, since rf is half
    stride = int(np.ceil((maxgsiz) * stridefac))
    if extract_in_2d:
        total_vox_ex = patchFW*patchFW
    else:
        if patchFW<dims_spatial_ex[2]:
            rfz = patchFW
        else:
            rfz = dims_spatial_ex[2]
        total_vox_ex = patchFW*patchFW*rfz

if total_vox_ex>=np.prod(dims_spatial_ex): #reset rf and stride if it turns out the patch is same size as fov or bigger
    rf = None # setting rf to none will run CNMF on the whole FOV
    stride = None       

K = int(np.round( total_vox_ex / np.prod(gsiz_use)*roidensity))  #K is number of components in whole fov (the "whole fov patch")

if deconvolution_in_each_patch and p>0:
    p_patch = p # default is zero (ie do not deconvolution_in_each_patch); if nonzero, run deconvolution in each patch, rather than after merging patches, if nonzero
else:
    p_patch = 0

morph_gSig = int(np.mean(gSig)) #must be odd and greater than 1; only used for cm.base.rois.extract_binary_masks_from_structural_channel (were it's called gSig), which is only used in two_channel_ex when automated structural rois seed the other channel
if morph_gSig<3:
    morph_gSig = 3
if morph_gSig%2!=1:
    morph_gSig = morph_gSig + 1



############ EXAMPLE OPTIONS DICT ############

opttmp = {
            #these are used in cnmf.fit, here they are sorted by their calling functions, later they are sorted alphabetically
            'K': K,
            'gSig': gSig,
            'gSiz': gSiz,
            'nb': nb,
            'p': p,
            'update_background_components': update_background_components,
            'low_rank_background' : low_rank_background,
            'merge_thr': merge_thr,
            'only_init': only_init,
            'normalize_init': normalize_init,
            'method_init': method_init,
            'perc_baseline_snmf': perc_baseline_snmf,
            'max_iter_snmf': max_iter_snmf,
            'sigma_smooth_snmf': sigma_smooth_snmf,
            'alpha_snmf': alpha_snmf,
            'lambda_gnmf': lambda_gnmf,
            'SC_sigma': SC_sigma,           
            'SC_thr': SC_thr,               
            'SC_normalize': SC_normalize,       
            'SC_use_NN': SC_use_NN,   
            'SC_nnn': SC_nnn,             
            'ITER': ITER,
            'fudge_factor': fudge_factor,
            'bas_nonneg': bas_nonneg,
            'rf': rf,
            'stride': stride,
            'p_patch': p_patch,
            'nb_patch': nb_patch,
            'rolling_sum': rolling_sum,
            'rolling_length': rolling_length,
            'thr_method': thr_method,
            'maxthr': maxthr,
            'nrgthr': nrgthr,
            'extract_cc': extract_cc,
            'fnames': fnames,
            #these are used in evaluate_components (not cnmf.fit)
            'SNR_lowest': SNR_lowest,
            'min_SNR': min_SNR,
            'rval_thr': rval_thr,
            'rval_lowest': rval_lowest,
            'use_cnn': use_cnn,
            'min_cnn_thr': min_cnn_thr,
            'cnn_lowest': cnn_lowest,
            'decay_time': decay_time,
            #not sure where these are used, if at all
            'dxy': dxy,
            'fr': fr,
            #these are used in extract_binary_masks_from_structural_channel (not cnmf.fit)
            'morph_min_area_size': morph_min_area_size, 
            'morph_min_hole_size': morph_min_hole_size, 
            'morph_gSig': morph_gSig, 
            'morph_expand_method': morph_expand_method 
            } 