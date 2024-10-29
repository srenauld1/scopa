function o = odf(oin, vbin, copybin, opt)


%{

odf is just a wrapper for odfscal; odfscal operates on scalar struct argument oin; odf just loops over elements of oin

WARNING THIS FUNCTION WORKS AS INTENDED BUT THE CODE AT THE BOTTOM THAT UPDATES ALL DEFAULTS IS CONFUSING;
note the docs in oset are also about odf, and are much more extensive than the docs here
odf is intended to help the user easily set a potentially complex set of pipeline options (see function oset, where odf is called)

can call odf in different ways
    zero arguments sets o equal to d (all default options)
    one argument sets options for fields in oin, setting default for options not listed 
    two arguments sets options for d.vbin only, even if vbin don't appear in oin (if they don't they will be all default); vbin can be nested (vbin1.vbin2)
    three arguments creates struct(s) (names in copybin) within vbin
    name-value argument 'files': if files==1, will find files matching user supplied stack file specifiers (or default specifiers, if no user supplied specifiers); files mode must have 'spec' vbin in oin, or 'spec' as vbin second argument; if files==0, will not search for files; if files==2, will not search for files, but will keep found files in input struct and put them in the output struct

struct d holds all default options;
fields directly under d are mostly used within single functions called from a2p, except mn, which is used in a2p direcly
each section contains options for a major routine called in a2p (section header is options field name, with function name in parentheses, and brief description of function)
output struct o holds options used in a2p
output o matches default d unless input oin specifies a different value
in particular: if a field is in both oin.vbin and d.vbin, use the value in oin.vbin; if field is only in d.vbin, use the value in d.vbin; if field isn't in d.vbin, error

%}

arguments
    oin = [] %input options struct for overwriting defaults in default options struct d
    vbin = [] %cell of char (or char, if scalar); if nonempty, and copybin is nonempty, update vbin and place results in copybin, and update ~vbin without placing in copybin; if nonempty and copybin is empty, just update vbin; if empty and copybin is nonempty, update all and place all in copybin
    copybin = [] %subfields into which vbin is copied
    opt.files = 0 %whether to use spec to find stack files, or skip
end
files = opt.files;

if isstring(oin) || isstring(vbin) || isstring(vbin)
    error('you may have attempted to pass "files" name-value argument, without some of the other non-name-value arguments, but misspelled "files" it or used the wrong term;')
end

if files %if files==1, oin must be scalar
    if numel(oin)>1
        error("if files==1, oin must be scalar")
    end
    o = odfscal(oin, vbin, copybin, files); %odfs is for scalar struct o
else %otherwise, oin can be nonscalar
    if ( numel(oin)>1 && any(~cellfun(@isempty, getfieldns(oin,'id.pth'))) ) || ( isfield(oin, 'id') && isfield(oin.id, 'pth') )
        files=2;
    end
    if isempty(oin)
        o = odfscal(oin, vbin, copybin, files); %odfs is for scalar struct o
    else
        for k = numel(oin):-1:1 %in case o is nonscalar, loop over each element, calling odfs; backwards to preallocate
            o(k) = odfscal(oin(k), vbin, copybin, files); %odfs is for scalar struct o
        end
    end
end

end

function o = odfscal(oin, vbin, copybin, files)


if files && ~isfield(oin, 'spec') && ~any(strcmp(vbin, 'spec'))
    error("if files is true, you must pass input struct with spec vbin, or pass vbin argument that includes 'spec'")
end

if files
    [~, flatfntmp, ~] = structflat(oin, 'prefix', 'o');
    if any(strcmp(flatfntmp, 'spec.pth')) && ~isempty(oin.spec.pth)
        if (any(strcmp(flatfntmp, 'spec.recdate')) && ~isempty(oin.spec.recdate)) || (any(strcmp(flatfntmp, 'spec.fly')) && ~isempty(oin.spec.fly)) || (any(strcmp(flatfntmp, 'spec.trial')) && ~isempty(oin.spec.trial)) || (any(strcmp(flatfntmp, 'spec.suffix')) && ~isempty(oin.spec.suffix))
            error("in file mode, cannot pass in spec.pth and any of spec.recdate, spec.fly, spec.trial, spec.suffix")
        end
    end
end


%% spec (stackfind: find files matching recording specifications, called below)

d.spec.pthparent_local = '~/stacks'; %on local machine, full path to folder containing all recording folders
d.spec.pthparent_o2 = ''; %on o2, full path to folder containing all recording folders, leave empty to automatically find path in /n/files/scratch with same parent folder name as o.mn.pthparent_local; ap2 will automatically determine if you're on O2; example path is '/n/scratch/users/c/caw846/stacks/'
d.spec.validsuffix = ["raw", "cmrg", "cmrg_dcdn", "bksb_cmrg", "bksb_cmrg_dcdn", "bksb_cmrg_dcdn_nosn"]; %all valid suffixes on files (all tifs, except for '*nosn', output by 'pre' part of scopa pipeline (pipeline_init.py, cxp.sh); 'raw' is raw tif file output by scanimage (not scopa 'pre'), which will not actually have suffix 'raw' (unless you're carl, who renames the flyg/scanimage raw files with suffix 'raw')
d.spec.pth = '';  %cell array of char (or scalar char), full path for file(s); if this is used, spec.recdate, spec.fly, spec.trial, spec.suffix are all 'fullpathinput' (rather than their default values); if this is empty (user doens't pass in full path(s) to a2p) then those fields are used and this remains empty
if files
    d.spec.recdate = {'*'}; %cell array of char, can use wildcards
    d.spec.fly = {'*'}; %cell array of char, can use wildcards
    d.spec.trial = {'*'}; %cell array of char, can use wildcards
    d.spec.suffix = {'raw'};  %cell array of char (or scalar char), can use wildcards, scopa 'pre' pipeline output filename suffix to use in this 'post' pipeline (or 'raw' for raw tif output by scanimage/flyg, which does not necessarily have filename suffix 'raw'); valid suffixes are defined in validsuffix
    d.spec.match = 'each'; %'any' for all combinations of recdate, fly, trial, suffixstack, 'each' for matched indices of each (length 1 will be repeated to match anything longer)
else
    d.spec.recdate = ''; %cell array of char, can use wildcards
    d.spec.fly = ''; %cell array of char, can use wildcards
    d.spec.trial = ''; %cell array of char, can use wildcards
    d.spec.suffix = '';  %cell array of char (or scalar char), can use wildcards, scopa 'pre' pipeline output filename suffix to use in this 'post' pipeline (or 'raw' for raw tif output by scanimage/flyg, which does not necessarily have filename suffix 'raw'); valid suffixes are defined in validsuffix
    d.spec.match = ''; %'any' for all combinations of recdate, fly, trial, suffixstack, 'each' for matched indices of each (length 1 will be repeated to match anything longer)
end

%% mn (ap2: main pipeline control in a2p)

d.mn.dodaq = 0; %process daq data
d.mn.doftv = 0; %temporal resample fictrac video to match imaging (only relevant if you've not set up proper sync to daq)
d.mn.doroi = 0; %do roi extraction 
d.mn.dopop = 0; %compute population features (o.pop below)
d.mn.dofit = 0; %model fitting (o.mfit below)
d.mn.dopltx = 0; %plot experiment (o.pltx below)
d.mn.pltvis = 1; %1 shows requested plots and saves them, 0 saves but does not show them
d.mn.fldrtmp = 'scopatmp'; %will be created in same dir as stacks, stores small tmp files used in interactive figures; getActiveFilename is problematic on O2 so using this approach instead
d.mn.timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));
d.mn.oldcarl = 0; %run with some settings for carl's old project

%% daq (daqld: load, process daq)

d.daq.useinds = 'none'; % 'none', 'slice', 'vol', 'all', or numeric vector of slice indices, with optional 0 to mean volume indices; 'none' (resample using 'resample' function with padding to avoid start/end transients), 'slice' (resample using all slice indices), 'vol' (resample using volume indices), 'all' (resample using all slice indices and volume indices), numeric vector defines which slice indices (one indexed) to use with 0 denoting volume index resampling (eg [0 4] will resample with volume and slice 4); 'none' is fastest but has a little more aliasing, which is probably rarely a problem; slice resampling is included especially for slow imaging rate, or large flyback; the more resampling registers are used, the slower this function on first run (output is saved/loaded for subsequent runs)
d.daq.usefbl = 1; % whether to include flyback lines when resampling with frame indices (if useinds is not 'none')
d.daq.usefbf = 1; % whether to include flyback frames when resampling with volume indices (if useinds is not 'none')
d.daq.balldia = 9; % mm, used to convert fictrac variables into mm
d.daq.slopelensec = 0.4; % window numel used to fit slope (to compute daq variable derivatives (eg velocities)
d.daq.slopeord = 2; % order of polynomial used to fit local slope; this should probably just remain 2
d.daq.vnormal = ["Time", "heat", "virmenIteration"]; % list normal (not circular, not categorical) daq variables you want to process; virmenIteration is averaged by imaging frame, output is converted to frame number in the usual way
d.daq.vcircular = ["ficTracIntSide", "ficTracIntForward", "ficTracYaw", "g4panels"]; % list circular daq variables you want to process
d.daq.vcategorical = ["ftcam"]; % list categorical daq variables you want to process
d.daq.toballscale = ["ficTracIntSide", "ficTracIntForward"]; % define which vars to rescale from radians to mm
d.daq.tounwrap = ["ficTracIntSide'", "ficTracIntForward"]; % define which vars to unwrap
d.daq.tozero = ["ficTracIntSide", "ficTracIntForward"]; % %define which vars to zero (force to start at 0)
d.daq.voltmin = 0; % daq voltage min; need to find this in metadata
d.daq.voltmax = 10; % daq voltage max, need to find this in metadata
d.daq.use_carls_epochs = 1; %1 for carl, 0 for everybody else; use vector of epoch indices defining stimulus state for each sample of trial; vector is created in socket code to control stimulus state, then saved at end of experiment; for old recordings file was not saved, so use_carls_epochs recreates that vector in the same way the socket code did
d.daq.doplt = 0; % if 1, will plot original and resampled timeseries in same figure, overlain, by default partitioned into 20 segments, one on each frame of a gif


%% sld (stackld: load, process stack)

d.sld.chanuse = [1 2]; % which PMT channel to use ,1, or 2, or [1 2]; ignored if requested channel doens't exist
d.sld.cropfb = 1; %crop flyback frames from each volume
d.sld.zerostack = 1; %subtract min to make min zero
d.sld.tcrop = [0 0]; %how many samples to remove from [start, end] of stack; similar to cropdata in rec6 (also applied in metrics2 without variable name cropdata), crop first 4 and last 2 imaging frames (stimulus features, and deprecated responses, have been extracted with this cropping in rec6)
d.sld.stackdtype = 'uint16';
d.sld.smsdspace = [0 0 0]; %gaussian smooth stack in space (yxz); for each dimension, yxz, gaussian sd is one-fifth corresponding entry in smsdspace; each entry must be odd, or 0; [0 0 0] or empty to skip smoothing; 0 will skip smoothing in corresponding dimension (eg [3 3 0] skips smoothing in z)
d.sld.smsdtimesec = 0; %gaussian smooth stack in time; gaussian sd is smsdtime seconds; 0 to skip
d.sld.dostats = 0; %turns on/off do_plot_stack_stats, which is old/inefficient and needs to be updated, but is not useless
d.sld.suffixplt = [ %stack suffixes to plot together in stackplt gif, nonexistent or invalid suffixes are ignored; will be reordered from least to most processed (by suffix length)
    %"raw", ...
    %"cmrg", ...
    %"cmrg_dcdn", ...
    %"bksb_cmrg_dcdn", ...
    %"bksb_cmrg_dcdn_nosn"
    ];


%% ftv (ftvproc: load, align, resample fictrac video if not on daq)

d.ftv.num_periodic_peaks_defining_laser_oscillations = 10; %in laser oscillation timeseries, number of contiguous peaks with periodic distance to be considered the start of the imaging trial, and also the end when applied in the reverse direction; this could just be same as numvol, but in case there are missing peaks, making this number smaller . . . max would be  round(numvol*0.8)
d.ftv.smsdspace = 2; %std of gaussian smoothing filter applied to average frame of fictrac video, prior to finding the brightest pixels (to locate laser)
d.ftv.numpix_to_extract_laser_timeseries = 10; %after spatial smoothing, number of pixels to average on each frame of fictrac video; these are the brightest 'numpix_to_extract_laser_timeseries' pixels in the mean frame of fictrac video
d.ftv.smsdtime = 6; %std of gaussian smoothing filter applied to laser timeseries, to help denoise timeseries prior to findpeaks (to help find the true laser oscillation peaks)
d.ftv.doplt = 0; %0 skips plots, 1 plots and saves, 2 saves but does not display

%%  (roimake: draw and/or automatically segment morphological rois, extract and normalize their responses)

d.roi.regionex = 'dflt'; %default regionex name 'dflt' automatically gets fullfov croplim; user is not prompted to create one in this case
d.roi.domm = 0; %do "morph manual"; if true, draw rois in an interactive plot, and save, (or load if already drawn and saved), if false, skip drawing
d.roi.doma = 0; %do "morph auto"; if true, automatically segment drawn rois (or if none, full fov)
d.roi.docm = 0; %do caiman extract.py; if true, load caiman rois with regionex in filename
d.roi.doqc = 0; %do quality control (remove bad rois)
d.roi.doplt = 0; %do plots

%% mm (drawrois: mm = "morphological manual")

d.mm.maskname = ['dflt']; %empty to skip; string array of names for roi mask(s) drawn on the same regionex
d.mm.chandraw = [1]; %which channel(s) to use as background for roi drawing; 'both' will draw on sum
d.mm.chancp = [1]; %which channel's drawn rois to copy onto the other (concatenated with any other rois on that channel, ie does not overwrite); this is not automatically done with un-drawn channel because user may not want drawn rois for one channel

%% ma (roimauto: ma = "morphological automated", automated morphological roi extraction, can be applied to drawn rois (or not))

d.ma.chanauto = 1; %which channel for auto roi extraction (for now all options below are same for each) option where auto rois interact has not been written yet);
d.ma.numroi = 128; %partition regionex into num_roim_auto morphological rois; a drawn roi, if it exists, masks the regionex prior to automated super-roi extraction; num_roim_auto and number drawn rois cannot both exceed 1 (i.e. the code cannot automatically partition discontiguous rois within a single regionex)
d.ma.usehires = 0; %cell of regionex strings, use hi-z-res stack to help make morphological rois (to help 3d edge detection of region boundaries, and to help automated subdivision of 3d region into morphological rois)
d.ma.maskmake = 'nonzero'; %'nonzero'; %method for automatically defining morphological roi mask (union of all morphological rois) from stack or union of manually drawn rois, options are 'edge', 'outlier', 'triangle', 'nonzero'
d.ma.maskseg = 'uniform'; %'skeleton' for elongated structures or 'uniform'; method for subsampling mask into rois; for 'uniform', o.roi.ma.num_roim_auto_str must be power of 2 and works best for convex structures since for concave structures it will find rois outside the structure but can be masked to remove orois outside the structure afterward
d.ma.edgethr = [.1, .7]; %two thresholds to detect strong and weak edges; includes weak edges in output only if they are connected to strong edges
d.ma.edgesig = [sqrt(2)*2, sqrt(2)*2, sqrt(2)*2]; %for edge detection, defines smoothing filter sigma for each dim xyz, or use one value for all dim, if 2d edge detection, first element is used for x and y
d.ma.celsz = 8; %for bwmorph close after edge detection, helps connect edges
d.ma.do3d = 1; %1 makes 3d mask unless stack is 2d, 0 makes 2d mask for 2d, 3d, or 4d stack input
d.ma.doplt = 0;

%% cm (roifmake: cm = "caiman"; load, process, cluster, normalize functional rois/responses output by caiman in extract.py; option names here match option names in map2opt, and their counterparts in optex)

d.cm.methodex = '1'; %'1' (channel 1 only), '2' (channel 2 only), '12' (channel 1 and 2 independently), 'seedeachpy' (channel 1 and 2 independently, with python-automated morph roi seed masks for each channel), 'seedeachmat' (same as seedeachpy, but using morph rois created/saved in matlab), 'seed21py' (python-automated morph roi seed mask in channel 2 seed functional extraction from channel 1), 'seed12py' (inverse of seed21py), 'seed21mat' (same as 'seed21py', but for morph rois created/saved in matlab), 'seed12mat' (inverse of 'seed21mat'); the seed*py methodex only work when extract_in_2d=true
d.cm.gSig = [2, 2, 0.5]; %approximate xyz half-size, in pixels, of average neurons; z ignored if extract_in_2d; later, forced to be odd when creating gsiz, so min gsiz is 3; any number 0-1 has same effect as 1, but since gSig is used to derive sigma_smooth_snmf, which is not clipped to 1, go ahead and use the real value; also, consider that our z are often much larger than xy when you set this, so if neurons are restricted to single z planes, make this 1 (since gsig unit is pixels); z (3rd element) ignored if extract_in_2d;
d.cm.nb = 1; %nb is used everywhere; default 1; num background components
d.cm.low_rank_background = true; % spatial, and patch; #default true; and  #true makes bankground nb, false makes it update with hals, if true with patches, each patch keeps its background, if false, each patch bg approximated with global background
d.cm.update_background_components = true; %spatial; #default true; update background components during spatial phase
d.cm.merge_thr = 0.85; %merge_components; default 0.85; threshold for merging components
d.cm.only_init = false; %default false; only use the initialization for extraction (no updating of spatial and or temporal components, ie no alternating least squares for spatial and temporal refinement)
d.cm.normalize_init = true; %init; default true; variance norm by pixel over time befroe initialization;  prob should always be true except for 1p data; patches take care of this to some extent but why not just do it always;
d.cm.roidensity = 0.4; %not a caiman option; used to derive K (approximate number of neurons to find), given other options, gSig, and patch or fov size; keep above 0 and less than or equal to 1; 1 is "space filling" (as many neurons as possible given patch or fov size, reoslution, and gsiz); caiman demo does not use this variable, but effectively their demo sets it at 0.33)
d.cm.p = 0; %for deconvolution model if 1 or 2, or skipping deconvolution if 0 (skip deconvolution if neuron is nonspiking); order of the autoregressive system - 0 for nonspiking, 1 for instanteous rise but not decay (low sample rate), 2 for non-ionstantaneous rise and decay (higher sample rate)
d.cm.method_init = 'graph_nmf'; %'greedy_roi' #'graph_nmf' #sparse_nmf; default greedy_roi; greedy_roi looks for globular sources; carl usually does not use greedy_roi  
d.cm.sigma_smooth_snmf_time = [0.5]; %first element of sigma_smooth_snmf, for smoothing in time before initialization; sigma_smooth_snmf default is [0.5, 0.5, 0.5, 0.5], which is txyz std of gaussian smoothing filter applied just before initialization with method_init sparse_nmf or graph_nmf; similar to gSig for method_init greedy_roi, but unlike gSig, values 0-1 and evens do have effect; consider z width, relative to xy width, when setting this; in optex, the xyz elements are assigned the same values as gSig
d.cm.perc_baseline_snmf = [20]; % default 20; baseline percentile, removed from stack before initialization for method_init graph_nmf and sparse_nmf
d.cm.max_iter_snmf = [500]; %default 500; number iterations in initialization for method_init graph_nmf and sparse_nmf)
d.cm.sparsity_penalty = [1, 4]; %not a caiman option, but assigned to caiman options alpha_snmf (when using method_init sparse_nmf) and lambda_gnmf (when using method_init graph_nmf);


%% qc (quality control rois)

d.qc.minpixperreg = 3; % min pix in each distongiguous region, roi selection criterion
d.qc.minroisz = 5; % pixels, roi selection criterion
d.qc.maxroisz = 300; % pixels
d.qc.maxregperroi = 4; % for discontiguous rois
d.qc.inmaskthr = 0.5; % discard roi if more than inmaskthr is outside morphological mask (morph mask is all ones if you don't make one)
d.qc.doplt = 0; %plot roi overlay


%% nrm (roits: extract and/or normalize roi timeseries)

% options for response extraction/normalization of roi responses
% all normalizations are applied to individual vector timeseries
% normalization strings are listed below; they can be combined arbitrarily and if combined, will be applied left to right order (eg 'nnbox' applies 'nn' then 'box'):
    % 'f': no normalization
    % 'dffuuuvvv': sliding window dff, uuu is percentile to compute f0 for each window, vvv is sliding window length in seconds, if vvv is 000 then f0 is computed across the entire timeseries, not a sliding window (e.g. dff010008 is 10th percentile over 8-seconde sliding window)
    % 'rscxxxyyy': rescale, sending xxx percentile to 0, yyy percentile to 1 (eg rsc000100 is same as default matlab rescale function)
    % 'z': zscore
    % 'nn': nonnegative (subtract min)
    % 'box': box-cox

d.nrm.pre = 'f'; %must have at least one string, compsed of syllables above; % precluster normalization is applied before clustering (i.e. normalization of each pixel in roi, or subroi within a larger roi)
d.nrm.post = 'f'; %must have at least one string, compsed of syllables above; postcluster normalization is applied after clustering (ie to each roi)
d.nrm.degdtr = 0; %polynomial for detrending before normalization; 0 to skip detrending; wavp detrends by default
d.nrm.wavp = []; %[0.3 50]; %(n,2) array denoting wavelet filtering min and max period (seconds); if n>1, will use last row in output by default (n>1 is really for exploration, plotting to see how different periods affect output); empty to skip; 0 in first column will not apply lower period threshold; any number larger than max valid period (determined in wavflt) will not apply upper period threshold, but [0 inf] (or 0 and any giant number) is not the proper way to skip wavelet filtering because the algorithm will still be applied (ie timeseries will be unchanged except mean will be lost, pointlessly), so use [] to skip wavelet filtering
d.nrm.channorm = [0]; %work in progress; 0 to skip; leave as 0 for now; which channel to normalize the other with (dampen time-frequency regions of high wavelet coherence)
d.nrm.doplt = 0;

%% pop (popcmp: compute population features from roi timeseries, e.g. bump)

d.pop.id = []; %currently just a wrapper for bump routine (bumpcmp)

%% bump (bumpcmp: compute bump)

% options for bump in bumpcmp function
% a von mises is fit to the instantaneous relationship between each roi timeseries (given by all matches from o.bump.mfit.tg.v1) and all matches from o.bump.mfit.tg.v2
% the value of the independent variable at the max predicted response is the preferred heading for each roi
% if o.bump.domaintypeis 'functional', these preferred headings are used as the angle, and o.bump.mfit.tg.v1 as the magnitude, in computing pva
% if the regionex in o.bump.mfit.tg.v1 is in o.bump.numcluster_for_bump_domain_resample, and that regionex is followed by hyphen and number greater than zero, these preferred heading angles are resampled into that number, so that the rois evenly sample range 0-2pi (resampling changes angle and magnitude)
% if o.bump.domaintypeis 'morphological', angle is forced to be 0-2pi, with each roi evenly sampling that range

% o.bump.mfit(1).depv{1} = {['resp, pb, mo*, in_imf_pc_f_cl_rsc000100_w_*']};
%this will select all fields in struct 'ts', matching this pattern, with * as wildcard: ts.resp.pb.mo*.in_imf_pc_f_cl_rsc000100_w_*
%the selected timeseries will be assigned to depv
%selecting indv uses the same approach
%depv and indv are matched at the outer cell level
%at the inner cell level, there can be multiple field specifiers (fieldspec)
%each fieldspec is a char array, composed of segments separated by comma with space (', '), each segment matching the name of a field at a different level under struct 'ts'
%depv and indv are composed of all timeseries matching fieldspecs
%if multiple matches, depv is concatenated along second dim (time), since currently mfit fits single timeseries
%if multiple matches, indv is concatenated along first dim (not time), since mfit can accept multidimensional independent variable
% o.bump.mfit(1).indv{1} = {['vis, angsd']};

%options for computing bump
d.bump.mthd = 'pva'; %'pva' for vector average
d.bump.domaintype = 'functional'; %'functional' to define circular domain with fit to each roi, or 'morphological' to define as circle across region mask
d.bump.domain = 'all'; %cell array of char, 'all', 'right', 'left', 'larger', 'weighted', 'random'
d.bump.slopeord = 2; %order of polynomial used to fit local slope (e.g. to compute bump speed)
d.bump.slopelensec = 5; %order of polynomial used to fit local slope (e.g. to compute bump speed)
d.bump.smoothwindow_sec = 0.2; %full width of gaussian smoothing window (5 times std)
d.bump.numcluster_for_bump_domain_resample = 16; %how many clusters/superrois across the entire region (not hemisphere) when resampled uniformly prior to computing bump as vector average, regionex must exist in matches to o.bump.mfit.tg.v1  . . . to skip resampling for a regionex, just don't list it here, or write 'regionex-0'
d.bump.resample_smoothfac = 1; %when resampling compass, bandwidth of the antialiasing filter, larger number will have smoother resampled compass
d.bump.rescale_clusters = 1; %just before computing bump, rescale each cluster's timeseries to range 0-1
d.bump.omitnan = 1; %ignore nans in case there are any (e.g., making hybrid morph-func rois, some morph rois have no func members, making their response 'nan', omit will ignore this in computing pva)
d.bump.doplt = 0;

%% mfit (mfit: fit models to individual roi responses)

% options for modeling depv as function of indv in mfit function

d.mfit.num_synthetic_depv = 0; %create synthetic data (using requested mdlname options, within any requested bounds) for testing fit; this is number of synthetic responses to fit; 0 to skip
d.mfit.epochinds = 1;
d.mfit.mdl_lag_sec = 0; %0 is one sample, how many samples indv precedes depv for model fit . . . for now, must be nonnegative integers, range 0 to lenfit_samp-1
d.mfit.mdl_length_sec = 2; %seconds, 0 is one sample
d.mfit.keep_transition_zones = 0; %1 to keep multi-timepoint model samples that have multiple epochs
d.mfit.validation_fold = 6; %applied to all mdlnames; k in k-fold cross-validation; k non-overlapping validation sets; if numbouts of each epoch in epochinds is divisible by validation_fold, will validate on numbouts/validation_fold bouts for each epoch in epochinds; if only one bout for each epoch, will evenly split each bout into k validation sets; otherwise will error; 0 skips validation
d.mfit.validation_split_style = 'boutsamples'; %'samples' or 'bouts' or 'boutsamples' %applied to all mdlnames; k in k-fold cross-validation; k non-overlapping validation sets; if numbouts of each epoch in epochinds is divisible by validation_fold, will validate on numbouts/validation_fold bouts for each epoch in epochinds; if only one bout for each epoch, will evenly split each bout into k validation sets; otherwise will error; 0 skips validation
d.mfit.slvrg = 'globalsearch';
d.mfit.slvrl = 'fmincon'; %'lsqcurvefit';
d.mfit.mdlname = 'fnet_A01_sh16'; %'svd' or fnet string (see docs_mdlname.m)
d.mfit.excludeopts = '';
d.mfit.normalize_indv = 'minmaxcnt'; %'minmax' range [0,1], 'minmaxcnt' range [-1,1], 'zscore' mean 0 unit var, 'none' . . . normalization used in fitting model but not all plotting . . . don't forget mse sensitive to scale
d.mfit.normalize_depv = 'minmaxcnt'; %'minmax' range [0,1], 'minmaxcnt' range [-1,1], 'zscore' mean 0 unit var, 'none' . . . normalization used in fitting model but not all plotting . . . don't forget mse sensitive to scale
d.mfit.smoothdepv = 0; %gaussian window std is one fifth total length
d.mfit.smoothindv = 0; %gaussian window std is one fifth total length
d.mfit.use_saved_model = 1;
d.mfit.omit_time_from_savemodel_datestr = 1; %to prevent too many saved files, setting to 1 will use date suffix in saved model filename, rather than datetime suffix
d.mfit.optim_hist_save_iter_spacing = 2;
d.mfit.doplt = 0;


%% tg (tsget: choose timeseries using string matching of flattened struct ts)

d.tg.domain = [];
d.tg.optused = [];
d.tg.name = [];
d.tg.group = 'name';

%% pltx (pltx: explore various components of experiment in interactive plots, e.g. brain images, timeseries, stimulus videos, scatterplots, fictive path, model components)

d.pltx.vpmapl = [1 2 3 4]; %map of indices of each tg.v above to plot positions (on left axis)
d.pltx.vpmapr = [5 6 7 8]; %map of indices of each tg.v above to plot positions (on right axis)

d.pltx.lagsxy_sec = [0, 0, 1, 0]; %lags for interactive scatterplot;  %empty or zero to skip; scalar or vector; seconds of lag, rounded to nearest frame; repeated frames are omitted; to see all frames within range, bookend with zeros, eg [0, 1, 2, 0] is all samples in range 1-2 (done this way to prevent using cell, since cell sare for opt expansion)
d.pltx.lagsz_sec = [0, 0, 1, 0]; %same as lagxy_sec, except z lags are applied for each xy lag (xy vars are lagged, then together lagged relative to z); will be automatically set to 0 if there is no z variable
d.pltx.lags_to_plot = 'best'; % 'zero', 'best', 'zeroandbest', 'all'
d.pltx.plot_z_as_color = 1; %if z variable exists, 0 will make 3d scatterplot, 1 will make 2d with z variable as color

d.pltx.epochinds = [1]; %cell array of vectors or scalars listing epochs (within single trial) to group in scatterplots, empty cell with empty vector for all epochs, like this {[]}

d.pltx.iz = []; %z indices to plot, empty for all, negative for that number equidistant from all available
d.pltx.it = []; %[3320]; %t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
d.pltx.dr = [0,1];
d.pltx.doui = 1;

%% hires (hiresld: load and register high-z-res stack if it exists)

%options for hires stack (high z resolution version of main stack) . . . this code is a little deprecated
%hires stack is only used in making morphological rois, set o.roi.ma.use_hires=1 to use
%options below, in vbin hires, are for registering the hires stack to the regular stack;
% hires registration is done in matlab rather than in caiman, but should be switched over to caiman

d.hires.disttype = 'monomodal'; % multimodal monomodal, used in stackrg3d from within hiresrg
d.hires.regtype = 'rigid'; %3d registration type (rigid should be best for tiny fly brain), used in stackrg3d from within hiresrg
d.hires.use_caiman_on_hires = 0; %keep at 0 bc pipeline not yet finished for this option (also doens't seem to help)
d.hires.doplt = 0;

%% tp (tsplt: plot timeseries)

d.tp.predlot_norm = 'each'; %amplitude normalization for the detail plots at bottom, 'all' normalizes to population, 'each' normalizes to each
d.tp.maxnumroiplot = 100; %number of rois that get detail view on the bottom, one per gif frame
d.tp.sort_method = 'unbiased'; %'majoraxis', 'unbiased', 'gof', 'custom'; %how to select rois for detail plots, 'unbiased' for equidistant maxnumroiplot, 'gof' for equidistant maxnumroiplot sorted by gof in descending order (so starts with best fit ends with worst)
d.tp.max_tinds = 1000; %1000; %for the timeseries view of depv, how many samples to plot at the most (will take indices 1:max_tinds), big number to plot all
d.tp.timeseries_numsegments = 3; %how many equispaced segments to display in setail view, ending at final frame

%% sp (stackplt: plot stack with various viewing options)

d.sp.it = [50.3];%t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments (where segments are equidistant, if possible)
d.sp.iz = []; %z indices to plot, empty for all, negative for that number equidistant from all available
d.sp.ir = []; %scalar/vector; which rois to plot in ; empty to skip
d.sp.roi_color = [1 0 0]; %color for rois, if shown
d.sp.roialpha = 0.3; %transparency for rois, if shown
d.sp.dr = [0,1];

%% imhsv (hsvplt and hsvcmp: make and plot hsv images)

d.imhsv.fg = 'allrois'; %'eachroi' plots each individually, 'allrois' plots all together
d.imhsv.mdlname = ''; %string for swithcing among plotting defaults in plots_setup_hsv, leave empty for default set
d.imhsv.huestr = ''; %deprecated variable, leave empty
d.imhsv.huenorm = 'native'; %hue normalization method, 'native' normalizes to a preset range (hard coded in plots_setup_hsv) according to 'mdlname', 'relative' normalizes to the data range assigned to hue, 'manual' normalizes to the range set below in opt.roi.hsv.hrange_in_manual; if you request 'native' but don't pass huelimnat to hsvcmp it will switch to 'relative'; if you request 'manual' but don't set hrange_in_manual it will switch to 'relative'
d.imhsv.satnorm = 'relative'; %sat normalization method, same logic as huenorm
d.imhsv.valnorm = 'relative';%val normalization method, same logic as huenorm
d.imhsv.hrange_in_manual = []; %manual range for normalizing hue, prior to normalization to plot scale, whose max range is [0 1]), see hsvcmp
d.imhsv.srange_in_manual = []; %manual range for normalizing sat, prior to normalization to plot scale, whose max range is [0 1]), see hsvcmp
d.imhsv.vrange_in_manual = []; %manual range for normalizing val, prior to normalization to plot scale, whose max range is [0 1]), see hsvcmp
d.imhsv.hrange_out_manual = [0 0.6]; %[0.25 1]; %hue plot scale, whose max range is [0 1] hue hange around color circle, defaults to less than full circle for non-periodic plotting domain, but overwrites in plots_setup_hsv to [0 1] when plotting a periodic huefeature (e.g. von mises center, ie mdlname 'v' with huestr 'loc'), see hsvcmp
d.imhsv.srange_out_manual = [0 1]; %sat plot scale, whose max range is [0 1], if you want to force saturation you can reduce (e.g. [0 0.75] will force smaller range to max saturation, see hsvcmp
d.imhsv.vrange_out_manual = [0 1];  %val plot scale, whose max range is [0 1], if you want to force value you can reduce (e.g. [0 0.75] will force smaller range to max value, see hsvcmp
d.imhsv.hueshift = 0; %0-1, circularly shift the hue map around the color circle for change to arbitrary color assignment, applied before any clipping due to, see hsvcmp, this works for periodic or non-periodic features assigned to hue
d.imhsv.ignorehue = 0; %when creating and plotting variable 'img', which is built from variable 'hsvmap', 1 ignores hue in variable 'hsvmap', makes constant 1, but does not change 'hsvmap'
d.imhsv.ignoresat = 0;  %when creating and plotting variable 'img', which is built from variable 'hsvmap', 1 ignores sat in variable 'hsvmap', makes constant 1, but does not change 'hsvmap'
d.imhsv.ignoreval = 0;  %when creating and plotting variable 'img', which is built from variable 'hsvmap', 1 ignores val in variable 'hsvmap', makes constant 1, but does not change 'hsvmap'

%% options for carl's old project

d.carl.stimtype = 'drone';
d.carl.feat = 'CON_51';
d.carl.pthparent_feat = '~/ds/data/rec';
d.carl.pth_template = '~/ds/data/stimuli';

%% for output oout, update defaults with input oin

if isfield(oin, 'id') %id is the one field that doesn't have defaults (it holds found files info)
    idhold = oin.id; %put it aside and put back below
    oin = rmfield(oin, 'id');
else
    idhold = [];
end

fnd = fieldnames(d);

if isempty(vbin)
    vbin = {};
end
if ~iscell(vbin)
    vbin = {vbin};
end
if isempty(copybin)
    copybin = {};
end
if ~iscell(copybin)
    copybin = {copybin};
end

if isempty(oin) || isempty(fieldnames(oin))
    if isempty(vbin)
        oin = d;
    else
        for k = 1:numel(vbin)
            if ~isfield(d, vbin{k})
                error(sprintf("d." + vbin{k}) + " does not exist")
            end
            oin.(vbin{k}) = d.(vbin{k});
        end
    end
end

if ~isfield(oin, 'copybinprev')
    oin.copybinprev = {};
end
copybinprev = oin.copybinprev;

if isempty(vbin)
    o = optupdate(oin, d, copybinprev, copybin);
else
    if any(contains(vbin, '.')) %if nested vbin, remove deepest vbin and operate on it, invoking defaults throughout the nested vbin, and and then merge with everything else in input, which remains untouched (algorithm is different than non-nested, hence the if/else, otherwise we could just use eval for nested and nonnested)
        [~, fbsortinds] = sort(cellfun(@numel, regexp(vbin, '[.]*')), 'descend'); %
        vbin = vbin(fbsortinds); %sort to make update order deepest nested vbin to shallowest, otherwise doens't work
        for k = 1:numel(fnd)
            repeatvbin = cellfun(@numel, strfind(vbin, fnd{k}))>1;
            if any(repeatvbin)
                error(sprintf("you have multiple copies of vbin " + fnd{k} + " and possibly others; in a nested vbin each vbin can only appear once, for now at least"))
            end
        end
        [~, fnflattmp] = structflat(oin, 'prefix', 'o'); %use prefix in case it's nonscalar
        fnflattmp = erase(fnflattmp, 'o_');
        notvbin = regexprep(erase(fnflattmp, strcat(fnd, '.')), '^[.]*', ''); %remove everything but the vbins
        if ~isempty(cell2mat(regexp(notvbin, '[.]{2,}'))) %at least 2 periods means a non-vbin is above a vbin
            error("you must have placed a non-vbin somewhere other than the end of a nesting; for example, o.vbin1.optionA.vbin2 is not allowed; options can themselves be nested, but options must come at the end of each flattened fieldname")
        end
        fnflat = unique(regexprep(erase(fnflattmp, notvbin), '[.]*$', '')); %just the vbins (options and copybins removed)
        copybinprev_and_newvbindeepest = [];
        for k = 1:numel(vbin)
            if startsWith(vbin{k}, 'o.')
                error("for nested vbin, omit the leading 'o.'")
            end
            vbintmp = strsplit(vbin{k}, '.');
            vbinshallowest = vbintmp{1};
            vbindeepest = vbintmp{end};
            if ~isempty(copybin) %if you're making copybin of a nested vbin . . .
                copybinprev_and_newvbindeepest = unique([copybinprev_and_newvbindeepest, copybinprev, vbindeepest]); %must ignore copybinprev and vbindeepest in optupdate on the full nested vbin branch (otherwise the vbin enclosing the new copybin, vbindeepest, will get populated with defaults, but this is only needed if copybin is nonempty
            end
            if ~isfield(d, vbinshallowest)
                error(sprintf("d." + vbinshallowest) + " does not exist; nested vbin must start with primary vbin directly under o")
            end
            if ismember(vbin{k}, fnflat) %if the nested vbin exists in oin, grab the deepest vbin
                eval(['oindeepest.' vbindeepest ' = oin.' vbin{k} ';']); %use eval to succinctly extract nested field
            else %if the nesting doesn't exist in oin, create it with defaults in the deepest layer, and nothing above
                if isfield(d, vbindeepest)
                    fprintf("note: " + vbindeepest + " does not exist in your input to odf, creating it and populating with all default values" + newline)
                else
                    error(sprintf("d." + vbindeepest) + " does not exist")
                end
                oindeepest.(vbindeepest) = d.(vbindeepest);
            end
            oindeepest = optupdate(oindeepest, d, copybinprev, copybin); %update deepest vbin
            eval(['oin.' vbin{k} ' = oindeepest.' vbindeepest ';']); %after updating, put deepest back into oin where it was before (ie according to vbin nesting), with possible copybin applied
            oinsub.(vbinshallowest) = oin.(vbinshallowest); %put that nested vbin aside and ...
            oin = rmfield(oin, vbinshallowest); %remove it from oin
            if k==numel(vbin)
                o = optupdate(oinsub, d, copybinprev_and_newvbindeepest, []); %then update the full nested vbin; don't use copybin on full nested vbin (only use it on oindeepest above); here you must ignore copybinprev_and_newvbindeepest, which contains both the enclosing vbin for the newly created copybin (vbindeepest), as well as old copybin (copybinprev); note you could break this if copybindeepest appears more than once in the nesting, then optupdate will ignore the shallower, so there's an above error to catch that
            end
        end
    else %if non-nested vbin, remove vbin and operate on it, and then merge with everything else in input, which remains untouched
        fn = fieldnames(oin);
        for k = 1:numel(vbin)
            if ismember(vbin{k}, fn)
                oinsub.(vbin{k}) = oin.(vbin{k});
                oin = rmfield(oin, vbin{k});
            else
                if isfield(d, vbin{k})
                    fprintf("note: " + vbin{k} + " does not exist in your input to odf, creating it and populating with all default values" + newline)
                    oinsub.(vbin{k}) = d.(vbin{k}); %use all defaults vbin{k} is not in oin
                else
                    error(sprintf("d." + vbin{k}) + " does not exist")
                end
            end
        end
        copybin_inert = copybin(ismember(copybin, copybinprev));
        if ~isempty(copybin_inert)
            fprintf(strjoin(copybin_inert, ', ') + " has/have already been set, nothing will change in this/these copybin" + newline)
        end
        o = optupdate(oinsub, d, copybinprev, copybin); %just update vbin
    end
    o = cell2struct([struct2cell(oin); struct2cell(o)],[fieldnames(oin); fieldnames(o)]); %combine with what was unchanged
end

o.copybinprev = unique([oin.copybinprev, copybin]); %must ignore copybinprev and vbindeepest in optupdate on the full nested vbin branch (otherwise the vbin enclosing the new copybin, vbindeepest, will get populated with defaults, but this is only needed if copybin is nonempty

o.id = idhold;
o = fieldord(o);


%% find files


if files
    if ~isempty(o.spec.pth) %if user passed no input to a2p, or a struct with file specifiers, or is running odf with files flag true but no oin or no spec field in oin
        o.spec.recdate = '';
        o.spec.fly = '';
        o.spec.trial = '';
        o.spec.suffix = '';
        o.spec.match = '';
    end
end

if files==1
    fprintf("RUNNING odf with files==1, SEARCHING FOR FILES" + newline)

    if isempty(o.spec.pth) %if fullpaths were not passed into a2p, use filename specifiers in spec to find files
        rectmp = stackfind(pthparent_local=o.spec.pthparent_local, pthparent_o2=o.spec.pthparent_o2, validsuffix=o.spec.validsuffix, recdate=o.spec.recdate, fly=o.spec.fly, trial=o.spec.trial, suffix=o.spec.suffix, match=o.spec.match); %find files matching spec
    else
        rectmp = stackfind(pth=o.spec.pth); %find files matching fullpath input to a2p (can contain wildcards following rules in rdir)
        if isempty(rectmp)
            fprintf("NONE OF THE FULL PATH INPUT (OR WILDCARD PATTERNS) TO a2p EXIST" + newline)
        end
    end
    if isempty(cell2mat(rectmp))
        error("NO STACKS FOUND")
    end
    idtmp = idmake(rectmp);
    numrec = numel(idtmp);

    o = rmfield(o, 'id'); %if id exists, remove it because you just made it (it's either empty or 'nofile' or is the same as idtmp)
    o = repelem(o, numrec);
    for h = 1:numrec
        o(h).id = idtmp(h);
    end
elseif files==0
    o.id = 'nofilemode';
    fprintf("RUNNING odf with files==0, NOT SEARCHING FOR FILES" + newline)
elseif files==2
    fprintf("RUNNING odf with files==2, NOT SEARCHING FOR FILES, BUT KEEPING EXISTING FILES IN o.id" + newline)
end



%% globals

if isempty(glb('pthparent')) && isempty(glb('regionexdf')) && isempty(glb('timestr')) && isempty(glb('validsuffix')) && isempty(glb('pltvis'))
    pthparent = pthparentfind(o.spec.pthparent_local, o.spec.pthparent_o2);
    glb(pthparent=pthparent, regionexdf=d.roi.regionex, timestr=d.mn.timestr, validsuffix=d.spec.validsuffix, pltvis=d.mn.pltvis); %set some globals, force update if they already have been set with first argument 1
end

end








