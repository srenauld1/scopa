def zsep_todn_carls_old_project(pth_tif_read, fn_prefix, pth_denoising, md, denoise_volume):

    # prepare files for denoising by writing each z slice to different tif and putting in separate folders if denoise_volume = 0 
    # if using denoise_volume = 1, saves all separate tifs into one folder 
    # we do this cpu-intensive part outside denoise.py, which is gpu-intensive, since requesting lots of gpu and cpu will delay job start

    chanstr_primary = ''
    chanstr_secondary = ''
    
    print("\n\n\npreparing carl's old data for deepcad denoising, if you're not carl there is a problem")

    dims = md['dims']
    
    stack = imread(pth_tif_read)
    stack = stack.reshape(dims)
    stack = np.transpose(stack, (0, 2, 3, 1)) #put in order t y x z (not t x y z)
    if stack.dtype!='uint16':
        raise Exception("dtype should be uint16 (arbitrary choice for this pipeline)")
    zind_all_dn = np.arange(dims[1])

    for zii in zind_all_dn: #deepcad wants 3d data, so organize slices into separate tif files, and put in one folder (if denoise_volume=1, ie train on all slices) or separate folders (if denoise_volume=0, ie train on z subset)

        stacknew = stack[:,:,:,zii]
        Lt, Ly, Lx = stacknew.shape
        denoise_input_dtype = stacknew.dtype
        if stacknew.shape != (dims[0], dims[2], dims[3]):
            raise Exception("dims changed")

        if denoise_volume:
            pretend_z = str(int(fn_prefix.split('_')[2]) - 1) #make it zero indexed
            pretend_trial = '1' # pretend they all come from same trial
            dnfolder = fn_prefix.split('_')[0] + '_' + fn_prefix.split('_')[1] + '_' + pretend_trial + '_all' #for these non-volumetric grad recordings, if do_volume == 1, rename all trials "1", and each trial a different z slice
            tifname = fn_prefix.split('_')[0] + '_' + fn_prefix.split('_')[1] + '_' + pretend_trial + '_' + pretend_z + '_' + str(Lt) + '_' + str(Ly)  + '_' + str(Lx) + '_' + str(denoise_input_dtype) + '_.tif'
        else: #if not denoise_volume, just keep it the way it is (all trials have only z slice 0)
            actual_z = '0'
            dnfolder = fn_prefix + '_' + actual_z
            tifname = fn_prefix + '_' + actual_z + str(Lt) + '_' + str(Ly)  + '_' + str(Lx) + '_' + str(denoise_input_dtype) + '_.tif'

        print(tifname)
        pth_trainset = pth_denoising + dnfolder #dir containing all tif files for training
        pth_tif_write = pth_trainset + '/' + tifname
        
        # for old project cannot remove folder because it saves from separate runs of register        
        # if os.path.exists(pth_trainset) and (zii==0 or denoise_volume==0): #if you're on the first zii (regardless of denoise_volume value), or for all zii if denoise_volume==0
        #     shutil.rmtree(pth_trainset) #REMOVE any existing training folder before training, to ensure models don't get mixed (until "resume training" functionality is written)
        
        if not os.path.exists(pth_trainset): #don't make this "else" connected to "if" above because you have to evaluate it
            os.mkdir(pth_trainset)
        imwrite(pth_tif_write, stacknew, bigtiff=True, photometric='minisblack') #put the tif in the folder deepcad looks to for training data

    return chanstr_primary, chanstr_secondary


def stitchdn_carls_old_project(pth_denoising, fn_prefix, pth_tif_read, md, denoise_volume, epoch_choose_denoise):

  #stitch together denoised slices (tyx) into original size (tzyx, with singleton z)

    pth_tif_write = pth_tif_read[:-4] + 'd_.tif'
    
    if os.path.isfile(pth_tif_write):
    
        print("\n\n\nWARNING, SKIPPING stitch BECAUSE pth_tif_write ALREADY EXISTS - DELETE IT TO CREATE A NEW ONE")
    
    else:

        print("\n\n\nwriting denoised tifs for carls old project, if you're not carl there's a problem")

        dims_pre_denoise = md['dims']

        goal_trial = int(fn_prefix.split('_')[2])
        actual_z_size = 1

        if denoise_volume == 1:
            pretend_trial = '1' # pretend they all come from same trial
            dnfolder = fn_prefix.split('_')[0] + '_' + fn_prefix.split('_')[1] + '_' + pretend_trial + '_all/' #for these non-volumetric grad recordings, if do_volume == 1, rename all trials "1", and each trial a different z slice
            pth_trainset_all = natsorted(glob.glob(pth_denoising + '/' + dnfolder))

        else:

            pth_trainset_all = natsorted(glob.glob(os.path.join(pth_denoising, fn_prefix + '_*/')))
            fldr_exclude = fn_prefix.split('_')[0] + '_' + fn_prefix.split('_')[1] + '_' + pretend_trial + '_al*/' 
            pth_trainset_all = list(set(pth_trainset_all) - set(natsorted(glob.glob(fldr_exclude)))) #exclude the "all" folders when denoise_volume==1

        countz = 0
        for pth_trainset in pth_trainset_all:

            
            fldr_chex = natsorted(glob.glob(os.path.join(pth_trainset, 'DataFolderIs_*')))
            for fcxi,fcx in enumerate(fldr_chex):
                if fcxi!=len(fldr_chex)-1:
                    print("deleting this denoise test folder from old run")
                    print(fcx)
                    shutil.rmtree(fcx)


            fldr_outtiff_all = natsorted(glob.glob(os.path.join(pth_trainset, 'DataFolderIs_*', 'E_*'))) #for all epochs that were used for denoising, organize tif files into single folder in 'denoised' folder
            for fldr_outtiff in fldr_outtiff_all:
                if fnmatch.fnmatch(fldr_outtiff.split('/')[-1], 'E_' + "{:02d}".format(epoch_choose_denoise) + '_Iter_*'):
                    pth_denoised_singles = natsorted(glob.glob(os.path.join(fldr_outtiff, '*output.tif')))

                    stack = np.zeros((dims_pre_denoise[0], dims_pre_denoise[2], dims_pre_denoise[3], actual_z_size), dtype='float32') #t y x z
                    print(dims_pre_denoise[1])
                    for fni,f in enumerate(pth_denoised_singles): #loop over each denoised z slice and reassemble into array matching shape of original 4d volume
                        if denoise_volume == 1:
                            trial = int(f.split('/')[-1].split('_')[3]) + 1 #filename z position is actual trial if denoise_volume was==1, add one bc they were made zero index, but original trial is one indexed
                        else:
                            trial = int(f.split('/')[-1].split('_')[2]) #filename trial is in nortmal trial position

                        if trial == goal_trial:
                            countz = countz + 1
                            print(f)
                            sliceind = 0 #always zero for these non-volumetric old recordings 
                            stacknew = imread(f)
                            if stacknew.dtype!='uint16':
                                print("warning, converting type from " + str(stacknew.dtype))
                                if np.min(stacknew)<0 or np.max(stacknew) > 65535:
                                    raise Exception("denoising have operated on uint16 for this pipeline, or adjust it")
                                stacknew = stacknew.astype('uint16')
                            print(stacknew.dtype)
                            print(sliceind)
                            stack[:,:,:,sliceind] = stacknew

                            mnmv = np.min(stack).astype('float32')
                            stack -= mnmv #make nonnegative before writing to uint16
                            print("MIN AFTER DENOISING " + str(mnmv))
                                
                            stack = stack.astype('uint16')
                            
                            stack = np.transpose(stack, (0, 3, 1, 2)) #tzyx
                            print(stack.shape)
                            stack = stack.reshape(dims_pre_denoise[0] * actual_z_size, dims_pre_denoise[2], dims_pre_denoise[3]) #(tz)yx
                            print(stack.shape)
                            imwrite(pth_tif_write, stack.squeeze(), bigtiff=True, photometric='minisblack') #write the registered movie as tif for use in matlab, and caiman extraction below


                    if countz != dims_pre_denoise[1]:
                        raise Exception("more or less than one slice present")

