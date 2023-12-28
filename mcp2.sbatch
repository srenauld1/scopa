#!/bin/bash

echo "$(date): job $SLURM_JOBID (array task $SLURM_ARRAY_TASK_ID) starting on $SLURM_NODELIST"

module purge
ml python/3.10.11

if [ -z "${DO_COPYFILES}" ]; then
    echo "DO_COPYFILES EMPTY"
    ml miniconda3/4.10.3
    source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
    conda activate caiman
fi

echo "DO_COPYFILES is set to: "$DO_COPYFILES""

~/.conda/envs/caiman/bin/python3 $(pwd)/pipeline_init.py \
--pars_filename 'pars.txt' \
--do_copyfiles "$DO_COPYFILES" \
--do_register 1 \
--do_planar_registration 1 \
--do_background_subtraction 0 \
--len_window_smooth_t 0 \
--recording_index $SLURM_ARRAY_TASK_ID &


wait
sleep 1m
date
sleep 1m


