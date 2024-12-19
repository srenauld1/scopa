

import argparse
from dictsort import dictsort


##THIS VERSION WAS USED IN defualt_params_batch.py still existed, allowing command line arguments to update defaults
## but now pipeline_init is either run interactively with all arguments specified in optdfpl 
## or it's run from pl.sh, in which case all arguments are either written to pars file, or passed as command line, but none need defaults to be invoked, so the command line parsing has been removed

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


def parse_command_line(folder_with_all_recordings_on_storage_and_compute_filesystems, pth_storage_prefix, 
                      do_copyfiles, fnind_fn_prefix, pth_parsfile, scopatmpdir, 
                      recdate, fly, trial, folder_substring, recording_index, file_matching_style,
                      registration_template_group_id, do_register, register_in_2d, bglenpx, smlenpx_mcp, max_shifts_prc, use_cluster,    
                      do_denoise, do_stitch, denoise_volume, denoise_slice_index, num_epochs_denoise, 
                      use_background_subtracted, use_denoised, epoch_choose_denoise, 
                      do_remove, smlensec_rsc, use_scannoise_removed, 
                      do_crop_only, do_extract, extract_in_2d, regionex, 
                      do_a2p, first_job):
    
    CLI=argparse.ArgumentParser()

    CLI.add_argument(
        "--pth_parsfile",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=str,
        default=[pth_parsfile],  # default if nothing is provided
    )
    CLI.add_argument(
        "--scopatmpdir",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=str,
        default=[scopatmpdir],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_copyfiles",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_copyfiles],  # default if nothing is provided
    )
    CLI.add_argument(
        "--fnind_fn_prefix",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=str,
        default=[fnind_fn_prefix],  # default if nothing is provided
    )
    CLI.add_argument(
        "--folder_with_all_recordings_on_storage_and_compute_filesystems",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=str,
        default=[folder_with_all_recordings_on_storage_and_compute_filesystems],  # default if nothing is provided
    )
    CLI.add_argument(
        "--pth_storage_prefix",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=str,
        default=[pth_storage_prefix],  # default if nothing is provided
    )
    CLI.add_argument(
        "--regionex",  # name on the CLI - drop the `--` for positional/required parameters
        nargs="*",  # 0 or more values expected => creates a list
        type=str,
        default=[regionex],  # default if nothing is provided
    )
    CLI.add_argument(
        "--bglenpx",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[bglenpx],  # default if nothing is provided
    )
    CLI.add_argument(
        "--registration_template_group_id",  # name on the CLI - drop the `--` for positional/required parameters
        nargs="*", 
        type=str,
        default=[registration_template_group_id],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_register",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_register],  # default if nothing is provided
    )
    CLI.add_argument(
        "--register_in_2d",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[register_in_2d],  # default if nothing is provided
    )
    CLI.add_argument(
        "--smlenpx_mcp",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=float,
        default=[smlenpx_mcp],  # default if nothing is provided
    )
    CLI.add_argument(
        "--max_shifts_prc",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=float,
        default=[max_shifts_prc],  # default if nothing is provided
    )
    CLI.add_argument(
        "--use_cluster",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[use_cluster],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_denoise",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_denoise],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_stitch",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_stitch],  # default if nothing is provided
    )
    CLI.add_argument(
        "--denoise_volume",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[denoise_volume],  # default if nothing is provided
    )
    CLI.add_argument(
        "--denoise_slice_index",  # name on the CLI - drop the `--` for positional/required parameters
        nargs="*", 
        type=str,
        default=[denoise_slice_index],  # default if nothing is provided
    )
    CLI.add_argument(
        "--num_epochs_denoise",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[num_epochs_denoise],  # default if nothing is provided
    )
    CLI.add_argument(
        "--epoch_choose_denoise",  # name on the CLI - drop the `--` for positional/required parameters
        nargs="*", 
        type=str,
        default=[epoch_choose_denoise],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_remove",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_remove],  # default if nothing is provided
    )
    CLI.add_argument(
        "--smlensec_rsc",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=float,
        default=[smlensec_rsc],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_crop_only",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_crop_only],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_extract",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_extract],  # default if nothing is provided
    )
    CLI.add_argument(
        "--extract_in_2d",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,  
        type=int,
        default=[extract_in_2d],  # default if nothing is provided
    )
    CLI.add_argument(
        "--use_background_subtracted",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,  
        type=int,
        default=[use_background_subtracted],  # default if nothing is provided
    )
    CLI.add_argument(
        "--use_denoised",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,  
        type=int,
        default=[use_denoised],  # default if nothing is provided
    )
    CLI.add_argument(
        "--use_scannoise_removed",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,  
        type=int,
        default=[use_scannoise_removed],  # default if nothing is provided
    )
    CLI.add_argument(
        "--recdate",  # name on the CLI - drop the `--` for positional/required parameters
        nargs="*", 
        type=str,
        default=[recdate],  # default if nothing is provided
    )
    CLI.add_argument(
        "--fly",  # name on the CLI - drop the `--` for positional/required parameters
        nargs="*", 
        type=str,
        default=[fly],  # default if nothing is provided
    )
    CLI.add_argument(
        "--trial",  # name on the CLI - drop the `--` for positional/required parameters
        nargs="*", 
        type=str,
        default=[trial],  # default if nothing is provided
    )
    CLI.add_argument(
        "--folder_substring",  # name on the CLI - drop the `--` for positional/required parameters
        nargs="*", 
        type=str,
        default=[folder_substring],  # default if nothing is provided
    )
    CLI.add_argument(
        "--recording_index",  # name on the CLI - drop the `--` for positional/required parameters
        nargs="*", 
        type=str,
        default=[recording_index],  # default if nothing is provided
    )
    CLI.add_argument(
        "--file_matching_style",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=str,
        default=[file_matching_style],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_a2p",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,  
        type=int,
        default=[do_a2p],  # default if nothing is provided
    )
    CLI.add_argument(
        "--first_job",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,  
        type=int,
        default=[first_job],  # default if nothing is provided
    )

    args = CLI.parse_args() #COMMAND LINE ARGUMENT PASSED, IT IS USED, OTHERWISE THE DEFAULT IS USED 

    pth_parsfile = args.pth_parsfile[0]

    if pth_parsfile: #additional option to read input from file written in bash script, should come after command line arguments 
        
        pars = parse_pars_file(pth_parsfile) #have to do it this way for exec to create a local variable 
        # args = pars.overwrite_args(args) #not working yet . . . attempts to automatically overwrite args with whatever is in pars_file, so they don't have to be manually defined (as below) 
        ##args.__dict__ = pars.__dict__.copy() #untested . . .  try this to overwrite new args, need to make them lowercase programmatically first, perhaps in the exec call above 

        #vars not written to pars are: the main do* args, and recording_index

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
        args.smlensec_rsc = pars.SMLENSEC_RSC
        args.extract_in_2d = pars.EXTRACT_IN_2D
        args.regionex = pars.REGIONEX


    ##make sure parsed arguments are either singletons, or lists (not lists of lists), and for some, convert to ints
    
    folder_with_all_recordings_on_storage_and_compute_filesystems =  args.folder_with_all_recordings_on_storage_and_compute_filesystems[0] 
    pth_storage_prefix = args.pth_storage_prefix[0] 
    do_copyfiles = int(args.do_copyfiles[0])
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
    if isinstance(args.recording_index[0], list):
        recording_index = args.recording_index[0] #keep as list
    else:
        recording_index = args.recording_index #keep as list
    if recording_index != ['all']:
        recording_index = [int(tmp) for tmp in recording_index] #convert to int if not 'all'

    file_matching_style = args.file_matching_style[0] 

    if isinstance(args.registration_template_group_id[0], list):
        registration_template_group_id = args.registration_template_group_id[0] #keep as list
    else:
        registration_template_group_id = args.registration_template_group_id #keep as list

    
    do_register = int(args.do_register[0])
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

    do_denoise = int(args.do_denoise[0])
    do_stitch = int(args.do_stitch[0])
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
    
    do_remove = int(args.do_remove[0])
    smlensec_rsc = float(args.smlensec_rsc[0])
    do_crop_only = int(args.do_crop_only[0])
    do_extract = int(args.do_extract[0])
    extract_in_2d = int(args.extract_in_2d[0])

    if isinstance(args.regionex[0], list):
        regionex = args.regionex[0] #keep as list
    else:
        regionex = args.regionex #keep as list

    do_a2p = int(args.do_a2p[0])
    first_job = int(args.first_job[0])

    print("\n\n\nPARSED THESE COMMAND LINE AND/OR PARAM FILE ARGUMENTS:")

    # options = {k: v for k, v in locals().items() if v is not None} #example turn locals into dict

    whitespaces_three = '   '
    loccop = locals().copy()
    loccop = dictsort(loccop)
    for k,v in loccop.items():
        if not k.startswith('_') and k!='loccop' and k!='CLI' and k!='args' and k!='pars' and k!='In' and k!='Out' and not hasattr(v, '__call__'):
            print(whitespaces_three, k, '=', v)

    return (folder_with_all_recordings_on_storage_and_compute_filesystems, pth_storage_prefix, 
                      do_copyfiles, fnind_fn_prefix, pth_parsfile, scopatmpdir, 
                      recdate, fly, trial, folder_substring, recording_index, file_matching_style,
                      registration_template_group_id, do_register, register_in_2d, bglenpx, smlenpx_mcp, max_shifts_prc, use_cluster,  
                      do_denoise, do_stitch, denoise_volume, denoise_slice_index, num_epochs_denoise, 
                      use_background_subtracted, use_denoised, epoch_choose_denoise, 
                      do_remove, smlensec_rsc, use_scannoise_removed, 
                      do_crop_only, do_extract, extract_in_2d, regionex, 
                      do_a2p, first_job)


