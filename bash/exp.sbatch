#!/bin/bash
#SBATCH --time=1:00:00
#SBATCH -p short
#SBATCH --cpus-per-task=5
#SBATCH --mem-per-cpu=3G
#SBATCH --array=[0,1,2,5,6]
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
--do_extract 1 \
--index_extraction_param_set 'default' \
--region_extraction 'pb' 'gar' 'gal' 'no' \
--do_planar_extraction 1 \
--use_background_subtracted 0 \
--use_denoised 1 \
--recdates '202311*' \
--fly '*' \
--trial '*' \
--recording_index $SLURM_ARRAY_TASK_ID &

wait
sleep 1m
date
sleep 1m
