##default params for interactive mode (e.g. when pipeline_init.py is called directly, not from cxp.sh)
##these params can be changed, since these are the values that will be used in interactive mode
##these params are roughly in order in which they appear in the pipeline (up to do_analysis at least)

folder_with_all_recordings_on_storage_and_compute_filesystems = 'Sophia' #folder holding all recordings you want this pipeline to operate on, if you're using do_copyfiles, this will refer to a folder on storage server and o2, tree on storage will be mirrored on o2; it is a separate variable (rather than end of pth_storage_prefix) to emphasize that it is separated off and mirrored on O2 
pth_storage_prefix = '/n/files/Neurobio/wilsonlab/Sophia/' #string, single element not in list, pth_storage_prefix+folder_with_all_recordings_on_storage_and_compute_filesystems is the path to the storage folder containing all recordings, data will be copied from here, into a folder on scratch with name (folder_with_all_recordings_on_storage_and_compute_filesystems) then analyzed, then copied back, ignored if do_copyfiles==0, 
do_copyfiles = 0 #0, 1, or 2 . . . 1 does nothing but copy the files matching pattern from pth_storage_prefix to compute folder, 2 is same but vice-versa, 0 allows everything else in the pipeline to occur . . . set to 0 if you do not have access to pth_storage_prefix from where you're running this script
fnind_fn_prefix = '' #string, the job id (before any underscore if arrayed) for the first job run by cxp.sh, will point to a file that saves filename indices to ensure files get the same index across all jobs run by cxp, make empty to skip 
pth_parsfile = '' #string, single element not in list, skip if empty, name of input argument txt file, convenient for passing same arguments to multiple stages of pipeline 
scopatmpdir = '' #string, keep empty

recdate = ['20240919'] #list of strings, as it appears in the directory and raw file filename (with hyphen not underscore for now), '*' for any 
fly = ['7'] #list of strings, fly, '*' for any, can be len 1 or len(recdate), if len 1 and len(recdate)>1, fly will be copied to match
trial = ['*'] #list of strings, trial, '*' for any #
folder_substring = ['*'] #list of strings, '*' for any, match recordings only in folders containing any substring in list  
recording_index = ['all'] #list, 'all' or list of zero-indexed string ints or ints, if 'all', loop over all recordings matching pattern in pth_compute, if not 'all', zero indexed (can be str or int) operate on recording whose index (in sorted list of all recordings in pth_compute) matches value in recording_index
file_matching_style = 'any' #string, single element not in list, 'any' or 'each', if any, will find all files matching any combo from above lists, if each, will match files using corresponding elements of above lists

registration_template_group_id=('') #empty string to skip; list of strings, each formatted recdate_fly_trial_folderSubstring; for each string, use brackets to designate which single trial is used as template, while all trials matching string with chars inside brackets replaced with wildcard * are registered to that template; e.g.  '202406[01]_[1]_[1]_[60312]' will register all trials matching 202406*_*_*_* (if they are also matched to above file specifiers, recdate, fly, trial, folder_substring) to a template created from raw tif matching **/*312*/**/20240601_1_1*tif (or **/*312*/**/20240601_1_*trial_001*tif for flyg filename format); recordings requested above that do not match any REGISTRATION_TEMPLATE_GROUP_ID just get registered in the default way (without a template); strings cannot have overlapping matches (within brackets, or outside); template must match recording in xyz size; template is median of 5 frames, which are each mean of 10 frames, equidistant across entire stack; code will sleep (with messages) for up to 300 seconds while waiting for template to be created (in case being created in parallel job)  

do_register = 1 #caiman normCorre registration 
discard_channel_reg = None #None, 1, or 2
chan_primary_when_two_reg = 2 #1 or 2; one indexed; this is ignored if data has one channel or discard_channel_reg is not 'none';  channel that is registered first (typically the higher snr, or more static, or both), other channel gets shifted using this channel's registration; 
register_in_2d = 1 #one z slice at a time, for 4d data, ignored if 3d data  
halfwidth_window_bgsub = 0 #half width of patch over which mean is computed for background subtraction (patch is a line in x), applied before registration, won't happejn unless do_register==1, make zero to skip, 
len_window_smooth_t_mcp_sec = 0 #0.8 #smoothing window length, uses 1d gaussian with std that is (by default) one-tenth len_window_smooth_t_mcp_sec - 1 (since gaussian window radius is truncated at 5 std), (len_window_smooth_t_mcp_sec = 0 skips smoothing)
register_presmoothed = 0 # if 1, and if len_window_smooth_t_mcp_sec!=0, register the presmoothed stack to the smoothed stack and discard the smoothed stack, if 0 and if len_window_smooth_t_mcp_sec!=0, just register the smoothed stack and use that going formward  
