
def optreduce(opt, two_channel_ex):

    #create a minimal set of options output from optex (the effective set), since option use depends on other options
    # here, scopa variables used in optex to derive caiman variables are not used; instead the derived caiman variables are used

    ored = {}


    ored['methodex'] = opt['methodex'] #not a caiman param
    ored['regionex'] = opt['regionex'] #not a caiman param
    ored['maskname'] = opt['maskname'] #not a caiman param

    ored['gSig'] = opt['gSig']
    ored['nb'] = opt['nb']
    ored['low_rank_background'] = opt['low_rank_background']
    ored['update_background_components'] = opt['update_background_components']
    ored['normalize_init'] = opt['normalize_init']
    ored['only_init'] = opt['only_init']

    ored['roidensity'] = opt['roidensity'] #used to derive K

    #init
    ored['method_init'] = opt['method_init']

    if opt['method_init']=='greedy_roi':
        if opt['rolling_sum']==True:
            ored['rolling_sum'] = opt['rolling_sum']
            ored['rolling_length'] = opt['rolling_length']
    elif opt['method_init']=='graph_nmf' or opt['method_init']=='sparse_nmf':
        ored['sigma_smooth_snmf_time'] = opt['sigma_smooth_snmf_time'] #used to derive sigma_smooth_snmf
        ored['perc_baseline_snmf'] = opt['perc_baseline_snmf']
        ored['max_iter_snmf'] = opt['max_iter_snmf']
        ored['sparsity_penalty'] = opt['sparsity_penalty'] #assigned to alpha_snmf or lambda_gnmf
        if opt['method_init']=='graph_nmf':
            ored['SC_sigma'] = opt['SC_sigma']
            ored['SC_thr'] = opt['SC_thr']
            ored['SC_normalize'] = opt['SC_normalize']
            ored['SC_use_NN'] = opt['SC_use_NN']
            ored['SC_nnn'] = opt['SC_nnn']

    if opt['only_init']==False: #if not doing initialization only

        #temporal
        ored['p'] = opt['p']
        ored['ITER'] = opt['ITER']

        #deconvolution
        if opt['p']!=0:
            ored['bas_nonneg'] = opt['bas_nonneg']
            ored['fudge_factor'] = opt['fudge_factor']

        #spatial
        ored['thr_method'] = opt['thr_method']
        ored['maxthr'] = opt['maxthr']
        ored['nrgthr'] = opt['nrgthr']
        ored['extract_cc'] = opt['extract_cc']

        #merging
        ored['merge_thr'] = opt['merge_thr']


    #patches
    if not two_channel_ex and opt['patchfac']!=0: # originally if opt['rf'] is not None: but we don't know rf until derive_some_options, later
        ored['patchfac'] = opt['patchfac'] #used to derive rf
        ored['stridefac'] = opt['stridefac'] #used to derive stride
        if opt['low_rank_background']==True:
            ored['nb_patch'] = 0
        else:
            ored['nb_patch'] = opt['nb_patch']
        if opt['p']!=0:
            opt['deconvolution_in_each_patch'] # this is used to derive ored['p_patch'] = opt['p_patch']


    #evaluation
    if opt['use_cnn']==True:
        ored['use_cnn'] = opt['use_cnn']
        ored['cnn_lowest'] = opt['cnn_lowest']
        ored['min_cnn_thr'] = opt['min_cnn_thr']

    if opt['methodex'].startswith('seed') and opt['methodex'].endswith('py'): #python automated morph roi extraction to seed functional extraction (not just two_channel_ex since seedeachpy is not two_channel_ex)
        ored['morph_min_area_size'] = opt['morph_min_area_size']
        ored['morph_min_hole_size'] = opt['morph_min_hole_size']
        ored['morph_expand_method'] = opt['morph_expand_method']


    return ored

