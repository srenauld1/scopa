#!/bin/bash
#SBATCH --time=00:30:00
#SBATCH -p short
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=20G
#SBATCH --array=[0]
#SBATCH --begin=now+10
#SBATCH --dependency=singleton
#SBATCH --signal=B:SIGUSR1@90
#SBATCH --requeue

echo "$(date): job $SLURM_JOBID (array task $SLURM_ARRAY_TASK_ID) starting on $SLURM_NODELIST"

module purge
ml python/3.10.11
ml miniconda3/4.10.3
source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
conda activate caiman

~/.conda/envs/caiman/bin/python3 /home/caw846/scopa/pipeline_init.py \
--do_register 1 \
--do_background_subtraction 0 \
--len_window_smooth_t 0 \
--recdates '*' \
--fly '*' \
--trial '*' \
--recording_index $SLURM_ARRAY_TASK_ID &

wait
sleep 1m
date
sleep 1m
