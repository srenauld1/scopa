function opt = input_params_alt(varargin)



% struct 'opt' holds all input params
% substructures within opt are mostly used within single functions called from a2p

%some params below have suffix '_str'; these are string inputs (for user input convenience) that are mapped later to numeric variables

%% MAIN

%params for main pipeline control in file a2p
opt.mn.pthparent_local = '~/stacks'; %on local machine, full path to folder containing all recording folders
opt.mn.pthparent_o2 = ''; %on o2, full path to folder containing all recording folders, leave empty to automatically find path in scratch with same parent folder name as opt.mn.pthparent_local; ap2 will automatically determine if you're on O2; example path is '/n/scratch/users/c/caw846/stacks/'
opt.mn.tmp_folder_name = 'scopatmp'; %will be created in same dir as stacks, stores small tmp files used in interactive figures; getActiveFilename is problematic on O2 so using this approach instead

if isempty(varargin{1}) %if not running a2p from cxp, set filename specs here 
    opt.mn.recdate = '20240602'; %can use wildcards
    opt.mn.fly = '4'; %can use wildcards
    opt.mn.trial = '1'; %can use wildcards
    opt.mn.suffix_analysis = 'cmrg_dcdn'; %scopa 'pre' pipeline output filename suffix to use in this 'post' pipeline
    [opt.mn.pthstack, opt.mn.pth_grandparent] = find_preprocessed_files(opt.mn);
else
    opt.mn.pthstack = varargin{1};
    [pthstack, ~, ~] = fileparts(opt.mn.pthstack);
    pthstack = strsplit(pthstack, filesep);
    opt.mn.pth_grandparent = [strjoin(pthstack(1:end-2), filesep) filesep];
end


opt.mn.regionex_all = {'ebfb_eb', 'ebfb_fb'}; %cell array of strings matching regionex from scopa 'pre' pipeline; append an underscore and suffix (format existingregionex_suffix) to create a new regionex with the same croplim as existing regionex (e.g., if the cuboid from 'pre' has two subregions you want to analyze separately, including with different morphological rois);  if no match from 'pre' you will be prompted to define the regionex (i.e., to define 'croplim', a cuboid, in interactive plots)
opt.mn.timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS')) ;

opt.mn.do_daq = 0;
opt.mn.do_temporal_downsample_align_fictrac_video = 0; %temporal resample to match imaging 
opt.mn.do_popfeat = 0; %compute population features (opt.pf below)
opt.mn.do_fit = 0; %model fitting (opt.mfit below)
opt.mn.do_scatter = 0; %scatterplots (opt.scat below)
opt.mn.do_pltexp = 1; %plot experiment (opt.pltx below)
opt.mn.old_project = 0; %for carl



%% DAQ (i.e. FICTRAC/STIMULUS)

%params for daq processing in load_DAQ (i.e. stimulus/fictrac processing)
opt.daq.ignore_daq = 1; %1 to skip daq
opt.daq.ball_diameter = 9; %mm, used to convert fictrac variables into mm
opt.daq.fast_version = 0; %1 will use resample rather than slower but more accurate framewise scheme
opt.daq.slopeorder = 2; %order of polynomial used to fit local slope
opt.daq.slopelen_sec = 0.4; %window length used to fit slope
opt.daq.use_carls_epochs = 1; %0 for everybody else
opt.daq.doplots = 0; %if 1, will plot original and resampled timeseries in same figure, overlain, by default partitioned into 20 segments, one on each frame of a gif


%% TEMPORALLY DOWNSAMPLE AND ALIGN FICTRAC VIDEO WITH IMAGING 

opt.ftv.ftvid_spatial_smooth_window_std = 2; %std of gaussian smoothing filter applied to average frame of fictrac video, prior to finding the brightest pixels (to locate laser)
opt.ftv.numpix_to_extract_laser_timeseries = 10; %after spatial smoothing, number of pixels to average on each frame of fictrac video; these are the brightest 'numpix_to_extract_laser_timeseries' pixels in the mean frame of fictrac video
opt.ftv.laser_timeseries_smooth_window_std = 6; %std of gaussian smoothing filter applied to laser timeseries, to help denoise timeseries prior to findpeaks (to help find the true laser oscillation peaks)
opt.ftv.max_peak_distance_change_defining_periodic = 2; %in laser oscillation timeseries, 2 adjacent peaks are only considered periodic with less than a 'max_peak_distance_change_defining_periodic'-sample change in peak-to-peak distance (ie, diff(diff(lk)), where lk is peak indices, or locations in time)
opt.ftv.doplots = 0; %0 skips plots, 1 plots and saves, 2 saves but does not display 

%% STACK VISUALIZATION (GIF)

%opt.ld holds params used in stackld
%opt.ld.gif holds params for making gif of imaging movies in function stackld; these options do not affect stack for analysis (opt.mn.suffix_analysis) 
opt.ld.crop_flyback = 1; %crop flyback frames from each volume 
opt.ld.zero_stack = 1; %subtract min to make min zero 
opt.ld.tcropfront = 0; %how many samples to remove from beginning of stack; similar to cropdata in rec6 (also applied in metrics2 without variable name cropdata), crop first 4 and last 2 imaging frames (stimulus features, and deprecated responses, have been extracted with this cropping in rec6)
opt.ld.tcropback = 0; % how many samples to remove from end of stack
opt.ld.do_plot_stack_stats = 0; %function this uses is old and needs to be updated

opt.ld.gif.suffixes_plot = { 
    %'raw', ... %comment if you don't want to plot (can comment all too)
    %'cmrg', ...%comment if you don't want to plot (can comment all too)
    %'cmrg_dcdn', ... %comment if you don't want to a plot (can comment all too)
    %'bksb_cmrg_dcdn', ...
    %'bksb_cmrg_dcdn_nosn'
    }; %anything missing will be skipped, will be reordered from least to most processed (by suffix length)
opt.ld.gif.it = [50.3];%t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
opt.ld.gif.iz = []; %z indices to plot, empty for all, negative for that number equidistant from all available
opt.ld.gif.rescale_each_stack = 0; %1 to rescale 0-1 before combining into single plot; 
opt.ld.gif.display_range = [0,1]; %2-element vector, [low,high], where anything below low in 0-1 normalized image is displayed as black, and anything above high is displayed as white, 
opt.ld.gif.smooth_window_temporal = 0; %smooth the stack in time, 0 to skip


%% MORPHOLOGICAL ROIS

% params for making morphological rois (manual or automated), mostly used in function make_morphological_rois
% for opt.mroi.auto.use_hires, opt.mroi.use_drawn_rois, and opt.mroi.auto.num_mroi_auto: use empty cell to skip, otherwise a cell array of strings from regionex_all;any string in regionex_all that is missing in opt.mroi will be skipped

%%params for the manually drawn morphological rois
opt.mroi.use_drawn_rois =  {'ebfb_eb', 'ebfb_fb'}; %cell of regionex strings, let the user hand draw 2d or 3d morphological rois in an interactive plot, and save, or load if already drawn and saved

%%params for the automated morphological roi extraction (will be applied to drawn morphological rois, if they exist . . . for example, you draw a roi around a region, then there is automated morphological segmentation within that region)
opt.mroi.auto.num_mroi_auto_str = {'ebfb_eb-32', 'ebfb_fb-32'}; %each string is format regionex-integer, e.g. {'eb-12, 'pb-16'}, use 3d edge detection to define a 3d super-roi, then partition that super-roi into num_mroi_auto morphological rois; a drawn roi, if it exists, masks the regionex prior to automated super-roi extraction; num_mroi_auto and number drawn rois cannot both exceed 1 (i.e. the code cannot automatically partition discontiguous rois within a single regionex)
opt.mroi.auto.use_hires = {''}; %cell of regionex strings, use hi-z-res stack to help make morphological rois (to help 3d edge detection of region boundaries, and to help automated subdivision of 3d region into morphological rois)
opt.mroi.create_mask_method = 'nonzero'; %method for automatically defining morphological roi mask (union of all morphological rois) from stack or union of manually drawn rois, options are 'edge', 'outlier', 'triangle', 'nonzero'
opt.mroi.subsample_mask_method = 'uniform'; %'skeleton' for elongated structures or 'uniform'; method for subsampling mask into rois; for 'uniform', opt.mroi.auto.num_mroi_auto_str must be power of 2
opt.mroi.edgethresh = [.1, .7]; %two thresholds to detect strong and weak edges; includes weak edges in output only if they are connected to strong edges
opt.mroi.edgesig = [sqrt(2)*2 sqrt(2)*2 sqrt(2)*2 ]; %for edge detection, defines smoothing filter sigma for each dim xyz, or use one value for all dim, if 2d edge detection, first element is used for x and y
opt.mroi.closing_element_size = 8; %for bwmorph close after edge detection, helps connect edges
opt.mroi.extract_morph_rois_in_3d = 0; %1 makes 3d mask unless stack is 2d, 0 makes 2d mask for 2d, 3d, or 4d stack input

opt.mroi.do_other_plots = 1; %do plots besides overlay and hsvopt in make_morphological_rois and make_morphological_rois_auto

%params for roi overlay plot of morophological rois (make a gif showing each z slice of mean t stack)
opt.mroi.olayopt.doplot = 1; %plot or don't plot roi overlay with background, plots one roi at a time, each slice, with roi in red
opt.mroi.olayopt.foreground_plot_style = 'overlay'; %'boundary'; %options to show individual rois are 'boundary' and 'overlay'
opt.mroi.olayopt.ncol_each = 128; %number colors in each part of the overlay plot (2 parts are: mean volume/background, and roi/foreground)
opt.mroi.olayopt.saturation_factor_background = 1; %for gif, above this fraction of data is sent to max
opt.mroi.olayopt.saturation_factor_rois = 1; %for gif above this fraction of data is sent to max

%params for hsv plot of morophological rois (make a gif showing each z slice of mean t stack with hsv encoding of rois)
opt.mroi.hsvopt.do = 1; %1 to plot/save, 0 to just compute hsv image but skip plot/save
opt.mroi.hsvopt.foreground = 'allrois'; %'eachroi' plots each individually, 'allrois' plots all together
opt.mroi.hsvopt.mdlname = ''; %string for swithcing among plotting defaults in plots_setup_hsv, leave empty for default set
opt.mroi.hsvopt.huestr = ''; %deprecated variable, leave empty
opt.mroi.hsvopt.huenorm = 'native'; %hue normalization method, 'native' normalizes to a preset range (hard coded in plots_setup_hsv) according to 'mdlname', 'relative' normalizes to the data range assigned to hue, 'manual' normalizes to the range set below in opt.mroi.hsv.hrange_in_manual; if you request 'native' but don't pass huelimnat to plots_compute_hsv it will switch to 'relative'; if you request 'manual' but don't set opt.mroi.hsvopt.hrange_in_manual it will switch to 'relative'
opt.mroi.hsvopt.satnorm = 'relative'; %sat normalization method, same logic as huenorm
opt.mroi.hsvopt.valnorm = 'relative';%val normalization method, same logic as huenorm
opt.mroi.hsvopt.hrange_in_manual = []; %manual range for normalizing hue, prior to normalization to plot scale, whose max range is [0 1]), see plots_compute_hsv
opt.mroi.hsvopt.srange_in_manual = []; %manual range for normalizing sat, prior to normalization to plot scale, whose max range is [0 1]), see plots_compute_hsv
opt.mroi.hsvopt.vrange_in_manual = []; %manual range for normalizing val, prior to normalization to plot scale, whose max range is [0 1]), see plots_compute_hsv
opt.mroi.hsvopt.hrange_out_manual = [0.25 1]; %hue plot scale, whose max range is [0 1] hue hange around color circle, defaults to less than full circle for non-periodic plotting domain, but overwrites in plots_setup_hsv to [0 1] when plotting a periodic huefeature (e.g. von mises center, ie mdlname 'v' with huestr 'loc'), see plots_compute_hsv
opt.mroi.hsvopt.srange_out_manual = [0 1]; %sat plot scale, whose max range is [0 1], if you want to force saturation you can reduce (e.g. [0 0.75] will force smaller range to max saturation, see plots_compute_hsv
opt.mroi.hsvopt.vrange_out_manual = [0 1];  %val plot scale, whose max range is [0 1], if you want to force value you can reduce (e.g. [0 0.75] will force smaller range to max value, see plots_compute_hsv
opt.mroi.hsvopt.hueshift = 0; %0-1, circularly shift the hue map around the color circle for change to arbitrary color assignment, applied before any clipping due to, see plots_compute_hsv, this works for periodic or non-periodic features assigned to hue
opt.mroi.hsvopt.ignorehue = 0; %when creating and plotting variable 'img', which is built from variable 'hsvmap', 1 ignores hue in variable 'hsvmap', makes constant 1, but does not change 'hsvmap'
opt.mroi.hsvopt.ignoresat = 1;  %when creating and plotting variable 'img', which is built from variable 'hsvmap', 1 ignores sat in variable 'hsvmap', makes constant 1, but does not change 'hsvmap'
opt.mroi.hsvopt.ignoreval = 1;  %when creating and plotting variable 'img', which is built from variable 'hsvmap', 1 ignores val in variable 'hsvmap', makes constant 1, but does not change 'hsvmap'


% params for response extraction/normalization of morphological roi responses (opt.mroi.norm)
% precluster normalization is applied before clustering (i.e. normalization for timeseries of every pixel or caiman roi within a larger roi)
% postcluster normalization is applied after clustering
% clustering means averaging data for all pixels or caiman rois within a morphological roi
% precluster and postcluster are each a list of strings specifying different
% normalization methods, each must have at least one string (use 'f' for no normalization)

% below xxx, yyy, zzz, and www, are 3-character strings converted to integers, string range 0-100 (ie use leading zeros to reach 3 characters for anything under 100)
% all normalizations are applied to individual pixel or roi timeseries
% normalization strings are:
% 'dffuuuvvv' % sliding window dff, uuu as percentile to compute f0 for each window, vvv as sliding window length in seconds, if www is 000 then f0 is computed across the entire timeseries, not a sliding window
% 'rscxxxyyy' % rescale, sending xxx percentile to 0, yyy percentile to 1,
% 'z' % zscore
% 'nn' % nonnegative (subtract min)
% 'box'... % box-cox

opt.mroi.norm.precluster = {'f'}; %must have at least one string, compsed of syllables above
opt.mroi.norm.postcluster = {'f', 'rsc000100'}; %must have at least one string, compsed of syllables above
opt.mroi.norm.doplots = 0;

%% FUCNTIONAL ROIS

%params for loading/selecting/viewing functional rois (applied in process_functional_rois)
opt.froi.caiman_lr_str = {'2_1_*_*_*_*_*_1000_*_*_graph_2dex'}; %cell array of caiman param strings (in filename of roi file output by scopa pre), can use wildcards, empty to skip
opt.froi.min_pixels_per_region = 3; %min pix in each distongiguous region, roi selection criterion
opt.froi.min_roi_size = 5;%pixels, roi selection criterion
opt.froi.max_roi_size = 300; %pixels
opt.froi.max_regions_per_roi = 4; %for discontiguous rois
opt.froi.within_mask_threshold = 0.5; %discard roi if more than within_mask_threshold is outside morphological mask (morph mask is all ones if you don't make one)
opt.froi.numbins = 20; %num hist bins for rval and snr caiman output
opt.froi.sort_roi_method = 'majoraxis'; %'snr' sorts by caiman output cmsnr, 'none' doens't sort, 'majoraxis' if morphological rois exist, 'majoraxis' will sort along 3d major axis
opt.froi.foreground_plot_style = 'overlay'; %'boundary'; %options to show roi are 'boundary' and 'overlay'
opt.froi.numrois_for_gif = 0; %how many roi to put in gif, big number to plot all, 0 to skip gif
opt.froi.ncol_each = 128; %number colors in each part of the overlay plot (2 parts are: mean volume/background, and roi/foreground)
opt.froi.do_other_plots = 0; %do the other plots
opt.froi.saturation_factor_background = 0.4; %for gif, above this fraction of data is sent to max
opt.froi.saturation_factor_rois = 0.1; %for gif above this fraction of data is sent to max

% params for response extraction/normalization of functional roi responses (opt.froi.norm), same convention as above for opt.mroi.norm)

opt.froi.norm.precluster = {'f'}; %must have at least one string, compsed of syllables above
opt.froi.norm.postcluster = {'f', 'rsc000100'}; %must have at least one string, compsed of syllables above
opt.froi.norm.doplots = 0;

%% BUMP

% opt.pf holds params for computing population features, each substructure beneath opt.pf is for a different population feature, below, for example, is opt.pf.bump

% params for bump in compute_bump function
% a von mises is fit to the instantaneous relationship between each roi timeseries (given by all matches from opt.pf.bump.mfit.varnms.depvp) and all matches from opt.pf.bump.mfit.varnms.indvp
% the value of the independent variable at the max predicted response is the preferred heading for each roi
% if opt.pf.bump.domain_methodis 'functional', these preferred headings are used as the angle, and opt.pf.bump.mfit.varnms.depvp as the magnitude, in computing pva
% if the regionex in opt.pf.bump.mfit.varnms.depvp is in opt.pf.bump.numcluster_for_bump_domain_resample, and that regionex is followed by hyphen and number greater than zero, these preferred heading angles are resampled into that number, so that the rois evenly sample range 0-2pi (resampling changes angle and magnitude)
% if opt.pf.bump.domain_methodis 'morphological', angle is forced to be 0-2pi, with each roi evenly sampling that range

% opt.pf.bump.mfit(1).depv{1} = {['resp, pb, mo*, in_rawf_pc_f_cl_rsc000100_w_*']};
%this will select all fields in struct 'ts', matching this pattern, with * as wildcard: ts.resp.pb.mo*.in_rawf_pc_f_cl_rsc000100_w_*
%the selected timeseries will be assigned to depv
%selecting indv uses the same approach
%depv and indv are matched at the outer cell level
%at the inner cell level, there can be multiple field specifiers (fieldspec)
%each fieldspec is a char array, composed of segments separated by comma with space (', '), each segment matching the name of a field at a different level under struct 'ts'
%depv and indv are composed of all timeseries matching fieldspecs
%if multiple matches, depv is concatenated along second dim (time), since currently mfit fits single timeseries
%if multiple matches, indv is concatenated along first dim (not time), since mfit can accept multidimensional independent variable
% opt.pf.bump.mfit(1).indv{1} = {['vis, angsd']};

%params for computing bump
opt.pf.bump.bump_method = 'pva'; %'pva' for vector average
opt.pf.bump.domain_method = 'functional'; %'functional' to define circular domain with fit to each roi, or 'morphological' to define as circle across region mask
opt.pf.bump.bump_subdomain = {'all'}; %cell array of char, 'all', 'right', 'left', 'larger', 'weighted', 'random'
opt.pf.bump.slopeorder = 2; %order of polynomial used to fit local slope (e.g. to compute bump speed)
opt.pf.bump.slopelen_sec = 5; %order of polynomial used to fit local slope (e.g. to compute bump speed)
opt.pf.bump.smoothwindow_sec = 0.2; %full width of gaussian smoothing window (5 times std)
opt.pf.bump.numcluster_for_bump_domain_resample_str = {'eb-16'}; %how many clusters/superrois across the entire region (not hemisphere) when resampled uniformly prior to computing bump as vector average, cell array of string 'regionex-integer', regionex must exist in matches to opt.pf.bump.mfit.varnms.depvp  . . . to skip resampling for a regionex, just don't list it here, or write 'regionex-0'
opt.pf.bump.resample_smoothfac = 1; %when resampling compass, bandwidth of the antialiasing filter, larger number will have smoother resampled compass
opt.pf.bump.rescale_clusters = 1; %just before computing bump, rescale each cluster's timeseries to range 0-1
opt.pf.bump.omitnan = 1; %ignore nans in case there are any (e.g., making hybrid morph-func rois, some morph rois have no func members, making their response 'nan', omit will ignore this in computing pva)
opt.pf.bump.doplots = 0;

%params for finding preferred heading using mfit
% opt.pf.bump.mfit(1).varnms.depvp{1} = {['resp, pb, mo*, in_rawf_pc_f_cl_rsc000100_w_*']}; %will skip bump if empty opt.pf.bump.mfit(1).depv{1} = {};
opt.pf.bump.mfit(1).varnms.depvp{1} = {['resp, eb, mo*, in_rawf_pc_f_cl_rsc000100_w_*']}; %will skip bump if empty opt.pf.bump.mfit(1).depv{1} = {};
opt.pf.bump.mfit(1).varnms.indvp{1} = {['vis, angsd']};
opt.pf.bump.mfit(1).vars_combine = 'any'; %any or each, how to combine depv and indv outermost cells for a given fit structure element

opt.pf.bump.mfit(1).normalize_indv = 'none';
opt.pf.bump.mfit(1).validation_fold = 0; %applied to all mdlnames; k in k-fold cross-validation; k non-overlapping validation sets; if numbouts of each epoch in epochinds is divisible by validation_fold, will validate on numbouts/validation_fold bouts for each epoch in epochinds; if only one bout for each epoch, will evenly split each bout into k validation sets; otherwise will error; 0 skips validation
opt.pf.bump.mfit(1).mdlname = 'fnet_v'; %'fnet_v';
opt.pf.bump.mfit(1).epochinds = {[4]};

opt.pf.bump.mfit(1).mdl_length_sec = 0;
opt.pf.bump.mfit(1).hsv_background = 'rois';
opt.pf.bump.mfit(1).sort_method = 'unbiased';
opt.pf.bump.mfit(1).use_saved_model = 1;
opt.pf.bump.mfit(1).doplots = 1;


opt.pf.bump.mfit = default_fit_params(opt.pf.bump.mfit);

%% FIT MODEL


%params for fitting model using mfit
% modeling depv in mfit function
% mfit fits model describing how indv is transformed into depv

% opt.mfit.varnms.indvp.(regionex) specifies which input to use for fit,
% it is a cell array of cell arrays of strings defining variable struct then field of that struct
% for example opt.mfit.varnms.indvp.no_r = {{'ball', 'yawvel'}, {'bump',
% 'mu'}} will fit depv (specified as described above) in regionex 'no_r' to
% two-dimensional input, the first dimension being ball.yawvel, the second being bump.mu
%the name of the innermost nested field must be a regionex that is listed in opt.mfit.regionpat_fit
%since roi responses for all regionex are extracted and normalized before mfit, responses from all rois, in struct 'resp', are available as input to mfit
%since the bump is computed before mfit, fields from structure 'bump' are available as input to mfit
%subfield not listed, uses all, like wildcard

% to specify independent and dependent variables for model fitting, use opt.mfit.varnms.indvp and opt.mfit.varnms.depvp
% format opt.mfit(i).varnms.depvp{j} = {fieldspec1, fieldspec2, ... fieldspecN};
% format opt.mfit(i).varnms.indvp{j} = {fieldspec1, fieldspec2, ... fieldspecN};

% where fieldspec is a string, with substrings separated by comma then space
% fieldspec specifies the data to use from struct 'ts', which stores various timeseries
% for example, for ts.resp, fieldspec requires 4 delimiters (', '), since there are 4 levels in the struct ts.resp,
% namely ts.resp.tsclass.regionex.parsex.normex,
% so fieldspec would follow the pattern ['tsclass, regionex, parsex, normex']
% where tsclass is a field in the first level of struct 'ts'
% regionex is region extraction string in opt.mn.regionex_all above,
% parsex is extraction param string
% normex is normalization param string
% for ts.ball and ts.vis, fieldspec only has two levels, since ball and vis are not derived from specific brain regions, or roi extraction runs
% for ts.bump, fieldspec has 6 levels (the same four as bump.resp, with 2 more specifying bump domain, and bump parameter, following this pattern
% ['tsclass, regionex, parsex, normex, bumpdomain, bumpparam']
% for all substrings in fieldspec, you can use '*' as wildcard, all matches will be used
% you can use multiple fieldspec, all matches in a single outer cell (index j) will be grouped into a variable for fitting
% opt.mfit.varnms.indvp and opt.mfit.varnms.depvp are matched by index i in opt.mfit(i)
% within a single opt.mfit(i).varnms.indvp or opt.mfit(i).varnms.depvp, you can specify multiple cells with index j, in single opt.mfit(i).indv{j} or opt.mfit(i).varnms.depvp{j}
% indvp_str and depvp_str are matched by index j if opt.mfit(i).vars_combine is 'each',
% if opt.mfit(1).vars_combine is 'any', then all combinations of single opt.mfit(i).indv and single opt.mfit(i).depv are used
% for example
%    opt.mfit(1).varnms.depvp{1} = {['resp, no_r, mo*, in_rawf_pc_f_cl_f_w_no']};
%    opt.mfit(1).varnms.indvp{1} = {['ball, yawvel'], ['bump, pb, mo*, *, all, mu']};

%for now, depv at single struct and outer cell level should come from single regionex
opt.mfit(1).varnms.depvp{1} = {['resp, no_l, mo*, in_rawf_pc_f_cl_f_w_no']}; %if empty, do will be set to false
opt.mfit(1).varnms.depvp{2} = {['resp, no_r, mo*, in_rawf_pc_f_cl_f_w_no']}; %if empty, do will be set to false
opt.mfit(1).varnms.indvp{1} = {['ball, yawvel'], ['bump, eb, mo*, *, all, vel']};
opt.mfit(1).varnms.indvp{2} = {['ball, yawvel'], ['resp, gal, mo*, in_rawf_pc_f_cl_f_w_no']};
opt.mfit(1).varnms.indvp{3} = {['ball, yawvel']};

opt.mfit(1).vars_combine = 'any'; %any or each, how to combine depv and indv outermost cells for a given fit structure element
opt.mfit(1).epochinds = {[2 3 4]};
opt.mfit(1).validation_fold = 6; %applied to all mdlnames; k in k-fold cross-validation; k non-overlapping validation sets; if numbouts of each epoch in epochinds is divisible by validation_fold, will validate on numbouts/validation_fold bouts for each epoch in epochinds; if only one bout for each epoch, will evenly split each bout into k validation sets; otherwise will error; 0 skips validation

% see notes_mdlname for notes about opt.mfit.mdlname syntax

opt.mfit(1).mdlname = 'fnet_A01_sh16';
opt.mfit(1).plt.doplots = 100;

opt.mfit = default_fit_params(opt.mfit);


%% SCATTERPLOTS

% params for scatterplots
%scatterplots come at the end so all variables computed in 'post' pipeline are available for scatterplots

%if any of x, y, or z are polar, they are moved to theta on the scatterplots; two polar variables get layered in r
% opt.scat(1).varnms.x{1} = {['ball, *for*'], ['ball, *yaw*'], ['vis, *']};
opt.scat(1).varnms.x{1} = {['ball, *'], ['vis, *']};
opt.scat(1).varnms.y{1} = {['resp, fullfov, mo*, in_rawf_pc_f_cl_f_w_yes']}; %if empty, do will be set to false
opt.scat(1).varnms.z{1} = {['']};
opt.scat(1).varnms.y{2} = {['resp, fullfov, cm*, in_cmc_pc_f_cl_null_w_null']};
opt.scat(1).varnms.y{3} = {['resp, fullfov, cm*, in_cmc_pc_f_cl_null_w_null']};
% opt.scat(1).varnms.x{2} = {['ball, *for*'], ['ball, *yaw*'], ['vis, *']};
opt.scat(1).lagsxy_sec = linspace(-1, 1, 1e4); %empty or zero to skip; scalar or vector; seconds of lag, rounded to nearest frame; repeated frames are omitted; to see all frames within range, use spacing smaller than sample rate (just use very small spacing to ensure it, so you don't have to think about it, like this linspace(-1, 1, 1e4)); negative means x follows y, positive means y follows x; 
opt.scat(1).lagsz_sec = linspace(-1, 1, 1e4); %same as lagxy_sec, except z lags are applied for each xy lag (xy vars are lagged, then together lagged relative to z); will be automatically set to 0 if there is no z variable 
opt.scat(1).lags_to_plot = 'zeroandbest'; % 'zero', 'best', 'zeroandbest', 'all'
opt.scat(1).plot_z_as_color = 1; %if z variable exists, 0 will make 3d scatterplot, 1 will make 2d with z variable as color 
opt.scat(1).vars_combine = 'any'; %any or each, how to combine depv and indv outermost cells for a given fit structure element
opt.scat(1).ignore_missing_vars = 0; %set to 1 not error if any requested timeseries in vars above do not exist
opt.scat(1).epochinds = {[1]}; %cell array of vectors or scalars listing epochs (within single trial) to group in scatterplots, empty cell with empty vector for all epochs, like this {[]}
opt.scat(1).gif_visibility = 'on'; %0 will save but not plot, 1 will do both



%% PLOT EXPERIMENT

% params for plot_experiment

opt.pltx(1).varnms.x{1} = {['ball, *forv*']};
% opt.pltx(1).varnms.x{1} = {['ball, *for*'], ['vis, *']};
opt.pltx(1).varnms.y{1} = {['resp, fullfov, mo*, in_rawf_pc_f_cl_f_w_yes']}; %if empty, do will be set to false
opt.pltx(1).varnms.z{1} = {['']};
% opt.pltx(1).varnms.y{2} = {['resp, fullfov, cm*, in_cmc_pc_f_cl_null_w_null']};
opt.pltx(1).vars_combine = 'any'; %any or each, how to combine depv and indv outermost cells for a given fit structure element
opt.pltx(1).ignore_missing_vars = 0; %set to 1 not error if any requested timeseries in vars above do not exist
opt.pltx(1).epochinds = {[1]}; %cell array of vectors or scalars listing epochs (within single trial) to group in scatterplots, empty cell with empty vector for all epochs, like this {[]}
opt.pltx(1).gif_visibility = 'on'; %0 will save but not plot, 1 will do both

opt.pltx(1).it = [];%t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
opt.pltx(1).iz = []; %z indices to plot, empty for all, negative for that number equidistant from all available
opt.pltx(1).display_range = [0,1]; 



%% HIRES

%params for hires stack (high z resolution version of main stack) . . . this code is a little deprecated
%hires stack is only used in making morphological rois, set opt.mroi.auto.use_hires=1 to use
%params below, in opt.hires, are for processing the hires stack, and visualization with gif in opt.hires.gif
opt.hires.ld.crop_flyback = 1; %crop flyback frames from each volume 
opt.hires.ld.zero_stack = 1; %subtract min to make min zero 
opt.hires.ld.tcropfront = 0; %how many samples to remove from beginning of stack; similar to cropdata in rec6 (also applied in metrics2 without variable name cropdata), crop first 4 and last 2 imaging frames (stimulus features, and deprecated responses, have been extracted with this cropping in rec6)
opt.hires.ld.tcropback = 0; % how many samples to remove from end of stack
opt.hires.ld.do_plot_stack_stats = 0; %function this uses is old and needs to be updated

opt.hires.ld.gif.it = [1]; %t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
opt.hires.ld.gif.iz = []; %z indices to plot, empty for all, negative for that number equidistant from all available
opt.hires.ld.gif.rescale_each_stack = 1; %rescale each subplot to same range 0-1 before combining
opt.hires.ld.gif.display_range = [0 1]; %combined ploto rescale arguments, [lower, upper]
opt.hires.ld.gif.smooth_window_temporal = 0; %smooth the stack in time, 0 to skip
opt.hires.ld.gif.plot_stack_gif = 1; %this one is not available in opt.ld.gif (it is automatically determined); haven't made this one automatic yet

opt.hires.do_reg_plots = 1;
opt.hires.disttype = 'monomodal'; % multimodal monomodal, used in register_one_stack_to_another_in_3d from within register_3d_hires_to_3d_lores
opt.hires.regtype = 'rigid'; %3d registration type (rigid should be best for tiny fly brain), used in register_one_stack_to_another_in_3d from within register_3d_hires_to_3d_lores
opt.hires.use_caiman_on_hires = 0; %keep at 0 bc pipeline not yet finished for this option (also doens't seem to help)
opt.hires.caiman_hr_str = '*'; %empty to skip


%% CARL'S OLD PROJECT

%overwrite some params for carl's old project
% if ~strcmp(opt.mn.recdate, '*') && strcmp(opt.mn.recdate(1:2), '22') %override some settings for old project
%     opt.mn.old_project = 1;
%     opt.md.tcropfront = 4; % how many samples to remove from beginning of stack; similar to cropdata in rec6 (also applied in metrics2 without variable name cropdata), crop first 4 and last 2 imaging frames (stimulus features, and deprecated responses, have been extracted with this cropping in rec6)
%     opt.md.tcropfront = 2; % how many samples to remove from end of stack
%     opt.mfit.mdl_lag_sec = 1; %how many samples indv precedes depv for model fit . . . for now, only nonnegative integers (0 to lenfit_samp - 1)
%     opt.mfit.mdl_length_sec = 1.25;
% end

%% order fields

opt = orderfields_recursive(opt);
