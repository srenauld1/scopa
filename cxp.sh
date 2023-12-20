#!/bin/bash

arr1id=$(sbatch --time=00:15:00 -p short --mem-per-cpu=40G --parsable --export=ALL,\
DO_COPYFILES_TMP='in',\
RECDATES_TMP='*',\
FLY_TMP='*',\
TRIAL_TMP='*',\
FOLDER_SUBSTRINGS_TMP='*',\
FILE_MATCHING_STYLE_TMP='any' mcp.sbatch)

echo "Job-Array. ID: ${arr1id}"

arr2id=$(sbatch --parsable --dependency=aftercorr:${arr1id} --export=ALL,\
DO_COPYFILES_TMP='no' mcp.sbatch)

#arr2id=$(sbatch --parsable --dependency=aftercorr:${arr1id} stc.sbatch)
#echo "Job-Array. ID: ${arr2id}"

#sbatch --dependency=aftercorr:${arr2id} exp.sbatch