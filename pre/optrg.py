def optrg(md, register_in_2d, min_mov, fnames = None):

    ### registration options ###

    ## carl wienecke made some changes to caiman registration that only affect rigid registration because drosophila brain motion seems rigid (is he wrong?)
    # scopa doens't use caiman param 'indices' to motion correct a subset of the FOV (it is automatically set to None in cnmf.params)

    pw_rigid = False #rigid or non, for tiny fly brains i'm guessing nonrigid is not necessary and invites artifact, so i always leave false, but i've not noticed a difference in tests with my data yet 
    nonneg_movie = True #true because i make it nonnegative before registration

    niter_rig = 2 #default 1, number registration iterations (regardles of pw_rigid, or is3d); template is updated as bin_median of registered stack from each iteration 
    shifts_opencv = False #automatically false if is3D==true, or if pw_rigid = True . . . so true only works for rigid 2d registration . . . true uses intercubic interp (faster but smoother), false uses fourier
    max_deviation_rigid = 3 #only relevant if pw_rigid==True, this is max amount patches can deviate from whole fov rigid shifts 
    upsample_factor_grid = 4 #default 4, use for merging patches if pw_rigid==True; not the same as upsample factor in register translation, whichy is just set to 10 by default, for subpixel shift
    # num_frames_split = 200 #for paralellization, within each split frames are processed one at a time, so this doens't matter i don't think

    if register_in_2d:
        is3D = False #if not 3d, register each slice . . . 
        strides = (24, 24) #ignored if pw_rigid==False, otherwise this is piecewise patch stride 
        overlaps = (12, 12) #ignored if pw_rigid==False, otherwise this is piecewise patch overlap
        max_shifts = (8, 8) #max allowed shifts (in patch if piecewise, or whole fov if not) 
        gSig_filt = None #(3,3)
    else:
        is3D = True
        strides = (12, 12, 12) #ignored if pw_rigid==False, otherwise this is piecewise patch stride 
        overlaps = (8, 8, 8)#ignored if pw_rigid==False, otherwise this is piecewise patch overlap
        max_shifts = (4, 4, 4) #max allowed shifts (in patch if piecewise, or whole fov if not) 
        gSig_filt = None #(3,3,3)#(3,3,3) #(3,3,3)

    fr = md['volrate'] #0.6193  #9.8465 frame period so 1000 / (9.8465 *(113+51)) # approximate frame rate of data - CONFIRMED FPS
    if md['zfov']==0: #this occurs if it's a 2d stack (not volumetric); below the third element (hard coded 0.0) will be removed
        dxy = [md['xpix']/md['xfov'], md['ypix']/md['yfov'], 0.0 ] #pixels per micron
    else:
        dxy = [md['xpix']/md['xfov'], md['ypix']/md['yfov'], md['numslice']/md['zfov']] #pixels per micron

    opts_dict = {
                'strides': strides,    # start a new patch for pw-rigid motion correction every x pixels
                'overlaps': overlaps,   # overlap between pathes (size of patch strides+overlaps)
                'max_shifts': max_shifts,   # maximum allowed rigid shifts (in pixels)
                'max_deviation_rigid': max_deviation_rigid,  # maximum shifts deviation allowed for patch with respect to rigid shifts
                'pw_rigid': pw_rigid,         # flag for performing non-rigid motion correction
                # 'num_frames_split': num_frames_split,
                'gSig_filt': gSig_filt,
                'is3D': is3D,
                'nonneg_movie': nonneg_movie,
                'min_mov': min_mov,
                'shifts_opencv': shifts_opencv,
                'niter_rig': niter_rig,
                'upsample_factor_grid': upsample_factor_grid, 
                'fnames': fnames,
                'fr': fr,
                'dxy': dxy,
                }
    
    return opts_dict