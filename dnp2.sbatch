#!/bin/bash
#SBATCH --time=04:00:00
#SBATCH -p gpu_requeue
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=12G
#SBATCH --job-name=DNP2
#SBATCH --gres=gpu:rtx6000:1,vram:24G
#SBATCH --array=[0]
#SBATCH --begin=now+10
#SBATCH --dependency=singleton
#SBATCH --signal=B:SIGUSR1@90
#SBATCH --requeue

echo "$(date): job $SLURM_JOBID (array task $SLURM_ARRAY_TASK_ID) starting on $SLURM_NODELIST"

module purge
module load python/3.10.11
module load miniconda3/4.10.3
module load gcc/9.2.0
module load cuda/11.7
source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
conda activate deepcadrt

/n/cluster/bin/job_gpu_monitor.sh &

for i in {4..7}
do
    sleep 20s
    ~/.conda/envs/deepcadrt/bin/python3 /home/caw846/scopa/pipeline_init.py \
    --virtenv 'deepcad' \
    --do_denoise 1 \
    --denoise_slice_index 'all' \
    --recdates '2023062*' \
    --fly '*' \
    --trial '*' \
    --recording_index $i &
done

wait
sleep 1m
date
sleep 1m
