
import argparse


def parse_command_line(index, region_extraction, do_motion_correction, 
                       do_denoise, do_extraction, do_planar_extraction, 
                       recdates, fly, trial, do_cropping_session, 
                       array_index):
    

    print("in parse")


    CLI=argparse.ArgumentParser()

    CLI.add_argument(
        "--index",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,  # 0 or more values expected => creates a list
        type=int,
        default=index,  # default if nothing is provided
    )
    CLI.add_argument(
        "--region_extraction",  # name on the CLI - drop the `--` for positional/required parameters
        nargs="*",  # 0 or more values expected => creates a list
        type=str,
        default=[region_extraction],  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_motion_correction",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,  # 0 or more values expected => creates a list
        type=int,
        default=do_motion_correction,  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_denoise",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,  # 0 or more values expected => creates a list
        type=int,
        default=do_denoise,  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_extraction",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,  # 0 or more values expected => creates a list
        type=int,
        default=do_extraction,  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_planar_extraction",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,  # 0 or more values expected => creates a list
        type=int,
        default=do_planar_extraction,  # default if nothing is provided
    )
    CLI.add_argument(
        "--recdates",  # name on the CLI - drop the `--` for positional/required parameters
        nargs="*",  # 0 or more values expected => creates a list
        type=str,
        default=[recdates],  # default if nothing is provided
    )
    CLI.add_argument(
        "--fly",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,  # 0 or more values expected => creates a list
        type=str,
        default=fly,  # default if nothing is provided
    )
    CLI.add_argument(
        "--trial",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,  # 0 or more values expected => creates a list
        type=str,
        default=trial,  # default if nothing is provided
    )
    CLI.add_argument(
        "--do_cropping_session",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,  # 0 or more values expected => creates a list
        type=int,
        default=do_cropping_session,  # default if nothing is provided
    )
    CLI.add_argument(
        "--array_index",  # name on the CLI - drop the `--` for positional/required parameters
        nargs=1,  # 0 or more values expected => creates a list
        type=int,
        default=array_index,  # default if nothing is provided
    )

    args = CLI.parse_args()

    print(args)
    
    index = args.index[0]
    region_extraction = args.region_extraction #keep as list
    do_motion_correction = args.do_motion_correction[0]
    do_denoise = args.do_denoise[0]
    do_extraction = args.do_extraction[0]
    do_planar_extraction = args.do_planar_extraction[0]
    recdates = args.recdates #keep as list
    fly = args.fly[0]
    trial = args.trial[0]
    do_cropping_session = args.do_cropping_session[0]
    array_index = args.array_index[0]

    return index, region_extraction, do_motion_correction, do_denoise, do_extraction, do_planar_extraction, recdates,  fly, trial, do_cropping_session, array_index
