

import numpy as np
from odist import odist
from ored import ored
from dictsort import dictsort
from oexid import oexid
from dict_unique import dict_unique
from dicttxtld import dicttxtld


def oex(fnames, md, dims_spatial_ex, extract_in_2d, two_channel_ex, pth_optdf, pth_optroi, methodex, regionex, maskname):


    # optlist hold carl's favorite options (each in a list) for tuning caiman roi extraction;
    # each option here is also an option optdf, which are default options read from the default options file, optdf.txt file; if an option is a list in optdf, it must be a list of lists in optlist
    # options in optlist will overwrite their counterparts in optdf
    # lists are distributed into all possible combinations (using odist) and extract.py loops over these options sets, so you can see how extraction is affected by varying these params; 
    # any params from oex can be used here, these are just my favorite because they seem to have the largest effect, and/or are most variable across recordings 
    # after optlist is applied/distributed, ored will remove any options that aren't used (since option use depend on options themselves), then dict_unique will remove any repeat sets, 
    # then oexid finds a unique ID by checking all options sets that have ever been run (using file optroi.txt) and assigns an ID to each option set currently in use (if it's never been used it gets a new ID and is appended to optroi.txt)
    # then optderive derives a few caiman options from the options the user specifies, some of which are not direct caiman options, but solely used in optderive (since, in my opinion, some caiman options are best used this way, ie options that can be made invalid or poor because of changes to the data, eg K, number of neurons, is derived because it depends o much of the data size (regionex size) and whether you are using patches)
    # then optcheck makes sure there are no problems with the options 
    # all this also occurs in oset.m, in the matlab part of the scopa pipeline (so user can run caiman extraction from matlab, or from python); running from matlab gives the user more option-specification flexibility
    # in short: user's set, load df, overwrite df, distribute, reduce, sort, unique, ID, derive, check

    ############ SET OPTIONS IN optlist TO OVERWRITE DEFAULTS optdf, USE LISTS TO DISTRIBUTE OPTIONS INTO OPTIONS SETS COVERING ALL POSSIBLE COMBINATIONS; IF ALL OPTIONS IN optlist ARE SCALAR, THERE WILL ONLY BE ONE OPTIONS SET  ############

    optlist = {}
    
    optlist['gSig'] = [ [2, 2, 0.5], [4, 4, 1] ] #list of lists; z (3rd element) ignored if extract_in_2d; 
    optlist['nb'] = [1,2] 
    optlist['low_rank_background'] = [1, 0]
    optlist['update_background_components'] = [1] 
    optlist['merge_thr'] = [0.85] 
    optlist['only_init'] = [0] 
    optlist['normalize_init'] = [1] 
    optlist['roidensity'] = [0.4, 0.8]  #not a caiman param, but used to derive caiman param K
    optlist['p'] = [0, 1]

    optlist['method_init'] = ['graph_nmf', 'sparse_nmf', 'greedy_roi']
    optlist['sigma_smooth_snmf_time'] = [0.5] #first element of sigma_smooth_snmf, for smoothing in time before initialization; in oex, the xyz elements are assigned the same values as gSig 
    optlist['perc_baseline_snmf'] = [20]
    optlist['max_iter_snmf'] = [500] 
    optlist['sparsity_penalty'] = [1, 4] #not a caiman option, but assigned to caiman options alpha_snmf (when using method_init sparse_nmf) and lambda_gnmf (when using method_init graph_nmf)



    ############ READ DEFAULT OPTIONS AND OVERWRITE WITH ANY ABOVE IN optlist ############


    optdf = dicttxtld(pth_optdf)

    notlist = {}
    for k,v in optdf.items():
        if k not in optlist:
            optlist[k] = v
        if not isinstance(optlist[k], list):
            notlist[k] = 1
            optlist[k] = [optlist[k]]


    # also assign a few options that are set or derived outside oex (putting them down here because they are not for user input here)
    optlist['fnames'] = [ fnames ]
    optlist['regionex'] = [ regionex ] 
    optlist['methodex'] = [ methodex ] 
    optlist['maskname'] = [ maskname ] 

    optlist['domm'] = [ 0 ] #false if not calling extract from matlab
    optlist['doma'] = [ 0 ] #false if not calling extract from matlab
    optlist['docm'] = [ 1 ] #true whether calling extract from matlab or not
    optlist['doqc'] = [ 0 ] #false if not calling extract from matlab

    ############ DISTRIBUTE OPTIONS IN LISTS (APPLY odist TO CREATE ALL COMBINATIONS OF OPTIONS) ############

    optsets = odist(optlist)
    max_num_options_sets = 500 #error if you create more than this many options sets
    if len(optsets.map)>max_num_options_sets:
        raise Exception("WARNING, YOU HAVE CREATED MORE THAN " + str(max_num_options_sets) + " OPTIONS SETS, IF YOU REALLY WANT TO PROCEED WITH THIS NUMBER, COMMENT THIS EXCEPTION OR CHANGE max_num_options_sets")

    optredall = []
    opt_oneset = {}
    for opt_oneset_list in optsets.map:
        for key,val in zip(optsets.order, opt_oneset_list):
            opt_oneset[key] = val

        if extract_in_2d: #change some options from 3d to 2d (remove 3rd element), do this before ored, in case redundancy without 3rd element
            opt_oneset = opt2dfix(opt_oneset)
    
        ############ REDUCE TO MINIMAL EFFECTIVE SET, SORT, AND REMOVE DUPLICATE SETS ############

        ored = ored(opt_oneset, two_channel_ex) #get minimal effective set of options (ie remove options that won't be used, depending on other options)
        ored = dictsort(ored) #recursively order alphabetically, ignoring case
        optredall.append(ored)
    
    optredall = dict_unique(optredall) #remove redundant reduced options sets 
    

    ############ GET OPTID FROM OPTIONS FILE ############

    optout = {}
    for ored in optredall:
        optid = oexid(ored, pth_optroi)

        ############ DERIVE SOME OPTIONS AND CHECK FOR PROBLEMS ############

        optout[optid] = optderive(two_channel_ex, dims_spatial_ex, extract_in_2d, md, ored)        
        optout[optid] = optcheck(two_channel_ex, optout[optid]) #check for problems in how options were set
   
    return optout




def opt2dfix(opt_oneset):
    
    #right now there's only one param to correct (used to be more)
    opt_oneset['gSig'] = opt_oneset['gSig'][:-1] 
    
    return opt_oneset


def optderive(two_channel_ex, dims_spatial_ex, extract_in_2d, md, opt):
    
    ############ DERIVE main options K, gSiz, AND PATCH options rf, stride, and p_patch, and init options sigma_smooth_snmf, alpha_snmf, and lambda_gnmf, and also morph_gSig, fr, and dxy  ############
    
    if opt['method_init']=='graph_nmf' or opt['method_init']=='sparse_nmf':
        opt['sigma_smooth_snmf'] = [ opt['sigma_smooth_snmf_time'] ] + opt['gSig']
        opt['alpha_snmf'] = opt['sparsity_penalty']
        opt['lambda_gnmf'] = opt['sparsity_penalty']

    opt['gSiz'] = [int(np.round(2*gstmp + 1)) for gstmp in opt['gSig']] #half-size of bounding box for each neuron; this is what caiman does to compute gsiz from gsig, just putting it here for transparency
    if extract_in_2d:
        gsiz_use = opt['gSiz'][0:2]
    else:
        gsiz_use = opt['gSiz']
    
    if two_channel_ex or opt['patchfac']==0: #patches turned off (process whole regionex at once) when seeding functional rois with automatically segmented structural channel rois; PROCESS IN PATCHES AND THEN COMBINE, patches are useful if activity stats vary over fov (e.g. extracting same neurons from regions with varying SNR, patch runs will adapt to local stats)
        opt['rf'] = None # setting rf to none will run CNMF on the whole regionex
        opt['stride'] = None       
        total_vox_ex = np.prod(dims_spatial_ex) #total_vox_ex is in whole regionex if no patches
    else:
        maxgsiz = np.max(gsiz_use)
        opt['rf'] = int(np.ceil(maxgsiz * opt['patchfac']))
        patchFW = ['rf']*2 #patch full width, since rf is half
        opt['stride'] = int(np.ceil(maxgsiz * opt['stridefac']))
        if extract_in_2d:
            total_vox_ex = patchFW*patchFW #total_vox_ex is num vox per patch , if patches
        else:
            if patchFW<dims_spatial_ex[2]:
                rfz = patchFW
            else:
                rfz = dims_spatial_ex[2]
            total_vox_ex = patchFW*patchFW*rfz #total_vox_ex is num vox per patch , if patches

        if total_vox_ex>=np.prod(dims_spatial_ex): #reset total_vox_ex and rf and stride if it turns out the patch is same size as regionex or bigger
            raise Exception("total number voxels in patch is greater than total num voxels in regionex (or full fov, if regionex is 'none'); originally this reverted patch to empty, but this means accurate patch options cannot be set in optroi.txt, since if this reverted to empty it would break the isomorphism between input options and derived options;")
            total_vox_ex = np.prod(dims_spatial_ex)
            opt['rf'] = None # setting rf to none will run CNMF on the whole regionex
            opt['stride'] = None       
        
    opt['K'] = int(np.round( total_vox_ex / np.prod(gsiz_use)*opt['roidensity']))  #K is number of components in patch, or whole regionex if rf is none (no patches)

    if opt['only_init']==False: # opt below wont exist in reduced opt (passed into this function) unless only init is false
        if opt['p']!=0 and opt['deconvolution_in_each_patch']:
            opt['p_patch'] = opt['p'] # default is zero (ie do not deconvolution_in_each_patch); if nonzero, run deconvolution in each patch, rather than after merging patches, if nonzero
        else:
            opt['p_patch'] = 0
    
    opt['morph_gSig'] = int(np.mean(opt['gSig'])) #must be odd and greater than 1; only used for cm.base.rois.extract_binary_masks_from_structural_channel (were it's called gSig), which is only used in two_channel_ex when automated structural rois seed the other channel
    if opt['morph_gSig']<3:
       opt['morph_gSig'] = 3
    if opt['morph_gSig']%2!=1:
       opt ['morph_gSig'] = opt['morph_gSig'] + 1

    opt['fr'] = md['volrate'] #0.6193  #9.8465 frame period so 1000 / (9.8465 *(113+51)) # approximate frame rate of data - CONFIRMED FPS
    if extract_in_2d: 
        opt['dxy'] = [md['xpix']/md['xfov'], md['ypix']/md['yfov'] ] #pixels per micron
    else:
        opt['dxy'] = [md['xpix']/md['xfov'], md['ypix']/md['yfov'], md['numslice']/md['zfov']] #pixels per micron
    
    return opt

def optcheck(two_channel_ex, opt):
    
    ############ CHECK OPTIONS FOR PROBLEMS ############

    if opt['rf'] is not None and opt['rf']<np.max(opt['gSiz'])*3:
        raise Exception("rf should be at least 3 times gSiz, according to caiman recommendations")
    if opt['stride'] is not None and opt['stride']<np.max(opt['gSiz']):
        raise Exception("stride should be at least equal to gSiz, according to caiman recommendations")
    if opt['method_init']=='corr_pnr': #for 1p data, according to caiman . . . so does this mean lots of background activity?? 
        raise Exception("method_init 'corr_pnr' is for 1p data (data with busy background, aka high rank background); if you want to use it anyway, see required options changes below")
            #these changes are required for method_init=='corr_pnr':
                # K = None # none if using corr_pnr (if in cnmfe mode, ie 1p mode)
                # nb = 0 ##nb is used everywhere; num background components
                # only_init = 1 #only use the initialization for extraction (no alternating least squares for spatial and temporal refinement)
                # low_rank_background = None ##spatial, and patch; #true makes bankground nb, false makes it update with hals, if true with patches, each patch keeps its background, if false, each patch bg approximated with global background
                # center_psf = 1  #initialization; True indicates centering the filtering kernel for background removal. This is useful for data with large background fluctuations.
                # normalize_init = 0 #init; variance norm by pixel over time befroe initialization; prob should always be true except for 1p data; patches take care of this to some extent but why not just do it always; 
    if two_channel_ex and opt['only_init']:
        raise Exception("only_init must be false if two_channel_ex is true")
    if opt['morph_gSig']<3:
        raise Exception("warning, morph_gSig must be greater than or equal to 3 (and odd)")
    if not opt['morph_gSig']%2==1:
        raise Exception("warning, morph_gSig must be odd (and greater than or equalt o 3)")
    
    return opt


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


