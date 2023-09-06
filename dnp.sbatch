#!/bin/bash
#SBATCH --time=5:00:00
#SBATCH -p gpu_requeue
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=15G
#SBATCH --job-name=DNP
#SBATCH --gres=gpu:rtx6000:1,vram:24G
#SBATCH --array=[1]
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
module load python/3.10.11
module load miniconda3/4.10.3
module load gcc/9.2.0
module load cuda/11.7
source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
conda activate caiman

/n/cluster/bin/job_gpu_monitor.sh &

~/.conda/envs/caiman/bin/python3 /home/caw846/scopa/pipeline_init.py \
--index_extraction_param_set 0 \
--region_extraction 'pb' 'gar' 'gal' 'no' \
--do_background_subtraction 0 \
--do_motion_correction 0 \
--do_denoise 1 \
--use_denoised 0 \
--do_extraction 0 \
--do_planar_extraction 0 \
--recdates '20230627' \
--fly '2' \
--trial '2' \
--do_cropping_session 0 \
--recording_index $SLURM_ARRAY_TASK_ID &

wait
sleep 1m
date
sleep 1m
