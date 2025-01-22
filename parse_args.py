

import argparse
from dictsort import dictsort


class parse_pars_file():
    
    def __init__(self, pth_parsfile):

        pieces = open(pth_parsfile, 'r').read().split('\0')

        tmpdict = {}
        while len(pieces) >= 2:
            k = pieces.pop(0); v = pieces.pop(0)
            tmpdict[k] = v

        for key, value in tmpdict.items():
            tmplist = list(tmpdict[key].split(" "))
            exec('self.' + key + '=tmplist')
    
    # def overwrite_args(self, args): #this doesn't work yet

    #     for a in dir(self):
    #         print(a)
    #         if hasattr(args, a) and not a.startswith('__') and not callable(getattr(self, a)):
    #             print(a)
    #             exec('args.' + a + '=self.' + a)

    #     return args


def parse_command_line():
    
    ############## SET UP COMMAND LINE PARSER (ONLY A HANDFUL GET PASSED AS CL ARGS, THE REST ARE READ FROM PARSFILE) ##############

    CLI=argparse.ArgumentParser()

    CLI.add_argument(
        "--first_noncopy_job",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,  
        type=int,
        #default=[first_noncopy_job],  # default if nothing is provided
    )

    CLI.add_argument(
        "--do_copyfiles",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        #default=[do_copyfiles],  # default if nothing is provided
    )
    CLI.add_argument(
        "--jobnm",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=str,
        #default=[jobnm],  # default if nothing is provided
    )
    CLI.add_argument(
        "--jobind",  # name on the CLI - drop the `--` for positional/required parameters
        nargs="*", 
        type=str,
        #default=[jobind],  # default if nothing is provided
    )
    CLI.add_argument(
        "--pth_parsfile",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=str,
        #default=[pth_parsfile],  # default if nothing is provided
    )



    ############## READ PARAMETERS FROM COMMAND LINE ##############

    args = CLI.parse_args() #COMMAND LINE ARGUMENT PASSED, IT IS USED, OTHERWISE THE DEFAULT IS USED (BUT CURRENTLY THERE ARE NO DEFAULTS SPECIFIED ANYWHERE, THAT IS, EVERYTHING IS IN PL, PASSED EITHER AS COMMAND LINE ARGUMENT OR IN THE PARAMS FILE)

    first_noncopy_job = int(args.first_noncopy_job[0])
    do_copyfiles = int(args.do_copyfiles[0])
    
    if isinstance(args.jobnm[0], list):
        jobnm = args.jobnm[0] #keep as list
    else:
        jobnm = args.jobnm #keep as list

    if isinstance(args.jobind[0], list):
        jobind = args.jobind[0] #keep as list
    else:
        jobind = args.jobind #keep as list
    if jobind != ['all']:
        jobind = [int(tmp) for tmp in jobind] #convert to int if not 'all'
    
    if do_copyfiles!=0:
        jobind = ['all']
        print('FORCING jobind=all BECAUSE do_copyfiles IS NONZERO (SO ALL COPIES TO/FROM TRANSFER PARTITION WILL OCCUR IN A SINGLE JOB, SO SAVE RESOURCES)')

    pth_parsfile = args.pth_parsfile[0]


    ############## READ PARAMETERS FILE (parsfile) FOR ARGUMENTS ##############

    if pth_parsfile: #additional option to read input from file written in bash script, should come after command line arguments 
        
        pars = parse_pars_file(pth_parsfile) #have to do it this way for exec to create a local variable 
        # args = pars.overwrite_args(args) #not working yet . . . attempts to automatically overwrite args with whatever is in pars_file, so they don't have to be manually defined (as below) 
        ##args.__dict__ = pars.__dict__.copy() #untested . . .  try this to overwrite new args, need to make them lowercase programmatically first, perhaps in the exec call above 

        #vars not written to pars are: the main do* args, and jobind

        args.scopatmplt = pars.SCOPATMPLT
        args.clip = pars.CLIP
        args.methodrg = pars.METHODRG
        args.clipinterp = pars.CLIPINTERP
        args.chan_dn = pars.CHAN_DN
        args.methodex = pars.METHODEX

        args.folder_with_all_recordings_on_storage_and_compute_filesystems = pars.FOLDER_WITH_ALL_RECORDINGS_ON_STORAGE_AND_COMPUTE_FILESYSTEMS
        args.pth_storage_prefix = pars.PTH_STORAGE_PREFIX
        args.fnind_fn_prefix = pars.FNIND_FN_PREFIX
        args.scopatmpdir = pars.SCOPATMPDIR
        args.recdate = pars.RECDATE
        args.fly = pars.FLY
        args.trial = pars.TRIAL
        args.folder_substring = pars.FOLDER_SUBSTRING
        args.file_matching_style = pars.FILE_MATCHING_STYLE
        args.registration_template_group_id = pars.REGISTRATION_TEMPLATE_GROUP_ID
        args.register_in_2d = pars.REGISTER_IN_2D
        args.bglenpx = pars.BGLENPX
        args.smlenpx_mcp = pars.SMLENPX_MCP
        args.max_shifts_prc = pars.MAX_SHIFTS_PRC
        args.use_cluster = pars.USE_CLUSTER
        args.denoise_volume = pars.DENOISE_VOLUME
        args.denoise_slice_index = pars.DENOISE_SLICE_INDEX
        args.num_epochs_denoise = pars.NUM_EPOCHS_DENOISE
        args.use_background_subtracted = pars.USE_BACKGROUND_SUBTRACTED 
        args.use_denoised = pars.USE_DENOISED
        args.use_scannoise_removed = pars.USE_SCANNOISE_REMOVED
        args.epoch_choose_denoise = pars.EPOCH_CHOOSE_DENOISE
        args.stopband_rsc = pars.STOPBAND_RSC
        args.smlensec_rsc = pars.SMLENSEC_RSC
        args.extract_in_2d = pars.EXTRACT_IN_2D
        args.regionex = pars.REGIONEX


    ############## MAKE SURE THERE ARE NO LIST OF LISTS, AND CONVERT SOME TO INT ##############

    if isinstance(args.scopatmplt[0], list):
        scopatmplt = args.scopatmplt[0] #keep as list
    else:
        scopatmplt = args.scopatmplt #keep as list
    scopatmplt = int(scopatmplt[0])

    if isinstance(args.methodrg[0], list):
        methodrg = args.methodrg[0] #keep as list
    else:
        methodrg = args.methodrg #keep as list


    if isinstance(args.clip[0], list):
        clip = args.clip[0] #keep as list
    else:
        clip = args.clip #keep as list
    clip = [float(tmp) for tmp in clip] #convert to int if not 'all'

    if isinstance(args.stopband_rsc[0], list):
        stopband_rsc = args.stopband_rsc[0] #keep as list
    else:
        stopband_rsc = args.stopband_rsc #keep as list
    stopband_rsc = [int(tmp) for tmp in stopband_rsc] #convert to int if not 'all'


    if isinstance(args.clipinterp[0], list):
        clipinterp = args.clipinterp[0] #keep as list
    else:
        clipinterp = args.clipinterp #keep as list
    clipinterp = int(clipinterp[0])

    if isinstance(args.chan_dn[0], list):
        chan_dn = args.chan_dn[0] #keep as list
    else:
        chan_dn = args.chan_dn #keep as list
    if chan_dn != ['all']:
        chan_dn = int(chan_dn[0]) #convert to int if not 'all'


    if isinstance(args.methodex[0], list):
        methodex = args.methodex[0] #keep as list
    else:
        methodex = args.methodex #keep as list


    folder_with_all_recordings_on_storage_and_compute_filesystems =  args.folder_with_all_recordings_on_storage_and_compute_filesystems[0] 
    pth_storage_prefix = args.pth_storage_prefix[0] 
    fnind_fn_prefix = args.fnind_fn_prefix[0] 
    scopatmpdir = args.scopatmpdir[0] 
    
    if isinstance(args.recdate[0], list):
        recdate = args.recdate[0] #keep as list
    else:
        recdate = args.recdate #keep as list
    if isinstance(args.fly[0], list):
        fly = args.fly[0] #keep as list
    else:
        fly = args.fly #keep as list
    if isinstance(args.trial[0], list):
        trial = args.trial[0] #keep as list
    else:
        trial = args.trial #keep as list
    if isinstance(args.folder_substring[0], list):
        folder_substring = args.folder_substring[0] #keep as list
    else:
        folder_substring = args.folder_substring #keep as list

    file_matching_style = args.file_matching_style[0] 

    if isinstance(args.registration_template_group_id[0], list):
        registration_template_group_id = args.registration_template_group_id[0] #keep as list
    else:
        registration_template_group_id = args.registration_template_group_id #keep as list


    register_in_2d = int(args.register_in_2d[0])
    bglenpx = int(args.bglenpx[0])

    if isinstance(args.smlenpx_mcp[0], list):
        smlenpx_mcp = args.smlenpx_mcp[0] #keep as list
    else:
        smlenpx_mcp = args.smlenpx_mcp #keep as list
    smlenpx_mcp = [float(tmp) for tmp in smlenpx_mcp]

    if isinstance(args.max_shifts_prc[0], list):
        max_shifts_prc = args.max_shifts_prc[0] #keep as list
    else:
        max_shifts_prc = args.max_shifts_prc #keep as list
    max_shifts_prc = [float(tmp) for tmp in max_shifts_prc]

    use_cluster = int(args.use_cluster[0])

    denoise_volume = int(args.denoise_volume[0])

    if isinstance(args.denoise_slice_index[0], list):
        denoise_slice_index = args.denoise_slice_index[0] #keep as list
    else:
        denoise_slice_index = args.denoise_slice_index #keep as list
    if denoise_slice_index != ['all']:
        denoise_slice_index = [int(tmp) for tmp in denoise_slice_index] #convert to int if not 'all'

    num_epochs_denoise = int(args.num_epochs_denoise[0])

    use_background_subtracted = int(args.use_background_subtracted[0])
    use_denoised = int(args.use_denoised[0])
    use_scannoise_removed = int(args.use_scannoise_removed[0])

    if isinstance(args.epoch_choose_denoise[0], list):
        epoch_choose_denoise = args.epoch_choose_denoise[0] #keep as list
    else:
        epoch_choose_denoise = args.epoch_choose_denoise #keep as list
    epoch_choose_denoise = [int(tmp) for tmp in epoch_choose_denoise] #make sure int
    
    smlensec_rsc = float(args.smlensec_rsc[0])
    extract_in_2d = int(args.extract_in_2d[0])

    if isinstance(args.regionex[0], list):
        regionex = args.regionex[0] #keep as list
    else:
        regionex = args.regionex #keep as list


    ############## SET THE DO OPTIONS BASED ON COMMAND LINE ARGUMENT jobnm ##############

    do_autoallocate = int(jobnm==['alo'])
    do_register = int(jobnm==['mcp'])
    do_denoise = int(jobnm==['dnp'])
    do_stitch = int(jobnm==['stc'])
    do_extract = int(jobnm==['exp'])
    do_remove = int(jobnm==['rsc'])
    do_a2p = int(jobnm==['a2p'])

    ############## PRINT ALL THE ARGUMENTS ##############

    print("\n\n\nPARSED THESE COMMAND LINE AND/OR PARAM FILE ARGUMENTS:")

    whitespaces_three = '   '
    loccop = locals().copy()
    loccop = dictsort(loccop)
    for k,v in loccop.items():
        if not k.startswith('_') and k!='loccop' and k!='CLI' and k!='args' and k!='pars' and k!='In' and k!='Out' and not hasattr(v, '__call__'):
            print(whitespaces_three, k, '=', v)

    return (folder_with_all_recordings_on_storage_and_compute_filesystems, pth_storage_prefix, 
                      do_copyfiles, do_autoallocate, fnind_fn_prefix, pth_parsfile, scopatmpdir, 
                      recdate, fly, trial, folder_substring, jobind, file_matching_style,
                      registration_template_group_id, do_register, scopatmplt, clip, methodrg, clipinterp, register_in_2d, bglenpx, smlenpx_mcp, max_shifts_prc, use_cluster,  
                      do_denoise, do_stitch, chan_dn, denoise_volume, denoise_slice_index, num_epochs_denoise, 
                      use_background_subtracted, use_denoised, epoch_choose_denoise, 
                      do_remove, stopband_rsc, smlensec_rsc, use_scannoise_removed, 
                      do_extract, methodex, extract_in_2d, regionex, 
                      do_a2p, first_noncopy_job)


