#!/bin/bash

#SBATCH --gres=gpu:a100:1,vram:80G

echo "$(date): job $SLURM_JOBID (array task $SLURM_ARRAY_TASK_ID) starting on $SLURM_NODELIST"

module purge
ml python/3.10.11

if [ "$DO_COPYFILES" == 1 ]; then #no need to load any virtual environment for copying files 
    echo "COPYING FILES (NOT DOING ANALYSIS) BECAUSE DO_COPYFILES IS SET TO "$DO_COPYFILES""
else #load virtual env if not copying files
    echo "DOING ANALYSIS (NOT COPYING FILES) BECAUSE DO_COPYFILES IS SET TO "$DO_COPYFILES""
    module load miniconda3/4.10.3
    module load gcc/9.2.0
    module load cuda/11.7
    source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
    conda activate deepcadrt
fi

/n/cluster/bin/job_gpu_monitor.sh &


for i in 0
do
    sleep 20s
    ~/.conda/envs/caiman/bin/python3 $(pwd)/pipeline_init.py \
    --pars_filename "$PARS_FILENAME" \
    --do_copyfiles "$DO_COPYFILES" \
    --do_denoise 1 \
    --denoise_volume 1 \
    --num_epochs_denoise 5 \
    --denoise_slice_index 'all' \
    --recording_index $SLURM_ARRAY_TASK_ID &

done

wait
sleep 1m
date
sleep 1m

scontrol show job $SLURM_JOB_ID


