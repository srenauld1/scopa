#!/bin/bash

#see readme.md for docs

############ SET PARAMS THAT DETERMINE WHICH JOBS ARE RUN, WHETHER TO AUTOMATE FILE TRANSFER, AND WHETHER TO USE PARALLELIZATION ############

do_register=0 #0 or 1, no space after =, caiman normcorre registration (python)
do_denoise=0 #0 or 1, no space after =, deepcad denoise (python), ARE ADJACENT YOUR FRAMES VERY SIMILAR (SUFFICIENT T RES)?
do_stitch=1 #0 or 1, no space after =, stitch denoised z slices into stack (suffix dcdn_.tif) matching original stack size; must run do_stitch this if USE_DENOISED=(1) for any subsequent jobs in pipeline (e.g. do_remove, do_extract, do_a2p)
do_remove=0 #0 or 1, no space after =, remove scan noise (matlab)
do_extract=0 #0 or 1, no space after =, caiman source extraction (python)
do_a2p=0 #0 or 1, no space after =, first-order analysis of imaging and stimulus/behavior data (matlab)

do_copyfiles_sequence=(1 0 2) #set to (1 0 2) (ie copy in, no copy, copy out) to copy only required files from storage server to O2, then compute on those files (creating new files), then copy new contents back to storage server (requires access to O2 "transfer job partition", must request access at rchelp@hms.harvard.edu), set to (0) to skip all copying and just copy manually
jobind=( 0 ) #zero-indexed, unlike many of the bash arrays here, nonsequential syntax for jobind uses commas, like this ( 0,2,7 ), and sequential syntax uses dash, like this ( 0-2 ) . . . indices for parallel runs (using slurm job array), specifies which recording to analyse from list of those matching file specifiers below . . . right now only available paralellization is by recording tif identified with date_fly_trial and folder substring, and each parallel job will have only one jobind; if this bash variable can be turned into a list of vectors, then pl will paralellize along non-scalar jobarray inds, like doing two parallel jobs, 0-3 at the same time as 4-6)

do_autoallocate=0 #do_autoallocate=1 uses transfer partition to look into server and find size of stack in raw scanimage tif, but doesn't copy anything; stack size determines all resource requests; do_autoallocate=0 uses resources set by user below
fnind_fn_prefix_override='' #if you want to use a file/jobind mapping from a previous pl run (e.g. if there was an error partway through), you can supply the FNIND_FN_PREFIX of that run here (but txt files with prefix fnind_fn_prefix_override must still be present in scopa/fnind), leave empty to let pl assign a new FNIND_FN_PREFIX

############ SET PARAMS FOR IDENTIFYING RECORDING ############

#set input args common to all sbatch jobs below (job-specific arguments are specified within each sbatch file)
#matches filenames with pattern RECDATES_FLY_TRIAL_suffix.tif (where suffix is automatically determined by stage of pipeline) or RECDATES_FLY_*_TRIAL_*_*.tif ( * is wildcard)
#matches within folders containing FOLDER_SUBSTRING ( * is wildcard)
#matching file can be anywhere in directory tree under directory superfolder_name_compute (or superfolder_name_storage if copying to O2)

#BASH LISTS BELOW MUST BE SPACE-DELIMITED, ENCLOSED BY PARENTHESES, AND IF QUOTED, USING SINGLE-QUOTES (all this prevents asterisk * from causing problems) 

FOLDER_WITH_ALL_RECORDINGS_ON_STORAGE_AND_COMPUTE_FILESYSTEMS=('stacks')
PTH_STORAGE_PREFIX=('/n/files/Neurobio/wilsonlab/wienecke/') 

RECDATE=('20250329')
FLY=('3')
TRIAL=('*')
FOLDER_SUBSTRING=('*') #in case RECDATE, FLY, and TRIAL is not specific enough, can also match only within folders containing FOLDER_SUBSTRING 
FILE_MATCHING_STYLE=('any') #'any' will match any combination of elements from RECDATE, FLY, TRIAL, FOLDER_SUBSTRING, 'each' will  match corresponding elements (must all be equal length, or length 1 in which case element is copied to match length of whichever has length greater than 1)


############ SET PARAMS FOR ANALYSIS ############

SCOPATMPLT=(1) #1 to use scopa template
CLIP=(-1) #use space as delimiter, not comma; 0 to skip clip; -1 to set negatives to 0, or (lower upper) quantiles to clip, or (-1 upper), which will set negatives to 0, and clip upper quantile; unless your stack is very noisy, or you have miscalibrated pmt offset, negative values should be predominantly noise and can be removed (assuming you "autoread" pmt offset and "subtract offset" ); 
METHODRG=('first')  #'first' to register the first (or only) saved channel and discard channel 2 if it exists; 'second' to register second channel only and discard first (will error if there is only one saved channel, even if it's channel 2); 'both' to register channels 1 and 2 independently ('both' does not work yet!); '12' to register channel 1, then register channel 2 with the same shifts as channel 1; '21' is same as '12' but reversed; if methodrg is '12' or '21' or 'both' and only one channel is present, methodrg is automatically changed to 'first' 
REGISTER_IN_2D=(0) #register each z slice independently
BGLENPX=(0) #must be even and nonzero, will run line-by-line background subtraction; 0 to skip background subtraction; full width of patch over which mean is computed for background subtraction (patch is a line in x); must be even; applied before registration, won't happen unless do_register==1, (helps remove stimulus bleedthrough, but don't use unless there's a lot of bleedthrough, and there is a clear background patch on each line; if that's the case, set this as large as possible to cover that background, and even)
MAX_SHIFTS_PRC=(15 15 15) #xyz percentages; 0 will be made 1 pixel; unit percentage of FOV in each dimension xyz (converted to pixels in oreg.py; rounds to nearest pixel); max possible shifts (in patch if piecewise, or whole fov if not); z ignored if register_in_2d=1; shifts are computed using a subregion of fov with outermost max_shifts removed (for template and image); this way, in case the fov drifts, the correlation (used to compute shifts) uses a constant region of image (as long as brain doesn't drift more than max_shifts); if your image drifts a lot, max_shifts has to be large, which means a small region of fov is getting correlated with template, which makes it harder to get correct shifts, especially if snr is low; so set this as small as possible to accommodate drift (the extent to which minimizing max_shifts matters depends on snr, assuming it is large enough to accommodate drift)
SMLENPX_MCP=(0 0 0) #gaussian xyz smoothing window length (pixels) in register (registration shifts computed with smoothed data, but shifts applied to nonsmoothed data), so fft-based shifting can still fail if image is so noisy that signal cannot be reconstructed in frequency domain; 0 0 0 to skip
CLIPINTERP=(1) #clip intensity to remain in original data range (interpolation can smear the histogram, sometimes significantly, which can reduce data contrast, ie dff); applied per frame; this happens by default in the original normcorre for matlab, but not in caiman version
REGISTRATION_TEMPLATE_GROUP_ID=('') #empty string to skip; list of space-delimited strings, each formatted recdate_fly_trial_folderSubstring; for each string, use brackets to designate which single trial is used as template, while all trials matching string with chars inside brackets replaced with wildcard * are registered to that template; e.g.  '202406[01]_[1]_[1]_[60312]' will register all trials matching 202406*_*_*_* (if they are also matched to above file specifiers, recdate, fly, trial, folder_substring) to a template created from raw tif matching **/*312*/**/20240601_1_1*tif (or **/*312*/**/20240601_1_*trial_001*tif for flyg filename format); recordings requested above that do not match any REGISTRATION_TEMPLATE_GROUP_ID just get registered in the default way (without a template); strings cannot have overlapping matches (within brackets, or outside); template must match recording in xyz size; template is median of 5 frames, which are each mean of 10 frames, equidistant across entire stack; code will sleep (with messages) for up to 300 seconds while waiting for template to be created (in case being created in parallel job)  

DNRAW=(1) #denoise raw (unregistered) stacl
CHAN_DN=('all') #'all', '1', or '2'; refers to the index in the output stack from registration (suffix *cmrg_.tif), so if you discarded channel 1 in registration the output cmrg will have one channel, and if you want to denoise that one channel (which is channel 2), set chan_dn to 1 (not 2), or you can just set to 'all' and it will work always; also 2 will error if there was only one channel to begin with (ie no *chn2_cmrg*.tif exists)
DENOISE_VOLUME=(1) #0 or 1, train on multiple z slices, or one z slice at a time
DENOISE_SLICE_INDEX=('all') #'all' for all z slices, or list of z indices for subset
NUM_EPOCHS_DENOISE=(10) #how many training epochs (training is continuous across epochs, but model is saved after each to allow denoising (testing) to apply to model at different states of training)
EPOCH_CHOOSE_DENOISE=$(seq -s ' ' $NUM_EPOCHS_DENOISE) #syntax is EPOCH_CHOOSE_DENOISE=$(seq  -s ' ' $NUM_EPOCHS_DENOISE) for all epochs (1 to NUM_EPOCHS_DENOISE), or EPOCH_CHOOSE_DENOISE=(2 3 7) for a subset (here, 2, 3, and 7), or EPOCH_CHOOSE_DENOISE=(2) for one epoch; denoising epoch used going forward in the pipeline, chosen epoch's z slices stitched into stack and saved as tif with suffix dcdn (in stc, called by do_stich); one-indexed; must exist, ie must be one of epochs_choose in denoise.py; if single number, will use that epoch, if multiple, will choose best epoch automatically (see denoise_score.py); will overwrite existing dcdn stack if you run on same data more than once 

USE_BACKGROUND_SUBTRACTED=(0) #1 to use the background-subtracted, registered stack (suffix *bksb_cmrg_.tif) for any job after registration, 0 to use the registered stack (without background subtraction, suffix *cmrg_.tif) for any job after registration; if it doesn't exist, won't error
USE_DENOISED=(1) #1 to use the registered, denoised stack for any job after registration and/or denoising (suffix *cmrg_dcdn_.tif), 0 to use the registered stack (without denoising) for any job after registration and/or denoising (suffix *cmrg_.tif); if it doesn't exist, won't error

STOPBAND_RSC=(10 20) #stopband frequency indices; for now just set emperically at [10 20] (removing 10th-20th frequencies); keep between 2 and half number of pixels in x dimension . . . hopefully scan noise bandwidth scales simply with imaging temporal frequency
SMLENSEC_RSC=(0) #seconds, gaussian temporal smoothing window length in scannoiserm (only used if do_remove=1); to better bandlimit scan noise before filtering
USE_SCANNOISE_REMOVED=(0) #1 to use the stack (a mat file) with scan noise removed (suffix 'nosn_.mat', output from do_remove), for any job after do_remove, 0 to not use it; if it doesn't exist, won't error

METHODEX=('seed21py') #'1' (channel 1 only), '2' (channel 2 only), '12' (channel 1 and 2 independently), 'seedeachpy' (channel 1 and 2 independently, with python-automated morph roi seed masks for each channel), 'seedeachmat' (same as seedeachpy, but using morph rois created/saved in matlab), 'seed21py' (python-automated morph roi seed mask in channel 2 seed functional extraction from channel 1), 'seed12py' (inverse of seed21py), 'seed21mat' (same as 'seed21py', but for morph rois created/saved in matlab), 'seed12mat' (inverse of 'seed21mat'); the seed*py methodex only work when extract_in_2d=True
EXTRACT_IN_2D=(1)
RGNAME=('fullfov')

USE_CLUSTER=(1) #to speed up caiman code; registration is fast enough (less than an hour) for our normal recordings; consider using cluster if your recording is very long (>30000 frames, for example) or very high res (>512,512,20, for example); running O2 non-interactive jobs, use cluster_backend='multiprocessing' (automatically set in pl.py); i haven't gotten cluster_backend='ipyparallel' to work for that case, and haven't tried for other cases


############ SET PARAMS FOR RESOURCE REQUEST MANUALLY IF do_autoallocate=0, OTHERWISE IT IS AUTOMATIC) ############

if [ "$do_autoallocate" == 0 ]; then
    
    ############ SET PARAMS FOR ALL JOBS EXCEPT DENOISING (THESE DO NOT USE GPU) ############

    cpu_per_task_copyfiles=1
    mem_per_cpu_copyfiles=4G
    time_copyfiles=00:20:00

    cpu_per_task_autoallocate=1
    mem_per_cpu_autoallocate=5G
    time_autoallocate=00:10:00

    cpu_per_task_register=3
    mem_per_cpu_register=25G
    time_register=0:40:00

    cpu_per_task_stitch=1
    mem_per_cpu_stitch=20G
    time_stitch=00:25:00

    cpu_per_task_extract=1
    mem_per_cpu_extract=20G
    time_extract=1:30:00

    cpu_per_task_remove=1
    mem_per_cpu_remove=20G
    time_remove=0:30:00

    cpu_per_task_a2p=1
    mem_per_cpu_a2p=10G
    time_a2p=0:20:00

    ############ SET PARAMS FOR DENOISING RESOURCE REQUEST (THIS INCLUDES GPU) ############

    cpu_per_task_denoise=1
    mem_per_cpu_denoise=18G

    gpustr=rtx6000_24 #shorthand name of gpu to use; suggested gpu is rtx6000_24, or a100_80 for large stacks; current options are a100_80, a100_40_mig, v100_32, a100_40, rtx6000_24, m40_12, v100_16 (there are others on O2, but this list covers large and small on the major gpu partitions)

    if [ "$gpustr" == a100_80 ]; then 
        gpu_to_use=a100:1,vram:80G  #fastest on gpu_quad (double precision)
        gpu_partition=gpu_quad 
        time_denoise=5:00:00
    elif [ "$gpustr" == a100_40_mig ]; then 
        gpu_to_use=a100.mig:1,vram:40G  #mig on gpu_quad (probably double precision)
        gpu_partition=gpu_quad 
        time_denoise=4:30:00 #untested, 
    elif [ "$gpustr" == v100_32 ]; then 
        gpu_to_use=teslaV100s:1,vram:32G #lowest vram on on gpu_quad (double precision)
        gpu_partition=gpu_quad 
        time_denoise=9:00:00
    elif [ "$gpustr" == a100_40 ]; then 
        gpu_to_use=a100:1,vram:40G #fastest on gpu_requeue (here 40G, but 80G also available) (unnamed precision)
        gpu_partition=gpu_requeue
        time_denoise=4:00:00 #time untested on requeue, maybe similar to time for a100_80 on quad partition?
    elif [ "$gpustr" == rtx6000_24 ]; then 
        gpu_to_use=rtx6000:1,vram:24G #2nd-lowest vram on gpu_requeue (single precision)
        gpu_partition=gpu_requeue
        time_denoise=8:30:00 #for stack size (128,256,15,3047), tested time 5.5 hours, train 5 epochs with 10K patches, test 5 epochs, 
    elif [ "$gpustr" == m40_12 ]; then 
        gpu_to_use=teslaM40:1,vram:12G #lowest vram on gpu_requeue (probably double precision), there's also one on gpu partition (also 24 gb, double precision), where it's the 2nd fastest, but running on gpu_requeue is preferred method on scopa
        gpu_partition=gpu_requeue
        time_denoise=18:00:00 #tested time a little under 12 hours, train 5 epochs with 10K patches, test 5 epochs, 
    elif [ "$gpustr" == v100_16 ]; then 
        gpu_to_use=teslaV100:1,vram:16G #fastest on gpu partition (double precision)
        gpu_partition=gpu
        time_denoise=18:00:00 #tested time a little under 12 hours, train 5 epochs with 10K patches, test 5 epochs, 
    fi   

fi

############ USER SHOULD NOT HAVE TO CHANGE ANYTHING BELOW THIS LINE ############



############ CREATE PREFIX FOR TXT FILES THAT WILL MAP FOUND FILENAMES TO PARALLEL JOB INDICES ############

if [ -z "${fnind_fn_prefix_override}" ]; then 
    CURRTIME="`date +%Y%m%d%H%M%S`"
    FNIND_FN_PREFIX=${CURRTIME} #string, a datetime string id assigned on the first job run by pl.sh, will point to a file that saves/maps filename specifiers and indices to ensure files get the same index across all jobs run by pl, make empty to skip 
else 
    FNIND_FN_PREFIX=$fnind_fn_prefix_override #override jobid mapping in fnind file with a file with your own suffix
fi

############ MAKE SCOPATMPDIR TO STORE SCOPA TEMP FILES AND OUTPUT IN USER'S HOME DIR ############

user_homedir=$( getent passwd "$USER" | cut -d: -f6 ) 
SCOPADIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
name_of_scopa_tmp_folder=scopatmp
SCOPATMPDIR=$user_homedir/$name_of_scopa_tmp_folder
mkdir -p $SCOPATMPDIR

pthout=$SCOPATMPDIR/slurm-%A_%a.out

#PTH_GPULOG=$SCOPATMPDIR/$SLURM_JOBID.gpulog

############ WRITE THE ABOVE PARAMS TO PTH_PARSFILE ############

PTH_PARSFILE=$SCOPATMPDIR/scopaparams.txt #no need to change this, make empty to skip (no reason to do that here though) filename for params that are common to all sbatch files called below, this txt file is automatically created and overwritten each time you run pl.sh

declare -A pars #put common input args into associative array called pars (grouping them into associative array helps with automation downstream)

pars["SCOPATMPDIR"]="${SCOPATMPDIR[@]}"
pars["FNIND_FN_PREFIX"]="${FNIND_FN_PREFIX[@]}"
pars["FOLDER_WITH_ALL_RECORDINGS_ON_STORAGE_AND_COMPUTE_FILESYSTEMS"]="${FOLDER_WITH_ALL_RECORDINGS_ON_STORAGE_AND_COMPUTE_FILESYSTEMS[@]}"
pars["PTH_STORAGE_PREFIX"]="${PTH_STORAGE_PREFIX[@]}"
pars["RECDATE"]="${RECDATE[@]}"
pars["FLY"]="${FLY[@]}"
pars["TRIAL"]="${TRIAL[@]}"
pars["FOLDER_SUBSTRING"]="${FOLDER_SUBSTRING[@]}"
pars["FILE_MATCHING_STYLE"]="${FILE_MATCHING_STYLE[@]}"
pars["SCOPATMPLT"]="${SCOPATMPLT[@]}"
pars["CLIP"]="${CLIP[@]}"
pars["METHODRG"]="${METHODRG[@]}"
pars["CLIPINTERP"]="${CLIPINTERP[@]}"
pars["REGISTRATION_TEMPLATE_GROUP_ID"]="${REGISTRATION_TEMPLATE_GROUP_ID[@]}"
pars["REGISTER_IN_2D"]="${REGISTER_IN_2D[@]}"
pars["BGLENPX"]="${BGLENPX[@]}"
pars["SMLENPX_MCP"]="${SMLENPX_MCP[@]}"
pars["MAX_SHIFTS_PRC"]="${MAX_SHIFTS_PRC[@]}"
pars["USE_CLUSTER"]="${USE_CLUSTER[@]}"
pars["DNRAW"]="${DNRAW[@]}"
pars["CHAN_DN"]="${CHAN_DN[@]}"
pars["DENOISE_VOLUME"]="${DENOISE_VOLUME[@]}"
pars["DENOISE_SLICE_INDEX"]="${DENOISE_SLICE_INDEX[@]}"
pars["NUM_EPOCHS_DENOISE"]="${NUM_EPOCHS_DENOISE[@]}"
pars["USE_BACKGROUND_SUBTRACTED"]="${USE_BACKGROUND_SUBTRACTED[@]}"
pars["USE_DENOISED"]="${USE_DENOISED[@]}"
pars["USE_SCANNOISE_REMOVED"]="${USE_SCANNOISE_REMOVED[@]}"
pars["EPOCH_CHOOSE_DENOISE"]="${EPOCH_CHOOSE_DENOISE[@]}"
pars["STOPBAND_RSC"]="${STOPBAND_RSC[@]}"
pars["SMLENSEC_RSC"]="${SMLENSEC_RSC[@]}"
pars["METHODEX"]="${METHODEX[@]}"
pars["EXTRACT_IN_2D"]="${EXTRACT_IN_2D[@]}"
pars["RGNAME"]="${RGNAME[@]}"

for key in "${!pars[@]}"; do
  printf '%s\0' "$key" "${pars[$key]}"
done >"$PTH_PARSFILE" #write common input args to txt file


############ SET SEQUENCE OF SBATCH JOBS TO BE SUBMITTED ############


jobnm_seq=() #list of sbatch jobs run by pl.sh (space delimited, enclosed by parentheses, no quotes required)

if [ "$do_autoallocate" == 1 ]; then
    jobnm_seq+=(alo)
fi
if [ "$do_register" == 1 ]; then
    jobnm_seq+=(mcp)
fi
if [ "$do_denoise" == 1 ]; then
    jobnm_seq+=(dnp)
fi
if [ "$do_stitch" == 1 ]; then
    jobnm_seq+=(stc)
fi
if [ "$do_remove" == 1 ]; then
    jobnm_seq+=(rsc)
fi
if [ "$do_extract" == 1 ]; then
    jobnm_seq+=(exp)
fi
if [ "$do_a2p" == 1 ]; then
    jobnm_seq+=(a2p)
fi


############ LOOP OVER SBATCH JOBS AND DO_COPYFILES DIRECTIVES (TODO: RESOURCES SET IN LOOP BELOW FOR NOW, MAKE THIS AUTOMATED SOON) ############

echo -e "STARTING SCOPA PIPELINE \n SUBMITTING THE FOLLOWING SBATCH JOBS \n "${jobnm_seq[@]}""
echo LIST OF PATHS AVAILABLE TO pl.sh: ; echo ; echo "${PATH//:/$'\n'}" ; echo

swtichon=1
loopcount=0
for JOBNM in "${jobnm_seq[@]}"; do
    
    for DO_COPYFILES in "${do_copyfiles_sequence[@]}"; do #copy files on first loop (from superfolder_name_storage to superfolder_name_compute), analyze data from those files on second loop 

        if { [ "$DO_COPYFILES" != 0 ] && [ "$JOBNM" == alo ]; } || { [ "$DO_COPYFILES" == 1 ] && [ "$JOBNM" == dnp ] && [ "$do_register" == 1 ]; } ||  { [ "$DO_COPYFILES" == 2 ] && [ "$JOBNM" == dnp ]; } || { [ "$DO_COPYFILES" == 1 ] && [ "$JOBNM" == stc ]; }; then #skip copyfiles 1 for denoising if you also ran register, copyfiles 2 for denoising, and copyfiles 1 for stitch,  

            echo "SKIPPING A COPYFILES JOB BECAUSE IT'S NOT NECESSARY"

        else

            if [ $loopcount == 0 ]; then #on the first loop, use first_noncopy_job flag, and there is no job dependency ('singleton' will do nothing because --name param is not specified)
                dep_str=singleton
            else #on subsequent loops, use dependencies, and turn off first_noncopy_job flag 
                dep_str=aftercorr:${!tmpid} #the job depends on the previous job with corresponding array index, whose value is accessed with ${!tmpid}, rather than $tmpid, since it is dynamic
            fi

            if [ "$DO_COPYFILES" == 0 ] && [ "$swtichon" == 1 ]; then
                FIRST_NONCOPY_JOB=1 #set to 0 the first time the loop encounters a job with do_copyfiles 0   
                swtichon=0    
            else
                FIRST_NONCOPY_JOB=0 #set to 0 the first time the loop encounters a job with do_copyfiles 0               
            fi

            requeue_str=--begin=now #don't change this dummy variable, only overwritten if using the gpu_requeue partition 
            gres_str=--begin=now #this is a dummy string to make gres_str work properly for all jobs (denoising with dnp, when gres_str is actully functional by setting gpu, and otherwise, when this dummy string is used to make the job begin "now", which is default anyway . . . empty string doesn't work)
            if [ "$DO_COPYFILES" == 1 ] || [ "$DO_COPYFILES" == 2 ]; then #do_copyfiles 1 or 2
                echo "ON LOOP "$loopcount", TYPE "$DO_COPYFILES" FILE COPY FROM WITHIN SBATCH JOB"
                echo "FORCING jobind=0 SO COPYFILES OCCURS IN A SINGLE JOB"
                jobind_tmp=( 0 )
                partition_str=transfer    
                time_str=$time_copyfiles
                ntasks_str=1
                cpus_per_task_str=$cpu_per_task_copyfiles
                mem_per_cpu_str=$mem_per_cpu_copyfiles
            else
                jobind_tmp=("${jobind[@]}")
                echo "ON LOOP "$loopcount", NO FILE COPY FROM WITHIN SBATCH JOB"
                if [ "$JOBNM" == alo ]; then #do_autoallocate
                    partition_str=transfer #use transfer partition if autoallocate
                    time_str=$time_autoallocate
                    ntasks_str=1
                    cpus_per_task_str=$cpu_per_task_autoallocate
                    mem_per_cpu_str=$mem_per_cpu_autoallocate
                elif [ "$JOBNM" == mcp ]; then #do_register
                    partition_str=short
                    time_str=$time_register
                    ntasks_str=1
                    if [ "${BGLENPX[@]}" == 0 ]; then #use less memory if no bg subtraction
                        cpus_per_task_str=$cpu_per_task_register
                        mem_per_cpu_str=$mem_per_cpu_register
                    else #use more memory if using bg subtraction
                        cpus_per_task_str=$cpu_per_task_register
                        mem_per_cpu_str=$mem_per_cpu_register
                    fi
                elif [ "$JOBNM" == dnp ]; then #do_denoise
                    partition_str=$gpu_partition
                    time_str=$time_denoise
                    ntasks_str=1
                    cpus_per_task_str=$cpu_per_task_denoise
                    mem_per_cpu_str=$mem_per_cpu_denoise
                    gres_str=--gres=gpu:$gpu_to_use
                    if [ "$gpu_partition" == gpu_requeue ]; then
                        requeue_str=--requeue 
                    fi 
                elif [ "$JOBNM" == stc ]; then #do_stitch
                    partition_str=short
                    time_str=$time_stitch
                    ntasks_str=1
                    cpus_per_task_str=$cpu_per_task_stitch
                    mem_per_cpu_str=$mem_per_cpu_stitch
                elif [ "$JOBNM" == exp ]; then #do_extract
                    partition_str=short
                    time_str=$time_extract
                    ntasks_str=1
                    cpus_per_task_str=$cpu_per_task_extract
                    mem_per_cpu_str=$mem_per_cpu_extract
                elif [ "$JOBNM" == rsc ]; then #do_remove
                    partition_str=short
                    time_str=$time_remove #11:40:00
                    ntasks_str=1
                    cpus_per_task_str=$cpu_per_task_remove
                    mem_per_cpu_str=$mem_per_cpu_remove
                elif [ "$JOBNM" == a2p ]; then  #do_a2p
                    partition_str=short
                    time_str=$time_a2p
                    ntasks_str=1
                    cpus_per_task_str=$cpu_per_task_a2p
                    mem_per_cpu_str=$mem_per_cpu_a2p
                fi
            fi

            #run the sbatch file, using export to pass args, and specifying slurm directives, including job array indices, use parsable to output the job id for dependencies downstream
            arr_id_out=$(sbatch --parsable \
            --export=DO_COPYFILES="$DO_COPYFILES",FIRST_NONCOPY_JOB="$FIRST_NONCOPY_JOB",PTH_PARSFILE="$PTH_PARSFILE",SCOPADIR="$SCOPADIR",JOBNM="$JOBNM" \
            --array=[$jobind_tmp] \
            --dependency="$dep_str" \
            --partition="$partition_str" \
            --time="$time_str" \
            --ntasks="$ntasks_str" \
            --cpus-per-task="$cpus_per_task_str" \
            --mem-per-cpu="$mem_per_cpu_str" \
            --output="$pthout" \
            --error="$pthout" \
            --exclude=compute-gc-17-245 \
            --mail-type=ALL,ARRAY_TASKS \
            "$requeue_str" \
            "$gres_str" \
            pl.sbatch) 


            declare arrid_${loopcount}_dynvar=$arr_id_out #create dynamic variable name to store job_id for next job dependency specification
            tmpid=arrid_${loopcount}_dynvar #assign to another var whose value is accessed with ${!tmpid}, rather than $tmpid, since it is dynamic

            echo ""$JOBNM" HAS JOB-ARRAY ID: ${!tmpid}"

            loopcount=$((loopcount+1)) #increment loopcount

        fi

    done

done

