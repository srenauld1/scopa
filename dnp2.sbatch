#!/bin/bash
#SBATCH --time=01:30:00
#SBATCH -p gpu_quad
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=12G
#SBATCH --job-name=DNPPAR
#SBATCH --gres=gpu:a100:1,vram:80G
#SBATCH --array=[0-1]
#SBATCH --begin=now+10
#SBATCH --dependency=singleton
#SBATCH --signal=B:SIGUSR1@90
#SBATCH --requeue

echo "$(date): job $SLURM_JOBID (array task $SLURM_ARRAY_TASK_ID) starting on $SLURM_NODELIST"

module purge
module load gcc/9.2.0 python/3.9.14 cuda/11.7
source ~/deepcadrt2/bin/activate

/n/cluster/bin/job_gpu_monitor.sh &

for i in 0
do
    sleep 20s
    python3 $(pwd)/pipeline_init.py \
    --do_denoise 1 \
    --denoise_volume 1 \
    --denoise_slice_index 'all' \
    --num_epochs_denoise 5 \
    --recdates '*' \
    --fly '*' \
    --trial '*' \
    --folder_substrings '*' \ 
    --file_matching_style 'any' \ 
    --recording_index $SLURM_ARRAY_TASK_ID &
done

wait
sleep 1m
date
sleep 1m
