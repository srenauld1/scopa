#!/bin/bash

arr1id=$(sbatch --parsable --array=1-5  mcp.sh)
echo "Job-Array. ID: ${arr1id}"
echo ""
arr2id=$(sbatch --parsable --array=1-3  mcp.sh)
echo "Job-Array. ID: ${arr2id}"
sbatch --array=1-5 --dependency=aftercorr:${arr2id} exp.sh