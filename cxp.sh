#!/bin/bash

arr1id=$(sbatch --export=ALL,COPYFLAG='in' --parsable mcp.sbatch)
echo "Job-Array. ID: ${arr1id}"

arr2id=$(sbatch -export=ALL,COPYFLAG='in' --parsable --dependency=aftercorr:${arr1id} stc.sbatch)
echo "Job-Array. ID: ${arr2id}"

sbatch --dependency=aftercorr:${arr2id} exp.sbatch