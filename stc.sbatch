#!/bin/bash
#SBATCH --time=0:05:00
#SBATCH -p short
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=5
#SBATCH --mem-per-cpu=10G
#SBATCH --array=[1-3]
#SBATCH --begin=now+10
#SBATCH --signal=B:SIGUSR1@90
#SBATCH --requeue

echo "$(date): job $SLURM_JOBID (array task $SLURM_ARRAY_TASK_ID) starting on $SLURM_NODELIST"

module purge
ml python/3.10.11
ml miniconda3/4.10.3
source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
conda activate caiman

~/.conda/envs/caiman/bin/python3 $(pwd)/pipeline_init.py \
--do_stitching_session 0 \
--epoch_choose_denoise 5 \
--recdates '*' \
--fly '*' \
--trial '*' \
--recording_index $SLURM_ARRAY_TASK_ID &

wait
sleep 1m
date
sleep 1m
