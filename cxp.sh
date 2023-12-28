#!/bin/bash

#cxp.sh runs the entire preprocessing pipeline by specifying params for pipeline_init.py
#pipeline_init.py is called from various sbatch files, which are themselves called below
#cxp.sh is designed to only be called once
#the sbatch files called below can run multiple jobs in parallel if JOBARRAYIND has more than one element (those indices are used to select recordings for analysis)
#each sbatch file below is called in a 2-iteration for loop, the first iteration copies the required files from storage server to scratch on O2, the second operates on them, afterward files are automatically copied back to the storage server  
#copying requires access to the transfer job partition (write rchelp@hms.harvard.edu to request access), without access the copying is skipped (so you must manually move files to O2)
#see pipeline_init.py and README.md for more details 

PARS_FILENAME='pars.txt' #filename for params that are common to all sbatch files called below, this txt file is automatically created and overwritten each time you run cxp.sh

JOBARRAYIND=( 0-2 ) #indices for parallel runs (using slurm job array), specifies which recording to analyse from list of those matching file specifiers below, this is the syntax for sequential indices
#JOBARRAYIND=( 0,2,7 ) #and this is the syntax for non-sequential indices

#set input args common to all sbatch jobs below (job-specific arguments are specified within each sbatch file)
#matches filenames with pattern RECDATES_FLY_TRIAL_suffix.tif (where suffix is automatically determined by stage of pipeline) or RECDATES_FLY_*_TRIAL_*_*.tif, 
#matches within folders containing FOLDER_SUBSTRINGS
#   * is wildcard
#matching file can be anywhere in directory tree under directory superfolder_name_compute (or superfolder_name_storage if copying to O2)
#MUST BE SINGLE-QUOTED STRING OR STRINGS, IF MULTIPLE ELEMENTS, EACH MUST BE SEPARATED BY A SPACE (NO COMMA OR OTHER DELIMITER)
RECDATES=('22*' '2023061*')
FLY=('*')
TRIAL=('*')
FOLDER_SUBSTRINGS=('*') #in case RECDATES, FLY, and TRIAL is not specific enough, can also match only within folders containing FOLDER_SUBSTRINGS 
FILE_MATCHING_STYLE=('any') #'any' will match any combination of elements from RECDATES, FLY, TRIAL, FOLDER_SUBSTRINGS, 'each' will  match corresponding elements (must all be equal length, or length 1 in which case element is copied to match length of whichever has length greater than 1)

declare -A pars #put common input args into associative array called pars (purpose is to group them to be written txt)
pars["RECDATES"]="${RECDATES[@]}"
pars["FLY"]="${FLY[@]}"
pars["TRIAL"]="${TRIAL[@]}"
pars["FOLDER_SUBSTRINGS"]="${FOLDER_SUBSTRINGS[@]}"
pars["FILE_MATCHING_STYLE"]="${FILE_MATCHING_STYLE[@]}"

for key in "${!pars[@]}"; do
  printf '%s\0' "$key" "${pars[$key]}"
done >"$PARS_FILENAME" #write common input args to txt file

for ci in 0 1; do #copy files on first loop (from superfolder_name_storage to superfolder_name_compute), analyze data from those files on second loop 

    if [ $ci == 0 ]; then
        DO_COPYFILES=1 #on first loop (ci==0) set to 1 to copy the requested files from storage server to O2
        DEPSTR="singleton" #on first loop have no dependency ('singleton' will do nothing because --name param is not specified)
    else
        DO_COPYFILES=0 #on second loop (ci==1) set to 0 to do analysis on the files that were moved in on first loop
        DEPSTR="aftercorr:${arr1id}"
    fi

    #run the sbatch file, using export to pass args, and specifying slurm directives, including job array indices, use parsable to output the job id for dependencies downstream
    arr1id=$(sbatch --parsable \
    --export=DO_COPYFILES="$DO_COPYFILES",PARS_FILENAME="$PARS_FILENAME" \
    --dependency="$DEPSTR" \
    -p short \
    --time=0:15:00 \
    --ntasks=1 \
    --cpus-per-task=1 \
    --mem-per-cpu=10G \
    --ntasks=1 \
    --cpus-per-task=1 \
    --array=[$JOBARRAYIND] \
    mcp.sbatch) #the name of the sbatch file at the end 

    echo "Job-Array. ID: ${arr1id}"

done


#arr2id=$(sbatch --parsable --dependency=aftercorr:${arr1id} stc.sbatch)
#echo "Job-Array. ID: ${arr2id}"

#sbatch --dependency=aftercorr:${arr2id} exp.sbatch