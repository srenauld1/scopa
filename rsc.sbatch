#!/bin/bash
#SBATCH -p short
#SBATCH -t 0:50:00
#SBATCH -c 5
#SBATCH --mem=90G
#SBATCH --array=[1-3]

module purge
module load matlab/2023a
RECDATES='*'
FLY='*'
TRIAL='*'
SMOOTHWINDOWTIME=30

matlab -batch "try; cx_remove_scan_noise('$RECDATES', '$FLY', '$TRIAL', $SMOOTHWINDOWTIME, $SLURM_ARRAY_TASK_ID); catch; end; quit"
