

import numpy as np
from map2opt import map2opt
from optreduce import optreduce
from optex2id import optex2id
from dict_unique import dict_unique
import json


def optex(fnames, md, dims_spatial_ex, extract_in_2d, two_channel_ex, pth_optdf, pth_optroi, methodex):

    ############ SET OPTIONS IN YOU WANT TO OVERWRITE DEFAULTS IN DICT otmp, USE LISTS TO EXPAND INTO ALL COMBINATIONS; IF ALL OPTIONS IN otmp ARE SINGLE ELEMENTS, THEN THERE WILL ONLY BE ONE OPTIONS SET  ############
    
    otmp = {}
    otmp['gSig'] = [ [2, 2, 0.5], [4, 4, 1] ] #list of lists; z (3rd element) ignored if extract_in_2d; 
    otmp['nb'] = [1,2] 
    otmp['low_rank_background'] = [1, 0]
    otmp['update_background_components'] = [1] 
    otmp['merge_thr'] = [0.85] 
    otmp['only_init'] = [0] 
    otmp['normalize_init'] = [1] 
    otmp['roidensity'] = [0.4, 0.8]  #not a caiman param, but used to derive caiman param K
    otmp['p'] = [0, 1]

    otmp['method_init'] = ['graph_nmf', 'sparse_nmf', 'greedy_roi']
    otmp['sigma_smooth_snmf_time'] = [0.5] #first element of sigma_smooth_snmf, for smoothing in time before initialization; in optex, the xyz elements are assigned the same values as gSig 
    otmp['perc_baseline_snmf'] = [20]
    otmp['max_iter_snmf'] = [500] 
    otmp['sparsity_penalty'] = [1, 4] #not a caiman option, but assigned to caiman options alpha_snmf (when using method_init sparse_nmf) and lambda_gnmf (when using method_init graph_nmf)

    ############ READ DEFAULT OPTIONS AND OVERWRITE WITH ANY ABOVE IN otmp ############

    with open(pth_optdf, 'r') as file:
        optdf = json.loads(file.read())
    optdf = optdf['cm']

    notlist = {}
    for k,v in optdf.items():
        if k not in otmp:
            otmp[k] = v
        if not isinstance(otmp[k], list):
            notlist[k] = 1
            otmp[k] = [otmp[k]]

    ############ EXPAND OPTIONS (APPLY map2opt TO CREATE ALL COMBINATIONS OF OPTIONS), THEN GET MINIMAL EFFECTIVE SET  ############

    optsets = map2opt(otmp)
    max_num_options_sets = 500 #error if you create more than this many options sets
    if len(optsets.map)>max_num_options_sets:
        raise Exception("WARNING, YOU HAVE CREATED MORE THAN " + str(max_num_options_sets) + " OPTIONS SETS, IF YOU REALLY WANT TO PROCEED WITH THIS NUMBER, COMMENT THIS EXCEPTION OR CHANGE max_num_options_sets")

    optredall = []
    opt_oneset = {}
    for opt_oneset_list in optsets.map:
        for key,val in zip(optsets.order, opt_oneset_list):
            opt_oneset[key] = val

        opt_oneset = derive_some_options(two_channel_ex, dims_spatial_ex, extract_in_2d, md, opt_oneset)        
        opt_oneset = optcheck(two_channel_ex, extract_in_2d, opt_oneset) #check for problems in how options were set
        optred = optreduce(opt_oneset, methodex) #get minimal effective set of options (ie remove options that won't be used, depending on other options)
        optredall.append(optred)
    
    optredall = dict_unique(optredall) #remove redundant reduced options sets 
    
    ############ GET OPTID FROM OPTIONS FILE ############

    optout = {}
    for opt_oneset in optredall:
        optid = optex2id(opt_oneset, methodex, pth_optroi)
        optout[optid] = opt_oneset
   
    return optout


def derive_some_options(two_channel_ex, dims_spatial_ex, extract_in_2d, md, opttmp):
    
    ############ DERIVE main options K, gSiz, AND PATCH options rf, stride, and p_patch, and init options sigma_smooth_snmf, alpha_snmf, and lambda_gnmf, and also morph_gSig, fr, and dxy  ############
    
    opttmp['sigma_smooth_snmf'] = [ opttmp['sigma_smooth_snmf_time'] ] + opttmp['gSig']
    opttmp ['alpha_snmf'] = opttmp['sparsity_penalty']
    opttmp['lambda_gnmf'] = opttmp['sparsity_penalty']

    opttmp['gSiz'] = [int(np.round(2*gstmp + 1)) for gstmp in ['gSig']] #half-size of bounding box for each neuron; this is what caiman does to compute gsiz from gsig, just putting it here for transparency
    if extract_in_2d:
        gsiz_use = opttmp['gSiz'][0:2]
    else:
        gsiz_use = opttmp['gSiz']
    if two_channel_ex: #patches turned off (process whole fov at once) when seeding functional rois with automatically segmented structural channel rois; PROCESS IN PATCHES AND THEN COMBINE, patches are useful if activity stats vary over fov (e.g. extracting same neurons from regions with varying SNR, patch runs will adapt to local stats)
        opttmp['rf'] = None # setting rf to none will run CNMF on the whole FOV
        opttmp['stride'] = None       
        total_vox_ex = np.prod(dims_spatial_ex)
    else:
        maxgsiz = np.max(gsiz_use)
        opttmp['rf'] = int(np.ceil((maxgsiz) * opttmp['patchfac']))
        patchFW = ['rf']*2 #patch full width, since rf is half
        opttmp['stride'] = int(np.ceil((maxgsiz) * opttmp['stridefac']))
        if extract_in_2d:
            total_vox_ex = patchFW*patchFW
        else:
            if patchFW<dims_spatial_ex[2]:
                rfz = patchFW
            else:
                rfz = dims_spatial_ex[2]
            total_vox_ex = patchFW*patchFW*rfz

    if total_vox_ex>=np.prod(dims_spatial_ex): #reset rf and stride if it turns out the patch is same size as fov or bigger
        opttmp['rf'] = None # setting rf to none will run CNMF on the whole FOV
        opttmp['stride'] = None       
    
    K = int(np.round( total_vox_ex / np.prod(gsiz_use)*opttmp['roidensity']))  #K is number of components in whole fov (the "whole fov patch")

    if opttmp['run_deconvolution_in_each_patch'] and opttmp['p']>0:
        opttmp['p_patch'] = p # default is zero (ie do not run_deconvolution_in_each_patch); if nonzero, run deconvolution in each patch, rather than after merging patches, if nonzero
    else:
        opttmp['p_patch'] = 0
    
    opttmp['morph_gSig'] = int(np.mean(opttmp['gSig'])) #must be odd and greater than 1; only used for cm.base.rois.extract_binary_masks_from_structural_channel (were it's called gSig), which is only used in two_channel_ex when automated structural rois seed the other channel
    if opttmp['morph_gSig']<3:
       opttmp['morph_gSig'] = 3
    if opttmp['morph_gSig']%2!=1:
       opttmp ['morph_gSig'] = opttmp['morph_gSig'] + 1

    opttmp['fr'] = md['volrate'] #0.6193  #9.8465 frame period so 1000 / (9.8465 *(113+51)) # approximate frame rate of data - CONFIRMED FPS
    if md['zfov']==0: #md['zfov']==0 when stack is xyt (not volumetric xyzt); below, the third element (hard coded 0.0) will be removed
        opttmp['dxy'] = [md['xpix']/md['xfov'], md['ypix']/md['yfov'], 0.0 ] #pixels per micron
    else:
        opttmp['dxy'] = [md['xpix']/md['xfov'], md['ypix']/md['yfov'], md['numslice']/md['zfov']] #pixels per micron
    
    return opttmp

def optcheck(two_channel_ex, extract_in_2d, opttmp):
    
    ############ CHECK OPTIONS FOR PROBLEMS ############

    if extract_in_2d: #change a few options from 3d to 2d (remove 3rd element)
        opttmp['dxy'] = opttmp['dxy'][:-1] 
        opttmp['gSig'] = opttmp['gSig'][:-1] 
        opttmp['gSiz'] = opttmp['gSiz'][:-1] 
        opttmp['sigma_smooth_snmf'] = opttmp['sigma_smooth_snmf'][:-1]

    if opttmp['rf'] is not None and opttmp['rf']<np.max(opttmp['gSiz'])*3:
        raise Exception("rf should be at least 3 times gSiz, according to caiman recommendations")
    if opttmp['stride'] is not None and opttmp['stride']<np.max(opttmp['gSiz']):
        raise Exception("stride should be at least equal to gSiz, according to caiman recommendations")
    if opttmp['method_init']=='corr_pnr': #for 1p data, according to caiman . . . so does this mean lots of background activity?? 
        raise Exception("method_init 'corr_pnr' is for 1p data (data with busy background, aka high rank background); if you want to use it anyway, see required options changes below")
            #these changes are required for method_init=='corr_pnr':
                # K = None # none if using corr_pnr (if in cnmfe mode, ie 1p mode)
                # nb = 0 ##nb is used everywhere; num background components
                # only_init = 1 #only use the initialization for extraction (no alternating least squares for spatial and temporal refinement)
                # low_rank_background = None ##spatial, and patch; #true makes bankground nb, false makes it update with hals, if true with patches, each patch keeps its background, if false, each patch bg approximated with global background
                # center_psf = 1  #initialization; True indicates centering the filtering kernel for background removal. This is useful for data with large background fluctuations.
                # normalize_init = 0 #init; variance norm by pixel over time befroe initialization; prob should always be true except for 1p data; patches take care of this to some extent but why not just do it always; 
    if two_channel_ex and opttmp['only_init']:
        raise Exception("only_init must be false if two_channel_ex is true")
    if opttmp['morph_gSig']<3:
        raise Exception("warning, morph_gSig must be greater than or equal to 3 (and odd)")
    if not opttmp['morph_gSig']%2==1:
        raise Exception("warning, morph_gSig must be odd (and greater than or equalt o 3)")
    
    return opttmp


    ############ NOTES ON INITIALIZATION METHODS ############

    # for reference here are the initialization defs for 3 methods, 
    # sparse_nmf "has problems" according to gitter, although it's worked for carl

    # greedy roi is best for globular sources
        # greedyROI(stack, nr=30, gSig=[5, 5], gSiz=[11, 11], nIter=5, kernel=None, nb=1, rolling_sum=False, rolling_length=100, seed_method='auto')

    # for graphnmf all these are tunable in cnmf params except remove_baseline, truncate, tol, and SC_kernel whose defaults are below
    # note SC_kernel appears to be tunable because it's in params but it is not, heat is default
        # graphNMF(Y_ds, nr, max_iter_snmf=500, lambda_gnmf=1, sigma_smooth=(.5, .5, .5), remove_baseline=True, perc_baseline=20, nb=1, 
        #       truncate=2, tol=1e-3, SC_kernel='heat', SC_normalize=True, SC_thr=0, SC_sigma=1, SC_use_NN=False, SC_nnn=20

    # for sparsenmf all these are tunable in cnmf params except remove_baseline and truncate, whose defaults are below
        # # sparseNMF(Y_ds, nr, max_iter_snmf=200, alpha=0.5, sigma_smooth=(.5, .5, .5), remove_baseline=True, perc_baseline=20, nb=1, truncate=2):


