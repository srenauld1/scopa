#!/bin/bash
#SBATCH -p short
#SBATCH -t 1:00:00
#SBATCH -c 5
#SBATCH --mem=10G
#SBATCH --array=[0-3]

module purge
module load matlab/2023a
RECDATES='*'
FLY='*'
TRIAL='*'
SMOOTHWINDOWTIME=30

matlab -batch "addpath(genpath( '$(pwd)' )), \
'$(pwd)'/cx_remove_scan_noise('$RECDATES', '$FLY', '$TRIAL', $SMOOTHWINDOWTIME, $SLURM_ARRAY_TASK_ID);exit"

wait
sleep 1m
date
sleep 1m
