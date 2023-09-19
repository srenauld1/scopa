
import argparse
from ast import literal_eval


def parse_command_line(index_extraction_param_set, region_extraction, do_background_subtraction, do_motion_correction, 
                       do_denoise, denoise_slice_index, do_extraction, do_planar_extraction, use_denoised, use_background_subtracted,
                       recdates, fly, trial, do_cropping_session, 
                       recording_index):
    
    CLI=argparse.ArgumentParser()

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
        "--do_motion_correction",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_motion_correction],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_denoise",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_denoise],  # default if nothing is provided
    )
    CLI.add_argument(
        "--denoise_slice_index",  # name on the CLI - drop the `--` for positional/required parameters
        nargs="*", 
        type=str,
        default=[denoise_slice_index],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_extraction",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=int,
        default=[do_extraction],  # default if nothing is provided
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
    
    if args.index_extraction_param_set[0] != 'default':
        index_extraction_param_set = int(args.index_extraction_param_set[0])
    if isinstance(args.region_extraction[0], list):
        region_extraction = args.region_extraction[0] #keep as list
    else:
        region_extraction = args.region_extraction #keep as list
    do_motion_correction = args.do_motion_correction[0]
    do_denoise = args.do_denoise[0]
    if isinstance(args.denoise_slice_index[0], list):
        denoise_slice_index = args.denoise_slice_index[0] #keep as list
    else:
        denoise_slice_index = args.denoise_slice_index #keep as list
    do_extraction = args.do_extraction[0]
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

    return (index_extraction_param_set, region_extraction, do_background_subtraction, 
            do_motion_correction, do_denoise, denoise_slice_index, do_extraction, 
            do_planar_extraction, use_denoised, use_background_subtracted, recdates, 
            fly, trial, do_cropping_session, recording_index)




def parse_command_line_denoise(pth_in, pth_denoising, pth_denoised, fn_prefix, dims, denoise_slice_index):
    
    CLI=argparse.ArgumentParser()

    CLI.add_argument(
        "--pth_in",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,
        type=str,
        default=pth_in,  # default if nothing is provided
    )
    CLI.add_argument(
        "--pth_denoising",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,
        type=str,
        default=pth_denoising,  # default if nothing is provided
    )
    CLI.add_argument(
        "--pth_denoised",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1, 
        type=str,
        default=pth_denoised,  # default if nothing is provided
    )
    CLI.add_argument(
        "--fn_prefix",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,
        type=str,
        default=fn_prefix,  # default if nothing is provided
    )    
    CLI.add_argument(
        "--dims",  # name on the CLI - drop the `--` for positional/required parameters
        nargs="*", 
        type=str,
        default=dims,  # default if nothing is provided
    )
    CLI.add_argument(
        "--denoise_slice_index",  # name on the CLI - drop the `--` for positional/required parameters
        nargs="*", 
        type=str,
        default=denoise_slice_index,  # default if nothing is provided
    )

    args = CLI.parse_args()

    print("parsed command line arguments for denoise.py")
    print(args)

    pth_in = args.pth_in[0]
    pth_denoising = args.pth_denoising[0]
    pth_denoised = args.pth_denoised[0]
    fn_prefix = args.fn_prefix[0]
    dims = list(map(int, args.dims))
    if denoise_slice_index != 'all':
        denoise_slice_index = list(map(int, args.denoise_slice_index))

    return pth_in, pth_denoising, pth_denoised, fn_prefix, dims, denoise_slice_index