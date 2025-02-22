
def ored(opt, two_channel_ex):

    #create a minimal set of options output from oex (the effective set), since option use depends on other options
    # here, scopa variables used in oex to derive caiman variables are not used; instead the derived caiman variables are used

    optred = {}


    optred['methodex'] = opt['methodex'] #not a caiman param
    optred['rgname'] = opt['rgname'] #not a caiman param
    optred['maskname'] = opt['maskname'] #not a caiman param

    optred['gSig'] = opt['gSig']
    optred['nb'] = opt['nb']
    optred['low_rank_background'] = opt['low_rank_background']
    optred['update_background_components'] = opt['update_background_components']
    optred['normalize_init'] = opt['normalize_init']
    optred['only_init'] = opt['only_init']

    optred['roidensity'] = opt['roidensity'] #used to derive K

    #init
    optred['method_init'] = opt['method_init']

    if opt['method_init']=='greedy_roi':
        if opt['rolling_sum']==True:
            optred['rolling_sum'] = opt['rolling_sum']
            optred['rolling_length'] = opt['rolling_length']
    elif opt['method_init']=='graph_nmf' or opt['method_init']=='sparse_nmf':
        optred['sigma_smooth_snmf_time'] = opt['sigma_smooth_snmf_time'] #used to derive sigma_smooth_snmf
        optred['perc_baseline_snmf'] = opt['perc_baseline_snmf']
        optred['max_iter_snmf'] = opt['max_iter_snmf']
        optred['sparsity_penalty'] = opt['sparsity_penalty'] #assigned to alpha_snmf or lambda_gnmf
        if opt['method_init']=='graph_nmf':
            optred['SC_sigma'] = opt['SC_sigma']
            optred['SC_thr'] = opt['SC_thr']
            optred['SC_normalize'] = opt['SC_normalize']
            optred['SC_use_NN'] = opt['SC_use_NN']
            optred['SC_nnn'] = opt['SC_nnn']

    if opt['only_init']==False: #if not doing initialization only

        #temporal
        optred['p'] = opt['p']
        optred['ITER'] = opt['ITER']

        #deconvolution
        if opt['p']!=0:
            optred['bas_nonneg'] = opt['bas_nonneg']
            optred['fudge_factor'] = opt['fudge_factor']

        #spatial
        optred['thr_method'] = opt['thr_method']
        optred['maxthr'] = opt['maxthr']
        optred['nrgthr'] = opt['nrgthr']
        optred['extract_cc'] = opt['extract_cc']

        #merging
        optred['merge_thr'] = opt['merge_thr']


    #patches
    if not two_channel_ex and opt['patchfac']!=0: # originally if opt['rf'] is not None: but we don't know rf until derive_some_options, later
        optred['patchfac'] = opt['patchfac'] #used to derive rf
        optred['stridefac'] = opt['stridefac'] #used to derive stride
        if opt['low_rank_background']==True:
            optred['nb_patch'] = 0
        else:
            optred['nb_patch'] = opt['nb_patch']
        if opt['p']!=0:
            opt['deconvolution_in_each_patch'] # this is used to derive optred['p_patch'] = opt['p_patch']


    #evaluation
    if opt['use_cnn']==True:
        optred['use_cnn'] = opt['use_cnn']
        optred['cnn_lowest'] = opt['cnn_lowest']
        optred['min_cnn_thr'] = opt['min_cnn_thr']

    if opt['methodex'].startswith('seed') and opt['methodex'].endswith('py'): #python automated morph roi extraction to seed functional extraction (not just two_channel_ex since seedeachpy is not two_channel_ex)
        optred['morph_min_area_size'] = opt['morph_min_area_size']
        optred['morph_min_hole_size'] = opt['morph_min_hole_size']
        optred['morph_expand_method'] = opt['morph_expand_method']


    return optred

