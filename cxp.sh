#!/bin/bash

arr1id=$(sbatch --parsable COPYFLAG='in' mcp.sbatch)
echo "Job-Array. ID: ${arr1id}"

arr3id=$(sbatch --parsable --dependency=aftercorr:${arr1id} COPYFLAG='in' stc.sbatch)
echo "Job-Array. ID: ${arr2id}"

sbatch --dependency=aftercorr:${arr2id} exp.sbatch