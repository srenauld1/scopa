#!/bin/bash

COPYFLAG='in' 
arr1id=$(sbatch --parsable mcp.sbatch)
echo "Job-Array. ID: ${arr1id}"

COPYFLAG='in' 
arr3id=$(sbatch --parsable --dependency=aftercorr:${arr1id} stc.sbatch)
echo "Job-Array. ID: ${arr2id}"

sbatch --dependency=aftercorr:${arr2id} exp.sbatch