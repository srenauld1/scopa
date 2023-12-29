#!/bin/bash
#SBATCH --time=0:15:00
#SBATCH -p transfer
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=10G
#SBATCH --array=[0-2]

echo "$(date): job $SLURM_JOBID (array task $SLURM_ARRAY_TASK_ID) starting on $SLURM_NODELIST"

# module purge
# ml python/3.10.11

pthsource=/n/files/Neurobio/wilsonlab/wienecke/stacks/20231120/
pthdest=/n/scratch3/users/c/caw846/copytest
rsync -rnv $pthsource $pthdest --ignore-existing

# ~/.conda/envs/caiman/bin/python3 $(pwd)/pipeline_init.py \
# --do_stitching_session 0 \
# --epoch_choose_denoise 5 \
# --recdates '*' \
# --fly '*' \
# --trial '*' \
# --folder_substrings '*' \ 
# --file_matching_style 'any' \ 
# --recording_index $SLURM_ARRAY_TASK_ID &

# wait
# sleep 1m
# date
# sleep 1m