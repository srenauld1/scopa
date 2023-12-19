#!/bin/bash
#SBATCH --time=00:15:00
#SBATCH -p short
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=40G
#SBATCH --array=[0-2]
#SBATCH --begin=now+10
#SBATCH --signal=B:SIGUSR1@90
#SBATCH --requeue

echo "$(date): job $SLURM_JOBID (array task $SLURM_ARRAY_TASK_ID) starting on $SLURM_NODELIST"

module purge
ml python/3.10.11

if [[ ! -v COPYFLAG ]]; then
    echo "COPYFLAG is not set"
    COPYFLAG='no'
    NUMLOOP=1
else
    echo "COPYFLAG is set to: $COPYFLAG"
    NUMLOOP=2
fi

for (( i = 1; i <= $NUMLOOP; i++ )); do

    if (($i==1 && $NUMLOOP==2)); then
        COPYFLAGNEW=$COPYFLAG
    else
        COPYFLAGNEW='no'
        ml miniconda3/4.10.3
        source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
        conda activate caiman
    fi

    echo "COPYFLAGNEW is set to: $COPYFLAGNEW"

    ~/.conda/envs/caiman/bin/python3 $(pwd)/pipeline_init.py \
    --do_copyfiles $COPYFLAGNEW \
    --do_register 1 \
    --do_planar_registration 1 \
    --do_background_subtraction 0 \
    --len_window_smooth_t 0 \
    --recdates '*' \
    --fly '*' \
    --trial '*' \
    --folder_substrings '*' \ 
    --file_matching_style 'any' \ 
    --recording_index $SLURM_ARRAY_TASK_ID &

    wait
    sleep 1m
    date
    sleep 1m

done
