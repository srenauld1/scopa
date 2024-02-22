#!/bin/bash

echo "$(date): job $SLURM_JOBID (array task $SLURM_ARRAY_TASK_ID) starting on $SLURM_NODELIST"

module purge
module load gcc/9.2.0 python/3.9.14

if [ "$DO_COPYFILES" == 1 ] || [ "$DO_COPYFILES" == 2 ]; then  #no need to load any virtual environment for copying files 
    
    echo "COPYING FILES (NOT DOING ANALYSIS) BECAUSE DO_COPYFILES IS SET TO "$DO_COPYFILES""

else #load virtual env if not copying files
    
    echo "DOING ANALYSIS (NOT COPYING FILES) BECAUSE DO_COPYFILES IS SET TO "$DO_COPYFILES""
    module load cuda/11.7
    source ~/deepcadrt2/bin/activate

    /n/cluster/bin/job_gpu_monitor.sh &

fi

for i in 0
do
    sleep 20s
    python3 $(pwd)/pipeline_init.py \
    --pth_parsfile "$PTH_PARSFILE" \
    --do_copyfiles "$DO_COPYFILES" \
    --first_job "$FIRST_JOB" \
    --do_denoise 1 \
    --recording_index $SLURM_ARRAY_TASK_ID

done

wait
sleep 1m
date
sleep 1m

# scontrol show job $SLURM_JOB_ID


