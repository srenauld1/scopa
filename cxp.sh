#!/bin/bash

#cxp.sh runs the entire preprocessing pipeline by specifying params for pipeline_init.py
#pipeline_init.py is called from various sbatch files (specified by sbatch_job_name_sequence), which are themselves called below, and each of which uses different resources and depends on the previous (with matching jobarrayind) to finish without error
#cxp.sh is designed to only be called once 
#the sbatch files called below can run multiple jobs in parallel if jobarrayind has more than one element (those indices are used to select recordings for analysis, ie embarrassingly parallel)
#each sbatch file below is called in a 2-iteration for loop, the first iteration copies the required files from storage server to scratch on O2, the second operates on them, afterward files are automatically copied back to the storage server  
#copying requires access to the transfer job partition (write rchelp@hms.harvard.edu to request access), without access the copying is skipped (so you must manually move files to O2)

#the cxp.sh pipeline is separated into tasks that require different time/memory resources, to make analysis more efficient
#see pipeline_init.py and README.md for more details 

#note bash variables are strings; variables that are passed to python code have single quotes (this is both functional and stylistic, this code is written to handle those single quotes, and changing them can cause error), variables that are only used in bash code are not in quotes (for most or maybe all of these variables, this is just a matter of style)
#bash variables that are created by us are in lowercase, unless they are exported to another sbatch file (to distinguish them from environmental and internal variables, which are capitalized)

echo "SHELL IS " $SHELL

do_register=1
do_separate=0
do_denoise=0
do_stitch=0
do_extract=0

do_copyfiles_sequence=(1) #set to (1 0) to copy required files from storage server to O2 before each of the above sbatch_job_name_sequence is run (requires access to transfer job partition, must request access at rchelp@hms.harvard.edu), set to (0) to skip copying (must copy manually to O2 first)
PARS_FILENAME='pars.txt' #filename for params that are common to all sbatch files called below, this txt file is automatically created and overwritten each time you run cxp.sh

jobarrayind=( 0-2 ) #nonsequential syntax ( 0,2,7 ) or sequential syntax ( 0-2 ) . . . indices for parallel runs (using slurm job array), specifies which recording to analyse from list of those matching file specifiers below, this is the syntax for sequential indices

#set input args common to all sbatch jobs below (job-specific arguments are specified within each sbatch file)
#matches filenames with pattern RECDATES_FLY_TRIAL_suffix.tif (where suffix is automatically determined by stage of pipeline) or RECDATES_FLY_*_TRIAL_*_*.tif ( * is wildcard)
#matches within folders containing FOLDER_SUBSTRINGS ( * is wildcard)
#matching file can be anywhere in directory tree under directory superfolder_name_compute (or superfolder_name_storage if copying to O2)
#HERE, THESE BASH LISTS MUST BE SINGLE-QUOTED, SPACE-DELIMITED, ENCLOSED BY PARENTHESES (this prevents asterisk * from causing problems) 
PATH_STORAGE=('/n/files/Neurobio/wilsonlab/wienecke/stacks/')
RECDATES=('20231119', '22*')
FLY=('1', '2*')
TRIAL=('*')
FOLDER_SUBSTRINGS=('*') #in case RECDATES, FLY, and TRIAL is not specific enough, can also match only within folders containing FOLDER_SUBSTRINGS 
FILE_MATCHING_STYLE=('any') #'any' will match any combination of elements from RECDATES, FLY, TRIAL, FOLDER_SUBSTRINGS, 'each' will  match corresponding elements (must all be equal length, or length 1 in which case element is copied to match length of whichever has length greater than 1)

declare -A pars #put common input args into associative array called pars (grouping them into associative array helps with automation downstream)
pars["PATH_STORAGE"]="${PATH_STORAGE[@]}"
pars["RECDATES"]="${RECDATES[@]}"
pars["FLY"]="${FLY[@]}"
pars["TRIAL"]="${TRIAL[@]}"
pars["FOLDER_SUBSTRINGS"]="${FOLDER_SUBSTRINGS[@]}"
pars["FILE_MATCHING_STYLE"]="${FILE_MATCHING_STYLE[@]}"

for key in "${!pars[@]}"; do
  printf '%s\0' "$key" "${pars[$key]}"
done >"$PARS_FILENAME" #write common input args to txt file


sbatch_job_name_sequence=() #list of sbatch jobs run by cxp.sh (space delimited, enclosed by parentheses, no quotes required)

if [ "$do_register" == 1 ]; then
    sbatch_job_name_sequence+=(mcp.sbatch)
fi
if [ "$do_separate" == 1 ]; then
    sbatch_job_name_sequence+=(sep.sbatch)
fi
if [ "$do_denoise" == 1 ]; then
    sbatch_job_name_sequence+=(dnp.sbatch)
fi
if [ "$do_stitch" == 1 ]; then
    sbatch_job_name_sequence+=(stc.sbatch)
fi
if [ "$do_extract" == 1 ]; then
    sbatch_job_name_sequence+=(exp.sbatch)
fi

echo "WILL SUBMIT THE FOLLOWING SBATCH JOBS "${sbatch_job_name_sequence[@]}""

loopcount=0
for sbatch_job_name in "${sbatch_job_name_sequence[@]}"; do
    
    for DO_COPYFILES in "${do_copyfiles_sequence[@]}"; do #copy files on first loop (from superfolder_name_storage to superfolder_name_compute), analyze data from those files on second loop 

        if [ $loopcount == 0 ]; then #on the first loop, there is no job dependency ('singleton' will do nothing because --name param is not specified)
            dep_str=singleton
        else #on subsequent loops, use dependencies 
            dep_str=aftercorr:${!tmpid} #the job depends on the previous job with corresponding array index, whose value is accessed with ${!tmpid}, rather than $tmpid, since it is dynamic
        fi

        if [ $DO_COPYFILES == 1 ]; then
            echo "COPYING FILES IN SBATCH JOB "$sbatch_job_name""
            partition_str=transfer #use short partition for everything but copying files (when do_copyfiles==0)        
            time_str=00:20:00
            ntasks_str=1
            cpus_per_task_str=1
            mem_per_cpu_str=1G
        else
            echo "RUNNING SBATCH JOB "$sbatch_job_name""
            if [ "$sbatch_job_name" == mcp.sbatch ]; then
                partition_str=short #use transfer partition if do_copyfiles==1
                time_str=00:40:00
                ntasks_str=1
                cpus_per_task_str=5
                mem_per_cpu_str=10G
            elif [ "$sbatch_job_name" == sep.sbatch ]; then
                partition_str=short #use transfer partition if do_copyfiles==1
                time_str=00:15:00
                ntasks_str=1
                cpus_per_task_str=5
                mem_per_cpu_str=10G
            elif [ "$sbatch_job_name" == dnp.sbatch ]; then 
                partition_str=gpu_quad #use transfer partition if do_copyfiles==1
                time_str=02:30:00
                ntasks_str=1
                cpus_per_task_str=1
                mem_per_cpu_str=15G
            elif [ "$sbatch_job_name" == stc.sbatch ]; then 
                partition_str=short #use transfer partition if do_copyfiles==1
                time_str=00:20:00
                ntasks_str=1
                cpus_per_task_str=5
                mem_per_cpu_str=10G
            elif [ "$sbatch_job_name" == exp.sbatch ]; then 
                partition_str=short #use transfer partition if do_copyfiles==1
                time_str=00:40:00
                ntasks_str=1
                cpus_per_task_str=5
                mem_per_cpu_str=4G
            fi
        fi

        #run the sbatch file (sbatch_job_name), using export to pass args, and specifying slurm directives, including job array indices, use parsable to output the job id for dependencies downstream
        arr_id_out=$(sbatch --parsable \
        --export=DO_COPYFILES="$DO_COPYFILES",PARS_FILENAME="$PARS_FILENAME" \
        --array=[$jobarrayind] \
        --dependency="$dep_str" \
        -p "$partition_str" \
        --time="$time_str" \
        --ntasks="$ntasks_str" \
        --cpus-per-task="$cpus_per_task_str" \
        --mem-per-cpu="$mem_per_cpu_str" \
        "$sbatch_job_name") 

        declare arrid_${loopcount}_dynvar=$arr_id_out #create dynamic variable name to store job_id for next job dependency specification
        tmpid=arrid_${loopcount}_dynvar #assign to another var whose value is accessed with ${!tmpid}, rather than $tmpid, since it is dynamic

        echo "Job-Array ID: ${!tmpid}"

        loopcount=$((loopcount+1)) #increment loopcount

    done

done

