def optrg(register_in_2d = True,  min_mov = 0, fnames = None, md = None):

    ### registration options ###

    pw_rigid = False #rigid or non, for tiny fly brains i'm guessing nonrigid is not necessary and invites artifact, so i always leave false, but i've not noticed a difference in tests with my data yet 
    nonneg_movie = True #true because i make it nonnegative before registration
    min_mov = min_mov

    niter_rig = 2 #default 1, number registration iterations (regardles of pw_rigid, or is3d); template is updated as bin_median of registered stack from each iteration 
    shifts_opencv = False #automatically false if is3D_mc==true, or if pw_rigid = True . . . so true only works for rigid 2d registration . . . true uses intercubic interp (faster but smoother), false uses fourier
    max_deviation_rigid = 3 #only relevant if pw_rigid==True, this is max amount patches can deviate from whole fov rigid shifts 
    upsample_factor_grid = 4 #default 4, use for merging patches if pw_rigid==True; not the same as upsample factor in register translation, whichy is just set to 10 by default, for subpixel shift
    # num_frames_split = 200 #for paralellization, within each split frames are processed one at a time, so this doens't matter i don't think

    if register_in_2d:
        is3D_mc = False #if not 3d, register each slice . . . 
        indices_mc = (slice(None), slice(None)) #if is3d is true for motion correction, will overwrite with nones and will lose indices_ex
        strides_mc = (24, 24) #ignored if pw_rigid==False, otherwise this is piecewise patch stride 
        overlaps_mc = (12, 12) #ignored if pw_rigid==False, otherwise this is piecewise patch overlap
        max_shifts_mc = (8, 8) #max allowed shifts (in patch if piecewise, or whole fov if not) 
        gsig_filt = None #(3,3)
    else:
        is3D_mc = True
        indices_mc = (slice(None), slice(None), slice(None)) #if is3d is true for motion correction, will overwrite with nones and will lose indices_ex
        strides_mc = (12, 12, 12) #ignored if pw_rigid==False, otherwise this is piecewise patch stride 
        overlaps_mc = (8, 8, 8)#ignored if pw_rigid==False, otherwise this is piecewise patch overlap
        max_shifts_mc = (4, 4, 4) #max allowed shifts (in patch if piecewise, or whole fov if not) 
        gsig_filt = None #(3,3,3)#(3,3,3) #(3,3,3)

    fr = md['volrate'] #0.6193  #9.8465 frame period so 1000 / (9.8465 *(113+51)) # approximate frame rate of data - CONFIRMED FPS
    if md['zfov']==0: #this occurs if it's a 2d stack (not volumetric); below the third element (hard coded 0.0) will be removed
        dxy = [md['xpix']/md['xfov'], md['ypix']/md['yfov'], 0.0 ] #pixels per micron
    else:
        dxy = [md['xpix']/md['xfov'], md['ypix']/md['yfov'], md['numslice']/md['zfov']] #pixels per micron

    opts_dict = {
                'strides': strides_mc,    # start a new patch for pw-rigid motion correction every x pixels
                'overlaps': overlaps_mc,   # overlap between pathes (size of patch strides+overlaps)
                'max_shifts': max_shifts_mc,   # maximum allowed rigid shifts (in pixels)
                'max_deviation_rigid': max_deviation_rigid,  # maximum shifts deviation allowed for patch with respect to rigid shifts
                'pw_rigid': pw_rigid,         # flag for performing non-rigid motion correction
                # 'num_frames_split': num_frames_split,
                'indices': indices_mc,  #for some reason indices_mc is causing error, maybe needs list for mc and tuple for extraction?
                'gSig_filt': gsig_filt,
                'is3D': is3D_mc,
                'nonneg_movie':nonneg_movie,
                'min_mov': min_mov,
                'shifts_opencv':shifts_opencv,
                'niter_rig':niter_rig,
                'upsample_factor_grid':upsample_factor_grid, 
                'fnames': fnames,
                'fr': fr,
                'dxy': dxy,
                }
    
    return opts_dict