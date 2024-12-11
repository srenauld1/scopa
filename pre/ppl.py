
#!/usr/bin/env python

##########################################################################################################################################

#SEE README.md FOR MORE DOCUMENTATION#

##########################################################################################################################################

import sys
import os
import json

currscriptdir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.dirname(currscriptdir))

print("\n\nLIST OF PATHS AVAILABLE TO ppl.py:\n","\n ".join(sys.path),"\n")

if '--pth_parsfile' in sys.argv: #in noninteractive mode, all options come from cxp (and a handful are hard coded to never change here)
  cluster_backend = 'multiprocessing' #irrelevant if use_cluster=0; use 'multiprocessing' on O2 to speed up caiman code
  makeplots = 0 #should be 0 if running job from cxp on O2, so not a command line argument because it errors unless running in an interactive mode, like in vscode, in register calls plot_gif, in extract calls caiman_plots_all, which shows extracted components' spatial masks and timeseries,  
  do_crop_only = 0 #should be 0 if running job from cxp on O2, since this is interactive drawing/cropping of FOV
  print("pth_parsfile passed as input to ppl.py (in batch mode), using options from pth_parsfile (options from cxp.sh)")
else: #in interactive mode, read options set in optdfpre, and also set a few options that user will not need to modify in interactive mode, here, to keep separate from optdfpre.py, where user sets options; 2 options, do_copyfiles and recording_index, are unlikely to be changed by user in interactive mode, but it's at least possible, so they are in optdfpre
  print("pth_parsfile not passed as input (in interactive mode), using options from optdfpre.py")
  exec(open(currscriptdir + '/' + 'optdfpre.py').read())
  first_job = 1 #this should always be 1 if you're running ppl.py directly/interactively, first_job is only used when ppl.py is called from cxp.sh, as part of a larger pipeline 
  jobnm = '' #empty for intyeractive mode; job name run from cxp (noninteractive job identifier)
  pth_parsfile = '' #string, single element not in list, skip if empty, name of input argument txt file, convenient for passing same arguments to multiple stages of pipeline 
  scopatmpdir = '' #string, keep empty for interactive; directory for scopatmp folder; automatically defined in make_paths
  fnind_fn_prefix = '' #string, keep empty for interactive; the job id (before any underscore if arrayed) for the first job run by cxp.sh, will point to a file that saves filename indices to ensure files get the same index across all jobs run by cxp, make empty to skip 


from parse_args import parse_command_line
from paths_scopa import make_paths
from choose_files import choose_files
from copy_files_scopa import copy_files_scopa

if len(sys.argv)>1: #if in noninteractive mode (running cxp), read in arguments from cxp

    [folder_with_all_recordings_on_storage_and_compute_filesystems, pth_storage_prefix, 
                      do_copyfiles, fnind_fn_prefix, pth_parsfile, scopatmpdir, 
                      recdate, fly, trial, folder_substring, recording_index, file_matching_style,
                      registration_template_group_id, do_register, scopatmplt, clip, discard_channel_reg, chan_primary_when_two_reg, clipinterp, register_in_2d, halfwidth_window_bgsub, smlenpx_mcp, max_shifts_prc, use_cluster,  
                      do_denoise, do_stitch, chan_dn, denoise_volume, denoise_slice_index, num_epochs_denoise, 
                      use_background_subtracted, use_denoised, epoch_choose_denoise, 
                      do_remove, smlenpx_rsc, use_scannoise_removed,
                      do_extract, methodex, extract_in_2d, regionex, 
                      do_a2p, first_job] = parse_command_line()


[pth_scopa, pth_allrec, pth_fldr_copydest_prefix, pth_denoising, pth_fldr_fnind, pth_optdf, pth_optroi] = make_paths(currscriptdir, do_copyfiles, folder_with_all_recordings_on_storage_and_compute_filesystems, pth_storage_prefix, scopatmpdir)


if do_register + do_denoise + do_stitch + do_remove + do_extract + do_crop_only + do_a2p > 1:
  raise Exception ("only one of these variables can be true: do_register, do_denoise, do_stitch, do_remove, do_extract, do_crop_only, do_a2p")
else:
  if recording_index !=['all'] and len(recording_index)>1:
     raise Exception ("currently can only have one recording_index per parallel run")
  if do_denoise:
    if denoise_volume==0 and len(denoise_slice_index)>1 and denoise_slice_index != ['all'] and denoise_slice_index!='all':
        raise Exception ("if denoise_volume==0, must either pass single denoise_slice_index (not multiple), or denoise_slice_index must be all. . . IS THIS STILL TRUE?")
    if denoise_volume==1 and denoise_slice_index != ['all'] and denoise_slice_index!='all':
        raise Exception ("if denoise volume == 1, denoise slice index must be 'all' (for now, although code can be adapted to accept z subset range) . . . IS THIS STILL TRUE?")

if not do_copyfiles:

  import numpy as np
  import cv2
  import logging
 
  if do_register or do_extract or do_crop_only:
    try:
        cv2.setNumThreads(0) #don't think this is necessary 
    except:
        pass

    try:
        if __IPYTHON__: #for debugging only. allows to reload classes when changed
            get_ipython().magic('load_ext autoreload')
            get_ipython().magic('autoreload 2')
    except NameError:
        pass

    try:
        shell = get_ipython().__class__.__name__
        print(shell)
    except NameError:
        print("in py file probably")      # Probably standard Python interpreter

    from register import register
    from spatial_downsample_fictrac_video import spatial_downsample_fictrac_video
    from extract import extract
    import logging
    logging.basicConfig(format=
                        "%(relativeCreated)12d [%(filename)s:%(funcName)20s():%(lineno)s]"\
                        "[%(process)d] %(message)s",
                        #filename="/n/scratch3/users/c/caw846/ctmp/caiman.log",
                        level=logging.WARNING,
                        )

  elif do_denoise:
    from denoise import denoise
    from z_separate import separate_z_slices_for_denoising

  elif do_stitch:
    from z_stitch import stitch_denoised_slices
    
  elif do_remove or do_a2p:
    import matlab.engine
    import io


[pth_read_all, pth_fldr_all, fn_prefix_all, pth_prefix_all, pth_md_all, pth_daq_all, pth_ftvid_all, pth_ftdat_all, pth_croplim_all, pth_hires_all, carls_old_project_all] = \
  choose_files(first_job, pth_allrec, recdate, fly, trial, folder_substring, recording_index, file_matching_style, pth_fldr_fnind, fnind_fn_prefix, 
                 do_copyfiles, do_register, do_denoise, do_stitch, do_remove, do_extract, do_a2p, use_background_subtracted, use_denoised, use_scannoise_removed,
                 folder_with_all_recordings_on_storage_and_compute_filesystems)


for ri, _ in enumerate(pth_read_all):
   
    if do_copyfiles!=0: #copy data (from storage to compute filesystem, or vice versa)
      copy_files_scopa(do_copyfiles, do_register, do_denoise, do_stitch, do_extract, do_crop_only, do_a2p, pth_read_all[ri], pth_md_all[ri], pth_daq_all[ri], pth_ftvid_all[ri], pth_ftdat_all[ri], pth_croplim_all[ri], pth_hires_all[ri], pth_fldr_copydest_prefix, pth_fldr_all[ri], folder_with_all_recordings_on_storage_and_compute_filesystems)
        
    elif do_copyfiles==0: #analyze data 
      
      print("\n\n\nOPERATING ON THE FOLLOWING FILE: \n" + pth_read_all[ri] + "\nLOADING SCANIMAGE METADATA FROM THIS FILE: \n" + pth_md_all[ri]) 

      with open(pth_md_all[ri], 'r') as file:
        md = json.loads(file.read())

      if do_register:
          try: #spatial_downsample_fictrac_video is not essential, so putting in a try block
            spatial_downsample_fictrac_video(pth_ftvid_all[ri], pth_prefix_all[ri], makeplots) #doing this in registration because it is the beginning of the pipeline, it's fast, and doesn't require much memory 
          except Exception as err:
            print("AN EXCEPTION OCCURRED DURING spatial_downsample_fictrac_video, PIPELINE WILL CONTINUE BUT FICTRAC VIDEO HAS NOT BEEN SPATIALLY DOWNSAMPLED. \nTHE EXCEPTION WAS: \n", err)
          register(pth_read_all[ri], pth_prefix_all[ri], pth_allrec, md, scopatmplt, clip, discard_channel_reg, chan_primary_when_two_reg, register_in_2d, halfwidth_window_bgsub, max_shifts_prc, smlenpx_mcp, clipinterp, registration_template_group_id, cluster_backend, use_cluster, makeplots)

      if do_denoise:
        chanstr_primary, chanstr_secondary = separate_z_slices_for_denoising(pth_read_all[ri], fn_prefix_all[ri], pth_denoising, md, denoise_volume, chan_dn) 
        denoise(pth_denoising, fn_prefix_all[ri], md['dims'], md['volrate'], denoise_slice_index, denoise_volume, num_epochs_denoise, carls_old_project_all[ri], chanstr_primary)
        if chanstr_secondary:
          denoise(pth_denoising, fn_prefix_all[ri], md['dims'], md['volrate'], denoise_slice_index, denoise_volume, num_epochs_denoise, carls_old_project_all[ri], chanstr_secondary)
           
      if do_stitch:
        stitch_denoised_slices(pth_denoising, fn_prefix_all[ri], pth_read_all[ri], md, denoise_volume, epoch_choose_denoise) 

      if do_remove:
        eng = matlab.engine.start_matlab()
        eng.addpath(eng.genpath(pth_scopa))
        mtlout = io.StringIO()
        mtlerr = io.StringIO()
        eng.scannoiserm(pth_read_all[ri], smlenpx_rsc, stdout=mtlout, stderr=mtlerr, nargout=0)

      if do_extract or do_crop_only:
        extract(pth_prefix_all[ri], pth_read_all[ri], pth_optdf, pth_optroi, md, extract_in_2d, methodex, regionex, maskname, do_crop_only, makeplots, cluster_backend, use_cluster)

      if do_a2p:
        eng = matlab.engine.start_matlab()
        eng.addpath(eng.genpath(pth_scopa))
        mtlout = io.StringIO()
        mtlerr = io.StringIO()
        eng.a2p(pth_read_all[ri], stdout=mtlout, stderr=mtlerr, nargout=0)
          
         

print("\n\n\nEXITING ppl.py") 
