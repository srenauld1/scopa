#!/bin/bash

echo "$(date): job $SLURM_JOBID (array task $SLURM_ARRAY_TASK_ID) starting on $SLURM_NODELIST"

module purge
ml python/3.10.11

if [ "$DO_COPYFILES" == 1 ] || [ "$DO_COPYFILES" == 2 ]; then #no need to load any virtual environment for copying files 
    echo "COPYING FILES (NOT DOING ANALYSIS) BECAUSE DO_COPYFILES IS SET TO "$DO_COPYFILES""
else #load virtual env if not copying files
    echo "DOING ANALYSIS (NOT COPYING FILES) BECAUSE DO_COPYFILES IS SET TO "$DO_COPYFILES""
fi

~/.conda/envs/caiman/bin/python3 $(pwd)/pipeline_init.py \
--pars_filename "$PARS_FILENAME" \
--do_copyfiles "$DO_COPYFILES" \
--do_separate 1 \
--use_background_subtracted 0 \
--recording_index $SLURM_ARRAY_TASK_ID &

wait
sleep 1m
date
sleep 1m


# scontrol show job $SLURM_JOB_ID


