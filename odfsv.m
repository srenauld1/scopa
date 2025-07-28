function odfsv(pthopt)
 
% default options for a2p
% running odfsv writes all options to txt file in scopa using jsonencode (written to file to encourage stability)  

arguments
    pthopt = []
end

pthscopa = pathscopafind();
if isempty(pthopt)
    pthopt = [pthscopa 'optdf.txt'];
end


%% meta (these fields do not allow user input; they get created/modified while creating options struct)

d.copybin = ""; 
d.filled = 0;
d.id = [];
d.nestvalid = [ % all vbins (first line) and nested vbins (following lines, organized by function hierarchy) currently supported in options struct o; options struct will make sure all of these are populated before existing oset; note some vbins are only used nested within others (e.g. mm only exists as roi.mm), but defaults for these can still be called using odf, like to invoke defaults from within the function that uses them e.g. odf('mm', unpack=1)
    "spec", "mn", "daq", "sld", "roi", "bmp", "mdl", "pltx", "fmf", ... %standalone vbins; these vbins only exist from within others: "mm", "ma", "cm", "qc", "nrm", "imhsv", "tp", "sp", "tg"
    "roi.mm", "roi.ma", "roi.cm", "roi.qc", "roi.nrm", "roi.sp", "roi.imhsv", ...   
    "mdl.sp", "mdl.tp", "mdl.opg", "mdl.opl", ...
    "bmp.mdl", "bmp.mdl", "bmp.mdl.sp", "bmp.mdl.tp", "bmp.mdl.opg", "bmp.mdl.opl", ...
    "daq.ftv", ...
    "copybin", "filled", "id", "nestvalid", ... 
    ];



%% spec

d.spec.pthparent_local = '/Users/wienecke/stacks'; %on local machine, full path to folder containing all recording folders
d.spec.pthparent_o2 = ''; %on o2, full path to folder containing all recording folders, leave empty to automatically find path in /n/files/scratch with same parent folder name as o.mn.pthparent_local; ap2 will automatically determine if you're on O2; example path is '/n/scratch/users/c/caw846/stacks/'
d.spec.suffixchar_original = ["o"]; %stack suffix character for original/raw scanimage output files, also first character on processed stacks; for flyg users, except carl, original scanimage output files will not actually have suffix 'o' (they are named with flyg convention); carl renames the flyg/scanimage original files with suffix 'o'; used in stackfind.m to locate stacks  
d.spec.suffixchars = ["r", "d", "b", "s"]; %all valid stack suffix characters output by scopa preprocessing pipeline (pl.py, pl.sh); r=registered, d=denoised, b=background-subtracted, s=scannoise-removed; can appear in any order, multiple times; suffix denotes preprocessing steps applied to stack; suffixchar_original (defined above) can only appear once, at the beginning of the suffix (e.g., ord means registered then denoised, o alone means original/unprocessed); used in stackfind.m to locate stacks    
d.spec.pth = '';  %cell array of char (or scalar char), full path for file(s); if this is used, spec.recdate, spec.fly, spec.trial, spec.suffix are all 'fullpathinput' (rather than their default values); if this is empty (user doens't pass in full path(s) to a2p) then those fields are used and this remains empty
d.spec.recdate = ''; %cell array of char, can use wildcards
d.spec.fly = ''; %cell array of char, can use wildcards
d.spec.trial = ''; %cell array of char, can use wildcards
d.spec.suffix = '';  %cell array of char (or scalar char), can use wildcards, scopa 'pre' pipeline output filename suffix to use in this 'post' pipeline (or 'o' for original tif output by scanimage/flyg, which does not necessarily have filename suffix 'o'); valid suffixes are defined in suffixchars
d.spec.substr = ''; %cell array of char (or scalar char), can use wildcards, substring contained in path to stack (e.g. if all recordings from one campaign are in a subfolder with a descriptive name, you could put that name here, and asterisks for recdate, fly, trial, and get all those recordings just with the substr)
d.spec.match = 'each'; %'any' for all combinations of recdate, fly, trial, suffixstack, 'each' for matched indices of each (length 1 will be repeated to match anything longer)

%% mn (ap2: main pipeline control in a2p)

d.mn.doroi = 0; %do roi extraction
d.mn.dobmp = 0; %model fitting (o.mdl below)
d.mn.dofmf = 0; %model fitting (o.mdl below)
d.mn.dofit = 0; %model fitting (o.mdl below)
d.mn.dopltx = 0; %plot experiment (o.pltx below)

d.mn.usegit = 0;  %1 to use git to sync with scopa remote repository to ensure integration across filesystems (eg for opt files); 0 to skip git
d.mn.dirtmp = 'scopatmp'; %will be created in same dir as stacks, stores small tmp files used in interactive figures; getActiveFilename is problematic on O2 so using this approach instead
d.mn.timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));
d.mn.plt = [""]; %list of subroutines that get plots (none by default); ["daq", "sld", "ftv", "roi", "bmp", "mdl"]
d.mn.pltvis = 1; %1 shows requested plots (o.mn.plt) and saves them, 0 saves but does not show them
d.mn.dmstackdf = 'yxztck'; %default stack dimension order; c is pmt channel, k is rgb channel if truecolor
d.mn.copybindf = 'none'; %default name for copybin (assigned if user did not assign one)
d.mn.optiddf = 'z0'; %if user doesn't use oid to map options sets and variables to optid, optiddf is used instead (in filenames, figures, and struct naming) 
d.mn.ided_vbin = ["sld", "daq", "roi", "bmp", "mdl", "fmf"]; %vbin that can be mapped to ids; only these vbin can be distributed (odist) and mapped to id (since they are the most option-dependent, user-may want to explore options easily, and also their options can be set simply without requiring complex encoding/decoding between matlab/python, or into and out of txt file; 
d.mn.inert_vbin = ["sp", "tp", "imhsv", "tg", "savemem", "optid"]; %vbin or options that have no functional effect (set to empty in txt files recording options, and not considered when deriving optid)

d.mn.scopausername = 'youforgottossetuser';

d.mn.pthpy = ''; %path to python executable  

%% daq (daqld: load, process daq)

d.daq.vtime = ["Time", "time", "T", "t"]; %list possible names for the time variable in the raw daq file; one and only one of these must exist in the raw daq file, otherwise error
d.daq.vnormal = ["Time", "heat", "virmenIteration"]; % list possible normal (not circular, not categorical) daq variables you want to process; if any of these don't exist, they are ignored (will not error); virmenIteration is averaged by imaging frame, output is converted to frame number in the usual way
d.daq.vradians = ["ficTracIntSide", "ficTracIntForward", "ficTracYaw", "ficTracHeading", "g4panels", "g4yaw"]; % list possible circular daq variables you want to process (must be in radians); if any of these don't exist, they are ignored (will not error); 
d.daq.vdegrees = [""]; % list possible circular daq variables you want to process (must be in radians); if any of these don't exist, they are ignored (will not error); 
d.daq.vcategorical = ["ftcam", "cameraFrameClock", "epoch", "g4vel", "g4velnom"]; % list possbile categorical or integer daq variables you want to process; if any of these don't exist, they are ignored (will not error); 
d.daq.tomm = ["ficTracIntSide", "ficTracIntForward"]; %list which vars to unwrap, then make start at zero, then rescale from radians to mm
d.daq.useinds = 'none'; % 'none', 'slice', 'vol', 'all', or numeric vector of slice indices, with optional 0 to mean volume indices; 'none' (resample using 'resample' function with padding to avoid start/end transients), 'slice' (resample using all slice indices), 'vol' (resample using volume indices), 'all' (resample using all slice indices and volume indices), numeric vector defines which slice indices (one indexed) to use with 0 denoting volume index resampling (eg [0 4] will resample with volume and slice 4); 'none' is fastest but has a little more aliasing, which is probably rarely a problem; slice resampling is included especially for slow imaging rate, or large flyback; the more resampling registers are used, the slower this function on first run (output is saved/loaded for subsequent runs)
d.daq.supprate = []; % supplemental downsampling rate (in addition to main downsampling into imaging rate); empty to skip; for supplemental resampling, useinds is effectively 'none' (uses resample function, since there is no daq record of indices at the supplemental rate, but if there were, for example, a record of each fictrac sample on the daq, this could be used for the resampling, and then there would need to be a useinds_supp option) 
d.daq.slopelensec = 0.4; % window length in seconds used to fit slope to each daq variable (to compute their derivatives, ie velocities); make empty to have this derived automatically (in tsdv) to be as short as possible, given sample rate and slopeord
d.daq.slopeord = 2; % order of polynomial used to fit local slope
d.daq.slopelensec_supp = 0.4; % same as slopelensec but for supplemental resampling rate (supprate, if nonempty)
d.daq.slopeord_supp = 2; % same as slopeord but for supplemental resampling rate (supprate, if nonempty)
d.daq.usefbl = 1; % whether to include flyback lines when resampling with frame indices (if useinds is not 'none')
d.daq.usefbf = 1; % whether to include flyback frames when resampling with volume indices (if useinds is not 'none')
d.daq.balldia = 9; % mm, used to convert fictrac variables into mm
d.daq.voltmin = 0; % daq voltage min; would be better to have this in metadata
d.daq.voltmax = 10; % daq voltage max, need to find this in metadata
d.daq.voltminyaw = 1/12 * 2*pi; %yaw position assigned to voltmin and voltmax (on bergI, it is fly's 1 o'clock, and target range is -pi to pi, hence 1/12) 
d.daq.vrenm = [  %string array; each element is "newname: oldnames", where newname is one name, oldnames is comma separated list of names; newname will be fieldname within new, saved struct 'daq', containing daq data resampled/aligned with imaging; oldnames are all possibilities for names of variable written to raw daq file that are to be renamed with new name; for each new name, if old name exists it gets new name, and if no old name exists the new name is given empty value; if you are running a2p, do not change the newnames
    "t: Time, time, T, t";
    "epochts: epoch";
    "vyvnom: g4vel, g4velnom";
    "vy: g4panels, g4yaw";
    "vyv: g4panels_dv, g4yaw_dv";
    "bf: ficTracIntForward";
    "bfv: ficTracIntForward_dv";
    "bs: ficTracIntSide";
    "bsv: ficTracIntSide_dv";
    "by: ficTracYaw, ficTracHeading";
    "byv: ficTracYaw_dv, ficTracHeading_dv";
    "ftcam: ftcam"]; 

%% spr (stackseries: plot stacks from different stages of preprocessing)

d.spr.suffixplt = [ d.spec.suffixchars ]; %stack suffixes to plot together in a gif; default tries to plot all d.spec.suffixchars; nonexistent or invalid suffixes are ignored; these stacks are also converted from tif to mat (along with d.spec.suffix, in case user doesn't list it here)

%% sld (stackld: load/process stack from tif / save to mat )

d.sld.fbrm = 1; %crop flyback frames from each volume, if they exist, before saving to mat
d.sld.trm = []; %how many samples to remove from [start, end] of stack, before saving to mat; empty to skip; similar to cropdata in rec6 (also applied in metrics2 without variable name cropdata), crop first 4 and last 2 imaging frames (stimulus features, and deprecated responses, have been extracted with this cropping in rec6)
d.sld.iy = []; %y indices to keep and save to mat
d.sld.ix = []; %x indices to keep and save to mat
d.sld.ic = []; %c indices to keep and save to mat; this is stack channel index (5th dimension in the stack); this is not pmt index; for example, 2 will error if pmt channel 2 was the only saved channel, because the channel index for that channel is 1; empty to keep all; will error if you request channel that doens't exist
d.sld.iz = []; %z indices to keep and save to mat
d.sld.it = []; %t indices to keep and save to mat 
d.sld.zerostack = 1; %subtract min to make min zero
d.sld.clip = [0,1];  %(1,2) vector, range 0-1, clip quantile for stack, [0,1] does no clipping; or scalar -1 to set all negatives to zero
d.sld.stackdtype = 'uint16';
d.sld.smlenpx = [0, 0, 0]; %spatial yxz window length (in pixels) for smoothdata (default gaussian method); for each dimension, yxz, gaussian sd is one-fifth corresponding entry in smlenpx; [0 0 0] or empty to skip; 0 will skip smoothing in corresponding dimension (eg [3 3 0] skips smoothing in z)
d.sld.smlensec = 0; %tenporal window length (in seconds) for smoothdata (default gaussian method); gaussian sd is one-fifth smlensec seconds; 0 to skip
d.sld.smmthd = 'gaussian'; %any single valid input for name-value argument 'method' to matlab builtin function 'smoothdata', or cell with sequence of them, to apply smoothing methods in sequence (e.g.,  {'gaussian', 'movmedian'})
d.sld.savemem = 0; %1 will use tiffstack (memmap stack, can save memory if you want to read subset of stack with inds_*_read_from, but usually slower, and also uses mex code that might break on some os/versions/platforms; 0 will use tifreadfast (usually faster, but doens't memmap, reads entire stack into memory initially (or at best a subset of "frames" which are collapsed czt dimensions, so not useful for saving memory if you don't have metadata already to correctly form those indices (maybe a todo)

%% ftv (ftvpr: load, align, resample fictrac video, hack that is only useful if video framees are not on daq)

d.ftv.numpkthr = 10; %in laser oscillation timeseries, number of contiguous peaks with periodic distance to be considered the start of the imaging trial, and also the end when applied in the reverse direction; this could just be same as numvol, but in case there are missing peaks, making this number smaller . . . max would be  round(numvol*0.8)
d.ftv.smlenpx = 2; %window length for gaussian smoothing filter applied to average frame of fictrac video, prior to finding the brightest pixels (to locate laser)
d.ftv.smlensec = 1; %window length for gaussian smoothing filter applied to laser timeseries, to help denoise timeseries prior to findpeaks (to help find the true laser oscillation peaks)
d.ftv.numpx = 10; %after spatial smoothing, number of pixels to average on each frame of fictrac video; these are the brightest 'numpx' pixels in the mean frame of fictrac video

%%  (roimake: draw and/or automatically segment morphological rois, extract and normalize their responses)

d.roi.rgname = 'none'; %default rgname name 'none' automatically gets full fov rg; user is not prompted to create one in this case
d.roi.domm = 0; %do "morph manual"; if true, draw rois in an interactive plot, and save, (or load if already drawn and saved), if false, skip drawing
d.roi.doma = 0; %do "morph auto"; if true, automatically segment drawn rois (or if none, full fov)
d.roi.docm = 0; %do caiman extract.py; if true, load caiman rois with rgname in filename
d.roi.doqc = 0; %do quality control (remove bad rois)

%% mm (roidraw: mm = "morphological manual")

d.mm.maskname = ['none']; %empty to skip; string array of names for roi mask(s) drawn on the same rgname
d.mm.methodmm = ['all']; %'1', '2', 'all', '1cp', '2cp'; '1' draws on first channel (stack index 1 in 5th dimension), '2' draws on second channel (stack index 2 in 5th dimension), 'all' draws on all available channels (whether 1 or 2 channel), '1cp' copies what is drawn on channel 1 onto channel 2; '2cp' copies what is drawn on channel 2 onto channel 1 

%% ma (roimauto: ma = "morphological automated", automated morphological roi extraction, can be applied to drawn rois (or not))

d.ma.chan = 1; %1, 2, or [1 2], which channel gets auto roi extraction; this is stack index, not pmt index; (for now all options below are same for each) option where auto rois interact has not been written yet);
d.ma.numroi = 128; %partition rgname into num_roim_auto morphological rois; a drawn roi, if it exists, masks the rgname prior to automated super-roi extraction; num_roim_auto and number drawn rois cannot both exceed 1 (i.e. the code cannot automatically partition discontiguous rois within a single rgname)
d.ma.maskmake = 'nonzero'; % %method for automatically defining morphological roi mask (union of all morphological rois) from stack or union of manually drawn rois, options are 'edge', 'outlier', 'triangle', 'nonzero'
d.ma.maskseg = 'uniform'; %'skeleton' for elongated structures or 'uniform'; method for subsampling mask into rois; for 'uniform', o.roi.ma.num_roim_auto_str must be power of 2 and works best for convex structures since for concave structures it will find rois outside the structure but can be masked to remove orois outside the structure afterward
d.ma.roirad = []; %radius of roi (circle if 2d, sphere if 3d) centered on roi centroid; make this empty to have voxels mapped to roi centroid using euclidian distance; units are length of pixel in x (if z length is double x and y length, roirad 6 is 2 pixels in x and y, and 1 in z)
d.ma.edgethr = [0.1, 0.7]; %two thresholds to detect strong and weak edges; includes weak edges in output only if they are connected to strong edges
d.ma.edgesig = [3, 3, 3]; %for edge detection, defines smoothing filter sigma for each dim xyz, or use one value for all dim, if 2d edge detection, first element is used for x and y
d.ma.celsz = 8; %for bwmorph close after edge detection, helps connect edges
d.ma.do3d = 1; %1 makes 3d mask unless stack is 2d, 0 makes 2d mask for 2d, 3d, or 4d stack input

%% cm (roifauto: cm = "caiman"; load, process, cluster, normalize functional rois/responses output by caiman in extract.py; option names here match option names in map2opt, and their counterparts in oex)

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

% MAIN
d.cm.methodex = '1'; %see notes on methodex above
d.cm.gSig = [2, 2, 0.5]; %approximate xyz half-size, in pixels, of average neurons; z ignored if extract_in_2d; later, forced to be odd when creating gsiz, so min gsiz is 3; any number 0-1 has same effect as 1, but since gSig is used to derive sigma_smooth_snmf, which is not clipped to 1, go ahead and use the real value; also, consider that our z are often much larger than xy when you set this, so if neurons are restricted to single z planes, make this 1 (since gsig unit is pixels); z (3rd element) ignored if extract_in_2d;
d.cm.nb = 1; %nb is used everywhere; default 1; num background components
d.cm.low_rank_background = true; % spatial, and patch; #default true; and  #true makes bankground nb, false makes it update with hals, if true with patches, each patch keeps its background, if false, each patch bg approximated with global background
d.cm.update_background_components = true; %spatial; #default true; update background components during spatial phase
d.cm.merge_thr = 0.85; %merge_components; default 0.85; threshold for merging components
d.cm.only_init = false; %default false; only use the initialization for extraction (no updating of spatial and or temporal components, ie no alternating least squares for spatial and temporal refinement)
d.cm.normalize_init = true; %init; default true; variance norm by pixel over time befroe initialization;  prob should always be true except for 1p data; patches take care of this to some extent but why not just do it always;
d.cm.roidensity = 0.4; %not a caiman option; used to derive K (approximate number of neurons to find), given other options, gSig, and patch or fov size; keep above 0 and less than or equal to 1; 1 is "space filling" (as many neurons as possible given patch or fov size, reoslution, and gsiz); caiman demo does not use this variable, but effectively their demo sets it at 0.33)
d.cm.p = 0; %for deconvolution model if 1 or 2, or skipping deconvolution if 0 (skip deconvolution if neuron is nonspiking); order of the autoregressive system - 0 for nonspiking, 1 for instanteous rise but not decay (low sample rate), 2 for non-ionstantaneous rise and decay (higher sample rate)

% INITIALIZATION
d.cm.method_init = 'graph_nmf'; %'greedy_roi' #'graph_nmf' #sparse_nmf; default greedy_roi; greedy_roi looks for globular sources; carl usually does not use greedy_roi
d.cm.sigma_smooth_snmf_time = 0.5; %first element of sigma_smooth_snmf, for smoothing in time before initialization; sigma_smooth_snmf default is [0.5, 0.5, 0.5, 0.5], which is txyz std of gaussian smoothing filter applied just before initialization with method_init sparse_nmf or graph_nmf; similar to gSig for method_init greedy_roi, but unlike gSig, values 0-1 and evens do have effect; consider z width, relative to xy width, when setting this; in oex, the xyz elements are assigned the same values as gSig
d.cm.perc_baseline_snmf = 20; % default 20; baseline percentile, removed from stack before initialization for method_init graph_nmf and sparse_nmf
d.cm.max_iter_snmf = 500; %default 500; number iterations in initialization for method_init graph_nmf and sparse_nmf)

% for method_init sparse_nmf only
d.cm.sparsity_penalty = 0.5; %not a caiman option, but assigned to caiman options alpha_snmf (when using method_init sparse_nmf) and lambda_gnmf (when using method_init graph_nmf); note these have different defaults in caiman (alpha_snmf is 0.5, lambda_gnmf is 1)

% for method_init graph_nmf only
d.cm.SC_sigma = 1; % default 1; std for SC kernel
d.cm.SC_thr = 0; % default 0; threshold for affinity matrix
d.cm.SC_normalize = 1; % default True; standardize entries prior to computing affinity matrix
d.cm.SC_use_NN = 0; % default False; sparsify affinity matrix by using only nearest neighbors
d.cm.SC_nnn = 20; % default 20; number of nearest neighbors to use if SC_use_NN = True

% for method_init greedy_roi only
d.cm.rolling_sum = 0; %default false Using rolling sum for initialization (RollingGreedyROI), instead of total sum
d.cm.rolling_length = 100; %default 100

% UPDATE TEMPORAL COMPONENTS AND DECONVOLUTION (USED IN temporal.py AND deconvolution.py)%%%%%%%%%%%%
%p belongs in this section, but because it is so important, it was moved above under section "general"
d.cm.ITER = 3; % (default is 2; old value=5) -- block coordinate descent iterations
d.cm.bas_nonneg = 0; %clip negatives in deconvolution (not the same as clipping negatives in stack); appears to not matter unless you're deconvolving (p is 1 or 2, not 0)
d.cm.fudge_factor = 0.96; % (default is 0.96; old value = 1) -- bias correction factor for discrete time constants

%UPDATE SPATIAL COMPONENTS (USED IN spatial.py, specifically in function threshold_components)%%%%%%%%%%%%
%during refinement, in update_spatial, the following params are used in function threshold_components
d.cm.thr_method = 'nrg'; %or 'max'
d.cm.maxthr = 0.1; %for  thr_method = 'max' keep pixels above this threshold
d.cm.nrgthr = 0.9999; %for  thr_method = 'nrg' keep pixels whose sorted cumsum contributes this much of total energy
d.cm.extract_cc = 1; %true will throw away isolated pixels of some kind (cc means connected components)

%PATCHES (USED IN cnmf.py AND map_reduce.py)%%%%%%%%%%%%
%low_rank_background also has meaning for patches in run_CNMF_patches, see notes for low_rank_background above
d.cm.patchfac = 4; %not a caiman option; how many times larger largest dim of patch is than lagest dim of neuron diameter (ie largest dim of gsiz, since neuron diameter is approximately gsiz); 0 to skip patches, or make it large to do one patch on the full fov (saqme as 0); caiman recommends 3-4 (if not 0);automatically skipped if two_channel_ex (seeded extraction); if fov is smaller than patch, it's just one patch; patches are useful if activity stats vary over fov (e.g. extracting same neurons from regions with varying SNR, patch runs will adapt to local stats)
d.cm.stridefac = 2; %not a caiman option; how many times larger largest dim of stride is than lagest dim of neuron diameter (ie largest dim of gsiz, since neuron diameter is approximately gsiz); 0 to skip patches; caiman recommends at least 1 (at least neuron dia) (if not 0);automatically skipped if two_channel_ex (seeded extraction); if fov is smaller than patch, it's just one patch; patches are useful if activity stats vary over fov (e.g. extracting same neurons from regions with varying SNR, patch runs will adapt to local stats)
d.cm.nb_patch = 1; %default matches nb; num background components per patch
d.cm.deconvolution_in_each_patch = 0; %not a caiman param but used to derive p_patch; this will only have effect if p is nonzero above

%QUALITY EVALUATION (USED IN evaluate_components)%%%%%%%%%%%%
% Each parameter has a low threshold (rval_lowest (default -1), SNR_lowest (default 0.5), cnn_lowest (default 0.1)) and high threshold (rval_thr (default 0.8), min_SNR (default 2.5), min_cnn_thr (default 0.9)).
% in evaluate_components (called outside cnmf.fit), a component has to exceed ALL low thresholds as well as ONE high threshold to be accepted.
% can turn off CNN part withy use_CNN = false;
% these values below were set by carl as scopa defaults result in no roi filtering
d.cm.SNR_lowest = 0; % 0.5 % 0 % 0.5 default% minimum SNR for accepted components
d.cm.min_SNR = 0; % 0 % 2.5 default% accept components with that peak-SNR or higher
d.cm.rval_lowest = -1; % -1 default 0.6% space correlation threshold
d.cm.rval_thr = 0; % 0% 0.8 default% space correlation threshold
d.cm.use_cnn = 0; % True default% use the CNN classifier affects if 2 below params are used
d.cm.cnn_lowest = 0; % 0.1 default% neurons with cnn probability lower than this value are rejected
d.cm.min_cnn_thr = 0; % 0.9 default% if cnn classifier predicts below this value, reject
d.cm.decay_time = .2; % carl can only find this used in components evaluation (and onacid), approximate length of indicator tau off

% AUTOMATED MORPH ROI IN extract_binary_masks_from_structural_channel
d.cm.morph_min_area_size = 2; %min area (in pixels); only used for cm.base.rois.extract_binary_masks_from_structural_channel, which is only used in two_channel_ex when automated structural rois seed the other channel
d.cm.morph_min_hole_size = 0; %holes with smaller area (in pixels) will be filled in; only used for cm.base.rois.extract_binary_masks_from_structural_channel, which is only used in two_channel_ex when automated structural rois seed the other channel
d.cm.morph_expand_method = 'closing'; %closing or dilation; only used for cm.base.rois.extract_binary_masks_from_structural_channel, which is only used in two_channel_ex when automated structural rois seed the other channel


%% qc (quality control rois)

d.qc.minpixperreg = 3; % min pix in each distongiguous region, roi selection criterion
d.qc.minroisz = 5; % pixels, roi selection criterion
d.qc.maxroisz = 300; % pixels
d.qc.maxregperroi = 4; % for discontiguous rois
d.qc.inmaskthr = 0.5; % discard roi if more than inmaskthr is outside morphological mask (morph mask is all ones if you don't make one)


%% nrm (roits: extract and/or normalize roi timeseries)

% options for extraction/normalization of roi signals
% standard normalizations (e.g. rescaling, z-scoring, dff, box-cox) are handled by nrm.pre and nrm.post, 
% all normalizations are applied to individual vector timeseries
% normalization strings are listed below; they can be combined arbitrarily; if combined, they are applied left to right order (eg 'nnbox' applies 'nn' then 'box'):
    % 'f': no normalization
    % 'dffuuuvvv': dff; vvv is sliding window length in seconds over which f0 is computed; if vvv is 000, f0 is computed across the entire timeseries, not a sliding window; uuu is percentile to compute f0 for each window (e.g. dff010008 is 10th percentile over 8-seconde sliding window, dff001000 is 1st percentile over entire timeseries)
    % 'rscxxxyyy': rescale, sending xxx percentile to 0, yyy percentile to 1 (eg rsc000100 is same as default matlab rescale function)
    % 'z': zscore
    % 'nn': nonnegative (subtract min)
    % 'box': box-cox

d.nrm.pre = 'f'; %must have at least one string, compsed of syllables above; % precluster normalization is applied before clustering (i.e. normalization of each pixel in roi, or subroi within a larger roi)
d.nrm.post = 'f'; %must have at least one string, compsed of syllables above; postcluster normalization is applied after clustering (ie to each roi)
d.nrm.degdtr = 0; %polynomial for detrending before normalization; 0 to skip detrending; wavp detrends by default
d.nrm.wavp = []; %[0.3 50]; %(n,2) array denoting wavelet filtering min and max period (seconds); if n>1, will use last row in output by default (n>1 is really for exploration, plotting to see how different periods affect output); empty to skip; 0 in first column will not apply lower period threshold; any number larger than max valid period (determined in wavflt) will not apply upper period threshold, but [0 inf] (or 0 and any giant number) is not the proper way to skip wavelet filtering because the algorithm will still be applied (ie timeseries will be unchanged except mean will be lost, pointlessly), so use [] to skip wavelet filtering
d.nrm.channorm = 0; %work in progress; 0 to skip; leave as 0 for now; which channel to normalize the other with (dampen time-frequency regions of high wavelet coherence)
d.nrm.mincoh = 0.3; %work in progress; min coherence for channorm


%% bmp (bmpmake: compute bump)

% options for bump in bmpmake function
% a von mises is fit to the instantaneous relationship between each roi timeseries (given by all matches from o.bmp.mdl.tg.v1) and all matches from o.bmp.mdl.tg.v2
% the value of the independent variable at the max predicted response is the preferred heading for each roi
% if o.bmp.domaintypeis 'functional', these preferred headings are used as the angle, and o.bmp.mdl.tg.v1 as the magnitude, in computing pva
% if the rgname in o.bmp.mdl.tg.v1 is in o.bmp.numangrs, and that rgname is followed by hyphen and number greater than zero, these preferred heading angles are resampled into that number, so that the rois evenly sample range 0-2pi (resampling changes angle and magnitude)
% if o.bmp.domaintypeis 'morphological', angle is forced to be 0-2pi, with each roi evenly sampling that range

d.bmp.indv = struct('tg', []);
d.bmp.depv = struct('tg', []);
d.bmp.domtype = 'm'; %'f' (functional) to define circular domain with fit to each roi, or 'm' (morphological) to define as circle across region mask
d.bmp.numcirc = 1; %number of circles (eg 1 for eb, 2 for pb), if pb, always use 2 because you can subset with argument 'scope' below
d.bmp.mthd = 'pva'; %'pva' for vector average, pvas for signed vector average, vm for fit von mises to activity across all roi at each sample
d.bmp.scope = 'all'; %which part of compass to use in computing bump parameters, using anything but 'all' doesn't make much sense uunless you have a 2-circle structure, like pb; cell array of char, 'all', 'right', 'left', 'max', 'random', or a digits (numeric or text) denoting left half percentage weight (right will be 100-left)
d.bmp.slopeord = 2; %order of polynomial used to fit local slope (e.g. to compute bump speed)
d.bmp.slopelensec = 0.4; %order of polynomial used to fit local slope (e.g. to compute bump speed)
d.bmp.smlensec = 0; %full width of gaussian smoothing window (5 times std)
d.bmp.numangrs = 16; %how many clusters/superrois across the entire region (not hemisphere) when resampled uniformly prior to computing bump as vector average
d.bmp.maxangrs = 8; %max number resolvable ("unaliased") angles in resampled output (ie 1/maxangrs) is highest frequency you wish to capture in output)d.bmp.smfac = 1; %when resampling compass, bandwidth of the antialiasing filter, larger number will have smoother resampled compass
d.bmp.dorescale = 0; %just before computing bump, rescale each cluster's timeseries to range 0-1
d.bmp.omitnan = 1; %ignore nans in case there are any (e.g., making hybrid morph-func rois, some morph rois have no func members, making their response 'nan', omit will ignore this in computing pva)

%% mdlmake (mdlmake: fit model, depv as function of indv)
 
d.mdl.indv = struct('tg', []);
d.mdl.depv = struct('tg', []);
d.mdl.epochnum = 1;
d.mdl.lagsec = 0; %0 is one sample, how many samples indv precedes depv for model fit . . . for now, must be nonnegative integers, range 0 to lenfit_samp-1
d.mdl.lensec = 0; %seconds, 0 is one sample
d.mdl.epochmix = 0; %1 to keep multi-timepoint model samples that have multiple epochs
d.mdl.valnum = 0; %applied to all mdlnames; k in k-fold cross-validation; k non-overlapping validation sets; if numbouts of each epoch in epochnum is divisible by valnum, will validate on numbouts/valnum bouts for each epoch in epochnum; if only one bout for each epoch, will evenly split each bout into k validation sets; otherwise will error; 0 skips validation
d.mdl.valsplit = 'boutsamples'; %'samples' or 'bouts' or 'boutsamples' %applied to all mdlnames; k in k-fold cross-validation; k non-overlapping validation sets; if numbouts of each epoch in epochnum is divisible by valnum, will validate on numbouts/valnum bouts for each epoch in epochnum; if only one bout for each epoch, will evenly split each bout into k validation sets; otherwise will error; 0 skips validation
d.mdl.slvrg = 'globalsearch';
d.mdl.max_iter_global = 3; %this will not be assigned to globalsearch object d.opg; instead is used in output function for optimization problem, to stop optimization
d.mdl.slvrl = 'fmincon'; %'lsqcurvefit';
d.mdl.mdlname = 'fnet_A01_s'; %'svd' or fnet string (see docs_mdlname.m)
d.mdl.rm = []; %options for removing samples
d.mdl.nrmi = []; %'minmaxcnt'; %'minmax' range [0,1], 'minmaxcnt' range [-1,1], 'zscore' mean 0 unit var, 'none' . . . normalization used in fitting model but not all plotting . . . don't forget mse sensitive to scale
d.mdl.nrmd = []; %'minmaxcnt'; %'minmax' range [0,1], 'minmaxcnt' range [-1,1], 'zscore' mean 0 unit var, 'none' . . . normalization used in fitting model but not all plotting . . . don't forget mse sensitive to scale

%% global solver options

if strcmp(d.mdl.slvrg, 'globalsearch')
    d.opg = GlobalSearch; %globalsearch can only use fmincon
else
    error("mdlmake currently only supports globalsearch")
end

%these are defaults for scopa, but are not the defaults output by optimoptions 
d.opg.StartPointsToRun = 'bounds-ineqs'; 

%these are the defaults output by calling GlobalSearch, contained in d.opg (except any updates above, shown here for convenience)
% d.opg.NumTrialPoints = 1000; %1000
% d.opg.BasinRadiusFactor = 0.2; %0.2000
% d.opg.DistanceThresholdFactor = 0.75; %0.7500
% d.opg.MaxWaitCycle = 20; %20
% d.opg.NumStageOnePoints = 200; %200
% d.opg.PenaltyThresholdFactor = 0.2; %0.2000
% d.opg.Display = 'final'; %'final'
% d.opg.FunctionTolerance = 1e-6; %1.0000e-06
% d.opg.MaxTime = Inf; %Inf
% d.opg.OutputFcn = []; %[]
% d.opg.PlotFcn = []; %{@gsplotbestf, @gsplotfunccount}; %[]
% d.opg.StartPointsToRun = 'all'; %'all'
% d.opg.XTolerance = 1e-6; %1.0000e-06

%% local solver options


if strcmp(d.mdl.slvrl, 'fmincon')
    d.opl = optimoptions(d.mdl.slvrl);
else
    error("mdlmake currently only supports local solver fmincon")
end


%these are defaults for scopa, but are not the defaults output by optimoptions 
d.opl.Display = 'iter-detailed';
d.opl.FiniteDifferenceType = 'central';
% d.opl.MaxFunctionEvaluations = Inf;
% d.opl.MaxIterations = 10000;
d.opl.OutputFcn = [];

% these are the defaults output by optimoptions, contained in d.opl (except any updates above, shown here, commented out, for convenience)
% d.opl.Algorithm = 'interior-point'; %algorithm chosen automatically?? . . . was using 'Algorithm', 'interior-point'); % https://www.mathworks.com/help/optim/ug/choosing-the-algorithm.html
% d.opl.BarrierParamUpdate = 'monotone';
% d.opl.CheckGradients = false;
% d.opl.ConstraintTolerance = 1.0000e-06;
% d.opl.Display = 'final'; %'final'; %iter-detailed
% d.opl.EnableFeasibilityMode = false;
% d.opl.FiniteDifferenceStepSize = 'sqrt(eps)';
% d.opl.FiniteDifferenceType = 'forward'; 
% d.opl.HessianApproximation = 'bfgs';
% d.opl.HessianFcn = [];
% d.opl.HessianMultiplyFcn = [];
% d.opl.HonorBounds = 1;
% d.opl.MaxFunctionEvaluations = 3000; %3000 for interior-point, 100*numvariables for others
% d.opl.MaxIterations = 1000; %1000 for interior-point, 400 for others
% d.opl.ObjectiveLimit = -1.0000e+20;
% d.opl.OptimalityTolerance = 1.0000e-06;
% d.opl.OutputFcn = [];
% d.opl.PlotFcn = [];
% d.opl.ScaleProblem = false; %false
% d.opl.SpecifyConstraintGradient = 0;
% d.opl.SpecifyObjectiveGradient = 0;
% d.opl.StepTolerance = 1.0000e-10; %set to zero, along with OptimalityTolerance, to force fminncon to run specified number of iterations in MaxIterations
% d.opl.SubproblemAlgorithm = 'factorization';
% d.opl.TypicalX = 'ones(numberOfVariables,1)';
% d.opl.UseParallel = 0;

%% tg (tsget: get timeseries, using various filters to choose from all saved variables in filesystem)

d.tg.recid = 'curr';
d.tg.stackid = 'curr';
d.tg.optid = [];
d.tg.vbin = [];
d.tg.vnm = [];
d.tg.ii = [];
d.tg.it = [];
d.tg.ic = [];
d.tg.group = '1';
d.tg.group2 = '1';

%% pltx (pltx: explore various components of experiment in interactive plots, e.g. brain images, timeseries, stimulus videos, scatterplots, fictive path, model components)

d.pltx.vpmapl = [1, 2, 3, 4]; %map of indices of each tg.v above to plot positions (on left axis)
d.pltx.vpmapr = [5, 6, 7, 8]; %map of indices of each tg.v above to plot positions (on right axis)

d.pltx.lagsxy_sec = [0, 0, 1, 0]; %lags for interactive scatterplot;  %empty or zero to skip; scalar or vector; seconds of lag, rounded to nearest frame; repeated frames are omitted; to see all frames within range, bookend with zeros, eg [0, 1, 2, 0] is all samples in range 1-2 (done this way to prevent using cell, since cell sare for opt expansion)
d.pltx.lagsz_sec = [0, 0, 1, 0]; %same as lagxy_sec, except z lags are applied for each xy lag (xy vars are lagged, then together lagged relative to z); will be automatically set to 0 if there is no z variable
d.pltx.lags_to_plot = 'best'; % 'zero', 'best', 'zeroandbest', 'all'
d.pltx.plot_z_as_color = 1; %if z variable exists, 0 will make 3d scatterplot, 1 will make 2d with z variable as color

d.pltx.epochnum = 1; %cell array of vectors or scalars listing epochs (within single trial) to group in scatterplots, empty cell with empty vector for all epochs, like this {[]}

d.pltx.iz = []; %z indices to plot, empty for all, negative for that number equidistant from all available
d.pltx.it = []; %[3320]; %t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
d.pltx.dr = [0,1];
d.pltx.doui = 1;

%% tp (tsplt: plot timeseries)

d.tp.predlot_norm = 'each'; %amplitude normalization for the detail plots at bottom, 'all' normalizes to population, 'each' normalizes to each
d.tp.maxnumroiplot = 100; %number of rois that get detail view on the bottom, one per gif frame
d.tp.sort_method = 'unbiased'; %'majoraxis', 'unbiased', 'gof', 'custom'; %how to select rois for detail plots, 'unbiased' for equidistant maxnumroiplot, 'gof' for equidistant maxnumroiplot sorted by gof in descending order (so starts with best fit ends with worst)
d.tp.max_tinds = 1000; %1000; %for the timeseries view of depv, how many samples to plot at the most (will take indices 1:max_tinds), big number to plot all
d.tp.timeseries_numsegments = 3; %how many equispaced segments to display in setail view, ending at final frame

%% sp (stackplt: plot stack with various viewing options)

d.sp.it = [-100];%t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments (where segments are equidistant, if possible)
d.sp.iz = []; %z indices to plot, empty for all, negative for that number equidistant from all available
d.sp.dr = [0,1]; %display range (contrast)
d.sp.ir = []; %scalar/vector; which rois to plot in ; empty to skip
d.sp.roi_color = [1, 0, 0]; %color for rois, if shown
d.sp.roialpha = 0.3; %transparency for rois, if shown


%% imhsv (hsvplt and hsvcmp: make and plot hsv images)

d.imhsv.fg = 'allrois'; %'eachroi' plots each individually, 'allrois' plots all together
d.imhsv.mdlname = ''; %string for swithcing among plotting defaults in plots_setup_hsv, leave empty for default set
d.imhsv.huestr = ''; %deprecated variable, leave empty
d.imhsv.huenorm = 'native'; %hue normalization method, 'native' normalizes to a preset range (hard coded in plots_setup_hsv) according to 'mdlname', 'relative' normalizes to the data range assigned to hue, 'manual' normalizes to the range set below in imhsv.hrange_in_manual; if you request 'native' but don't pass in huelimnat to hsvcmp it will switch to 'relative'; if you request 'manual' but don't set hrange_in_manual it will switch to 'relative'
d.imhsv.satnorm = 'relative'; %sat normalization method, same logic as huenorm
d.imhsv.valnorm = 'relative';%val normalization method, same logic as huenorm
d.imhsv.hrange_in_manual = []; %manual range for normalizing hue, prior to normalization to plot scale, whose max range is [0 1]), see hsvcmp
d.imhsv.srange_in_manual = []; %manual range for normalizing sat, prior to normalization to plot scale, whose max range is [0 1]), see hsvcmp
d.imhsv.vrange_in_manual = []; %manual range for normalizing val, prior to normalization to plot scale, whose max range is [0 1]), see hsvcmp
d.imhsv.hrange_out_manual = [0, 0.6]; %[0.25 1]; %hue plot scale, whose max range is [0 1] hue hange around color circle, defaults to less than full circle for non-periodic plotting domain, but overwrites in plots_setup_hsv to [0 1] when plotting a periodic huefeature (e.g. von mises center, ie mdlname 'v' with huestr 'loc'), see hsvcmp
d.imhsv.srange_out_manual = [0, 1]; %sat plot scale, whose max range is [0 1], if you want to force saturation you can reduce (e.g. [0 0.75] will force smaller range to max saturation, see hsvcmp
d.imhsv.vrange_out_manual = [0, 1];  %val plot scale, whose max range is [0 1], if you want to force value you can reduce (e.g. [0 0.75] will force smaller range to max value, see hsvcmp
d.imhsv.hueshift = 0; %0-1, circularly shift the hue map around the color circle for change to arbitrary color assignment, applied before any clipping due to, see hsvcmp, this works for periodic or non-periodic features assigned to hue
d.imhsv.ignorehue = 0; %when creating and plotting variable 'img', which is built from variable 'hsvmap', 1 ignores hue in variable 'hsvmap', makes constant 1, but does not change 'hsvmap'
d.imhsv.ignoresat = 0;  %when creating and plotting variable 'img', which is built from variable 'hsvmap', 1 ignores sat in variable 'hsvmap', makes constant 1, but does not change 'hsvmap'
d.imhsv.ignoreval = 0;  %when creating and plotting variable 'img', which is built from variable 'hsvmap', 1 ignores val in variable 'hsvmap', makes constant 1, but does not change 'hsvmap'

%% fmf (flymaxfe: flymax visual stimulus feature extraction)

d.fmf.stimtype = 'drone';
d.fmf.id = 'CON_51';
d.fmf.pthparent = [];
d.fmf.pthtemplate = [];
d.fmf.rep = 1;
d.fmf.feat2 = [];
d.fmf.getgrid = 1; %get the feature on a grid (phi theta if vistype is sphere, xy if gridtype is plane)
d.fmf.vistype = 'plane'; %sphere, plane, or raw 
d.fmf.it = -100;
d.fmf.gridres = 256;
d.fmf.flipped = 0;
d.fmf.downsample_template = 1; %downsamples template, then uses it, rather than using template then downsampling; fine for most cases, just looks a little rougher
d.fmf.crop_edges = 1;


%% write options to file

tmp = split(d.daq.vrenm, ':');
if ~strcmp(tmp(:,1)', ["t", "epochts", "vyvnom", "vy", "vyv", "bf", "bfv", "bs", "bsv", "by", "byv", "ftcam"])
    error("you cannot change new names for the daq in d.daq.vrenm if you're running a2p")
end
if ~isequal(d, structunflat(structflat(d)))
    error("at least one of the default values above must be an empty struct; empty structs are not allowed to be default values (although empty vector, cell, char, and string are allowed); empty structs are used in oid to eliminate options structs that depend on other options, before writing to the options file ")
end

fprintf("writing default options to: " + pthopt + newline)
structsv(d, pthopt, overwrite=1, readonly=1, dosort=1)

glb(dfset=1); %mark defaults have been set in globals

