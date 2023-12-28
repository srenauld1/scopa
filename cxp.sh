#!/bin/bash

#cxp.sh runs the entire pipeline 

PARS_FILENAME='pars.txt'

JOBARRAYIND=( 0-2 ) #indices for parallel runs (using slurm job array), this is the syntax for sequential
#JOBARRAYIND=( 0,2,7 ) #and this is the syntax for non-sequential

#set input args common to all jobs below
RECDATES=('22*' '2023061')
FLY=('*' '2')
TRIAL=('*')
FOLDER_SUBSTRINGS=('*')
FILE_MATCHING_STYLE=('any')

declare -A pars #put common input args into associative array called pars (purpose is to group them to be written txt)

pars["RECDATES"]="${RECDATES[@]}"
pars["FLY"]="${FLY[@]}"
pars["TRIAL"]="${TRIAL[@]}"
pars["FOLDER_SUBSTRINGS"]="${FOLDER_SUBSTRINGS[@]}"
pars["FILE_MATCHING_STYLE"]="${FILE_MATCHING_STYLE[@]}"

for key in "${!pars[@]}"; do
  printf '%s\0' "$key" "${pars[$key]}"
done >"$PARS_FILENAME" #write common input args to txt file

for ci in 0 1; do #copy files on first loop, analyze data from those files on second loop 

    if [ $ci == 0 ]; then
        DO_COPYFILES='in' #on first loop (ci==0) set to 'in' to copy the requested files from storage server to O2
        DEPSTR="singleton" #on first loop have no dependency ('singleton' will do nothing because --name param is not specified)
    else
        DO_COPYFILES='' #on second loop (ci==1) set to '' (empty) to do analysis on the files that were moved in on first loop
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