
import numpy as np
import os
import json
from tifffile.tifffile import imwrite, imread
import scipy.io as sio
import caiman as cm
import caiman.source_extraction.cnmf as cnmf
from oreg import oreg
from helpers import tracefunc, stack_reshape_transpose_clip_zero_type 
from zstitch import stitchrg 
from registration_template import choose_registration_template
from stackchan import stackchan
from subtract_background import subtract_background
from stacksm import stacksm
from im_montage import im_montage
from plot_gif import plot_gif
from bidiphase import compute as bidiphase_compute
from bidiphase import shift as bidiphase_shift
from stackshape import stackshape


def register(pth_tif_read, pthmd, pth_prefix, pth_allrec, md, scopatmplt, clip, methodrg, register_in_2d, bglenpx, max_shifts_prc, smlenpx_mcp, clipinterp, registration_template_group_id, cluster_backend='ipyparallel', use_cluster=0, makeplots=0):

   # note md['dims'] does not include channels, since each channel is operated on separately through this part of the pipeline

    ########################## LOAD / PREP STACK ##########################

    print("\n\n\nENTERING register.py")

    if use_cluster:
        if 'dview' in locals(): cm.stop_server(dview=dview)
        cc, dview, n_processes = cm.cluster.setup_cluster(backend=cluster_backend, n_processes=None, single_thread=False)
    else:
        n_processes = 1 #set this in case you don't (or can't) setup cluster 
        dview = None #set this in case you don't (or can't) setup cluster
        

    stack = imread(pth_tif_read) #(tz)yx, or if multiple channels, (tz)cyx; use to include .astype('float32') but float is not actually necessary as far as i can tell, although caiman has it this way i think O2 resource savings are worth the loss in precision 
        
        
    if md['dims'][1]>1:
        stack_has_multiple_z_slices = 1
        indzall = np.arange(md['dims'][1])
    else:
        stack_has_multiple_z_slices = 0
        indzall = [0]
        if not register_in_2d:
            register_in_2d = 1
            print("stack does not have multiple slices but register_in_2d is set to false, changing register_in_2d to true now")


    md = check_aborted_stack(md, pthmd, stack, stack_has_multiple_z_slices)

    tzcyx, numchan = stackshape(stack, md)

    chanrm, chan_primary, methodrg = parse_methodrg(methodrg, numchan)
    
    stack, stack_secondary, two_channel_reg, chan_primary, chan_secondary, chanstr_primary, chanstr_secondary = stackchan(stack, md, pthmd, chanrm, chan_primary)

    if bglenpx:
        pth_tif_write = pth_prefix + chanstr_primary + '_bksb_cmrg_.tif' #match pattern in filefind (make this more reliable)
    else:
        pth_tif_write = pth_prefix + chanstr_primary + '_cmrg_.tif'#match pattern in filefind (make this more reliable)
    pth_tif_write_allchan = pth_tif_write.replace(chanstr_primary, '') #this is same as pth_tif_write if two_channel_reg==0

    pth_tif_write_tmp = pth_tif_write[:-4] + 'tmp_.tif'
    if two_channel_reg:
        print("SINCE STACK HAS 2 CHANNELS AND chan_primary IS SET TO " + chanstr_primary + ", WILL REGISTER CHANNEL " + chanstr_secondary + " USING SHIFTS FROM CHANNEL " + chanstr_primary )
        pth_tif_write_secondary = pth_tif_write.replace(chanstr_primary, chanstr_secondary) #only used if two_channel_reg==1 (ie if there are two channels and chanrm=None)
        pth_tif_write_secondary_tmp_prefix = pth_tif_write_secondary[:-4] + 'tmp'
    else:
        pth_tif_write_secondary = []  
    
    if np.any(smlenpx_mcp): 
        register_presmoothed = 1
        pth_tif_write_presmoothed_tmp_prefix = pth_tif_write[:-4] + 'presmoothed_tmp'
    else:
        register_presmoothed = 0
        pth_tif_write_presmoothed_tmp_prefix = []



    stack = cropflyback(stack, md['dims'], md['flyback'])

    bidiphase_frame_increment = 8 #use subset of frames because bidiphase_compute uses complex doubles, increasing size of array 8 times, also bidiphase should be constant throughout recording
    phoff = bidiphase_compute(stack[::bidiphase_frame_increment,...]) #compute bidirectional phase offset, can be zero 
    if phoff:
        bidiphase_shift(stack, phoff) #correct any bidirectional phase offset if nonzero
    stack = stack_reshape_transpose_clip_zero_type(stack, md['dims'], clip=clip)
    if two_channel_reg:
        stack_secondary = cropflyback(stack_secondary, md['dims'], md['flyback'])
        phoff = bidiphase_compute(stack_secondary[::bidiphase_frame_increment,...])
        if phoff:
            bidiphase_shift(stack_secondary, phoff)
        stack_secondary = stack_reshape_transpose_clip_zero_type(stack_secondary, md['dims'], clip=clip)
    

    stack_shape = stack.shape
    stack_shape_space = stack_shape[1:]

    if makeplots:
        #im_montage(stack[10,:,:,:], vmin=mnmv, vmax=np.max(stack))
        plot_gif(stack, pth_tif_read[:-4] + 'raw.gif', indsz = slice(4,5,1), indst = slice(0, 100, 1))  #view stack before registration, can pass xyzt indices, otherwise will do all indices for each 
        if two_channel_reg:
            #im_montage(stack_secondary[10,:,:,:], vmin=mnmv, vmax=np.max(stack)) #view montage to check registration
            plot_gif(stack_secondary, pth_tif_read[:-4] + chanstr_secondary + '.gif', indsz = slice(3,4,1), indst = slice(0, 100, 1))  #view stack before registration, can pass xyzt indices, otherwise will do all indices for each 
   
   
    ########################## BACKGROUND SUBTRACTION ##########################

    if bglenpx:
        stack = subtract_background(stack, bglenpx, pth_prefix, makeplots, indzall)
        if two_channel_reg:
            stack_secondary = subtract_background(stack_secondary, bglenpx, pth_prefix, makeplots, indzall)

    if clipinterp:
        limax = tuple(np.arange(1,np.ndim(stack)))
        immn = np.min(stack, axis=limax)
        immx = np.max(stack, axis=limax)
        immn2 = []
        immx2 = []
        if two_channel_reg:
            immn2 = np.min(stack_secondary, axis=limax)
            immx2 = np.max(stack_secondary, axis=limax)


    ########################## WRITE SECONDARY TMP STACK IF register_presmoothed ##########################

    if register_presmoothed:
        msgstr = 'PRESMOOTHED STACK'
        pth_tif_write_presmothed_tmp = write_supp_stack(stack, pth_tif_write_presmoothed_tmp_prefix, register_in_2d, indzall, msgstr)

    ########################## WRITE SECONDARY TMP STACK IF two_channel_reg ##########################

    if two_channel_reg: #write secondary stack (secondary channel in this case) to be registered to primary stack (this after smoothing, in case secondary channel needs it)
        msgstr = 'STACK CHANNEL ' + chanstr_secondary
        pth_tif_write_secondary_tmp = write_supp_stack(stack_secondary, pth_tif_write_secondary_tmp_prefix, register_in_2d, indzall, msgstr)

    ########################## SPATIAL SMOOTHING FOR BOOSTING SNR TO COMPUTE SHIFTS (BUT NOT TO KEEP IN REGISTERED STACK) ##########################

    if register_presmoothed:
        stack = stacksm(stack, smlenpx_mcp, md['volrate'], md['dims'][0])
        # if independent_channel_reg and register_presmoothed: 
        #     stack_secondary = stacksm(stack_secondary, smlenpx_mcp, md['volrate'], md['dims'][0])

    ########################## MAKE OR LOAD REGISTRATION TEMPLATE ##########################

    if scopatmplt:
        registration_template_group_id = [ pth_prefix.split('/')[-1] + '_' + pth_prefix.split('/')[-2] ]
    regtemplate = choose_registration_template(stack, md, registration_template_group_id, pth_allrec, pth_prefix, register_in_2d, max_shifts_prc, stack_shape_space, stack_has_multiple_z_slices, makeplots) #if making a template, use stack rather than stack_secondary
        
    ########################## REGISTRATION (CAIMAN NORMCORRE) ##########################

    min_mov = np.min(stack).astype('float32') #do this here, not in loop below

    if register_in_2d: 
        indz = indzall #each slice 
    else:
        indz = [indzall] #all slices in one list (not 2d)


    countz = 0
    for iz in indz: #for each slice (or all slices if register_in_2d = false)

        mc = None #reset caiman motion correction object
        if register_in_2d and stack_has_multiple_z_slices: #for 2d registration take on z slice at a time
            stack_sub = stack[:,:,:,iz]
            print("DOING 2d registration FOR SLICE " + str(iz))
        else: # for 3d registration keep all z slices (for now, until implement z ranges)
            stack_sub = stack #can't .copy() for some reason (but that's fine as long as you don't modify stack_sub, which we dont)
            if stack_has_multiple_z_slices:
                print("DOING 3D REGISTRATION FOR ALL SLICES")
            else:
                print("DOING 2d REGISTRATION FOR THE ONLY SLICE IN THE STACK")

        if register_in_2d and stack_has_multiple_z_slices and regtemplate is not None:
            regtemplate_sub = regtemplate[:,:,iz]
        else:
            regtemplate_sub = regtemplate

            
        imwrite(pth_tif_write_tmp, stack_sub.squeeze(), bigtiff=True, photometric='minisblack') #write as t x y z (z might be singleton for non-volumetric data, so squeeze)

        opts_dict = oreg(md, register_in_2d, min_mov, stack_shape_space, fnames = pth_tif_write_tmp, max_shifts_prc = max_shifts_prc) ## FOR SOME REASON CALLING oreg OUTSIDE iz LOOP CAUSES ALL LOOP ITERATIONS EXCEPT THE FIRST TO HAVE PROBLEMS (PRESUMABLY SOME PARAM IS CHANGED ON EACH LOOP) FOR NOW PLACE IT INSIDE LOOP TO RESET ALL OPTS SO EACH SLICE GETS THE SAME 
        opts = cnmf.params.CNMFParams(params_dict=opts_dict)

        mc = cm.motion_correction.MotionCorrect([pth_tif_write_tmp], dview=dview, **opts.get_group('motion'))
        mc.motion_correct(save_movie=True, template = regtemplate_sub)

        mdict = {}
        mdict['shifts'] = mc.shifts_rig
        mdict['templates_rig'] = mc.templates_rig
        mdict['max_shifts'] = mc.max_shifts
        pth_mat_rg = pth_tif_write[:-4] + 'reginfo.mat'
        sio.savemat(pth_mat_rg, mdict)


        os.remove(pth_tif_write_tmp)   
        if register_presmoothed: #apply shifts learned from smoothed movie to the raw movie (if you don't want smoothed movie ultimately)
            tmp = mc.apply_shifts_movie(pth_tif_write_presmothed_tmp[countz], save_memmap=False, order='F') #for some reason cannot save_memmap=True here, so must pass nd array to save_memmap below
            input_for_save_memmap_primary = [tmp] #update name so presmoothed gets saved but not presmoothed 
        else:
            input_for_save_memmap_primary = mc.mmap_file #name this input_for_save_memmap caiman's save_memmap can take memmap file or ndarray as argument
        memmap2stackwrite(iz, input_for_save_memmap_primary, pth_tif_write, register_in_2d, mc, dview)
        os.remove(mc.mmap_file[0]) #remove the mmap file in F order      
        
        if two_channel_reg:
            tmp = mc.apply_shifts_movie(pth_tif_write_secondary_tmp[countz], save_memmap=False, order='F') #for some reason cannot save_memmap=True here, so must pass nd array to save_memmap below
            os.remove(pth_tif_write_secondary_tmp[countz])
            input_for_save_memmap_secondary = [tmp] #so must pass nd array to save_memmap below
            memmap2stackwrite(iz, input_for_save_memmap_secondary, pth_tif_write_secondary, register_in_2d, mc, dview)


        if (register_in_2d and iz==indz[-1]) or not register_in_2d: #on final slice, if register_in_2d, or if 3d register

            stack_shape = stack.shape
            stack_dtype = 'uint16' #stack.dtype
            stack = None
            if two_channel_reg: #OVERWRITE STACK TO SAVE MEMORY SINCE WE'RE AT THE END, AND ONLY PLOTTING IS LEFT
                stack_allchan = np.zeros((stack_shape[0], stack_shape[1], stack_shape[2], stack_shape[3], 2), dtype=stack_dtype)
                stack_allchan[:,:,:,:,chan_primary-1] = stitchrg(pth_tif_write, md['dims']) #output is all slices, txyz
                stack_allchan[:,:,:,:,chan_secondary-1] = stitchrg(pth_tif_write_secondary, md['dims']) #output is all slices, txyz
                if makeplots:
                    plot_gif(stack_allchan[:,:,:,:,chan_primary-1].squeeze(), pth_tif_write[:-4] + '.gif', indsz = slice(3, 4, 1), indst = slice(0, 100, 1))  #view gif to check registration, can pass xyzt indices, otherwise will do all indices for each 
                    plot_gif(stack_allchan[:,:,:,:,chan_secondary-1].squeeze(), pth_tif_write_secondary[:-4] + '.gif', indsz = slice(3, 4, 1), indst = slice(0, 100, 1))  #view gif to check registration, can pass xyzt indices, otherwise will do all indices for each 
            else:
                stack_allchan = stitchrg(pth_tif_write_allchan, md['dims']) #here stack_allchan is one chan output is all slices, txyz
                if makeplots:
                    plot_gif(stack_allchan, pth_tif_write[:-4] + '.gif', indsz = slice(3, 4, 1), indst = slice(0, 100, 1))  #view gif to check registration, can pass xyzt indices, otherwise will do all indices for each 
                    #plot_gif(smooth_movie(stack_allchan, sigma=(1.2,1.2), axes=(1,2)), '/Users/wienecke/stacks/test.gif', indsz=slice(3,4,1), indst=slice(0,100,1))
            
            if clipinterp:
                stack_shape_final = stack_allchan.shape
                if two_channel_reg:
                    stack_allchan = stack_allchan.reshape(len(immn), -1, 2)
                else:
                    stack_allchan = stack_allchan.reshape(len(immn), -1, 1)
                for chn in np.arange(stack_allchan.shape[-1]):
                    for cnt, (frame,newmin,newmx,newmin2,newmx2) in enumerate(zip(stack_allchan[:,:,chn],immn,immx,immn2,immx2)):
                        if chn==0: #chn==0 is channel 1
                            frame[frame<newmin] = newmin
                            frame[frame>newmx] = newmx
                        elif chn==1: #chn==1 is channel 2
                            frame[frame<newmin2] = newmin2
                            frame[frame>newmx2] = newmx2
                        stack_allchan[cnt,:,chn] = frame

                stack_allchan = np.reshape(stack_allchan, stack_shape_final)

            write_registered_stack(stack_allchan, pth_tif_write_allchan)

        countz = countz + 1
    

    suffix = pth_tif_write_allchan.replace(pth_prefix, '')
    suffix = suffix.replace('_.tif', '')

    print("now that the stack has been written, updating metadata to include chanrm")
    md['chanrm' + suffix] = chanrm
    with open(pthmd, 'w') as file: 
        file.write(json.dumps(md, sort_keys=True, indent=4))



################################ HELPER FUNCTIONS FOR REGISTRATION ######################################################################################################
########################################################################################################################################################
########################################################################################################################################################
########################################################################################################################################################
########################################################################################################################################################
########################################################################################################################################################


def check_aborted_stack(md, pthmd, stack, stack_has_multiple_z_slices):
    if stack_has_multiple_z_slices==0 and md['dims'][0] != stack.shape[0]:
        print("stack cannot be reshaped into dimensions reported in tif header, but since it is not volumetric, assuming user aborted acquisition and updating metadata to match stack dimensions")
        md['numvol'] = stack.shape[0]
        md['dims'][0] = md['numvol']
    with open(pthmd, 'w') as file: 
        file.write(json.dumps(md, sort_keys=True, indent=4))
    return md


def parse_methodrg(methodrg, numchan):

    if isinstance(methodrg, list):
        methodrg = methodrg[0]
    
    if methodrg!='first' and methodrg!='second' and numchan==1:
        print("WARNING, methodrg is " + methodrg + ", WHICH REQUIRES TWO CHANNELS, BUT ONLY ONE CHANNEL IS PRESENT; CHANGING methodrg to '1' TO OPERATE ON THE ONLY CHANNEL PRESENT")
        methodrg = 'first'

    chan_primary = None #irrelevant unless methodrg denotes 2-channel registration 
    chanrm = None
    if methodrg=='first':
        if numchan==2:
            chanrm = 2 
    elif methodrg=='second':
        if numchan==2:
            chanrm = 1 
        else:
            raise Exception("methodrg second is for the registering the second of two saved channels, but only one channel was saved, so you should use methodrg first, even if the one saved channel is channel 2")
    elif methodrg=='both':
        raise Exception("methodrg both does not work yet")
    elif methodrg=='12':
        chan_primary = 1
    elif methodrg=='21':
        chan_primary = 2
    else:
        raise Exception('methodrg must be first, second, both, 12, or 21')

    return chanrm, chan_primary, methodrg


def cropflyback(stack, dims, flyback):
    stack = stack.reshape(dims[0], dims[1]+flyback, dims[2], dims[3])
    if flyback!=0:    
        stack = stack[:,:-flyback,:,:] #crop flyback frames
    stack = stack.reshape(dims[0]*dims[1], dims[2], dims[3])
    return stack



def write_supp_stack(stack, pth_tif_write_supp_prefix, register_in_2d, indzall, msgstr):

    if register_in_2d: #for 2d registration write one secondary stack z at a time
        pth_tif_write_supp_tmp = ['']*len(indzall)
        for zind in indzall: #for every z slice 
            print("WRITING " + msgstr + " SLICE " + str(zind) + " FOR SECONDARY REGISTRATION AFTER PRIMARY REGISTRATION")
            pth_tif_write_supp_tmp[zind] = pth_tif_write_supp_prefix + '_' + str(zind) + '_.tif'
            imwrite(pth_tif_write_supp_tmp[zind], stack[:,:,:,zind].squeeze(), bigtiff=True, photometric='minisblack') 
    else:  
        print("WRITING ALL " + msgstr + " SLICES FOR SECONDARY REGISTRATION AFTER PRIMARY REGISTRATION" )
        pth_tif_write_supp_tmp = [pth_tif_write_supp_prefix + '_all_.tif']
        imwrite(pth_tif_write_supp_tmp[0], stack.squeeze(), bigtiff=True, photometric='minisblack') #write as t x y z (z might be singleton for non-volumetric data, so squeeze)

    return pth_tif_write_supp_tmp    


def write_registered_stack(stack, pth_tif_write):

    print("WRITING FINAL REGISTERED STACK")

    stack_shape = stack.shape
    print(stack_shape)
    if len(stack.shape)==3: #transpose into tzyx, collapse t and z (if z exists) 
        stack = np.transpose(stack, (0, 2, 1)).reshape(stack_shape[0], stack_shape[2], stack_shape[1])
    elif len(stack.shape)==4:
        stack = np.transpose(stack, (0, 3, 2, 1)).reshape(stack_shape[0] * stack_shape[3], stack_shape[2], stack_shape[1])
    elif len(stack.shape)==5:
        stack = np.transpose(stack, (0, 3, 4, 2, 1)).reshape(stack_shape[0] * stack_shape[3] * stack_shape[4], stack_shape[2], stack_shape[1])
    imwrite(pth_tif_write, stack, bigtiff=True, photometric='minisblack') #write the registered movie as tif (uint16) for use in matlab, and caiman extraction below


def memmap2stackwrite(iz, input_for_save_memmap, pth_tif_write, register_in_2d, mc, dview):

        border_to_0 = 0 if mc.border_nan == 'copy' else mc.border_to_0 
        basename_memap = pth_tif_write.split('/')[-1][:-4]
        pth_mmap_reg = cm.save_memmap(input_for_save_memmap, base_name=basename_memap, order='C', border_to_0=border_to_0, dview=dview) # save in order C (motion_correct above has to save in order F)
        stack, dims_spatial_rg, dim_time_rg = cm.load_memmap(pth_mmap_reg) 
        os.remove(pth_mmap_reg) #remove the mmap file in C order 
        stack = np.reshape(stack.T, [dim_time_rg] + list(dims_spatial_rg), order='F') 

        if register_in_2d:
            pth_write_single = pth_tif_write[:-4] + str(iz) + '_z_.tif'
            imwrite(pth_write_single, np.transpose(stack, (0, 2, 1)).reshape(dim_time_rg, dims_spatial_rg[1], dims_spatial_rg[0]), bigtiff=True, photometric='minisblack') #write the registered movie as tif (uint16) for use in matlab, and caiman extraction below
        else:
            for si2 in np.arange(stack.shape[3]): #write 3d registered, each slice, bc reading them back makes caiman output stack mutable, without doubling ram by simply copying stack (takes more storage but less ram, on O2 this is preferable), also writing one big float32 4d array takes forever on local, each slice does better 
                pth_write_single = pth_tif_write[:-4] + str(si2) + '_z_.tif'
                imwrite(pth_write_single, np.transpose(stack[:,:,:,si2], (0, 2, 1)).reshape(dim_time_rg, dims_spatial_rg[1], dims_spatial_rg[0]), bigtiff=True, photometric='minisblack') #write the registered movie as tif (uint16) for use in matlab, and caiman extraction below

