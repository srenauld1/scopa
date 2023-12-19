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
ml miniconda3/4.10.3
source /n/app/miniconda3/4.10.3/etc/profile.d/conda.sh
conda activate caiman

if [ -z ${COPYFLAG+x} ]
then echo "COPYFLAG is unset"
else echo "COPYFLAG is set to '$COPYFLAG'"
    ~/.conda/envs/caiman/bin/python3 $(pwd)/pipeline_init.py \
    --do_copyfiles $COPYFLAG
fi

for i in 0 1 

do

    if test $i -eq 0
    then
    COPYFLAG2=$COPYFLAG
    else
    COPYFLAG2='hjhj'
    fi

    echo $COPYFLAG2


    ~/.conda/envs/caiman/bin/python3 $(pwd)/pipeline_init.py \
    --do_copyfiles $COPYFLAG2 \
    --do_register 1 \
    --do_planar_registration 1 \
    --do_background_subtraction 0 \
    --len_window_smooth_t 0 \
    --recdates '*' \
    --fly '*' \
    --trial '*' \
    --folder_substrings '' \ 
    --file_matching_style 'any' \ 
    --recording_index $SLURM_ARRAY_TASK_ID &

    wait
    sleep 1m
    date
    sleep 1m

done
