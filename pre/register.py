
import numpy as np
import os
from tifffile.tifffile import imwrite, imread

import caiman as cm
import caiman.source_extraction.cnmf as cnmf
from configs import configs
from helpers import tracefunc 
from z_stitch import stitch_registered_slices 
from registration_template import choose_registration_template
from subtract_background import subtract_background
from scipy.ndimage import gaussian_filter as smooth_movie
from im_montage import im_montage
from plot_gif import plot_gif


def register(pth_tif_read, pth_prefix, pth_allrec, md, registration_template_group_id, discard_channel, chan_primary_when_two, register_in_2d, halfwidth_window_bgsub, len_window_smooth_t_mcp_sec, register_presmoothed, cluster_backend, use_cluster, makeplots):
   
   # note md['dims'] does not include channels, since each channel is operated on separately through this part of the pipeline

    ########################## LOAD / PREP STACK ##########################

    print("\n\n\nENTERING REGISTRATION FUNCTION")

    if use_cluster:
        if 'dview' in locals(): cm.stop_server(dview=dview)
        cc, dview, n_processes = cm.cluster.setup_cluster(backend=cluster_backend, n_processes=None, single_thread=False)
    else:
        n_processes = 1 #set this in case you don't (or can't) setup cluster 
        dview = None #set this in case you don't (or can't) setup cluster
        
    stack = imread(pth_tif_read).astype('float32') ##  is float necessary?? (tz)yx, or if multiple channels, (tz)cyx; 
        
    if md['dims'][1]>1:
        stack_has_multiple_z_slices = 1
        zindall = np.arange(md['dims'][1])
    else:
        stack_has_multiple_z_slices = 0
        zindall = [0]
        if not register_in_2d:
            register_in_2d = 1
            print("stack does not have multiple slices but register_in_2d is set to false, changing register_in_2d to true now")

    stack, stack_secondary, two_channel_reg, chan_secondary, chanstr_primary, chanstr_secondary = separate_channels_when_two(stack, md, discard_channel, chan_primary_when_two, register_presmoothed)

    if halfwidth_window_bgsub:
        pth_tif_write = pth_prefix + chanstr_primary + '_bksb_cmrg_.tif' #match pattern in choose_files (make this more reliable)
    else:
        pth_tif_write = pth_prefix + chanstr_primary + '_cmrg_.tif'#match pattern in choose_files (make this more reliable)
    pth_tif_write_allchan = pth_tif_write.replace(chanstr_primary, '') #only used if two_channel_reg==1 (ie if there are two channels and discard_channel=None)

    pth_tif_write_tmp = pth_tif_write[:-4] + 'tmp_.tif'
    if two_channel_reg:
        pth_tif_write_secondary = pth_tif_write.replace(chanstr_primary, chanstr_secondary) #only used if two_channel_reg==1 (ie if there are two channels and discard_channel=None)
        pth_tif_write_secondary_tmp_prefix = pth_tif_write_secondary[:-4] + 'tmp'
    else:
        pth_tif_write_secondary = []  
        if register_presmoothed:
            pth_tif_write_secondary_tmp_prefix = pth_tif_write[:-4] + '_presmoothed_tmp'


    stack = stack_reshape_transpose_zero_type(stack, md['dims'], md['flyback'])
    if two_channel_reg:
        stack_secondary = stack_reshape_transpose_zero_type(stack_secondary, md['dims'], md['flyback'])

    if makeplots:
        #im_montage(stack[10,:,:,:], vmin=mnmv, vmax=np.max(stack))
        plot_gif(stack, pth_tif_read[:-4] + '.gif', indsz = slice(3,4,1), indst = slice(0, 100, 1))  #view stack before registration, can pass xyzt indices, otherwise will do all indices for each 
        if two_channel_reg:
            #im_montage(stack_secondary[10,:,:,:], vmin=mnmv, vmax=np.max(stack)) #view montage to check registration
            plot_gif(stack_secondary, pth_tif_read[:-4] + chanstr_secondary + '.gif', indsz = slice(3,4,1), indst = slice(0, 100, 1))  #view stack before registration, can pass xyzt indices, otherwise will do all indices for each 
   
   
    ########################## BACKGROUND SUBTRACTION ##########################

    if halfwidth_window_bgsub:
        stack = subtract_background(stack, halfwidth_window_bgsub, pth_prefix, makeplots, zindall)
        if two_channel_reg:
            stack_secondary = subtract_background(stack_secondary, halfwidth_window_bgsub, pth_prefix, makeplots, zindall)


    ########################## WRITE SECONDARY TMP STACK IF register_presmoothed ##########################

    if register_presmoothed: #write secondary stack (presmoothed movie in this case) to be registered to primary stack 
        msgstr = 'PRESMOOTHED STACK'
        pth_tif_write_secondary_tmp = write_secondary_tmp_stack(stack, pth_tif_write_secondary_tmp_prefix, register_in_2d, zindall, msgstr)

    ########################## TEMPORAL SMOOTHING ##########################

    if len_window_smooth_t_mcp_sec: 
        stack = smooth_stack(stack, len_window_smooth_t_mcp_sec, md['volrate'], md['dims'][0])
        if two_channel_reg:
            stack_secondary = smooth_stack(stack_secondary, len_window_smooth_t_mcp_sec, md['volrate'], md['dims'][0])

    ########################## WRITE SECONDARY TMP STACK IF two_channel_reg ##########################

    if two_channel_reg: #write secondary stack (secondary channel in this case) to be registered to primary stack (this after smoothing, in case secondary channel needs it)
        msgstr = 'STACK CHANNEL ' + str(chan_secondary)
        pth_tif_write_secondary_tmp = write_secondary_tmp_stack(stack_secondary, pth_tif_write_secondary_tmp_prefix, register_in_2d, zindall, msgstr)

    ########################## MAKE OR LOAD REGISTRATION TEMPLATE ##########################

    regtemplate = choose_registration_template(stack, md, registration_template_group_id, pth_allrec, pth_prefix, register_in_2d, stack_has_multiple_z_slices, makeplots) #if making a template, use stack rather than stack_secondary
        
    ########################## REGISTRATION (CAIMAN NORMCORRE) ##########################

    min_mov = np.min(stack).astype('float32') #do this here, not in loop below

    if register_in_2d: 
        sliceindz = zindall #each slice 
    else:
        sliceindz = [zindall] #all slices in one list (not planar)

    countz = 0
    for si in sliceindz: #for each slice (or all slices if extract_in_2d = false)

        mc = None #reset caiman motion correction object
        if register_in_2d and stack_has_multiple_z_slices: #for planar extraction take on z slice at a time
            stack_sub = stack[:,:,:,si]
            print("DOING PLANAR registration FOR SLICE " + str(si))
        else: # for 3d extraction keep all z slices (for now, until implement z ranges)
            stack_sub = stack #can't .copy() for some reason (but that's fine as long as you don't modify stack_sub)
            if stack_has_multiple_z_slices:
                print("DOING 3D REGISTRATION FOR ALL SLICES")
            else:
                print("DOING PLANAR REGISTRATION FOR THE ONLY SLICE IN THE STACK")

        if register_in_2d and stack_has_multiple_z_slices and regtemplate is not None:
            regtemplate_sub = regtemplate[:,:,si]
        else:
            regtemplate_sub = regtemplate

            
        imwrite(pth_tif_write_tmp, stack_sub.squeeze(), bigtiff=True, photometric='minisblack') #write as t x y z (z might be singleton for non-volumetric data, so squeeze)
    
        opts_dict, _, _ = configs(register_in_2d = register_in_2d, fnames = pth_tif_write_tmp, min_mov = min_mov, md = md) ## FOR SOME REASON CALLING configs OUTSIDE si LOOP CAUSES ALL LOOP ITERATIONS EXCEPT THE FIRST TO HAVE PROBLEMS (PRESUMABLY SOME PARAM IS CHANGED ON EACH LOOP) FOR NOW PLACE IT INSIDE LOOP TO RESET ALL CONFIGS SO EACH SLICE GETS THE SAME 
        opts = cnmf.params.CNMFParams(params_dict=opts_dict)

        mc = cm.motion_correction.MotionCorrect([pth_tif_write_tmp], dview=dview, **opts.get_group('motion'))
        mc.motion_correct(save_movie=True, template = regtemplate_sub)
        input_for_save_memmap_primary = mc.mmap_file #name this input_for_save_memmap caiman's save_memmap can take memmap file or ndarray as argument
        if two_channel_reg or register_presmoothed: #apply shifts learned from smoothed movie to the raw movie (if you don't want smoothed movie ultimately)
            tmp = mc.apply_shifts_movie(pth_tif_write_secondary_tmp[countz], save_memmap=False, order='F') #for some reason cannot save_memmap=True here, so must pass nd array to save_memmap below
            os.remove(pth_tif_write_secondary_tmp[countz])
            if two_channel_reg: #save the first registered stack, so rename input_for_save_memmap so it's not overwritten by the other stack channel (which is registered wth apply_shifts_movie, and which gets named input_for_save_memmap); if register_presmoothed, we discard the first registered stack (which is a smoothed stack)
                input_for_save_memmap_secondary = [tmp] #so must pass nd array to save_memmap below
            elif register_presmoothed: 
                input_for_save_memmap_primary = [tmp] #update name so presmoothed gets saved but not presmoothed 

        os.remove(pth_tif_write_tmp)        
        memmap2stackwrite(si, input_for_save_memmap_primary, pth_tif_write, register_in_2d, mc, dview)
        os.remove(mc.mmap_file[0]) #remove the mmap file in F order 
        if two_channel_reg:
            memmap2stackwrite(si, input_for_save_memmap_secondary, pth_tif_write_secondary, register_in_2d, mc, dview)

        if (register_in_2d and si==sliceindz[-1]) or not register_in_2d: #on final slice, if register_in_2d, or if 3d register
            stack = stitch_registered_slices(pth_tif_write, md['dims']) #output is all slices, txyz
            # write_registered_stack(stack, pth_tif_write)
            if makeplots:
                #im_montage(stack[10,:,:,:], vmin=mnmv, vmax=np.max(stack)) #view montage to check registration
                plot_gif(stack, pth_tif_write[:-4] + '.gif', indsz = slice(3, 4, 1), indst = slice(0, 100, 1))  #view gif to check registration, can pass xyzt indices, otherwise will do all indices for each 
            if two_channel_reg: #OVERWRITE STACK TO SAVE MEMORY SINCE WE'RE AT THE END, AND ONLY PLOTTING IS LEFT
                stack_secondary = stitch_registered_slices(pth_tif_write_secondary, md['dims']) #output is all slices, txyz
                # write_registered_stack(stack_secondary, pth_tif_write_secondary)
                stack_combined = np.zeros((stack.shape[0], stack.shape[1], 2, stack.shape[2], stack.shape[3]), dtype=stack.dtype)
                stack_combined[:,:,chan_primary_when_two-1,:,:] = stack
                stack_combined[:,:,chan_secondary-1,:,:] = stack_secondary
                write_registered_stack(stack_combined, pth_tif_write_allchan)
                if makeplots:
                    #im_montage(stack_secondary[10,:,:,:], vmin=mnmv, vmax=np.max(stack_secondary)) #view montage to check registration
                    plot_gif(stack_secondary, pth_tif_write_secondary[:-4] + '.gif', indsz = slice(3, 4, 1), indst = slice(0, 100, 1))  #view gif to check registration, can pass xyzt indices, otherwise will do all indices for each 

        countz = countz + 1



################################ HELPER FUNCTIONS ######################################################################################################
########################################################################################################################################################
########################################################################################################################################################
########################################################################################################################################################
########################################################################################################################################################
########################################################################################################################################################
########################################################################################################################################################
########################################################################################################################################################
########################################################################################################################################################

def stack_reshape_transpose_zero_type(stack, dims, flyback):

    stack = stack.reshape(dims[0], dims[1]+flyback, dims[2], dims[3])
    if flyback!=0:    
        stack = stack[:,:-flyback,:,:] #crop flyback frames
    stack = np.transpose(stack, (0, 3, 2, 1)) #put in order t x y z 
    mnmv = np.min(stack).astype('float32') 
    stack -= mnmv #make movie nonnegative then convert to uint16 (not sure this matters for caiman, but useful further ahead)
    stack = stack.astype('uint16')
    print("MIN BEFORE MOTION CORRECTION " + str(mnmv))
    
    return stack



def separate_channels_when_two(stack, md, discard_channel, chan_primary_when_two, register_presmoothed):
    
    two_channel_reg = 0
    stack_secondary = None
    chan_secondary = None
    chanstr_primary = 'chn1' #default 
    chanstr_secondary = ''
    if 'channelSave' in md: #older runs of do_register will not have this field in md, if you want it, delete metadatanew and rerun
        if not isinstance(md['channelSave'], int):
            if len(md['channelSave'])==2:
                if discard_channel is not None:
                    keepchan = np.setxor1d([1,2], discard_channel)
                    chanstr_primary = '_chn' + str(keepchan)
                    stack = stack[:,keepchan[0]-1,:,:].squeeze()
                    print("STACK HAS 2 CHANNELS, BUT discard_channel IS SET TO " + str(discard_channel) + ", SO DISCARDING CHANNEL " + str(discard_channel) + " AND KEEPING CHANNEL " + str(keepchan))
                else:
                    two_channel_reg = 1
                    chan_secondary = np.setxor1d([1,2], chan_primary_when_two)
                    chan_secondary = chan_secondary[0]
                    chanstr_primary = '_chn' + str(chan_primary_when_two)
                    chanstr_secondary = '_chn' + str(chan_secondary)
                    stack_secondary = stack[:,chan_secondary-1,:,:].squeeze()
                    stack = stack[:,chan_primary_when_two-1,:,:].squeeze()
                    print("STACK HAS 2 CHANNELS, WILL REGISTER CHANNEL " + str(chan_primary_when_two) + ", THEN WILL REGISTER CHANNEL " + str(chan_secondary) + " USING SHIFTS FROM CHANNEL " + str(chan_primary_when_two) )
            else:
                raise Exception("there is a channels problem")
        

    if two_channel_reg and register_presmoothed:
        raise Exception("two_channel_reg and register_presmoothed cannot both be true; since you have a 2-channel stack, you can set discard_channel to 1 or 2, or set register_presmoothed to 0")
            
    return stack, stack_secondary, two_channel_reg, chan_secondary, chanstr_primary, chanstr_secondary
    

def smooth_stack(stack, len_window_smooth_t_mcp_sec, volrate, length_t):
      

        print("TEMPORALLY SMOOTHING STACK BEFORE REGISTRATION")

        dimtmp_presmooth = stack.shape
        numsigma_smooth_prereg = 5.0 #truncate gaussian filter after this many stds
        dtmni = 1/volrate
        len_window_smooth_t_mcp_samp = len_window_smooth_t_mcp_sec / dtmni #smooth might require int, cant remember 
        sigma_smooth_prereg = (len_window_smooth_t_mcp_samp - 1) / numsigma_smooth_prereg / 2
        stack = smooth_movie(stack.reshape(length_t, -1), sigma=sigma_smooth_prereg, mode='reflect', truncate=numsigma_smooth_prereg, axes=0)
        stack = stack.reshape(dimtmp_presmooth)

        return stack


def write_secondary_tmp_stack(stack, pth_tif_write_secondary_tmp_prefix, register_in_2d, zindall, msgstr):

    if register_in_2d: #for planar extraction write one secondary stack z at a time
        pth_tif_write_secondary_tmp = ['']*len(zindall)
        for zind in zindall: #for every z slice 
            print("WRITING " + msgstr + " SLICE " + str(zind) + " FOR SECONDARY REGISTRATION AFTER PRIMARY REGISTRATION")
            pth_tif_write_secondary_tmp[zind] = pth_tif_write_secondary_tmp_prefix + '_' + str(zind) + '_.tif'
            imwrite(pth_tif_write_secondary_tmp[zind], stack[:,:,:,zind].squeeze(), bigtiff=True, photometric='minisblack') 
    else:  
        print("WRITING ALL " + msgstr + " SLICES FOR SECONDARY REGISTRATION AFTER PRIMARY REGISTRATION" )
        pth_tif_write_secondary_tmp = [pth_tif_write_secondary_tmp_prefix + '_all_.tif']
        imwrite(pth_tif_write_secondary_tmp[0], stack.squeeze(), bigtiff=True, photometric='minisblack') #write as t x y z (z might be singleton for non-volumetric data, so squeeze)

    return pth_tif_write_secondary_tmp    


def write_registered_stack(stack, pth_tif_write):

    mnmv = np.min(stack).astype('float32')
    stack -= mnmv #make nonnegative before converting to uint16
    if np.max(stack) > 65535:
        raise Exception("clipping will occur when converting to uint16")
    print("MIN AFTER REGISTRATION " + str(mnmv))
    stack = stack.astype('uint16')
    stack_shape = stack.shape
    print(stack_shape)
    if len(stack.shape)==3: #transpose into tzyx, collapse t and z (if z exists) 
        stack = np.transpose(stack, (0, 2, 1)).reshape(stack_shape[0], stack_shape[2], stack_shape[1])
    else:
        stack = np.transpose(stack, (0, 3, 2, 1)).reshape(stack_shape[0] * stack_shape[3], stack_shape[2], stack_shape[1])
    imwrite(pth_tif_write, stack, bigtiff=True, photometric='minisblack') #write the registered movie as tif (uint16) for use in matlab, and caiman extraction below


def memmap2stackwrite(si, input_for_save_memmap, pth_tif_write, register_in_2d, mc, dview):

        border_to_0 = 0 if mc.border_nan == 'copy' else mc.border_to_0 
        basename_memap = pth_tif_write.split('/')[-1][:-4]
        pth_mmap_reg = cm.save_memmap(input_for_save_memmap, base_name=basename_memap, order='C', border_to_0=border_to_0, dview=dview) # save in order C (motion_correct above has to save in order F)
        stack, dims_spatial_rg, dim_time_rg = cm.load_memmap(pth_mmap_reg) 
        os.remove(pth_mmap_reg) #remove the mmap file in C order 
        stack = np.reshape(stack.T, [dim_time_rg] + list(dims_spatial_rg), order='F') 

        if register_in_2d:
            pth_write_single = pth_tif_write[:-4] + str(si) + '_z_.tif'
            imwrite(pth_write_single, np.transpose(stack, (0, 2, 1)).reshape(dim_time_rg, dims_spatial_rg[1], dims_spatial_rg[0]), bigtiff=True, photometric='minisblack') #write the registered movie as tif (uint16) for use in matlab, and caiman extraction below
        else:
            for si2 in np.arange(stack.shape[3]): #write 3d registered, each slice, bc reading them back makes caiman output stack mutable, without doubling ram by simply copying stack (takes more storage but less ram, on O2 this is preferable), also writing one big float32 4d array takes forever on local, each slice does better 
                pth_write_single = pth_tif_write[:-4] + str(si2) + '_z_.tif'
                imwrite(pth_write_single, np.transpose(stack[:,:,:,si2], (0, 2, 1)).reshape(dim_time_rg, dims_spatial_rg[1], dims_spatial_rg[0]), bigtiff=True, photometric='minisblack') #write the registered movie as tif (uint16) for use in matlab, and caiman extraction below

