function parsout = default_hsv_opts(parsin)

do = 0; %1 to plot/save, 0 to just compute hsv image but skip plot/save  
foreground = 'allrois'; %'eachroi' plots each individually, 'allrois' plots all together
mdlname = ''; %string for swithcing among plotting defaults in plots_setup_hsv, leave empty for default set 
huestr = ''; %deprecated variable, leave empty 
huenorm = 'native'; %hue normalization method, 'native' normalizes to a preset range (hard coded in plots_setup_hsv) according to 'mdlname', 'relative' normalizes to the data range assigned to hue, 'manual' normalizes to the range set below in opt.mroi.hsv.hrange_in_manual; if you request 'native' but don't pass huelimnat to plots_compute_hsv it will switch to 'relative'; if you request 'manual' but don't set hrange_in_manual it will switch to 'relative'      
satnorm = 'relative'; %sat normalization method, same logic as huenorm
valnorm = 'relative';%val normalization method, same logic as huenorm
hrange_in_manual = []; %manual range for normalizing hue, prior to normalization to plot scale, whose max range is [0 1]), see plots_compute_hsv
srange_in_manual = []; %manual range for normalizing sat, prior to normalization to plot scale, whose max range is [0 1]), see plots_compute_hsv
vrange_in_manual = []; %manual range for normalizing val, prior to normalization to plot scale, whose max range is [0 1]), see plots_compute_hsv
hrange_out_manual = [0.25 1]; %hue plot scale, whose max range is [0 1] hue hange around color circle, defaults to less than full circle for non-periodic plotting domain, but overwrites in plots_setup_hsv to [0 1] when plotting a periodic huefeature (e.g. von mises center, ie mdlname 'v' with huestr 'loc'), see plots_compute_hsv
srange_out_manual = [0 1]; %sat plot scale, whose max range is [0 1], if you want to force saturation you can reduce (e.g. [0 0.75] will force smaller range to max saturation, see plots_compute_hsv
vrange_out_manual = [0 1];  %val plot scale, whose max range is [0 1], if you want to force value you can reduce (e.g. [0 0.75] will force smaller range to max value, see plots_compute_hsv
hueshift = 0; %0-1, circularly shift the hue map around the color circle for change to arbitrary color assignment, applied before any clipping due to, see plots_compute_hsv, this works for periodic or non-periodic features assigned to hue
ignorehue = 0; %when creating and plotting variable 'img', which is built from variable 'hsvmap', 1 ignores hue in variable 'hsvmap', makes constant 1, but does not change 'hsvmap'
ignoresat = 1;  %when creating and plotting variable 'img', which is built from variable 'hsvmap', 1 ignores sat in variable 'hsvmap', makes constant 1, but does not change 'hsvmap'
ignoreval = 1;  %when creating and plotting variable 'img', which is built from variable 'hsvmap', 1 ignores val in variable 'hsvmap', makes constant 1, but does not change 'hsvmap'

update_param_struct; %call this script to overwrite any default params above with fields in parsin, and organize into parsout 
