#!/bin/bash

arr1id=$(sbatch --parsable --export=ALL,\
DO_COPYFILES='in',\
RECDATES='*',\
FLY='*',\
TRIAL='*',\
FOLDER_SUBSTRINGS='*',\
FILE_MATCHING_STYLE='any',\
mcp.sbatch)

echo "Job-Array. ID: ${arr1id}"

#arr2id=$(sbatch --parsable --dependency=aftercorr:${arr1id} stc.sbatch)
#echo "Job-Array. ID: ${arr2id}"

#sbatch --dependency=aftercorr:${arr2id} exp.sbatch