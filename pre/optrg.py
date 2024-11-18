import numpy as np

def optrg(md, register_in_2d, min_mov, stack_shape_space, max_shifts_prc = None, fnames = None):

    ### REGISTRATION OPTIONS ###

    # output dict opt holds all caiman motion_correction options defined in motion_correction init
    # user can modify all of them in top section (except these four options: 
    #   num_frames_split (appears to be overridden by num_splits_els and num_splits_rig, which are set with num_splits_time below)
    #   num_splits_to_process_els (caiman says do not modify)
    #   num_splits_to_process_rig (caiman says do not modify)
    #   indices (scopa doens't use caiman param 'indices' to motion correct a subset of the FOV (it is automatically set to None in cnmf.params)

    # carl wienecke made some changes to caiman registration that only affect rigid registration; he didn't bother with nonrigid because drosophila brain motion seems predominantly rigid (is he wrong?)
    # since 3d registration is most appropriate for cube voxels (or close) xy resolution must generally decrease to maintain acceptable volume rate, which means some of these options with pixel units should be different in 2d than 3d (besides just omitting the 3rd (z) element for 2d); for example, max_shifts 4 may seem small in a 2d brain that is yxz size (128,256,10), but not in a 3d brain that is yxz size (24,64,16) (both with similar volume rates)
    # options below are organized by function

    ### USER CAN MODIFY OPTIONS IN THIS SECTION ###

    # a few options that should probably never change
    pw_rigid = False #false applies rigid motion correction, true applies nonrigid motion correction; for tiny fly brains i'm guessing nonrigid is not necessary and invites artifact, so i always leave false, but i've not noticed a difference in tests with my data yet 
    use_highpass_filter = False #this invokes gSig_filt (makes it not None); caiman says this is for 1p data (data with large background fluctuations); so this should be False in general
    nonneg_movie = True #true because scopa makes the stack nonnegative before registration; putting it up top to make that clear
    use_cuda = False # flag for using a GPU; for now this is always false, maybe determine if gpu exists in future; registration is not slow enough for me to care though

    # some options that are good to modify 
    niter_rig = 1 #default 1; number registration iterations (regardles of pw_rigid, or is3d); template is updated as bin_median of registered stack from each iteration 
    shifts_opencv = False #automatically false if is3D==true, or if pw_rigid = True . . . so true only works for rigid 2d registration . . . true uses intercubic interp (faster but smoother), false uses fourier; keeping this false means it will always be applied as specified
    border_nan = 'copy' #(True, False, 'copy', 'min'); default is true; Specifies how to deal with borders (where imaginary comes into frame after applying shifts) true uses nan, false uses 0, 'min' uses min value along first shift dimension, 'copy' copies nearest value along first shift dimension
    
    numsec_batch = 20
    numsamp_batch = numsec_batch*md['volrate']
    
    num_splits_time = int(md['numvol']/numsamp_batch) #default is 14 (for rigid and nonrigid); below, num_splits_time is applied to both splits_els (nonrigid) and splits_rig (rigid); num_splits_time is for paralellization, number of frames for each parallel batch; within each split frames are processed one at a time; this is not important unless you think your registration is taking too long
    
    if register_in_2d:
        is3D = False #if not 3d, register each slice . . . 
        gSig_filt = None #unit pixels eg (3,3); high pass filter sigma; used for 1p data where background is flutuating a lot; in general (always?) None for 2p
        if max_shifts_prc is None: #if user made max_shifts_prc empty, use these defaults
            max_shifts = (8, 8) #unit pixels; max possible shifts in xy (in patch if piecewise, or whole fov if not); shifts are computed using a subregion of fov with outermost max_shifts removed (for template and image); this way, in case the fov drifts, the correlation (used to compute shifts) uses a constant region of image (as long as brain doesn't drift more than max_shifts); if your image drifts a lot, max_shifts has to be large, which means a small region of fov is getting correlated with template, which makes it harder to get correct shifts, especially if snr is low; so set this as small as possible to accommodate drift (the extent to which minimizing max_shifts matters depends on snr, assuming it is large enough to accommodate drift)
        else:
            max_shifts = [int(np.round(stack_shape_space[ind]*val/100)) for ind,val in enumerate(tuple(max_shifts_prc[:2]))]
            print("\nuser specified nonempty value of " + str(max_shifts_prc) + " for max_shifts_prc; \nusing the first two (xy) values of max_shifts_prc to set max_shifts to: " + str(max_shifts) + "\n3rd value, z, is ignored because register_in_2d is true; \nif your fov drifts more than this many pixels in xy, set max_shifts_prc to a larger number; \nset it just large enough to capture drift, but not too large because that removes signal in the correlation")
    else:  
        is3D = True #if 3d, register whole volume at once
        gSig_filt = None #unit pixels; eg (3,3,3); high pass filter sigma; used for 1p data where background is flutuating a lot; in general (always?) None for 2p
        if max_shifts_prc is None: #if user made max_shifts_prc empty, use these defaults
            max_shifts = (4, 4, 4) #unit pixels; max possible shifts in xyz (in patch if piecewise, or whole fov if not); shifts are computed using a subregion of fov with outermost max_shifts removed (for template and image); this way, in case the fov drifts, the correlation (used to compute shifts) uses a constant region of image (as long as brain doesn't drift more than max_shifts); if your image drifts a lot, max_shifts has to be large, which means a small region of fov is getting correlated with template, which makes it harder to get correct shifts, especially if snr is low; so set this as small as possible to accommodate drift (the extent to which minimizing max_shifts matters depends on snr, assuming it is large enough to accommodate drift)
        else:
            max_shifts = [int(np.round(stack_shape_space[ind]*val/100)) for ind,val in enumerate(tuple(max_shifts_prc))]
            print("\nuser specified nonempty value of " + str(max_shifts_prc) + " for max_shifts_prc; \nusing all 3 (xyz) values of max_shifts_prc to set max_shifts to: " + str(max_shifts) + "\nif your fov drifts more than this many pixels in xy, set max_shifts_prc to a larger number; \nset it just large enough to capture drift, but not too large because that removes signal in the correlation")

        if max_shifts[2]==0:
            if stack_shape_space[2]<4:
                raise Exception("max z shifts for stack with fewer than 4 slices is 1; do you really want this?")
            else:
                print("\changing z max_shifts for 3d registration from 0 to 1")
                max_shifts[2]=1


    #a few options that are only relevant for nonrigid registration (if pw_rigid=True), which may not ever be necessary for fly brains (??)
    max_deviation_rigid = 3 #only relevant if pw_rigid==True, this is max amount patches can deviate from whole fov rigid shifts 
    upsample_factor_grid = 4 #only relevant if pw_rigid==True, default 4, use for merging patches if pw_rigid==True; not the same as upsample factor in register translation, whichy is just set to 10 by default, for subpixel shift
    if register_in_2d:
        strides = (24, 24) #unit pixels; ignored if pw_rigid==False, otherwise this is piecewise patch stride (ie start a new patch for pw-rigid motion correction every stride pixels)
        overlaps = (12, 12) #unit pixels; ignored if pw_rigid==False, otherwise this is piecewise patch overlap (ie  overlap between patches, ie size of patch is strides+overlaps)
    else:  #since 3d registration is most appropriate for cube voxels (or close) xy resolution must generally decrease to maintain acceptable volume rate, which means some of these options with pixel units should be different in 2d than 3d (besides just omitting the 3rd (z) element for 2d); for example, max_shifts 4 may seem small in a 2d brain that is yxz size (128,256,10), but not in a 3d brain that is yxz size (24,64,16) (both with similar volume rates)
        strides = (12, 12, 12) #unit pixels; ignored if pw_rigid==False, otherwise this is piecewise patch stride (ie start a new patch for pw-rigid motion correction every stride pixels) 
        overlaps = (8, 8, 8) #unit pixels; ignored if pw_rigid==False, otherwise this is piecewise patch overlap (ie  overlap between patches, ie size of patch is strides+overlaps)


    #an option that is only relevant if you want to apply highpass filter to images, which caiman does not recommend for 2p data  
    if use_highpass_filter:
        if register_in_2d:
            gSig_filt = (3,3) # pixel unit; high pass filter sigma; used for 1p data where background is flutuating a lot; in general (always?) None for 2p
        else:  #since 3d registration is most appropriate for cube voxels (or close) xy resolution must generally decrease to maintain acceptable volume rate, which means some of these options with pixel units should be different in 2d than 3d (besides just omitting the 3rd (z) element for 2d); for example, max_shifts 4 may seem small in a 2d brain that is yxz size (128,256,10), but not in a 3d brain that is yxz size (24,64,16) (both with similar volume rates)
            gSig_filt = (2,2,2) # pixel unit; high pass filter sigma; used for 1p data where background is flutuating a lot; in general (always?) None for 2p
    else:
        gSig_filt = None


    ## DERIVE A COUPLE DATA OPTIONS FROM METADATA (THESE DON'T APEAR TO GET USED)

    fr = md['volrate'] #0.6193  #9.8465 frame period so 1000 / (9.8465 *(113+51)) # approximate frame rate of data - CONFIRMED FPS
    if md['zfov']==0: #this occurs if it's a 2d stack (not volumetric); below the third element (hard coded 0.0) will be removed
        dxy = [md['xpix']/md['xfov'], md['ypix']/md['yfov'], 0.0 ] #pixels per micron
    else:
        dxy = [md['xpix']/md['xfov'], md['ypix']/md['yfov'], md['numslice']/md['zfov']] #pixels per micron
    

    ## CHECK OPTIONS FOR PROBLEMS ##
    if not nonneg_movie:
        raise Exception("scopa makes stack nonnegative by default, so nonneg_movie should always be true; in general though i don't think this is very important")
    # if not register_in_2d:
    #     if np.ptp(dxy)>np.min(dxy):
    #         raise Exception("you are trying to do 3d registration on a stack with at least one voxel width that is at least double the smallest dimension's voxel width (most likely, z width is greater than x and y); consider 2d registration instead; but if you want to proceed with 3d registration, comment this exception and run again")
    if pw_rigid==True:
        raise Exception("you are trying to run non-rigid registration with pw_rigid=True; the options in scopa have not been optimized for nonrigid registration; it may work well, but it is not well tested")
    if (is3D or pw_rigid) and shifts_opencv:
        raise Exception("shifts_opencv is True, but so is is3D or pw_rigid; make is3D and pw_rigid false to use shifts_opencv true; caiman automatically changes shifts_opencv for you, but this exception is meant to make it clear what settings are actually being used; so if you don't like this exception, you can remove it and nothing will change")

    ##### PUT IN DICT; CAIMAN NOTES ON EACH OPTION ARE INCLUDED  

    opt = {
        'border_nan': border_nan,               # flag for allowing NaN in the boundaries
        'gSig_filt': gSig_filt,                  # size of kernel for high pass spatial filtering in 1p data
        'is3D': is3D,                      # flag for 3D recordings for motion correction
        'max_deviation_rigid': max_deviation_rigid,           # maximum deviation between rigid and non-rigid
        'max_shifts': max_shifts,               # maximum shifts per dimension (in pixels)
        'min_mov': min_mov,                    # minimum value of movie
        'niter_rig': niter_rig,                     # number of iterations rigid motion correction
        'nonneg_movie': nonneg_movie,               # flag for producing a non-negative movie
        'overlaps': overlaps,               # overlap between patches in pw-rigid motion correction
        'pw_rigid': pw_rigid,                  # flag for performing pw-rigid motion correction
        'shifts_opencv': shifts_opencv,              # flag for applying shifts using cubic interpolation (otherwise FFT)
        'strides': strides,                # how often to start a new patch in pw-rigid registration
        'upsample_factor_grid': upsample_factor_grid,          # motion field upsampling factor during FFT shifts
        'splits_els': num_splits_time,                   # number of splits across time for pw-rigid registration
        'splits_rig': num_splits_time,                   # number of splits across time for rigid registration
        'use_cuda': use_cuda,                  # flag for using a GPU
        'fr': fr,                # imaging rate in frames per second
        'dxy': dxy,          # spatial resolution of FOV in pixels per um
        ##OPTIONS BELOW ARE NOT SET IN OPTRG ABOVE, HERE THEY GET CAIMAN DEFAULT VALUES; THEY ARE INCLUDED FOR CLARITY
        'num_frames_split': 80,             # THIS APPEARS TO NOT BE USED; split across time every x frames
        'num_splits_to_process_els': None,  # DO NOT MODIFY
        'num_splits_to_process_rig': None,  # DO NOT MODIFY
        'indices': (slice(None), slice(None))  # part of FOV to be corrected
        }

    return opt