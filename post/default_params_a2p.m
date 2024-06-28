function parsout = default_params_a2p(parsin)


% struct 'opt' holds all input params
% substructures within opt are mostly used within single functions called from a2p

%some params below have suffix '_str'; these are string inputs (for user input convenience) that are mapped later to numeric variables

%% MAIN

%params for main pipeline control in file a2p

mn.parent_folder_path_local = '~/stacks'; %on local machine, full path to folder containing all recording folders 
mn.parent_folder_path_o2 = ''; %on o2, full path to folder containing all recording folders, leave empty to automatically find path in scratch with same parent folder name as mn.parent_folder_path_local; ap2 will automatically determine if you're on O2; example path is '/n/scratch/users/c/caw846/stacks/'
mn.tmp_folder_name = 'scopatmp'; %will be created in same dir as stacks, stores small tmp files used in interactive figures; getActiveFilename is problematic on O2 so using this approach instead

if isempty(fieldnames(filespec_in))
    mn.recdate = '*'; %can use wildcards
    mn.fly = '*'; %can use wildcards
    mn.trial = '*'; %can use wildcards
    mn.suffix_analysis = '*'; %scopa 'pre' pipeline output filename suffix to use in this 'post' pipeline
else
    mn.recdate = filespec_in.recdate; %can use wildcards
    mn.fly = filespec_in.fly; %can use wildcards
    mn.trial = filespec_in.trial; %can use wildcards
    mn.suffix_analysis = filespec_in.suffix_analysis;
end

[mn.pth_usefile_prefix_all, mn.pth_grandparent] = find_preprocessed_files(mn);

mn.regionex_all = {'pb', 'gal_d', 'gal_v', 'gar_d', 'gar_v', 'no_l', 'no_r' }; %cell array of strings matching regionex from scopa 'pre' pipeline; append an underscore and suffix (format existingregionex_suffix) to create a new regionex with the same croplim as existing regionex (e.g., if the cuboid from 'pre' has two subregions you want to analyze separately, including with different morphological rois);  if no match from 'pre' you will be prompted to define the regionex (i.e., to define 'croplim', a cuboid, in interactive plots)
mn.regionex_all = {'fullfov' }; %cell array of strings matching regionex from scopa 'pre' pipeline; append an underscore and suffix (format existingregionex_suffix) to create a new regionex with the same croplim as existing regionex (e.g., if the cuboid from 'pre' has two subregions you want to analyze separately, including with different morphological rois);  if no match from 'pre' you will be prompted to define the regionex (i.e., to define 'croplim', a cuboid, in interactive plots)
mn.timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));
mn.old_project = 0; %for carl

mn.do_popfeat = 0; %compute population features (pf below)
mn.do_fit = 0; %model fitting (fit below)
mn.do_scatter = 0; %scatterplots (scatter below)
mn.do_pltexp = 1; %plot experiment (pltexp below)

%% DAQ (i.e. FICTRAC/STIMULUS)

%params for daq processing in load_DAQ (i.e. stimulus/fictrac processing)
daq.ignore_daq = 0; %1 to skip daq
daq.fast_version = 1; %1 will use resample rather than slower but more accurate framewise scheme
daq.slopeorder = 2; %order of polynomial used to fit local slope
daq.slopelen_sec = 0.4; %window length used to fit slope
daq.use_carls_epochs = 1; %0 for everybody else
daq.doplots = 0; %if 1, will plot original and resampled timeseries in same figure, overlain, by default partitioned into 20 segments, one on each frame of a gif


%% STACK VISUALIZATION (GIF)

%load holds params used in load_stack
%ld.gif holds params for making gif of imaging movies in function load_stack; these options do not affect stack for analysis (mn.suffix_analysis) 
ld.crop_flyback = 1; %crop flyback frames from each volume 
ld.zero_stack = 1; %subtract min to make min zero 
ld.cropinds_t_start = 0; %how many samples to remove from beginning of stack; similar to cropdata in rec6 (also applied in metrics2 without variable name cropdata), crop first 4 and last 2 imaging frames (stimulus features, and deprecated responses, have been extracted with this cropping in rec6)
ld.cropinds_t_end = 0; % how many samples to remove from end of stack
ld.plot_stack_stats = 0; %function this uses is old and needs to be updated

ld.gif.suffixes_plot = { 
    %'raw', ... %comment if you don't want to plot (can comment all too)
    %'cmrg', ...%comment if you don't want to plot (can comment all too)
    'cmrg_dcdn', ... %comment if you don't want to a plot (can comment all too)
    %'bksb_cmrg_dcdn', ...
    %'bksb_cmrg_dcdn_nosn'
    }; %anything missing will be skipped, will be reordered from least to most processed (by suffix length)
ld.gif.plotinds.t = [30:100];%t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
ld.gif.plotinds.z = [2,5,8]; %z indices to plot, empty for all, negative for that number equidistant from all available
ld.gif.rescale_each_stack = 0; %1 to rescale 0-1 before combining into single plot; 
ld.gif.display_range = [0,1]; %2-element vector, [low,high], where anything below low in 0-1 normalized image is displayed as black, and anything above high is displayed as white, 
ld.gif.smooth_window_temporal = 0; %smooth the stack in time, 0 to skip


%% MORPHOLOGICAL ROIS

% params for making morphological rois (manual or automated), mostly used in function make_morphological_rois
% for mroi.use_hires, mroi.use_drawn_rois, and mroi.num_mroi_auto: use empty cell to skip, otherwise a cell array of strings from regionex_all;any string in regionex_all that is missing in mroi will be skipped

%%params for the manually drawn morphological rois
mroi.use_drawn_rois_str =  {'pb', 'gal_d', 'gal_v', 'gar_d', 'gar_v', 'no_l', 'no_r' }; %cell of regionex strings, let the user hand draw 2d or 3d morphological rois in an interactive plot, and save, or load if already drawn and saved
mroi.use_drawn_rois_str =  {'fullfov' }; %cell of regionex strings, let the user hand draw 2d or 3d morphological rois in an interactive plot, and save, or load if already drawn and saved

%%params for the automated morphological roi extraction (will be applied to drawn morphological rois, if they exist . . . for example, you draw a roi around a region, then there is automated morphological segmentation within that region)
mroi.num_mroi_auto_str = {'fullfov-128'}; %each string is format regionex-integer, e.g. {'eb-12, 'pb-16'}, use 3d edge detection to define a 3d super-roi, then partition that super-roi into num_mroi_auto morphological rois; a drawn roi, if it exists, masks the regionex prior to automated super-roi extraction; num_mroi_auto and number drawn rois cannot both exceed 1 (i.e. the code cannot automatically partition discontiguous rois within a single regionex)
mroi.use_hires_str = {''}; %cell of regionex strings, use hi-z-res stack to help make morphological rois (to help 3d edge detection of region boundaries, and to help automated subdivision of 3d region into morphological rois)
mroi.create_mask_method = 'nonzero'; %method for automatically defining morphological roi mask (union of all morphological rois) from stack or union of manually drawn rois, options are 'edge', 'outlier', 'triangle', 'nonzero'
mroi.subsample_mask_method = 'uniform'; %'skeleton' for elongated structures or 'uniform'; method for subsampling mask into rois; for 'uniform', mroi.num_mroi_auto_str must be power of 2
mroi.edgethresh = [.1, .7]; %two thresholds to detect strong and weak edges; includes weak edges in output only if they are connected to strong edges
mroi.edgesig = [sqrt(2)*2 sqrt(2)*2 sqrt(2)*2 ]; %for edge detection, defines smoothing filter sigma for each dim xyz, or use one value for all dim, if 2d edge detection, first element is used for x and y
mroi.closing_element_size = 8; %for bwmorph close after edge detection, helps connect edges
mroi.extract_morph_rois_in_3d = 1; %1 makes 3d mask unless stack is 2d, 0 makes 2d mask for 2d, 3d, or 4d stack input

mroi.do_other_plots = 0; %do plots besides overlay and hsvopt in make_morphological_rois and make_morphological_rois_auto

%params for roi overlay plot of morophological rois (make a gif showing each z slice of mean t stack)
mroi.olayopt.doplot = 0; %plot or don't plot roi overlay with background, plots one roi at a time, each slice, with roi in red
mroi.olayopt.foreground_plot_style = 'overlay'; %'boundary'; %options to show individual rois are 'boundary' and 'overlay'
mroi.olayopt.ncol_each = 128; %number colors in each part of the overlay plot (2 parts are: mean volume/background, and roi/foreground)
mroi.olayopt.saturation_factor_background = 1; %for gif, above this fraction of data is sent to max
mroi.olayopt.saturation_factor_rois = 1; %for gif above this fraction of data is sent to max

%params for hsv plot of morophological rois (make a gif showing each z slice of mean t stack with hsv encoding of rois)
mroi.hsvopt.do = 0; %1 to plot/save, 0 to just compute hsv image but skip plot/save  
mroi.hsvopt.foreground = 'allrois'; %'eachroi' plots each individually, 'allrois' plots all together
mroi.hsvopt.mdlname = ''; %string for swithcing among plotting defaults in plots_setup_hsv, leave empty for default set 
mroi.hsvopt.huestr = ''; %deprecated variable, leave empty 
mroi.hsvopt.huenorm = 'native'; %hue normalization method, 'native' normalizes to a preset range (hard coded in plots_setup_hsv) according to 'mdlname', 'relative' normalizes to the data range assigned to hue, 'manual' normalizes to the range set below in mroi.hsv.hrange_in_manual; if you request 'native' but don't pass huelimnat to plots_compute_hsv it will switch to 'relative'; if you request 'manual' but don't set mroi.hsvopt.hrange_in_manual it will switch to 'relative'      
mroi.hsvopt.satnorm = 'relative'; %sat normalization method, same logic as huenorm
mroi.hsvopt.valnorm = 'relative';%val normalization method, same logic as huenorm
mroi.hsvopt.hrange_in_manual = []; %manual range for normalizing hue, prior to normalization to plot scale, whose max range is [0 1]), see plots_compute_hsv
mroi.hsvopt.srange_in_manual = []; %manual range for normalizing sat, prior to normalization to plot scale, whose max range is [0 1]), see plots_compute_hsv
mroi.hsvopt.vrange_in_manual = []; %manual range for normalizing val, prior to normalization to plot scale, whose max range is [0 1]), see plots_compute_hsv
mroi.hsvopt.hrange_out_manual = [0.25 1]; %hue plot scale, whose max range is [0 1] hue hange around color circle, defaults to less than full circle for non-periodic plotting domain, but overwrites in plots_setup_hsv to [0 1] when plotting a periodic huefeature (e.g. von mises center, ie mdlname 'v' with huestr 'loc'), see plots_compute_hsv
mroi.hsvopt.srange_out_manual = [0 1]; %sat plot scale, whose max range is [0 1], if you want to force saturation you can reduce (e.g. [0 0.75] will force smaller range to max saturation, see plots_compute_hsv
mroi.hsvopt.vrange_out_manual = [0 1];  %val plot scale, whose max range is [0 1], if you want to force value you can reduce (e.g. [0 0.75] will force smaller range to max value, see plots_compute_hsv
mroi.hsvopt.hueshift = 0; %0-1, circularly shift the hue map around the color circle for change to arbitrary color assignment, applied before any clipping due to, see plots_compute_hsv, this works for periodic or non-periodic features assigned to hue
mroi.hsvopt.ignorehue = 0; %when creating and plotting variable 'img', which is built from variable 'hsvmap', 1 ignores hue in variable 'hsvmap', makes constant 1, but does not change 'hsvmap'
mroi.hsvopt.ignoresat = 1;  %when creating and plotting variable 'img', which is built from variable 'hsvmap', 1 ignores sat in variable 'hsvmap', makes constant 1, but does not change 'hsvmap'
mroi.hsvopt.ignoreval = 1;  %when creating and plotting variable 'img', which is built from variable 'hsvmap', 1 ignores val in variable 'hsvmap', makes constant 1, but does not change 'hsvmap'

% params for response extraction/normalization of morphological roi responses (mroi.norm)
% precluster normalization is applied before clustering (i.e. normalization for timeseries of every pixel or caiman roi within a larger roi)
% postcluster normalization is applied after clustering
% clustering means averaging data for all pixels or caiman rois within a morphological roi
% precluster and postcluster are each a list of strings specifying different
% normalization methods, each must have at least one string (use 'f' for no normalization)

% below xxx, yyy, zzz, and www, are 3-character strings converted to integers, string range 0-100 (ie use leading zeros to reach 3 characters for anything under 100)
% all normalizations are applied to individual pixel or roi timeseries
% normalization strings are:
% 'dffuuuvvv' % sliding window dff, uuu as percentile to compute f0 for each window, uuu as sliding window length in seconds, if uuu is 000 then f0 is computed across the entire timeseries, not a sliding window
% 'rscxxxyyy' % rescale, sending xxx percentile to 0, yyy percentile to 1,
% 'z' % zscore
% 'nn' % nonnegative (subtract min)
% 'box'... % box-cox

mroi.norm.precluster = {'f'}; %must have at least one string, compsed of syllables above
mroi.norm.postcluster = {'f', 'rsc000100'}; %must have at least one string, compsed of syllables above
mroi.norm.doplots = 0;

%% FUCNTIONAL ROIS

%params for loading/selecting/viewing functional rois (applied in process_functional_rois)
froi.caiman_lr_str = {'2_1_*_*_*_*_*_1000_*_*_graph_2dex'}; %cell array of caiman param strings (in filename of roi file output by scopa pre), can use wildcards, empty to skip
froi.min_pixels_per_region = 3; %min pix in each distongiguous region, roi selection criterion
froi.min_roi_size = 5;%pixels, roi selection criterion
froi.max_roi_size = 300; %pixels
froi.max_regions_per_roi = 4; %for discontiguous rois
froi.within_mask_threshold = 0.5; %discard roi if more than within_mask_threshold is outside morphological mask (morph mask is all ones if you don't make one)
froi.numbins = 20; %num hist bins for rval and snr caiman output
froi.sort_roi_method = 'majoraxis'; %'snr' sorts by caiman output cmsnr, 'none' doens't sort, 'majoraxis' if morphological rois exist, 'majoraxis' will sort along 3d major axis
froi.foreground_plot_style = 'overlay'; %'boundary'; %options to show roi are 'boundary' and 'overlay'
froi.numrois_for_gif = 0; %how many roi to put in gif, big number to plot all, 0 to skip gif
froi.ncol_each = 128; %number colors in each part of the overlay plot (2 parts are: mean volume/background, and roi/foreground)
froi.do_other_plots = 0; %do the other plots
froi.saturation_factor_background = 0.4; %for gif, above this fraction of data is sent to max
froi.saturation_factor_rois = 0.1; %for gif above this fraction of data is sent to max

% params for response extraction/normalization of functional roi responses (froi.norm), same convention as above for mroi.norm)

froi.norm.precluster = {'f'}; %must have at least one string, compsed of syllables above
froi.norm.postcluster = {'f', 'rsc000100'}; %must have at least one string, compsed of syllables above
froi.norm.doplots = 0;

%% BUMP

% pf holds params for computing population features, each substructure beneath pf is for a different population feature, below, for example, is pf.bump

% params for bump in compute_bump function
% a von mises is fit to the instantaneous relationship between each roi timeseries (given by all matches from pf.bump.fitm.vars.depvpre_str) and all matches from pf.bump.fitm.vars.indvpre_str
% the value of the independent variable at the max predicted response is the preferred heading for each roi
% if pf.bump.domain_methodis 'functional', these preferred headings are used as the angle, and pf.bump.fitm.vars.depvpre_str as the magnitude, in computing pva
% if the regionex in pf.bump.fitm.vars.depvpre_str is in pf.bump.numcluster_for_bump_domain_resample, and that regionex is followed by hyphen and number greater than zero, these preferred heading angles are resampled into that number, so that the rois evenly sample range 0-2pi (resampling changes angle and magnitude)
% if pf.bump.domain_methodis 'morphological', angle is forced to be 0-2pi, with each roi evenly sampling that range

% pf.bump.fitm(1).depv{1} = {['resp, pb, mo*, in_rawf_pc_f_cl_rsc000100_w_*']};
%this will select all fields in struct 'ts', matching this pattern, with * as wildcard: ts.resp.pb.mo*.in_rawf_pc_f_cl_rsc000100_w_*
%the selected timeseries will be assigned to depv
%selecting indv uses the same approach
%depv and indv are matched at the outer cell level
%at the inner cell level, there can be multiple field specifiers (fieldspec)
%each fieldspec is a char array, composed of segments separated by comma with space (', '), each segment matching the name of a field at a different level under struct 'ts'
%depv and indv are composed of all timeseries matching fieldspecs
%if multiple matches, depv is concatenated along second dim (time), since currently fitmdl fits single timeseries
%if multiple matches, indv is concatenated along first dim (not time), since fitmdl can accept multidimensional independent variable
% pf.bump.fitm(1).indv{1} = {['vis, angsd']};

%params for computing bump
pf.bump.bump_method = 'pva'; %'pva' for vector average
pf.bump.domain_method = 'functional'; %'functional' to define circular domain with fit to each roi, or 'morphological' to define as circle across region mask
pf.bump.bump_subdomain = {'all'}; %cell array of char, 'all', 'right', 'left', 'larger', 'weighted', 'random'
pf.bump.slopeorder = 2; %order of polynomial used to fit local slope (e.g. to compute bump speed)
pf.bump.slopelen_sec = 5; %order of polynomial used to fit local slope (e.g. to compute bump speed)
pf.bump.smoothwindow_sec = 0.2; %full width of gaussian smoothing window (5 times std)
pf.bump.numcluster_for_bump_domain_resample_str = {'eb-16'}; %how many clusters/superrois across the entire region (not hemisphere) when resampled uniformly prior to computing bump as vector average, cell array of string 'regionex-integer', regionex must exist in matches to pf.bump.fitm.vars.depvpre_str  . . . to skip resampling for a regionex, just don't list it here, or write 'regionex-0'
pf.bump.resample_smoothfac = 1; %when resampling compass, bandwidth of the antialiasing filter, larger number will have smoother resampled compass
pf.bump.rescale_clusters = 1; %just before computing bump, rescale each cluster's timeseries to range 0-1
pf.bump.omitnan = 1; %ignore nans in case there are any (e.g., making hybrid morph-func rois, some morph rois have no func members, making their response 'nan', omit will ignore this in computing pva)
pf.bump.doplots = 0;

%params for finding preferred heading using fitmdl
% pf.bump.fitm(1).vars.depvpre_str{1} = {['resp, pb, mo*, in_rawf_pc_f_cl_rsc000100_w_*']}; %will skip bump if empty pf.bump.fitm(1).depv{1} = {};
pf.bump.fitm(1).vars.depvpre_str{1} = {['resp, eb, mo*, in_rawf_pc_f_cl_rsc000100_w_*']}; %will skip bump if empty pf.bump.fitm(1).depv{1} = {};
pf.bump.fitm(1).vars.indvpre_str{1} = {['vis, ang']};
pf.bump.fitm(1).vars_combine = 'any'; %any or each, how to combine depv and indv outermost cells for a given fit structure element

pf.bump.fitm(1).normalize_indv = 'none';
pf.bump.fitm(1).validation_fold = 0; %applied to all mdlnames; k in k-fold cross-validation; k non-overlapping validation sets; if numbouts of each epoch in epochinds is divisible by validation_fold, will validate on numbouts/validation_fold bouts for each epoch in epochinds; if only one bout for each epoch, will evenly split each bout into k validation sets; otherwise will error; 0 skips validation
pf.bump.fitm(1).mdlname = 'fnet_v'; %'fnet_v';
pf.bump.fitm(1).epochinds = {[4]};
pf.bump.fitm(1).mdl_length_sec = 0;
pf.bump.fitm(1).hsv_background = 'rois';
pf.bump.fitm(1).sort_method = 'unbiased';
pf.bump.fitm(1).use_saved_model = 1;
pf.bump.fitm(1).doplots = 1;


pf.bump.fit = default_fit_params(pf.bump.fit);

%% FIT MODEL


%params for fitting model using fitmdl
% modeling depv in fitmdl function
% fitmdl fits model describing how indv is transformed into depv

% fitm.vars.indvpre_str.(regionex) specifies which input to use for fit,
% it is a cell array of cell arrays of strings defining variable struct then field of that struct
% for example fitm.vars.indvpre_str.no_r = {{'ball', 'angvel'}, {'bump',
% 'mu'}} will fit depv (specified as described above) in regionex 'no_r' to
% two-dimensional input, the first dimension being ball.angvel, the second being bump.mu
%the name of the innermost nested field must be a regionex that is listed in fitm.regionpat_fit
%since roi responses for all regionex are extracted and normalized before fitmdl, responses from all rois, in struct 'resp', are available as input to fitmdl
%since the bump is computed before fitmdl, fields from structure 'bump' are available as input to fitmdl
%subfield not listed, uses all, like wildcard

% to specify independent and dependent variables for model fitting, use fitm.vars.indvpre_str and fitm.vars.depvpre_str
% format fitm(i).vars.depvpre_str{j} = {fieldspec1, fieldspec2, ... fieldspecN};
% format fitm(i).vars.indvpre_str{j} = {fieldspec1, fieldspec2, ... fieldspecN};

% where fieldspec is a string, with substrings separated by comma then space
% fieldspec specifies the data to use from struct 'ts', which stores various timeseries
% for example, for ts.resp, fieldspec requires 4 delimiters (', '), since there are 4 levels in the struct ts.resp,
% namely ts.resp.tsclass.regionex.parsex.normex,
% so fieldspec would follow the pattern ['tsclass, regionex, parsex, normex']
% where tsclass is a field in the first level of struct 'ts'
% regionex is region extraction string in mn.regionex_all above,
% parsex is extraction param string
% normex is normalization param string
% for ts.ball and ts.vis, fieldspec only has two levels, since ball and vis are not derived from specific brain regions, or roi extraction runs
% for ts.bump, fieldspec has 6 levels (the same four as bump.resp, with 2 more specifying bump domain, and bump parameter, following this pattern
% ['tsclass, regionex, parsex, normex, bumpdomain, bumpparam']
% for all substrings in fieldspec, you can use '*' as wildcard, all matches will be used
% you can use multiple fieldspec, all matches in a single outer cell (index j) will be grouped into a variable for fitting
% fitm.vars.indvpre_str and fitm.vars.depvpre_str are matched by index i in fitm(i)
% within a single fitm(i).vars.indvpre_str or fitm(i).vars.depvpre_str, you can specify multiple cells with index j, in single fitm(i).indv{j} or fitm(i).vars.depvpre_str{j}
% indvpre_str and depvpre_str are matched by index j if fitm(i).vars_combine is 'each',
% if fitm(1).vars_combine is 'any', then all combinations of single fitm(i).indv and single fitm(i).depv are used
% for example
%    fitm(1).vars.depvpre_str{1} = {['resp, no_r, mo*, in_rawf_pc_f_cl_f_w_no']};
%    fitm(1).vars.indvpre_str{1} = {['ball, angvel'], ['bump, pb, mo*, *, all, mu']};

%for now, depv at single struct and outer cell level should come from single regionex
fitm(1).vars.depvpre_str{1} = {['resp, no_l, mo*, in_rawf_pc_f_cl_f_w_no']}; %if empty, do will be set to false
fitm(1).vars.depvpre_str{2} = {['resp, no_r, mo*, in_rawf_pc_f_cl_f_w_no']}; %if empty, do will be set to false
fitm(1).vars.indvpre_str{1} = {['ball, angvel'], ['bump, eb, mo*, *, all, vel']};
fitm(1).vars.indvpre_str{2} = {['ball, angvel'], ['resp, gal, mo*, in_rawf_pc_f_cl_f_w_no']};
fitm(1).vars.indvpre_str{3} = {['ball, angvel']};

fitm(1).vars_combine = 'any'; %any or each, how to combine depv and indv outermost cells for a given fit structure element
fitm(1).epochinds = {[2 3 4]};
fitm(1).validation_fold = 6; %applied to all mdlnames; k in k-fold cross-validation; k non-overlapping validation sets; if numbouts of each epoch in epochinds is divisible by validation_fold, will validate on numbouts/validation_fold bouts for each epoch in epochinds; if only one bout for each epoch, will evenly split each bout into k validation sets; otherwise will error; 0 skips validation

% see notes_mdlname for notes about fitm.mdlname syntax

fitm(1).mdlname = 'fnet_A01_sh16';
fitm(1).plt.doplots = 100;

fitm = default_fit_params(fitm);


%% SCATTERPLOTS

% params for scatterplots
%scatterplots come at the end so all variables computed in 'post' pipeline are available for scatterplots

%if any of x, y, or z are polar, they are moved to theta on the scatterplots; two polar variables get layered in r
% scat(1).vars.x_str{1} = {['ball, *for*'], ['ball, *yaw*'], ['vis, *']};
scat(1).vars.x_str{1} = {['ball, *'], ['vis, *']};
scat(1).vars.y_str{1} = {['resp, fullfov, mo*, in_rawf_pc_f_cl_f_w_yes']}; %if empty, do will be set to false
scat(1).vars.z_str{1} = {['']};
scat(1).vars.y_str{2} = {['resp, fullfov, cm*, in_cmc_pc_f_cl_null_w_null']};
scat(1).vars.y_str{3} = {['resp, fullfov, cm*, in_cmc_pc_f_cl_null_w_null']};
% scat(1).vars.x_str{2} = {['ball, *for*'], ['ball, *yaw*'], ['vis, *']};
scat(1).lagsxy_sec = linspace(-1, 1, 1e4); %empty or zero to skip; scalar or vector; seconds of lag, rounded to nearest frame; repeated frames are omitted; to see all frames within range, use spacing smaller than sample rate (just use very small spacing to ensure it, so you don't have to think about it, like this linspace(-1, 1, 1e4)); negative means x follows y, positive means y follows x; 
scat(1).lagsz_sec = linspace(-1, 1, 1e4); %same as lagxy_sec, except z lags are applied for each xy lag (xy vars are lagged, then together lagged relative to z); will be automatically set to 0 if there is no z variable 
scat(1).lags_to_plot = 'zeroandbest'; % 'zero', 'best', 'zeroandbest', 'all'
scat(1).plot_z_as_color = 1; %if z variable exists, 0 will make 3d scatterplot, 1 will make 2d with z variable as color 
scat(1).vars_combine = 'any'; %any or each, how to combine depv and indv outermost cells for a given fit structure element
scat(1).ignore_missing_vars = 0; %set to 1 not error if any requested timeseries in vars above do not exist
scat(1).epochinds = {[1]}; %cell array of vectors or scalars listing epochs (within single trial) to group in scatterplots, empty cell with empty vector for all epochs, like this {[]}
scat(1).gif_visibility = 'on'; %0 will save but not plot, 1 will do both



%% PLOT EXPERIMENT

% params for plot_experiment

pltexp(1).vars.x_str{1} = {['ball, *forv*']};
% pltexp(1).vars.x_str{1} = {['ball, *for*'], ['vis, *']};
pltexp(1).vars.y_str{1} = {['resp, fullfov, mo*, in_rawf_pc_f_cl_f_w_yes']}; %if empty, do will be set to false
pltexp(1).vars.z_str{1} = {['']};
% pltexp(1).vars.y_str{2} = {['resp, fullfov, cm*, in_cmc_pc_f_cl_null_w_null']};
pltexp(1).vars_combine = 'any'; %any or each, how to combine depv and indv outermost cells for a given fit structure element
pltexp(1).ignore_missing_vars = 0; %set to 1 not error if any requested timeseries in vars above do not exist
pltexp(1).epochinds = {[1]}; %cell array of vectors or scalars listing epochs (within single trial) to group in scatterplots, empty cell with empty vector for all epochs, like this {[]}
pltexp(1).gif_visibility = 'on'; %0 will save but not plot, 1 will do both

pltexp(1).plotinds.t = [];%t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
pltexp(1).plotinds.z = []; %z indices to plot, empty for all, negative for that number equidistant from all available
pltexp(1).display_range = [0,1]; 

%% HIRES

%params for hires stack (high z resolution version of main stack) . . . this code is a little deprecated
%hires stack is only used in making morphological rois, set mroi.use_hires=1 to use
%params below, in hires, are for processing the hires stack, and visualization with gif in hires.gif
hires.ld.crop_flyback = 1; %crop flyback frames from each volume 
hires.ld.zero_stack = 1; %subtract min to make min zero 
hires.ld.cropinds_t_start = 0; %how many samples to remove from beginning of stack; similar to cropdata in rec6 (also applied in metrics2 without variable name cropdata), crop first 4 and last 2 imaging frames (stimulus features, and deprecated responses, have been extracted with this cropping in rec6)
hires.ld.cropinds_t_end = 0; % how many samples to remove from end of stack
hires.ld.plot_stack_stats = 0; %function this uses is old and needs to be updated

hires.ld.gif.plotinds.t = [1]; %t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
hires.ld.gif.plotinds.z = []; %z indices to plot, empty for all, negative for that number equidistant from all available
hires.ld.gif.rescale_each_stack = 1; %rescale each subplot to same range 0-1 before combining
hires.ld.gif.display_range = [0 1]; %combined ploto rescale arguments, [lower, upper]
hires.ld.gif.smooth_window_temporal = 0; %smooth the stack in time, 0 to skip
hires.ld.gif.plot_stack_gif = 1; %this one is not available in ld.gif (it is automatically determined); haven't made this one automatic yet

hires.do_reg_plots = 1;
hires.disttype = 'monomodal'; % multimodal monomodal, used in register_one_stack_to_another_in_3d from within register_3d_hires_to_3d_lores
hires.regtype = 'rigid'; %3d registration type (rigid should be best for tiny fly brain), used in register_one_stack_to_another_in_3d from within register_3d_hires_to_3d_lores
hires.use_caiman_on_hires = 0; %keep at 0 bc pipeline not yet finished for this option (also doens't seem to help)
hires.caiman_hr_str = '*'; %empty to skip

%% CARL'S OLD PROJECT

%overwrite some params for carl's old project
if ~strcmp(mn.recdate, '*') && strcmp(mn.recdate(1:2), '22') %override some settings for old project
    mn.old_project = 1;
    ld.cropinds_t_start = 4; % how many samples to remove from beginning of stack; similar to cropdata in rec6 (also applied in metrics2 without variable name cropdata), crop first 4 and last 2 imaging frames (stimulus features, and deprecated responses, have been extracted with this cropping in rec6)
    ld.cropinds_t_start = 2; % how many samples to remove from end of stack
    fitm.mdl_lag_sec = 1; %how many samples indv precedes depv for model fit . . . for now, only nonnegative integers (0 to lenfit_samp - 1)
    fitm.mdl_length_sec = 1.25;
end

%% assign to struct


update_param_struct; %call this script to overwrite any default params above with fields in parsin, and organize into parsout 


end