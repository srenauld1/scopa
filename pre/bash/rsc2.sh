#!/bin/bash

echo "$(date): job $SLURM_JOBID (array task $SLURM_ARRAY_TASK_ID) starting on $SLURM_NODELIST"

module purge
ml python/3.10.11

if [ "$DO_COPYFILES" == 1 ] || [ "$DO_COPYFILES" == 2 ]; then #no need to load any virtual environment for copying files 
    echo "COPYING FILES (NOT DOING ANALYSIS) BECAUSE DO_COPYFILES IS SET TO "$DO_COPYFILES""
else #load virtual env if not copying files
    echo "DOING ANALYSIS (NOT COPYING FILES) BECAUSE DO_COPYFILES IS SET TO "$DO_COPYFILES""
    eval "$(/n/data1/hms/neurobio/wilson/miniforge3/bin/conda shell.bash hook)"
    conda activate caiman
fi

summation=$(/n/data1/hms/neurobio/wilson/miniforge3/envs/caiman/bin/python3 $PARENDIR/pipeline_init.py \
--pth_parsfile "$PTH_PARSFILE" \
--do_copyfiles "$DO_COPYFILES" \
--first_job "$FIRST_JOB" \
--do_remove 1 \
--recording_index $SLURM_ARRAY_TASK_ID) &


echo "FINISHED PIPELINE_INIT, STARTING MATLAB"


module purge
module load matlab/2023a

matlab -batch "try; remove_scan_noise('scopaparams.txt', [], $SLURM_ARRAY_TASK_ID); catch; end; quit"


wait
sleep 1m
date
sleep 1m


# scontrol show job $SLURM_JOB_ID



