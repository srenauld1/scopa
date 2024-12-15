
import numpy as np
import os
import re
import fnmatch
import time
import glob
from pathlib import Path

from tifffile.tifffile import imwrite, imread
import caiman as cm
import caiman.source_extraction.cnmf as cnmf

from optrg import optrg
from im_montage import im_montage
from plot_gif import plot_gif


def choose_registration_template(stack, md, registration_template_group_id_all, pth_allrec, pth_prefix, register_in_2d, max_shifts_prc, stack_shape_space, stack_has_multiple_z_slices, makeplots):

    # make or load registration template; sleep until it's available, if necessary (error after waiting 5 min)

    if not isinstance(registration_template_group_id_all, list):
        registration_template_group_id_all = [registration_template_group_id_all]

    # make sure there are no overlaps in matches to registration_template_group_id

    if not registration_template_group_id_all:
        registration_template_group_id_all = ['dummystringwillnotmatchanythingunlessyouareamaster']
    pat_usetemplate_all = []
    for registration_template_group_id in registration_template_group_id_all:
        pat_usetemplate_tmp = re.sub("[\[].*?[\]]", "*", registration_template_group_id)
        pat_usetemplate_all.append('*' + '_'.join(pat_usetemplate_tmp.split('_')[4:]) + '*/' + '_'.join(pat_usetemplate_tmp.split('_')[0:3]))
    for ppi, pat_usetemplate in enumerate(pat_usetemplate_all):
        pat_usetemplate_all_tmp = pat_usetemplate_all.copy()
        pat_usetemplate_all_tmp.pop(ppi)
        for putat in pat_usetemplate_all_tmp:
            if fnmatch.fnmatch(pat_usetemplate, putat):
                print(pat_usetemplate)
                print(putat)     
                raise Exception ("ERROR, YOU HAVE SPECIFIED registration_template_group_id WITH OVERLAPPING MATCHES (THIS EXCEPTION NEEDS TO BE MOVED TO CXP, BEFORE JOB INITIATION)")



    # determine whether this is a make-and-use-template or use-but-don't-make-template or don't-use-template registration job
    pat_usetemplate = 'anotherdummystringwillnotmatchanythingunlessyouareamaster'
    for registration_template_group_id in registration_template_group_id_all:
        pat_usetemplate_tmp = re.sub("[\[].*?[\]]", "*", registration_template_group_id)
        pat_usetemplate_tmp = '*' + '_'.join(pat_usetemplate_tmp.split('_')[4:]) + '*/' + '_'.join(pat_usetemplate_tmp.split('_')[0:3])
        if fnmatch.fnmatch(pth_prefix, pat_usetemplate_tmp):
            pat_usetemplate = pat_usetemplate_tmp
            pat_maketemplate = re.sub("[\[\]]", "", registration_template_group_id)
            pat_maketemplate_fldrsubstr = '_'.join(pat_maketemplate.split('_')[4:])
            pat_maketemplate_fn = '_'.join(pat_maketemplate.split('_')[0:3])
            pat_maketemplate = '*' + pat_maketemplate_fldrsubstr + '*/' + pat_maketemplate_fn
            pat_maketemplate_for_glob = '**/*' + pat_maketemplate_fldrsubstr + '*/**/' + pat_maketemplate_fn
            fnsuffix_regtemplate = "_regtemplate_.tif"
    

    if fnmatch.fnmatch(pth_prefix, pat_usetemplate): #if this recording is meant to be registered to template 
        
        if fnmatch.fnmatch(pth_prefix, pat_maketemplate): #make template if this recording is meant to be the template and it hasn't already been made 
            
            pth_regtemplate = pth_prefix + fnsuffix_regtemplate
            if os.path.isfile(pth_regtemplate):
                regtemplate = imread(pth_regtemplate).astype('float32')
            else:
                minmovtmp = np.min(stack).astype('float32')
                opts_dict = optrg(md, register_in_2d, minmovtmp, stack_shape_space, max_shifts_prc = max_shifts_prc) ## FOR SOME REASON CALLING optrg OUTSIDE iz LOOP CAUSES ALL LOOP ITERATIONS EXCEPT THE FIRST TO HAVE PROBLEMS (PRESUMABLY SOME PARAM IS CHANGED ON EACH LOOP) FOR NOW PLACE IT INSIDE LOOP TO RESET ALL OPTS SO EACH SLICE GETS THE SAME 
                opts = cnmf.params.CNMFParams(params_dict=opts_dict)
                regtemplate = make_registration_template(stack, md['volrate'], stack_has_multiple_z_slices, register_in_2d, pth_regtemplate, opts.motion['max_shifts'], opts.motion['indices'])
        
        else: #load template if this recording is not meant to be the template, or it is and the template has already been made  
        
            pat_regtemplate_parent = pth_allrec + pat_maketemplate_for_glob + '*tif'
            pth_regtemplate_parent_tifs = glob.glob(pat_regtemplate_parent, recursive=True) #first find the path of dir the template should be in, there may be many results, so choose one  
            seccount = 0
            while not pth_regtemplate_parent_tifs: #sleep until a tif in the template's dir appears (since this run may be in parallel with the one that makes the template)
                pth_regtemplate_parent_tifs = glob.glob(pat_regtemplate_parent, recursive=True) #first find the path of dir the template should be in, there may be many results, so choose one  
                print("sleeping 10 sec while waiting for template parent folder to be created; pattern for folder is: \n" + pat_regtemplate_parent)
                time.sleep(10)
                seccount = seccount + 10 
                if seccount>300:
                    raise Exception ("\n\n\nERROR, TEMPLATE PARENT FOLDER SHOULD HAVE APPEARED BY NOW, THERE MAY BE AN ERROR IN THE JOB CREATING IT")


            pp = []
            for each_found_tif in pth_regtemplate_parent_tifs:
                pp.append(Path(each_found_tif).parts[:-1]) #split path
            if not all(x == pp[0] for x in pp): #make sure if multiple results they all point different tifs in the same dir 
                raise Exception ("\n\n\nERROR, MULTIPLE POSSIBLE LOCATIONS FOR REGISTRATION TEMPLATE, REGISTRATION_TEMPLATE_GROUP_ID IS NOT SPECIFIC ENOUGH")
            pth_regtemplate_parent = '/'.join(pp[0]) + '/' #path to folder that contains or soon will contain template (index 0 to ensure it exists)
            if pp[0][0]=='/':
                pth_regtemplate_parent = pth_regtemplate_parent[1:]
            pth_regtemplate = pth_regtemplate_parent + pat_maketemplate_fn + fnsuffix_regtemplate #this is the full path to the template 
            
            
            seccount = 0
            while not os.path.exists(pth_regtemplate): #sleep until the template appears (since this run may be in parallel with the one that makes the template)
                print("sleeping 10 sec while waiting for template to be created; template filename is: \n" + pth_regtemplate)
                time.sleep(10) 
                seccount = seccount + 10 
                if seccount>300:
                    raise Exception ("\n\n\nERROR, TEMPLATE SHOULD HAVE APPEARED BY NOW, THERE MAY BE AN ERROR IN THE JOB CREATING IT")
            if os.path.isfile(pth_regtemplate): #just to be sure it's a real file 
                regtemplate = imread(pth_regtemplate).astype('float32')
            else:
                raise ValueError("%s isn't a file!" % pth_regtemplate)
        
        if makeplots:
            im_montage(regtemplate, vmin=np.min(regtemplate), vmax=np.max(regtemplate))
            filename_gif = pth_prefix + '_regtemplate_couldBeFromOtherRecording.gif'
            plot_gif(regtemplate, filename_gif) 

        print("\n\n\nUSING REGISTRATION TEMPLATE, TEMPLATE FILE IS: \n" + pth_regtemplate + "\n\n\n")


        if stack_has_multiple_z_slices:     
            if not np.array_equal(regtemplate.shape, md['dims'][1:]):
                raise Exception ("\n\n\nERROR, REGTEMPLATE SIZE DOES NOT MATCH SIZE OF RECORDING IT IS BEING USED FOR ")
            regtemplate = np.transpose(regtemplate, (2, 1, 0))
        else:
            if not np.array_equal(regtemplate.shape, md['dims'][2:]):
                raise Exception ("\n\n\nERROR, REGTEMPLATE SIZE DOES NOT MATCH SIZE OF RECORDING IT IS BEING USED FOR ")
            regtemplate = np.transpose(regtemplate, (1, 0))
    

    else:
        regtemplate = None
        print("\n\n\nNOT USING REGISTRATION REGTEMPLATE\n\n\n")


    return regtemplate



def make_registration_template(stack, volrate, stack_has_multiple_z_slices, register_in_2d, pth_regtemplate, max_shifts, indices=(slice(None), slice(None)), subidx=slice(None, None, 1), gSig_filt=None):

    # takes subset of frames across entire stack, take mean over small windows of that subset, then take median
    # by default in 4d if stack is 4d, in 3d if stack is 3d
    # later template is used by slice if registration is in 2d, or by volume if not  
    # note caiman template is 'movie' while this is 'array' . . . doesn't seem to matter
    
    if volrate<4:
        raise Exception("your volume rate is under 4 Hz, consider adjusting windowlen_sec_mean and/or num_seconds_template_if_not_using_caiman_default_template")
    
    register_regtemplate = 0 #WILSONLAB, CFRW, 240218, caiman default is register_2d_template=1; SWITCH OFF TEMPLATE REGISTER for 2d, IT CAN MAKE A BAD TEMPLATE FOR A NOISY MOVIE; there is no option to register 3d template in caiman yet
    use_caiman_default_template_frames = 0 #WILSONLAB, CFRW, 240218, caiman defualt is use_caiman_default_template_frames=1; 1 to use caiman's original, which is 10 equidistant frames in 2d template, 50 equidistant in 3d template; make 0 to make template from first num_template_frames frames
    num_seconds_template_if_not_using_caiman_default_template = 7
    start_frame_template_if_not_using_caiman_default_template_frames = int(np.floor(stack.shape[0]/2)) # was 0, switched to middle frame #first frame of template if use_caiman_default_template_frames is fals
    windowlen_sec_mean = 0.75

    num_frames_template_if_not_using_caiman_default_template_frames = int(num_seconds_template_if_not_using_caiman_default_template*volrate) #if use_caiman_default_template_frames is false, how many initial frames of stack to use to make template
    windowlen_mean = int(windowlen_sec_mean*volrate) #must be int, >=1, if greater than T (num template frames), window=T; average every windowlen_mean frames of template, then take median of result, and that is template (2d or 3d); median is taken over resulting num windows, num windows is int(T // windowlen_mean)

    Ts = stack.shape[0] # Ts = np.arange(T)[subidx].shape[0]
         
    if use_caiman_default_template_frames:
        step = Ts // 10 if stack_has_multiple_z_slices else Ts // 50 #this is caiman's default 
        time_slicer = slice(subidx.start, subidx.stop, step + 1)
    else:
        if subidx.start is not None or subidx.stop is not None:
            raise Exception("you are using use_caiman_default_template_frames=0 but have also passed t indices; do one or the other")
        time_slicer = slice(0+start_frame_template_if_not_using_caiman_default_template_frames, num_frames_template_if_not_using_caiman_default_template_frames+start_frame_template_if_not_using_caiman_default_template_frames, 1) #first num_frames_template_if_not_using_caiman_default_template_frames frames


    if register_in_2d or not stack_has_multiple_z_slices: #indices to take subset of FOV, set in optrg (default does not use these)
        if stack_has_multiple_z_slices:
            stack = stack[time_slicer, indices[0], indices[1], :]
        else:
            stack = stack[time_slicer, indices[0], indices[1]].squeeze()
    else:
        stack = stack[time_slicer, indices[0], indices[1], indices[2]]


    stack = stack.astype('float32') #convert to float after subsampling

    if gSig_filt is not None:
        stack = cm.movie(np.array([cm.motion_correction.high_pass_filter_space(m_, gSig_filt) for m_ in stack]))
    
    if stack_has_multiple_z_slices: 
        regtemplate = cm.motion_correction.bin_median_3d(stack, window=windowlen_mean) # motion_correct_3d has not been implemented in 'movies' yet - instead initialize to just median image
        regtemplate = np.transpose(regtemplate, (2, 1, 0))
    else:
        if register_regtemplate:
            regtemplate = cm.motion_correction.bin_median(stack.motion_correct(max_shifts[1], max_shifts[0], regtemplate=None)[0])
        else:
            regtemplate = cm.motion_correction.bin_median(stack, window=windowlen_mean)
        regtemplate = np.transpose(regtemplate, (1, 0))


    print("created registration regtemplate, writing to: " + pth_regtemplate)
    imwrite(pth_regtemplate, regtemplate, bigtiff=True, photometric='minisblack') #write as tif


    return regtemplate
