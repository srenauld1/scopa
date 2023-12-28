#!/bin/bash

#JOBARRAYIND=( 0,2,7 ) #this is the syntax for non-sequential
JOBARRAYIND=( 0-2 ) #this is the syntax for sequential

RECDATES=('22*' '2023061')
FLY=('*' '2')
TRIAL=('*')
FOLDER_SUBSTRINGS=('*')
FILE_MATCHING_STYLE=('any')

declare -A pars

pars["RECDATES"]="${RECDATES[@]}"
pars["FLY"]="${FLY[@]}"
pars["TRIAL"]="${TRIAL[@]}"
pars["FOLDER_SUBSTRINGS"]="${FOLDER_SUBSTRINGS[@]}"
pars["FILE_MATCHING_STYLE"]="${FILE_MATCHING_STYLE[@]}"

for key in "${!pars[@]}"; do
  printf '%s\0' "$key" "${pars[$key]}"
done >pars.txt

DO_COPYFILES='' 
arr1id=$(sbatch --parsable \
--export=DO_COPYFILES=$DO_COPYFILES \
-p short \
--time=0:15:00 \
--ntasks=1 \
--cpus-per-task=1 \
--mem-per-cpu=10G \
--ntasks=1 \
--cpus-per-task=1 \
--array=[$JOBARRAYIND] \
mcp2.sbatch)

echo "Job-Array. ID: ${arr1id}"

#arr2id=$(sbatch --parsable --dependency=aftercorr:${arr1id} stc.sbatch)
#echo "Job-Array. ID: ${arr2id}"

#sbatch --dependency=aftercorr:${arr2id} exp.sbatch