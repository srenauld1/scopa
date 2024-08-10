#!/bin/bash

#cxp.sh runs the entire preprocessing pipeline by specifying params for pipeline_init.py
# run as ./cxp.sh and it will not be submitted to the scheduler itself, but will submit jobs to the scheduler
#pipeline_init.py is called from various sbatch files (specified by sbatch_job_name_sequence), which are themselves called below, and each of which uses different resources and depends on the previous (with matching jobarrayind) to finish without error
#cxp.sh is designed to only be called once  #######
#the sbatch files called below can run multiple jobs in parallel if jobarrayind has more than one element (those indices are used to select recordings for analysis, ie embarrassingly parallel)
#each sbatch file below is called in a 2-iteration for loop, the first iteration copies the required files from storage server to scratch on O2, the second operates on them, afterward files are automatically copied back to the storage server  
#copying requires access to the transfer job partition (write rchelp@hms.harvard.edu to request access), without access the copying is skipped (so you must manually move files to O2)
##
#the cxp.sh pipeline is separated into tasks that require different time/memory resources, to make analysis more efficient
#see pipeline_init.py and README.md for more details 

#note bash variables are strings; variables that are passed to python code have single quotes (this is both functional and stylistic, this code is written to handle those single quotes, and changing them can cause error), variables that are only used in bash code are not in quotes (for most or maybe all of these variables, this is just a matter of style)
#bash variables that are created by us are in lowercase, unless they are exported to another sbatch file (to distinguish them from environmental and internal variables, which are capitalized)

#emailz sent to user for all tasks, all job states, to avoid clutter, you can configure your email to store all slurm emails in a slurm folder 

### CONSIDERING ADDING VARIABLE that requires user defined roi limits before DO_EXTRACT (ie do not operate on default fullfov)

##TO USE cxp.sh, CLONE SCOPA REPO INTO YOUR HOME DIR ON O2 

#set variables that control which jobs are done

############ SET PARAMS THAT DETERMINE WHICH JOBS ARE RUN, WHETHER TO AUTOMATE FILE TRANSFER, AND WHETHER TO USE PARALLELIZATION ############

do_register=0 #0 or 1, no space after =, caiman normcorre registration (python)
do_denoise=1 #0 or 1, no space after =, deepcad denoise (python), ARE ADJACENT YOUR FRAMES VERY SIMILAR (SUFFICIENT T RES)?
do_remove=0 #0 or 1, no space after =, remove scan noise (matlab)
do_extract=0 #0 or 1, no space after =, caiman source extraction (python)
do_analysis=0 #0 or 1, no space after =, first-order analysis of imaging and stimulus/behavior data (matlab)
do_copyfiles_sequence=(0 2) #set to (1 0 2) (ie copy in, no copy, copy out) to copy only required files from storage server to O2, then compute on those files (creating new files), then copy new contents back to storage server (requires access to O2 "transfer job partition", must request access at rchelp@hms.harvard.edu), set to (0) to skip all copying and just copy manually
jobarrayind=( 0 ) #zero-indexed, unlike many of the bash arrays here, nonsequential syntax for jobarrayind uses commas, like this ( 0,2,7 ), and sequential syntax uses dash, like this ( 0-2 ) . . . indices for parallel runs (using slurm job array), specifies which recording to analyse from list of those matching file specifiers below . . . right now only available paralellization is by recording tif identified with date_fly_trial and folder substring, and each parallel job will have only one jobarrayind
fnind_fn_prefix_override='' #if you want to use a file/jobarrayind mapping from a previous cxp run (e.g. if there was an error partway through), you can supply the FNIND_FN_PREFIX of that run here (but txt files with prefix fnind_fn_prefix_override must still be present in scopa/fnind), leave empty to let cxp assign a new FNIND_FN_PREFIX

############ SET PARAMS FOR IDENTIFYING RECORDING ############

#set input args common to all sbatch jobs below (job-specific arguments are specified within each sbatch file)
#matches filenames with pattern RECDATES_FLY_TRIAL_suffix.tif (where suffix is automatically determined by stage of pipeline) or RECDATES_FLY_*_TRIAL_*_*.tif ( * is wildcard)
#matches within folders containing FOLDER_SUBSTRING ( * is wildcard)
#matching file can be anywhere in directory tree under directory superfolder_name_compute (or superfolder_name_storage if copying to O2)



#BASH LISTS BELOW MUST BE SINGLE-QUOTED, SPACE-DELIMITED, ENCLOSED BY PARENTHESES (this prevents asterisk * from causing problems) 


FOLDER_WITH_ALL_RECORDINGS_ON_STORAGE_AND_COMPUTE_FILESYSTEMS=('stacks')
PTH_STORAGE_PREFIX=('/n/files/Neurobio/wilsonlab/wienecke/') 

RECDATE=('202408*')
FLY=('*')
TRIAL=('*')
FOLDER_SUBSTRING=('*') #in case RECDATE, FLY, and TRIAL is not specific enough, can also match only within folders containing FOLDER_SUBSTRING 
FILE_MATCHING_STYLE=('any') #'any' will match any combination of elements from RECDATE, FLY, TRIAL, FOLDER_SUBSTRING, 'each' will  match corresponding elements (must all be equal length, or length 1 in which case element is copied to match length of whichever has length greater than 1)


############ SET PARAMS FOR ANALYSIS ############

REGISTRATION_TEMPLATE_GROUP_ID=('') #empty string to skip; list of space-delimited strings, each formatted recdate_fly_trial_folderSubstring; for each string, use brackets to designate which single trial is used as template, while all trials matching string with chars inside brackets replaced with wildcard * are registered to that template; e.g.  '202406[01]_[1]_[1]_[60312]' will register all trials matching 202406*_*_*_* (if they are also matched to above file specifiers, recdate, fly, trial, folder_substring) to a template created from raw tif matching **/*312*/**/20240601_1_1*tif (or **/*312*/**/20240601_1_*trial_001*tif for flyg filename format); recordings requested above that do not match any REGISTRATION_TEMPLATE_GROUP_ID just get registered in the default way (without a template); strings cannot have overlapping matches (within brackets, or outside); template must match recording in xyz size; template is median of 5 frames, which are each mean of 10 frames, equidistant across entire stack; code will sleep (with messages) for up to 300 seconds while waiting for template to be created (in case being created in parallel job)  

REGISTER_IN_2D=(1) #register each z slice independently
HALFWIDTH_WINDOW_BGSUB=(0) #make zero to skip, otherwise window half width for line by line background subtraction (helps remove stimulus bleedthrough, but don't use unless there's a lot of bleedthrough)
LEN_WINDOW_SMOOTH_T_MCP_SEC=(0) #seconds, gaussian temporal smoothing window length in register (prior to registration, helps register noisy movies)

DENOISE_VOLUME=(1) #0 or 1, train on multiple z slices, or one z slice at a time
DENOISE_SLICE_INDEX=('all') #'all' for all z slices, or list of z indices for subset
NUM_EPOCHS_DENOISE=(5) #how many training epochs (training is continuous across epochs, but model is saved after each to allow denoising (testing) to apply to model at different states of training)
EPOCH_CHOOSE_DENOISE=(5) #denoising epoch used going forward, denoised stack saved as tif with suffix dcdn (TODO: epoch is not saved in filename, meaning you have to delete or move existing dcdn_.tif and rerun with different EPOCH_CHOOSE_DENOISE if you want to use different epoch, this is faster than rerunning denoising, but still stupid, fix it soon) 

USE_BACKGROUND_SUBTRACTED=(0) #1 to use the background-subtracted, registered stack (suffix *bksb_cmrg_.tif) for any job after registration, 0 to use the registered stack (without background subtraction, suffix *cmrg_.tif) for any job after registration; if it doesn't exist, won't error
USE_DENOISED=(1) #1 to use the registered, denoised stack for any job after registration and/or denoising (suffix *cmrg_dcdn_.tif), 0 to use the registered stack (without denoising) for any job after registration and/or denoising (suffix *cmrg_.tif); if it doesn't exist, won't error

LEN_WINDOW_SMOOTH_T_RSC_SEC=(0) #seconds, gaussian temporal smoothing window length in remove_scan_noise (only used if do_remove=1)
USE_SCANNOISE_REMOVED=(0) #1 to use the stack (a mat file) with scan noise removed (suffix 'nosn_.mat', output from do_remove), for any job after do_remove, 0 to not use it; if it doesn't exist, won't error

EXTRACT_IN_2D=(1)
REGIONEX=('fullfov')
INDEX_EXTRACTION_PARAM_SET=('default')


############ SET PARAMS FOR RESOURCE REQUEST ############

gpu_to_use=a100:1,vram:80G  #fastest on gpu_quad (double precision)
# gpu_to_use=a100.mig:1,vram:40G  #mig on gpu_quad (probably double precision)
# gpu_to_use=teslaV100s:1,vram:32G #lowest vram on on gpu_quad (double precision)
#gpu_to_use=a100:1,vram:40G #fastest on gpu_requeue (here 40G, but 80G also available) (unnamed precision)
#gpu_to_use=rtx6000:1,vram:24G #2nd-lowest vram on gpu_requeue (single precision)
#gpu_to_use=teslaM40:1,vram:12G #lowest vram on gpu_requeue (probably double precision)
# gpu_to_use=teslaV100:1,vram:16G #fastest on gpu partition (double precision)
# this one same as on gpu_requeue so work out which to use ---> gpu_to_use=teslaM40:1,vram:12G #2nd fastest on gpu partition (also 24G) (double precision)


if [ "$gpu_to_use" == teslaM40:1,vram:12G ]; then 
    gpu_partition=gpu_requeue
    gpu_time=12:00:00 #tested time a little under 12 hours, train 5 epochs with 10K patches, test 5 epochs, 
elif [ "$gpu_to_use" == rtx6000:1,vram:24G ]; then 
    gpu_partition=gpu_requeue
    gpu_time=8:00:00 #for stack size (128,256,15,3047), tested time 5.5 hours, train 5 epochs with 10K patches, test 5 epochs, 
elif [ "$gpu_to_use" == teslaV100s:1,vram:32G ]; then 
    gpu_partition=gpu_quad 
    gpu_time=6:00:00
elif [ "$gpu_to_use" == a100:1,vram:80G ]; then 
    gpu_partition=gpu_quad 
    gpu_time=3:00:00
fi


############ CREATE PREFIX FOR TXT FILES THAT WILL MAP FOUND FILENAMES TO PARALLEL JOB INDICES ############

if [ -z "${fnind_fn_prefix_override}" ]; then #on the first loop, use first_job flag, and there is no job dependency ('singleton' will do nothing because --name param is not specified)
    CURRTIME="`date +%Y%m%d%H%M%S`"
    FNIND_FN_PREFIX=${CURRTIME} #string, a datetime string id assigned on the first job run by cxp.sh, will point to a file that saves/maps filename specifiers and indices to ensure files get the same index across all jobs run by cxp, make empty to skip 
else #on subsequent loops, use dependencies, and turn off first_job flag 
    FNIND_FN_PREFIX=$fnind_fn_prefix_override
fi

############ MAKE SCOPATMPDIR TO STORE SCOPA TEMP FILES AND OUTPUT IN USER'S HOME DIR ############

user_homedir=$( getent passwd "$USER" | cut -d: -f6 ) 
scripdir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PARENDIR="$(dirname "$scripdir")"
name_of_scopa_tmp_folder=scopatmp
SCOPATMPDIR=$user_homedir/$name_of_scopa_tmp_folder
mkdir -p $SCOPATMPDIR

pthout=$SCOPATMPDIR/slurm-%A_%a.out

############ WRITE THE ABOVE PARAMS TO PTH_PARSFILE ############

PTH_PARSFILE=$SCOPATMPDIR/scopaparams.txt #no need to change this, make empty to skip (no reason to do that here though) filename for params that are common to all sbatch files called below, this txt file is automatically created and overwritten each time you run cxp.sh

declare -A pars #put common input args into associative array called pars (grouping them into associative array helps with automation downstream)

pars["SCOPATMPDIR"]="${SCOPATMPDIR[@]}"
pars["FOLDER_WITH_ALL_RECORDINGS_ON_STORAGE_AND_COMPUTE_FILESYSTEMS"]="${FOLDER_WITH_ALL_RECORDINGS_ON_STORAGE_AND_COMPUTE_FILESYSTEMS[@]}"
pars["PTH_STORAGE_PREFIX"]="${PTH_STORAGE_PREFIX[@]}"
pars["RECDATE"]="${RECDATE[@]}"
pars["FLY"]="${FLY[@]}"
pars["TRIAL"]="${TRIAL[@]}"
pars["FOLDER_SUBSTRING"]="${FOLDER_SUBSTRING[@]}"
pars["FILE_MATCHING_STYLE"]="${FILE_MATCHING_STYLE[@]}"
pars["REGISTRATION_TEMPLATE_GROUP_ID"]="${REGISTRATION_TEMPLATE_GROUP_ID[@]}"
pars["REGISTER_IN_2D"]="${REGISTER_IN_2D[@]}"
pars["HALFWIDTH_WINDOW_BGSUB"]="${HALFWIDTH_WINDOW_BGSUB[@]}"
pars["LEN_WINDOW_SMOOTH_T_MCP_SEC"]="${LEN_WINDOW_SMOOTH_T_MCP_SEC[@]}"
pars["DENOISE_VOLUME"]="${DENOISE_VOLUME[@]}"
pars["DENOISE_SLICE_INDEX"]="${DENOISE_SLICE_INDEX[@]}"
pars["NUM_EPOCHS_DENOISE"]="${NUM_EPOCHS_DENOISE[@]}"
pars["USE_BACKGROUND_SUBTRACTED"]="${USE_BACKGROUND_SUBTRACTED[@]}"
pars["USE_DENOISED"]="${USE_DENOISED[@]}"
pars["USE_SCANNOISE_REMOVED"]="${USE_SCANNOISE_REMOVED[@]}"
pars["EPOCH_CHOOSE_DENOISE"]="${EPOCH_CHOOSE_DENOISE[@]}"
pars["LEN_WINDOW_SMOOTH_T_RSC_SEC"]="${LEN_WINDOW_SMOOTH_T_RSC_SEC[@]}"
pars["EXTRACT_IN_2D"]="${EXTRACT_IN_2D[@]}"
pars["REGIONEX"]="${REGIONEX[@]}"
pars["INDEX_EXTRACTION_PARAM_SET"]="${INDEX_EXTRACTION_PARAM_SET[@]}"
pars["FNIND_FN_PREFIX"]="${FNIND_FN_PREFIX[@]}"

for key in "${!pars[@]}"; do
  printf '%s\0' "$key" "${pars[$key]}"
done >"$PTH_PARSFILE" #write common input args to txt file


############ SET SEQUENCE OF SBATCH JOBS TO BE SUBMITTED ############


sbatch_job_name_sequence=() #list of sbatch jobs run by cxp.sh (space delimited, enclosed by parentheses, no quotes required)

if [ "$do_register" == 1 ]; then
    sbatch_job_name_sequence+=(mcp.sbatch)
fi
if [ "$do_denoise" == 1 ]; then
    sbatch_job_name_sequence+=(dnp.sbatch)
    sbatch_job_name_sequence+=(stc.sbatch)
fi
if [ "$do_remove" == 1 ]; then
    sbatch_job_name_sequence+=(rsc.sbatch)
fi
if [ "$do_extract" == 1 ]; then
    sbatch_job_name_sequence+=(exp.sbatch)
fi
if [ "$do_analysis" == 1 ]; then
    sbatch_job_name_sequence+=(a2p.sbatch)
fi


############ LOOP OVER SBATCH JOBS AND DO_COPYFILES DIRECTIVES (TODO: RESOURCES SET IN LOOP BELOW FOR NOW, MAKE THIS AUTOMATED SOON) ############

echo -e "STARTING SCOPA PIPELINE \n SUBMITTING THE FOLLOWING SBATCH JOBS \n "${sbatch_job_name_sequence[@]}""
echo LIST OF PATHS AVAILABLE TO cxp.sh: ; echo ; echo "${PATH//:/$'\n'}" ; echo

loopcount=0
for sbatch_job_name in "${sbatch_job_name_sequence[@]}"; do
    
    for DO_COPYFILES in "${do_copyfiles_sequence[@]}"; do #copy files on first loop (from superfolder_name_storage to superfolder_name_compute), analyze data from those files on second loop 

        if [ $loopcount == 0 ]; then #on the first loop, use first_job flag, and there is no job dependency ('singleton' will do nothing because --name param is not specified)
            FIRST_JOB=1
            dep_str=singleton
        else #on subsequent loops, use dependencies, and turn off first_job flag 
            FIRST_JOB=0
            dep_str=aftercorr:${!tmpid} #the job depends on the previous job with corresponding array index, whose value is accessed with ${!tmpid}, rather than $tmpid, since it is dynamic
        fi

        requeue_str=--begin=now #don't change this dummy variable, only overwritten if using the gpu_requeue partition 
        gres_str=--begin=now #this is a dummy string to make gres_str work properly for all jobs (denoising with dnp.sbatch, when gres_str is actully functional by setting gpu, and otherwise, when this dummy string is used to make the job begin "now", which is default anyway . . . empty string doesn't work)
        if [ "$DO_COPYFILES" == 1 ] || [ "$DO_COPYFILES" == 2 ]; then
            echo "ON LOOP "$loopcount", TYPE "$DO_COPYFILES" FILE COPY FROM WITHIN SBATCH JOB"
            partition_str=transfer #use short partition for everything but copying files (when do_copyfiles==0)        
            time_str=00:10:00
            ntasks_str=1
            cpus_per_task_str=1
            mem_per_cpu_str=5G
        else
            echo "ON LOOP "$loopcount", NO FILE COPY FROM WITHIN SBATCH JOB"
            if [ "$sbatch_job_name" == mcp.sbatch ]; then
                partition_str=short #use transfer partition if do_copyfiles==1
                time_str=00:30:00
                ntasks_str=1
                if [ "${HALFWIDTH_WINDOW_BGSUB[@]}" == 0 ]; then #use less memory if no bg subtraction
                    cpus_per_task_str=5
                    mem_per_cpu_str=3G
                else #use more memory if using bg subtraction
                    cpus_per_task_str=5
                    mem_per_cpu_str=7G
                fi
            elif [ "$sbatch_job_name" == dnp.sbatch ]; then 
                partition_str=$gpu_partition #use transfer partition if do_copyfiles==1
                time_str=$gpu_time
                ntasks_str=1
                cpus_per_task_str=4
                mem_per_cpu_str=4G
                gres_str=--gres=gpu:$gpu_to_use
                if [ "$gpu_partition" == gpu_requeue ]; then
                    requeue_str=--requeue 
                fi 
            elif [ "$sbatch_job_name" == stc.sbatch ]; then
                partition_str=short #use transfer partition if do_copyfiles==1
                time_str=00:45:00
                ntasks_str=1
                cpus_per_task_str=4
                mem_per_cpu_str=10G
            elif [ "$sbatch_job_name" == rsc.sbatch ]; then 
                partition_str=short #use transfer partition if do_copyfiles==1
                time_str=11:40:00 #11:40:00
                ntasks_str=1
                cpus_per_task_str=5
                mem_per_cpu_str=12G
            elif [ "$sbatch_job_name" == exp.sbatch ]; then 
                partition_str=short #use transfer partition if do_copyfiles==1
                time_str=01:30:00
                ntasks_str=1
                cpus_per_task_str=1
                mem_per_cpu_str=20G
            elif [ "$sbatch_job_name" == a2p.sbatch ]; then 
                partition_str=short #use transfer partition if do_copyfiles==1
                time_str=02:00:00
                ntasks_str=1
                cpus_per_task_str=5
                mem_per_cpu_str=10G
            fi
        fi

        #run the sbatch file (sbatch_job_name), using export to pass args, and specifying slurm directives, including job array indices, use parsable to output the job id for dependencies downstream
        arr_id_out=$(sbatch --parsable \
        --export=DO_COPYFILES="$DO_COPYFILES",FIRST_JOB="$FIRST_JOB",PTH_PARSFILE="$PTH_PARSFILE",PARENDIR="$PARENDIR" \
        --array=[$jobarrayind] \
        --dependency="$dep_str" \
        --partition="$partition_str" \
        --time="$time_str" \
        --ntasks="$ntasks_str" \
        --cpus-per-task="$cpus_per_task_str" \
        --mem-per-cpu="$mem_per_cpu_str" \
        --output="$pthout" \
        --error="$pthout" \
        --mail-type=ALL,ARRAY_TASKS \
        "$requeue_str" \
        "$gres_str" \
        "$sbatch_job_name") 

        declare arrid_${loopcount}_dynvar=$arr_id_out #create dynamic variable name to store job_id for next job dependency specification
        tmpid=arrid_${loopcount}_dynvar #assign to another var whose value is accessed with ${!tmpid}, rather than $tmpid, since it is dynamic

        echo ""$sbatch_job_name" HAS JOB-ARRAY ID: ${!tmpid}"

        loopcount=$((loopcount+1)) #increment loopcount

    done

done

