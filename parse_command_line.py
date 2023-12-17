
import argparse
from ast import literal_eval


def parse_command_line(do_copyfiles, superfolder_name_compute, superfolder_name_storage, index_extraction_param_set, region_extraction, do_background_subtraction, do_register, do_planar_registration, len_window_smooth_t,
                       do_denoise, denoise_volume, denoise_slice_index, num_epochs_denoise, epoch_choose_denoise, do_stitching_session, 
                       do_extract, do_planar_extraction, use_denoised, use_background_subtracted, recdates, fly, trial, do_cropping_session, recording_index):
    
    CLI=argparse.ArgumentParser()

    CLI.add_argument(
        "--do_copyfiles",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=str,
        default=[do_copyfiles],  # default if nothing is provided
    )
    CLI.add_argument(
        "--superfolder_name_compute",  # name on the CLI - drop the `--` for positional/required parameters
        nargs="*",  # 0 or more values expected => creates a list
        type=str,
        default=[superfolder_name_compute],  # default if nothing is provided
    )
    CLI.add_argument(
        "--superfolder_name_storage",  # name on the CLI - drop the `--` for positional/required parameters
        nargs="*",  # 0 or more values expected => creates a list
        type=str,
        default=[superfolder_name_storage],  # default if nothing is provided
    )
    CLI.add_argument(
        "--index_extraction_param_set",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
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
        "--do_stitching_session",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_stitching_session],  # default if nothing is provided
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
        "--recdates",  # name on the CLI - drop the `--` for positional/required parameters
        nargs="*", 
        type=str,
        default=[recdates],  # default if nothing is provided
    )
    CLI.add_argument(
        "--fly",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=str,
        default=[fly],  # default if nothing is provided
    )
    CLI.add_argument(
        "--trial",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=str,
        default=[trial],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_cropping_session",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_cropping_session],  # default if nothing is provided
    )
    CLI.add_argument(
        "--recording_index",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=str,
        default=[recording_index],  # default if nothing is provided
    )

    args = CLI.parse_args()

    print("parsed command line arguments for pipeline_init.py")
    print(args)

    do_copyfiles = args.do_copyfiles[0]
    if isinstance(args.superfolder_name_storage, list):
        superfolder_name_compute = args.superfolder_name_compute[0] #shouldn't be list 
    else:
        superfolder_name_compute = args.superfolder_name_compute #shouldn't be list 
    if isinstance(args.superfolder_name_storage, list):
        superfolder_name_storage = args.superfolder_name_storage[0] #shouldn't be list 
    else:
        superfolder_name_storage = args.superfolder_name_storage #shouldn't be list 
    if args.index_extraction_param_set[0] != 'default':
        index_extraction_param_set = int(args.index_extraction_param_set[0])
    if isinstance(args.region_extraction[0], list):
        region_extraction = args.region_extraction[0] #keep as list
    else:
        region_extraction = args.region_extraction #keep as list
    do_register = args.do_register[0]
    do_planar_registration = args.do_planar_registration[0]
    len_window_smooth_t = args.len_window_smooth_t[0]
    do_denoise = args.do_denoise[0]
    denoise_volume = args.denoise_volume[0]
    if isinstance(args.denoise_slice_index[0], list):
        denoise_slice_index = args.denoise_slice_index[0] #keep as list
    else:
        denoise_slice_index = args.denoise_slice_index #keep as list
    num_epochs_denoise = args.num_epochs_denoise[0]
    epoch_choose_denoise = args.epoch_choose_denoise[0]
    do_stitching_session = args.do_stitching_session[0]
    do_extract = args.do_extract[0]
    do_planar_extraction = args.do_planar_extraction[0]
    use_denoised = args.use_denoised[0]
    use_background_subtracted = args.use_background_subtracted[0]
    if isinstance(args.recdates[0], list):
        recdates = args.recdates[0] #keep as list
    else:
        recdates = args.recdates #keep as list
    fly = args.fly[0]
    trial = args.trial[0]
    do_cropping_session = args.do_cropping_session[0]
    if args.recording_index[0] != 'all':
        recording_index = int(args.recording_index[0])

    return (do_copyfiles, superfolder_name_compute, superfolder_name_storage, index_extraction_param_set, region_extraction, 
            do_background_subtraction, do_register, do_planar_registration, len_window_smooth_t, 
            do_denoise, denoise_volume, denoise_slice_index, num_epochs_denoise, epoch_choose_denoise, do_stitching_session, 
            do_extract, do_planar_extraction, use_denoised, use_background_subtracted, recdates, fly, trial, do_cropping_session, recording_index)


