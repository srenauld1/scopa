#!/bin/bash
#SBATCH --time=00:05:00
#SBATCH -p short
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=5
#SBATCH --array=[0-3]
#SBATCH --begin=now+10
#SBATCH --dependency=singleton
#SBATCH --signal=B:SIGUSR1@90
#SBATCH --requeue

echo "$(date): job $SLURM_JOBID (array task $SLURM_ARRAY_TASK_ID) starting on $SLURM_NODELIST"

module purge
ml matlab

RECDATES='*'
FLY='*'
TRIAL='*'
SMOOTHWINDOWTIME=30

matlab -batch "addpath(genpath( $(pwd) )), \
run $(pwd)/cx_remove_scan_noise($RECDATES, $FLY, $TRIAL, $SMOOTHWINDOWTIME, $SLURM_ARRAY_TASK_ID);exit"

wait
sleep 1m
date
sleep 1m
