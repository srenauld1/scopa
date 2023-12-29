#!/bin/bash

echo "$(date): job $SLURM_JOBID (array task $SLURM_ARRAY_TASK_ID) starting on $SLURM_NODELIST"

module purge
ml python/3.10.11

if [ "$DO_COPYFILES" == 0 ]; then #load virtual env if not copying files
    echo "DOING ANALYSIS (NOT COPYING FILES) BECAUSE DO_COPYFILES IS SET TO "$DO_COPYFILES""
    ml miniconda3/4.10.3 
    source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
    conda activate caiman
else #otherwise no need to load virtual env
    echo "COPYING FILES (NOT DOING ANALYSIS) BECAUSE DO_COPYFILES IS SET TO "$DO_COPYFILES""
fi

#run the python code, passing in arguments indirectly with pars file, and also directly
~/.conda/envs/caiman/bin/python3 $(pwd)/pipeline_init.py \
--pars_filename "$PARS_FILENAME" \
--do_copyfiles "$DO_COPYFILES" \
--do_register 0 \
--do_planar_registration 1 \
--do_background_subtraction 0 \
--len_window_smooth_t 0 \
--recording_index $SLURM_ARRAY_TASK_ID &


wait
sleep 1m
date
sleep 1m

scontrol show job $SLURM_JOB_ID
scontrol write batch_script $SLURM_JOB_ID -


