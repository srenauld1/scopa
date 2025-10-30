
#!/usr/bin/env python

##########################################################################################################################################

#SEE README.md FOR MORE DOCUMENTATION#

##########################################################################################################################################

import sys
import os
import json

currscriptdir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.dirname(currscriptdir))

print("\n\nLIST OF PATHS AVAILABLE TO pl.py:\n","\n ".join(sys.path),"\n")

if '--pth_parsfile' in sys.argv: #in noninteractive mode, all options come from pl (and a handful are hard coded to never change here)
  cluster_backend = 'multiprocessing' #irrelevant if use_cluster=0; use 'multiprocessing' on O2 to speed up caiman code
  makeplots = 0 #should be 0 if running job from pl on O2, so not a command line argument because it errors unless running in an interactive mode, like in vscode, in register calls plot_gif, in extract calls caiman_plots_all, which shows extracted components' spatial masks and timeseries,  
  do_crop_only = 0 #should be 0 if running job from pl on O2, since this is interactive drawing/cropping of FOV
  print("pth_parsfile passed as input to pl.py (in batch mode), using options from pth_parsfile (options from pl.sh)")
else: #in interactive mode, read options set in oset, and also set a few options that user will not need to modify in interactive mode, here, to keep separate from oset.py, where user sets options; 2 options, do_copyfiles and jobind, are unlikely to be changed by user in interactive mode, but it's at least possible, so they are in oset
  print("pth_parsfile not passed as input (in interactive mode), using options from oset.py")
  exec(open(currscriptdir + '/' + 'oset.py').read())
  first_noncopy_job = 1 #this should always be 1 if you're running pl.py directly/interactively, first_noncopy_job is only used when pl.py is called from pl.sh, as part of a larger pipeline 
  jobnm = '' #empty for intyeractive mode; job name run from pl (noninteractive job identifier)
  pth_parsfile = '' #string, single element not in list, skip if empty, name of input argument txt file, convenient for passing same arguments to multiple stages of pipeline 
  scopatmpdir = '' #string, keep empty for interactive; directory for scopatmp folder; automatically defined in pthmake
  fnind_fn_prefix = '' #string, keep empty for interactive; the job id (before any underscore if arrayed) for the first job run by pl.sh, will point to a file that saves filename indices to ensure files get the same index across all jobs run by pl, make empty to skip 
  do_autoallocate = 0 #autoallocate resources or not; only used in noninteractive mode

from parse_args import parse_command_line
from pthmake import pthmake
from filefind import filefind
from filecp import filecp
from autoallocate import autoallocate

if len(sys.argv)>1: #if in noninteractive mode (running pl), read in arguments from pl

    [folder_with_all_recordings_on_storage_and_compute_filesystems, pth_storage_prefix, 
                      do_copyfiles, do_autoallocate, fnind_fn_prefix, pth_parsfile, scopatmpdir, 
                      recdate, fly, trial, substr, jobind, file_matching_style,
                      registration_template_group_id, do_register, scopatmplt, clip, methodrg, clipinterp, register_in_2d, bglenpx, smlenpx_mcp, max_shifts_prc, use_cluster,  
                      do_denoise, dnraw, do_stitch, chan_dn, denoise_volume, denoise_slice_index, num_epochs_denoise, 
                      use_background_subtracted, use_denoised, epoch_choose_denoise, 
                      do_remove, stopband_rsc, smlensec_rsc, use_scannoise_removed,
                      do_extract, methodex, extract_in_2d, rgname, 
                      do_a2p, first_noncopy_job] = parse_command_line()


[pth_scopa, pth_allrec, pth_fldr_copydest_prefix, pth_denoising, pth_fldr_fnind, pth_optdf, pth_optroi] = pthmake(do_copyfiles, do_autoallocate, folder_with_all_recordings_on_storage_and_compute_filesystems, pth_storage_prefix, scopatmpdir)


if do_register + do_denoise + do_stitch + do_remove + do_extract + do_crop_only + do_a2p > 1:
  raise Exception ("only one of these variables can be true: do_register, do_denoise, do_stitch, do_remove, do_extract, do_crop_only, do_a2p")
else:
  if jobind !=['all'] and len(jobind)>1:
     raise Exception ("currently can only have one jobind per parallel run")
  if do_denoise:
    if denoise_volume==0 and len(denoise_slice_index)>1 and denoise_slice_index != ['all'] and denoise_slice_index!='all':
        raise Exception ("if denoise_volume==0, must either pass in single denoise_slice_index (not multiple), or denoise_slice_index must be all. . . IS THIS STILL TRUE?")
    if denoise_volume==1 and denoise_slice_index != ['all'] and denoise_slice_index!='all':
        raise Exception ("if denoise volume == 1, denoise slice index must be 'all' (for now, although code can be adapted to accept z subset range) . . . IS THIS STILL TRUE?")

if do_copyfiles==0 and do_autoallocate==0:

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
    from ftvdownsample import ftvdownsample
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
    from zsep import zsep_todn

  elif do_stitch:
    from zstitch import stitchdn
    
  elif do_remove or do_a2p:
    import matlab.engine
    import io


[pth_read_all, pth_fldr_all, fn_prefix_all, pth_prefix_all, pthmd_all, pth_daq_all, pth_ftvid_all, pth_ftdat_all, pth_opt_all, carls_old_project_all] = \
  filefind(first_noncopy_job, pth_allrec, recdate, fly, trial, substr, jobind, file_matching_style, pth_fldr_fnind, fnind_fn_prefix, 
                 do_copyfiles, do_register, do_denoise, dnraw, do_stitch, do_remove, do_crop_only, do_extract, do_a2p, use_background_subtracted, use_denoised, use_scannoise_removed,
                 folder_with_all_recordings_on_storage_and_compute_filesystems)


for ri, _ in enumerate(pth_read_all):
   
    if do_autoallocate==1: 
      
      autoallocate(do_copyfiles, do_register, do_denoise, do_stitch, do_remove, do_extract, do_crop_only, do_a2p, pth_read_all[ri], pthmd_all[ri], pth_daq_all[ri], pth_ftvid_all[ri], pth_ftdat_all[ri], pth_opt_all[ri], pth_fldr_copydest_prefix, pth_fldr_all[ri], folder_with_all_recordings_on_storage_and_compute_filesystems)

    else:
      
      if do_copyfiles!=0: #copy data (from storage to compute filesystem, or vice versa)
        filecp(do_copyfiles, do_register, do_denoise, do_stitch, do_remove, do_extract, do_crop_only, do_a2p, pth_read_all[ri], pthmd_all[ri], pth_daq_all[ri], pth_ftvid_all[ri], pth_ftdat_all[ri], pth_opt_all[ri], pth_fldr_copydest_prefix, pth_fldr_all[ri], folder_with_all_recordings_on_storage_and_compute_filesystems)
          
      elif do_copyfiles==0: #analyze data 
        
        print("\n\n\nOPERATING ON THE FOLLOWING FILE: \n" + pth_read_all[ri] + "\nLOADING SCANIMAGE METADATA FROM THIS FILE: \n" + pthmd_all[ri]) 

        with open(pthmd_all[ri], 'r') as file:
          md = json.loads(file.read())

        if do_register:
            try: #ftvdownsample is not essential, so putting in a try block
              ftvdownsample(pth_ftvid_all[ri], pth_prefix_all[ri], makeplots) #doing this in registration because it is the beginning of the pipeline, it's fast, and doesn't require much memory 
            except Exception as err:
              print("AN EXCEPTION OCCURRED DURING ftvdownsample, PIPELINE WILL CONTINUE BUT FICTRAC VIDEO HAS NOT BEEN SPATIALLY DOWNSAMPLED. \nTHE EXCEPTION WAS: \n", err)
            register(pth_read_all[ri], pthmd_all[ri], pth_prefix_all[ri], pth_allrec, md, scopatmplt, clip, methodrg, register_in_2d, bglenpx, max_shifts_prc, smlenpx_mcp, clipinterp, registration_template_group_id, cluster_backend, use_cluster, makeplots)

        if do_denoise:
          chanstr_primary, chanstr_secondary = zsep_todn(pth_read_all[ri], fn_prefix_all[ri], pth_denoising, md, pthmd_all[ri], denoise_volume, chan_dn, dnraw, clip) 
          denoise(pth_denoising, fn_prefix_all[ri], md['dims'], md['volrate'], denoise_slice_index, denoise_volume, num_epochs_denoise, carls_old_project_all[ri], chanstr_primary)
          if chanstr_secondary:
           denoise(pth_denoising, fn_prefix_all[ri], md['dims'], md['volrate'], denoise_slice_index, denoise_volume, num_epochs_denoise, carls_old_project_all[ri], chanstr_secondary)
            
        if do_stitch:
          stitchdn(pth_denoising, fn_prefix_all[ri], pth_read_all[ri], md, denoise_volume, epoch_choose_denoise, pthmd_all[ri]) 

        if do_remove:
          eng = matlab.engine.start_matlab()
          eng.addpath(eng.genpath(pth_scopa))
          mtlout = io.StringIO()
          mtlerr = io.StringIO()
          eng.scannoiserm(pth_read_all[ri], stopband_rsc, smlensec_rsc, stdout=mtlout, stderr=mtlerr, nargout=0)

        if do_extract or do_crop_only:
          extract(pth_prefix_all[ri], pth_read_all[ri], pth_optdf, pth_optroi, md, pthmd_all[ri], extract_in_2d, methodex, rgname, mmname, do_crop_only, makeplots, cluster_backend, use_cluster)

        if do_a2p:
          eng = matlab.engine.start_matlab()
          eng.addpath(eng.genpath(pth_scopa))
          mtlout = io.StringIO()
          mtlerr = io.StringIO()
          eng.a2p(pth_read_all[ri], stdout=mtlout, stderr=mtlerr, nargout=0)
            
          

print("\n\n\nEXITING pl.py") 
