function opt = input_params_carl()



% struct 'opt' holds all input params
% substructures within opt are mostly used within single functions called from a2p

%some params below have suffix '_str'; these are string inputs (for user input convenience) that are mapped later to numeric variables

%% MAIN

%params for main pipeline control in file a2p
opt.main.parent_folder_path = '~/stacks'; %full path to folder containing all recording folders (on local or o2)
opt.main.recdate = '20231119'; %can use wildcardsxw
opt.main.fly = '2'; %can use wildcards
opt.main.trial = '*'; %can use wildcards
opt.main.suffix_analysis = 'cmrg_dcdn'; %scopa 'pre' pipeline output filename suffix to use in this 'post' pipeline
opt.main.regionex_all = {'eb', 'gal_d', 'gal_v', 'gar_d', 'gar_v', 'no_l', 'no_r' }; %cell array of strings matching regionex from scopa 'pre' pipeline; append an underscore and suffix (format existingregionex_suffix) to create a new regionex with the same croplim as existing regionex (e.g., if the cuboid from 'pre' has two subregions you want to analyze separately, including with different morphological rois);  if no match from 'pre' you will be prompted to define the regionex (i.e., to define 'croplim', a cuboid, in interactive plots)
opt.main.timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS')) ;

opt.main.old_project = 0; %for carl


%% STACK VISUALIZATION (GIF)

%params for making gif of raw data movies in function load_stack
opt.gif.suffixes_plot = {
    %'cmrg', ...%comment if you don't want to plot (can comment all too)
    %'raw', ... %comment if you don't want to plot (can comment all too)
    %'cmrg_dcdn', ... %comment if you don't want toa plot (can comment all too)
    }; %anything missing will be skipped, will be reordered from least to most processed (by suffix length)
opt.gif.plotinds_t = [50.3]; %t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
opt.gif.plotinds_z = []; %z indices to plot, empty for all, negative for that number equidistant from all available
opt.gif.swapdim = 1; %true will flip z and t for plotting to change perspective on registration, recommended for length(plotinds_z)>1
opt.gif.nan_numlines = 4; %how many lines of nans to insert in dim 1 above each subplot
opt.gif.rescale_each_subplot = 1; %rescale each subplot to same range 0-1 before combining
opt.gif.rescalefac_wholeplot = [0 1]; %combined ploto rescale arguments, [lower, upper]
opt.gif.smooth_window_temporal = 0; %smooth the stack in time, 0 to skip
opt.gif.plot_stack_stats = 0; %function this uses is old and needs to be updated


%% MORPHOLOGICAL ROIS

% params for making morphological rois (manual or automated), mostly used in function make_morphological_rois
% for opt.mroi.use_hires, opt.mroi.use_drawn_rois, and opt.mroi.num_mroi_auto: use empty cell to skip, otherwise a cell array of strings from regionex_all;any string in regionex_all that is missing in opt.mroi will be skipped

%%params for the manually drawn morphological rois
opt.mroi.use_drawn_rois_str =  {'eb', 'gal_d', 'gal_v', 'gar_d', 'gar_v', 'no_l', 'no_r' }; %cell of regionex strings, let the user hand draw 2d or 3d morphological rois in an interactive plot, and save, or load if already drawn and saved

%%params for the automated morphological roi extraction (will be applied to drawn morphological rois, if they exist . . . for example, you draw a roi around a region, then there is automated morphological segmentation within that region)
opt.mroi.num_mroi_auto_str = {'eb-32'}; %each string is format regionex-integer, e.g. {'eb-12, 'pb-16'}, use 3d edge detection to define a 3d super-roi, then partition that super-roi into num_mroi_auto morphological rois; a drawn roi, if it exists, masks the regionex prior to automated super-roi extraction; num_mroi_auto and number drawn rois cannot both exceed 1 (i.e. the code cannot automatically partition discontiguous rois within a single regionex)
opt.mroi.use_hires_str = {''}; %cell of regionex strings, use hi-z-res stack to help make morphological rois (to help 3d edge detection of region boundaries, and to help automated subdivision of 3d region into morphological rois)
opt.mroi.create_mask_method = 'edge'; %method for automatically defining morphological roi mask (union of all morphological rois) from stack or union of manually drawn rois, options are 'edge', 'outlier', 'triangle', 'nonzero'
opt.mroi.subsample_mask_method = 'uniform'; %'skeleton' for elongated structures or 'uniform'; method for subsampling mask into rois; for 'uniform', opt.mroi.num_mroi_auto_str must be power of 2
opt.mroi.edgethresh = [.1, .7]; %two thresholds to detect strong and weak edges; includes weak edges in output only if they are connected to strong edges
opt.mroi.edgesig = [sqrt(2)*2 sqrt(2)*2 sqrt(2)*2 ]; %for edge detection, defines smoothing filter sigma for each dim xyz, or use one value for all dim, if 2d edge detection, first element is used for x and y
opt.mroi.closing_element_size = 8; %for bwmorph close after edge detection, helps connect edges

opt.mroi.do_other_plots = 0; %do plots besides overlay and hsvopt in make_morphological_rois and make_morphological_rois_auto

%params for roi overlay plot of morophological rois (make a gif showing each z slice of mean t stack)
opt.mroi.olayopt.do = 1; %plot or don't plot roi overlay with background, plots one roi at a time, each slice, with roi in red
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
% 'dffuuuvvv' % sliding window dff, uuu as percentile to compute f0 for each window, uuu as sliding window length in seconds, if uuu is 000 then f0 is computed across the entire timeseries, not a sliding window
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

%% FICTRAC/STIMULUS

%params for stimulus/fictrac processing
opt.ftrac.include_behavior = 0; %0 to skip behavior
opt.ftrac.no_stim_epochs = 0; %set to 1 if you have multiple epochs within a trial, epochs defined in load_fictrac or load_stim
opt.ftrac.dark_stim_end_duration = 60; %final seconds
opt.ftrac.smoothwindow_sec = 0.2; %full width of gaussian smoothing window (5 times std)
opt.ftrac.slopeorder = 2; %order of polynomial used to fit local slope
opt.ftrac.slopelen = 5; %window length used to fit slope
opt.ftrac.doplots = 0;

%% BUMP

% opt.pf holds params for computing population features, each substructure beneath opt.pf is for a different population feature, below, for example, is opt.pf.bump

% params for bump in compute_bump function
% a von mises is fit to the instantaneous relationship between each roi timeseries (given by all matches from opt.pf.bump.fit.depvpre_str) and all matches from opt.pf.bump.fit.indvpre_str
% the value of the independent variable at the max predicted response is the preferred heading for each roi
% if opt.pf.bump.domain_methodis 'functional', these preferred headings are used as the angle, and opt.pf.bump.fit.depvpre_str as the magnitude, in computing pva
% if the regionex in opt.pf.bump.fit.depvpre_str is in opt.pf.bump.numcluster_for_bump_domain_resample, and that regionex is followed by hyphen and number greater than zero, these preferred heading angles are resampled into that number, so that the rois evenly sample range 0-2pi (resampling changes angle and magnitude)
% if opt.pf.bump.domain_methodis 'morphological', angle is forced to be 0-2pi, with each roi evenly sampling that range

% opt.pf.bump.fit(1).depv{1} = {['resp, pb, mo*, in_rawf_pc_f_cl_rsc000100_w_*']};
%this will select all fields in struct 'ts', matching this pattern, with * as wildcard: ts.resp.pb.mo*.in_rawf_pc_f_cl_rsc000100_w_*
%the selected timeseries will be assigned to depv
%selecting indv uses the same approach
%depv and indv are matched at the outer cell level
%at the inner cell level, there can be multiple field specifiers (fieldspec)
%each fieldspec is a char array, composed of segments separated by comma with space (', '), each segment matching the name of a field at a different level under struct 'ts'
%depv and indv are composed of all timeseries matching fieldspecs
%if multiple matches, depv is concatenated along second dim (time), since currently fitmdl fits single timeseries
%if multiple matches, indv is concatenated along first dim (not time), since fitmdl can accept multidimensional independent variable
% opt.pf.bump.fit(1).indv{1} = {['vis, angsd']};

%params for computing bump
opt.pf.bump.do = 1; %0 to skip compute_bump
opt.pf.bump.bump_method = 'pva'; %'pva' for vector average
opt.pf.bump.domain_method = 'functional'; %'functional' to define circular domain with fit to each roi, or 'morphological' to define as circle across region mask
opt.pf.bump.bump_subdomain = {'all'}; %cell array of char, 'all', 'right', 'left', 'larger', 'weighted', 'random'
opt.pf.bump.slopeorder = 2; %order of polynomial used to fit local slope (e.g. to compute bump speed)
opt.pf.bump.slopelen = 5; %order of polynomial used to fit local slope (e.g. to compute bump speed)
opt.pf.bump.smoothwindow_sec = 0.2; %full width of gaussian smoothing window (5 times std)
opt.pf.bump.numcluster_for_bump_domain_resample_str = {'eb-16'}; %how many clusters/superrois across the entire region (not hemisphere) when resampled uniformly prior to computing bump as vector average, cell array of string 'regionex-integer', regionex must exist in matches to opt.pf.bump.fit.depvpre_str  . . . to skip resampling for a regionex, just don't list it here, or write 'regionex-0'
opt.pf.bump.resample_smoothfac = 1; %when resampling compass, bandwidth of the antialiasing filter, larger number will have smoother resampled compass
opt.pf.bump.rescale_clusters = 1; %just before computing bump, rescale each cluster's timeseries to range 0-1
opt.pf.bump.omitnan = 1; %ignore nans in case there are any (e.g., making hybrid morph-func rois, some morph rois have no func members, making their response 'nan', omit will ignore this in computing pva)
opt.pf.bump.doplots = 0;

%params for finding preferred heading using fitmdl
% opt.pf.bump.fit(1).depvpre_str{1} = {['resp, pb, mo*, in_rawf_pc_f_cl_rsc000100_w_*']}; %will skip bump if empty opt.pf.bump.fit(1).depv{1} = {};
opt.pf.bump.fit(1).depvpre_str{1} = {['resp, eb, mo*, in_rawf_pc_f_cl_rsc000100_w_*']}; %will skip bump if empty opt.pf.bump.fit(1).depv{1} = {};
opt.pf.bump.fit(1).indvpre_str{1} = {['vis, angsd']};
opt.pf.bump.fit(1).depv_indv_combine = 'any'; %any or each, how to combine depv and indv outermost cells for a given fit structure element

opt.pf.bump.fit(1).normalize_indv = 'none';
opt.pf.bump.fit(1).validation_fold = 0; %applied to all mdlnames; k in k-fold cross-validation; k non-overlapping validation sets; if numbouts of each epoch in epochinds is divisible by validation_fold, will validate on numbouts/validation_fold bouts for each epoch in epochinds; if only one bout for each epoch, will evenly split each bout into k validation sets; otherwise will error; 0 skips validation
opt.pf.bump.fit(1).mdlname = 'fnet_v'; %'fnet_v';
if str2double(opt.main.recdate)<20231119
    opt.pf.bump.fit(1).epochinds = {[4]}; %closed loop epochind for 1st dataset
else
    opt.pf.bump.fit(1).epochinds = {[5]}; %closed loop epochind for 2nd dataset
end
opt.pf.bump.fit(1).mdl_length_sec = 0;
opt.pf.bump.fit(1).hsv_background = 'rois';
opt.pf.bump.fit(1).sort_method = 'unbiased';
opt.pf.bump.fit(1).use_saved_model = 1;
opt.pf.bump.fit(1).doplots = 1;


opt.pf.bump.fit = default_fit_params(opt.pf.bump.fit);

%% FIT MODEL


%params for fitting model using fitmdl
% modeling depv in fitmdl function
% fitmdl fits model describing how indv is transformed into depv

% opt.fit.indvpre_str.(regionex) specifies which input to use for fit,
% it is a cell array of cell arrays of strings defining variable struct then field of that struct
% for example opt.fit.indvpre_str.no_r = {{'ball', 'velrsd'}, {'bump',
% 'mu'}} will fit depv (specified as described above) in regionex 'no_r' to
% two-dimensional input, the first dimension being ball.velrsd, the second being bump.mu
%the name of the innermost nested field must be a regionex that is listed in opt.fit.regionpat_fit
%since roi responses for all regionex are extracted and normalized before fitmdl, responses from all rois, in struct 'resp', are available as input to fitmdl
%since the bump is computed before fitmdl, fields from structure 'bump' are available as input to fitmdl
%subfield not listed, uses all, like wildcard

% to specify independent and dependent variables for model fitting, use opt.fit.indvpre_str and opt.fit.depvpre_str
% format opt.fit(i).depvpre_str{j} = {fieldspec1, fieldspec2, ... fieldspecN};
% format opt.fit(i).indvpre_str{j} = {fieldspec1, fieldspec2, ... fieldspecN};

% where fieldspec is a string, with substrings separated by comma then space
% fieldspec specifies the data to use from struct 'ts', which stores various timeseries
% for example, for ts.resp, fieldspec requires 4 delimiters (', '), since there are 4 levels in the struct ts.resp,
% namely ts.resp.tsclass.regionex.parsex.normex,
% so fieldspec would follow the pattern ['tsclass, regionex, parsex, normex']
% where tsclass is a field in the first level of struct 'ts'
% regionex is region extraction string in opt.main.regionex_all above,
% parsex is extraction param string
% normex is normalization param string
% for ts.ball and ts.vis, fieldspec only has two levels, since ball and vis are not derived from specific brain regions, or roi extraction runs
% for ts.bump, fieldspec has 6 levels (the same four as bump.resp, with 2 more specifying bump domain, and bump parameter, following this pattern
% ['tsclass, regionex, parsex, normex, bumpdomain, bumpparam']
% for all substrings in fieldspec, you can use '*' as wildcard, all matches will be used
% you can use multiple fieldspec, all matches in a single outer cell (index j) will be grouped into a variable for fitting
% opt.fit.indvpre_str and opt.fit.depvpre_str are matched by index i in opt.fit(i)
% within a single opt.fit(i).indvpre_str or opt.fit(i).depvpre_str, you can specify multiple cells with index j, in single opt.fit(i).indv{j} or opt.fit(i).depvpre_str{j}
% indvpre_str and depvpre_str are matched by index j if opt.fit(i).depv_indv_combine is 'each',
% if opt.fit(1).depv_indv_combine is 'any', then all combinations of single opt.fit(i).indv and single opt.fit(i).depv are used
% for example
%    opt.fit(1).depvpre_str{1} = {['resp, no_r, mo*, in_rawf_pc_f_cl_f_w_no']};
%    opt.fit(1).indvpre_str{1} = {['ball, velrsd'], ['bump, pb, mo*, *, all, mu']};

%for now, depv at single struct and outer cell level should come from single regionex
opt.fit.do = 1; %0 to skip fit_mdl
opt.fit(1).depvpre_str{1} = {['resp, no_l, mo*, in_rawf_pc_f_cl_f_w_no']}; %if empty, do will be set to false
opt.fit(1).depvpre_str{2} = {['resp, no_r, mo*, in_rawf_pc_f_cl_f_w_no']}; %if empty, do will be set to false
% opt.fit(1).indv{1} = {['ball, velrsd'], ['bump, pb, mo*, *, all, mu']};
% opt.fit(1).indvpre_str{1} = {['ball, velrsd'], ['bump, pb, mo*, *, all, vel']};
opt.fit(1).indvpre_str{1} = {['ball, velrsd'], ['bump, eb, mo*, *, all, vel']};
opt.fit(1).indvpre_str{2} = {['ball, velrsd'], ['resp, gal, mo*, in_rawf_pc_f_cl_f_w_no']};
opt.fit(1).indvpre_str{3} = {['ball, velrsd']};

opt.fit(1).depv_indv_combine = 'any'; %any or each, how to combine depv and indv outermost cells for a given fit structure element
opt.fit(1).epochinds = {[2 3 4]};
opt.fit(1).validation_fold = 6; %applied to all mdlnames; k in k-fold cross-validation; k non-overlapping validation sets; if numbouts of each epoch in epochinds is divisible by validation_fold, will validate on numbouts/validation_fold bouts for each epoch in epochinds; if only one bout for each epoch, will evenly split each bout into k validation sets; otherwise will error; 0 skips validation

% see notes_mdlname for notes about opt.fit.mdlname syntax

opt.fit(1).mdlname = 'fnet_A01_sh16';
opt.fit(1).plt.doplots = 100;

opt.fit = default_fit_params(opt.fit);


%% SCATTERPLOTS

% params for scatterplots
%scatterplots come at the end so all variables computed in 'post' pipeline are available for scatterplots
opt.scatter.do_scatter = 1;
opt.scatter.epochinds = {[1 2 3 4 5]; [1 4]; [2 3]; [1]; [2]; [3]; [4]; [5]}; %cell array of vectors or scalars listing epochs (within single trial) to group in scatterplots, empty cell with empty vector for all epochs, like this {[]}


%% HIRES

%params for hires stack (high z resolution version of main stack) . . . this code is a little deprecated
%hires stack is only used in making morphological rois, set opt.mroi.use_hires=1 to use
%params below, in opt.hires, are for processing the hires stack, and visualization with gif in opt.hires.gif
opt.hires.gif.plotinds_t = [1]; %t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
opt.hires.gif.plotinds_z = []; %z indices to plot, empty for all, negative for that number equidistant from all available
opt.hires.gif.swapdim = 1; %true will flip z and t for plotting to change perspective on registration, recommended for length(plotinds_z)>1
opt.hires.gif.nan_numlines = 4; %how many lines of nans to insert in dim 1 above each subplot
opt.hires.gif.rescale_each_subplot = 1; %rescale each subplot to same range 0-1 before combining
opt.hires.gif.rescalefac_wholeplot = [0 1]; %combined ploto rescale arguments, [lower, upper]
opt.hires.gif.smooth_window_temporal = 0; %smooth the stack in time, 0 to skip
opt.hires.gif.plot_stack_stats = 0; %function this uses is old and needs to be updated
opt.hires.gif.plot_stack_gif = 1;
opt.hires.do_reg_plots = 1;
opt.hires.disttype = 'monomodal'; % multimodal monomodal, used in register_one_stack_to_another_in_3d from within register_3d_hires_to_3d_lores
opt.hires.regtype = 'rigid'; %3d registration type (rigid should be best for tiny fly brain), used in register_one_stack_to_another_in_3d from within register_3d_hires_to_3d_lores
opt.hires.use_caiman_on_hires = 0; %keep at 0 bc pipeline not yet finished for this option (also doens't seem to help)
opt.hires.caiman_hr_str = '*'; %empty to skip

%% METADATA (TO ADD TO EXISTING METADATA FROM *metadatanew.mat)

%params to be added to metadata struct that was created in python preprocessing
opt.md.croptimeinds = [0 0]; %this is only relevant for carl's old project

%% CARL'S OLD PROJECT


%overwrite some params for carl's old project
if strcmp(opt.main.recdate(1:2), '22') %override some settings for old project
    opt.main.old_project = 1;
    opt.main.no_stim_epochs = 1;
    opt.md.croptimeinds = [4 2]; %same as cropdata in rec6 (also applied in metrics2 without variable name cropdata), crop first 4 and last 2 imaging frames (stimulus features, and deprecated responses, have been extracted with this cropping in rec6)
    opt.fit.epochinds = {[1]};
    opt.fit.mdl_lag_sec = 1; %how many samples indv precedes depv for model fit . . . for now, only nonnegative integers (0 to lenfit_samp - 1)
    opt.fit.mdl_length_sec = 1.25;
end

%% order fields

opt = orderfields_recursive(opt);
