function roimask = roifauto(stack, opt, opt2)

%{
methodex:
    '1' (channel 1 only), 
    '2' (channel 2 only), 
    '12' (channel 1 and 2 independently), 
    'seedeachpy' (channel 1 and 2 independently, with python-automated morph roi seed masks for each channel), 
    'seedeachmat' (same as seedeachpy, but using morph rois created/saved in matlab), 
    'seed21py' (python-automated morph roi seed mask in channel 2 seed functional extraction from channel 1), 
    'seed12py' (inverse of seed21py), 
    'seed21mat' (same as 'seed21py', but for morph rois created/saved in matlab), 
    'seed12mat' (inverse of 'seed21mat'); the seed*py methodex only work when extract_in_2d=true
%}

arguments

    stack

    % MAIN
    opt.methodex = '1'; %see notes on methodex in function roifauto
    opt.gSig = [2, 2, 0.5]; %approximate xyz half-size, in pixels, of average neurons; z ignored if extract_in_2d; later, forced to be odd when creating gsiz, so min gsiz is 3; any number 0-1 has same effect as 1, but since gSig is used to derive sigma_smooth_snmf, which is not clipped to 1, go ahead and use the real value; also, consider that our z are often much larger than xy when you set this, so if neurons are restricted to single z planes, make this 1 (since gsig unit is pixels); z (3rd element) ignored if extract_in_2d;
    opt.nb = 1; %nb is used everywhere; default 1; num background components
    opt.low_rank_background = true; % spatial, and patch; #default true; and  #true makes bankground nb, false makes it update with hals, if true with patches, each patch keeps its background, if false, each patch bg approximated with global background
    opt.update_background_components = true; %spatial; #default true; update background components during spatial phase
    opt.merge_thr = 0.85; %merge_components; default 0.85; threshold for merging components
    opt.only_init = false; %default false; only use the initialization for extraction (no updating of spatial and or temporal components, ie no alternating least squares for spatial and temporal refinement)
    opt.normalize_init = true; %init; default true; variance norm by pixel over time befroe initialization;  prob should always be true except for 1p data; patches take care of this to some extent but why not just do it always;
    opt.roidensity = 0.4; %not a caiman option; used to derive K (approximate number of neurons to find), given other options, gSig, and patch or fov size; keep above 0 and less than or equal to 1; 1 is "space filling" (as many neurons as possible given patch or fov size, reoslution, and gsiz); caiman demo does not use this variable, but effectively their demo sets it at 0.33)
    opt.p = 0; %for deconvolution model if 1 or 2, or skipping deconvolution if 0 (skip deconvolution if neuron is nonspiking); order of the autoregressive system - 0 for nonspiking, 1 for instanteous rise but not decay (low sample rate), 2 for non-ionstantaneous rise and decay (higher sample rate)

    % INITIALIZATION
    opt.method_init = 'graph_nmf'; %'greedy_roi' #'graph_nmf' #sparse_nmf; default greedy_roi; greedy_roi looks for globular sources; carl usually does not use greedy_roi
    opt.sigma_smooth_snmf_time = 0.5; %first element of sigma_smooth_snmf, for smoothing in time before initialization; sigma_smooth_snmf default is [0.5, 0.5, 0.5, 0.5], which is txyz std of gaussian smoothing filter applied just before initialization with method_init sparse_nmf or graph_nmf; similar to gSig for method_init greedy_roi, but unlike gSig, values 0-1 and evens do have effect; consider z width, relative to xy width, when setting this; in oex, the xyz elements are assigned the same values as gSig
    opt.perc_baseline_snmf = 20; % default 20; baseline percentile, removed from stack before initialization for method_init graph_nmf and sparse_nmf
    opt.max_iter_snmf = 500; %default 500; number iterations in initialization for method_init graph_nmf and sparse_nmf)

    % for method_init sparse_nmf only
    opt.sparsity_penalty = 0.5; %not a caiman option, but assigned to caiman options alpha_snmf (when using method_init sparse_nmf) and lambda_gnmf (when using method_init graph_nmf); note these have different defaults in caiman (alpha_snmf is 0.5, lambda_gnmf is 1)

    % for method_init graph_nmf only
    opt.SC_sigma = 1; % default 1; std for SC kernel
    opt.SC_thr = 0; % default 0; threshold for affinity matrix
    opt.SC_normalize = 1; % default True; standardize entries prior to computing affinity matrix
    opt.SC_use_NN = 0; % default False; sparsify affinity matrix by using only nearest neighbors
    opt.SC_nnn = 20; % default 20; number of nearest neighbors to use if SC_use_NN = True

    % for method_init greedy_roi only
    opt.rolling_sum = 0; %default false Using rolling sum for initialization (RollingGreedyROI), instead of total sum
    opt.rolling_length = 100; %default 100

    % UPDATE TEMPORAL COMPONENTS AND DECONVOLUTION (USED IN temporal.py AND deconvolution.py)%
    %p belongs in this section, but because it is so important, it was moved above under section "general"
    opt.ITER = 3; % (default is 2; old value=5) -- block coordinate descent iterations
    opt.bas_nonneg = 0; %clip negatives in deconvolution (not the same as clipping negatives in stack); appears to not matter unless you're deconvolving (p is 1 or 2, not 0)
    opt.fudge_factor = 0.96; % (default is 0.96; old value = 1) -- bias correction factor for discrete time constants

    %UPDATE SPATIAL COMPONENTS (USED IN spatial.py, specifically in function threshold_components)%
    %during refinement, in update_spatial, the following params are used in function threshold_components
    opt.thr_method = 'nrg'; %or 'max'
    opt.maxthr = 0.1; %for  thr_method = 'max' keep pixels above this threshold
    opt.nrgthr = 0.9999; %for  thr_method = 'nrg' keep pixels whose sorted cumsum contributes this much of total energy
    opt.extract_cc = 1; %true will throw away isolated pixels of some kind (cc means connected components)

    %PATCHES (USED IN cnmf.py AND map_reduce.py)%
    %low_rank_background also has meaning for patches in run_CNMF_patches, see notes for low_rank_background above
    opt.patchfac = 4; %not a caiman option; how many times larger largest dim of patch is than lagest dim of neuron diameter (ie largest dim of gsiz, since neuron diameter is approximately gsiz); 0 to skip patches, or make it large to do one patch on the full fov (saqme as 0); caiman recommends 3-4 (if not 0);automatically skipped if two_channel_ex (seeded extraction); if fov is smaller than patch, it's just one patch; patches are useful if activity stats vary over fov (e.g. extracting same neurons from regions with varying SNR, patch runs will adapt to local stats)
    opt.stridefac = 2; %not a caiman option; how many times larger largest dim of stride is than lagest dim of neuron diameter (ie largest dim of gsiz, since neuron diameter is approximately gsiz); 0 to skip patches; caiman recommends at least 1 (at least neuron dia) (if not 0);automatically skipped if two_channel_ex (seeded extraction); if fov is smaller than patch, it's just one patch; patches are useful if activity stats vary over fov (e.g. extracting same neurons from regions with varying SNR, patch runs will adapt to local stats)
    opt.nb_patch = 1; %default matches nb; num background components per patch
    opt.deconvolution_in_each_patch = 0; %not a caiman param but used to derive p_patch; this will only have effect if p is nonzero above

    %QUALITY EVALUATION (USED IN evaluate_components)%
    % Each parameter has a low threshold (rval_lowest (default -1), SNR_lowest (default 0.5), cnn_lowest (default 0.1)) and high threshold (rval_thr (default 0.8), min_SNR (default 2.5), min_cnn_thr (default 0.9)).
    % in evaluate_components (called outside cnmf.fit), a component has to exceed ALL low thresholds as well as ONE high threshold to be accepted.
    % can turn off CNN part withy use_CNN = false;
    % these values below were set by carl as scopa defaults result in no roi filtering
    opt.SNR_lowest = 0; % 0.5 % 0 % 0.5 default% minimum SNR for accepted components
    opt.min_SNR = 0; % 0 % 2.5 default% accept components with that peak-SNR or higher
    opt.rval_lowest = -1; % -1 default 0.6% space correlation threshold
    opt.rval_thr = 0; % 0% 0.8 default% space correlation threshold
    opt.use_cnn = 0; % True default% use the CNN classifier affects if 2 below params are used
    opt.cnn_lowest = 0; % 0.1 default% neurons with cnn probability lower than this value are rejected
    opt.min_cnn_thr = 0; % 0.9 default% if cnn classifier predicts below this value, reject
    opt.decay_time = .2; % carl can only find this used in components evaluation (and onacid), approximate length of indicator tau off

    % AUTOMATED MORPH ROI IN extract_binary_masks_from_structural_channel
    opt.morph_min_area_size = 2; %min area (in pixels); only used for cm.base.rois.extract_binary_masks_from_structural_channel, which is only used in two_channel_ex when automated structural rois seed the other channel
    opt.morph_min_hole_size = 0; %holes with smaller area (in pixels) will be filled in; only used for cm.base.rois.extract_binary_masks_from_structural_channel, which is only used in two_channel_ex when automated structural rois seed the other channel
    opt.morph_expand_method = 'closing'; %closing or dilation; only used for cm.base.rois.extract_binary_masks_from_structural_channel, which is only used in two_channel_ex when automated structural rois seed the other channel

    opt2.rgname = 'none'
    opt2.roiname = 'none'
    opt2.och (1,1) {mustBeBinary} = 0 %och means "options check"; 1 to exit function and return nothing but arguments block struct opt (not opt2 or any other name-value arguments struct); 0 to skip och (run function normally), which is default

end

if opt2.och
    if isfield(opt, 'optid')
        opt = rmfield(opt, 'optid');
    end
    roimask = opt;
    return
end

rgname = opt2.rgname;
roiname = opt2.roiname;

pthpy = userdatfile('pthpy', err=1); %path to python executable; only required to run caiman from matlab (if opt.cm is nonempty)
pthscopa = pthscopaget();

if isempty(opt)
    fprintf("user did not pass in options as argument, using all defaults")
    tmp = ofill('roi.cm', rec=1, unpack=1);
    opt = tmp.cm;
end


try %run python directly from matlab (ie not using system command to control a shell)
    petmp = pyenv;
    if ~strcmp(petmp.Executable, pthpy) && ~strcmp(petmp.ExecutionMode, 'OutOfProcess')
        try
            pyenv(ExecutionMode="OutOfProcess")
            pyenv(Version=pthpy)
        catch ME
            fprintf(ME.message + newline)
            fprintf("do not use pyenv in the current matlab session with a different Version or ExecutionMode than those specified here" + newline)
        end
    end
    if count(py.sys.path,pthscopa) == 0
        insert(py.sys.path,int32(0),pthscopa);
    end
    py.extract.extract( ...
        pth_prefix='', ...
        pth_tif_read='', ...
        pth_optdf='', ...
        pth_optroi='', ...
        md=2, ...
        extract_in_2d=0, ...
        methodex='1', ...
        rgname=rgname, ...
        roiname=roiname, ...
        optall=opt ...
        );
catch ME %alternative that uses system command
    fprintf(ME.message + newline)
    fprintf("RUNNING PYTHON DIRECTLY FAILED, USING system TO RUN PYTHON INSTEAD")
    pyfn = [pthscopa 'extract_mat.py'];
    syscmd = [pthpy ' ' pyfn ' ' pthraw ' ' pthmd];
    system(syscmd)
end
