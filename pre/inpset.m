

inp.user = 'caw846';
inp.remote = '@o2.hms.harvard.edu';
inp.shfile = 'cxp.sh';


inp.do_register=1; %0 or 1, no space after =, caiman normcorre registration (python)
inp.do_denoise=0; %0 or 1, no space after =, deepcad denoise (python)
inp.do_remove=0; %0 or 1, no space after =, remove scan noise (matlab)
inp.do_extract=1; %0 or 1, no space after =, caiman source extraction (python)
inp.do_analysis=0; %0 or 1, no space after =, first-order analysis of imaging and stimulus/behavior data (matlab)
inp.do_copyfiles_sequence=[1]; %set to (1 0 2) (ie copy in, no copy, copy out) to copy only required files from storage server to O2, then compute on those files (creating new files), then copy new contents back to storage server (requires access to O2 "transfer job partition", must request access at rchelp@hms.harvard.edu), set to (0) to skip all copying and just copy manually
% inp.jobarrayind=[0]; %unlike many of the bash arrays here, nonsequential syntax for jobarrayind uses commas, like this ( 0,2,7 ), and sequential syntax uses dash, like this ( 0-2 ) . . . indices for parallel runs (using slurm job array), specifies which recording to analyse from list of those matching file specifiers below . . . right now only available paralellization is by recording tif identified with date_fly_trial and folder substring, and each parallel job will have only one jobarrayind
% inp.fnind_fn_prefix_override=''; %if you want to use a file/jobarrayind mapping from a previous cxp run (e.g. if there was an error partway through), you can supply the FNIND_FN_PREFIX of that run here (but txt files with prefix fnind_fn_prefix_override must still be present in scopa/fnind), leave empty to let cxp assign a new FNIND_FN_PREFIX
% 
% %%%%%%%%%%%% SET PARAMS FOR IDENTIFYING RECORDING %%%%%%%%%%%%
% 
% %set input args common to all sbatch jobs below (job-specific arguments are specified within each sbatch file)
% %matches filenames with pattern RECDATES_FLY_TRIAL_suffix.tif (where suffix is automatically determined by stage of pipeline) or RECDATES_FLY_*_TRIAL_*_*.tif ( * is wildcard)
% %matches within folders containing FOLDER_SUBSTRING ( * is wildcard)
% %matching file can be anywhere in directory tree under directory superfolder_name_compute (or superfolder_name_storage if copying to O2)
% 
% %THESE BASH LISTS MUST BE SINGLE-QUOTED, SPACE-DELIMITED, ENCLOSED BY PARENTHESES (this prevents asterisk * from causing problems) 
% 
% inp.FOLDER_WITH_ALL_RECORDINGS_ON_STORAGE_AND_COMPUTE_FILESYSTEMS=('stacks');
inp.PTH_STORAGE_PREFIX=('/n/files/Neurobio/wilsonlab/wienecke/');
% 
% inp.RECDATE=('202306*');
% inp.FLY=('*');
% inp.TRIAL=('*');
% inp.FOLDER_SUBSTRING=('*'); %in case RECDATE, FLY, and TRIAL is not specific enough, can also match only within folders containing FOLDER_SUBSTRING 
% inp.FILE_MATCHING_STYLE=('any'); %'any' will match any combination of elements from RECDATE, FLY, TRIAL, FOLDER_SUBSTRING, 'each' will  match corresponding elements (must all be equal length, or length 1 in which case element is copied to match length of whichever has length greater than 1)
% 
% 
% %%%%%%%%%%%% SET PARAMS FOR ANALYSIS %%%%%%%%%%%%
% 
% inp.REGISTER_IN_2D=(1); %register each z slice independently
% inp.LEN_WINDOW_BGSUB=(0); %make zero to skip, otherwise window full width for line by line background subtraction (helps remove stimulus bleedthrough, but don't use unless there's a lot of bleedthrough)
% inp.LEN_WINDOW_SMOOTH_T_MCP=(0); %gaussian smoothing window length in register (prior to registration, helps register noisy movies)
% 
% inp.DENOISE_VOLUME=(1); %0 or 1, train on multiple z slices, or one z slice at a time
% inp.DENOISE_SLICE_INDEX=('all'); %'all' for all z slices, or list of z indices for subset
% inp.NUM_EPOCHS_DENOISE=(5); %how many training epochs (training is continuous across epochs, but model is saved after each to allow denoising (testing) to apply to model at different states of training)
% inp.EPOCH_CHOOSE_DENOISE=(5); %denoising epoch used going forward, denoised stack saved as tif with suffix dcdn (TODO: epoch is not saved in filename, meaning you have to delete or move existing dcdn_.tif and rerun with different EPOCH_CHOOSE_DENOISE if you want to use different epoch, thisn is faster than rerunning denoising, but still stupid, fix it soon) 
% 
% inp.USE_BACKGROUND_SUBTRACTED=(0); %note: value assigned here used in do_extract 
% inp.USE_DENOISED=(1);
% 
% inp.LEN_WINDOW_SMOOTH_T_RSC=(0); %smoothing window in remove_scan_noise 
% 
% inp.EXTRACT_IN_2D=(1);
% inp.REGIONEX=('pb');
% inp.INDEX_EXTRACTION_PARAM_SET=('default');
% 
