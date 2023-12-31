
import argparse


class parse_pars_file():
    
    def __init__(self, pars_filename):

        pieces = open(pars_filename, 'r').read().split('\0')

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


def parse_command_line(pars_filename, do_copyfiles, pth_storage, index_extraction_param_set, region_extraction, do_background_subtraction, do_register, do_planar_registration, len_window_smooth_t,
                       do_separate, do_denoise, denoise_volume, denoise_slice_index, num_epochs_denoise, epoch_choose_denoise, do_stitch, 
                       do_extract, do_planar_extraction, use_denoised, use_background_subtracted, recdate, fly, trial, folder_substrings, do_crop, recording_index, file_matching_style):
    
    CLI=argparse.ArgumentParser()

    CLI.add_argument(
        "--pars_filename",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=str,
        default=[pars_filename],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_copyfiles",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_copyfiles],  # default if nothing is provided
    )
    CLI.add_argument(
        "--pth_storage",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=str,
        default=[pth_storage],  # default if nothing is provided
    )
    CLI.add_argument(
        "--index_extraction_param_set",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,  # 0 or more values expected => creates a list
        type=str,
        default=[index_extraction_param_set],  # default if nothing is provided
    )
    CLI.add_argument(
        "--region_extraction",  # name on the CLI - drop the `--` for positional/required parameters
        nargs="*",  # 0 or more values expected => creates a list
        type=str,
        default=[region_extraction],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_background_subtraction",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_background_subtraction],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_register",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_register],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_planar_registration",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_planar_registration],  # default if nothing is provided
    )
    CLI.add_argument(
        "--len_window_smooth_t",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[len_window_smooth_t],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_separate",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_separate],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_denoise",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_denoise],  # default if nothing is provided
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
        nargs=1, 
        type=int,
        default=[epoch_choose_denoise],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_stitch",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_stitch],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_crop",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_crop],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_extract",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_extract],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_planar_extraction",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,  
        type=int,
        default=[do_planar_extraction],  # default if nothing is provided
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
        "--folder_substrings",  # name on the CLI - drop the `--` for positional/required parameters
        nargs="*", 
        type=str,
        default=[folder_substrings],  # default if nothing is provided
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

    args = CLI.parse_args()

    pars_filename = args.pars_filename[0]

    if pars_filename=='pars.txt': #additional option to read input from file written in bash script, should come after command line arguments 
        
        pars = parse_pars_file(pars_filename) #have to do it this way for exec to create a local variable 
        # args = pars.overwrite_args(args) #not working yet . . . attempts to automatically overwrite args with whatever is in pars_file, so they don't have to be manually defined (as below) 
        
        ##args.__dict__ = pars.__dict__.copy() #untested . . .  try this to overwrite new args, need to make them lowercase programmatically first, perhaps in the exec call above 

        args.pth_storage = pars.PTH_STORAGE
        args.recdate = pars.RECDATE
        args.fly = pars.FLY
        args.trial = pars.TRIAL
        args.folder_substrings = pars.FOLDER_SUBSTRINGS
        args.file_matching_style = pars.FILE_MATCHING_STYLE


    ##make sure parsed arguments are either singletons, or lists (not lists of lists), and for some, convert to ints
    
    pth_storage = args.pth_storage[0] 
    do_copyfiles = args.do_copyfiles[0]
    
    index_extraction_param_set = args.index_extraction_param_set[0] 
    if index_extraction_param_set != 'default':
        index_extraction_param_set = int(index_extraction_param_set) #convert to int if not 'default'

    if isinstance(args.region_extraction[0], list):
        region_extraction = args.region_extraction[0] #keep as list
    else:
        region_extraction = args.region_extraction #keep as list
        
    do_register = args.do_register[0]
    do_planar_registration = args.do_planar_registration[0]
    len_window_smooth_t = args.len_window_smooth_t[0]
    do_separate = args.do_separate[0]
    do_denoise = args.do_denoise[0]
    denoise_volume = args.denoise_volume[0]

    if isinstance(args.denoise_slice_index[0], list):
        denoise_slice_index = args.denoise_slice_index[0] #keep as list
    else:
        denoise_slice_index = args.denoise_slice_index #keep as list
    if denoise_slice_index != ['all']:
        denoise_slice_index = [int(ri) for ri in denoise_slice_index] #convert to int if not 'all'

    num_epochs_denoise = args.num_epochs_denoise[0]
    epoch_choose_denoise = args.epoch_choose_denoise[0]
    do_stitch = args.do_stitch[0]
    do_crop = args.do_crop[0]
    do_extract = args.do_extract[0]
    do_planar_extraction = args.do_planar_extraction[0]
    use_denoised = args.use_denoised[0]
    use_background_subtracted = args.use_background_subtracted[0]
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
    if isinstance(args.folder_substrings[0], list):
        folder_substrings = args.folder_substrings[0] #keep as list
    else:
        folder_substrings = args.folder_substrings #keep as list
    if isinstance(args.recording_index[0], list):
        recording_index = args.recording_index[0] #keep as list
    else:
        recording_index = args.recording_index #keep as list
    if recording_index != ['all']:
        recording_index = [int(ri) for ri in recording_index] #convert to int if not 'all'

    file_matching_style = args.file_matching_style[0] 

    print("\n\n\n parsed these command line and/or param file arguments")

    localscopy = locals().copy()
    for k,v in localscopy.items():
        if not k.startswith('_') and k!='localscopy' and k!='CLI' and k!='args' and k!='pars' and k!='In' and k!='Out' and not hasattr(v, '__call__'):
            print(k,'=',v)


    return (pars_filename, do_copyfiles, pth_storage, index_extraction_param_set, region_extraction, 
            do_background_subtraction, do_register, do_planar_registration, len_window_smooth_t, 
            do_separate, do_denoise, denoise_volume, denoise_slice_index, num_epochs_denoise, epoch_choose_denoise, 
            do_stitch, do_crop, do_extract, do_planar_extraction, use_denoised, use_background_subtracted, 
            recdate, fly, trial, folder_substrings, recording_index, file_matching_style)


