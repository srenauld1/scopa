#!/bin/bash
#SBATCH --time=11:59:00
#SBATCH -p short
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=13G
#SBATCH --array=[1-33]
#SBATCH --begin=now+10
#SBATCH --dependency=singleton
#SBATCH --signal=B:SIGUSR1@90

_requeue() {
    echo "$(date): job $SLURM_JOBID re-queueing"
    scontrol requeue $SLURM_JOBID
}

trap '_requeue' SIGUSR1 SIGTERM

echo "$(date): job $SLURM_JOBID (array task $SLURM_ARRAY_TASK_ID) starting on $SLURM_NODELIST"

module purge
ml python/3.10.11
ml miniconda3/4.10.3
source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
conda activate caiman

~/.conda/envs/caiman/bin/python3 /home/caw846/scopa/pipeline_init.py \
--index_extraction_param_set 0 \
--region_extraction 'pb' 'gar' 'gal' 'no' \
--do_motion_correction 1 \
--do_denoise 0 \
--use_denoised 0 \
--do_extraction 0 \
--do_planar_extraction 0 \
--recdates '*' \
--fly '*' \
--trial '*' \
--do_cropping_session 0 \
--recording_index $SLURM_ARRAY_TASK_ID &

wait
sleep 1m
date
sleep 1m
