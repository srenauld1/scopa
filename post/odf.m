function o = odf(oin, funbin, copybin)

arguments
    oin = [] %input options for overwriting defaults in d 
    funbin = [] %cell of char (or char, if scalar); if nonempty, and copybin is nonempty, update funbin and place results in copybin, and update ~funbin without placing in copybin; if nonempty and copybin is empty, just update funbin; if empty and copybin is nonempty, update all and place all in copybin
    copybin = [] %subfields into which funbin is copied
end


% struct d holds all default options;
% fields directly under d are mostly used within single functions called from a2p, except mn, which is used in a2p direcly
% each section contains options for a major routine called in a2p (section header is options field name, with function name in parentheses, and brief description of function)
% output struct o holds options used in pipeline
% o matches d unless input struct oin specifies a different value
% in particular: let's call dsub a field of d; if a field is in both oin and dsub, use the value in oin; if field is only in dsub, use the value in dsub; if field isn't in dsub, recurse into odf to check field in the same way as dsub


%% recspec (filefind: find files matching recording specifications)

d.recspec.recdate = {'*'}; %cell array of char, can use wildcards
d.recspec.fly = {'*'}; %cell array of char, can use wildcards
d.recspec.trial = {'*'}; %cell array of char, can use wildcards
d.recspec.suffix = {'raw'}; %cell array of char; can use wildcards, scopa 'pre' pipeline output filename suffix to use in this 'post' pipeline (or 'raw' for raw tif output by scanimage/flyg); valid suffixes are defined in validsuffix
d.recspec.match = 'each'; %'any' for all combinations of recdate, fly, trial, suffixstack, 'each' for matched indices of each (length 1 will be repeated to match anything longer)
d.recspec.pthparent_local = '~/stacks'; %on local machine, full path to folder containing all recording folders
d.recspec.pthparent_o2 = ''; %on o2, full path to folder containing all recording folders, leave empty to automatically find path in /n/files/scratch with same parent folder name as o.mn.pthparent_local; ap2 will automatically determine if you're on O2; example path is '/n/scratch/users/c/caw846/stacks/'
d.recspec.validsuffix = {'raw', 'cmrg', 'cmrg_dcdn', 'bksb_cmrg', 'bksb_cmrg_dcdn', 'bksb_cmrg_dcdn_nosn'}; %all valid suffixes on files (all tifs, except for '*nosn', output by 'pre' part of scopa pipeline (pipeline_init.py, cxp.sh); 'raw' is raw tif file output by scanimage (not scopa 'pre'), which will not actually have suffix 'raw' (unless you're carl, who renames the flyg/scanimage raw files with suffix 'raw')


%% mn (ap2: main pipeline control in a2p)

d.mn.dodaq = 1; %process daq data
d.mn.doftv = 1; %temporal resample fictrac video to match imaging (only relevant if you've not set up proper sync to daq)
d.mn.dopop = 0; %compute population features (o.pop below)
d.mn.dofit = 0; %model fitting (o.mfit below)
d.mn.dopltx = 1; %plot experiment (o.pltx below)
d.mn.fldrtmp = 'scopatmp'; %will be created in same dir as stacks, stores small tmp files used in interactive figures; getActiveFilename is problematic on O2 so using this approach instead
d.mn.timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));
d.mn.rec = []; %full path to recording(s)
d.mn.regionex = 'default'; %names to analyze same recording separately

%% daq (daqld: load, process daq)

d.daq.useinds = 'none'; % 'none', 'slice', 'vol', 'all', or numeric vector of slice indices, with optional 0 to mean volume indices; 'none' (resample using 'resample' function with padding to avoid start/end transients), 'slice' (resample using all slice indices), 'vol' (resample using volume indices), 'all' (resample using all slice indices and volume indices), numeric vector defines which slice indices (one indexed) to use with 0 denoting volume index resampling (eg [0 4] will resample with volume and slice 4); 'none' is fastest but has a little more aliasing, which is probably rarely a problem; slice resampling is included especially for slow imaging rate, or large flyback; the more resampling registers are used, the slower this function on first run (output is saved/loaded for subsequent runs)
d.daq.usefbl = 1; % whether to include flyback lines when resampling with frame indices (if useinds is not 'none')
d.daq.usefbf = 1; % whether to include flyback frames when resampling with volume indices (if useinds is not 'none')
d.daq.balldia = 9; % mm, used to convert fictrac variables into mm
d.daq.slopelensec = 0.4; % window numel used to fit slope (to compute daq variable derivatives (eg velocities)
d.daq.slopeord = 2; % order of polynomial used to fit local slope; this should probably just remain 2
d.daq.vnormal = {'Time', 'heat', 'virmenIteration'}; % list normal (not circular, not categorical) daq variables you want to process; virmenIteration is averaged by imaging frame, output is converted to frame number in the usual way
d.daq.vcircular = {'ficTracIntSide', 'ficTracIntForward', 'ficTracYaw', 'g4panels'}; % list circular daq variables you want to process
d.daq.vcategorical = {'ftcam'}; % list categorical daq variables you want to process
d.daq.toballscale = {'ficTracIntSide', 'ficTracIntForward'}; % define which vars to rescale from radians to mm
d.daq.tounwrap = {'ficTracIntSide', 'ficTracIntForward'}; % define which vars to unwrap
d.daq.tozero = {'ficTracIntSide', 'ficTracIntForward'}; % %define which vars to zero (force to start at 0)
d.daq.voltmin = 0; % daq voltage min; need to find this in metadata
d.daq.voltmax = 10; % daq voltage max, need to find this in metadata
d.daq.use_carls_epochs = 1; %1 for carl, 0 for everybody else; use vector of epoch indices defining stimulus state for each sample of trial; vector is created in socket code to control stimulus state, then saved at end of experiment; for old recordings file was not saved, so use_carls_epochs recreates that vector in the same way the socket code did
d.daq.doplt = 0; % if 1, will plot original and resampled timeseries in same figure, overlain, by default partitioned into 20 segments, one on each frame of a gif


%% sld (stackld: load, process stack)

d.sld.chanuse = [1 2]; % which PMT channel to use ,1, or 2, or [1 2]; ignored if requested channel doens't exist
d.sld.cropfb = 1; %crop flyback frames from each volume
d.sld.zerostack = 1; %subtract min to make min zero
d.sld.tcropfront = 0; %how many samples to remove from beginning of stack; similar to cropdata in rec6 (also applied in metrics2 without variable name cropdata), crop first 4 and last 2 imaging frames (stimulus features, and deprecated responses, have been extracted with this cropping in rec6)
d.sld.tcropback = 0; % how many samples to remove from end of stack
d.sld.stackdtype = 'uint16';
d.sld.smsdspace = 0; %smooth the stack in time, 0 to skip
d.sld.smsdtime = 0; %smooth the stack in time, 0 to skip
d.sld.dostats = 0; %turns on/off do_plot_stack_stats, which is old/inefficient and needs to be updated, but is not useless
d.sld.suffixplt = { %stack suffixes to plot together in stackplt gif, nonexistent or invalid suffixes are ignored; will be reordered from least to most processed (by suffix length)
    %'raw', ...
    %'cmrg', ...
    %'cmrg_dcdn', ...
    %'bksb_cmrg_dcdn', ...
    %'bksb_cmrg_dcdn_nosn'
    };


%% ftv (ftvproc: load, align, resample fictrac video if not on daq)

d.ftv.num_periodic_peaks_defining_laser_oscillations = 10; %in laser oscillation timeseries, number of contiguous peaks with periodic distance to be considered the start of the imaging trial, and also the end when applied in the reverse direction; this could just be same as numvol, but in case there are missing peaks, making this number smaller . . . max would be  round(numvol*0.8)
d.ftv.smsdspace = 2; %std of gaussian smoothing filter applied to average frame of fictrac video, prior to finding the brightest pixels (to locate laser)
d.ftv.numpix_to_extract_laser_timeseries = 10; %after spatial smoothing, number of pixels to average on each frame of fictrac video; these are the brightest 'numpix_to_extract_laser_timeseries' pixels in the mean frame of fictrac video
d.ftv.smsdtime = 6; %std of gaussian smoothing filter applied to laser timeseries, to help denoise timeseries prior to findpeaks (to help find the true laser oscillation peaks)
d.ftv.doplt = 0; %0 skips plots, 1 plots and saves, 2 saves but does not display


%% mroi (mroimake: draw and/or automatically segment morphological rois, extract and normalize their responses)

% options for making morphological rois (manual or automated), mostly used in function mroimake
% for o.mroi.auto.use_hires, o.mroi.dodraw, and o.mroi.auto.num_mroi_auto: use empty cell to skip, otherwise a cell array of strings from regionex_all;any string in regionex_all that is missing in o.mroi will be skipped

d.mroi.dodraw = 0; %whether to draw rois in an interactive plot, and save, or load if already drawn and saved
d.mroi.chandraw = [1]; %which channel(s) to use as background for roi drawing; 'both' will draw on sum
d.mroi.chancp = [1]; %which channel's rois to copy onto the other (concatenated with any other rois on that channel, ie does not overwrite)
d.mroi.channorm = []; %which channel to normalize the other with (dampen time-frequency regions of high wavelet coherence)
d.mroi.degdtr = 0; %polynomial for detrending before normalization; 0 to skip detrending; wavp detrends by default
d.mroi.wavp = [0 50];%[0.3 50]; %(n,2) array denoting wavelet filtering min and max period (seconds); if n>1, will use last row in output by default (n>1 is really for exploration, plotting to see how different periods affect output); empty to skip; 0 in first column will not apply lower period threshold; any number larger than max valid period (determined in wavflt) will not apply upper period threshold, but [0 inf] (or 0 and any giant number) is not the proper way to skip wavelet filtering because the algorithm will still be applied (ie timeseries will be unchanged except mean will be lost, pointlessly), so use [] to skip wavelet filtering
d.mroi.doplt = 0; %do plots besides overlay and imhsv in mroimake and mroiauto
d.mroi.doroiol = 0; %plot or don't plot roi overlay with background, plots one roi at a time, each slice, with roi in red
d.mroi.doimhsv = 0; %plot or don't plot hsv image with roi as hue

%% seg (mroiauto: automated morphological roi extraction, can be applied to drawn rois)

d.seg.chan = [1]; %which channel for auto mroi extraction (for now all options below are same for each) option where auto rois interact has not been written yet);
d.seg.numroi = 128; %partition regionex into num_mroi_auto morphological rois; a drawn roi, if it exists, masks the regionex prior to automated super-roi extraction; num_mroi_auto and number drawn rois cannot both exceed 1 (i.e. the code cannot automatically partition discontiguous rois within a single regionex)
d.seg.usehires = 0; %cell of regionex strings, use hi-z-res stack to help make morphological rois (to help 3d edge detection of region boundaries, and to help automated subdivision of 3d region into morphological rois)
d.seg.maskmake = 'nonzero'; %'nonzero'; %method for automatically defining morphological roi mask (union of all morphological rois) from stack or union of manually drawn rois, options are 'edge', 'outlier', 'triangle', 'nonzero'
d.seg.maskseg = 'uniform'; %'skeleton' for elongated structures or 'uniform'; method for subsampling mask into rois; for 'uniform', o.mroi.auto.num_mroi_auto_str must be power of 2 and works best for convex structures since for concave structures it will find rois outside the structure but can be masked to remove orois outside the structure afterward
d.seg.edgethr = [.1, .7]; %two thresholds to detect strong and weak edges; includes weak edges in output only if they are connected to strong edges
d.seg.edgesig = [sqrt(2)*2 sqrt(2)*2 sqrt(2)*2]; %for edge detection, defines smoothing filter sigma for each dim xyz, or use one value for all dim, if 2d edge detection, first element is used for x and y
d.seg.celsz = 8; %for bwmorph close after edge detection, helps connect edges
d.seg.do3d = 1; %1 makes 3d mask unless stack is 2d, 0 makes 2d mask for 2d, 3d, or 4d stack input
d.seg.doplt = 0;

%% froi (froiproc: load, process, cluster, normalize functional rois/responses output by caiman in extract.py)

d.froi.roistr = {'2_1_*_*_*_*_*_1000_*_*_graph_2dex'}; % cell array of caiman param strings (in filename of roi file output by scopa pre), can use wildcards, empty to skip
d.froi.minpixperreg = 3; % min pix in each distongiguous region, roi selection criterion
d.froi.minroisz = 5; % pixels, roi selection criterion
d.froi.maxroisz = 300; % pixels
d.froi.maxregperroi = 4; % for discontiguous rois
d.froi.inmaskthr = 0.5; % discard roi if more than inmaskthr is outside morphological mask (morph mask is all ones if you don't make one)
d.froi.numbins = 20; % num hist bins for rval and snr caiman output
d.froi.roisrt = 'majoraxis'; % 'snr' sorts by caiman output cmsnr, 'none' doens't sort, 'majoraxis' if morphological rois exist, 'majoraxis' will sort along 3d major axis
d.froi.doplt = 0; %plot roi overlay


%% nrm (respnorm: normalize roi timeseries)

% options for response extraction/normalization of morphological roi responses (o.mroi.norm)
% precluster normalization is applied before clustering (i.e. normalization of each pixel in roi, or subroi within a larger roi)
% postcluster normalization is applied after clustering (ie to each roi)
% clustering means averaging data for all pixels or caiman rois within a morphological roi
% precluster and postcluster are each a list of strings specifying different
% normalization methods, each must have at least one string (use 'f' for no normalization)
% all normalizations are applied to individual (vector) timeseries
% normalization strings are listed below; they can be combined arbitrarily and if combined, will be applied left to right order (eg 'nnbox' applies 'nn' then 'box'):
% 'f': no normalization
% 'dffuuuvvv': sliding window dff, uuu is percentile to compute f0 for each window, vvv is sliding window length in seconds, if vvv is 000 then f0 is computed across the entire timeseries, not a sliding window (e.g. dff010008 is 10th percentile over 8-seconde sliding window)
% 'rscxxxyyy': rescale, sending xxx percentile to 0, yyy percentile to 1 (eg rsc000100 is same as default matlab rescale function)
% 'z': zscore
% 'nn': nonnegative (subtract min)
% 'box': box-cox

d.nrm.pre = {'f'}; %must have at least one string, compsed of syllables above
d.nrm.post = {'f', 'rsc000100'}; %must have at least one string, compsed of syllables above
d.nrm.doplt = 0;

%% pop (popcmp: compute population features from roi timeseries, e.g. bump)

d.pop.id = []; %currently just a wrapper for bump routine (bumpcmp)

%% bump (bumpcmp: compute bump)

% options for bump in bumpcmp function
% a von mises is fit to the instantaneous relationship between each roi timeseries (given by all matches from o.bump.mfit.tg.v1) and all matches from o.bump.mfit.tg.v2
% the value of the independent variable at the max predicted response is the preferred heading for each roi
% if o.bump.domain_methodis 'functional', these preferred headings are used as the angle, and o.bump.mfit.tg.v1 as the magnitude, in computing pva
% if the regionex in o.bump.mfit.tg.v1 is in o.bump.numcluster_for_bump_domain_resample, and that regionex is followed by hyphen and number greater than zero, these preferred heading angles are resampled into that number, so that the rois evenly sample range 0-2pi (resampling changes angle and magnitude)
% if o.bump.domain_methodis 'morphological', angle is forced to be 0-2pi, with each roi evenly sampling that range

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
d.bump.domain_method = 'functional'; %'functional' to define circular domain with fit to each roi, or 'morphological' to define as circle across region mask
d.bump.bump_subdomain = {'all'}; %cell array of char, 'all', 'right', 'left', 'larger', 'weighted', 'random'
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

% to specify independent and dependent variables for model fitting, use o.mfit.tg.v2 and o.mfit.tg.v1
% format o.mfit(i).tg.v1{j} = {fieldspec1, fieldspec2, ... fieldspecN};
% format o.mfit(i).tg.v2{j} = {fieldspec1, fieldspec2, ... fieldspecN};

% where fieldspec is a pattern used to match the flattened struct fieldname, with wildcard (*) allowed anywhere

% fieldspec for ts.resp would follow the pattern ['tsclass.regionex.parsex.normex']
% where tsclass is a field in the first level of struct 'ts'
% regionex is region extraction string in o.mn.regionex_all above,
% parsex is extraction param string
% normex is normalization param string

% for ts.ball and ts.vis, fieldspec only has two levels, since ball and vis are not derived from specific brain regions, or roi extraction runs
% for ts.bump, fieldspec has 6 levels (the same four as bump.resp, with 2 more specifying bump domain, and bump parameter, following this pattern
% ['tsclass, regionex, parsex, normex, bumpdomain, bumpparam']
% for all substrings in fieldspec, you can use '*' as wildcard, all matches will be used (or a single * will match all timeseries in ts)
% you can use multiple fieldspec, all matches in a single outer cell (index j) will be grouped into a variable for fitting
% any field defined for the first struct index but not subsequent will be copied from the first
% o.mfit.tg.v2 and o.mfit.tg.v1 are matched by index i in o.mfit(i)
% within a single o.mfit(i).tg.v2 or o.mfit(i).tg.v1, you can specify multiple cells with index j, in single o.mfit(i).indv{j} or o.mfit(i).tg.v1{j}
% all combinations of single o.mfit(i).indv and single o.mfit(i).depv at the outer cell level are used
%for now, depv at single struct and outer cell level should come from single regionex

d.mfit.num_synthetic_depv = 0; %create synthetic data (using requested mdlname options, within any requested bounds) for testing fit; this is number of synthetic responses to fit; 0 to skip
d.mfit.epochinds = {[1]};
d.mfit.mdl_lag_sec = 0; %0 is one sample, how many samples indv precedes depv for model fit . . . for now, must be nonnegative integers, range 0 to lenfit_samp-1
d.mfit.mdl_length_sec = 2; %seconds, 0 is one sample
d.mfit.keep_transition_zones = 0; %1 to keep multi-timepoint model samples that have multiple epochs
d.mfit.validation_fold = 6; %applied to all mdlnames; k in k-fold cross-validation; k non-overlapping validation sets; if numbouts of each epoch in epochinds is divisible by validation_fold, will validate on numbouts/validation_fold bouts for each epoch in epochinds; if only one bout for each epoch, will evenly split each bout into k validation sets; otherwise will error; 0 skips validation
d.mfit.validation_split_style = 'boutsamples'; %'samples' or 'bouts' or 'boutsamples' %applied to all mdlnames; k in k-fold cross-validation; k non-overlapping validation sets; if numbouts of each epoch in epochinds is divisible by validation_fold, will validate on numbouts/validation_fold bouts for each epoch in epochinds; if only one bout for each epoch, will evenly split each bout into k validation sets; otherwise will error; 0 skips validation
d.mfit.slvrg = 'globalsearch';
d.mfit.slvrl = 'fmincon'; %'lsqcurvefit';
d.mfit.mdlname = 'fnet_A01_sh16'; %'svd' or fnet string (see notes_mdlname.m)
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

d.tg.v1{1} = {['']};
d.tg.v2{1} = {['']};
d.tg.v3{1} = {['']};
d.tg.v4{1} = {['']};
d.tg.v5{1} = {['']}; 
d.tg.v6{1} = {['']}; 
d.tg.v7{1} = {['']};
d.tg.v8{1} = {['']};

%% pltx (pltx: explore various components of experiment in interactive plots, e.g. brain images, timeseries, stimulus videos, scatterplots, fictive path, model components)

d.pltx.vpmapl = [1 2 3 4]; %map of indices of each tg.v above to plot positions (on left axis)
d.pltx.vpmapr = [5 6 7 8]; %map of indices of each tg.v above to plot positions (on right axis)

d.pltx.lagsxy_sec = linspace(-1, 1, 1e4); %empty or zero to skip; scalar or vector; seconds of lag, rounded to nearest frame; repeated frames are omitted; to see all frames within range, use spacing smaller than sample rate (just use very small spacing to ensure it, so you don't have to think about it, like this linspace(-1, 1, 1e4)); negative means x follows y, positive means y follows x;
d.pltx.lagsz_sec = linspace(-1, 1, 1e4); %same as lagxy_sec, except z lags are applied for each xy lag (xy vars are lagged, then together lagged relative to z); will be automatically set to 0 if there is no z variable
d.pltx.lags_to_plot = 'best'; % 'zero', 'best', 'zeroandbest', 'all'
d.pltx.plot_z_as_color = 1; %if z variable exists, 0 will make 3d scatterplot, 1 will make 2d with z variable as color

d.pltx.epochinds = {[1]}; %cell array of vectors or scalars listing epochs (within single trial) to group in scatterplots, empty cell with empty vector for all epochs, like this {[]}
d.pltx.gifvis = 'on'; %0 will save but not plot, 1 will do both

d.pltx.iz = []; %z indices to plot, empty for all, negative for that number equidistant from all available
d.pltx.it = []; %[3320]; %t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
d.pltx.dr = [0,1];
d.pltx.letui = 1;

%% hires (hiresld: load and register high-z-res stack if it exists)

%options for hires stack (high z resolution version of main stack) . . . this code is a little deprecated
%hires stack is only used in making morphological rois, set o.mroi.auto.use_hires=1 to use
%options below, in o.hires, are for processing the hires stack, and visualization with gif in o.hires.gif

d.hires.disttype = 'monomodal'; % multimodal monomodal, used in register_one_stack_to_another_in_3d from within register_3d_hires_to_3d_lores
d.hires.regtype = 'rigid'; %3d registration type (rigid should be best for tiny fly brain), used in register_one_stack_to_another_in_3d from within register_3d_hires_to_3d_lores
d.hires.use_caiman_on_hires = 0; %keep at 0 bc pipeline not yet finished for this option (also doens't seem to help)
d.hires.caiman_hr_str = '*'; %empty to skip
d.hires.doplt = 0;

%% tp (tsplt: plot timeseries) 

d.tp.predlot_norm = 'each'; %amplotude normalization for the detail plots at bottom, 'all' normalizes to population, 'each' normalizes to each
d.tp.maxnumroiplot = 100; %number of rois that get detail view on the bottom, one per gif frame
d.tp.sort_method = 'unbiased'; %'majoraxis', 'unbiased', 'gof', 'custom'; %how to select rois for detail plots, 'unbiased' for equidistant maxnumroiplot, 'gof' for equidistant maxnumroiplot sorted by gof in descending order (so starts with best fit ends with worst)
d.tp.gifvis = 'on'; %on shows gif while plotting/writing/saving, off saves/writes but doesn't show it
d.tp.max_tinds = 1000; %1000; %for the timeseries view of depv, how many samples to plot at the most (will take indices 1:max_tinds), big number to plot all
d.tp.timeseries_numsegments = 3; %how many equispaced segments to display in setail view, ending at final frame
d.tp.plot_class = 'hsv'; %hsv only shows one epoch per plot/gif frame, epoch shows multiple epochs but no hsv map
d.tp.plot3d = 0;

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
d.imhsv.huenorm = 'native'; %hue normalization method, 'native' normalizes to a preset range (hard coded in plots_setup_hsv) according to 'mdlname', 'relative' normalizes to the data range assigned to hue, 'manual' normalizes to the range set below in opt.mroi.hsv.hrange_in_manual; if you request 'native' but don't pass huelimnat to hsvcmp it will switch to 'relative'; if you request 'manual' but don't set hrange_in_manual it will switch to 'relative'
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


%% globals

glb(1, regionexdf=d.mn.regionex, timestr=d.mn.timestr, validsuffix=d.recspec.validsuffix); %set some globals, force update if they already have been set with first argument 1


%% for output oout, update defaults with input oin

if isempty(oin) || isempty(fieldnames(oin))
    oin = d;
end

if isfield(oin, 'copybinall')
    copybinall = oin.copybinall;
else
    copybinall = [];
end

if isempty(funbin)
    o = optupdate(oin, d, copybinall, copybin);
else
    fn = fieldnames(oin);
    if ~iscell(funbin)
        funbin = {funbin};
    end
    for w = 1:numel(funbin)
        if contains(funbin{w}, '.')
            funbintmp = strsplit(funbin{w}, '.');
            parbintmp = funbintmp(1:end-1);
            funbintmp = funbintmp(end);
        else
            funbintmp = funbin{w};
        end
        if ismember(funbintmp, fn)
            oinsub.(funbintmp) = oin.(funbintmp);
            oin = rmfield(oin, funbintmp);
        else
            if ~isfield(d, funbintmp)
                error(sprintf("d." + funbintmp) + " does not exist")
            end
            oinsub.(funbintmp) = d.(funbintmp); %use all defaults funbintmp is not in oin
        end
    end
    o = optupdate(oinsub, d, copybinall, copybin);
    if isempty(copybin) %if 2-argument syntax, just update funbin
        o = cell2struct([struct2cell(oin); struct2cell(o)],[fieldnames(oin); fieldnames(o)]);
    else %if 3-argument syntax, update funbin and place in copybin, and update ~funbin without placing in any copybin
        if ~isempty(fieldnames(oin)) 
            ointmp = optupdate(oin, d, copybinall, []);
            o = cell2struct([struct2cell(ointmp); struct2cell(o)],[fieldnames(ointmp); fieldnames(o)]);
        end
    end
end


o.copybinall = unique([copybinall, copybin]); %keep record of copybin, to ignore them in optupdate

o = fieldord(o);


end






