function oout = odf(oin, sub)

arguments
    oin = []
end
arguments (Repeating)
    sub
end

% struct 'o' holds all default options
% fields directly under o are mostly used within single functions called from a2p, except mn, which is used in a2p direcly
% each section contains options for a major routine called in a2p (section header is options field name, with function name in parentheses, and brief description of function)

%% recspec (filefind: find files matching recording specifications)

o.recspec.recdate = {'*'}; %cell array of char, can use wildcards
o.recspec.fly = {'*'}; %cell array of char, can use wildcards
o.recspec.trial = {'*'}; %cell array of char, can use wildcards
o.recspec.suffix = {'raw'}; %cell array of char; can use wildcards, scopa 'pre' pipeline output filename suffix to use in this 'post' pipeline (or 'raw' for raw tif output by scanimage/flyg); valid suffixes are defined in validsuffix
o.recspec.match = 'each'; %'any' for all combinations of recdate, fly, trial, suffixstack, 'each' for matched indices of each (length 1 will be repeated to match anything longer)
o.recspec.pthparent_local = '~/stacks'; %on local machine, full path to folder containing all recording folders
o.recspec.pthparent_o2 = ''; %on o2, full path to folder containing all recording folders, leave empty to automatically find path in /n/files/scratch with same parent folder name as o.mn.pthparent_local; ap2 will automatically determine if you're on O2; example path is '/n/scratch/users/c/caw846/stacks/'
o.recspec.validsuffix = {'raw', 'cmrg', 'cmrg_dcdn', 'bksb_cmrg', 'bksb_cmrg_dcdn', 'bksb_cmrg_dcdn_nosn'}; %all valid suffixes on files (all tifs, except for '*nosn', output by 'pre' part of scopa pipeline (pipeline_init.py, cxp.sh); 'raw' is raw tif file output by scanimage (not scopa 'pre'), which will not actually have suffix 'raw' (unless you're carl, who renames the flyg/scanimage raw files with suffix 'raw')


%% mn (ap2: main pipeline control in a2p)

o.mn.dodaq = 1; %process daq data
o.mn.doftv = 1; %temporal resample fictrac video to match imaging (only relevant if you've not set up proper sync to daq)
o.mn.dopop = 0; %compute population features (o.pf below)
o.mn.dofit = 0; %model fitting (o.mfit below)
o.mn.dopltx = 1; %plot experiment (o.pltx below)
o.mn.fldrtmp = 'scopatmp'; %will be created in same dir as stacks, stores small tmp files used in interactive figures; getActiveFilename is problematic on O2 so using this approach instead
o.mn.timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));


%% daq (daqld: load, process daq)

o.daq.useinds = 'none'; % 'none', 'slice', 'vol', 'all', or numeric vector of slice indices, with optional 0 to mean volume indices; 'none' (resample using 'resample' function with padding to avoid start/end transients), 'slice' (resample using all slice indices), 'vol' (resample using volume indices), 'all' (resample using all slice indices and volume indices), numeric vector defines which slice indices (one indexed) to use with 0 denoting volume index resampling (eg [0 4] will resample with volume and slice 4); 'none' is fastest but has a little more aliasing, which is probably rarely a problem; slice resampling is included especially for slow imaging rate, or large flyback; the more resampling registers are used, the slower this function on first run (output is saved/loaded for subsequent runs)
o.daq.usefbl = 1; % whether to include flyback lines when resampling with frame indices (if useinds is not 'none')
o.daq.usefbf = 1; % whether to include flyback frames when resampling with volume indices (if useinds is not 'none')
o.daq.balldia = 9; % mm, used to convert fictrac variables into mm
o.daq.slopelensec = 0.4; % window numel used to fit slope (to compute daq variable derivatives (eg velocities)
o.daq.slopeord = 2; % order of polynomial used to fit local slope; this should probably just remain 2
o.daq.vnormal = {'Time', 'heat', 'virmenIteration'}; % list normal (not circular, not categorical) daq variables you want to process; virmenIteration is averaged by imaging frame, output is converted to frame number in the usual way
o.daq.vcircular = {'ficTracIntSide', 'ficTracIntForward', 'ficTracYaw', 'g4panels'}; % list circular daq variables you want to process
o.daq.vcategorical = {'ftcam'}; % list categorical daq variables you want to process
o.daq.toballscale = {'ficTracIntSide', 'ficTracIntForward'}; % define which vars to rescale from radians to mm
o.daq.tounwrap = {'ficTracIntSide', 'ficTracIntForward'}; % define which vars to unwrap
o.daq.tozero = {'ficTracIntSide', 'ficTracIntForward'}; % %define which vars to zero (force to start at 0)
o.daq.voltmin = 0; % daq voltage min; need to find this in metadata
o.daq.voltmax = 10; % daq voltage max, need to find this in metadata
o.daq.doplt = 0; % if 1, will plot original and resampled timeseries in same figure, overlain, by default partitioned into 20 segments, one on each frame of a gif
o.daq.use_carls_epochs = 1; %1 for carl, 0 for everybody else; use vector of epoch indices defining stimulus state for each sample of trial; vector is created in socket code to control stimulus state, then saved at end of experiment; for old recordings file was not saved, so use_carls_epochs recreates that vector in the same way the socket code did


%% sld (stackld: load, process stack)

o.sld.chanuse = [1 2]; % which PMT channel to use ,1, or 2, or [1 2]; ignored if requested channel doens't exist
o.sld.cropfb = 1; %crop flyback frames from each volume
o.sld.zerostack = 1; %subtract min to make min zero
o.sld.tcropfront = 0; %how many samples to remove from beginning of stack; similar to cropdata in rec6 (also applied in metrics2 without variable name cropdata), crop first 4 and last 2 imaging frames (stimulus features, and deprecated responses, have been extracted with this cropping in rec6)
o.sld.tcropback = 0; % how many samples to remove from end of stack
o.sld.stackdtype = 'uint16';
o.sld.smsdspace = 0; %smooth the stack in time, 0 to skip
o.sld.smsdtime = 0; %smooth the stack in time, 0 to skip
o.sld.dostats = 0; %turns on/off do_plot_stack_stats, which is old/inefficient and needs to be updated, but is not useless
o.sld.suffixplt = { %stack suffixes to plot together in stackplt gif, nonexistent or invalid suffixes are ignored; will be reordered from least to most processed (by suffix length)
    %'raw', ...
    %'cmrg', ...
    %'cmrg_dcdn', ...
    %'bksb_cmrg_dcdn', ...
    %'bksb_cmrg_dcdn_nosn'
    };


%% ftv (ftvproc: load, align, resample fictrac video if not on daq)

o.ftv.num_periodic_peaks_defining_laser_oscillations = 10; %in laser oscillation timeseries, number of contiguous peaks with periodic distance to be considered the start of the imaging trial, and also the end when applied in the reverse direction; this could just be same as numvol, but in case there are missing peaks, making this number smaller . . . max would be  round(numvol*0.8)
o.ftv.ftvid_spatial_smooth_window_std = 2; %std of gaussian smoothing filter applied to average frame of fictrac video, prior to finding the brightest pixels (to locate laser)
o.ftv.numpix_to_extract_laser_timeseries = 10; %after spatial smoothing, number of pixels to average on each frame of fictrac video; these are the brightest 'numpix_to_extract_laser_timeseries' pixels in the mean frame of fictrac video
o.ftv.laser_timeseries_smooth_window_std = 6; %std of gaussian smoothing filter applied to laser timeseries, to help denoise timeseries prior to findpeaks (to help find the true laser oscillation peaks)
o.ftv.doplt = 1; %0 skips plots, 1 plots and saves, 2 saves but does not display


%% mroi (mroimake: draw and/or automatically segment morphological rois, extract and normalize their responses)

% options for making morphological rois (manual or automated), mostly used in function mroimake
% for o.mroi.auto.use_hires, o.mroi.dodraw, and o.mroi.auto.num_mroi_auto: use empty cell to skip, otherwise a cell array of strings from regionex_all;any string in regionex_all that is missing in o.mroi will be skipped

o.mroi.chancp = [1]; %which channel's rois to copy onto the other (concatenated with any other rois on that channel, ie does not overwrite)
o.mroi.channorm = []; %which channel to normalize the other with (dampen time-frequency regions of high wavelet coherence)
o.mroi.degdtr = 0; %polynomial for detrending before normalization; 0 to skip detrending; wavp detrends by default
o.mroi.wavp = [0 50];%[0.3 50]; %(n,2) array denoting wavelet filtering min and max period (seconds); if n>1, will use last row in output by default (n>1 is really for exploration, plotting to see how different periods affect output); empty to skip; 0 in first column will not apply lower period threshold; any number larger than max valid period (determined in wavflt) will not apply upper period threshold, but [0 inf] (or 0 and any giant number) is not the proper way to skip wavelet filtering because the algorithm will still be applied (ie timeseries will be unchanged except mean will be lost, pointlessly), so use [] to skip wavelet filtering
o.mroi.doplt = 0; %do plots besides overlay and imhsv in mroimake and mroiauto

o.mroi.dodraw = 0; %whether to draw rois in an interactive plot, and save, or load if already drawn and saved
o.mroi.chandraw = [1]; %which channel(s) to use as background for roi drawing; 'both' will draw on sum

%%options for the automated morphological roi extraction (will be applied to drawn morphological rois, if they exist . . . for example, you draw a roi around a region, then there is automated morphological segmentation within that region)
o.mroi.auto.chan = [1]; %which channel for auto mroi extraction (for now all options below are same for each) option where auto rois interact has not been written yet);
o.mroi.auto.numroi = 128; %partition regionex into num_mroi_auto morphological rois; a drawn roi, if it exists, masks the regionex prior to automated super-roi extraction; num_mroi_auto and number drawn rois cannot both exceed 1 (i.e. the code cannot automatically partition discontiguous rois within a single regionex)
o.mroi.auto.usehires = {''}; %cell of regionex strings, use hi-z-res stack to help make morphological rois (to help 3d edge detection of region boundaries, and to help automated subdivision of 3d region into morphological rois)
o.mroi.auto.maskmake = 'nonzero'; %'nonzero'; %method for automatically defining morphological roi mask (union of all morphological rois) from stack or union of manually drawn rois, options are 'edge', 'outlier', 'triangle', 'nonzero'
o.mroi.auto.maskseg = 'uniform'; %'skeleton' for elongated structures or 'uniform'; method for subsampling mask into rois; for 'uniform', o.mroi.auto.num_mroi_auto_str must be power of 2 and works best for convex structures since for concave structures it will find rois outside the structure but can be masked to remove orois outside the structure afterward
o.mroi.auto.edgethr = [.1, .7]; %two thresholds to detect strong and weak edges; includes weak edges in output only if they are connected to strong edges
o.mroi.auto.edgesig = [sqrt(2)*2 sqrt(2)*2 sqrt(2)*2]; %for edge detection, defines smoothing filter sigma for each dim xyz, or use one value for all dim, if 2d edge detection, first element is used for x and y
o.mroi.auto.celsz = 8; %for bwmorph close after edge detection, helps connect edges
o.mroi.auto.do3d = 1; %1 makes 3d mask unless stack is 2d, 0 makes 2d mask for 2d, 3d, or 4d stack input

o.mroi.normpre = {'f'}; %must have at least one string, compsed of syllables above
o.mroi.normpost = {'f', 'rsc000100'}; %must have at least one string, compsed of syllables above

%options for roi overlay plot of morophological rois (make a gif showing each z slice of mean t stack)
o.mroi.roiol.do = 0; %plot or don't plot roi overlay with background, plots one roi at a time, each slice, with roi in red
o.mroi.roiol.ir = [1 3 5]; %scalar/vector; which rois to plot in overlay
o.mroi.roiol.roi_color = [1 0 0]; %color for roi overlay
o.mroi.roiol.roialpha = 0.3; %transparency for roi overlay

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


%% froi (froiproc: load, process, cluster, normalize functional rois/responses output by caiman in extract.py)  

o.froi.roistr = {'2_1_*_*_*_*_*_1000_*_*_graph_2dex'}; % cell array of caiman param strings (in filename of roi file output by scopa pre), can use wildcards, empty to skip
o.froi.minpixperreg = 3; % min pix in each distongiguous region, roi selection criterion
o.froi.minroisz = 5; % pixels, roi selection criterion
o.froi.maxroisz = 300; % pixels
o.froi.maxregperroi = 4; % for discontiguous rois
o.froi.inmaskthr = 0.5; % discard roi if more than inmaskthr is outside morphological mask (morph mask is all ones if you don't make one)
o.froi.numbins = 20; % num hist bins for rval and snr caiman output
o.froi.roisrt = 'majoraxis'; % 'snr' sorts by caiman output cmsnr, 'none' doens't sort, 'majoraxis' if morphological rois exist, 'majoraxis' will sort along 3d major axis
o.froi.doplt = 0; %plot roi overlay
o.froi.normpre = {'f'}; %must have at least one string, compsed of syllables above
o.froi.normpost = {'f', 'rsc000100'}; %must have at least one string, compsed of syllables above


%% pop (popcmp: compute population features from roi timeseries, e.g. bump) 


%% bump (bumpcmp: compute bump)

% options for bump in bumpcmp function
% a von mises is fit to the instantaneous relationship between each roi timeseries (given by all matches from o.bump.mfit.varnms.depvp) and all matches from o.bump.mfit.varnms.indvp
% the value of the independent variable at the max predicted response is the preferred heading for each roi
% if o.bump.domain_methodis 'functional', these preferred headings are used as the angle, and o.bump.mfit.varnms.depvp as the magnitude, in computing pva
% if the regionex in o.bump.mfit.varnms.depvp is in o.bump.numcluster_for_bump_domain_resample, and that regionex is followed by hyphen and number greater than zero, these preferred heading angles are resampled into that number, so that the rois evenly sample range 0-2pi (resampling changes angle and magnitude)
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
o.bump.mthd = 'pva'; %'pva' for vector average
o.bump.domain_method = 'functional'; %'functional' to define circular domain with fit to each roi, or 'morphological' to define as circle across region mask
o.bump.bump_subdomain = {'all'}; %cell array of char, 'all', 'right', 'left', 'larger', 'weighted', 'random'
o.bump.slopeord = 2; %order of polynomial used to fit local slope (e.g. to compute bump speed)
o.bump.slopelensec = 5; %order of polynomial used to fit local slope (e.g. to compute bump speed)
o.bump.smoothwindow_sec = 0.2; %full width of gaussian smoothing window (5 times std)
o.bump.numcluster_for_bump_domain_resample = 16; %how many clusters/superrois across the entire region (not hemisphere) when resampled uniformly prior to computing bump as vector average, regionex must exist in matches to o.bump.mfit.varnms.depvp  . . . to skip resampling for a regionex, just don't list it here, or write 'regionex-0'
o.bump.resample_smoothfac = 1; %when resampling compass, bandwidth of the antialiasing filter, larger number will have smoother resampled compass
o.bump.rescale_clusters = 1; %just before computing bump, rescale each cluster's timeseries to range 0-1
o.bump.omitnan = 1; %ignore nans in case there are any (e.g., making hybrid morph-func rois, some morph rois have no func members, making their response 'nan', omit will ignore this in computing pva)
o.bump.doplt = 0;



%% mfit (mfit: fit models to individual roi responses)

% options for modeling depv as function of indv in mfit function

% to specify independent and dependent variables for model fitting, use o.mfit.varnms.indvp and o.mfit.varnms.depvp
% format o.mfit(i).varnms.depvp{j} = {fieldspec1, fieldspec2, ... fieldspecN};
% format o.mfit(i).varnms.indvp{j} = {fieldspec1, fieldspec2, ... fieldspecN};

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
% o.mfit.varnms.indvp and o.mfit.varnms.depvp are matched by index i in o.mfit(i)
% within a single o.mfit(i).varnms.indvp or o.mfit(i).varnms.depvp, you can specify multiple cells with index j, in single o.mfit(i).indv{j} or o.mfit(i).varnms.depvp{j}
% all combinations of single o.mfit(i).indv and single o.mfit(i).depv at the outer cell level are used
%for now, depv at single struct and outer cell level should come from single regionex

o.mfit.do = 1;
o.mfit.varnms.depvp = {...
    ['resp, *, *, *'], ...
    };
o.mfit.varnms.indvp = {...
    {['resp, *, *, *']}...
    };
o.mfit.ignore_missing_vars = 0;
o.mfit.num_synthetic_depv = 0; %create synthetic data (using requested mdlname options, within any requested bounds) for testing fit; this is number of synthetic responses to fit; 0 to skip
o.mfit.epochinds = {[4]};
o.mfit.mdl_lag_sec = 0; %0 is one sample, how many samples indv precedes depv for model fit . . . for now, must be nonnegative integers, range 0 to lenfit_samp-1
o.mfit.mdl_length_sec = 2; %seconds, 0 is one sample
o.mfit.keep_transition_zones = 0; %1 to keep multi-timepoint model samples that have multiple epochs
o.mfit.validation_fold = 6; %applied to all mdlnames; k in k-fold cross-validation; k non-overlapping validation sets; if numbouts of each epoch in epochinds is divisible by validation_fold, will validate on numbouts/validation_fold bouts for each epoch in epochinds; if only one bout for each epoch, will evenly split each bout into k validation sets; otherwise will error; 0 skips validation
o.mfit.validation_split_style = 'boutsamples'; %'samples' or 'bouts' or 'boutsamples' %applied to all mdlnames; k in k-fold cross-validation; k non-overlapping validation sets; if numbouts of each epoch in epochinds is divisible by validation_fold, will validate on numbouts/validation_fold bouts for each epoch in epochinds; if only one bout for each epoch, will evenly split each bout into k validation sets; otherwise will error; 0 skips validation
o.mfit.slvrg = 'globalsearch';
o.mfit.slvrl = 'fmincon'; %'lsqcurvefit';
o.mfit.mdlname = 'fnet_A01_sh16'; %'svd' or fnet string (see notes_mdlname.m)
o.mfit.excludeopts = '';
o.mfit.normalize_indv = 'minmaxcnt'; %'minmax' range [0,1], 'minmaxcnt' range [-1,1], 'zscore' mean 0 unit var, 'none' . . . normalization used in fitting model but not all plotting . . . don't forget mse sensitive to scale
o.mfit.normalize_depv = 'minmaxcnt'; %'minmax' range [0,1], 'minmaxcnt' range [-1,1], 'zscore' mean 0 unit var, 'none' . . . normalization used in fitting model but not all plotting . . . don't forget mse sensitive to scale
o.mfit.smoothdepv = 0; %gaussian window std is one fifth total length
o.mfit.smoothindv = 0; %gaussian window std is one fifth total length
o.mfit.use_saved_model = 1;
o.mfit.omit_time_from_savemodel_datestr = 1; %to prevent too many saved files, setting to 1 will use date suffix in saved model filename, rather than datetime suffix
o.mfit.optim_hist_save_iter_spacing = 2;

o.mfit.plt.predlot_norm = 'each'; %amplotude normalization for the detail plots at bottom, 'all' normalizes to population, 'each' normalizes to each
o.mfit.plt.maxnumroiplot = 100; %number of rois that get detail view on the bottom, one per gif frame
o.mfit.plt.sort_method = 'unbiased'; %'majoraxis', 'unbiased', 'gof', 'custom'; %how to select rois for detail plots, 'unbiased' for equidistant maxnumroiplot, 'gof' for equidistant maxnumroiplot sorted by gof in descending order (so starts with best fit ends with worst)
o.mfit.plt.gifvis = 'on'; %on shows gif while plotting/writing/saving, off saves/writes but doesn't show it
o.mfit.plt.max_tinds = 1000; %1000; %for the timeseries view of depv, how many samples to plot at the most (will take indices 1:max_tinds), big number to plot all
o.mfit.plt.timeseries_numsegments = 3; %how many equispaced segments to display in setail view, ending at final frame
o.mfit.plt.plot_class = 'hsv'; %hsv only shows one epoch per plot/gif frame, epoch shows multiple epochs but no hsv map
o.mfit.plt.plot3d = 0;
o.mfit.plt.doplt = 1;

%character options for different categories in different mdlnames chopt.mdlclass.category (where mdlclass is prefix of mdlname, i.e. before any optional underscore suffixes)
o.mfit.chopt.fnet.lay = {'[A-Z]{1}'}; %layer is any single capital letter
o.mfit.chopt.fnet.chan = {'^(0*\d{1,2})*(0*\d{1,2}-\d+)*$'}; %channel is zero or more two-digit numbers, with optional hyphens denoting ranges; no channel means all channels
o.mfit.chopt.fnet.comb = {'x'}; %a single x
o.mfit.chopt.fnet.prefix = {'^x*0*\d*(?=\D)'}; %optional x followed by optional 2-digit number
o.mfit.chopt.fnet.unit = {'^x*\d*((\D)*(h\d+)*(\D)*)+$'}; %optional x followed by optional 2-digit number, followed by one or more non-numeric character or one-hot encoding substring;
o.mfit.chopt.fnet.lin = {'s','r','d','c','f'}; %linear functions;
o.mfit.chopt.fnet.non = {'e','i','l','g','v'}; %nonlinear functions;
o.mfit.chopt.fnet.hot = {'h\d+'}; %one-hot encoding function; h followed by one or more numeric characters


%% pltx (pltx: explore various components of experiment in interactive plots, e.g. brain images, timeseries, stimulus videos, scatterplots, fictive path, model components)

% options for plot_experiment
% o.pltx.varnms follows the same pattern as o.mfit.varnms above

o.pltx(1).varnms.ts1{1} = {['ball.forvel']};
o.pltx(1).varnms.ts2{1} = {['']};
o.pltx(1).varnms.ts3{1} = {['']};
o.pltx(1).varnms.ts4{1} = {['']};
o.pltx(1).varnms.ts5{1} = {['resp.fb128.mo*.*chn1.ind1']}; %if empty, do will be set to false
o.pltx(1).varnms.ts6{1} = {['']}; %if empty, do will be set to false
o.pltx(1).varnms.ts7{1} = {['']};
o.pltx(1).varnms.ts8{1} = {['']};

o.pltx(1).vpmap.left = [1 2 3 4]; %map of indices of each varnms.ts above to plot positions (on left axis)
o.pltx(1).vpmap.right = [5 6 7 8]; %map of indices of each varnms.ts above to plot positions (on right axis)

o.pltx(1).lagsxy_sec = linspace(-1, 1, 1e4); %empty or zero to skip; scalar or vector; seconds of lag, rounded to nearest frame; repeated frames are omitted; to see all frames within range, use spacing smaller than sample rate (just use very small spacing to ensure it, so you don't have to think about it, like this linspace(-1, 1, 1e4)); negative means x follows y, positive means y follows x;
o.pltx(1).lagsz_sec = linspace(-1, 1, 1e4); %same as lagxy_sec, except z lags are applied for each xy lag (xy vars are lagged, then together lagged relative to z); will be automatically set to 0 if there is no z variable
o.pltx(1).lags_to_plot = 'best'; % 'zero', 'best', 'zeroandbest', 'all'
o.pltx(1).plot_z_as_color = 1; %if z variable exists, 0 will make 3d scatterplot, 1 will make 2d with z variable as color

o.pltx(1).epochinds = {[1]}; %cell array of vectors or scalars listing epochs (within single trial) to group in scatterplots, empty cell with empty vector for all epochs, like this {[]}
o.pltx(1).gifvis = 'on'; %0 will save but not plot, 1 will do both

o.pltx(1).iz = []; %z indices to plot, empty for all, negative for that number equidistant from all available
o.pltx(1).it = []; %[3320]; %t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
o.pltx(1).dr = [0,1];
o.pltx(1).letui = 1;

o.pltx = structfill(o.pltx);

%% hires (hiresld: load and register high-z-res stack if it exists)

%options for hires stack (high z resolution version of main stack) . . . this code is a little deprecated
%hires stack is only used in making morphological rois, set o.mroi.auto.use_hires=1 to use
%options below, in o.hires, are for processing the hires stack, and visualization with gif in o.hires.gif

o.hires.do_reg_plots = 0;
o.hires.disttype = 'monomodal'; % multimodal monomodal, used in register_one_stack_to_another_in_3d from within register_3d_hires_to_3d_lores
o.hires.regtype = 'rigid'; %3d registration type (rigid should be best for tiny fly brain), used in register_one_stack_to_another_in_3d from within register_3d_hires_to_3d_lores
o.hires.use_caiman_on_hires = 0; %keep at 0 bc pipeline not yet finished for this option (also doens't seem to help)
o.hires.caiman_hr_str = '*'; %empty to skip


%% sp (stackplt: plot stack with various viewing options)

o.sp.it = [50.3];%t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments (where segments are equidistant, if possible)
o.sp.iz = []; %z indices to plot, empty for all, negative for that number equidistant from all available

% display ranges for each suffix; applied in stackplt; dr represents proportion of full range, where [0,1] is full range; stack values that are proportionally within dr are linearly mapped to image intensity; less than or equal to dr(1) is mapped to image min (black); greater than or equal to dr(2) is mapped to image max (white); if stack doesn't exist its dr is ignored
o.sp.dr.raw = [0,1];
o.sp.dr.cmrg = [0,1];
o.sp.dr.cmrg_dcdn = [0,1];
o.sp.dr.bksb_cmrg_dcdn = [0,1];
o.sp.dr.bksb_cmrg_dcdn_nosn = [0,1];


%% imhsv (hsvplt and hsvcmp: hsv


o.imhsv.do = 0; %1 to plot/save, 0 to just compute hsv image but skip plot/save
o.imhsv.fg = 'allrois'; %'eachroi' plots each individually, 'allrois' plots all together
o.imhsv.mdlname = ''; %string for swithcing among plotting defaults in plots_setup_hsv, leave empty for default set
o.imhsv.huestr = ''; %deprecated variable, leave empty
o.imhsv.huenorm = 'native'; %hue normalization method, 'native' normalizes to a preset range (hard coded in plots_setup_hsv) according to 'mdlname', 'relative' normalizes to the data range assigned to hue, 'manual' normalizes to the range set below in opt.mroi.hsv.hrange_in_manual; if you request 'native' but don't pass huelimnat to hsvcmp it will switch to 'relative'; if you request 'manual' but don't set hrange_in_manual it will switch to 'relative'
o.imhsv.satnorm = 'relative'; %sat normalization method, same logic as huenorm
o.imhsv.valnorm = 'relative';%val normalization method, same logic as huenorm
o.imhsv.hrange_in_manual = []; %manual range for normalizing hue, prior to normalization to plot scale, whose max range is [0 1]), see hsvcmp
o.imhsv.srange_in_manual = []; %manual range for normalizing sat, prior to normalization to plot scale, whose max range is [0 1]), see hsvcmp
o.imhsv.vrange_in_manual = []; %manual range for normalizing val, prior to normalization to plot scale, whose max range is [0 1]), see hsvcmp
o.imhsv.hrange_out_manual = [0 0.6]; %[0.25 1]; %hue plot scale, whose max range is [0 1] hue hange around color circle, defaults to less than full circle for non-periodic plotting domain, but overwrites in plots_setup_hsv to [0 1] when plotting a periodic huefeature (e.g. von mises center, ie mdlname 'v' with huestr 'loc'), see hsvcmp
o.imhsv.srange_out_manual = [0 1]; %sat plot scale, whose max range is [0 1], if you want to force saturation you can reduce (e.g. [0 0.75] will force smaller range to max saturation, see hsvcmp
o.imhsv.vrange_out_manual = [0 1];  %val plot scale, whose max range is [0 1], if you want to force value you can reduce (e.g. [0 0.75] will force smaller range to max value, see hsvcmp
o.imhsv.hueshift = 0; %0-1, circularly shift the hue map around the color circle for change to arbitrary color assignment, applied before any clipping due to, see hsvcmp, this works for periodic or non-periodic features assigned to hue
o.imhsv.ignorehue = 0; %when creating and plotting variable 'img', which is built from variable 'hsvmap', 1 ignores hue in variable 'hsvmap', makes constant 1, but does not change 'hsvmap'
o.imhsv.ignoresat = 0;  %when creating and plotting variable 'img', which is built from variable 'hsvmap', 1 ignores sat in variable 'hsvmap', makes constant 1, but does not change 'hsvmap'
o.imhsv.ignoreval = 0;  %when creating and plotting variable 'img', which is built from variable 'hsvmap', 1 ignores val in variable 'hsvmap', makes constant 1, but does not change 'hsvmap'


%% update defaults

if isempty(oin)
    oin = struct;
end
if isempty(sub)
    nosubsub = 1;
    numloop = 1;
else
    nosubsub = 0;
    numloop = numel(sub);
end

fn = fieldnames(oin);
if numel(fn)==1
    newopt = oin.(fn{1});
    defopt = o.(fn{1});
elseif numel(fn)>1
    error("there can only be one field directly under oin")
elseif numel(fn)==0
    error("you passed an empty oin; oin must contain one field")
end

%update options for fn{1} (and subfields, recursively); fn{1} is a field of o
for k = 1:numloop
    if nosubsub
        oout = structupdate(newopt, defopt);
    else
        oout.(sub{k}) = structupdate(newopt, defopt);
    end
end

%update options for any field of fn{1} that is also a field of o (and subfields, recursively)
fn2 = fieldnames(newopt);
for m = 1:numel(fn2)
    if isfield(o, fn2{m})
        newoptsupp = newopt.(fn2{m});
        defopt = o.(fn2{m});
        for k = 1:numloop
            if nosubsub
                oout.(fn2{m}) = structupdate(newoptsupp, defopt);
            else
                oout.(sub{k}).(fn2{m}) = structupdate(newoptsupp, defopt);
            end
        end
    end
end

oout = fieldord(oout);




