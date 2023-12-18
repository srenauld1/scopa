#!/bin/bash

arr1id=$(sbatch --parsable mcp.sbatch)
echo "Job-Array. ID: ${arr1id}"
echo ""
arr2id=$(sbatch --parsable --dependency=aftercorr:${arr1id} stc.sbatch)
echo "Job-Array. ID: ${arr2id}"
echo ""
sbatch --dependency=aftercorr:${arr2id} exp.sbatch