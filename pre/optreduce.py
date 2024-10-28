
def optreduce(opt, optmo, two_channel_ex = 0):

    #create a minimal set of options output from optex (the effective set), since option use depends on other options
    # here, scopa variables used in optex to derive caiman variables are not used; instead the derived caiman variables are used

    ored = {}


    ored['gSig'] = opt['gSig']
    ored['nb'] = opt['nb']
    ored['low_rank_background'] = opt['low_rank_background']
    ored['update_background_components'] = opt['update_background_components']
    ored['normalize_init'] = opt['normalize_init']
    ored['only_init'] = opt['only_init']

    ored['K'] = opt['K'] #derived from roi_density

    #init
    ored['method_init'] = opt['method_init']

    if opt['method_init']=='greedy_roi':
        if opt['rolling_sum']==True:
            ored['rolling_sum'] = opt['rolling_sum']
            ored['rolling_length'] = opt['rolling_length']
    elif opt['method_init']=='graph_nmf' or opt['method_init']=='sparse_nmf':
        ored['sigma_smooth_snmf'] = opt['sigma_smooth_snmf']
        ored['perc_baseline_snmf'] = opt['perc_baseline_snmf']
        ored['max_iter_snmf'] = opt['max_iter_snmf']
        if opt['method_init']=='sparse_nmf':
            ored['alpha_snmf'] = opt['alpha_snmf']
        elif opt['method_init']=='graph_nmf':
            ored['lambda_gnmf'] = opt['lambda_gnmf']
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
        ored['se'] = opt['se']
        ored['medw'] = opt['medw']

        #merging
        ored['merge_thresh'] = opt['merge_thresh']


    #patches
    if opt['rf'] is not None:
        ored['rf'] = opt['rf'] #derived from patchfac
        ored['stride'] = opt['stride'] #derived from stridefac
        if opt['low_rank_background']==True:
            ored['nb_patch'] = 0
        else:
            ored['nb_patch'] = opt['nb_patch']
        if opt['p']!=0:
            ored['p_patch'] = opt['p_patch']

    #evaluation
    if opt['use_cnn']==True:
        ored['use_cnn'] = opt['use_cnn']
        ored['cnn_lowest'] = opt['cnn_lowest']
        ored['min_cnn_thr'] = opt['min_cnn_thr']

    if two_channel_ex:
        ored['morph_se'] = optmo['morph_se']
        ored['morph_areamin'] = optmo['morph_areamin']
        ored['morph_holemin'] = optmo['morph_holemin']
        ored['morph_expandmthd'] = optmo['morph_expandmthd']
        ored['morph_gsig'] = optmo['morph_gsig']


    return ored